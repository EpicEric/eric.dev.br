{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  pkgs ? import sources.nixpkgs { inherit system; },
}:
let
  inherit (pkgs) lib;
in
pkgs.buildNpmPackage {
  name = "eric-dev-br";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./astro.config.mjs
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

  inherit (pkgs.importNpmLock) npmConfigHook;

  makeCacheWritable = true;

  ASTRO_TELEMETRY_DISABLED = "1";

  installPhase = ''
    cp -r dist/ $out
  '';
}
