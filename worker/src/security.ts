/**
 * Security utility functions for the maintenance worker
 */

// Headers to add for enhanced security
export const securityHeaders = {
  // Protection against clickjacking
  "X-Frame-Options": "DENY",
  
  // Protection against XSS attacks
  "X-XSS-Protection": "1; mode=block",
  
  // Protection against MIME-type sniffing
  "X-Content-Type-Options": "nosniff",
  
  // Content Security Policy to restrict resource loading
  "Content-Security-Policy": "default-src 'self'; img-src 'self' https:; style-src 'self' 'unsafe-inline'; font-src 'self' https:; script-src 'none';",
  
  // Strict Transport Security for HTTPS enforcement
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains; preload",
  
  // Referrer Policy to control referrer information
  "Referrer-Policy": "strict-origin-when-cross-origin",
  
  // Permissions Policy to control browser features
  "Permissions-Policy": "camera=(), microphone=(), geolocation=(), interest-cohort=()"
};

/**
 * Check if a request is from a known bot
 * @param request - The incoming request
 * @returns boolean
 */
export function isBot(request: Request): boolean {
  const userAgent = request.headers.get('User-Agent') || '';
  
  // List of known bot patterns
  const botPatterns = [
    /bot/i,
    /spider/i,
    /crawl/i,
    /lighthouse/i,
    /slurp/i,
    /pingdom/i,
    /archive\.org/i,
    /facebookexternalhit/i,
    /whatsapp/i
  ];
  
  return botPatterns.some(pattern => pattern.test(userAgent));
}

/**
 * Validate the host to prevent host header attacks
 * @param request - The incoming request
 * @param allowedHosts - List of allowed hosts
 * @returns boolean - Whether the host is valid
 */
export function isValidHost(request: Request, allowedHosts: string[] = []): boolean {
  const url = new URL(request.url);
  const host = url.hostname;
  
  if (allowedHosts.length === 0) {
    return true; // No restrictions if no allowed hosts are specified
  }
  
  return allowedHosts.some(allowedHost => {
    // Support wildcard subdomains (e.g., *.example.com)
    if (allowedHost.startsWith('*.')) {
      const domain = allowedHost.substring(2);
      return host.endsWith(domain) && host.length > domain.length;
    }
    
    return host === allowedHost;
  });
}

/**
 * Apply security headers to a response
 * @param response - The original response
 * @returns Response - Response with security headers
 */
export function applySecurityHeaders(response: Response): Response {
  const secureResponse = new Response(response.body, response);
  const headers = secureResponse.headers;
  
  // Add security headers
  Object.keys(securityHeaders).forEach(headerName => {
    headers.set(headerName, securityHeaders[headerName as keyof typeof securityHeaders]);
  });
  
  return secureResponse;
}

/**
 * Create a specialized response for search engine bots
 * @param title - The maintenance page title
 * @param message - The maintenance message
 * @returns Response - Bot-friendly response
 */
export function createBotResponse(title: string, message: string): Response {
  // Return a simplified response for bots with just essential information
  return new Response(
    `<!DOCTYPE html>
<html>
<head>
  <title>${title}</title>
  <meta name="robots" content="noindex">
  <meta name="description" content="${message}">
</head>
<body>
  <h1>${title}</h1>
  <p>${message}</p>
</body>
</html>`,
    {
      status: 503,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
        "X-Robots-Tag": "noindex",
        "Retry-After": "3600"
      }
    }
  );
}