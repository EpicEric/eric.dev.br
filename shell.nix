{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  pkgs ? import sources.nixpkgs { inherit system; },
}:
pkgs.mkShell {
  packages = [
    pkgs.nodejs_24
    pkgs.rsync
  ];
}
