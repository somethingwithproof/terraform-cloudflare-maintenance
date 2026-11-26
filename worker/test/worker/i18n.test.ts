// SPDX-FileCopyrightText: 2026 Thomas Vincent <thomasvincent@gmail.com>
// SPDX-License-Identifier: MIT

import { describe, expect, it } from "vitest";
import { DEFAULT_MESSAGE, DEFAULT_TITLE, renderPage } from "../../src/html";
import {
  formatMessage,
  getCatalog,
  isRtl,
  negotiateLocale,
  resolveLocale,
  SUPPORTED_LOCALES,
} from "../../src/i18n";
import { handleRequest, type Env } from "../../src/index";

const PLACEHOLDER_RE = /\{[a-zA-Z0-9_]+\}/g;

function extractPlaceholders(value: string): string[] {
  return [...value.matchAll(PLACEHOLDER_RE)].map((m) => m[0]).sort();
}

const RTL_LOCALES = new Set(["ar", "ar-EG", "ar-MA", "fa", "he", "ur"]);

describe("i18n catalogs", () => {
  it("supports all 48 locales with 100% key and placeholder parity", () => {
    expect(SUPPORTED_LOCALES).toHaveLength(48);
    const enCatalog = getCatalog("en");
    const enKeys = Object.keys(enCatalog).sort();
    expect(enKeys.length).toBeGreaterThan(0);

    for (const locale of SUPPORTED_LOCALES) {
      const cat = getCatalog(locale);
      const locKeys = Object.keys(cat).sort();
      expect(locKeys).toEqual(enKeys);
      for (const key of enKeys) {
        const enVal = enCatalog[key as keyof typeof enCatalog];
        const locVal = cat[key as keyof typeof cat];
        expect(locVal.trim().length).toBeGreaterThan(0);
        expect(extractPlaceholders(locVal)).toEqual(extractPlaceholders(enVal));
      }
    }
  });

  it("marks all 6 RTL locales accurately", () => {
    for (const locale of SUPPORTED_LOCALES) {
      expect(isRtl(locale)).toBe(RTL_LOCALES.has(locale));
    }
  });

  it("resolves BCP-47, African, Asian, and script variants accurately", () => {
    expect(resolveLocale(undefined)).toBe("en");
    expect(resolveLocale("")).toBe("en");
    expect(resolveLocale("pt-BR")).toBe("pt-BR");
    expect(resolveLocale("pt_PT")).toBe("pt-BR");
    expect(resolveLocale("zh-CN")).toBe("zh-CN");
    expect(resolveLocale("zh-Hans")).toBe("zh-CN");
    expect(resolveLocale("zh-TW")).toBe("zh-TW");
    expect(resolveLocale("zh-Hant-HK")).toBe("zh-TW");
    expect(resolveLocale("ar-SA")).toBe("ar");
    expect(resolveLocale("ar-EG")).toBe("ar-EG");
    expect(resolveLocale("ar-MA")).toBe("ar-MA");
    expect(resolveLocale("fr-SN")).toBe("fr-SN");
    expect(resolveLocale("sw")).toBe("sw-KE");
    expect(resolveLocale("yo")).toBe("yo-NG");
    expect(resolveLocale("fa-IR")).toBe("fa");
    expect(resolveLocale("he-IL")).toBe("he");
    expect(resolveLocale("iw")).toBe("he");
    expect(resolveLocale("ur-PK")).toBe("ur");
    expect(resolveLocale("tl-PH")).toBe("fil");
    expect(resolveLocale("hi-IN")).toBe("hi");
    expect(resolveLocale("bs")).toBe("bs");
    expect(resolveLocale("bs-BA")).toBe("bs");
    expect(resolveLocale("hr")).toBe("hr");
    expect(resolveLocale("hr-HR")).toBe("hr");
    expect(resolveLocale("sr")).toBe("sr");
    expect(resolveLocale("sr-RS")).toBe("sr");
    expect(resolveLocale("sr-Cyrl")).toBe("sr");
    expect(resolveLocale("sr-Latn")).toBe("sr");
    expect(resolveLocale("sr-Cyrl-RS")).toBe("sr");
    expect(resolveLocale("sr-Latn-RS")).toBe("sr");
    expect(resolveLocale("xx-YY")).toBe("en");
    expect(resolveLocale("constructor")).toBe("en");
    expect(resolveLocale("toString")).toBe("en");
    expect(resolveLocale("__proto__")).toBe("en");
  });

  it("negotiates Accept-Language with q-values", () => {
    expect(negotiateLocale(null)).toBe("en");
    expect(negotiateLocale("constructor, toString;q=0.9")).toBe("en");
    expect(negotiateLocale("fr-CA, fr;q=0.9, en;q=0.8")).toBe("fr");
    expect(negotiateLocale("en;q=0.5, de-DE;q=0.9")).toBe("de");
    expect(negotiateLocale("de;q=0, ja;q=0.8")).toBe("ja");
    expect(negotiateLocale("zh-Hant-TW, zh;q=0.8")).toBe("zh-TW");
    expect(negotiateLocale("ar-EG, ar;q=0.9")).toBe("ar-EG");
    expect(negotiateLocale("fa-IR, en;q=0.5")).toBe("fa");
    expect(negotiateLocale("xx-YY, *;q=0.5")).toBe("en");
  });

  it("formats placeholders safely", () => {
    expect(formatMessage("Expected completion: {time}", { time: "10:00 UTC" })).toBe(
      "Expected completion: 10:00 UTC",
    );
  });
});

describe("localized maintenance page rendering", () => {
  const baseEnv: Env = {
    MAINTENANCE_ENABLED: "true",
    MAINTENANCE_TITLE: DEFAULT_TITLE,
    MAINTENANCE_MESSAGE: DEFAULT_MESSAGE,
    CONTACT_EMAIL: "support@example.com",
    CUSTOM_CSS: "",
    LOGO_URL: "https://example.com/logo.png",
    MAINTENANCE_WINDOW_START: "2025-04-06T08:00:00Z",
    MAINTENANCE_WINDOW_END: "2025-04-06T10:00:00Z",
    RETRY_AFTER: "3600",
    ALLOWED_IPS: "[]",
    ALLOWED_REGIONS: "[]",
    STATUS_PATH: "/__maintenance/status",
    PAGES: "[]",
  };

  it("sets lang and dir=rtl for Arabic requests", async () => {
    const req = new Request("https://example.com/", {
      headers: { "Accept-Language": "ar-SA, ar;q=0.9" },
    });
    const res = await handleRequest(req, baseEnv, new Date("2025-04-06T09:00:00Z"));
    expect(res.status).toBe(503);
    expect(res.headers.get("Content-Language")).toBe("ar");
    expect(res.headers.get("Vary")).toBe("Accept-Language");
    const html = await res.text();
    expect(html).toContain('<html lang="ar" dir="rtl">');
    expect(html).toContain(getCatalog("ar").title);
    expect(html).toContain('mailto:support@example.com');
  });

  it("localizes default title and message per Accept-Language", async () => {
    const req = new Request("https://example.com/", {
      headers: { "Accept-Language": "ja, en;q=0.5" },
    });
    const res = await handleRequest(req, baseEnv, new Date("2025-04-06T09:00:00Z"));
    expect(res.headers.get("Content-Language")).toBe("ja");
    const html = await res.text();
    expect(html).toContain('<html lang="ja">');
    expect(html).toContain(getCatalog("ja").title);
    expect(html).toContain(getCatalog("ja").message);
  });

  it("preserves custom operator title and message overrides", async () => {
    const req = new Request("https://example.com/", {
      headers: { "Accept-Language": "de-DE, de;q=0.9" },
    });
    const res = await handleRequest(
      req,
      { ...baseEnv, MAINTENANCE_TITLE: "Planned DB Upgrade", MAINTENANCE_MESSAGE: "Back at noon UTC." },
      new Date("2025-04-06T09:00:00Z"),
    );
    const html = await res.text();
    expect(html).toContain('<html lang="de">');
    expect(html).toContain("<title>Planned DB Upgrade</title>");
    expect(html).toContain("<p>Back at noon UTC.</p>");
  });

  it("renders every supported locale cleanly via renderPage", () => {
    for (const locale of SUPPORTED_LOCALES) {
      const html = renderPage({
        title: "",
        message: "",
        contactEmail: "ops@example.com",
        customCss: "",
        logoUrl: "",
        windowEnd: new Date("2025-04-06T10:00:00Z"),
        locale,
      });
      expect(html).toContain(`<html lang="${locale}"`);
      if (RTL_LOCALES.has(locale)) {
        expect(html).toContain('dir="rtl"');
      } else {
        expect(html).not.toContain('dir="rtl"');
      }
    }
  });
});
