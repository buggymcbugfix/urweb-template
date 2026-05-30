{
  curl,
  lib,
  stdenv,
  sqlite,
  urweb-with-libs,

  # Non-package arguments
  gitRev,
}:
let
  APP_NAME = "hello-urweb";
in
let
  TESTDB = "/tmp/__test_${APP_NAME}.sql"; # meh
in
stdenv.mkDerivation {
  pname = APP_NAME;
  version = "0.0.0";

  src = lib.fileset.toSource rec {
    root = ./.;
    fileset = lib.fileset.intersection (lib.fileset.gitTracked root) (
      lib.fileset.unions [
        (root + /db)
        (root + /main.ur)
        (root + /main.urp)
        (root + /main.urs)
        (root + /src)
        (root + /test)
      ]
    );
  };

  configurePhase = ''
    substituteInPlace ./main.ur --replace-fail '@GIT_REV@' '${gitRev}'
  '';

  nativeBuildInputs = [
    urweb-with-libs
  ];

  buildPhase = ''
    urweb ./main -dbms sqlite -db ${TESTDB} -endpoints endpoints.json
  '';

  nativeCheckInputs = [
    curl
    sqlite # needed again here?
  ];

  doCheck = false; # TODO: Fix TESTDB situation

  checkPhase = ''
      pid=""

      cleanup() {
        kill $pid 2>/dev/null || true
        pid=""
        rm -f ${TESTDB} ${TESTDB}-shm ${TESTDB}-wal
      }

      trap cleanup EXIT INT TERM

      setup() {
        rm -f ${TESTDB} 2>/dev/null
        sqlite3 ${TESTDB} < db/generated.sql
      }

      setup
      eval "$(./main.exe -a 127.0.0.1 -p 8000 -P 9000 -d3 3>&1 1>&2)"
      [ "$status" = 'OK' ] || { echo "${APP_NAME} failed to start" >&2; exit 1; }
    	curl -s "http://localhost:$port/Main/hello/World.21" | diff test/index.expected.html -
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ./main.exe $out/bin/${APP_NAME}
    cp endpoints.json $out/endpoints.json
  '';
}
