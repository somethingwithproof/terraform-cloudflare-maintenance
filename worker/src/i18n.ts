// SPDX-FileCopyrightText: 2026 Thomas Vincent <thomasvincent@gmail.com>
// SPDX-License-Identifier: MIT

import afZA from "./locales/af-ZA.json";
import amET from "./locales/am-ET.json";
import ar from "./locales/ar.json";
import arEG from "./locales/ar-EG.json";
import arMA from "./locales/ar-MA.json";
import bn from "./locales/bn.json";
import de from "./locales/de.json";
import en from "./locales/en.json";
import es from "./locales/es.json";
import fa from "./locales/fa.json";
import fil from "./locales/fil.json";
import fr from "./locales/fr.json";
import frMA from "./locales/fr-MA.json";
import frSN from "./locales/fr-SN.json";
import haNG from "./locales/ha-NG.json";
import he from "./locales/he.json";
import hi from "./locales/hi.json";
import id from "./locales/id.json";
import igNG from "./locales/ig-NG.json";
import it from "./locales/it.json";
import ja from "./locales/ja.json";
import ko from "./locales/ko.json";
import mgMG from "./locales/mg-MG.json";
import mr from "./locales/mr.json";
import ms from "./locales/ms.json";
import nl from "./locales/nl.json";
import pl from "./locales/pl.json";
import ptBR from "./locales/pt-BR.json";
import ru from "./locales/ru.json";
import rwRW from "./locales/rw-RW.json";
import soSO from "./locales/so-SO.json";
import sv from "./locales/sv.json";
import swKE from "./locales/sw-KE.json";
import ta from "./locales/ta.json";
import te from "./locales/te.json";
import th from "./locales/th.json";
import tr from "./locales/tr.json";
import uk from "./locales/uk.json";
import ur from "./locales/ur.json";
import vi from "./locales/vi.json";
import xhZA from "./locales/xh-ZA.json";
import yoNG from "./locales/yo-NG.json";
import zhCN from "./locales/zh-CN.json";
import zhTW from "./locales/zh-TW.json";
import zuZA from "./locales/zu-ZA.json";

export const SUPPORTED_LOCALES = [
  "en", "de", "es", "fr", "it", "pt-BR", "nl", "ru", "uk",
  "ja", "ko", "zh-CN", "zh-TW", "ar", "hi", "pl", "tr", "sv", "vi", "id",
  "af-ZA", "am-ET", "ar-EG", "ar-MA", "fr-MA", "fr-SN", "ha-NG", "ig-NG",
  "mg-MG", "rw-RW", "so-SO", "sw-KE", "xh-ZA", "yo-NG", "zu-ZA",
  "bn", "fa", "he", "mr", "ta", "te", "th", "ur", "ms", "fil",
] as const;

export type Locale = (typeof SUPPORTED_LOCALES)[number];

const RTL_LOCALES = new Set<Locale>(["ar", "ar-EG", "ar-MA", "fa", "he", "ur"]);

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
  "af-ZA": afZA,
  "am-ET": amET,
  "ar-EG": arEG,
  "ar-MA": arMA,
  "fr-MA": frMA,
  "fr-SN": frSN,
  "ha-NG": haNG,
  "ig-NG": igNG,
  "mg-MG": mgMG,
  "rw-RW": rwRW,
  "so-SO": soSO,
  "sw-KE": swKE,
  "xh-ZA": xhZA,
  "yo-NG": yoNG,
  "zu-ZA": zuZA,
  bn,
  fa,
  he,
  mr,
  ta,
  te,
  th,
  ur,
  ms,
  fil,
};

const BASE_ALIASES: Record<string, Locale> = {
  af: "af-ZA",
  am: "am-ET",
  ha: "ha-NG",
  ig: "ig-NG",
  in: "id",
  iw: "he",
  mg: "mg-MG",
  pt: "pt-BR",
  rw: "rw-RW",
  so: "so-SO",
  sw: "sw-KE",
  tl: "fil",
  xh: "xh-ZA",
  yo: "yo-NG",
  zu: "zu-ZA",
};

export function isRtl(locale: Locale): boolean {
  return RTL_LOCALES.has(locale);
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

  for (const loc of SUPPORTED_LOCALES) {
    if (loc.toLowerCase() === lower) return loc;
  }

  const base = lower.split("-")[0] ?? "";
  if (base === "zh") {
    if (lower.includes("-hans")) return "zh-CN";
    if (lower.includes("-hant") || lower.includes("-tw") || lower.includes("-hk") || lower.includes("-mo")) {
      return "zh-TW";
    }
    return "zh-CN";
  }
  if (Object.hasOwn(BASE_ALIASES, base)) {
    return BASE_ALIASES[base] ?? null;
  }

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
  const excluded = new Set<Locale>();
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
    if (!valid) continue;
    if (q === 0) {
      const denied = matchLocale(tag);
      if (denied) excluded.add(denied);
      continue;
    }
    weighted.push({ tag, q, index: i });
  }

  weighted.sort((a, b) => (b.q !== a.q ? b.q - a.q : a.index - b.index));

  for (const entry of weighted) {
    if (entry.tag === "*") {
      if (!excluded.has("en")) return "en";
      for (const loc of SUPPORTED_LOCALES) {
        if (!excluded.has(loc)) return loc;
      }
      return "en";
    }
    const matched = matchLocale(entry.tag);
    if (matched && !excluded.has(matched)) return matched;
  }
  return "en";
}

export function getCatalog(locale: Locale = "en"): LocaleCatalog {
  return CATALOGS[locale];
}

export function formatMessage(template: string, params: Record<string, string>): string {
  return template.replace(/\{([a-zA-Z0-9_]+)\}/g, (match, key: string) =>
    Object.hasOwn(params, key) ? (params[key] ?? match) : match,
  );
}
