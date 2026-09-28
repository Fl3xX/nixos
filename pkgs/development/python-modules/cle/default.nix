{
  lib,
  archinfo,
  arpy,
  buildPythonPackage,
  cart,
  fetchFromGitHub,
  minidump,
  pefile,
  pyelftools,
  pytestCheckHook,
  pyvex,
  pyxbe,
  pyxdia,
  pythonOlder,
  setuptools,
  sortedcontainers,
  uefi-firmware,
}:

let
  # Released alongside angr 10.0.0.
  binaries = fetchFromGitHub {
    owner = "angr";
    repo = "binaries";
    rev = "aa4d34a522c9363adbc0237fbfe58a416cc173af";
    hash = "sha256-ribTb7VMdNetfVZDMCFYM8a9k4P36tq014AMO2KaVmo=";
  };
in
buildPythonPackage (finalAttrs: {
  pname = "cle";
  # Keep angr-management, angr, archinfo, cle, and pyvex in sync.
  # nixpkgs-update: no auto update
  version = "10.0.0";
  pyproject = true;

  disabled = pythonOlder "3.12";

  src = fetchFromGitHub {
    owner = "angr";
    repo = "cle";
    tag = "v${finalAttrs.version}";
    hash = "sha256-I5HMPdSlitan8dYpHN6BY1TOUPWhmfFzMJFa4s+ZbWg=";
  };

  pythonRelaxDeps = [ "arpy" ];

  # pyxdia bundles Microsoft's unfree DIA runtime, so keep PDB support opt-in.
  pythonRemoveDeps = [ "pyxdia" ];

  build-system = [ setuptools ];

  dependencies = [
    archinfo
    arpy
    cart
    minidump
    pefile
    pyelftools
    pyvex
    pyxbe
    sortedcontainers
    uefi-firmware
  ];

  optional-dependencies.pdb = [ pyxdia ];

  nativeCheckInputs = [ pytestCheckHook ];

  preCheck = ''
    export HOME="$TMPDIR"
    ln -s ${binaries} ../binaries
  '';

  disabledTests = [
    # Require the optional unfree pyxdia dependency.
    "test_debug_symbol_paths_flat_layout"
    "test_debug_symbol_paths_multiple_paths"
    "test_debug_symbol_paths_nonexistent_path"
    "test_debug_symbol_paths_symbol_store_layout"
    "test_pdb"
  ];

  pythonImportsCheck = [ "cle" ];

  meta = {
    description = "Python loader for many binary formats";
    homepage = "https://github.com/angr/cle";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [
      connornelson
      fab
    ];
  };
})
