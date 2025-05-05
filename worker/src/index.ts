/// <reference types="@cloudflare/workers-types" />

// Import configuration and translations
import config from './config.json';
import { translations, Translation } from './translations';

// Define interfaces
interface MaintenanceConfig {
  enabled: boolean;
  maintenance_title: string;
  contact_email: string;
  allowed_ips: string; // JSON string of IP addresses
  maintenance_window: string | null; // JSON string or null
  custom_css: string;
  logo_url: string;
  environment: string;
  maintenance_language?: string;
  api_key?: string;
}

interface MaintenanceWindow {
  start_time: string;
  end_time: string;
}

// Global variables
const typedConfig = config as MaintenanceConfig;
let allowedIPs: string[] = [];
let maintenanceWindow: MaintenanceWindow | null = null;
const defaultLanguage = typedConfig.maintenance_language || 'en';

// Initialize configuration
try {
  allowedIPs = JSON.parse(typedConfig.allowed_ips);
  if (typedConfig.maintenance_window && typedConfig.maintenance_window !== "null") {
    maintenanceWindow = JSON.parse(typedConfig.maintenance_window);
  }
} catch (e) {
  console.error("Error parsing configuration:", e);
}

// Import API handler
import { handleApiRequest } from './api';

// Event listener for incoming requests
addEventListener("fetch", (event: FetchEvent) => {
  const url = new URL(event.request.url);
  
  // Route API requests differently
  if (url.pathname.startsWith('/api/')) {
    // @ts-ignore - KVNamespace not in types
    event.respondWith(handleApiRequest(event.request, typedConfig.api_key || 'default_api_key', MAINTENANCE_CONFIG));
  } else {
    event.respondWith(handleRequest(event.request, event));
  }
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
 * Detect preferred language from request
 * @param request - The incoming request
 * @returns string - Language code
 */
export function detectLanguage(request: Request): string {
  // Check for accept-language header
  const acceptLanguage = request.headers.get('Accept-Language');
  
  if (!acceptLanguage) {
    return defaultLanguage;
  }
  
  // Parse the Accept-Language header
  const preferredLanguages = acceptLanguage.split(',')
    .map(lang => {
      const [code, q = 'q=1.0'] = lang.trim().split(';');
      const quality = parseFloat(q.substring(2)) || 0;
      return { code: code.substring(0, 2).toLowerCase(), quality };
    })
    .sort((a, b) => b.quality - a.quality);
  
  // Try to find the first supported language
  for (const { code } of preferredLanguages) {
    if (translations[code]) {
      return code;
    }
  }
  
  // Fallback to default language
  return defaultLanguage;
}

/**
 * Log request details to Cloudflare Analytics
 * @param request - The incoming request
 * @param event - The fetch event
 */
function logRequest(request: Request, event: FetchEvent): void {
  const url = new URL(request.url);
  const clientLanguage = detectLanguage(request);

  // @ts-ignore - Analytics Engine is not in the types yet
  if (typeof MAINTENANCE_ANALYTICS !== 'undefined') {
    event.waitUntil(
      // @ts-ignore
      MAINTENANCE_ANALYTICS.writeDataPoint({
        blobs: [
          url.pathname,
          request.method,
          request.headers.get('CF-Connecting-IP') || 'unknown',
          request.headers.get('User-Agent') || 'unknown',
          clientLanguage,
          typedConfig.environment
        ],
        doubles: [Date.now()],
        indexes: [typedConfig.enabled ? 1 : 0]
      })
    );
  }
}

// Import security utilities
import { applySecurityHeaders, isBot, createBotResponse } from './security';

/**
 * Generate and serve the maintenance page
 * @param request - The incoming request
 * @returns Response
 */
function serveMaintenancePage(request: Request): Response {
  const language = detectLanguage(request);
  const trans = translations[language] || translations[defaultLanguage];
  
  // Handle bots differently - provide simpler response with appropriate headers
  if (isBot(request)) {
    return createBotResponse(
      typedConfig.maintenance_title || trans.title,
      trans.message
    );
  }
  
  const html = generateMaintenanceHTML(language);
  
  // Set content language header based on detected language
  const response = new Response(html, {
    status: 503,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Content-Language": language,
      "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
      "Retry-After": "300",
      "X-Robots-Tag": "noindex"
    }
  });
  
  // Apply additional security headers
  return applySecurityHeaders(response);
}

/**
 * Generate the HTML for the maintenance page
 * @param language - Language code for translations
 * @returns string - HTML content
 */
function generateMaintenanceHTML(language: string = defaultLanguage): string {
  // Get translation for the selected language or fall back to default
  const trans: Translation = translations[language] || translations[defaultLanguage];
  
  // Get configuration
  const title = typedConfig.maintenance_title || trans.title;
  const email = typedConfig.contact_email || "";
  const logo = typedConfig.logo_url || "";
  const customCSS = typedConfig.custom_css || "";
  
  // Generate HTML with the appropriate language code
  return `<!DOCTYPE html>
<html lang="${language}">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${title}</title>
  <meta name="robots" content="noindex,nofollow"/>
  <meta name="description" content="${trans.message}"/>
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
    
    .language-selector {
      margin-top: 1rem;
      font-size: 0.9rem;
    }
    
    .language-selector a {
      margin: 0 0.5rem;
      color: var(--secondary-color);
      text-decoration: none;
    }
    
    .language-selector a:hover {
      text-decoration: underline;
    }
    
    /* Dark mode support */
    @media (prefers-color-scheme: dark) {
      :root {
        --primary-color: #4d97ff;
        --secondary-color: #adb5bd;
        --background-color: #121212;
        --text-color: #e0e0e0;
        --border-color: #2c2c2c;
      }
      
      footer {
        background-color: #1e1e1e;
      }
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
    <p><span class="status-indicator"></span> ${trans.message}</p>
    <p>${trans.apology} ${trans.progress}</p>
    <p>${trans.checkBack}</p>
    ${email ? `
    <div class="contact">
      ${trans.contact} <a href="mailto:${email}">${email}</a>
    </div>
    ` : ''}
    
    <div class="language-selector">
      ${Object.keys(translations).map(langCode => 
        `<a href="?lang=${langCode}" ${langCode === language ? 'aria-current="true"' : ''}>${langCode.toUpperCase()}</a>`
      ).join(' ')}
    </div>
  </div>
  <footer>
    <p>${trans.footer}</p>
    ${typedConfig.environment !== 'production' ? 
      `<p><small>Environment: ${typedConfig.environment}</small></p>` : ''}
  </footer>
</body>
</html>`;
}
