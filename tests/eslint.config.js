import js from "@eslint/js";
import { defineConfig } from "eslint/config";
import globals from "globals";

// Bindings that Cloudflare injects into the service-worker global scope.
// They mirror the bindings list of cloudflare_workers_script in main.tf.
const workerBindings = Object.fromEntries(
  [
    "MAINTENANCE_ENABLED",
    "MAINTENANCE_TITLE",
    "MAINTENANCE_MESSAGE",
    "CONTACT_EMAIL",
    "CUSTOM_CSS",
    "LOGO_URL",
    "MAINTENANCE_WINDOW_START",
    "MAINTENANCE_WINDOW_END",
    "RETRY_AFTER",
    "ALLOWED_IPS",
    "ALLOWED_REGIONS",
  ].map((name) => [name, "readonly"]),
);

// This file lives in tests/ next to the npm tooling. `npm run lint` runs ESLint
// from the repository root with --config, so patterns are relative to the root.
export default defineConfig({
  extends: [
    { ignores: ["**/node_modules/", "**/coverage/"] },
    js.configs.recommended,
  {
    files: ["worker.js"],
    languageOptions: {
      sourceType: "script",
      globals: { ...globals.serviceworker, ...workerBindings },
    },
  },
  {
    files: ["tests/**/*.js"],
    languageOptions: {
      sourceType: "module",
      globals: { ...globals.node },
    },
  },
  ],
});
