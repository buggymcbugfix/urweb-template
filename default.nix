let
  sources = import ./npins;
  RED = "\\033[31m";
  GREEN = "\\033[32m";
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
        urweb-curl = final.callPackage sources.urweb-curl { };

        urweb-with-deps = final.urweb.withLibraries {
          inherit (final)
            urweb-curl
            ;
        };

        mlton = prev.mlton.overrideAttrs (old: {
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
      npins
      sqlite-interactive
      urweb-with-deps
    ];
    shellHook = ''
      # set -o pipefail
      set -eu
      pid=""
      port=""
      status=""
      logfile="$(mktemp)"
      testDb='test.db'

      ,stop() {
        if [ -n "$pid" ]; then
          printf 'Killing process %s... ' "$pid"
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
        ,stop
        rm -f "$logfile"
      }
      
      trap cleanup EXIT INT TERM

      ,build() {
        printf "Building main.exe... "
        ${pkgs.urweb-with-deps}/bin/urweb-with-libs main -dbms sqlite -db "$testDb" -endpoints endpoints.json \
          && printf "${GREEN}ok${RESET}\n"
      }

      ,b() {
        ,build
      }

      ,db() {
        sqlite3 "$testDb" -cmd '.headers on' -cmd 'PRAGMA foreign_keys = ON' "$@"
      }

      ,db-recreate() {
        printf "Recreating DB at '%s'\n" "$testDb"
        rm -f "$testDb" "$testDb"-shm "$testDb"-wal
        sqlite3 "$testDb" < db/generated.sql
      }

      ,run() {
        if [ ! -x main.exe ]; then
          ,build
        fi
        ,stop
        if [ ! -f $testDb ]; then
          ,db-recreate
        fi
        printf 'Launching app...\n'
        printf '**********************************************************************\n' >>"$logfile"
        date +"%Y-%m-%d %H:%M:%S" >>"$logfile"
        printf '**********************************************************************\n' >>"$logfile"
        eval "$(./main.exe -a 127.0.0.1 -p 8000 -P 9000 -d3 3>&1 1>>"$logfile" 2>>"$logfile")"
        if [ "$status" = 'OK' ]; then
          printf 'pid = %s\n' "$pid"
          printf 'port = %s\n' "$port"
          printf "Logging to '$logfile'\n"
        else
          printf "${RED}main.exe failed to start${RESET}\n" >&2
          return
        fi
      }

      ,go() {
        ,run
        url="http://localhost:$port"
        case "$(uname -s)" in
          Darwin) open "$url" ;;
          Linux)  xdg-open "$url" ;;
          *) printf '%s not supported\n' "$(uname -s)" ;;
        esac
      }

      ,help() {
        printf ',b / ,build   Build the application.\n'
        printf ',db           Launch the sqlite3 cli for the test database.\n'
        printf ',db-recreate  Recreate the test database.\n'
        printf ',go           Run the application and launch browser.\n'
        printf ',run          Run the application.\n'
        printf ',stop         Kill the running background server.\n'
      }

      help() {
        ,help
      }
      set +eu
    '';
  };
  myPackages = pkgs.myPackages;
}
