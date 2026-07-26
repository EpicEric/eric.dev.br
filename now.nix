{ runner, ... }:
{
  jobs = {
    build = {
      steps = [
        (runner.steps.upload "website" (import ./. { }))
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
              SSH_HOST = runner.secret "SSH_HOST";
            };
            run = ''
              rsync --delete-after -acP $WEBSITE/ $SSH_HOST:www
            '';
            path = [
              pkgs.rsync
            ];
          }
        ];
      };
  };
}
