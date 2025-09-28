import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  site: "https://eric.dev.br",
  integrations: [],
  build: {
    assets: "assets",
  },
  outDir: "./dist",
  vite: {
    plugins: [tailwindcss()],
  },
});
