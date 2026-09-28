{
  rustPlatform,
  fetchFromGitHub,
  meta,
  procps,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "clash-verge-service-ipc";
  version = "2.7.4";

  src = fetchFromGitHub {
    owner = "clash-verge-rev";
    repo = "clash-verge-service-ipc";
    tag = "v${finalAttrs.version}";
    hash = "sha256-O8tQ4geASXt4xDNVjbmKCI2WxegzR3VWEZuOUZMCdLo=";
  };

  patches = [
    # Let the NixOS module's RuntimeDirectory/Group own socket access policy.
    # Upstream defaults target installer-managed /tmp paths and broad fallback
    # permissions, which do not fit the hardened systemd service.
    ./patch-service-directory.patch
  ];

  cargoHash = "sha256-so3Y+G31xupCX+nKBBLuB82dEAiCSI4fvJB5hLRsdbA=";

  buildFeatures = [
    "standalone"
  ];

  nativeCheckInputs = [
    procps
  ];
  # build test helper binaries for tests
  preCheck = ''
    cargo build --features=standalone,test
  '';
  checkFeatures = [
    "standalone"
    "test"
    "client"
  ];
  inherit meta;
})
