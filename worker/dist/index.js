var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// src/html.ts
function escapeHtml(str) {
  if (!str) return "";
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}
__name(escapeHtml, "escapeHtml");
function escapeCss(css) {
  return (css ?? "").replace(/</g, "\\3C ");
}
__name(escapeCss, "escapeCss");
function isValidHttpsUrl(url) {
  if (!url) return false;
  try {
    return new URL(url).protocol === "https:";
  } catch {
    return false;
  }
}
__name(isValidHttpsUrl, "isValidHttpsUrl");
function sanitizeEmail(email) {
  if (!email || /[\s<>'"]/.test(email)) return "";
  const at = email.indexOf("@");
  if (at <= 0 || at !== email.lastIndexOf("@")) return "";
  if (!email.slice(at + 2, -1).includes(".")) return "";
  return email.replace(/&/g, "");
}
__name(sanitizeEmail, "sanitizeEmail");
var DEFAULT_TITLE = "Maintenance Mode";
var DEFAULT_MESSAGE = "We are currently performing scheduled maintenance. We will be back shortly.";
function renderPage(page) {
  const title = escapeHtml(page.title) || DEFAULT_TITLE;
  const message = escapeHtml(page.message) || DEFAULT_MESSAGE;
  const email = sanitizeEmail(page.contactEmail);
  const logo = isValidHttpsUrl(page.logoUrl) ? `<img src="${escapeHtml(page.logoUrl)}" alt="Logo" style="max-width: 200px; margin-bottom: 1rem;">` : "";
  const completion = page.windowEnd ? `<p style="font-size: 0.9rem; color: #888;">Expected completion: ${page.windowEnd.toUTCString()}</p>` : "";
  const contact = email ? `<p class="contact">Contact: <a href="mailto:${email}">${email}</a></p>` : "";
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      text-align: center;
    }
    .container {
      background: white;
      padding: 3rem;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      max-width: 500px;
    }
    h1 { color: #333; margin-bottom: 1rem; }
    p { color: #666; line-height: 1.6; }
    .contact { margin-top: 2rem; font-size: 0.9rem; color: #999; }
    ${escapeCss(page.customCss)}
  </style>
</head>
<body>
  <div class="container">
    ${logo}
    <h1>${title}</h1>
    <p>${message}</p>
    ${completion}
    ${contact}
  </div>
</body>
</html>`;
}
__name(renderPage, "renderPage");

// src/ip.ts
function isAllowedIp(ip, entries) {
  const addr = parseIp(ip);
  if (!addr) return false;
  return entries.some((entry) => {
    const net = parseCidr(entry);
    if (net?.version !== addr.version) return false;
    const shift = BigInt((net.version === 4 ? 32 : 128) - net.prefix);
    return addr.value >> shift === net.value >> shift;
  });
}
__name(isAllowedIp, "isAllowedIp");
function parseCidr(entry) {
  if (typeof entry !== "string") return null;
  const [text, prefixText, extra] = entry.trim().split("/");
  if (extra !== void 0) return null;
  const addr = parseIp(text);
  if (!addr) return null;
  const written = addr.mapped || addr.version === 6 ? 128 : 32;
  let prefix = written;
  if (prefixText !== void 0) {
    if (!/^\d{1,3}$/.test(prefixText)) return null;
    prefix = Number(prefixText);
  }
  if (prefix > written) return null;
  if (addr.mapped) {
    if (prefix < 96) return null;
    prefix -= 96;
  }
  return { version: addr.version, value: addr.value, prefix };
}
__name(parseCidr, "parseCidr");
function parseIp(text) {
  if (typeof text !== "string") return null;
  const s = text.trim();
  if (!s.includes(":")) {
    const value2 = parseIPv4(s);
    return value2 === null ? null : { version: 4, value: value2, mapped: false };
  }
  const value = parseIPv6(s);
  if (value === null) return null;
  if (value >> 32n === 0xffffn) {
    return { version: 4, value: value & 0xffffffffn, mapped: true };
  }
  return { version: 6, value, mapped: false };
}
__name(parseIp, "parseIp");
function parseIPv4(s) {
  const parts = s.split(".");
  if (parts.length !== 4) return null;
  let value = 0n;
  for (const part of parts) {
    if (!/^(0|[1-9]\d{0,2})$/.test(part) || Number(part) > 255) return null;
    value = value << 8n | BigInt(part);
  }
  return value;
}
__name(parseIPv4, "parseIPv4");
function parseIPv6(s) {
  let text = s;
  const lastColon = text.lastIndexOf(":");
  if (text.slice(lastColon + 1).includes(".")) {
    const v4 = parseIPv4(text.slice(lastColon + 1));
    if (v4 === null) return null;
    const high = (v4 >> 16n).toString(16);
    const low = (v4 & 0xffffn).toString(16);
    text = `${text.slice(0, lastColon + 1)}${high}:${low}`;
  }
  const halves = text.split("::");
  if (halves.length > 2) return null;
  const left = halves[0] ? halves[0].split(":") : [];
  const right = halves.length === 2 && halves[1] ? halves[1].split(":") : [];
  const missing = 8 - left.length - right.length;
  if (halves.length === 1 ? missing !== 0 : missing < 1) return null;
  const zeros = Array.from({ length: halves.length === 2 ? missing : 0 }, () => "0");
  let value = 0n;
  for (const group of [...left, ...zeros, ...right]) {
    if (!/^[0-9a-f]{1,4}$/i.test(group)) return null;
    value = value << 16n | BigInt(Number.parseInt(group, 16));
  }
  return value;
}
__name(parseIPv6, "parseIPv6");

// src/pages.ts
function optionalString(value) {
  return typeof value === "string" && value !== "" ? value : void 0;
}
__name(optionalString, "optionalString");
function parsePages(json) {
  let list;
  try {
    list = JSON.parse(json ?? "[]");
  } catch {
    return [];
  }
  if (!Array.isArray(list)) return [];
  const pages = [];
  for (const entry of list) {
    if (typeof entry !== "object" || entry === null) continue;
    const raw = entry;
    const pathPrefix = optionalString(raw.path_prefix) ?? "/";
    if (!pathPrefix.startsWith("/")) continue;
    const page = { pathPrefix };
    const host = optionalString(raw.host);
    const title = optionalString(raw.title);
    const message = optionalString(raw.message);
    if (host !== void 0) page.host = host.toLowerCase();
    if (title !== void 0) page.title = title;
    if (message !== void 0) page.message = message;
    pages.push(page);
  }
  return pages;
}
__name(parsePages, "parsePages");
function matchesPath(pathname, prefix) {
  if (prefix.endsWith("/")) return pathname.startsWith(prefix);
  return pathname === prefix || pathname.startsWith(`${prefix}/`);
}
__name(matchesPath, "matchesPath");
function selectPage(pages, url) {
  let best;
  let bestScore = -1;
  for (const page of pages) {
    if (page.host !== void 0 && page.host !== url.hostname) continue;
    if (!matchesPath(url.pathname, page.pathPrefix)) continue;
    const score = (page.host === void 0 ? 0 : 1 << 16) + page.pathPrefix.length;
    if (score > bestScore) {
      best = page;
      bestScore = score;
    }
  }
  return best;
}
__name(selectPage, "selectPage");

// src/schedule.ts
function parseWindow(start, end) {
  if (!start || !end) return null;
  const window = { start: new Date(start), end: new Date(end) };
  if (Number.isNaN(window.start.getTime()) || Number.isNaN(window.end.getTime())) {
    return null;
  }
  return window;
}
__name(parseWindow, "parseWindow");
function isInWindow(window, now) {
  return now >= window.start && now < window.end;
}
__name(isInWindow, "isInWindow");
function isMaintenanceActive(enabled, window, now) {
  return window ? isInWindow(window, now) : enabled;
}
__name(isMaintenanceActive, "isMaintenanceActive");
var DEFAULT_RETRY_AFTER = 3600;
function retryAfterSeconds(window, configured, now) {
  if (window && isInWindow(window, now)) {
    return Math.max(1, Math.ceil((window.end.getTime() - now.getTime()) / 1e3));
  }
  const value = Number.parseInt(configured ?? "", 10);
  return Number.isInteger(value) && value > 0 ? value : DEFAULT_RETRY_AFTER;
}
__name(retryAfterSeconds, "retryAfterSeconds");
function parseJsonList(json) {
  try {
    const list = JSON.parse(json ?? "[]");
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}
__name(parseJsonList, "parseJsonList");

// src/toggle.ts
var STATE_KEY = "state";
function parseOverride(value) {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return null;
  const raw = value;
  const override = {};
  if ("enabled" in raw) {
    if (typeof raw.enabled !== "boolean") return null;
    override.enabled = raw.enabled;
  }
  if ("window" in raw) {
    if (raw.window === null) {
      override.window = null;
    } else {
      const w = raw.window;
      const start = typeof w?.start_time === "string" ? w.start_time : void 0;
      const end = typeof w?.end_time === "string" ? w.end_time : void 0;
      const window = parseWindow(start, end);
      if (!window || window.end <= window.start) return null;
      override.window = window;
    }
  }
  for (const field of ["title", "message"]) {
    if (field in raw) {
      const text = raw[field];
      if (typeof text !== "string") return null;
      override[field] = text;
    }
  }
  return override;
}
__name(parseOverride, "parseOverride");
async function readOverride(kv, cacheTtl) {
  let value;
  try {
    value = await kv.get(STATE_KEY, { type: "json", cacheTtl });
  } catch {
    return { kind: "error" };
  }
  if (value === null) return { kind: "none" };
  const override = parseOverride(value);
  return override ? { kind: "override", override } : { kind: "error" };
}
__name(readOverride, "readOverride");
function cacheTtlSeconds(configured) {
  const value = Number(configured);
  return Number.isInteger(value) && value >= 30 ? value : 60;
}
__name(cacheTtlSeconds, "cacheTtlSeconds");

// src/index.ts
var CONTENT_SECURITY_POLICY = "default-src 'none'; style-src 'unsafe-inline'; img-src https:; form-action 'none'; base-uri 'none'; frame-ancestors 'none'";
var PAGE_HEADERS = {
  "Content-Type": "text/html; charset=utf-8",
  "Cache-Control": "no-store, no-cache, must-revalidate",
  "Content-Security-Policy": CONTENT_SECURITY_POLICY,
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "no-referrer"
};
function statusResponse(request, status) {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return new Response(null, { status: 405, headers: { Allow: "GET, HEAD", "Cache-Control": "no-store" } });
  }
  const body = JSON.stringify(status);
  return new Response(request.method === "HEAD" ? null : body, {
    status: 200,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      // Lets a status page on another origin poll it.
      "Access-Control-Allow-Origin": "*"
    }
  });
}
__name(statusResponse, "statusResponse");
async function handleRequest(request, env, now = /* @__PURE__ */ new Date()) {
  let enabled = env.MAINTENANCE_ENABLED === "true";
  let window = parseWindow(env.MAINTENANCE_WINDOW_START, env.MAINTENANCE_WINDOW_END);
  let title;
  let message;
  let active;
  if (env.MAINTENANCE_KV) {
    const toggle = await readOverride(env.MAINTENANCE_KV, cacheTtlSeconds(env.KV_CACHE_TTL));
    if (toggle.kind === "override") {
      const o = toggle.override;
      enabled = o.enabled ?? enabled;
      if (o.window !== void 0) window = o.window;
      title = o.title;
      message = o.message;
    }
    active = toggle.kind === "error" && env.KV_FAILURE_MODE === "closed" || isMaintenanceActive(enabled, window, now);
  } else {
    active = isMaintenanceActive(enabled, window, now);
  }
  const retryAfter = retryAfterSeconds(window, env.RETRY_AFTER, now);
  const url = new URL(request.url);
  if (env.STATUS_PATH && url.pathname === env.STATUS_PATH) {
    return statusResponse(request, {
      maintenance: active,
      window: window ? { start_time: window.start.toISOString(), end_time: window.end.toISOString() } : null,
      retry_after_seconds: active ? retryAfter : null
    });
  }
  if (!active) {
    return fetch(request);
  }
  if (isAllowedIp(request.headers.get("CF-Connecting-IP"), parseJsonList(env.ALLOWED_IPS))) {
    return fetch(request);
  }
  const country = request.cf?.country;
  if (typeof country === "string" && parseJsonList(env.ALLOWED_REGIONS).includes(country)) {
    return fetch(request);
  }
  const page = selectPage(parsePages(env.PAGES), url);
  const html = renderPage({
    title: title ?? page?.title ?? env.MAINTENANCE_TITLE ?? "",
    message: message ?? page?.message ?? env.MAINTENANCE_MESSAGE ?? "",
    contactEmail: env.CONTACT_EMAIL ?? "",
    customCss: env.CUSTOM_CSS ?? "",
    logoUrl: env.LOGO_URL ?? "",
    windowEnd: window?.end ?? null
  });
  return new Response(request.method === "HEAD" ? null : html, {
    status: 503,
    headers: { ...PAGE_HEADERS, "Retry-After": String(retryAfter) }
  });
}
__name(handleRequest, "handleRequest");
var index_default = {
  fetch(request, env) {
    return handleRequest(request, env);
  }
};
export {
  CONTENT_SECURITY_POLICY,
  index_default as default,
  handleRequest
};
