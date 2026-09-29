{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.bazarr;

  secretCheck =
    v:
    secretType.check v
    || lib.isList v && lib.any secretCheck v
    || lib.isAttrs v && lib.any secretCheck (lib.attrValues v);
  secretType = lib.types.attrTag {
    _secret = lib.mkOption {
      type = lib.types.either lib.types.externalPath (lib.types.listOf lib.types.externalPath);
    };
  };
  settingsFormat = pkgs.formats.yaml { };
  settingsType =
    lib.types.oneOf [
      secretType
      (lib.types.attrsOf settingsType)
      (lib.types.addCheck settingsFormat.type (v: !secretCheck v))
    ]
    // {
      description = "${settingsFormat.type.description}, where an attribute value may instead be an ${secretType.description} of ${
        lib.types.optionDescriptionPhrase (class: class == "noun")
          (secretType.getSubOptions [ ])._secret.type
      }";
    };

  settings = lib.pipe cfg.settings [
    (lib.mapAttrsToListRecursiveCond (_: as: !secretType.check as) lib.nameValuePair)
    (lib.partition ({ value, ... }: secretType.check value))
  ];
  secretSettings = map ({ name, value }: {
    inherit name;
    value = value._secret;
  }) settings.right;
  publicSettings = settings.wrong;

  envName = { name, ... }: "DYNACONF_${lib.join "__" name}";
  envValue =
    { name, value }:
    if lib.isBool value then
      "@bool ${lib.boolToString value}"
    else if lib.isFloat value then
      "@float ${toString value}"
    else if lib.isInt value then
      "@int ${toString value}"
    else if lib.isList value then
      "@json ${lib.toJSON value}"
    else if isNull value then
      "@none"
    else if lib.isString value then
      "@str ${value}"
    else
      throw "services.bazarr.settings: unsupported value type ${lib.typeOf value} at ${lib.showAttrPath name}";
  toEnvironment = lib.flip lib.pipe [
    (map (setting: lib.nameValuePair (envName setting) (envValue setting)))
    lib.listToAttrs
  ];

  credentialId = lib.concatMapStringsSep "." toString;
  mapSecret = f: { name, value }: {
    inherit name;
    value =
      if lib.isList value then
        lib.imap0 (i: f (credentialId (name ++ [ i ]))) value
      else
        f (credentialId name) value;
  };
  secretCredentials = lib.flip lib.pipe [
    (mapSecret (id: value: "${id}:${value}"))
    (lib.getAttr "value")
  ];
  secretFormat = lib.flip lib.pipe [
    (mapSecret (_: _: "%s"))
    envValue
    lib.escapeShellArg
  ];
  secretArgs = lib.flip lib.pipe [
    (mapSecret (id: _: ''"$(<$CREDENTIALS_DIRECTORY/${id})"''))
    (lib.getAttr "value")
    toString
  ];
  toCredentials = lib.flip lib.pipe [
    (map secretCredentials)
    lib.flatten
  ];
  toScript = lib.flip lib.pipe [
    (map (setting: ''
      printf -v ${envName setting} ${secretFormat setting} ${secretArgs setting}
      export ${envName setting}
    ''))
    lib.concatStrings
  ];
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "bazarr" "listenPort" ]
      [ "services" "bazarr" "settings" "general" "port" ]
    )
  ];

  options = {
    services.bazarr = {
      enable = lib.mkEnableOption "bazarr, a subtitle manager for Sonarr and Radarr";

      package = lib.mkPackageOption pkgs "bazarr" { };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/bazarr";
        description = "The directory where Bazarr stores its data files.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open ports in the firewall for the bazarr web interface.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "bazarr";
        description = "User account under which bazarr runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "bazarr";
        description = "Group under which bazarr runs.";
      };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = settingsType;
          options = {
            analytics.enabled = lib.mkEnableOption "sending anonymous usage statistics to Bazarr's developers";

            general = {
              auto_update = lib.mkOption {
                type = lib.types.bool;
                default = false;
                readOnly = true;
                description = ''
                  Bazarr is managed by Nix, so any self-update would fight the store.
                  This option is emitted as `DYNACONF_general__auto_update=@bool false` so the in-memory settings agree,
                  but the actual suppression is enforced unconditionally by the `--no-update` CLI flag,
                  which also hides the entire Updates section from the web UI.
                '';
              };

              port = lib.mkOption {
                type = lib.types.port;
                default = 6767;
                description = "Port on which the Bazarr web interface listens.";
              };
            };
          };
        };
        default = { };
        description = ''
          Bazarr configuration.
          Settings are emitted as `DYNACONF_*` environment variables at startup,
          overriding any value previously written by Bazarr's web UI to `config.yaml`.

          Use `_secret` to load values from files via systemd's `LoadCredential=`.
          Secret contents are exported into bazarr's environment at service start,
          as either a string or a list of strings.
        '';
        example = {
          general = {
            instance_name = "NixOS Bazarr";
            port = 12345;
          };
          auth.apikey._secret = "/run/secrets/bazarr-apikey";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.settings."10-bazarr".${cfg.dataDir}.d = {
      inherit (cfg) user group;
      mode = "0700";
    };

    systemd.services.bazarr = {
      description = "Bazarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = toEnvironment publicSettings;
      script = ''
        ${toScript secretSettings}
        exec ${lib.getExe cfg.package} ${
          lib.cli.toCommandLineShellGNU { } {
            config = cfg.dataDir;
            no-update = true;
          }
        }
      '';

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        SyslogIdentifier = "bazarr";
        Restart = "on-failure";
        KillSignal = "SIGINT";
        SuccessExitStatus = "0 156";
        LoadCredential = toCredentials secretSettings;
      };
      unitConfig.RequiresMountsFor = [ cfg.dataDir ];
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.settings.general.port ];
    };

    users.users = lib.mkIf (cfg.user == "bazarr") {
      bazarr = {
        inherit (cfg) group;
        isSystemUser = true;
        home = cfg.dataDir;
      };
    };

    users.groups = lib.mkIf (cfg.group == "bazarr") {
      bazarr = { };
    };
  };

  meta.maintainers = with lib.maintainers; [
    connor-grady
    diogotcorreia
  ];
}
