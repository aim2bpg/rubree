import path from "path";

import { defineConfig } from "vite";

export default defineConfig({
  base: process.env.GITHUB_ACTIONS ? "/rubree/" : "/",
  server: {
    headers: {
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    },
  },
  optimizeDeps: {
    exclude: ["@sqlite.org/sqlite-wasm"],
  },
  build: {
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, "index.html"),
        // boot: path.resolve(__dirname, "boot.html"),
        "boot-entry": path.resolve(__dirname, "boot-entry.js"),
      },
    },
  },
  plugins: [
    {
      name: "build-service-worker",
      apply: "build",
      async closeBundle() {
        const { build } = await import("vite");
        await build({
          configFile: false,
          logLevel: "warn",
          optimizeDeps: { exclude: ["@sqlite.org/sqlite-wasm"] },
          build: {
            lib: {
              entry: path.resolve(__dirname, "rails.sw.js"),
              name: "RailsSW",
              formats: ["es"],
            },
            outDir: path.resolve(__dirname, "dist"),
            emptyOutDir: false,
            rollupOptions: {
              external: () => false,
              output: {
                entryFileNames: "rails.sw.js",
              },
            },
            codeSplitting: false,
          },
        });
      },
    },
  ],
});
