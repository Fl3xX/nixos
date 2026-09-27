{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  clang,
}:

rustPlatform.buildRustPackage rec {
  pname = "lumis";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "leandrocp";
    repo = "lumis";
    rev = "cargo-lumis-cli/v${version}";
    hash = "sha256-xdBCa0KiNPLAFS0frykyk/k29WsHdVWoQ0G+ExG8W/E=";
  };

  cargoHash = "sha256-uvWlpfdz0iZ2PTNC5HevrvFOq+MQU2Va9HhjTX7elR8=";

  cargoBuildFlags = [
    "--package"
    "lumis-cli"
  ];

  doCheck = false;

  nativeBuildInputs = [ cmake ];
  buildInputs = [ clang ];

  meta = with lib; {
    description = "Syntax Highlighter CLI powered by Tree-sitter and Neovim themes";
    homepage = "https://lumis.sh";
    changelog = "https://github.com/leandrocp/lumis/releases/tag/cargo-lumis-cli/v${version}";
    license = with licenses; [ mit ];
    mainProgram = "lumis";
    maintainers = with maintainers; [ Freed-Wu ];
    platforms = with platforms; linux ++ darwin;
  };
}
