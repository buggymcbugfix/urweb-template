let
  sources = import ./npins;

  CMD_PREFIX = ",";

  RED = "\\033[31m";
  GREEN = "\\033[32m";
  BOLD = "\\033[1m";
  RESET = "\\033[0m";
in
{
  system ? builtins.currentSystem,
  nixpkgs ? sources.nixpkgs,
  # An already evaluated nixpkgs to build against instead of the pinned one,
  # e.g. from a NixOS configuration: `import sources.<name> { inherit pkgs; }`.
  # Its config and overlays are kept; ours is added on top.
  pkgs ? null,
}@args:
let
  overlay =
    final: prev:
    let
      myPackages = {
        urweb = import sources.urweb {
          # Not using pinned urweb Nixpkgs
          pkgs = final;
        };

        urweb-with-libs = final.urweb.withLibraries {
          urweb-curl = final.callPackage sources.urweb-curl { };
        };

        mlton20210117 = prev.mlton20210117.overrideAttrs (old: {
          doCheck = !prev.stdenv.hostPlatform.isDarwin;
        });

        build = final.callPackage ./package.nix { };
      };
    in
    myPackages
    // {
      inherit myPackages;
    };
  # `args` holds only the arguments actually passed, not defaults.
  pkgs =
    if (args.pkgs or null) != null then
      args.pkgs.extend overlay
    else
      import nixpkgs {
        inherit system;
        config = { };
        overlays = [ overlay ];
      };

in
pkgs.myPackages.build
// {
  shell = pkgs.mkShell {
    inputsFrom = [ pkgs.myPackages.build ];
    packages = with pkgs; [
      fswatch
      git # ,run reads the revision to pass to the app
      nixfmt-tree
      npins
      sqlite-interactive
      xdg-utils
    ];
    shellHook = ''
      set -eu

      pid=""
      port=""
      status=""
      logfiles=()
      testDb='db/test.db'

      ${CMD_PREFIX}stop() {
        if [ -n "$pid" ]; then
          printf 'Shutting down server process %s...\n' "$pid"
          if kill "$pid" 2>/dev/null; then
            wait "$pid" 2>/dev/null
            printf "${GREEN}ok${RESET}\n"
          else
            printf 'Oops, process %s already dead.\n' "$pid"
          fi
          pid=""
        fi
        status=""
      }

      cleanup() {
        rm -f "''${logfiles[@]}"
        ${CMD_PREFIX}stop
      }

      trap cleanup EXIT INT TERM

      ${CMD_PREFIX}build() {
        printf "Building main.exe...\n"
        urweb main -dbms sqlite -db "$testDb" -endpoints endpoints.json \
          && printf "${GREEN}ok${RESET}\n"
      }

      ${CMD_PREFIX}db() {
        sqlite3 "$testDb" -cmd '.headers on' -cmd 'PRAGMA foreign_keys = ON' "$@"
      }

      ${CMD_PREFIX}db-recreate() {
        printf "Recreating DB at '%s'\n" "$testDb"
        rm -f "$testDb" "$testDb"-shm "$testDb"-wal
        printf "Slurping ${BOLD}db/generated.sql${RESET}...\n"
        sqlite3 "$testDb" < db/generated.sql
        printf "Slurping ${BOLD}db/triggers.sql${RESET}...\n"
        sqlite3 "$testDb" < db/triggers.sql
        printf "Slurping ${BOLD}db/test-data.sql${RESET}...\n"
        sqlite3 "$testDb" < db/test-data.sql
      }

      ${CMD_PREFIX}run() {
        if ${CMD_PREFIX}build; then
          ${CMD_PREFIX}stop
          if [ ! -f $testDb ]; then
            ${CMD_PREFIX}db-recreate
          fi
          logfile="$(mktemp)"
          logfiles+=("$logfile")
          printf 'Launching app...\n'
          date +"%Y-%m-%d %H:%M:%S" >>"$logfile"
          export GIT_REV="$(git describe --always --dirty 2>/dev/null || echo unknown)"
          eval "$(./main.exe -a 127.0.0.1 -p 8000 -P 9000 -d3 3>&1 1>>"$logfile" 2>>"$logfile")"
          if [ "$status" = 'OK' ]; then
            printf 'pid = %s\n' "$pid"
            printf 'port = %s\n' "$port"
            printf "Logging to '$logfile'\n"
            printf 'http://localhost:%s\n' "$port"
          else
            printf "${RED}main.exe failed to start${RESET}\n" >&2
            cat "$logfile"
            return
          fi
        else
          return 1
        fi
      }

      ${CMD_PREFIX}go() {
        ${CMD_PREFIX}run && xdg-open "http://localhost:$port"
      }

      ${CMD_PREFIX}help() {
        printf '${CMD_PREFIX}build        Build the application.\n'
        printf '${CMD_PREFIX}db           Launch the sqlite3 cli for the test database.\n'
        printf '${CMD_PREFIX}db-recreate  Recreate the test database.\n'
        printf '${CMD_PREFIX}go           Run the application and launch browser.\n'
        printf '${CMD_PREFIX}run          Run the application.\n'
        printf '${CMD_PREFIX}stop         Kill the running background server.\n'
        printf '${CMD_PREFIX}watch        Rebuild and rerun the server on change of Ur/Web files.\n'
      }

      ${CMD_PREFIX}watch() {
        ${CMD_PREFIX}run
        while read -r _; do
          ${CMD_PREFIX}run
        done < <(fswatch -o -r -l 0.3 -e '.*' -i '\.ur$' -i '\.urs$' -i '\.urp$' .)
      }

      set +eu
    '';
  };
  myPackages = pkgs.myPackages;
}
