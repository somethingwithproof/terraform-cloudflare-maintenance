// Tests of the Worker's request handling, run inside workerd. Each test
// passes its own bindings and clock to handleRequest, so the page logic and
// the response under test are the shipped ones.

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import allowedIpFixtures from "../../../tests/fixtures/allowed-ips.json";
import { escapeHtml, isValidHttpsUrl, sanitizeEmail } from "../../src/html";
import { type Env, handleRequest } from "../../src/index";
import { isAllowedIp, parseCidr } from "../../src/ip";

const defaultEnv: Env = {
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

const window = {
  MAINTENANCE_WINDOW_START: "2025-04-06T08:00:00Z",
  MAINTENANCE_WINDOW_END: "2025-04-06T10:00:00Z",
};

let origin: ReturnType<typeof vi.spyOn<typeof globalThis, "fetch">>;

beforeEach(() => {
  origin = vi.spyOn(globalThis, "fetch").mockImplementation(() => Promise.resolve(new Response("Origin response")));
});

afterEach(() => {
  vi.restoreAllMocks();
});

function request({ ip, country }: { ip?: string; country?: string | null } = {}): Request {
  const headers = new Headers();
  if (ip) headers.set("CF-Connecting-IP", ip);
  const init: RequestInit = { headers };
  if (country !== undefined) {
    (init as { cf?: unknown }).cf = { country };
  }
  return new Request("https://example.com/", init);
}

function serve(env: Partial<Env> = {}, req: Request = request(), now?: Date): Promise<Response> {
  return handleRequest(req, { ...defaultEnv, ...env }, now);
}

async function maintenancePage(env: Partial<Env> = {}): Promise<string> {
  const response = await serve(env);
  expect(response.status).toBe(503);
  return response.text();
}

describe("isValidHttpsUrl", () => {
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
  it("returns valid addresses unchanged", () => {
    expect(sanitizeEmail("test@example.com")).toBe("test@example.com");
    expect(sanitizeEmail("user+tag@example.co.uk")).toBe("user+tag@example.co.uk");
    expect(sanitizeEmail("ops@a.b")).toBe("ops@a.b");
  });

  it("removes & from an otherwise valid address", () => {
    expect(sanitizeEmail("r&d@example.com")).toBe("rd@example.com");
  });

  it("checks long addresses in linear time", () => {
    const hostile = `!@!.${"!.".repeat(50_000)}`;
    const started = Date.now();
    expect(sanitizeEmail(`${hostile}@`)).toBe("");
    expect(Date.now() - started).toBeLessThan(100);
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
      "a@b@example.com",
      "test@.com",
      "test@example.",
      "test@exa mple.com",
    ]) {
      expect(sanitizeEmail(email)).toBe("");
    }
  });
});

describe("escapeHtml", () => {
  it("escapes HTML metacharacters", () => {
    expect(escapeHtml(`<a href="x">'&'</a>`)).toBe("&lt;a href=&quot;x&quot;&gt;&#039;&amp;&#039;&lt;/a&gt;");
  });

  it("returns an empty string for empty input", () => {
    expect(escapeHtml("")).toBe("");
    expect(escapeHtml(undefined)).toBe("");
  });
});

describe("Scheduled maintenance window", () => {
  const statusAt = async (iso: string, env: Partial<Env>) => (await serve(env, request(), new Date(iso))).status;

  for (const enabled of ["true", "false"]) {
    describe(`with MAINTENANCE_ENABLED=${enabled}`, () => {
      const env = { ...window, MAINTENANCE_ENABLED: enabled };

      it("passes traffic through before the window", async () => {
        expect(await statusAt("2025-04-06T07:59:59Z", env)).toBe(200);
      });

      it("serves maintenance from the start of the window", async () => {
        expect(await statusAt("2025-04-06T08:00:00Z", env)).toBe(503);
        expect(await statusAt("2025-04-06T09:59:59Z", env)).toBe(503);
      });

      it("passes traffic through from the end of the window", async () => {
        expect(await statusAt("2025-04-06T10:00:00Z", env)).toBe(200);
        expect(await statusAt("2025-04-07T00:00:00Z", env)).toBe(200);
      });
    });
  }

  it("serves maintenance at any time when enabled without a window", async () => {
    expect(await statusAt("2025-04-06T07:00:00Z", { MAINTENANCE_ENABLED: "true" })).toBe(503);
    expect(await statusAt("2030-01-01T00:00:00Z", { MAINTENANCE_ENABLED: "true" })).toBe(503);
  });

  it("passes traffic through when disabled without a window", async () => {
    expect(await statusAt("2025-04-06T09:00:00Z", { MAINTENANCE_ENABLED: "false" })).toBe(200);
  });

  it("falls back to MAINTENANCE_ENABLED when the window is unparseable", async () => {
    const broken = { MAINTENANCE_WINDOW_START: "not-a-date", MAINTENANCE_WINDOW_END: "2025-04-06T10:00:00Z" };
    expect(await statusAt("2025-04-06T09:00:00Z", { ...broken, MAINTENANCE_ENABLED: "true" })).toBe(503);
    expect(await statusAt("2025-04-06T09:00:00Z", { ...broken, MAINTENANCE_ENABLED: "false" })).toBe(200);
  });
});

describe("Expected completion", () => {
  it("shows the end of the window", async () => {
    const response = await serve(window, request(), new Date("2025-04-06T09:00:00Z"));
    const html = await response.text();
    expect(html).toContain("Expected completion:");
    expect(html).toContain("Sun, 06 Apr 2025 10:00:00 GMT");
  });

  it("is absent without a valid window", async () => {
    for (const bounds of [
      { MAINTENANCE_WINDOW_START: "", MAINTENANCE_WINDOW_END: "" },
      { MAINTENANCE_WINDOW_START: "invalid", MAINTENANCE_WINDOW_END: "invalid" },
    ]) {
      expect(await maintenancePage(bounds)).not.toContain("Expected completion:");
    }
  });
});

describe("Retry-After", () => {
  const retryAfterAt = async (iso: string, env: Partial<Env>) =>
    (await serve(env, request(), new Date(iso))).headers.get("Retry-After");

  it("counts down to the end of the window", async () => {
    expect(await retryAfterAt("2025-04-06T09:00:00Z", window)).toBe("3600");
    expect(await retryAfterAt("2025-04-06T09:59:30.500Z", window)).toBe("30");
    expect(await retryAfterAt("2025-04-06T09:59:59.999Z", window)).toBe("1");
  });

  it("uses RETRY_AFTER without a window", async () => {
    expect(await retryAfterAt("2025-04-06T09:00:00Z", { RETRY_AFTER: "120" })).toBe("120");
  });

  it("falls back to an hour for a missing or invalid RETRY_AFTER", async () => {
    const env: Partial<Env> = { ...defaultEnv };
    delete env.RETRY_AFTER;
    expect(await retryAfterAt("2025-04-06T09:00:00Z", env)).toBe("3600");
    for (const value of ["", "0", "-5", "soon"]) {
      expect(await retryAfterAt("2025-04-06T09:00:00Z", { RETRY_AFTER: value })).toBe("3600");
    }
  });
});

describe("IP allowlist", () => {
  const bypasses = async (ip: string | undefined, allowed: string) =>
    (await serve({ ALLOWED_IPS: allowed }, request(ip === undefined ? {} : { ip }))).status === 200;

  it("passes listed IPs through to the origin", async () => {
    expect(await bypasses("192.168.1.1", '["192.168.1.1", "10.0.0.1"]')).toBe(true);
    expect(await bypasses("10.0.0.1", '["192.168.1.1", "10.0.0.1"]')).toBe(true);
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
    const req = request({ ip: "203.0.113.9" });
    req.headers.set("X-Forwarded-For", "10.0.0.1");
    expect((await serve({ ALLOWED_IPS: '["10.0.0.1"]' }, req)).status).toBe(503);
  });
});

describe("isAllowedIp", () => {
  const allowed = (ip: string | null, ...entries: unknown[]) => isAllowedIp(ip, entries);

  it("matches IPv4 CIDR ranges", () => {
    expect(allowed("192.168.0.42", "192.168.0.0/24")).toBe(true);
    expect(allowed("192.168.1.1", "192.168.0.0/24")).toBe(false);
    expect(allowed("10.255.0.1", "10.0.0.0/8")).toBe(true);
    expect(allowed("11.0.0.1", "10.0.0.0/8")).toBe(false);
    expect(allowed("203.0.113.7", "0.0.0.0/0")).toBe(true);
    expect(allowed("203.0.113.7", "203.0.113.7/32")).toBe(true);
  });

  it("matches IPv6 addresses in any spelling", () => {
    expect(allowed("2001:db8::1", "2001:0db8:0000:0000:0000:0000:0000:0001")).toBe(true);
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
  it.each(allowedIpFixtures.valid)("accepts %s", (entry) => {
    expect(parseCidr(entry)).not.toBeNull();
  });

  it.each(allowedIpFixtures.invalid)("rejects %s", (entry) => {
    expect(parseCidr(entry)).toBeNull();
  });
});

describe("Region allowlist", () => {
  const bypasses = async (country: string | null | undefined, allowed: string) =>
    (await serve({ ALLOWED_REGIONS: allowed }, request(country === undefined ? {} : { country }))).status === 200;

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
    expect(await maintenancePage({ LOGO_URL: "https://example.com/logo.png" })).toContain(
      '<img src="https://example.com/logo.png"',
    );
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
    const html = await maintenancePage({ LOGO_URL: 'https://example.com/logo.png?a=1&b="x"<script>' });
    expect(html).toContain('<img src="https://example.com/logo.png?a=1&amp;b=&quot;x&quot;&lt;script&gt;"');
    expect(html).not.toContain("<script>");
  });
});

describe("Maintenance page", () => {
  it("renders the configured title, message and contact", async () => {
    const html = await maintenancePage({ MAINTENANCE_TITLE: "Custom Title", MAINTENANCE_MESSAGE: "Custom message here" });
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("<title>Custom Title</title>");
    expect(html).toContain("<p>Custom message here</p>");
    expect(html).toContain('<a href="mailto:test@example.com">test@example.com</a>');
  });

  it("falls back to default title and message", async () => {
    const html = await maintenancePage({ MAINTENANCE_TITLE: "", MAINTENANCE_MESSAGE: "" });
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
    expect(await maintenancePage({ CONTACT_EMAIL: "not-an-email" })).not.toContain("mailto:");
  });

  it("includes custom CSS", async () => {
    const css = "body { background: blue; } a > b { color: red; }";
    expect(await maintenancePage({ CUSTOM_CSS: css })).toContain(css);
  });

  // Every way out of <style> needs a "<", and none survives escapeCss.
  it.each([
    ["a plain close tag", "</style><script>x()</script>"],
    ["a close tag with a space", "</style ><script>x()</script>"],
    ["a close tag with a newline", "</style\n><script>x()</script>"],
    ["an uppercase close tag", "</STYLE><script>x()</script>"],
    ["a close tag rebuilt by removing a nested one", "</sty</style>le><script>x()</script>"],
    ["an HTML comment opener", "<!--</style><script>x()</script>-->"],
  ])("keeps custom CSS inside <style> against %s", async (_name, css) => {
    const html = await maintenancePage({ CUSTOM_CSS: css });
    expect(html.match(/<\/style/gi)).toHaveLength(1);
    expect(html).not.toMatch(/<script/i);
    expect(html).not.toContain("<!--");
  });

  it("writes < in custom CSS as a CSS escape", async () => {
    expect(await maintenancePage({ CUSTOM_CSS: 'a::after { content: "<"; }' })).toContain(
      'a::after { content: "\\3C "; }',
    );
  });

  it("keeps Unicode content", async () => {
    const html = await maintenancePage({ MAINTENANCE_TITLE: "Wartung 🔧", MAINTENANCE_MESSAGE: "メンテナンス中です" });
    expect(html).toContain("🔧");
    expect(html).toContain("メンテナンス中です");
  });

  it("sends 503 with no-cache and hardening headers", async () => {
    const response = await serve();
    expect(response.status).toBe(503);
    expect(response.headers.get("Content-Type")).toBe("text/html;charset=UTF-8");
    expect(response.headers.get("Cache-Control")).toContain("no-store");
    expect(response.headers.get("Retry-After")).toBe("3600");
    const csp = response.headers.get("Content-Security-Policy");
    for (const directive of ["default-src 'none'", "form-action 'none'", "base-uri 'none'", "frame-ancestors 'none'"]) {
      expect(csp).toContain(directive);
    }
    expect(response.headers.get("X-Frame-Options")).toBe("DENY");
  });

  it("passes traffic through when maintenance is disabled", async () => {
    const response = await serve({ MAINTENANCE_ENABLED: "false" });
    expect(response.status).toBe(200);
    expect(origin).toHaveBeenCalledTimes(1);
  });
});
