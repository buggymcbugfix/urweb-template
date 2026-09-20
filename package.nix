{
  hurl,
  lib,
  nginx,
  runtimeShell,
  spawn_fcgi,
  sqlite,
  stdenv,
  urweb-with-libs,
}:
let
  APP_NAME = import ./name.nix;
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

  # FastCGI: the binary accepts connections on fd 0 and is meant to run
  # behind nginx (see module.nix). The dev shell builds the http variant.
  buildPhase = ''
    urweb ./main -protocol fastcgi -dbms sqlite -db ${APP_NAME}.db -endpoints endpoints.json
  '';

  nativeCheckInputs = [
    hurl
    nginx
    spawn_fcgi
    sqlite
  ];

  doCheck = true;

  __darwinAllowLocalNetworking = true;

  # Runs the built binary the way it is deployed: behind nginx, over FastCGI,
  # and drives it with test/smoke.hurl. spawn-fcgi stands in for systemd's
  # socket activation, over TCP rather than a Unix socket (which is what the
  # module uses, and what the NixOS VM test covers): in the darwin build
  # sandbox, binding a Unix socket in the build directory leaves no file
  # behind, and spawn-fcgi dies on the chmod that follows. On darwin the two
  # ports are the build host's, so they can collide with something else on the
  # machine; the check says so when they do.
  checkPhase = ''
    runHook preCheck

    tmp="$(mktemp -d)"
    db="$tmp/test.db"
    sqlite3 "$db" < db/generated.sql

    pids=()
    cleanup() {
      kill "''${pids[@]}" 2>/dev/null || true
      wait 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM

    httpPort=8080
    fcgiPort=9000

    URWEB_SQLITE_DB_PATH="$db" \
      spawn-fcgi -n -a 127.0.0.1 -p "$fcgiPort" -- ./main.exe -t 2 \
      >"$tmp/app.log" 2>&1 &
    pids+=($!)

    appUp() { (exec 3<>/dev/tcp/127.0.0.1/"$fcgiPort") 2>/dev/null; }

    # Without this the application's absence only shows up as nginx 502s and
    # hurl retries, with the reason buried further up the build log.
    for _ in $(seq 100); do
      appUp && break
      kill -0 "''${pids[0]}" 2>/dev/null || break
      sleep 0.1
    done
    if ! appUp; then
      echo "checkPhase: nothing is listening on 127.0.0.1:$fcgiPort." >&2
      cat "$tmp/app.log" >&2
      exit 1
    fi

    cat > "$tmp/nginx.conf" <<EOF
    daemon off;
    pid $tmp/nginx.pid;
    error_log stderr warn;
    events { }
    http {
      access_log off;
      client_body_temp_path $tmp/client_body;
      proxy_temp_path $tmp/proxy;
      fastcgi_temp_path $tmp/fastcgi;
      uwsgi_temp_path $tmp/uwsgi;
      scgi_temp_path $tmp/scgi;
      server {
        listen 127.0.0.1:$httpPort;
        location / {
          include ${nginx}/conf/fastcgi_params;
          fastcgi_pass 127.0.0.1:$fcgiPort;
        }
      }
    }
    EOF
    nginx -c "$tmp/nginx.conf" -p "$tmp" &
    pids+=($!)

    # --retry covers nginx's startup.
    if ! hurl --test --retry 20 --retry-interval 250 \
      --variable base=http://127.0.0.1:"$httpPort" test/smoke.hurl; then
      echo "checkPhase: application log follows." >&2
      cat "$tmp/app.log" >&2
      exit 1
    fi

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/${APP_NAME}/db
    cp ./main.exe $out/bin/${APP_NAME}
    cp endpoints.json $out/endpoints.json
    cp db/generated.sql $out/share/${APP_NAME}/db/
    cp test/smoke.hurl test/index.expected.html $out/share/${APP_NAME}/

    # Smoke test for a running deployment; same checks as checkPhase.
    cat > $out/bin/${APP_NAME}-smoke <<'EOF'
    #!${runtimeShell}
    # Usage: ${APP_NAME}-smoke BASE_URL [hurl options...]
    # e.g.   ${APP_NAME}-smoke https://app.example.org --user alice:secret
    set -eu
    base="''${1:?usage: ${APP_NAME}-smoke BASE_URL [hurl options...]}"
    shift
    exec ${hurl}/bin/hurl --test --variable base="$base" "$@" ${placeholder "out"}/share/${APP_NAME}/smoke.hurl
    EOF
    chmod +x $out/bin/${APP_NAME}-smoke

    runHook postInstall
  '';
}
