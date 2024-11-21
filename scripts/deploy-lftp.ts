import { spawn } from "node:child_process";
import { join, normalize as n } from "node:path";
import { program, Option } from "commander";

interface DeployLftpOptions {
  host: string;
  user: string;
  password: string;
  targetFolder: string;
  sourceFolder: string;
  assetsFolder: string;
}

async function deployLftp({ host, user, password, targetFolder, sourceFolder, assetsFolder }: DeployLftpOptions) {
  const process = spawn(
    "lftp",
    [
      "-c",
      [
        `open -u ${user},${password.replaceAll(/([ \t.,:;?!`'"^|*+#&$\(\)\[\]{}<>\\/-])/g, "\\$1")} ${host}`,
        `mirror --reverse --include-glob ${join(assetsFolder, "*")} --delete --only-missing --no-perms --verbose ${n(sourceFolder)} ${n(targetFolder)}`,
        `mirror --reverse --exclude-glob ${join(assetsFolder, "*")} --delete                --no-perms --verbose ${n(sourceFolder)} ${n(targetFolder)}`,
        `bye`,
      ].join("\n"),
    ],
    {
      stdio: "inherit",
    },
  );
  await new Promise((resolve, reject) => {
    process.on("close", (code) => (code === 0 ? resolve(0) : reject(`lftp failed with code ${code}`)));
  });
}

await program
  .name("deploy-lftp")
  .description("Deploy files to remote server with LFTP")
  .addOption(
    new Option("-h, --host <hostname>", "Hostname of the LFTP (i.e. WebDav, SCP, SFTP...) remote.").env(
      "DEPLOY_LFTP_HOST",
    ),
  )
  .addOption(new Option("-u, --user <username>", "Username portion of the LFTP credentials").env("DEPLOY_LFTP_USER"))
  .addOption(
    new Option("-p, --password <pass>", "Password portion of the LFTP credentials").env("DEPLOY_LFTP_PASSWORD"),
  )
  .addOption(
    new Option("-t, --target-folder <remoteDir>", "Folder to mirror files to in the LFTP remote").env(
      "DEPLOY_LFTP_TARGETFOLDER",
    ),
  )
  .addOption(
    new Option("-s, --source-folder <localDir>", "Folder to read files from in the local machine")
      .env("DEPLOY_LFTP_SOURCEFOLDER")
      .default("dist/"),
  )
  .addOption(
    new Option("-a, --assets-folder <localDir>", "Directory inside of --source-folder of assets with hash-based names")
      .env("DEPLOY_LFTP_ASSETSFOLDER")
      .default("assets/"),
  )
  .action(deployLftp)
  .parseAsync();
