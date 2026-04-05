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
            bun
            tailwindcss_4
          ];

          shellHook = ''
            export PATH="$PWD:$PATH"
            echo "Dev shell active."
            echo "Gleam version: $(gleam --version)"
          '';
        };
      }
    );
}
