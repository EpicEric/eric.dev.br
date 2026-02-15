{
  system ? builtins.currentSystem,
}:
let
  sources = import ./npins;
  pkgs = import sources.nixpkgs { inherit system; };
  inherit (pkgs) lib;
in
pkgs.buildNpmPackage {
  name = "eric-dev-br";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./bun.lock
      ./package.json
      ./package-lock.json
      ./tsconfig.json
      ./public
      ./src
    ];
  };

  npmDeps = pkgs.importNpmLock {
    npmRoot = ./.;
  };

  npmConfigHook = pkgs.importNpmLock.npmConfigHook;

  makeCacheWritable = true;

  installPhase = ''
    mkdir -p $out
    cp -r ./dist/* $out
  '';
}
