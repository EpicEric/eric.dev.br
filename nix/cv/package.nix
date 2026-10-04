{
  chromium,
  lib,
  makeFontsConf,
  netcat,
  open-sans,
  puppeteer-cli,
  python3,
  runCommand,
  writableTmpDirAsHomeHook,
}:
let
  cv-pdf-dist = (import ../.. { }).overrideAttrs {
    name = "cv-pdf-dist";
    env = {
      ASTRO_TELEMETRY_DISABLED = "1";
      RENDER_CV_PAGES = "true";
    };
  };
in
runCommand "cv-pdf"
  {
    nativeBuildInputs = [
      netcat
      puppeteer-cli
      python3
      writableTmpDirAsHomeHook
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
    export PUPPETEER_EXECUTABLE_PATH=${lib.getExe chromium}
    export FONTCONFIG_FILE=${
      makeFontsConf {
        fontDirectories = [
          open-sans
        ];
      }
    }

    mkdir -p $out
    puppeteer print --format A4 http://localhost:$port/cv/pt $out/CV_pt.pdf
    puppeteer print --format A4 http://localhost:$port/cv/en $out/CV_en.pdf

    kill $DEV_PID || true
  ''
