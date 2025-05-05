module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  env: {
    es6: true,
    worker: true,
    node: true
  },
  rules: {
    // Performance optimizations
    'prefer-const': 'error',
    'no-var': 'error',
    'no-unused-vars': 'off', // TypeScript handles this better
    '@typescript-eslint/no-unused-vars': ['error', { 
      'argsIgnorePattern': '^_',
      'varsIgnorePattern': '^_'
    }],
    
    // Prevent security issues
    'no-eval': 'error',
    'no-implied-eval': 'error',
    
    // Maintainability
    'max-lines-per-function': ['warn', { 
      max: 50,
      skipBlankLines: true,
      skipComments: true
    }],
    'complexity': ['warn', 15],
    
    // Performance issues
    'no-console': ['warn', { allow: ['warn', 'error'] }]
  },
  ignorePatterns: [
    'dist/**/*',
    'node_modules/**/*'
  ]
};