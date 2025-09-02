// Export all test factories

export * from './produtoFactory'
export * from './documentoFactory'
export * from './userFactory'

// Helper function to reset all mocks
export const resetAllMocks = () => {
  jest.clearAllMocks()
  jest.resetAllMocks()
  jest.restoreAllMocks()
}

// Helper function for async testing
export const flushPromises = () => new Promise(resolve => setImmediate(resolve))

// Helper function to simulate Vue component errors
export const simulateError = (error) => {
  throw new Error(error)
}