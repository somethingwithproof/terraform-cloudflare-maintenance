// SPDX-FileCopyrightText: 2026 Thomas Vincent <thomasvincent@gmail.com>
// SPDX-License-Identifier: MIT

import ar from "./locales/ar.json";
import de from "./locales/de.json";
import en from "./locales/en.json";
import es from "./locales/es.json";
import fr from "./locales/fr.json";
import hi from "./locales/hi.json";
import id from "./locales/id.json";
import it from "./locales/it.json";
import ja from "./locales/ja.json";
import ko from "./locales/ko.json";
import nl from "./locales/nl.json";
import pl from "./locales/pl.json";
import ptBR from "./locales/pt-BR.json";
import ru from "./locales/ru.json";
import sv from "./locales/sv.json";
import tr from "./locales/tr.json";
import uk from "./locales/uk.json";
import vi from "./locales/vi.json";
import zhCN from "./locales/zh-CN.json";
import zhTW from "./locales/zh-TW.json";

export const SUPPORTED_LOCALES = [
  "en", "de", "es", "fr", "it", "pt-BR", "nl", "ru", "uk",
  "ja", "ko", "zh-CN", "zh-TW", "ar", "hi", "pl", "tr", "sv", "vi", "id",
] as const;

export type Locale = (typeof SUPPORTED_LOCALES)[number];

export interface LocaleCatalog {
  title: string;
  message: string;
  expectedCompletion: string;
  contact: string;
  logoAlt: string;
  statusUnavailable: string;
  retryNotice: string;
  languageName: string;
}

const CATALOGS: Record<Locale, LocaleCatalog> = {
  en,
  de,
  es,
  fr,
  it,
  "pt-BR": ptBR,
  nl,
  ru,
  uk,
  ja,
  ko,
  "zh-CN": zhCN,
  "zh-TW": zhTW,
  ar,
  hi,
  pl,
  tr,
  sv,
  vi,
  id,
};

export function isRtl(locale: Locale): boolean {
  return locale === "ar";
}

/**
 * Maps a BCP-47 language tag to a supported canonical locale, or null if unsupported.
 */
export function matchLocale(tag: string | null | undefined): Locale | null {
  if (!tag) return null;
  const clean = tag.trim().replaceAll("_", "-");
  const lower = clean.toLowerCase();
  if (!lower || lower === "*" || lower === "c" || lower === "posix") return null;

  if (
    lower === "zh-tw" ||
    lower === "zh-hk" ||
    lower === "zh-mo" ||
    lower === "zh-hant" ||
    lower.startsWith("zh-hant-")
  ) {
    return "zh-TW";
  }
  if (
    lower === "zh" ||
    lower === "zh-cn" ||
    lower === "zh-sg" ||
    lower === "zh-hans" ||
    lower.startsWith("zh-hans-")
  ) {
    return "zh-CN";
  }
  if (lower === "pt" || lower === "pt-br") return "pt-BR";

  for (const loc of SUPPORTED_LOCALES) {
    if (loc.toLowerCase() === lower) return loc;
  }

  const base = lower.split("-")[0] ?? "";
  if (base === "zh") {
    if (lower.includes("hant") || lower.includes("-tw") || lower.includes("-hk") || lower.includes("-mo")) {
      return "zh-TW";
    }
    return "zh-CN";
  }
  if (base === "pt") return "pt-BR";

  for (const loc of SUPPORTED_LOCALES) {
    if (loc.toLowerCase() === base) return loc;
  }
  return null;
}

export function resolveLocale(tag: string | null | undefined): Locale {
  return matchLocale(tag) ?? "en";
}

/**
 * Selects the best supported locale from an HTTP Accept-Language header,
 * honoring RFC 9110 quality values (q=0..1) and defaulting to "en".
 */
export function negotiateLocale(acceptLanguage: string | null | undefined): Locale {
  if (!acceptLanguage) return "en";

  const weighted: { tag: string; q: number; index: number }[] = [];
  const parts = acceptLanguage.split(",");
  for (let i = 0; i < parts.length; i += 1) {
    const raw = parts[i]?.trim();
    if (!raw) continue;
    const segments = raw.split(";");
    const tag = segments[0]?.trim() ?? "";
    if (!tag) continue;

    let q = 1;
    let valid = true;
    for (let j = 1; j < segments.length; j += 1) {
      const param = segments[j]?.trim().toLowerCase() ?? "";
      if (param.startsWith("q=")) {
        const parsed = Number(param.slice(2));
        if (!Number.isFinite(parsed) || parsed < 0 || parsed > 1) {
          valid = false;
          break;
        }
        q = parsed;
      }
    }
    if (!valid || q === 0) continue;
    weighted.push({ tag, q, index: i });
  }

  weighted.sort((a, b) => (b.q !== a.q ? b.q - a.q : a.index - b.index));

  for (const entry of weighted) {
    if (entry.tag === "*") return "en";
    const matched = matchLocale(entry.tag);
    if (matched) return matched;
  }
  return "en";
}

export function getCatalog(locale: Locale = "en"): LocaleCatalog {
  return CATALOGS[locale];
}

export function formatMessage(template: string, params: Record<string, string>): string {
  let out = template;
  for (const [key, value] of Object.entries(params)) {
    out = out.replaceAll(`{${key}}`, value);
  }
  return out;
}
