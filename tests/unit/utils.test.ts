import { describe, it, expect } from 'vitest';
import { formatCurrency, formatDate, generateToken, cn } from '@/lib/utils';

describe('Utils', () => {
  describe('formatCurrency', () => {
    it('formats VND correctly', () => {
      const result1 = formatCurrency(35000);
      expect(result1).toContain('35');
      expect(result1).toContain('000');
      expect(result1).toContain('₫');

      const result2 = formatCurrency(1000000);
      expect(result2).toContain('1');
      expect(result2).toContain('000');
      expect(result2).toContain('₫');

      expect(formatCurrency(0)).toContain('₫');
    });
  });

  describe('formatDate', () => {
    it('formats date in Vietnamese locale', () => {
      const date = new Date('2024-01-15T14:30:00');

      // Short format
      const short = formatDate(date, 'short');
      expect(short).toContain('15');
      expect(short).toContain('01');
      expect(short).toContain('2024');

      // Time format
      const time = formatDate(date, 'time');
      expect(time).toContain('14');
      expect(time).toContain('30');
    });
  });

  describe('generateToken', () => {
    it('generates token of specified length', () => {
      const token = generateToken(32);
      expect(token).toHaveLength(64); // hex encoding doubles length
    });

    it('generates unique tokens', () => {
      const token1 = generateToken(16);
      const token2 = generateToken(16);
      expect(token1).not.toBe(token2);
    });
  });

  describe('cn', () => {
    it('merges class names correctly', () => {
      expect(cn('text-red-500', 'text-blue-500')).toBe('text-blue-500');
      expect(cn('p-4', 'm-2', 'p-8')).toBe('m-2 p-8');
    });

    it('handles conditional classes', () => {
      expect(cn('base', true && 'active', false && 'inactive')).toBe('base active');
    });
  });
});
