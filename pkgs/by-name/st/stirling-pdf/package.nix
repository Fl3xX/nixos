{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchNpmDeps,
  rustPlatform,

  cargo,
  cargo-tauri,
  go-task,
  gradle_9,
  makeBinaryWrapper,
  nodejs,
  npmHooks,
  pkg-config,
  python3,
  wrapGAppsHook3,

  glib-networking,
  jdk25,
  libsoup_3,
  openssl,
  webkitgtk_4_1,

  nix-update-script,
  nixosTests,

  isDesktopVariant ? false,
  withAdditionalFeatures ? !isDesktopVariant,
  buildWithFrontend ? !isDesktopVariant,
}:

# you may only toggle this when building the server
assert isDesktopVariant -> !buildWithFrontend;

let
  gradle = gradle_9;
  jre = jdk25;
  python = python3.withPackages (ps: [ ps.fonttools ]);
in
stdenv.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "stirling-pdf" + lib.optionalString isDesktopVariant "-desktop";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "Stirling-Tools";
    repo = "Stirling-PDF";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zg73mpK4wCOsT5NqX+0kCwKbs1CnyA20NV88fCzws98=";
  };

  patches = [
    # remove timestamp from the header of a generated .properties file
    ./remove-props-file-timestamp.patch

    # tests require network facilities intentionally unavailable in the Nix sandbox
    ./skip-sandbox-incompatible-tests.patch
    # Upstream corpus tests filter /build from absolute paths, hiding every fixture in Nix builds.
    ./fix-corpus-tests-in-build-directory.patch
  ];

  postPatch = lib.optionalString isDesktopVariant ''
    # Nixpkgs does not produce artifacts for Stirling-PDF's upstream updater
    # and does not have access to upstream's private signing key.
    substituteInPlace frontend/editor/src-tauri/tauri.conf.json \
      --replace-fail '"createUpdaterArtifacts": true' '"createUpdaterArtifacts": false'
  '';

  npmRoot = "frontend";

  npmDeps = fetchNpmDeps {
    name = "stirling-pdf-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src patches;
    postPatch = "cd ${finalAttrs.npmRoot}";
    hash = "sha256-Iw91rbrFw0zmB6psnAzYYqnHHFNf1FutC7pkuLrNyng=";
  };

  cargoRoot = "frontend/editor/src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      pname
      version
      src
      patches
      cargoRoot
      ;
    hash = "sha256-GlrCdshCSh7Ckd09pzovNHsUHrSROy9HrmRr8f0dETM=";
  };

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;

  env = {
    PUPPETEER_SKIP_DOWNLOAD = "1";
    DISABLE_ADDITIONAL_FEATURES = if withAdditionalFeatures then "false" else "true";
  };

  gradleFlags = [
    "-PnoSpotless" # disable spotless because it tries to fetch files not in deps.json and also because it slows down the build process
  ]
  ++ lib.optionals buildWithFrontend [ "-PbuildWithFrontend=true" ];

  doCheck = true;

  nativeBuildInputs = [
    go-task
    gradle
    jre # one of the tests also require that the `java` command is available on the command line
    makeBinaryWrapper
  ]
  ++ lib.optionals (buildWithFrontend || isDesktopVariant) [
    nodejs
    npmHooks.npmConfigHook
  ]
  ++ lib.optionals isDesktopVariant [
    cargo
    cargo-tauri.hook
    rustPlatform.cargoSetupHook
  ]
  ++ lib.optionals (isDesktopVariant && stdenv.hostPlatform.isLinux) [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = lib.optionals (isDesktopVariant && stdenv.hostPlatform.isLinux) [
    glib-networking
    libsoup_3
    openssl
    webkitgtk_4_1
  ];

  dontUseGradleBuild = isDesktopVariant; # we'll use the buildPhase from cargo-tauri-hook for the desktop app

  # prepare the resources before building the desktop app
  preBuild = lib.optionalString isDesktopVariant ''
    MODE=desktop task frontend:prepare

    # this simulates what the desktop:jlink:jar would do
    gradle bootJar
    install -Dm644 ./app/core/build/libs/stirling-pdf-*.jar -t ./frontend/editor/src-tauri/libs

    # creates as minimal jre via jlink
    task desktop:jlink:runtime

    substituteInPlace frontend/editor/src-tauri/stirling-pdf.desktop \
      --replace-fail 'MimeType=application/pdf;' 'MimeType=application/pdf;x-scheme-handler/stirlingpdf;'
  '';

  # we use the installPhase from cargo-tauri-hook when we're building the desktop variant
  installPhase = lib.optionalString (!isDesktopVariant) ''
    runHook preInstall

    install -Dm644 ./app/core/build/libs/stirling-pdf-*.jar $out/share/stirling-pdf/Stirling-PDF.jar
    install -Dm644 ./scripts/convert_cff_to_ttf.py $out/share/stirling-pdf/scripts/convert_cff_to_ttf.py
    makeWrapper ${lib.getExe jre} $out/bin/Stirling-PDF \
      --add-flags "-jar $out/share/stirling-pdf/Stirling-PDF.jar" \
      --set-default PDFEDITOR_CFFCONVERTER_PYTHONCOMMAND ${lib.getExe python} \
      --set-default PDFEDITOR_CFFCONVERTER_PYTHONSCRIPT $out/share/stirling-pdf/scripts/convert_cff_to_ttf.py

    runHook postInstall
  '';

  postInstall = ''
    install -Dm644 LICENSE $out/share/licenses/stirling-pdf/LICENSE
  ''
  + lib.optionalString withAdditionalFeatures ''
    install -Dm644 app/proprietary/LICENSE $out/share/licenses/stirling-pdf/app-proprietary-LICENSE
    install -Dm644 frontend/editor/src/proprietary/LICENSE $out/share/licenses/stirling-pdf/frontend-proprietary-LICENSE
  ''
  + lib.optionalString isDesktopVariant ''
    install -Dm644 frontend/editor/src/desktop/LICENSE $out/share/licenses/stirling-pdf/frontend-desktop-LICENSE
    install -Dm644 frontend/editor/src/proprietary/LICENSE $out/share/licenses/stirling-pdf/frontend-proprietary-LICENSE
  ''
  + lib.optionalString (isDesktopVariant && stdenv.hostPlatform.isDarwin) ''
    makeWrapper "$out/Applications/Stirling PDF.app/Contents/MacOS/Stirling-PDF" "$out/bin/stirling-pdf"
  '';

  passthru = {
    tests = {
      inherit (nixosTests) stirling-pdf-desktop; # TODO: fix or remove
    }
    // lib.optionalAttrs (!isDesktopVariant) {
      inherit (nixosTests) stirling-pdf;
    };
  }
  // lib.optionalAttrs (!isDesktopVariant) {
    # this being optional makes the auto-update PRs always put stirling-pdf in the title
    updateScript = nix-update-script { };
  };

  meta = {
    changelog = "https://github.com/Stirling-Tools/Stirling-PDF/releases/tag/v${finalAttrs.version}";
    description =
      "PDF editing platform "
      + (if isDesktopVariant then "runnable as a desktop app" else "hostable as a web app");
    homepage = "https://github.com/Stirling-Tools/Stirling-PDF";
    license =
      if withAdditionalFeatures || isDesktopVariant then
        [
          lib.licenses.mit
          lib.licenses.unfree
        ]
      else
        lib.licenses.mit;
    mainProgram = "Stirling-PDF";
    maintainers = with lib.maintainers; [
      tomasajt
      staticdev
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # java deps
      binaryNativeCode # bundled jpdfium inside jar
    ];
  };
})
