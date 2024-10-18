import { defineWorkspace } from "vitest/config";

export default defineWorkspace([
  {
    extends: "./vitest.config.js",
    name: "unit",
  },
  {
    extends: "./vitest.e2e.config.js",
    name: "e2e",
  },
]);
