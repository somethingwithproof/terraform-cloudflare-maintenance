// CloudFlare Worker for maintenance mode - because sometimes things break and we need to fix them
// without everyone watching us frantically debug at 3am
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // First, check if we're actually in maintenance mode
  // If not, let traffic through like nothing happened
  if (!MAINTENANCE_ENABLED || MAINTENANCE_ENABLED === 'false') {
    return fetch(request)
  }

  // Check if this IP is on the VIP list (developers, ops team, that one stakeholder
  // who needs to "just check one thing real quick")
  const clientIP = request.headers.get('CF-Connecting-IP')
  const allowedIPs = JSON.parse(ALLOWED_IPS || '[]')
  if (clientIP && allowedIPs.includes(clientIP)) {
    // You're on the list, come on in!
    return fetch(request)
  }

  // Alright, time to show everyone the "We'll be right back" page
  // This HTML is nicer than the default 503 error at least
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
  </style>
</head>
<body>
  <div class="container">
    <h1>${MAINTENANCE_TITLE || 'Maintenance Mode'}</h1>
    <p>${MAINTENANCE_MESSAGE || 'We are currently performing scheduled maintenance. We will be back shortly.'}</p>
    ${CONTACT_EMAIL ? `<p class="contact">Contact: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a></p>` : ''}
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