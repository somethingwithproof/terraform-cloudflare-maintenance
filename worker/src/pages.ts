// Per-hostname and per-path page text, from the PAGES binding.

export interface PageOverride {
  /** Exact hostname to match; any host when absent. */
  host?: string;
  /** Path prefix, matched on whole segments ("/api" matches "/api/x", not "/apix"). */
  pathPrefix: string;
  title?: string;
  message?: string;
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" && value !== "" ? value : undefined;
}

/**
 * Parses the PAGES binding: a JSON array of {host, path_prefix, title,
 * message}. Entries that are not objects or have a path prefix not starting
 * with "/" are dropped, like malformed allowlist entries.
 */
export function parsePages(json: string | undefined): PageOverride[] {
  let list: unknown;
  try {
    list = JSON.parse(json ?? "[]");
  } catch {
    return [];
  }
  if (!Array.isArray(list)) return [];
  const pages: PageOverride[] = [];
  for (const entry of list as unknown[]) {
    if (typeof entry !== "object" || entry === null) continue;
    const raw = entry as Record<string, unknown>;
    const pathPrefix = optionalString(raw.path_prefix) ?? "/";
    if (!pathPrefix.startsWith("/")) continue;
    const page: PageOverride = { pathPrefix };
    const host = optionalString(raw.host);
    const title = optionalString(raw.title);
    const message = optionalString(raw.message);
    if (host !== undefined) page.host = host.toLowerCase();
    if (title !== undefined) page.title = title;
    if (message !== undefined) page.message = message;
    pages.push(page);
  }
  return pages;
}

function matchesPath(pathname: string, prefix: string): boolean {
  if (prefix.endsWith("/")) return pathname.startsWith(prefix);
  return pathname === prefix || pathname.startsWith(`${prefix}/`);
}

/**
 * The most specific page for a URL: a host match beats any host, then the
 * longest path prefix wins.
 */
export function selectPage(pages: readonly PageOverride[], url: URL): PageOverride | undefined {
  let best: PageOverride | undefined;
  let bestScore = -1;
  for (const page of pages) {
    if (page.host !== undefined && page.host !== url.hostname) continue;
    if (!matchesPath(url.pathname, page.pathPrefix)) continue;
    const score = (page.host === undefined ? 0 : 1 << 16) + page.pathPrefix.length;
    if (score > bestScore) {
      best = page;
      bestScore = score;
    }
  }
  return best;
}
