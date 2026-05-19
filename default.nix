let
  sources = import ./npins;
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

        urweb-with-deps = final.urweb.withLibraries [
          final.urweb-curl
        ];

        build = final.callPackage ./package.nix {
          gitRev = final.lib.sources.commitIdFromGitRepo ./.;
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
    ];
  };
  myPackages = pkgs.myPackages;
}
