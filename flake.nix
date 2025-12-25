{
  description = "My personal static website";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        flakedPkgs = pkgs;
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bun
          ];
        };
      }
    );
}
