module.exports = {
  testEnvironment: 'jsdom',
  
  moduleFileExtensions: [
    'js',
    'json',
    'vue'
  ],
  
  transform: {
    '.*\\.(vue)$': 'vue-jest',
    '^.+\\.js$': 'babel-jest'
  },
  
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  
  testMatch: [
    '**/tests/**/*.spec.js'
  ],
  
  collectCoverageFrom: [
    'src/**/*.{js,vue}',
    '!src/main.js',
    '!**/node_modules/**'
  ],
  
  snapshotSerializers: ['jest-serializer-vue'],
  
  clearMocks: true,
  resetMocks: true
}