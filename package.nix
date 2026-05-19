{
  lib,
  stdenv,
  cacert,
  urweb-with-deps,
  hello,

  # Non-package arguments
  gitRev,
}:
builtins.seq (stdenv.mkDerivation {
  pname = "urweb-test";
  version = "0.0.1";

  src = lib.fileset.toSource rec {
    root = ./.;
    fileset = lib.fileset.intersection (lib.fileset.gitTracked root) (
      lib.fileset.unions [
        (root + /ur)
      ]
    );
  };

  buildInputs = [
    # TODO: Needed?
    cacert
  ];

  configurePhase = ''
    substituteInPlace ur/lib/Constants.ur --replace-fail '@GIT_REV@' '${gitRev}'
  '';

  buildPhase = ''
    ${lib.getExe urweb-with-deps} ur/TODO
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ur/TODO.exe $out/bin/TODO
  '';
}) hello
