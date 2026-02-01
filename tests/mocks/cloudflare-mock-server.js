/**
 * Mock Cloudflare API Server for Local Testing
 * This server simulates Cloudflare API endpoints for testing without real API calls
 */

import { createServer } from 'http';
import { parse } from 'url';

const PORT = process.env.MOCK_SERVER_PORT || 8787;

// In-memory storage for mock data
const mockData = {
  zones: new Map(),
  workers: new Map(),
  rulesets: new Map(),
  routes: new Map(),
};

// Initialize default mock zone
mockData.zones.set('test-zone-id', {
  id: 'test-zone-id',
  name: 'example.com',
  status: 'active',
  account: { id: 'test-account-id', name: 'Test Account' },
});

/**
 * Generate a mock ID
 */
function generateId() {
  return `mock-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
}

/**
 * Parse JSON body from request
 */
async function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => (body += chunk));
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (error) {
        reject(error);
      }
    });
    req.on('error', reject);
  });
}

/**
 * Send JSON response
 */
function sendJson(res, data, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

/**
 * Cloudflare API response wrapper
 */
function cfResponse(result, success = true, errors = [], messages = []) {
  return {
    success,
    errors,
    messages,
    result,
  };
}

/**
 * Route handlers for different Cloudflare API endpoints
 */
const handlers = {
  // Zones API
  'GET /zones': (req, res) => {
    const zones = Array.from(mockData.zones.values());
    sendJson(res, cfResponse(zones));
  },

  'GET /zones/:zoneId': (req, res, params) => {
    const zone = mockData.zones.get(params.zoneId);
    if (!zone) {
      return sendJson(res, cfResponse(null, false, [{ code: 7003, message: 'Zone not found' }]), 404);
    }
    sendJson(res, cfResponse(zone));
  },

  // Workers API
  'PUT /accounts/:accountId/workers/scripts/:scriptName': async (req, res, params) => {
    const scriptId = generateId();
    const worker = {
      id: scriptId,
      script_name: params.scriptName,
      account_id: params.accountId,
      created_on: new Date().toISOString(),
      modified_on: new Date().toISOString(),
    };
    mockData.workers.set(params.scriptName, worker);
    sendJson(res, cfResponse(worker));
  },

  'GET /accounts/:accountId/workers/scripts/:scriptName': (req, res, params) => {
    const worker = mockData.workers.get(params.scriptName);
    if (!worker) {
      return sendJson(res, cfResponse(null, false, [{ code: 10007, message: 'Worker not found' }]), 404);
    }
    sendJson(res, cfResponse(worker));
  },

  'DELETE /accounts/:accountId/workers/scripts/:scriptName': (req, res, params) => {
    mockData.workers.delete(params.scriptName);
    sendJson(res, cfResponse(null));
  },

  // Worker Routes API
  'POST /zones/:zoneId/workers/routes': async (req, res, params) => {
    const body = await parseBody(req);
    const routeId = generateId();
    const route = {
      id: routeId,
      pattern: body.pattern,
      script: body.script,
      zone_id: params.zoneId,
    };
    mockData.routes.set(routeId, route);
    sendJson(res, cfResponse(route));
  },

  'GET /zones/:zoneId/workers/routes': (req, res, params) => {
    const routes = Array.from(mockData.routes.values()).filter(r => r.zone_id === params.zoneId);
    sendJson(res, cfResponse(routes));
  },

  'DELETE /zones/:zoneId/workers/routes/:routeId': (req, res, params) => {
    mockData.routes.delete(params.routeId);
    sendJson(res, cfResponse(null));
  },

  // Rulesets API (for rate limiting)
  'POST /zones/:zoneId/rulesets': async (req, res, params) => {
    const body = await parseBody(req);
    const rulesetId = generateId();
    const ruleset = {
      id: rulesetId,
      name: body.name,
      kind: body.kind || 'zone',
      phase: body.phase || 'http_ratelimit',
      rules: body.rules || [],
      zone_id: params.zoneId,
    };
    mockData.rulesets.set(rulesetId, ruleset);
    sendJson(res, cfResponse(ruleset));
  },

  'GET /zones/:zoneId/rulesets': (req, res, params) => {
    const rulesets = Array.from(mockData.rulesets.values()).filter(r => r.zone_id === params.zoneId);
    sendJson(res, cfResponse(rulesets));
  },

  'GET /zones/:zoneId/rulesets/:rulesetId': (req, res, params) => {
    const ruleset = mockData.rulesets.get(params.rulesetId);
    if (!ruleset) {
      return sendJson(res, cfResponse(null, false, [{ code: 10000, message: 'Ruleset not found' }]), 404);
    }
    sendJson(res, cfResponse(ruleset));
  },

  'PUT /zones/:zoneId/rulesets/:rulesetId': async (req, res, params) => {
    const body = await parseBody(req);
    const existing = mockData.rulesets.get(params.rulesetId);
    if (!existing) {
      return sendJson(res, cfResponse(null, false, [{ code: 10000, message: 'Ruleset not found' }]), 404);
    }
    const ruleset = { ...existing, ...body, id: params.rulesetId };
    mockData.rulesets.set(params.rulesetId, ruleset);
    sendJson(res, cfResponse(ruleset));
  },

  'DELETE /zones/:zoneId/rulesets/:rulesetId': (req, res, params) => {
    mockData.rulesets.delete(params.rulesetId);
    sendJson(res, cfResponse(null));
  },

  // Account verification
  'GET /accounts/:accountId': (req, res, params) => {
    sendJson(res, cfResponse({
      id: params.accountId,
      name: 'Test Account',
      type: 'standard',
      settings: {},
    }));
  },

  // User token verification
  'GET /user/tokens/verify': (req, res) => {
    sendJson(res, cfResponse({
      id: 'mock-token-id',
      status: 'active',
    }));
  },
};

/**
 * Match route pattern with URL
 */
function matchRoute(method, pathname) {
  for (const [routeKey, handler] of Object.entries(handlers)) {
    const [routeMethod, routePattern] = routeKey.split(' ');
    if (method !== routeMethod) continue;

    // Convert route pattern to regex
    const paramNames = [];
    const regexPattern = routePattern.replace(/:(\w+)/g, (_, name) => {
      paramNames.push(name);
      return '([^/]+)';
    });

    const regex = new RegExp(`^${regexPattern}$`);
    const match = pathname.match(regex);

    if (match) {
      const params = {};
      paramNames.forEach((name, index) => {
        params[name] = match[index + 1];
      });
      return { handler, params };
    }
  }
  return null;
}

/**
 * Request handler
 */
async function handleRequest(req, res) {
  const { pathname } = parse(req.url, true);
  const method = req.method;

  // Remove /client/v4 prefix if present
  const apiPath = pathname.replace(/^\/client\/v4/, '');

  console.log(`[Mock Server] ${method} ${apiPath}`);

  const matched = matchRoute(method, apiPath);

  if (matched) {
    try {
      await matched.handler(req, res, matched.params);
    } catch (error) {
      console.error(`[Mock Server] Error: ${error.message}`);
      sendJson(res, cfResponse(null, false, [{ code: 500, message: error.message }]), 500);
    }
  } else {
    console.log(`[Mock Server] Route not found: ${method} ${apiPath}`);
    sendJson(res, cfResponse(null, false, [{ code: 404, message: 'Route not found' }]), 404);
  }
}

/**
 * Start the mock server
 */
function startServer() {
  const server = createServer(handleRequest);

  server.listen(PORT, () => {
    console.log(`[Mock Server] Cloudflare API Mock Server running on http://localhost:${PORT}`);
    console.log(`[Mock Server] Use CLOUDFLARE_API_BASE_URL=http://localhost:${PORT}/client/v4 for testing`);
  });

  return server;
}

// Export for testing
export { startServer, mockData, handlers };

// Start server if running directly
if (import.meta.url === `file://${process.argv[1]}`) {
  startServer();
}
