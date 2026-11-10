// Maintenance page Worker. Terraform deploys the bundle built from this file
// (dist/index.js) and sets every Env value as a binding; see main.tf.

import { renderPage } from "./html";
import { isAllowedIp } from "./ip";
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
}

export const CONTENT_SECURITY_POLICY =
  "default-src 'none'; style-src 'unsafe-inline'; img-src https:; form-action 'none'; base-uri 'none'; frame-ancestors 'none'";

export async function handleRequest(request: Request, env: Env, now: Date = new Date()): Promise<Response> {
  const window = parseWindow(env.MAINTENANCE_WINDOW_START, env.MAINTENANCE_WINDOW_END);
  if (!isMaintenanceActive(env.MAINTENANCE_ENABLED === "true", window, now)) {
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

  const html = renderPage({
    title: env.MAINTENANCE_TITLE ?? "",
    message: env.MAINTENANCE_MESSAGE ?? "",
    contactEmail: env.CONTACT_EMAIL ?? "",
    customCss: env.CUSTOM_CSS ?? "",
    logoUrl: env.LOGO_URL ?? "",
    windowEnd: window?.end ?? null,
  });

  // 503 tells clients and crawlers the outage is temporary; Retry-After says
  // when to come back.
  return new Response(html, {
    status: 503,
    headers: {
      "Content-Type": "text/html;charset=UTF-8",
      "Cache-Control": "no-store, no-cache, must-revalidate",
      "Retry-After": String(retryAfterSeconds(window, env.RETRY_AFTER, now)),
      "Content-Security-Policy": CONTENT_SECURITY_POLICY,
      "X-Content-Type-Options": "nosniff",
      "X-Frame-Options": "DENY",
      "Referrer-Policy": "no-referrer",
    },
  });
}

export default {
  fetch(request, env) {
    return handleRequest(request, env);
  },
} satisfies ExportedHandler<Env>;
