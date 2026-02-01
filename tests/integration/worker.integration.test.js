/**
 * Integration tests for Cloudflare Worker using Miniflare
 * These tests run the actual worker code in a simulated Cloudflare environment
 */

import { Miniflare } from 'miniflare';
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { readFileSync } from 'fs';
import { join } from 'path';

describe('Worker Integration Tests', () => {
  let mf;

  beforeAll(async () => {
    // Read the worker script
    const workerPath = join(__dirname, '../../worker.js');
    const workerScript = readFileSync(workerPath, 'utf8');

    // Initialize Miniflare with default bindings
    mf = new Miniflare({
      script: workerScript,
      bindings: {
        MAINTENANCE_ENABLED: 'true',
        MAINTENANCE_TITLE: 'System Maintenance',
        MAINTENANCE_MESSAGE: 'We are currently performing scheduled maintenance.',
        CONTACT_EMAIL: 'support@example.com',
        CUSTOM_CSS: '',
        LOGO_URL: '',
        MAINTENANCE_WINDOW_START: '',
        MAINTENANCE_WINDOW_END: '',
        ALLOWED_IPS: '[]',
        ALLOWED_REGIONS: '[]',
      },
    });
  });

  afterAll(async () => {
    if (mf) {
      await mf.dispose();
    }
  });

  describe('Maintenance Mode Enabled', () => {
    beforeEach(async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'System Maintenance',
          MAINTENANCE_MESSAGE: 'We are currently performing scheduled maintenance.',
          CONTACT_EMAIL: 'support@example.com',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });
    });

    it('should return 503 status when maintenance is enabled', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      expect(response.status).toBe(503);
    });

    it('should return HTML content type', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      expect(response.headers.get('Content-Type')).toBe('text/html;charset=UTF-8');
    });

    it('should include maintenance title in response', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).toContain('System Maintenance');
    });

    it('should include maintenance message in response', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).toContain('We are currently performing scheduled maintenance.');
    });

    it('should include contact email in response', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).toContain('support@example.com');
      expect(body).toContain('mailto:support@example.com');
    });

    it('should set Cache-Control header to prevent caching', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      const cacheControl = response.headers.get('Cache-Control');
      expect(cacheControl).toContain('no-store');
      expect(cacheControl).toContain('no-cache');
    });

    it('should set Retry-After header', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      expect(response.headers.get('Retry-After')).toBe('3600');
    });
  });

  describe('Maintenance Mode Disabled', () => {
    beforeEach(async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'false',
          MAINTENANCE_TITLE: 'System Maintenance',
          MAINTENANCE_MESSAGE: 'We are currently performing scheduled maintenance.',
          CONTACT_EMAIL: 'support@example.com',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });
    });

    it('should pass through requests when maintenance is disabled', async () => {
      // Note: In a real test, fetch would go to the origin
      // With Miniflare, we're testing the logic flow
      const response = await mf.dispatchFetch('https://example.com/');
      // When maintenance is disabled and no window is active, request passes through
      // The mock fetch returns 200
      expect(response.status).toBe(200);
    });
  });

  describe('IP Allowlist', () => {
    beforeEach(async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'System Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '["192.168.1.1", "10.0.0.1"]',
          ALLOWED_REGIONS: '[]',
        },
      });
    });

    it('should allow requests from allowed IPs', async () => {
      const response = await mf.dispatchFetch('https://example.com/', {
        headers: {
          'CF-Connecting-IP': '192.168.1.1',
        },
      });
      // Allowed IP bypasses maintenance
      expect(response.status).toBe(200);
    });

    it('should block requests from non-allowed IPs', async () => {
      const response = await mf.dispatchFetch('https://example.com/', {
        headers: {
          'CF-Connecting-IP': '1.2.3.4',
        },
      });
      expect(response.status).toBe(503);
    });
  });

  describe('Region Allowlist', () => {
    beforeEach(async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'System Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '["US", "CA"]',
        },
      });
    });

    it('should allow requests from allowed regions', async () => {
      const response = await mf.dispatchFetch('https://example.com/', {
        cf: { country: 'US' },
      });
      // Allowed region bypasses maintenance
      expect(response.status).toBe(200);
    });

    it('should block requests from non-allowed regions', async () => {
      const response = await mf.dispatchFetch('https://example.com/', {
        cf: { country: 'DE' },
      });
      expect(response.status).toBe(503);
    });
  });

  describe('Maintenance Window', () => {
    it('should activate maintenance during scheduled window', async () => {
      const now = new Date();
      const start = new Date(now.getTime() - 3600000).toISOString(); // 1 hour ago
      const end = new Date(now.getTime() + 3600000).toISOString(); // 1 hour from now

      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'false', // Manual toggle is off
          MAINTENANCE_TITLE: 'Scheduled Maintenance',
          MAINTENANCE_MESSAGE: 'Scheduled maintenance in progress',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: start,
          MAINTENANCE_WINDOW_END: end,
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      // Within maintenance window, should show maintenance page
      expect(response.status).toBe(503);
    });

    it('should not activate maintenance outside scheduled window', async () => {
      const now = new Date();
      const start = new Date(now.getTime() + 3600000).toISOString(); // 1 hour from now
      const end = new Date(now.getTime() + 7200000).toISOString(); // 2 hours from now

      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'false',
          MAINTENANCE_TITLE: 'Scheduled Maintenance',
          MAINTENANCE_MESSAGE: 'Scheduled maintenance in progress',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: start,
          MAINTENANCE_WINDOW_END: end,
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      // Outside maintenance window, should pass through
      expect(response.status).toBe(200);
    });

    it('should show expected completion time in maintenance page', async () => {
      const now = new Date();
      const start = new Date(now.getTime() - 3600000).toISOString();
      const end = new Date(now.getTime() + 3600000).toISOString();

      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Scheduled Maintenance',
          MAINTENANCE_MESSAGE: 'In progress',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: start,
          MAINTENANCE_WINDOW_END: end,
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).toContain('Expected completion:');
    });
  });

  describe('Custom Styling', () => {
    it('should include custom CSS when provided', async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: 'body { background-color: #ff0000; }',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).toContain('background-color: #ff0000');
    });

    it('should include logo when valid HTTPS URL provided', async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: 'https://example.com/logo.png',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).toContain('src="https://example.com/logo.png"');
    });

    it('should not include logo when HTTP URL provided', async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: 'http://example.com/logo.png', // HTTP, not HTTPS
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).not.toContain('http://example.com/logo.png');
    });
  });

  describe('Security Tests', () => {
    it('should prevent XSS via logo URL', async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: 'javascript:alert(1)',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).not.toContain('javascript:');
    });

    it('should prevent XSS via data URL in logo', async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: 'data:text/html,<script>alert(1)</script>',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).not.toContain('data:');
    });

    it('should sanitize email addresses', async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '<script>alert(1)</script>@example.com',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });

      const response = await mf.dispatchFetch('https://example.com/');
      const body = await response.text();
      expect(body).not.toContain('<script>');
    });
  });

  describe('Multiple Path Tests', () => {
    beforeEach(async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });
    });

    it('should show maintenance page on root path', async () => {
      const response = await mf.dispatchFetch('https://example.com/');
      expect(response.status).toBe(503);
    });

    it('should show maintenance page on API paths', async () => {
      const response = await mf.dispatchFetch('https://example.com/api/v1/users');
      expect(response.status).toBe(503);
    });

    it('should show maintenance page on nested paths', async () => {
      const response = await mf.dispatchFetch('https://example.com/app/dashboard/settings');
      expect(response.status).toBe(503);
    });

    it('should show maintenance page with query parameters', async () => {
      const response = await mf.dispatchFetch('https://example.com/search?q=test');
      expect(response.status).toBe(503);
    });
  });

  describe('HTTP Method Tests', () => {
    beforeEach(async () => {
      await mf.setOptions({
        bindings: {
          MAINTENANCE_ENABLED: 'true',
          MAINTENANCE_TITLE: 'Maintenance',
          MAINTENANCE_MESSAGE: 'Under maintenance',
          CONTACT_EMAIL: '',
          CUSTOM_CSS: '',
          LOGO_URL: '',
          MAINTENANCE_WINDOW_START: '',
          MAINTENANCE_WINDOW_END: '',
          ALLOWED_IPS: '[]',
          ALLOWED_REGIONS: '[]',
        },
      });
    });

    it('should handle GET requests', async () => {
      const response = await mf.dispatchFetch('https://example.com/', {
        method: 'GET',
      });
      expect(response.status).toBe(503);
    });

    it('should handle POST requests', async () => {
      const response = await mf.dispatchFetch('https://example.com/api', {
        method: 'POST',
        body: JSON.stringify({ data: 'test' }),
      });
      expect(response.status).toBe(503);
    });

    it('should handle PUT requests', async () => {
      const response = await mf.dispatchFetch('https://example.com/api/1', {
        method: 'PUT',
        body: JSON.stringify({ data: 'test' }),
      });
      expect(response.status).toBe(503);
    });

    it('should handle DELETE requests', async () => {
      const response = await mf.dispatchFetch('https://example.com/api/1', {
        method: 'DELETE',
      });
      expect(response.status).toBe(503);
    });
  });
});
