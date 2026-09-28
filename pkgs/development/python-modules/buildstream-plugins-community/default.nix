{
  lib,
  buildPythonPackage,
  fetchFromGitLab,
  gitUpdater,
  nixosTests,
  setuptools,
  setuptools-scm,

  # Optional plugin dependencies, matching upstream's pyproject.toml extras.
  arpy,
  dulwich,
  packaging,
  requests,
  tomlkit,

  withCargo2 ? true,
  withDeb ? true,
  withGit ? true,
  withHttpfetcher ? true,
  withPypi ? true,
}:
buildPythonPackage (finalAttrs: {
  pname = "buildstream-plugins-community";
  version = "2.3.3";
  pyproject = true;

  src = fetchFromGitLab {
    owner = "buildstream";
    repo = "buildstream-plugins-community";
    tag = finalAttrs.version;
    hash = "sha256-Fvm7TKwKmOAiVATJrvvd9I5mpPN+zkCxaMXnoksVrJE=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies =
    lib.optionals withDeb [ arpy ]
    ++ lib.optionals (withCargo2 || withGit) [ dulwich ]
    ++ lib.optionals withCargo2 [ tomlkit ]
    ++ lib.optionals withHttpfetcher [ requests ]
    ++ lib.optionals withPypi [ packaging ];

  # `buildstream-plugins-community` is loaded by `bst` at runtime (via
  # pluginbase, as configured through a project's `project.conf`), so it
  # always has `buildstream` in its environment when imported; drop it from
  # the wheel's declared dependencies instead of propagating it as a
  # `dependencies` entry, to avoid pulling a second `buildstream` closure
  # into consumers that already bundle it. Its test suite, which does need
  # `buildstream` present, and needs real `/dev/fuse` access that the Nix
  # build sandbox doesn't provide, is run as a NixOS VM test instead; see
  # `passthru.tests.pytest`.
  pythonRemoveDeps = [ "buildstream" ];

  pythonImportsCheck = [ "buildstream_plugins_community" ];

  passthru = {
    updateScript = gitUpdater { };

    tests.pytest = nixosTests.buildstream-plugins-community;
  };

  meta = {
    changelog = "https://gitlab.com/BuildStream/buildstream-plugins-community/-/blob/${finalAttrs.src.tag}/NEWS";
    description = "BuildStream community plugins";
    homepage = "https://gitlab.com/buildstream/buildstream-plugins-community";
    platforms = lib.platforms.linux;
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ shymega ];
  };
})
