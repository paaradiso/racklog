import { defineConfig } from "vite";
import gleam from "vite-plugin-gleam";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [gleam(), tailwindcss()],
});
