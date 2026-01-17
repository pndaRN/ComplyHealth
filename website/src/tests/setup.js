// Simple setup for Jest
const { '@testing-library/jest-dom' } = require('@testing-library/jest-dom');

// Mock fetch globally
global.fetch = jest.fn();

// Mock localStorage
global.localStorage = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn()
};