{
  name = "whisparr_2";
  meta.maintainers = [ ];

  nodes.machine = { pkgs, ... }: {
    services.whisparr = {
      enable = true;
      package = pkgs.whisparr_2;
    };
  };

  testScript = ''
    machine.wait_for_unit("whisparr.service")
    machine.wait_for_open_port(6969)
    machine.succeed("curl --fail http://localhost:6969/")
  '';
}
