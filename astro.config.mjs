import { defineConfig } from "astro/config";
import tailwindIntegration from "@astrojs/tailwind";

// https://astro.build/config
export default defineConfig({
  site: "https://eric.dev.br",
  integrations: [
    tailwindIntegration({
      applyBaseStyles: false,
    }),
  ],
  build: {
    assets: "assets",
  },
  outDir: "./dist",
});
