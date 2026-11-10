// CloudFlare Worker for maintenance mode - because sometimes things break and we need to fix them
// without everyone watching us frantically debug at 3am
addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  // Check if we're in a scheduled maintenance window
  const now = new Date();
  const inMaintenanceWindow = checkMaintenanceWindow(now);

  // First, check if we're actually in maintenance mode
  // If not and not in a maintenance window, let traffic through
  if (
    (!MAINTENANCE_ENABLED || MAINTENANCE_ENABLED === "false") &&
    !inMaintenanceWindow
  ) {
    return fetch(request);
  }

  // CF-Connecting-IP is set by Cloudflare's edge and cannot be spoofed by the
  // client. X-Forwarded-For can, so it is never consulted.
  const clientIP = request.headers.get("CF-Connecting-IP");
  if (isAllowedIp(clientIP, parseJsonList(ALLOWED_IPS))) {
    return fetch(request);
  }

  const country = request.cf?.country;
  if (country && parseJsonList(ALLOWED_REGIONS).includes(country)) {
    return fetch(request);
  }

  // Validate and sanitize logo URL to prevent XSS
  let logoHtml = "";
  if (LOGO_URL && isValidHttpsUrl(LOGO_URL)) {
    // Additional check for javascript: and data: URIs
    const lowerUrl = LOGO_URL.toLowerCase();
    if (!lowerUrl.startsWith("javascript:") && !lowerUrl.startsWith("data:")) {
      const sanitizedUrl = LOGO_URL.replace(/['"<>`&]/g, "");
      logoHtml = `<img src="${sanitizedUrl}" alt="Logo" style="max-width: 200px; margin-bottom: 1rem;">`;
    }
  }

  // Alright, time to show everyone the "We'll be right back" page
  // This HTML is nicer than the default 503 error at least
  const customStyles = (CUSTOM_CSS || "").replace(/<\/style>/gi, "");

  // Sanitize contact email to prevent XSS
  const sanitizedEmail = sanitizeEmail(CONTACT_EMAIL || "");

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(MAINTENANCE_TITLE) || "Maintenance Mode"}</title>
  <style>
    /* Making it look professional even when things aren't working */
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
    ${customStyles}
  </style>
</head>
<body>
  <div class="container">
    ${logoHtml}
    <h1>${escapeHtml(MAINTENANCE_TITLE) || "Maintenance Mode"}</h1>
    <p>${escapeHtml(MAINTENANCE_MESSAGE) || "We are currently performing scheduled maintenance. We will be back shortly."}</p>
    ${getMaintenanceWindowMessage()}
    ${sanitizedEmail ? `<p class="contact">Contact: <a href="mailto:${sanitizedEmail}">${sanitizedEmail}</a></p>` : ""}
  </div>
</body>
</html>`;

  // Return a 503 because we're being honest about the service being unavailable
  // The Retry-After header is optimistic, but hey, we can hope
  return new Response(html, {
    status: 503,
    headers: {
      "Content-Type": "text/html;charset=UTF-8",
      "Cache-Control": "no-store, no-cache, must-revalidate", // Don't cache this disaster
      "Retry-After": "3600", // Try again in an hour (fingers crossed we're done by then)
      "Content-Security-Policy":
        "default-src 'none'; style-src 'unsafe-inline'; img-src https:;",
      "X-Content-Type-Options": "nosniff",
      "X-Frame-Options": "DENY",
      "Referrer-Policy": "no-referrer",
    },
  });
}

function checkMaintenanceWindow(now) {
  // Check if we're within a scheduled maintenance window
  const startTime = MAINTENANCE_WINDOW_START;
  const endTime = MAINTENANCE_WINDOW_END;

  if (!startTime || !endTime) {
    return false;
  }

  try {
    const start = new Date(startTime);
    const end = new Date(endTime);
    return now >= start && now <= end;
  } catch {
    // Invalid dates, ignore the maintenance window
    return false;
  }
}

function getMaintenanceWindowMessage() {
  const startTime = MAINTENANCE_WINDOW_START;
  const endTime = MAINTENANCE_WINDOW_END;

  if (!startTime || !endTime) {
    return "";
  }

  try {
    const end = new Date(endTime);
    if (Number.isNaN(end.getTime())) return "";
    return `<p style="font-size: 0.9rem; color: #888;">Expected completion: ${end.toUTCString()}</p>`;
  } catch {
    return "";
  }
}

function isValidHttpsUrl(url) {
  try {
    const parsedUrl = new URL(url);
    return parsedUrl.protocol === "https:";
  } catch {
    return false;
  }
}

function escapeHtml(str) {
  if (!str) return "";
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function sanitizeEmail(email) {
  // Basic email validation and sanitization
  const emailRegex = /^[^\s@<>'"]+@[^\s@<>'"]+\.[^\s@<>'"]+$/;
  if (!emailRegex.test(email)) {
    return "";
  }
  // Remove potentially dangerous characters
  return email.replace(/[<>'"&]/g, "");
}

// Parse a JSON array binding; anything else counts as an empty list.
function parseJsonList(json) {
  try {
    const list = JSON.parse(json || "[]");
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}

// True when ip matches an allowlist entry: a single address or a CIDR range,
// IPv4 or IPv6. Addresses are compared numerically, so every IPv6 spelling of
// an address matches, and IPv4-mapped IPv6 (::ffff:192.0.2.1) matches IPv4.
function isAllowedIp(ip, entries) {
  const addr = parseIp(ip);
  if (!addr) return false;
  return entries.some((entry) => {
    const net = parseCidr(entry);
    if (!net || net.version !== addr.version) return false;
    const shift = BigInt((net.version === 4 ? 32 : 128) - net.prefix);
    return addr.value >> shift === net.value >> shift;
  });
}

// Parse "address" or "address/prefix". An IPv4-mapped IPv6 network needs a
// prefix of at least 96 and is converted to the equivalent IPv4 network.
function parseCidr(entry) {
  if (typeof entry !== "string") return null;
  const [text, prefixText, extra] = entry.trim().split("/");
  if (extra !== undefined) return null;
  const addr = parseIp(text);
  if (!addr) return null;
  const written = addr.mapped ? 128 : addr.version === 4 ? 32 : 128;
  let prefix = written;
  if (prefixText !== undefined) {
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

// Parse an IPv4 or IPv6 address to { version, value: BigInt, mapped }.
function parseIp(text) {
  if (typeof text !== "string") return null;
  const s = text.trim();
  if (!s.includes(":")) {
    const value = parseIPv4(s);
    return value === null ? null : { version: 4, value, mapped: false };
  }
  const value = parseIPv6(s);
  if (value === null) return null;
  if (value >> 32n === 0xffffn) {
    return { version: 4, value: value & 0xffffffffn, mapped: true };
  }
  return { version: 6, value, mapped: false };
}

function parseIPv4(s) {
  const parts = s.split(".");
  if (parts.length !== 4) return null;
  let value = 0n;
  for (const part of parts) {
    // Reject leading zeros, which some parsers read as octal.
    if (!/^(0|[1-9]\d{0,2})$/.test(part) || Number(part) > 255) return null;
    value = (value << 8n) | BigInt(part);
  }
  return value;
}

function parseIPv6(s) {
  let text = s;
  // Rewrite a trailing dotted IPv4 part (::ffff:192.0.2.1) as two hex groups.
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
  const zeros = Array(halves.length === 2 ? missing : 0).fill("0");
  const groups = [...left, ...zeros, ...right];
  let value = 0n;
  for (const group of groups) {
    if (!/^[0-9a-f]{1,4}$/i.test(group)) return null;
    value = (value << 16n) | BigInt(Number.parseInt(group, 16));
  }
  return value;
}
