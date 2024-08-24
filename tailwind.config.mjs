/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["variant", "@media not print { .dark & }"],
  content: ["./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}"],
  plugins: [],
};
