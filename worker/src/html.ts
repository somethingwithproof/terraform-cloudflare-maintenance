// Escaping and rendering of the maintenance page. Every value from the
// bindings is escaped for the context it lands in.

export function escapeHtml(str: string | null | undefined): string {
  if (!str) return "";
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * Custom CSS goes inside <style>, where HTML escaping does not apply and the
 * first "</style" in any spelling ends the element. Writing every "<" as the
 * CSS escape \3C leaves no tag the HTML parser can see, and still means "<"
 * to CSS (for example inside a content string).
 */
export function escapeCss(css: string | null | undefined): string {
  return (css ?? "").replace(/</g, "\\3C ");
}

export function isValidHttpsUrl(url: string | null | undefined): boolean {
  if (!url) return false;
  try {
    return new URL(url).protocol === "https:";
  } catch {
    return false;
  }
}

/**
 * The address if it looks like one (local@domain.tld) and contains no markup,
 * otherwise "". Checked without a backtracking regex, because the contact
 * address is a binding of any length.
 */
export function sanitizeEmail(email: string | null | undefined): string {
  if (!email || /[\s<>'"]/.test(email)) return "";
  const at = email.indexOf("@");
  if (at <= 0 || at !== email.lastIndexOf("@")) return "";
  // A dot with something on both sides, somewhere in the domain.
  if (!email.slice(at + 2, -1).includes(".")) return "";
  return email.replace(/&/g, "");
}

export interface PageContent {
  title: string;
  message: string;
  contactEmail: string;
  customCss: string;
  logoUrl: string;
  /** End of the open window, shown as the expected completion time. */
  windowEnd: Date | null;
}

export const DEFAULT_TITLE = "Maintenance Mode";
export const DEFAULT_MESSAGE =
  "We are currently performing scheduled maintenance. We will be back shortly.";

export function renderPage(page: PageContent): string {
  const title = escapeHtml(page.title) || DEFAULT_TITLE;
  const message = escapeHtml(page.message) || DEFAULT_MESSAGE;
  const email = sanitizeEmail(page.contactEmail);
  // Only HTTPS logos; the URL is HTML-escaped for the attribute it sits in.
  const logo = isValidHttpsUrl(page.logoUrl)
    ? `<img src="${escapeHtml(page.logoUrl)}" alt="Logo" style="max-width: 200px; margin-bottom: 1rem;">`
    : "";
  const completion = page.windowEnd
    ? `<p style="font-size: 0.9rem; color: #888;">Expected completion: ${page.windowEnd.toUTCString()}</p>`
    : "";
  const contact = email
    ? `<p class="contact">Contact: <a href="mailto:${email}">${email}</a></p>`
    : "";

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
