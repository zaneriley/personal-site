import { defineConfig } from "vite";

export default defineConfig({
  test: {
    globals: true,
    environment: "jsdom",
    coverage: {
      provider: "v8",
      exclude: [
        "node_modules/**",
        "dist/**",
        "**/index.js",
        "**/*.d.ts",
        "**/e2e/**",
      ],
    },
  },
});
