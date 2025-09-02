// Custom test helpers and assertions for FormularioDCB tests

import { expect } from '@jest/globals'

/**
 * Assert that a Supabase query was called with correct parameters
 */
export const expectSupabaseQuery = (mockFn, table, expectedChain = []) => {
  expect(mockFn).toHaveBeenCalledWith(table)
  
  if (expectedChain.length > 0) {
    expectedChain.forEach(({ method, args }) => {
      const chainMock = mockFn().select
      expect(chainMock).toHaveBeenCalled()
    })
  }
}

/**
 * Assert that SweetAlert was called with specific parameters
 */
export const expectSweetAlert = (swalMock, expectedConfig) => {
  expect(swalMock).toHaveBeenCalledWith(
    expect.objectContaining(expectedConfig)
  )
}

/**
 * Assert that PDF was generated correctly
 */
export const expectPDFGeneration = (jsPDFMock, expectedFileName) => {
  expect(jsPDFMock).toHaveBeenCalledWith('p', 'mm', 'a4')
  
  const pdfInstance = jsPDFMock.mock.results[jsPDFMock.mock.results.length - 1].value
  expect(pdfInstance.save).toHaveBeenCalledWith(expectedFileName)
}

/**
 * Assert component data state
 */
export const expectComponentState = (wrapper, expectedState) => {
  Object.keys(expectedState).forEach(key => {
    expect(wrapper.vm[key]).toEqual(expectedState[key])
  })
}

/**
 * Assert loading state changes
 */
export const expectLoadingState = (wrapper, shouldBeLoading = true) => {
  expect(wrapper.vm.loading).toBe(shouldBeLoading)
  
  if (shouldBeLoading) {
    expect(wrapper.find('.loading').exists()).toBe(true)
  } else {
    expect(wrapper.find('.loading').exists()).toBe(false)
  }
}

/**
 * Assert error handling
 */
export const expectErrorHandling = (consoleSpy, swalMock, errorMessage, swalConfig) => {
  expect(consoleSpy).toHaveBeenCalledWith(
    expect.stringContaining(errorMessage),
    expect.any(Error)
  )
  
  if (swalConfig) {
    expectSweetAlert(swalMock, swalConfig)
  }
}

/**
 * Assert tenant isolation
 */
export const expectTenantIsolation = (mockQuery, tenantId) => {
  const eqCalls = mockQuery.eq.mock.calls
  const tenantFilterCall = eqCalls.find(call => call[0] === 'tenant_id')
  expect(tenantFilterCall).toBeTruthy()
  expect(tenantFilterCall[1]).toBe(tenantId)
}

/**
 * Assert date formatting
 */
export const expectDateFormat = (dateString, expectedFormat) => {
  expect(dateString).toMatch(/^\d{2}\/\d{2}\/\d{4}$/)
  if (expectedFormat) {
    expect(dateString).toBe(expectedFormat)
  }
}

/**
 * Assert DOM element visibility and content
 */
export const expectElementContent = (wrapper, selector, expectedText, shouldExist = true) => {
  const element = wrapper.find(selector)
  
  if (shouldExist) {
    expect(element.exists()).toBe(true)
    if (expectedText) {
      expect(element.text()).toContain(expectedText)
    }
  } else {
    expect(element.exists()).toBe(false)
  }
}

/**
 * Assert button states
 */
export const expectButtonState = (wrapper, buttonSelector, shouldBeDisabled = false) => {
  const button = wrapper.find(buttonSelector)
  expect(button.exists()).toBe(true)
  
  if (shouldBeDisabled) {
    expect(button.attributes('disabled')).toBe('disabled')
  } else {
    expect(button.attributes('disabled')).toBeUndefined()
  }
}

/**
 * Mock Supabase chain methods for easier testing
 */
export const createSupabaseChainMock = (returnValue) => ({
  select: jest.fn().mockReturnThis(),
  eq: jest.fn().mockReturnThis(),
  neq: jest.fn().mockReturnThis(),
  gt: jest.fn().mockReturnThis(),
  gte: jest.fn().mockReturnThis(),
  lt: jest.fn().mockReturnThis(),
  lte: jest.fn().mockReturnThis(),
  like: jest.fn().mockReturnThis(),
  ilike: jest.fn().mockReturnThis(),
  in: jest.fn().mockReturnThis(),
  is: jest.fn().mockReturnThis(),
  order: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  range: jest.fn().mockReturnThis(),
  single: jest.fn().mockResolvedValue(returnValue),
  maybeSingle: jest.fn().mockResolvedValue(returnValue),
  then: jest.fn().mockResolvedValue(returnValue)
})

/**
 * Create a mock PDF instance for testing
 */
export const createMockPDF = (overrides = {}) => ({
  setFont: jest.fn().mockReturnThis(),
  setFontSize: jest.fn().mockReturnThis(),
  text: jest.fn().mockReturnThis(),
  line: jest.fn().mockReturnThis(),
  getTextWidth: jest.fn().mockReturnValue(50),
  save: jest.fn(),
  addPage: jest.fn().mockReturnThis(),
  setTextColor: jest.fn().mockReturnThis(),
  setDrawColor: jest.fn().mockReturnThis(),
  setFillColor: jest.fn().mockReturnThis(),
  rect: jest.fn().mockReturnThis(),
  ...overrides
})

/**
 * Wait for Vue component to update
 */
export const waitForUpdate = async (wrapper) => {
  await wrapper.vm.$nextTick()
  await new Promise(resolve => setImmediate(resolve))
}

/**
 * Simulate user interaction with form elements
 */
export const simulateUserInteraction = {
  selectOption: async (wrapper, selector, value) => {
    const select = wrapper.find(selector)
    await select.setValue(value)
    await waitForUpdate(wrapper)
  },
  
  clickButton: async (wrapper, selector) => {
    const button = wrapper.find(selector)
    await button.trigger('click')
    await waitForUpdate(wrapper)
  },
  
  fillInput: async (wrapper, selector, value) => {
    const input = wrapper.find(selector)
    await input.setValue(value)
    await input.trigger('input')
    await waitForUpdate(wrapper)
  }
}