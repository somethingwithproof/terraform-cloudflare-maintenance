// test-setup.ts
import { vi } from 'vitest';

// Set up Cloudflare Worker environment globals
globalThis.addEventListener = vi.fn();
// @ts-ignore
globalThis.MAINTENANCE_ANALYTICS = {
  writeDataPoint: vi.fn().mockResolvedValue(undefined)
};
// @ts-ignore
globalThis.MAINTENANCE_CONFIG = {
  get: vi.fn().mockResolvedValue(null),
  put: vi.fn().mockResolvedValue(undefined)
};