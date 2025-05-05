import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { handleRequest, isAllowedIP, isWithinMaintenanceWindow, detectLanguage } from './index';

// Mock the translations
vi.mock('./translations', () => ({
  translations: {
    en: {
      title: "System Maintenance",
      message: "We're currently performing scheduled maintenance on our systems.",
      progress: "Our team is working diligently to complete the maintenance as quickly as possible.",
      apology: "We apologize for any inconvenience this may cause.",
      checkBack: "Please check back soon. We appreciate your patience.",
      contact: "If you need immediate assistance, please contact us at:",
      footer: "This site is temporarily unavailable due to planned maintenance."
    },
    es: {
      title: "Mantenimiento del Sistema",
      message: "Actualmente estamos realizando un mantenimiento programado en nuestros sistemas.",
      progress: "Nuestro equipo está trabajando diligentemente para completar el mantenimiento lo más rápido posible.",
      apology: "Pedimos disculpas por cualquier inconveniente que esto pueda causar.",
      checkBack: "Por favor, vuelva a consultar pronto. Agradecemos su paciencia.",
      contact: "Si necesita asistencia inmediata, contáctenos en:",
      footer: "Este sitio está temporalmente no disponible debido a un mantenimiento planificado."
    }
  },
  Translation: {}
}));

// Mock the config
vi.mock('./config.json', () => ({
  default: {
    enabled: true,
    maintenance_title: 'Test Maintenance',
    contact_email: 'test@example.com',
    allowed_ips: '["192.168.1.1"]',
    maintenance_window: null,
    custom_css: '',
    logo_url: '',
    environment: 'dev',
    maintenance_language: 'en'
  }
}));

describe('Maintenance Worker', () => {
  // Mock fetch
  const originalFetch = global.fetch;
  const mockFetch = vi.fn();
  
  // Mock headers
  const mockHeaders = new Map();
  
  // Mock request
  const createMockRequest = (ip?: string, acceptLanguage?: string) => {
    const headers = new Map();
    if (ip) {
      headers.set('CF-Connecting-IP', ip);
    }
    if (acceptLanguage) {
      headers.set('Accept-Language', acceptLanguage);
    }
    
    return {
      url: 'https://example.com/test',
      headers: {
        get: (name: string) => headers.get(name)
      },
      method: 'GET'
    } as unknown as Request;
  };
  
  // Mock event
  const createMockEvent = () => {
    return {
      waitUntil: vi.fn()
    } as unknown as FetchEvent;
  };
  
  beforeEach(() => {
    global.fetch = mockFetch;
    mockFetch.mockResolvedValue(new Response('Original Response'));
    vi.clearAllMocks();
  });
  
  afterEach(() => {
    global.fetch = originalFetch;
  });
  
  describe('handleRequest', () => {
    it('should serve the maintenance page when maintenance is enabled', async () => {
      const request = createMockRequest();
      const event = createMockEvent();
      
      const response = await handleRequest(request, event);
      
      expect(response.status).toBe(503);
      expect(mockFetch).not.toHaveBeenCalled();
      
      const text = await response.text();
      expect(text).toContain('Test Maintenance');
      expect(text).toContain('test@example.com');
    });
    
    it('should pass through requests when maintenance is disabled', async () => {
      // Override the mock to disable maintenance
      vi.mock('./config.json', () => ({
        default: {
          enabled: false,
          maintenance_title: 'Test Maintenance',
          contact_email: 'test@example.com',
          allowed_ips: '[]',
          maintenance_window: null,
          custom_css: '',
          logo_url: '',
          environment: 'dev',
          maintenance_language: 'en'
        }
      }), { virtual: true });
      
      const request = createMockRequest();
      const event = createMockEvent();
      
      const response = await handleRequest(request, event);
      
      expect(mockFetch).toHaveBeenCalledWith(request);
    });
    
    it('should pass through requests from allowed IPs', async () => {
      const request = createMockRequest('192.168.1.1');
      const event = createMockEvent();
      
      const response = await handleRequest(request, event);
      
      expect(mockFetch).toHaveBeenCalledWith(request);
    });
    
    it('should pass through requests outside maintenance window', async () => {
      // Override the mock to set a past maintenance window
      const pastDate = new Date();
      pastDate.setDate(pastDate.getDate() - 1);
      const pastDateStr = pastDate.toISOString();
      
      vi.mock('./config.json', () => ({
        default: {
          enabled: true,
          maintenance_title: 'Test Maintenance',
          contact_email: 'test@example.com',
          allowed_ips: '[]',
          maintenance_window: JSON.stringify({
            start_time: pastDateStr,
            end_time: pastDateStr
          }),
          custom_css: '',
          logo_url: '',
          environment: 'dev',
          maintenance_language: 'en'
        }
      }), { virtual: true });
      
      const request = createMockRequest();
      const event = createMockEvent();
      
      const response = await handleRequest(request, event);
      
      expect(mockFetch).toHaveBeenCalledWith(request);
    });
    
    it('should serve maintenance page with correct language based on Accept-Language header', async () => {
      const request = createMockRequest(undefined, 'es-ES,es;q=0.9,en;q=0.8');
      const event = createMockEvent();
      
      const response = await handleRequest(request, event);
      
      expect(response.status).toBe(503);
      expect(response.headers.get('Content-Language')).toBe('es');
      
      const text = await response.text();
      expect(text).toContain('lang="es"');
      expect(text).toContain('Mantenimiento del Sistema');
    });
  });
  
  describe('isAllowedIP', () => {
    it('should return true for allowed IPs', () => {
      const request = createMockRequest('192.168.1.1');
      expect(isAllowedIP(request)).toBe(true);
    });
    
    it('should return false for non-allowed IPs', () => {
      const request = createMockRequest('192.168.1.2');
      expect(isAllowedIP(request)).toBe(false);
    });
    
    it('should return false when no IP is provided', () => {
      const request = createMockRequest();
      expect(isAllowedIP(request)).toBe(false);
    });
  });
  
  describe('isWithinMaintenanceWindow', () => {
    it('should return true when current time is within window', () => {
      const now = new Date();
      const start = new Date(now);
      start.setHours(now.getHours() - 1);
      
      const end = new Date(now);
      end.setHours(now.getHours() + 1);
      
      expect(isWithinMaintenanceWindow({
        start_time: start.toISOString(),
        end_time: end.toISOString()
      })).toBe(true);
    });
    
    it('should return false when current time is outside window', () => {
      const now = new Date();
      const start = new Date(now);
      start.setDate(now.getDate() - 2);
      
      const end = new Date(now);
      end.setDate(now.getDate() - 1);
      
      expect(isWithinMaintenanceWindow({
        start_time: start.toISOString(),
        end_time: end.toISOString()
      })).toBe(false);
    });
    
    it('should return true when window is incomplete', () => {
      expect(isWithinMaintenanceWindow({
        start_time: '',
        end_time: ''
      })).toBe(true);
    });
  });
  
  describe('detectLanguage', () => {
    it('should detect language from Accept-Language header', () => {
      const request = createMockRequest(undefined, 'es-ES,es;q=0.9,en;q=0.8');
      expect(detectLanguage(request)).toBe('es');
    });
    
    it('should fall back to default language when Accept-Language header is not present', () => {
      const request = createMockRequest();
      expect(detectLanguage(request)).toBe('en');
    });
    
    it('should fall back to default language when Accept-Language does not match supported languages', () => {
      const request = createMockRequest(undefined, 'fr-FR,fr;q=0.9');
      // Note: In our mock we only defined 'en' and 'es' translations
      expect(detectLanguage(request)).toBe('en');
    });
    
    it('should respect quality values in Accept-Language header', () => {
      const request = createMockRequest(undefined, 'fr-FR;q=0.8,es-ES;q=0.9,en;q=0.7');
      expect(detectLanguage(request)).toBe('es');
    });
  });
});
