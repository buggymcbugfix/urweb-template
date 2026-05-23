- For development: `nix-shell` or https://github.com/direnv/direnv
- For building: `nix-build` (build defined in ./package.nix)
- Building other packages: `nix-build -A myPackages.<TAB>`
- Updating dependencies: `npins update`
- For flake-users: https://github.com/NixOS/flake-compat


# Development

```
nix-shell --pure
```


# TODO

- Npins version 5 vs 7: nix-shell?
- Fix mlton
- nix formatter
- `________placeholder_for_git_hash________`
- shellHook works weird with direnv
- urweb-with-libs vs urweb-with-deps
- xdg-open
