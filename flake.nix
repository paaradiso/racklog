{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gleam
            erlang
            rebar3
            nodejs
            prettierd
            tailwindcss_4
            bruno

            postgresql
            pgformatter
            (writeShellScriptBin "pg-stop" ''pg_ctl stop -D "$PGDATA" -m fast'')
            (writeShellScriptBin "pg-start" ''pg_ctl start -D "$PGDATA" -l "$PGHOST/postgres.log"'')
            (writeShellScriptBin "pg-status" ''pg_ctl status -D "$PGDATA"'')
            (writeShellScriptBin "pg-logs" ''tail -f "$PGHOST/postgres.log"'')
          ];

          shellHook = ''
            export PGDATA="$PWD/.pg/data"
            export PGHOST="$PWD/.pg"
            export PGPORT=5432
            export PGDATABASE="racklog_dev"
            export DATABASE_URL="postgres://$USER@localhost:$PGPORT/$PGDATABASE"

            if [ ! -d "$PGDATA" ]; then
              initdb --no-locale --encoding=UTF8 -D "$PGDATA" --auth=trust > /dev/null
              echo "unix_socket_directories = '$PGHOST'" >> "$PGDATA/postgresql.conf"
              mkdir -p "$PGHOST"
              pg_ctl start -D "$PGDATA" -l "$PGHOST/postgres.log"
              createdb "$PGDATABASE"
            fi

            if ! pg_ctl status -D "$PGDATA" > /dev/null 2>&1; then
              mkdir -p "$PGHOST"
              pg_ctl start -D "$PGDATA" -l "$PGHOST/postgres.log"
            fi

            echo "Postgres running on port $PGPORT, database: $PGDATABASE"
            echo "Dev shell active. Gleam version: $(gleam --version)"
            echo "Available commands: pg-start, pg-stop, pg-status, pg-logs"
          '';
        };
      }
    );
}
