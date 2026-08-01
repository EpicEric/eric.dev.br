{
  inputs ? import ../../.tack,
  system ? builtins.currentSystem,
  pkgs ? import inputs.nixpkgs { inherit system; },
}:
let

  inherit (pkgs) lib;

  cv-pdf-dist = pkgs.buildNpmPackage {
    name = "cv-pdf-dist";

    src = lib.fileset.toSource {
      root = ../..;
      fileset = lib.fileset.unions [
        ../../astro.config.mjs
        ../../package.json
        ../../package-lock.json
        ../../tsconfig.json
        ../../src
      ];
    };

    npmDeps = pkgs.importNpmLock {
      npmRoot = ../..;
    };

    npmConfigHook = pkgs.importNpmLock.npmConfigHook;

    makeCacheWritable = true;

    env = {
      ASTRO_TELEMETRY_DISABLED = "1";
      RENDER_CV_PAGES = "true";
    };

    installPhase = ''
      mkdir -p $out
      cp -r ./dist/* $out
    '';
  };
in
pkgs.runCommand "cv-pdf"
  {
    nativeBuildInputs = [
      pkgs.netcat
      pkgs.puppeteer-cli
      pkgs.python3
      pkgs.writableTmpDirAsHomeHook
    ];
  }
  ''
    while
      port=$(shuf -n 1 -i 49152-65535)
      nc -z localhost $port 2>/dev/null
    do
      continue
    done

    python3 -m http.server $port --directory ${cv-pdf-dist} &
    DEV_PID=$!
    for i in {1..30}; do
      if nc -z localhost $port 2>/dev/null; then
        break
      fi
      echo "Waiting for server... ($i/30)"
      sleep 0.5
    done

    export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
    export PUPPETEER_EXECUTABLE_PATH=${lib.getExe pkgs.chromium}
    export FONTCONFIG_FILE=${
      pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.open-sans
        ];
      }
    }

    mkdir -p $out
    puppeteer print --format A4 http://localhost:$port/cv/pt $out/CV_pt.pdf
    puppeteer print --format A4 http://localhost:$port/cv/en $out/CV_en.pdf

    kill $DEV_PID || true
  ''
