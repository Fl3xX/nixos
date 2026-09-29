{
  lib,
  angr-data,
  archinfo,
  buildPythonPackage,
  cachetools,
  capstone,
  cargo,
  cffi,
  cle,
  cxxheaderparser,
  fastmcp,
  fetchFromGitHub,
  gitpython,
  grpcio-tools,
  keystone-engine,
  lmdb,
  mcp,
  msgspec,
  mulpyplexer,
  networkx,
  platformdirs,
  protobuf,
  psutil,
  pycparser,
  pydantic-ai-slim,
  pydemumble,
  pypcode,
  pyvex,
  python,
  pythonOlder,
  rich,
  runCommandCC,
  rustc,
  rustPlatform,
  setuptools,
  setuptools-rust,
  sortedcontainers,
  sqlalchemy,
  sympy,
  typing-extensions,
  unicorn,
  z3-solver,
}:

buildPythonPackage (finalAttrs: {
  pname = "angr";
  # Keep angr-management, angr, archinfo, cle, and pyvex in sync.
  # nixpkgs-update: no auto update
  version = "10.0.0";
  pyproject = true;

  disabled = pythonOlder "3.12";

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-kv5s67+oyBQp/cqrnDPAEbanKHF3W5q+nMOLdMVF6hM=";
  };

  # Generate bindings for the Z3 version in Nixpkgs.
  patches = [ ./z3-bindgen.patch ];

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      src
      pname
      version
      patches
      ;
    hash = "sha256-FuIryOMHAe9ATt9b2AEy+20B8yWQcRUx5p7dKSJjVTU=";
  };

  # pythonRelaxDeps cannot relax build-system requirements.
  # z3 does not provide a dist-info, so python-runtime-deps-check will fail
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'grpcio-tools~=1.80.0' 'grpcio-tools' \
      --replace-fail 'protobuf>=6.31.1,<7' 'protobuf>=6.31.1' \
      --replace-fail '"z3-solver==5.1.0.0",' ""
  '';

  pythonRelaxDeps = [ "lmdb" ];

  build-system = [
    grpcio-tools
    protobuf
    pyvex
    setuptools
    setuptools-rust
    z3-solver
  ];

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustPlatform.bindgenHook
    cargo
    rustc
  ];

  env = {
    Z3_SYS_Z3_HEADER = "${z3-solver.dev}/include/z3.h";
    Z3_SYS_Z3_VERSION = z3-solver.version;
  };

  dependencies = [
    angr-data
    archinfo
    cachetools
    capstone
    cffi
    cle
    cxxheaderparser
    gitpython
    lmdb
    msgspec
    mulpyplexer
    networkx
    platformdirs
    protobuf
    psutil
    pycparser
    pydemumble
    pypcode
    pyvex
    rich
    sortedcontainers
    sympy
    typing-extensions
    z3-solver
  ];

  optional-dependencies = {
    angrdb = [ sqlalchemy ];
    keystone = [ keystone-engine ];
    llm = [
      fastmcp
      mcp
      pydantic-ai-slim
    ];
    unicorn = [ unicorn ];
  };

  # The full upstream suite requires large external fixtures and optional dependencies.
  doCheck = false;

  pythonImportsCheck = [
    "angr"
    "archinfo"
    "cle"
    "pypcode"
    "pyvex"
  ];

  passthru.tests.smoke =
    runCommandCC "angr-smoke-test"
      {
        __structuredAttrs = true;
        nativeBuildInputs = [
          (python.withPackages (_: [
            finalAttrs.finalPackage
            sqlalchemy
            unicorn
          ]))
        ];
      }
      ''
        cc -O1 ${./tests/fixture.c} -o fixture
        python ${./tests/smoke.py} "$PWD/fixture" ${finalAttrs.version}
        touch "$out"
      '';

  meta = {
    description = "Powerful and user-friendly binary analysis platform";
    homepage = "https://angr.io/";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [
      connornelson
      fab
    ];
  };
})
