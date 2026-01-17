// Simple validation test
const { validateEmail, errorMessages } = require('../lib/emailValidation.js');

// Mock Firebase for testing
const mockGetDocs = jest.fn();
jest.mock('../lib/firebase.js', () => ({
  getDb: jest.fn(),
  collection: jest.fn(),
  query: jest.fn(),
  where: jest.fn(),
  getDocs: mockGetDocs,
  serverTimestamp: jest.fn()
}));

describe('Email Validation', () => {
  beforeEach(() => {
    mockGetDocs.mockClear();
  });

  test('valid email passes', async () => {
    mockGetDocs.mockResolvedValue({ empty: true });
    const result = await validateEmail('test@example.com');
    expect(result.valid).toBe(true);
    expect(result.reason).toBeUndefined();
  });

  test('invalid format fails', async () => {
    const result = await validateEmail('invalid-email');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('invalid_format');
    expect(result.retry).toBe(true);
  });

  test('disposable email blocked', async () => {
    mockGetDocs.mockResolvedValue({ empty: true });
    const result = await validateEmail('test@10minutemail.com');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('disposable_email');
    expect(result.retry).toBe(false);
  });

  test('duplicate email blocked', async () => {
    mockGetDocs.mockResolvedValue({ 
      empty: false,
      docs: [{ ref: { id: '123' } }]
    });
    const result = await validateEmail('existing@example.com');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('duplicate_email');
    expect(result.retry).toBe(false);
  });

  test('error messages are defined', () => {
    const expectedErrors = [
      'invalid_format', 'disposable_email', 'domain_invalid',
      'mx_record_fail', 'validation_error', 'timeout', 'duplicate_email'
    ];
    
    expectedErrors.forEach(error => {
      expect(errorMessages[error]).toBeDefined();
      expect(typeof errorMessages[error]).toBe('string');
      expect(errorMessages[error].length).toBeGreaterThan(0);
    });
  });
});