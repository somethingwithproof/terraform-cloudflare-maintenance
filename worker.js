// CloudFlare Worker for maintenance mode - because sometimes things break and we need to fix them
// without everyone watching us frantically debug at 3am
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Check if we're in a scheduled maintenance window
  const now = new Date()
  const inMaintenanceWindow = checkMaintenanceWindow(now)
  
  // First, check if we're actually in maintenance mode
  // If not and not in a maintenance window, let traffic through
  if ((!MAINTENANCE_ENABLED || MAINTENANCE_ENABLED === 'false') && !inMaintenanceWindow) {
    return fetch(request)
  }

  // Check if this IP is on the VIP list (developers, ops team, that one stakeholder
  // who needs to "just check one thing real quick")
  const clientIP = request.headers.get('CF-Connecting-IP')
  let allowedIPs = []
  try {
    allowedIPs = JSON.parse(ALLOWED_IPS || '[]')
  } catch (e) {
    // Invalid JSON, skip IP check
  }
  if (clientIP && allowedIPs.includes(clientIP)) {
    // You're on the list, come on in!
    return fetch(request)
  }

  // Check if the request is from an allowed region
  const country = request.cf?.country
  let allowedRegions = []
  try {
    allowedRegions = JSON.parse(ALLOWED_REGIONS || '[]')
  } catch (e) {
    // Invalid JSON, skip region check
  }
  if (country && allowedRegions.includes(country)) {
    // Region is allowed, bypass maintenance
    return fetch(request)
  }

  // Validate and sanitize logo URL to prevent XSS
  let logoHtml = ''
  if (LOGO_URL && isValidHttpsUrl(LOGO_URL)) {
    // Additional check for javascript: and data: URIs
    const lowerUrl = LOGO_URL.toLowerCase()
    if (!lowerUrl.startsWith('javascript:') && !lowerUrl.startsWith('data:')) {
      const sanitizedUrl = LOGO_URL.replace(/['"<>`&]/g, '')
      logoHtml = `<img src="${sanitizedUrl}" alt="Logo" style="max-width: 200px; margin-bottom: 1rem;">`
    }
  }
  
  // Alright, time to show everyone the "We'll be right back" page
  // This HTML is nicer than the default 503 error at least
  const customStyles = CUSTOM_CSS || ''
  
  // Sanitize contact email to prevent XSS
  const sanitizedEmail = sanitizeEmail(CONTACT_EMAIL || '')
  
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${MAINTENANCE_TITLE || 'Maintenance Mode'}</title>
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
    <h1>${MAINTENANCE_TITLE || 'Maintenance Mode'}</h1>
    <p>${MAINTENANCE_MESSAGE || 'We are currently performing scheduled maintenance. We will be back shortly.'}</p>
    ${getMaintenanceWindowMessage()}
    ${sanitizedEmail ? `<p class="contact">Contact: <a href="mailto:${sanitizedEmail}">${sanitizedEmail}</a></p>` : ''}
  </div>
</body>
</html>`

  // Return a 503 because we're being honest about the service being unavailable
  // The Retry-After header is optimistic, but hey, we can hope
  return new Response(html, {
    status: 503,
    headers: {
      'Content-Type': 'text/html;charset=UTF-8',
      'Cache-Control': 'no-store, no-cache, must-revalidate', // Don't cache this disaster
      'Retry-After': '3600' // Try again in an hour (fingers crossed we're done by then)
    }
  })
}

function checkMaintenanceWindow(now) {
  // Check if we're within a scheduled maintenance window
  const startTime = MAINTENANCE_WINDOW_START
  const endTime = MAINTENANCE_WINDOW_END
  
  if (!startTime || !endTime) {
    return false
  }
  
  try {
    const start = new Date(startTime)
    const end = new Date(endTime)
    return now >= start && now <= end
  } catch (e) {
    // Invalid dates, ignore the maintenance window
    return false
  }
}

function getMaintenanceWindowMessage() {
  const startTime = MAINTENANCE_WINDOW_START
  const endTime = MAINTENANCE_WINDOW_END
  
  if (!startTime || !endTime) {
    return ''
  }
  
  try {
    const end = new Date(endTime)
    return `<p style="font-size: 0.9rem; color: #888;">Expected completion: ${end.toUTCString()}</p>`
  } catch (e) {
    return ''
  }
}

function isValidHttpsUrl(url) {
  try {
    const parsedUrl = new URL(url)
    return parsedUrl.protocol === 'https:'
  } catch (e) {
    return false
  }
}

function sanitizeEmail(email) {
  // Basic email validation and sanitization
  const emailRegex = /^[^\s@<>'"]+@[^\s@<>'"]+\.[^\s@<>'"]+$/
  if (!emailRegex.test(email)) {
    return ''
  }
  // Remove potentially dangerous characters
  return email.replace(/[<>'"&]/g, '')
}