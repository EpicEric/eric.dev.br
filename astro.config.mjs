import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

import alpinejs from "@astrojs/alpinejs";

export default defineConfig({
  site: "https://eric.dev.br",
  integrations: [alpinejs()],
  build: {
    assets: "assets",
  },
  outDir: "./dist",
  vite: {
    plugins: [tailwindcss()],
  },
});
