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
const allowedIpFixtures = JSON.parse(
  readFileSync(new URL("../fixtures/allowed-ips.json", import.meta.url), "utf8"),
);
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
  RETRY_AFTER: "3600",
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

describe("Scheduled maintenance window", () => {
  const window = {
    MAINTENANCE_WINDOW_START: "2025-04-06T08:00:00Z",
    MAINTENANCE_WINDOW_END: "2025-04-06T10:00:00Z",
  };

  // Serve one request at the given instant through the real handler.
  async function statusAt(iso, bindings) {
    vi.useFakeTimers({ now: new Date(iso), toFake: ["Date"] });
    try {
      const worker = loadWorker(bindings);
      return (await worker.handleRequest(request())).status;
    } finally {
      vi.useRealTimers();
    }
  }

  for (const enabled of ["true", "false"]) {
    describe(`with MAINTENANCE_ENABLED=${enabled}`, () => {
      const bindings = { ...window, MAINTENANCE_ENABLED: enabled };

      it("passes traffic through before the window", async () => {
        expect(await statusAt("2025-04-06T07:59:59Z", bindings)).toBe(200);
      });

      it("serves maintenance from the start of the window", async () => {
        expect(await statusAt("2025-04-06T08:00:00Z", bindings)).toBe(503);
        expect(await statusAt("2025-04-06T09:59:59Z", bindings)).toBe(503);
      });

      it("passes traffic through from the end of the window", async () => {
        expect(await statusAt("2025-04-06T10:00:00Z", bindings)).toBe(200);
        expect(await statusAt("2025-04-07T00:00:00Z", bindings)).toBe(200);
      });
    });
  }

  it("serves maintenance at any time when enabled without a window", async () => {
    const bindings = { MAINTENANCE_ENABLED: "true" };
    expect(await statusAt("2025-04-06T07:00:00Z", bindings)).toBe(503);
    expect(await statusAt("2030-01-01T00:00:00Z", bindings)).toBe(503);
  });

  it("passes traffic through when disabled without a window", async () => {
    const bindings = { MAINTENANCE_ENABLED: "false" };
    expect(await statusAt("2025-04-06T09:00:00Z", bindings)).toBe(200);
  });

  it("falls back to MAINTENANCE_ENABLED when the window is unparseable", () => {
    const at = new Date("2025-04-06T09:00:00Z");
    const broken = {
      MAINTENANCE_WINDOW_START: "not-a-date",
      MAINTENANCE_WINDOW_END: "2025-04-06T10:00:00Z",
    };
    expect(
      loadWorker({ ...broken, MAINTENANCE_ENABLED: "true" }).isMaintenanceActive(at),
    ).toBe(true);
    expect(
      loadWorker({ ...broken, MAINTENANCE_ENABLED: "false" }).isMaintenanceActive(at),
    ).toBe(false);
  });
});

describe("Retry-After", () => {
  async function retryAfterAt(iso, bindings) {
    vi.useFakeTimers({ now: new Date(iso), toFake: ["Date"] });
    try {
      const response = await loadWorker(bindings).handleRequest(request());
      return response.headers.get("Retry-After");
    } finally {
      vi.useRealTimers();
    }
  }

  const window = {
    MAINTENANCE_WINDOW_START: "2025-04-06T08:00:00Z",
    MAINTENANCE_WINDOW_END: "2025-04-06T10:00:00Z",
  };

  it("counts down to the end of the window", async () => {
    expect(await retryAfterAt("2025-04-06T09:00:00Z", window)).toBe("3600");
    expect(await retryAfterAt("2025-04-06T09:59:30.500Z", window)).toBe("30");
    expect(await retryAfterAt("2025-04-06T09:59:59.999Z", window)).toBe("1");
  });

  it("uses RETRY_AFTER without a window", async () => {
    const at = "2025-04-06T09:00:00Z";
    expect(await retryAfterAt(at, { RETRY_AFTER: "120" })).toBe("120");
  });

  it("falls back to an hour for a missing or invalid RETRY_AFTER", async () => {
    const at = "2025-04-06T09:00:00Z";
    for (const value of [undefined, "", "0", "-5", "soon"]) {
      expect(await retryAfterAt(at, { RETRY_AFTER: value })).toBe("3600");
    }
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
    for (const allowed of ["[]", "", "not-json", "{invalid}", '"1.2.3.4"']) {
      expect(await bypasses("1.2.3.4", allowed)).toBe(false);
    }
  });

  it("ignores X-Forwarded-For", async () => {
    const worker = loadWorker({ ALLOWED_IPS: '["10.0.0.1"]' });
    const req = request({ ip: "203.0.113.9" });
    req.headers.set("X-Forwarded-For", "10.0.0.1");
    expect((await worker.handleRequest(req)).status).toBe(503);
  });
});

describe("isAllowedIp", () => {
  const { isAllowedIp } = loadWorker();
  const allowed = (ip, ...entries) => isAllowedIp(ip, entries);

  it("matches IPv4 CIDR ranges", () => {
    expect(allowed("192.168.0.42", "192.168.0.0/24")).toBe(true);
    expect(allowed("192.168.1.1", "192.168.0.0/24")).toBe(false);
    expect(allowed("10.255.0.1", "10.0.0.0/8")).toBe(true);
    expect(allowed("11.0.0.1", "10.0.0.0/8")).toBe(false);
    expect(allowed("203.0.113.7", "0.0.0.0/0")).toBe(true);
    expect(allowed("203.0.113.7", "203.0.113.7/32")).toBe(true);
  });

  it("matches IPv6 addresses in any spelling", () => {
    expect(allowed("2001:db8::1", "2001:0db8:0000:0000:0000:0000:0000:0001")).toBe(
      true,
    );
    expect(allowed("2001:DB8::1", "2001:db8::1")).toBe(true);
    expect(allowed("2001:db8::2", "2001:db8::1")).toBe(false);
    expect(allowed("::1", "0:0:0:0:0:0:0:1")).toBe(true);
  });

  it("matches IPv6 CIDR ranges", () => {
    expect(allowed("2001:db8:abcd:12::1", "2001:db8:abcd::/48")).toBe(true);
    expect(allowed("2001:db8:abce::1", "2001:db8:abcd::/48")).toBe(false);
    expect(allowed("fe80::1", "::/0")).toBe(true);
  });

  it("treats IPv4-mapped IPv6 as the IPv4 address", () => {
    expect(allowed("::ffff:192.0.2.1", "192.0.2.1")).toBe(true);
    expect(allowed("::ffff:c000:201", "192.0.2.0/24")).toBe(true);
    expect(allowed("192.0.2.1", "::ffff:192.0.2.1")).toBe(true);
    expect(allowed("192.0.2.200", "::ffff:192.0.2.0/120")).toBe(true);
    expect(allowed("192.0.3.1", "::ffff:192.0.2.0/120")).toBe(false);
  });

  it("never matches across address families", () => {
    expect(allowed("192.0.2.1", "::/0")).toBe(false);
    expect(allowed("2001:db8::1", "0.0.0.0/0")).toBe(false);
  });

  it("rejects malformed addresses and entries", () => {
    expect(allowed("192.168.0.1", "192.168.0.0/33")).toBe(false);
    expect(allowed("192.168.0.1", "192.168.0.0/24/1")).toBe(false);
    expect(allowed("192.168.0.1", "192.168.0.0/x")).toBe(false);
    expect(allowed("192.168.0.1", "::ffff:192.168.0.0/64")).toBe(false);
    expect(allowed("192.168.0.1", 42, null, "")).toBe(false);
    expect(allowed("010.0.0.1", "10.0.0.1")).toBe(false);
    expect(allowed("256.0.0.1", "0.0.0.0/0")).toBe(false);
    expect(allowed("1.2.3", "0.0.0.0/0")).toBe(false);
    expect(allowed("1::2::3", "::/0")).toBe(false);
    expect(allowed("1:2:3:4:5:6:7:8:9", "::/0")).toBe(false);
    expect(allowed("2001:db8::g", "::/0")).toBe(false);
    expect(allowed(null, "0.0.0.0/0")).toBe(false);
  });
});

// tests/worker.tftest.hcl checks the same entries against the allowed_ips
// validation, so plan accepts exactly what the Worker can match.
describe("allowlist entries shared with the OpenTofu validation", () => {
  const { parseCidr } = loadWorker();

  it.each(allowedIpFixtures.valid)("accepts %s", (entry) => {
    expect(parseCidr(entry)).not.toBeNull();
  });

  it.each(allowedIpFixtures.invalid)("rejects %s", (entry) => {
    expect(parseCidr(entry)).toBeNull();
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

  it("escapes the URL for its attribute instead of mangling it", async () => {
    const html = await maintenancePage({
      LOGO_URL: 'https://example.com/logo.png?a=1&b="x"<script>',
    });
    expect(html).toContain(
      '<img src="https://example.com/logo.png?a=1&amp;b=&quot;x&quot;&lt;script&gt;"',
    );
    expect(html).not.toContain("<script>");
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

  it("includes custom CSS", async () => {
    const html = await maintenancePage({
      CUSTOM_CSS: "body { background: blue; } a > b { color: red; }",
    });
    expect(html).toContain("body { background: blue; } a > b { color: red; }");
  });

  // Every way out of <style> needs a "<", and none survives escapeCss.
  for (const [name, css] of [
    ["a plain close tag", "</style><script>x()</script>"],
    ["a close tag with a space", "</style ><script>x()</script>"],
    ["a close tag with a newline", "</style\n><script>x()</script>"],
    ["an uppercase close tag", "</STYLE><script>x()</script>"],
    ["a close tag rebuilt by removing a nested one", "</sty</style>le><script>x()</script>"],
    ["an HTML comment opener", "<!--</style><script>x()</script>-->"],
  ]) {
    it(`keeps custom CSS inside <style> against ${name}`, async () => {
      const html = await maintenancePage({ CUSTOM_CSS: css });
      expect(html.match(/<\/style/gi)).toHaveLength(1);
      expect(html).not.toMatch(/<script/i);
      expect(html).not.toContain("<!--");
    });
  }

  it("writes < in custom CSS as a CSS escape", async () => {
    const html = await maintenancePage({ CUSTOM_CSS: 'a::after { content: "<"; }' });
    expect(html).toContain('a::after { content: "\\3C "; }');
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
    const csp = response.headers.get("Content-Security-Policy");
    for (const directive of [
      "default-src 'none'",
      "form-action 'none'",
      "base-uri 'none'",
      "frame-ancestors 'none'",
    ]) {
      expect(csp).toContain(directive);
    }
    expect(response.headers.get("X-Frame-Options")).toBe("DENY");
  });

  it("passes traffic through when maintenance is disabled", async () => {
    const worker = loadWorker({ MAINTENANCE_ENABLED: "false" });
    const response = await worker.handleRequest(request());
    expect(response.status).toBe(200);
    expect(worker.fetch).toHaveBeenCalledTimes(1);
  });
});
