// Integration tests: requests go through the Worker's default export in
// workerd, with the bindings from wrangler.json, and requests passed through
// reach the stand-in origin configured in vitest.config.ts (no mocks).

import { env, exports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import worker, { type Env } from "../../src/index";

const hour = 3_600_000;

/** Sends a request through the default export with some bindings overridden. */
function dispatch(input: string, init: RequestInit = {}, overrides: Partial<Env> = {}): Promise<Response> {
  const request = new Request(input, init);
  return worker.fetch(request as Request<unknown, IncomingRequestCfProperties>, { ...env, ...overrides });
}

describe("with the wrangler.json bindings", () => {
  it("returns 503 with the maintenance page", async () => {
    const response = await exports.default.fetch("https://example.com/");
    expect(response.status).toBe(503);
    expect(response.headers.get("Content-Type")).toBe("text/html;charset=UTF-8");
    const body = await response.text();
    expect(body).toContain("Maintenance Mode");
    expect(body).toContain("We are currently performing scheduled maintenance.");
    expect(body).toContain("mailto:support@example.com");
  });

  it("prevents caching and says when to retry", async () => {
    const response = await exports.default.fetch("https://example.com/");
    expect(response.headers.get("Cache-Control")).toContain("no-store");
    expect(response.headers.get("Cache-Control")).toContain("no-cache");
    expect(response.headers.get("Retry-After")).toBe("3600");
  });

  it.each(["/", "/api/v1/users", "/app/dashboard/settings", "/search?q=test"])(
    "serves the page on %s",
    async (path) => {
      expect((await exports.default.fetch(`https://example.com${path}`)).status).toBe(503);
    },
  );

  it.each(["GET", "POST", "PUT", "DELETE"])("serves the page to %s requests", async (method) => {
    const init: RequestInit = { method };
    if (method === "POST" || method === "PUT") init.body = JSON.stringify({ data: "test" });
    expect((await exports.default.fetch("https://example.com/api/1", init)).status).toBe(503);
  });
});

describe("passing traffic to the origin", () => {
  it("when maintenance is disabled", async () => {
    const response = await dispatch("https://example.com/", {}, { MAINTENANCE_ENABLED: "false" });
    expect(response.status).toBe(200);
    expect(await response.text()).toBe("Origin response");
  });

  it("for allowed IPs only", async () => {
    const overrides = { ALLOWED_IPS: '["192.168.1.1", "10.0.0.1"]' };
    const from = (ip: string) => dispatch("https://example.com/", { headers: { "CF-Connecting-IP": ip } }, overrides);
    expect((await from("192.168.1.1")).status).toBe(200);
    expect((await from("1.2.3.4")).status).toBe(503);
  });

  it("for allowed regions only", async () => {
    const overrides = { ALLOWED_REGIONS: '["US", "CA"]' };
    const from = (country: string) => dispatch("https://example.com/", { cf: { country } }, overrides);
    expect((await from("US")).status).toBe(200);
    expect((await from("DE")).status).toBe(503);
  });
});

describe("maintenance window", () => {
  const windowAround = (startOffset: number, endOffset: number) => ({
    MAINTENANCE_WINDOW_START: new Date(Date.now() + startOffset).toISOString(),
    MAINTENANCE_WINDOW_END: new Date(Date.now() + endOffset).toISOString(),
  });

  it("serves the page with the expected completion inside the window", async () => {
    const response = await dispatch("https://example.com/", {}, { MAINTENANCE_ENABLED: "false", ...windowAround(-hour, hour) });
    expect(response.status).toBe(503);
    expect(await response.text()).toContain("Expected completion:");
  });

  it("passes traffic through before the window", async () => {
    const response = await dispatch("https://example.com/", {}, { MAINTENANCE_ENABLED: "false", ...windowAround(hour, 2 * hour) });
    expect(response.status).toBe(200);
  });

  it("passes traffic through after the window even when enabled", async () => {
    const response = await dispatch("https://example.com/", {}, { MAINTENANCE_ENABLED: "true", ...windowAround(-2 * hour, -hour) });
    expect(response.status).toBe(200);
  });
});

describe("page content", () => {
  const page = async (overrides: Partial<Env>) => (await dispatch("https://example.com/", {}, overrides)).text();

  it("includes custom CSS", async () => {
    expect(await page({ CUSTOM_CSS: "body { background-color: #ff0000; }" })).toContain("background-color: #ff0000");
  });

  it("includes an HTTPS logo and drops other schemes", async () => {
    expect(await page({ LOGO_URL: "https://example.com/logo.png" })).toContain('src="https://example.com/logo.png"');
    for (const url of ["http://example.com/logo.png", "javascript:alert(1)", "data:text/html,<script>alert(1)</script>"]) {
      expect(await page({ LOGO_URL: url })).not.toContain("<img");
    }
  });

  it("does not render markup from the contact email", async () => {
    expect(await page({ CONTACT_EMAIL: "<script>alert(1)</script>@example.com" })).not.toContain("<script>");
  });
});
