/**
 * Unit tests for the Cloudflare maintenance Worker.
 *
 * Every test runs the shipped ../../worker.js in a fresh VM context, so the
 * functions and the request handler under test are the real ones. Bindings
 * that Cloudflare injects as globals are supplied per test via loadWorker().
 */

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { runInNewContext } from "node:vm";
import { describe, it, expect, vi } from "vitest";

const workerUrl = new URL("../../worker.js", import.meta.url);
const workerSource = readFileSync(workerUrl, "utf8");

const defaultBindings = {
  MAINTENANCE_ENABLED: "true",
  MAINTENANCE_TITLE: "Test Maintenance",
  MAINTENANCE_MESSAGE: "We are under maintenance",
  CONTACT_EMAIL: "test@example.com",
  CUSTOM_CSS: "",
  LOGO_URL: "",
  MAINTENANCE_WINDOW_START: "",
  MAINTENANCE_WINDOW_END: "",
  ALLOWED_IPS: "[]",
  ALLOWED_REGIONS: "[]",
};

function loadWorker(bindings = {}) {
  const context = {
    ...defaultBindings,
    ...bindings,
    URL,
    Response,
    Date,
    addEventListener() {},
    fetch: vi.fn(async () => new Response("Origin response")),
  };
  runInNewContext(workerSource, context, {
    filename: fileURLToPath(workerUrl),
  });
  return context;
}

function request({ ip, country } = {}) {
  const req = new Request("https://example.com/");
  if (ip) req.headers.set("CF-Connecting-IP", ip);
  if (country !== undefined) req.cf = { country };
  return req;
}

async function maintenancePage(bindings = {}) {
  const response = await loadWorker(bindings).handleRequest(request());
  expect(response.status).toBe(503);
  return response.text();
}

describe("isValidHttpsUrl", () => {
  const { isValidHttpsUrl } = loadWorker();

  it("accepts HTTPS URLs", () => {
    expect(isValidHttpsUrl("https://example.com")).toBe(true);
    expect(isValidHttpsUrl("https://sub.example.com/path")).toBe(true);
    expect(isValidHttpsUrl("https://example.com:8443")).toBe(true);
  });

  it("rejects other schemes and non-URLs", () => {
    for (const url of [
      "http://example.com",
      "not-a-url",
      "",
      "javascript:alert(1)",
      "data:text/html,<script>alert(1)</script>",
      null,
      undefined,
    ]) {
      expect(isValidHttpsUrl(url)).toBe(false);
    }
  });
});

describe("sanitizeEmail", () => {
  const { sanitizeEmail } = loadWorker();

  it("returns valid addresses unchanged", () => {
    expect(sanitizeEmail("test@example.com")).toBe("test@example.com");
    expect(sanitizeEmail("user+tag@example.co.uk")).toBe(
      "user+tag@example.co.uk",
    );
  });

  it("rejects malformed addresses and markup", () => {
    for (const email of [
      "not-an-email",
      "@example.com",
      "test@",
      "test@example",
      "",
      "test<script>@example.com",
      "test'@example.com",
      'test"@example.com',
      "test@<img src=x onerror=alert(1)>.com",
    ]) {
      expect(sanitizeEmail(email)).toBe("");
    }
  });
});

describe("escapeHtml", () => {
  const { escapeHtml } = loadWorker();

  it("escapes HTML metacharacters", () => {
    expect(escapeHtml(`<a href="x">'&'</a>`)).toBe(
      "&lt;a href=&quot;x&quot;&gt;&#039;&amp;&#039;&lt;/a&gt;",
    );
  });

  it("returns an empty string for empty input", () => {
    expect(escapeHtml("")).toBe("");
    expect(escapeHtml(undefined)).toBe("");
  });
});

describe("checkMaintenanceWindow", () => {
  const window = {
    MAINTENANCE_WINDOW_START: "2025-04-06T08:00:00Z",
    MAINTENANCE_WINDOW_END: "2025-04-06T10:00:00Z",
  };
  const at = (iso, bindings = window) =>
    loadWorker(bindings).checkMaintenanceWindow(new Date(iso));

  it("is true inside the window and at its start", () => {
    expect(at("2025-04-06T09:00:00Z")).toBe(true);
    expect(at("2025-04-06T08:00:00Z")).toBe(true);
  });

  it("is false before and after the window", () => {
    expect(at("2025-04-06T07:59:59Z")).toBe(false);
    expect(at("2025-04-06T10:00:01Z")).toBe(false);
  });

  it("is false without a window or with unparseable times", () => {
    expect(at("2025-04-06T09:00:00Z", {})).toBe(false);
    expect(
      at("2025-04-06T09:00:00Z", {
        MAINTENANCE_WINDOW_START: "not-a-date",
        MAINTENANCE_WINDOW_END: "also-not-a-date",
      }),
    ).toBe(false);
  });
});

describe("getMaintenanceWindowMessage", () => {
  const message = (start, end) =>
    loadWorker({
      MAINTENANCE_WINDOW_START: start,
      MAINTENANCE_WINDOW_END: end,
    }).getMaintenanceWindowMessage();

  it("shows the expected completion time", () => {
    const result = message("2025-04-06T08:00:00Z", "2025-04-06T10:00:00Z");
    expect(result).toContain("Expected completion:");
    expect(result).toContain("Sun, 06 Apr 2025 10:00:00 GMT");
  });

  it("is empty without a valid window", () => {
    expect(message("", "")).toBe("");
    expect(message(null, null)).toBe("");
    expect(message("invalid", "invalid")).toBe("");
  });
});

describe("IP allowlist", () => {
  async function bypasses(ip, allowed) {
    const worker = loadWorker({ ALLOWED_IPS: allowed });
    return (await worker.handleRequest(request({ ip }))).status === 200;
  }

  it("passes listed IPs through to the origin", async () => {
    expect(await bypasses("192.168.1.1", '["192.168.1.1", "10.0.0.1"]')).toBe(
      true,
    );
    expect(await bypasses("10.0.0.1", '["192.168.1.1", "10.0.0.1"]')).toBe(
      true,
    );
  });

  it("serves maintenance to other or missing IPs", async () => {
    expect(await bypasses("1.2.3.4", '["192.168.1.1"]')).toBe(false);
    expect(await bypasses(undefined, '["192.168.1.1"]')).toBe(false);
  });

  it("treats empty or invalid allowlists as empty", async () => {
    for (const allowed of ["[]", "", "not-json", "{invalid}"]) {
      expect(await bypasses("1.2.3.4", allowed)).toBe(false);
    }
  });
});

describe("Region allowlist", () => {
  async function bypasses(country, allowed) {
    const worker = loadWorker({ ALLOWED_REGIONS: allowed });
    return (await worker.handleRequest(request({ country }))).status === 200;
  }

  it("passes listed countries through to the origin", async () => {
    expect(await bypasses("US", '["US", "CA", "GB"]')).toBe(true);
    expect(await bypasses("CA", '["US", "CA", "GB"]')).toBe(true);
  });

  it("serves maintenance to other or unknown countries", async () => {
    expect(await bypasses("DE", '["US", "CA", "GB"]')).toBe(false);
    expect(await bypasses(null, '["US"]')).toBe(false);
    expect(await bypasses(undefined, '["US"]')).toBe(false);
  });

  it("treats empty or invalid allowlists as empty", async () => {
    for (const allowed of ["[]", "", "not-json"]) {
      expect(await bypasses("US", allowed)).toBe(false);
    }
  });
});

describe("Logo URL", () => {
  it("renders an HTTPS logo", async () => {
    const html = await maintenancePage({
      LOGO_URL: "https://example.com/logo.png",
    });
    expect(html).toContain('<img src="https://example.com/logo.png"');
  });

  it("drops non-HTTPS logos", async () => {
    for (const url of [
      "http://example.com/logo.png",
      "javascript:alert(1)",
      "JAVASCRIPT:alert(1)",
      "data:image/png;base64,abc",
      "DATA:text/html,<script>alert(1)</script>",
    ]) {
      expect(await maintenancePage({ LOGO_URL: url })).not.toContain("<img");
    }
  });

  it("strips markup characters from the URL", async () => {
    const html = await maintenancePage({
      LOGO_URL: 'https://example.com/logo"onerror="x<script>.png',
    });
    expect(html).not.toContain("<script>");
    expect(html).not.toContain('"onerror');
  });
});

describe("Maintenance page", () => {
  it("renders the configured title, message and contact", async () => {
    const html = await maintenancePage({
      MAINTENANCE_TITLE: "Custom Title",
      MAINTENANCE_MESSAGE: "Custom message here",
    });
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("<title>Custom Title</title>");
    expect(html).toContain("<p>Custom message here</p>");
    expect(html).toContain(
      '<a href="mailto:test@example.com">test@example.com</a>',
    );
  });

  it("falls back to default title and message", async () => {
    const html = await maintenancePage({
      MAINTENANCE_TITLE: "",
      MAINTENANCE_MESSAGE: "",
    });
    expect(html).toContain("<title>Maintenance Mode</title>");
    expect(html).toContain("We are currently performing scheduled maintenance.");
  });

  it("escapes the title and message", async () => {
    const html = await maintenancePage({
      MAINTENANCE_TITLE: "Down <script>alert(1)</script>",
      MAINTENANCE_MESSAGE: "<img src=x onerror=alert(1)>",
    });
    expect(html).not.toContain("<script>alert(1)");
    expect(html).not.toContain("<img src=x");
    expect(html).toContain("Down &lt;script&gt;");
  });

  it("omits the contact line for an invalid email", async () => {
    const html = await maintenancePage({ CONTACT_EMAIL: "not-an-email" });
    expect(html).not.toContain("mailto:");
  });

  it("includes custom CSS but cannot close the style element", async () => {
    const html = await maintenancePage({
      CUSTOM_CSS: "body { background: blue; }</style><script>x()</script>",
    });
    expect(html).toContain("body { background: blue; }");
    expect(html.match(/<\/style>/g)).toHaveLength(1);
  });

  it("keeps Unicode content", async () => {
    const html = await maintenancePage({
      MAINTENANCE_TITLE: "Wartung 🔧",
      MAINTENANCE_MESSAGE: "メンテナンス中です",
    });
    expect(html).toContain("🔧");
    expect(html).toContain("メンテナンス中です");
  });

  it("sends 503 with no-cache and hardening headers", async () => {
    const response = await loadWorker().handleRequest(request());
    expect(response.status).toBe(503);
    expect(response.headers.get("Content-Type")).toBe(
      "text/html;charset=UTF-8",
    );
    expect(response.headers.get("Cache-Control")).toContain("no-store");
    expect(response.headers.get("Retry-After")).toBe("3600");
    expect(response.headers.get("Content-Security-Policy")).toContain(
      "default-src 'none'",
    );
    expect(response.headers.get("X-Frame-Options")).toBe("DENY");
  });

  it("passes traffic through when maintenance is disabled", async () => {
    const worker = loadWorker({ MAINTENANCE_ENABLED: "false" });
    const response = await worker.handleRequest(request());
    expect(response.status).toBe(200);
    expect(worker.fetch).toHaveBeenCalledTimes(1);
  });
});
