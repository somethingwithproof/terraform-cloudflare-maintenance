import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['**/*.test.js'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      include: ['../worker.js'],
      exclude: ['node_modules/', 'coverage/'],
    },
    testTimeout: 30000,
    hookTimeout: 30000,
  },
});
