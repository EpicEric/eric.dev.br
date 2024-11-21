# eric.dev.br

My personal static website, built from scratch with Astro. Currently work-in-progress.

## Development server

```bash
npm run dev
```

## Other development commands

```bash
npm run sync
npm run prettier
```

## Build and deploy

```bash
npm run build
```

SSG files are built to `dist/`. TO deploy with LFTP, create a `.env` file at the root of the project:

```env
DEPLOY_LFTP_HOST=https://example-webdav-server.com
DEPLOY_LFTP_USER=example_user
DEPLOY_LFTP_PASSWORD=sup3r_s3cr3t_password
DEPLOY_LFTP_TARGETFOLDER=sites/badmanners.xyz/
```

Then run `npm run deploy-lftp`.
