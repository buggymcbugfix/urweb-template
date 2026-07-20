let
  sources = import ./npins;

  CMD_PREFIX = ",";

  CMD_BUILD = "${CMD_PREFIX}build";
  CMD_DB = "${CMD_PREFIX}db";
  CMD_DB_RECREATE = "${CMD_PREFIX}db-recreate";
  CMD_GO = "${CMD_PREFIX}go";
  CMD_RUN = "${CMD_PREFIX}run";
  CMD_STOP = "${CMD_PREFIX}stop";
  CMD_WATCH = "${CMD_PREFIX}watch";
  CMD_HELP = "${CMD_PREFIX}help";

  RED = "\\033[31m";
  GREEN = "\\033[32m";
  BOLD = "\\033[1m";
  RESET = "\\033[0m";
in
{
  system ? builtins.currentSystem,
  nixpkgs ? sources.nixpkgs,
}:
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
          doCheck = false; # borked tests, take AGES to run
        });

        build = final.callPackage ./package.nix {
          gitRev = final.lib.sources.commitIdFromGitRepo ./.git; # can't track clean vs dirty
        };
      };
    in
    myPackages
    // {
      inherit myPackages;
    };
  pkgs = import nixpkgs {
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

      ${CMD_STOP}() {
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
        ${CMD_STOP}
      }

      trap cleanup EXIT INT TERM

      ${CMD_BUILD}() {
        printf "Building main.exe...\n"
        urweb main -dbms sqlite -db "$testDb" -endpoints endpoints.json \
          && printf "${GREEN}ok${RESET}\n"
      }

      ${CMD_DB}() {
        sqlite3 "$testDb" -cmd '.headers on' -cmd 'PRAGMA foreign_keys = ON' "$@"
      }

      ${CMD_DB_RECREATE}() {
        printf "Recreating DB at '%s'\n" "$testDb"
        rm -f "$testDb" "$testDb"-shm "$testDb"-wal
        printf "Slurping ${BOLD}db/generated.sql${RESET}...\n"
        sqlite3 "$testDb" < db/generated.sql
        printf "Slurping ${BOLD}db/triggers.sql${RESET}...\n"
        sqlite3 "$testDb" < db/triggers.sql
        printf "Slurping ${BOLD}db/test-data.sql${RESET}...\n"
        sqlite3 "$testDb" < db/test-data.sql
      }

      ${CMD_RUN}() {
        if ${CMD_RUN}; then
          ${CMD_STOP}
          if [ ! -f $testDb ]; then
            ${CMD_DB_RECREATE}
          fi
          logfile="$(mktemp)"
          logfiles+=("$logfile")
          printf 'Launching app...\n'
          date +"%Y-%m-%d %H:%M:%S" >>"$logfile"
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

      ${CMD_GO}() {
        ${CMD_RUN} && xdg-open "http://localhost:$port"
      }

      ${CMD_HELP}() {
        printf '${BOLD}${CMD_BUILD}${RESET}\n\tBuild the application.\n'
        printf '${BOLD}${CMD_DB}${RESET}\n\tLaunch the sqlite3 cli for the test database.\n'
        printf '${BOLD}${CMD_DB_RECREATE}${RESET}\n\tRecreate the test database.\n'
        printf '${BOLD}${CMD_GO}${RESET}\n\tRun the application and launch browser.\n'
        printf '${BOLD}${CMD_RUN}${RESET}\n\tRun the application.\n'
        printf '${BOLD}${CMD_STOP}${RESET}\n\tKill the running background server.\n'
        printf '${BOLD}${CMD_WATCH}${RESET}\n\tRebuild and rerun the server on change of Ur/Web files.\n'
      }

      ${CMD_WATCH}() {
        ${CMD_RUN}
        while read -r _; do
          ${CMD_RUN}
        done < <(fswatch -o -r -l 0.3 -e '.*' -i '\.ur$' -i '\.urs$' -i '\.urp$' .)
      }

      set +eu
    '';
  };
  myPackages = pkgs.myPackages;
}
