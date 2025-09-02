// Global test setup

// Mock global objects and methods
global.console = {
  ...console,
  // Silence console.log/warn/error in tests unless needed
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}

// Mock window methods
Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
    clear: jest.fn(),
  },
})

Object.defineProperty(window, 'sessionStorage', {
  value: {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
    clear: jest.fn(),
  },
})

// Mock URL.createObjectURL
global.URL = {
  createObjectURL: jest.fn(() => 'mock-blob-url'),
  revokeObjectURL: jest.fn(),
}

// Mock fetch
global.fetch = jest.fn()

// Mock window.open
global.window.open = jest.fn()

// Set up timezone for consistent date testing
process.env.TZ = 'UTC'

// Mock Date.now for consistent testing
const mockDate = new Date('2024-01-15T10:00:00.000Z')
Date.now = jest.fn(() => mockDate.getTime())

// Note: Don't mock Date constructor as it breaks new Date() in tests