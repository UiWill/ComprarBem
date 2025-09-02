// Test data factory for produtos

export const createProduto = (overrides = {}) => ({
  id: 1,
  nome: 'Produto Teste',
  marca: 'Marca Teste',
  modelo: 'Modelo Teste',
  fabricante: 'Fabricante Teste',
  cnpj: '12.345.678/0001-90',
  status: 'aprovado',
  data_emissao: '2024-01-15',
  data_validade: '2025-01-15',
  numero_edital: '001/2024',
  tenant_id: 'test-tenant-id',
  categoria: 'Eletrônicos',
  descricao: 'Descrição do produto teste',
  especificacoes: 'Especificações técnicas',
  created_at: '2024-01-15T10:00:00.000Z',
  updated_at: '2024-01-15T10:00:00.000Z',
  ...overrides
})

export const createProdutoList = (count = 3, overrides = {}) => {
  return Array.from({ length: count }, (_, index) => 
    createProduto({
      id: index + 1,
      nome: `Produto Teste ${index + 1}`,
      marca: `Marca ${index + 1}`,
      modelo: `Modelo ${index + 1}`,
      ...overrides
    })
  )
}

export const createProdutoRejeitado = (overrides = {}) => 
  createProduto({
    status: 'rejeitado',
    ...overrides
  })

export const createProdutoVencido = (overrides = {}) => 
  createProduto({
    data_validade: '2023-01-15', // Data no passado
    ...overrides
  })

export const createProdutoSemDatas = (overrides = {}) => 
  createProduto({
    data_emissao: null,
    data_validade: null,
    numero_edital: null,
    ...overrides
  })