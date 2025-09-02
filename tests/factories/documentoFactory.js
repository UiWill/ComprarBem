// Test data factory for documentos

export const createDocumento = (overrides = {}) => ({
  id: 1,
  produto_id: 1,
  nome: 'Documento Teste.pdf',
  arquivo_url: 'http://example.com/documento-teste.pdf',
  tipo: 'certificado',
  tamanho: 1024,
  tenant_id: 'test-tenant-id',
  created_at: '2024-01-15T10:00:00.000Z',
  updated_at: '2024-01-15T10:00:00.000Z',
  ...overrides
})

export const createDocumentoList = (count = 2, produtoId = 1, overrides = {}) => {
  return Array.from({ length: count }, (_, index) => 
    createDocumento({
      id: index + 1,
      produto_id: produtoId,
      nome: `Documento ${index + 1}.pdf`,
      arquivo_url: `http://example.com/documento-${index + 1}.pdf`,
      ...overrides
    })
  )
}

export const createDocumentoSemArquivo = (overrides = {}) => 
  createDocumento({
    arquivo_url: null,
    ...overrides
  })