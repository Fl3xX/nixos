{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  pkg-config,
  openssl,
  sqlite,
  libsodium,
  udev,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "microclaw";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "microclaw";
    repo = "microclaw";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rg36EbdlPxRNAGk86Ekn3CNEC/XILQ9EGjcoVwqTBIA=";
  };

  # The workspace lockfile pins Git revisions of GPUI/Zed crates used by the
  # optional desktop app. fetchCargoVendor vendors them behind this one hash.
  cargoHash = "sha256-slydtj+V3XMC/HwUTZMkunXF2ecHDc66T/SySbJ7Ce8=";

  # Only the server binary is packaged; skip the GPUI desktop crates.
  cargoBuildFlags = [
    "--package"
    "microclaw"
  ];

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    src = "${finalAttrs.src}/web";
    hash = "sha256-lAOiFmi0qQbvhhdnGIvQvUl+23kh2BUbNU11OGZPJ8k=";
  };
  npmRoot = "web";

  nativeBuildInputs = [
    pkg-config
    nodejs
    npmHooks.npmConfigHook
  ];

  buildInputs = [
    openssl
    sqlite
    libsodium
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ udev ];

  buildFeatures = lib.optionals stdenv.hostPlatform.isLinux [
    "journald"
    "sqlite-vec"
  ];

  # build.rs embeds web/dist into the binary. Build the bundle from the
  # offline npm cache first and stop build.rs from running npm on its own.
  preBuild = ''
    npm --prefix web run build
  '';
  env.MICROCLAW_SKIP_WEB_BUILD = "1";

  # The test suite needs a writable data dir and live provider endpoints.
  doCheck = false;

  meta = {
    description = "Multi-channel agent runtime for Telegram, Discord, Slack, Feishu, and Web";
    homepage = "https://github.com/microclaw/microclaw";
    changelog = "https://github.com/microclaw/microclaw/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "microclaw";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ everettjf ];
  };
})
