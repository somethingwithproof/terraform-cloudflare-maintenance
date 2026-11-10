// Maintenance page Worker. Terraform deploys the bundle built from this file
// (dist/index.js) and sets every Env value as a binding; see main.tf.

import { renderPage } from "./html";
import { isAllowedIp } from "./ip";
import { parsePages, selectPage } from "./pages";
import { isMaintenanceActive, parseJsonList, parseWindow, retryAfterSeconds } from "./schedule";

export interface Env {
  MAINTENANCE_ENABLED?: string;
  MAINTENANCE_TITLE?: string;
  MAINTENANCE_MESSAGE?: string;
  CONTACT_EMAIL?: string;
  CUSTOM_CSS?: string;
  LOGO_URL?: string;
  MAINTENANCE_WINDOW_START?: string;
  MAINTENANCE_WINDOW_END?: string;
  RETRY_AFTER?: string;
  /** JSON array of addresses and CIDR ranges. */
  ALLOWED_IPS?: string;
  /** JSON array of ISO 3166-1 alpha-2 country codes. */
  ALLOWED_REGIONS?: string;
  /** Path of the JSON status endpoint; empty disables it. */
  STATUS_PATH?: string;
  /** JSON array of per-host and per-path page text; see pages.ts. */
  PAGES?: string;
}

export const CONTENT_SECURITY_POLICY =
  "default-src 'none'; style-src 'unsafe-inline'; img-src https:; form-action 'none'; base-uri 'none'; frame-ancestors 'none'";

const PAGE_HEADERS = {
  "Content-Type": "text/html; charset=utf-8",
  "Cache-Control": "no-store, no-cache, must-revalidate",
  "Content-Security-Policy": CONTENT_SECURITY_POLICY,
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "no-referrer",
} as const;

/** What the status endpoint returns. It holds nothing an allowlist could leak. */
export interface MaintenanceStatus {
  maintenance: boolean;
  window: { start_time: string; end_time: string } | null;
  retry_after_seconds: number | null;
}

function statusResponse(request: Request, status: MaintenanceStatus): Response {
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
      "Access-Control-Allow-Origin": "*",
    },
  });
}

export async function handleRequest(request: Request, env: Env, now: Date = new Date()): Promise<Response> {
  const window = parseWindow(env.MAINTENANCE_WINDOW_START, env.MAINTENANCE_WINDOW_END);
  const active = isMaintenanceActive(env.MAINTENANCE_ENABLED === "true", window, now);
  const retryAfter = retryAfterSeconds(window, env.RETRY_AFTER, now);
  const url = new URL(request.url);

  // Answered for everyone, allowlisted or not, and never passed to the origin.
  if (env.STATUS_PATH && url.pathname === env.STATUS_PATH) {
    return statusResponse(request, {
      maintenance: active,
      window: window ? { start_time: window.start.toISOString(), end_time: window.end.toISOString() } : null,
      retry_after_seconds: active ? retryAfter : null,
    });
  }

  if (!active) {
    return fetch(request);
  }

  // CF-Connecting-IP is set by Cloudflare's edge and cannot be spoofed by the
  // client. X-Forwarded-For can, so it is never consulted.
  if (isAllowedIp(request.headers.get("CF-Connecting-IP"), parseJsonList(env.ALLOWED_IPS))) {
    return fetch(request);
  }

  const country = request.cf?.country;
  if (typeof country === "string" && parseJsonList(env.ALLOWED_REGIONS).includes(country)) {
    return fetch(request);
  }

  const page = selectPage(parsePages(env.PAGES), url);
  const html = renderPage({
    title: page?.title ?? env.MAINTENANCE_TITLE ?? "",
    message: page?.message ?? env.MAINTENANCE_MESSAGE ?? "",
    contactEmail: env.CONTACT_EMAIL ?? "",
    customCss: env.CUSTOM_CSS ?? "",
    logoUrl: env.LOGO_URL ?? "",
    windowEnd: window?.end ?? null,
  });

  // 503 tells clients and crawlers the outage is temporary; Retry-After says
  // when to come back. HEAD gets the same status and headers without a body.
  return new Response(request.method === "HEAD" ? null : html, {
    status: 503,
    headers: { ...PAGE_HEADERS, "Retry-After": String(retryAfter) },
  });
}

export default {
  fetch(request, env) {
    return handleRequest(request, env);
  },
} satisfies ExportedHandler<Env>;
