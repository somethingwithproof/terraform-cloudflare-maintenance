import { cloudflareTest } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    projects: [
      {
        // Worker tests run inside workerd with the bindings from wrangler.json.
        plugins: [
          cloudflareTest({
            wrangler: { configPath: "./wrangler.json" },
            miniflare: {
              // Stands in for the origin behind the route.
              outboundService: () => new Response("Origin response"),
            },
          }),
        ],
        test: { name: "worker", include: ["test/worker/**/*.test.ts"] },
      },
      {
        // Shell scripts the Worker's operators run, tested with Node.
        test: { name: "scripts", include: ["test/scripts/**/*.test.ts"], environment: "node" },
      },
    ],
    coverage: {
      provider: "istanbul",
      include: ["src/**/*.ts"],
      reporter: ["text", "lcov"],
    },
  },
});
