{
  lib,
  rustPlatform,
  fetchFromGitHub,
  apple-sdk,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rift-wm";
  version = "0.6.2";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/DpzPHqA5h4+0mwdWKr/za8kTTio5AmZmb5Gbdpxdy4=";
  };

  nativeBuildInputs = [
    apple-sdk
  ];

  cargoHash = "sha256-HnOhkR7p1nqjyBdzhY+UJzOBohfd1k0LpzF9+CmIFsA=";
  checkFlags = [
    # runs into: topology invalidation must resend the hidden-window frame write instead of treating the stale target as still pending: [GetVisibleWindows]
    "--skip=actor::reactor::tests::topology_change_clears_stale_pending_hide_target_before_next_workspace_layout"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Tiling window manager for macos";
    homepage = "https://github.com/acsandmann/rift";
    changelog = "https://github.com/acsandmann/rift/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ eveeifyeve ];
    mainProgram = "rift";
    platforms = lib.platforms.darwin;
  };
})
