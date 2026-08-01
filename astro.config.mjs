import { defineConfig, envField } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import alpinejs from "@astrojs/alpinejs";

export default defineConfig({
  site: "https://eric.dev.br",
  integrations: [alpinejs({ entrypoint: "/src/alpine_entrypoint" })],
  build: {
    assets: "assets",
  },
  outDir: "./dist",
  vite: {
    plugins: [tailwindcss()],
  },
  env: {
    schema: {
      RENDER_CV_PAGES: envField.boolean({ context: "server", access: "public", default: false }),
    },
  }
});
