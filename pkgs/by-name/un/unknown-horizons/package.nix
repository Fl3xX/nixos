{
  lib,
  fetchFromGitHub,
  python3Packages,
  gettext,
  intltool,
  writableTmpDirAsHomeHook,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "unknown-horizons";
  # Last tagged release is from 2019 and predates the Python 3 fixes on master.
  version = "0-unstable-2026-04-14";
  pyproject = true;

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "unknown-horizons";
    repo = "unknown-horizons";
    rev = "af9c8ef5c7f6cf9ec0b8c9e7d172c555f2793615";
    hash = "sha256-AoI1Tsp0NP1EwqwyywHKuOcHgRr8PEemfKl07/JVUU4=";
  };

  # Upstream bugs, not packaging workarounds. Vendored rather than fetched:
  # these are still open pull requests, so the commits they point at can be
  # rebased or garbage collected.
  patches = [
    # setup.py imports distutils, gone since Python 3.12.
    # https://github.com/unknown-horizons/unknown-horizons/pull/2982
    ./setuptools.patch
    # The fife version probe uses names that only exist on fife main.
    # https://github.com/unknown-horizons/unknown-horizons/pull/2983
    ./fife-version-detection.patch
    # The version lookup crashes without git, and never reaches its
    # gitversion.txt fallback on an installed build.
    # https://github.com/unknown-horizons/unknown-horizons/pull/2979
    ./version-lookup.patch
    # The atlases are generated without waiting, then never installed.
    # https://github.com/unknown-horizons/unknown-horizons/pull/2980
    ./atlas-generation.patch
    # Message catalogs are only searched for under /usr.
    # https://github.com/unknown-horizons/unknown-horizons/pull/2981
    ./translation-data-paths.patch
  ];

  postPatch = ''
    # The launcher searches hardcoded FHS paths for its content dir.
    substituteInPlace run_uh.py \
      --replace-fail "'/app/share'," "'${placeholder "out"}/share', '/app/share',"

    # setup.py runs `git describe` for the version and falls back to this
    # file. Only the shape matters; it has to parse as PEP 440.
    echo -n "2019.1-0-g${builtins.substring 0 8 finalAttrs.src.rev}" > content/packages/gitversion.txt
  '';

  build-system = with python3Packages; [ setuptools ];

  nativeBuildInputs = [
    gettext
    intltool
    # Atlas generation writes to $HOME.
    writableTmpDirAsHomeHook
  ];

  dependencies = with python3Packages; [
    distro
    fifengine
    pillow
    pyyaml
  ];

  # No test suite that runs without a display.
  doCheck = false;

  meta = {
    description = "2D realtime strategy simulation with an emphasis on economy and city building";
    homepage = "https://unknown-horizons.org/";
    license = lib.licenses.gpl2Plus;
    mainProgram = "unknown-horizons";
    maintainers = with lib.maintainers; [ FlorianFranzen ];
    platforms = lib.platforms.linux;
  };
})
