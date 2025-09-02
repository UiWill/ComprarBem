# FormularioDCB Test Suite

This directory contains a comprehensive test suite for the `FormularioDCB.vue` component, which handles the Declaration of Conformity for Products (DCB) functionality in the Comprar Bem system.

## Test Structure

```
tests/
├── __mocks__/              # Mock implementations for external dependencies
│   ├── @supabase/          # Supabase client mocks
│   ├── services/           # Internal service mocks
│   ├── jspdf.js           # PDF generation mocks
│   └── vue-sweetalert2.js # SweetAlert2 plugin mock
├── factories/              # Test data factories
│   ├── produtoFactory.js  # Product test data
│   ├── documentoFactory.js # Document test data
│   ├── userFactory.js     # User/session test data
│   └── index.js           # Factory exports and helpers
├── helpers/               # Test utilities and custom assertions
│   └── assertions.js      # Custom Jest matchers and helpers
├── unit/                  # Unit tests
│   ├── FormularioDCB.spec.js          # Core functionality tests
│   └── FormularioDCB.edge-cases.spec.js # Edge case and error handling
├── integration/           # Integration tests
│   └── FormularioDCB.integration.spec.js # End-to-end workflows
├── setup.js              # Global test setup
└── README.md             # This file
```

## Running Tests

### All Tests
```bash
npm test
```

### Watch Mode
```bash
npm run test:watch
```

### Coverage Report
```bash
npm run test:coverage
```

### Specific Test Files
```bash
# Unit tests only
npx jest tests/unit/

# Integration tests only
npx jest tests/integration/

# Specific test file
npx jest FormularioDCB.spec.js
```

## Test Categories

### Unit Tests (`tests/unit/`)

#### Core Functionality Tests
- Component initialization and data structure
- Computed properties (`produtoAprovado`)
- Authentication methods (`obterTenantId`)
- Data loading methods (`carregarProdutos`, `carregarDetalhes`)
- Status and formatting methods (`getStatusDCB`, `formatarData`)
- DCB actions (`visualizarDCB`, `baixarDCB`, `criarConteudoDCB`)
- Template rendering and user interactions

#### Edge Cases Tests
- Date validation with invalid/malformed dates
- PDF generation with special characters and long names
- Concurrent API calls and race conditions
- Memory management during component destruction
- SweetAlert integration edge cases
- Tenant validation scenarios

### Integration Tests (`tests/integration/`)

#### Full Workflow Tests
- Complete DCB generation workflow for approved products
- End-to-end rejection handling for non-approved products
- Multi-tenant data isolation
- Document management integration
- Loading state management

#### Error Scenarios
- Authentication failure handling
- Database connection errors
- Network timeout scenarios
- Graceful error recovery

## Test Data Factories

### Product Factory (`produtoFactory.js`)
```javascript
import { createProduto, createProdutoList, createProdutoRejeitado } from '../factories'

// Create a single approved product
const produto = createProduto({ nome: 'Custom Product' })

// Create multiple products
const produtos = createProdutoList(5)

// Create rejected product
const rejectedProduto = createProdutoRejeitado()
```

### Document Factory (`documentoFactory.js`)
```javascript
import { createDocumento, createDocumentoList } from '../factories'

// Create document for a product
const documento = createDocumento({ produto_id: 1 })

// Create multiple documents
const documentos = createDocumentoList(3, productId)
```

### User Factory (`userFactory.js`)
```javascript
import { createUser, createAuthResponse } from '../factories'

// Create authenticated user
const user = createUser({ email: 'test@example.com' })

// Create auth response
const authResponse = createAuthResponse()
```

## Mocking Strategy

### Supabase Mock
The Supabase client is completely mocked to prevent actual database calls during testing. The mock supports:
- Authentication methods (`getSession`, `getUser`)
- Query builder chain methods (`select`, `eq`, `order`, etc.)
- Database operations with configurable responses
- Error simulation for testing error handling

### PDF Generation Mock
jsPDF is mocked to test PDF generation without actually creating files:
```javascript
const mockPdf = {
  setFont: jest.fn().mockReturnThis(),
  text: jest.fn().mockReturnThis(),
  save: jest.fn()
}
```

### SweetAlert2 Mock
Vue SweetAlert2 plugin is mocked to test dialog interactions without actual UI popups.

## Custom Assertions

The test suite includes custom assertions for common testing patterns:

```javascript
import { expectSupabaseQuery, expectSweetAlert, expectPDFGeneration } from '../helpers/assertions'

// Assert Supabase query was called correctly
expectSupabaseQuery(supabase.from, 'produtos')

// Assert SweetAlert was called with expected config
expectSweetAlert(wrapper.vm.$swal, { icon: 'success' })

// Assert PDF generation
expectPDFGeneration(jsPDF, 'expected-filename.pdf')
```

## Test Scenarios Covered

### Authentication & Authorization
- ✅ User authentication state validation
- ✅ Tenant ID extraction from user metadata
- ✅ Fallback tenant lookup from database
- ✅ Unauthenticated user handling

### Data Loading & Management
- ✅ Product list loading with tenant filtering
- ✅ Product details loading with documents
- ✅ Loading state management
- ✅ Error handling for database failures
- ✅ Empty state handling

### Business Logic
- ✅ DCB status calculation based on validity dates
- ✅ Product approval status validation
- ✅ Date formatting and validation
- ✅ Missing data field handling

### PDF Generation
- ✅ PDF creation for approved products
- ✅ Content formatting and layout
- ✅ Error handling during PDF generation
- ✅ File naming conventions
- ✅ Special characters handling

### User Interface
- ✅ Product selection dropdown population
- ✅ Dynamic content rendering
- ✅ Button state management (enabled/disabled)
- ✅ Loading indicators
- ✅ Error message display

### Error Handling
- ✅ Network failures
- ✅ Invalid data handling
- ✅ Authentication errors
- ✅ Database constraint violations
- ✅ Third-party service failures

## Coverage Goals

The test suite aims for:
- **Lines**: 90%+
- **Functions**: 90%+
- **Branches**: 85%+
- **Statements**: 90%+

Current coverage can be checked with:
```bash
npm run test:coverage
```

## Best Practices Applied

### Testing Principles
- **Arrange-Act-Assert** pattern for clear test structure
- **Test isolation** - each test is independent
- **Mock external dependencies** - focus on unit under test
- **Descriptive test names** - clearly state what is being tested
- **Edge case coverage** - test boundary conditions and error states

### Maintenance Guidelines
- Keep test data factories up to date with schema changes
- Update mocks when external APIs change
- Add tests for new features and bug fixes
- Maintain test documentation
- Regular refactoring to reduce duplication

### Performance Considerations
- Parallel test execution enabled
- Efficient mock implementations
- Proper cleanup in `afterEach` hooks
- Minimal DOM manipulation in tests

## Troubleshooting

### Common Issues

#### Tests failing with "TypeError: Cannot read property 'X' of undefined"
- Check if all required mocks are properly set up
- Verify test data factories provide all required fields
- Ensure component props/data are correctly initialized

#### Timeout errors on async tests
- Use `flushPromises()` helper to wait for async operations
- Increase Jest timeout if needed: `jest.setTimeout(10000)`
- Check for unresolved promises in component lifecycle

#### Mock not being called as expected
- Verify mock setup in `beforeEach`
- Check if mock is properly imported and configured
- Use `console.log(mockFn.mock.calls)` to debug

### Debug Mode
Run tests with additional debugging:
```bash
# Run with verbose output
npx jest --verbose

# Run specific test with debug info
npx jest --verbose FormularioDCB.spec.js

# Run in watch mode for development
npm run test:watch FormularioDCB
```

## Contributing

When adding new tests:

1. Follow the existing test structure and naming conventions
2. Use test data factories instead of inline test data
3. Add appropriate mocks for external dependencies
4. Include both happy path and error scenarios
5. Update this README if adding new test categories or patterns

## Dependencies

### Testing Framework
- **Jest**: Test runner and assertion library
- **@vue/test-utils**: Vue component testing utilities
- **jest-environment-jsdom**: Browser-like environment for testing

### Test Utilities
- **vue-jest**: Vue SFC transformer for Jest
- **babel-jest**: JavaScript transformer
- **jest-serializer-vue**: Vue component snapshot serializer

### Mocks and Fixtures
- Custom mocks for Supabase, jsPDF, and SweetAlert2
- Test data factories for consistent test data generation
- Helper functions for common test patterns