import { defineConfig } from "vite";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["**/e2e/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"],
    exclude: [
      "**/node_modules/**",
      "**/dist/**",
      "**/cypress/**",
      "**/.{idea,git,cache,output,temp}/**",
    ],
    browser: {
      enabled: true,
      name: "chromium",
      provider: "playwright",
      headless: true,
    },
  },
});
