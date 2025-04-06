/// <reference types="@cloudflare/workers-types" />

// Import configuration
import config from './config.json';

// Define interfaces
interface MaintenanceConfig {
  enabled: boolean;
  maintenance_title: string;
  contact_email: string;
  allowed_ips: string; // JSON string of IP addresses
  maintenance_window: string | null; // JSON string or null
  custom_css: string;
  logo_url: string;
}

interface MaintenanceWindow {
  start_time: string;
  end_time: string;
}

// Global variables
const typedConfig = config as MaintenanceConfig;
let allowedIPs: string[] = [];
let maintenanceWindow: MaintenanceWindow | null = null;

// Initialize configuration
try {
  allowedIPs = JSON.parse(typedConfig.allowed_ips);
  if (typedConfig.maintenance_window && typedConfig.maintenance_window !== "null") {
    maintenanceWindow = JSON.parse(typedConfig.maintenance_window);
  }
} catch (e) {
  console.error("Error parsing configuration:", e);
}

// Event listener for incoming requests
addEventListener("fetch", (event: FetchEvent) => {
  event.respondWith(handleRequest(event.request, event));
});

/**
 * Handle incoming requests
 * @param request - The incoming request
 * @param event - The fetch event
 * @returns Response
 */
export async function handleRequest(request: Request, event: FetchEvent): Promise<Response> {
  // Log request for analytics
  logRequest(request, event);

  // Check if maintenance mode is enabled
  if (!typedConfig.enabled) {
    return fetch(request);
  }

  // Check if request is from an allowed IP
  if (isAllowedIP(request)) {
    return fetch(request);
  }

  // Check if we're within the maintenance window
  if (maintenanceWindow && !isWithinMaintenanceWindow(maintenanceWindow)) {
    return fetch(request);
  }

  // Serve maintenance page
  return serveMaintenancePage(request);
}

/**
 * Check if the request is from an allowed IP
 * @param request - The incoming request
 * @returns boolean
 */
export function isAllowedIP(request: Request): boolean {
  // Get client IP from CF-Connecting-IP header
  const clientIP = request.headers.get('CF-Connecting-IP');

  if (!clientIP || allowedIPs.length === 0) {
    return false;
  }

  return allowedIPs.includes(clientIP);
}

/**
 * Check if current time is within maintenance window
 * @param window - The maintenance window
 * @returns boolean
 */
export function isWithinMaintenanceWindow(window: MaintenanceWindow): boolean {
  if (!window.start_time || !window.end_time) {
    return true; // If window is incomplete, default to showing maintenance
  }

  const now = new Date();
  const start = new Date(window.start_time);
  const end = new Date(window.end_time);

  return now >= start && now <= end;
}

/**
 * Log request details to Cloudflare Analytics
 * @param request - The incoming request
 * @param event - The fetch event
 */
function logRequest(request: Request, event: FetchEvent): void {
  const url = new URL(request.url);

  // @ts-ignore - Analytics Engine is not in the types yet
  if (typeof MAINTENANCE_ANALYTICS !== 'undefined') {
    event.waitUntil(
      // @ts-ignore
      MAINTENANCE_ANALYTICS.writeDataPoint({
        blobs: [
          url.pathname,
          request.method,
          request.headers.get('CF-Connecting-IP') || 'unknown',
          request.headers.get('User-Agent') || 'unknown'
        ],
        doubles: [Date.now()],
        indexes: [typedConfig.enabled ? 1 : 0]
      })
    );
  }
}

/**
 * Generate and serve the maintenance page
 * @param request - The incoming request
 * @returns Response
 */
function serveMaintenancePage(request: Request): Response {
  const html = generateMaintenanceHTML();

  return new Response(html, {
    status: 503,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
      "Retry-After": "300",
      "X-Robots-Tag": "noindex"
    }
  });
}

/**
 * Generate the HTML for the maintenance page
 * @returns string - HTML content
 */
function generateMaintenanceHTML(): string {
  const title = typedConfig.maintenance_title || "System Maintenance";
  const email = typedConfig.contact_email || "";
  const logo = typedConfig.logo_url || "";
  const customCSS = typedConfig.custom_css || "";

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${title}</title>
  <style>
    :root {
      --primary-color: #0051c3;
      --secondary-color: #6c757d;
      --background-color: #f8f9fa;
      --text-color: #212529;
      --border-color: #dee2e6;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.6;
      color: var(--text-color);
      background-color: var(--background-color);
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      min-height: 100vh;
      text-align: center;
    }
    
    .maintenance-container {
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }
    
    .logo {
      max-width: 200px;
      margin: 0 auto 2rem;
    }
    
    h1 {
      font-size: 2.5rem;
      margin-bottom: 1rem;
      color: var(--primary-color);
    }
    
    p {
      font-size: 1.2rem;
      margin-bottom: 1.5rem;
    }
    
    .contact {
      margin-top: 2rem;
      padding-top: 1rem;
      border-top: 1px solid var(--border-color);
      font-size: 1rem;
      color: var(--secondary-color);
    }
    
    .status-indicator {
      display: inline-block;
      width: 12px;
      height: 12px;
      background-color: #ffc107;
      border-radius: 50%;
      margin-right: 8px;
    }
    
    footer {
      margin-top: 2rem;
      padding: 1rem;
      background-color: #f1f1f1;
      font-size: 0.9rem;
      color: var(--secondary-color);
    }
    
    @media (max-width: 768px) {
      .maintenance-container {
        padding: 1rem;
      }
      
      h1 {
        font-size: 2rem;
      }
    }
    
    /* Custom CSS */
    ${customCSS}
  </style>
</head>
<body>
  <div class="maintenance-container">
    ${logo ? `<img src="${logo}" alt="Logo" class="logo"/>` : ''}
    <h1>${title}</h1>
    <p><span class="status-indicator"></span> We're currently performing scheduled maintenance on our systems.</p>
    <p>We apologize for any inconvenience this may cause. Our team is working diligently to complete the maintenance as quickly as possible.</p>
    <p>Please check back soon. We appreciate your patience.</p>
    ${email ? `
    <div class="contact">
      If you need immediate assistance, please contact us at: <a href="mailto:${email}">${email}</a>
    </div>
    ` : ''}
  </div>
  <footer>
    <p>This site is temporarily unavailable due to planned maintenance.</p>
  </footer>
</body>
</html>`;
}
