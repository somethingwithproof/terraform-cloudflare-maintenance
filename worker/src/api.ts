/**
 * API endpoints for managing maintenance mode
 */

// Interface for maintenance API responses
interface ApiResponse {
  success: boolean;
  message: string;
  data?: any;
}

// Interface for maintenance window updates
interface MaintenanceWindowUpdate {
  enabled: boolean;
  start_time?: string;
  end_time?: string;
}

/**
 * Validate API key from request
 * @param request - The incoming request
 * @param expectedApiKey - The expected API key
 * @returns boolean
 */
function validateApiKey(request: Request, expectedApiKey: string): boolean {
  const authorization = request.headers.get('Authorization');
  
  if (!authorization) {
    return false;
  }
  
  // Check for Bearer token format
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return false;
  }
  
  const token = match[1];
  return token === expectedApiKey;
}

/**
 * Create a JSON response
 * @param data - Response data
 * @param status - HTTP status code
 * @returns Response
 */
function jsonResponse(data: ApiResponse, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0'
    }
  });
}

/**
 * Handle API request
 * @param request - The incoming request
 * @param apiKey - The API key for authentication
 * @param namespace - The KV namespace for storing maintenance data
 * @returns Promise<Response>
 */
export async function handleApiRequest(
  request: Request,
  apiKey: string,
  namespace: KVNamespace
): Promise<Response> {
  // Validate API key
  if (!validateApiKey(request, apiKey)) {
    return jsonResponse({ 
      success: false, 
      message: 'Unauthorized' 
    }, 401);
  }
  
  const url = new URL(request.url);
  const path = url.pathname.replace(/^\/api\//, '');
  
  // Handle different API endpoints
  switch (path) {
    case 'status':
      return handleStatusRequest(namespace);
      
    case 'maintenance':
      if (request.method === 'GET') {
        return handleGetMaintenanceStatus(namespace);
      } else if (request.method === 'PUT' || request.method === 'POST') {
        return handleUpdateMaintenanceStatus(request, namespace);
      } else {
        return jsonResponse({ 
          success: false, 
          message: 'Method not allowed' 
        }, 405);
      }
      
    default:
      return jsonResponse({ 
        success: false, 
        message: 'Not found' 
      }, 404);
  }
}

/**
 * Handle status request
 * @param namespace - The KV namespace
 * @returns Promise<Response>
 */
async function handleStatusRequest(namespace: KVNamespace): Promise<Response> {
  return jsonResponse({ 
    success: true, 
    message: 'Maintenance API is operational',
    data: {
      version: '3.0.0',
      timestamp: new Date().toISOString()
    }
  });
}

/**
 * Handle get maintenance status request
 * @param namespace - The KV namespace
 * @returns Promise<Response>
 */
async function handleGetMaintenanceStatus(namespace: KVNamespace): Promise<Response> {
  try {
    // Fetch current maintenance status
    const maintenanceConfig = await namespace.get('maintenance_config', { type: 'json' }) || {
      enabled: false
    };
    
    return jsonResponse({ 
      success: true, 
      message: 'Current maintenance status retrieved',
      data: maintenanceConfig
    });
  } catch (error) {
    return jsonResponse({ 
      success: false, 
      message: 'Error retrieving maintenance status: ' + (error as Error).message 
    }, 500);
  }
}

/**
 * Handle update maintenance status request
 * @param request - The incoming request
 * @param namespace - The KV namespace
 * @returns Promise<Response>
 */
async function handleUpdateMaintenanceStatus(
  request: Request,
  namespace: KVNamespace
): Promise<Response> {
  try {
    // Parse request body
    const body: MaintenanceWindowUpdate = await request.json();
    
    // Validate required fields
    if (typeof body.enabled !== 'boolean') {
      return jsonResponse({ 
        success: false, 
        message: 'Invalid request: enabled field is required and must be a boolean' 
      }, 400);
    }
    
    // Validate time format if provided
    if (body.start_time && !isValidISODate(body.start_time)) {
      return jsonResponse({ 
        success: false, 
        message: 'Invalid start_time format, must be ISO 8601' 
      }, 400);
    }
    
    if (body.end_time && !isValidISODate(body.end_time)) {
      return jsonResponse({ 
        success: false, 
        message: 'Invalid end_time format, must be ISO 8601' 
      }, 400);
    }
    
    // Fetch current config
    const currentConfig = await namespace.get('maintenance_config', { type: 'json' }) || {};
    
    // Update config
    const newConfig = {
      ...currentConfig,
      enabled: body.enabled,
      updated_at: new Date().toISOString()
    };
    
    // Update maintenance window if provided
    if (body.start_time && body.end_time) {
      newConfig.maintenance_window = {
        start_time: body.start_time,
        end_time: body.end_time
      };
    }
    
    // Save to KV
    await namespace.put('maintenance_config', JSON.stringify(newConfig));
    
    return jsonResponse({ 
      success: true, 
      message: 'Maintenance status updated successfully',
      data: newConfig
    });
    
  } catch (error) {
    return jsonResponse({ 
      success: false, 
      message: 'Error updating maintenance status: ' + (error as Error).message 
    }, 500);
  }
}

/**
 * Validate ISO date format
 * @param dateString - The date string to validate
 * @returns boolean
 */
function isValidISODate(dateString: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$/.test(dateString)) {
    return false;
  }
  
  const date = new Date(dateString);
  return !isNaN(date.getTime());
}