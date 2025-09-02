// Test data factory for users and sessions

export const createUser = (overrides = {}) => ({
  id: 'test-user-id',
  email: 'test@example.com',
  user_metadata: {
    tenant_id: 'test-tenant-id',
    nome: 'Usuario Teste',
    role: 'user'
  },
  app_metadata: {},
  aud: 'authenticated',
  created_at: '2024-01-15T10:00:00.000Z',
  updated_at: '2024-01-15T10:00:00.000Z',
  ...overrides
})

export const createSession = (overrides = {}) => ({
  user: createUser(overrides.user || {}),
  access_token: 'mock-access-token',
  refresh_token: 'mock-refresh-token',
  expires_at: Math.floor(Date.now() / 1000) + 3600,
  token_type: 'bearer',
  ...overrides
})

export const createAuthResponse = (overrides = {}) => ({
  data: {
    session: createSession(overrides.session || {}),
    user: createUser(overrides.user || {})
  },
  error: null,
  ...overrides
})

export const createUserWithoutTenant = (overrides = {}) => 
  createUser({
    user_metadata: {
      nome: 'Usuario sem Tenant',
      role: 'user'
    },
    ...overrides
  })

export const createAdminUser = (overrides = {}) => 
  createUser({
    user_metadata: {
      tenant_id: 'test-tenant-id',
      nome: 'Admin Teste',
      role: 'admin'
    },
    ...overrides
  })