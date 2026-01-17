/** @type {import('jest').Config} */
export default {
  testEnvironment: 'jsdom',
  transform: {
    '^.+\\.svelte$': ['svelte-jester', { preprocess: true }],
    '^.+\\.js$': 'babel-jest'
  },
  moduleFileExtensions: ['js', 'svelte'],
  testMatch: [
    '<rootDir>/src/**/__tests__/*.{js,svelte}',
    '<rootDir>/src/**/*.{test,spec}.{js,svelte}'
  ],
  setupFilesAfterEnv: ['<rootDir>/src/tests/setup.js']
};