{
  lib,
  melpaBuild,
  fetchFromGitHub,
  macaulay2,
}:
melpaBuild (finalAttrs: {
  pname = "macaulay2";
  ename = "M2";

  # the version can't contain numbers that start with 0 (e.g. 06)
  version = "1.26.6";

  src = fetchFromGitHub {
    # since the M2-emacs repo doesn't keep tags, we use the submodule in in the
    # Macaulay2 repo, which has the correct revision pinned for the current version
    inherit (macaulay2.src) owner repo tag;
    rootDir = "M2/Macaulay2/editors/emacs";
    fetchSubmodules = true;
    hash = "sha256-8qnPzLR616Oypb6YGUm1cVj8jd1QDdeajHkVaTaEnX4=";
  };

  postPatch = ''
    substituteInPlace M2.el \
      --replace-fail 'defcustom M2-exe "M2"' 'defcustom M2-exe "${lib.getExe macaulay2}"'
  '';

  meta = {
    inherit (macaulay2.meta) maintainers platforms;
    description = "Emacs package for Macaulay2";
    homepage = "https://github.com/Macaulay2/M2-emacs";
    license = lib.licenses.gpl3Plus;
  };
})
