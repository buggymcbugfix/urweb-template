- Building other packages: 
- Updating dependencies: `npins update`
- For flake-users: https://github.com/NixOS/flake-compat

# Building

The build process for this web app is defined in [package.nix](./package.nix). All you need to do is run this command:

~~~
nix-build
~~~

TODO.

## Dependencies
TODO.

### Building
`nix-build -A myPackages.<TAB>`
TODO.

### Updating Dependencies
TODO.

# Development

To develop the app, when you run `nix-shell` in your terminal,
you get a bash prompt with *development commands* for building and launching
the application, including the database. Nix takes care of setting up all
necessary dependencies with precisely defined versions. To exit the Nix shell,
run `exit` or hit `ctrl-d`.

**Development commands** begin with `,`. Example workflow

~~~
nix-shell
,go    # build the app and open it in your browser
,help  # list available development commands
,run   # rebuild the app and launch it (any previous instance gets killed)
~~~

The development commands are carefully designed to be well-behaved.
Whenever you close or exit the Nix shell, all resources are cleaned up.

<details>
<summary>

## Development Command Reference
</summary>

### `,build`
Builds the app.

### `,db`
Launches the SQLite command-line-interface for the test database.

### `,db-recreate`
Recreates the DB from scratch, wiping all existing data.

### `,go`
Calls `,run` and opens the app in your browser. 

### `,help`
Prints a summary of available development commands.

### `,run`
Runs the server, such that it listens on the first available port between 8000 and 9000, sending logs to a logfile.

Automatically does the following:

- (re)builds the server executable via `,build`
- if not already available, creates the database via `,db-recreate`

</details>


# Backstory

## How this template was set up

~~~
# we need the npins version to match 
nix-shell -p npins -I nixpkgs=channel:nixos-25.11
npins init --bare
npins add channel nixos-25.11 --name nixpkgs
npins add github buggymcbugfix urweb --branch nix
npins add github buggymcbugfix urweb-curl --branch master # uses release tags by default
~~~
