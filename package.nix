{
  curl,
  lib,
  stdenv,
  sqlite,
  urweb-with-libs,
}:
let
  APP_NAME = "hello-urweb";
  root = ./.;
  # A tarball or store copy of the repo (npins, fetchGit, flake input) has no .git dir
  tracked = if builtins.pathExists (root + "/.git") then lib.fileset.gitTracked root else root;

in
stdenv.mkDerivation {
  pname = APP_NAME;
  version = "0.0.0";

  src = lib.fileset.toSource {
    inherit root;
    fileset = lib.fileset.intersection tracked (
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

  nativeBuildInputs = [
    urweb-with-libs
  ];

  buildPhase = ''
    urweb ./main -dbms sqlite -db ${APP_NAME}.db -endpoints endpoints.json
  '';

  nativeCheckInputs = [
    curl
    sqlite # needed again here?
  ];

  doCheck = true; # TODO: Fix TESTDB situation

  checkPhase = ''
    TESTDB="$(mktemp /tmp/${APP_NAME}XXXXXX.db)"
    pid=""

    cleanup() {
      kill $pid 2>/dev/null || true
      pid=""
      rm -f $TESTDB TESTDB-shm TESTDB-wal
    }

    trap cleanup EXIT INT TERM

    setup() {
      sqlite3 $TESTDB < db/generated.sql
    }

    setup
    eval "$(URWEB_SQLITE_DB_PATH=$TESTDB ./main.exe -a 127.0.0.1 -p 8000 -P 9000 -d3 3>&1 1>&2)"
    [ "$status" = 'OK' ] || { echo "${APP_NAME} failed to start" >&2; exit 1; }
  	curl -s "http://localhost:$port/Main/hello/World.21" | diff test/index.expected.html -
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ./main.exe $out/bin/${APP_NAME}
    cp endpoints.json $out/endpoints.json
  '';
}
