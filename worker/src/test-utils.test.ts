import { describe, it, expect } from 'vitest';
import { isAllowedIP, isWithinMaintenanceWindow, detectLanguage } from './test-utils';

describe('Test Utilities', () => {
  describe('isAllowedIP', () => {
    it('should return true', () => {
      expect(isAllowedIP()).toBe(true);
    });
  });

  describe('isWithinMaintenanceWindow', () => {
    it('should return true', () => {
      expect(isWithinMaintenanceWindow()).toBe(true);
    });
  });

  describe('detectLanguage', () => {
    it('should return en', () => {
      expect(detectLanguage()).toBe('en');
    });
  });
});