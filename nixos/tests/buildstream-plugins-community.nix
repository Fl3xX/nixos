{ pkgs, lib, ... }:
let
  bstPluginsCommunity = pkgs.python3Packages.buildstream-plugins-community;

  # These reach out to gitlab.com to download real files (bazel manifest
  # fetches, git-lfs test repo), which isn't possible in this VM either.
  deselectedTests = [
    "tests/sources/bazel.py::test_basic"
    "tests/sources/bazel.py::test_multi_url"
    "tests/sources/bazel_file.py::test_basic"
    "tests/sources/bazel_file.py::test_multi_url"
    "tests/sources/git_tag.py::test_gitlfs"
    "tests/sources/git_tag.py::test_gitlfs_off"
    "tests/sources/git_tag.py::test_gitlfs_notset"

    # These are the shared repo-kind tests that `tests/conftest.py` pulls in
    # from `buildstream._testing._sourcetests` via `sourcetests_collection_hook`.
    # Their datafiles fixtures are project templates bundled inside the
    # already-installed (and therefore read-only, per the Nix store)
    # `buildstream` package; `pytest-datafiles` copies them with
    # `shutil.copytree`/`copy`, which preserve the source's (missing) write
    # bit, so code that writes into the copy (e.g. `add_plugins_conf`'s
    # atomic yaml dump) fails with `PermissionError`. This isn't specific to
    # the Nix build sandbox, so it still applies here.
    "build_checkout.py::test_fetch_build_checkout"
    "fetch.py::test_fetch"
    "fetch.py::test_fetch_cross_junction"
    "mirror.py::test_mirror_fetch"
    "mirror.py::test_mirror_fetch_upstream_absent"
    "mirror.py::test_mirror_from_includes"
    "mirror.py::test_mirror_track_upstream_present"
    "mirror.py::test_mirror_track_upstream_absent"
    "track.py::test_track"
    "track.py::test_track_recurse"
    "track.py::test_track_recurse_except"
    "track.py::test_cross_junction"
    "track.py::test_track_include"
    "track.py::test_track_include_junction"
    "track.py::test_track_junction_included"
    "workspace.py::test_open"
  ];

  # `buildstream`'s own `bst` entry point bakes its dependencies' site-packages
  # directories directly into that script (via `site.addsitedir`), rather than
  # exposing them under `${buildstream}/${python3.sitePackages}`; `toPythonModule`
  # is needed to pull `buildstream` and its dependencies into a shared
  # environment that `pytest` can import from.
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      (ps.toPythonModule pkgs.buildstream)
      bstPluginsCommunity
      pytest
      pytest-datafiles
      pytest-env
      pytest-xdist
      pyftpdlib
    ]
  );
in
{
  name = "buildstream-plugins-community";

  meta.maintainers = with pkgs.lib.maintainers; [ shymega ];

  nodes.machine =
    { pkgs, ... }:
    {
      # buildbox-casd finds `buildbox-fuse` on PATH and defaults to real
      # FUSE-based staging, which needs `/dev/fuse` and a working mount
      # path that the Nix build sandbox can't provide. Running here as a
      # VM test instead exercises the real FUSE-backed path.
      programs.fuse.enable = true;

      environment.systemPackages = [
        pythonEnv
        pkgs.buildbox
        pkgs.gitMinimal
        pkgs.ostree
      ];
    };

  testScript = ''
    machine.succeed("cp -r ${bstPluginsCommunity.src} /tmp/src && chmod -R u+w /tmp/src")
    machine.succeed(
        "cd /tmp/src && HOME=/root ${pythonEnv}/bin/pytest"
        + " ${lib.concatStringsSep " " (map (t: "--deselect=${t}") deselectedTests)}"
    )
  '';
}
