{ runner, ... }:
{
  inherit (import ./.tack) nixpkgs;

  jobs = {
    cv = {
      steps = [
        (runner.steps.upload {
          name = "cv";
          deriv = import ./nix/cv { };
        })
        {
          env.CV_DIR = runner.download "cv";
          run = ''
            cp $CV_DIR/* public/
          '';
        }
      ];
    };

    build = {
      steps = [
        (runner.steps.upload {
          name = "website";
          deriv = import ./. { };
        })
      ];
    };

    publish =
      { pkgs, ... }:
      {
        needs = [ "build" ];
        steps = [
          {
            env = {
              WEBSITE = runner.download "website";
              WEBSITE_HOST = runner.secret "WEBSITE_HOST";
            };
            path = [ pkgs.rsync ];
            run = ''
              rsync --delete-after -acP $WEBSITE/ $WEBSITE_HOST:www
            '';
          }
        ];
      };
  };
}
