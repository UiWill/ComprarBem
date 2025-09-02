// Unit tests for FormularioDCB component

import { mount, createLocalVue } from '@vue/test-utils'
import FormularioDCB from '@/components/dcb/FormularioDCB.vue'
import { supabase } from '@/services/supabase'
import { jsPDF } from 'jspdf'
import VueSweetAlert2 from 'vue-sweetalert2'
import {
  createProduto,
  createProdutoList,
  createProdutoRejeitado,
  createProdutoVencido,
  createProdutoSemDatas,
  createDocumentoList,
  createAuthResponse,
  createUserWithoutTenant,
  resetAllMocks,
  flushPromises
} from '../factories'

// Mock modules
jest.mock('@/services/supabase')
jest.mock('jspdf')

const localVue = createLocalVue()
localVue.use(VueSweetAlert2)

describe('FormularioDCB.vue', () => {
  let wrapper

  // Helper function to create wrapper with common setup
  const createWrapper = (data = {}, methods = {}) => {
    return mount(FormularioDCB, {
      localVue,
      data() {
        return {
          produtoSelecionado: '',
          produtoDetalhes: null,
          documentos: [],
          produtos: [],
          loading: false,
          currentTenantId: null,
          ...data
        }
      },
      methods: {
        ...methods
      }
    })
  }

  beforeEach(() => {
    resetAllMocks()
    
    // Default mock implementations
    supabase.auth.getSession.mockResolvedValue(createAuthResponse())
    supabase.from.mockReturnValue({
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      order: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({ data: createProduto(), error: null }),
      then: jest.fn().mockResolvedValue({ data: createProdutoList(), error: null })
    })
  })

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy()
    }
  })

  describe('Component Initialization', () => {
    it('should render component with proper title', () => {
      wrapper = createWrapper()
      expect(wrapper.find('h2').text()).toBe('Declaração de Conformidade de Bem (DCB)')
    })

    it('should initialize with correct default data', () => {
      wrapper = createWrapper()
      const vm = wrapper.vm

      expect(vm.produtoSelecionado).toBe('')
      expect(vm.produtoDetalhes).toBeNull()
      expect(vm.documentos).toEqual([])
      expect(vm.produtos).toEqual([])
      expect(vm.loading).toBe(false)
      expect(vm.currentTenantId).toBeNull()
    })

    it('should call obterTenantId and carregarProdutos on created', async () => {
      const obterTenantIdSpy = jest.spyOn(FormularioDCB.methods, 'obterTenantId').mockResolvedValue()
      const carregarProdutosSpy = jest.spyOn(FormularioDCB.methods, 'carregarProdutos').mockResolvedValue()

      wrapper = mount(FormularioDCB, { localVue })
      await flushPromises()

      expect(obterTenantIdSpy).toHaveBeenCalled()
      expect(carregarProdutosSpy).toHaveBeenCalled()

      obterTenantIdSpy.mockRestore()
      carregarProdutosSpy.mockRestore()
    })
  })

  describe('Computed Properties', () => {
    describe('produtoAprovado', () => {
      it('should return true when product status is "aprovado"', () => {
        wrapper = createWrapper({
          produtoDetalhes: createProduto({ status: 'aprovado' })
        })

        expect(wrapper.vm.produtoAprovado).toBe(true)
      })

      it('should return false when product status is not "aprovado"', () => {
        wrapper = createWrapper({
          produtoDetalhes: createProdutoRejeitado()
        })

        expect(wrapper.vm.produtoAprovado).toBe(false)
      })

      it('should return false when produtoDetalhes is null', () => {
        wrapper = createWrapper({
          produtoDetalhes: null
        })

        expect(wrapper.vm.produtoAprovado).toBe(false)
      })
    })
  })

  describe('Authentication Methods', () => {
    describe('obterTenantId', () => {
      it('should extract tenant_id from user metadata', async () => {
        const authResponse = createAuthResponse({
          session: {
            user: {
              user_metadata: { tenant_id: 'test-tenant-123' }
            }
          }
        })
        supabase.auth.getSession.mockResolvedValue(authResponse)

        wrapper = createWrapper()
        await wrapper.vm.obterTenantId()

        expect(wrapper.vm.currentTenantId).toBe('test-tenant-123')
      })

      it('should fetch tenant_id from usuarios table when not in metadata', async () => {
        const authResponse = createAuthResponse({
          session: {
            user: createUserWithoutTenant({ email: 'test@example.com' })
          }
        })
        supabase.auth.getSession.mockResolvedValue(authResponse)
        supabase.from.mockReturnValue({
          select: jest.fn().mockReturnThis(),
          eq: jest.fn().mockReturnThis(),
          single: jest.fn().mockResolvedValue({ 
            data: { tenant_id: 'fetched-tenant-id' }, 
            error: null 
          })
        })

        wrapper = createWrapper()
        await wrapper.vm.obterTenantId()

        expect(supabase.from).toHaveBeenCalledWith('usuarios')
        expect(wrapper.vm.currentTenantId).toBe('fetched-tenant-id')
      })

      it('should handle unauthenticated user', async () => {
        supabase.auth.getSession.mockResolvedValue({
          data: { session: null },
          error: null
        })
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

        wrapper = createWrapper()
        await wrapper.vm.obterTenantId()

        expect(consoleSpy).toHaveBeenCalledWith('Usuário não está autenticado')
        expect(wrapper.vm.currentTenantId).toBeNull()

        consoleSpy.mockRestore()
      })

      it('should handle database error when fetching tenant', async () => {
        const authResponse = createAuthResponse({
          session: {
            user: createUserWithoutTenant()
          }
        })
        supabase.auth.getSession.mockResolvedValue(authResponse)
        supabase.from.mockReturnValue({
          select: jest.fn().mockReturnThis(),
          eq: jest.fn().mockReturnThis(),
          single: jest.fn().mockResolvedValue({ 
            data: null, 
            error: { message: 'Database error' } 
          })
        })
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

        wrapper = createWrapper()
        await wrapper.vm.obterTenantId()

        expect(consoleSpy).toHaveBeenCalledWith('Erro ao buscar tenant_id:', { message: 'Database error' })

        consoleSpy.mockRestore()
      })
    })
  })

  describe('Data Loading Methods', () => {
    describe('carregarProdutos', () => {
      it('should load produtos successfully', async () => {
        const mockProdutos = createProdutoList(3)
        supabase.from.mockReturnValue({
          select: jest.fn().mockReturnThis(),
          eq: jest.fn().mockReturnThis(),
          order: jest.fn().mockReturnThis(),
          then: jest.fn().mockResolvedValue({ data: mockProdutos, error: null })
        })

        wrapper = createWrapper({ currentTenantId: 'test-tenant-id' })
        await wrapper.vm.carregarProdutos()

        expect(supabase.from).toHaveBeenCalledWith('produtos')
        expect(wrapper.vm.produtos).toEqual(mockProdutos)
      })

      it('should handle missing tenant_id', async () => {
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

        wrapper = createWrapper({ currentTenantId: null })
        await wrapper.vm.carregarProdutos()

        expect(consoleSpy).toHaveBeenCalledWith('Tenant ID não disponível')

        consoleSpy.mockRestore()
      })

      it('should handle database error', async () => {
        supabase.from.mockReturnValue({
          select: jest.fn().mockReturnThis(),
          eq: jest.fn().mockReturnThis(),
          order: jest.fn().mockReturnThis(),
          then: jest.fn().mockRejectedValue(new Error('Database error'))
        })
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

        wrapper = createWrapper({ currentTenantId: 'test-tenant-id' })
        await wrapper.vm.carregarProdutos()

        expect(consoleSpy).toHaveBeenCalledWith('Erro ao carregar produtos:', expect.any(Error))
        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível carregar os produtos.'
        })

        consoleSpy.mockRestore()
      })
    })

    describe('carregarDetalhes', () => {
      beforeEach(() => {
        wrapper = createWrapper({ currentTenantId: 'test-tenant-id' })
      })

      it('should reset data when no product is selected', async () => {
        wrapper.setData({
          produtoSelecionado: '',
          produtoDetalhes: createProduto(),
          documentos: createDocumentoList(2)
        })

        await wrapper.vm.carregarDetalhes()

        expect(wrapper.vm.produtoDetalhes).toBeNull()
        expect(wrapper.vm.documentos).toEqual([])
      })

      it('should load product details and documents successfully', async () => {
        const mockProduto = createProduto()
        const mockDocumentos = createDocumentoList(2, mockProduto.id)

        supabase.from.mockImplementation((table) => {
          if (table === 'produtos') {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: mockProduto, error: null })
            }
          } else if (table === 'documentos') {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: mockDocumentos, error: null })
            }
          }
        })

        wrapper.setData({ produtoSelecionado: mockProduto.id })
        await wrapper.vm.carregarDetalhes()

        expect(wrapper.vm.produtoDetalhes).toEqual(mockProduto)
        expect(wrapper.vm.documentos).toEqual(mockDocumentos)
        expect(wrapper.vm.loading).toBe(false)
      })

      it('should generate missing dates and edital number', async () => {
        const mockProduto = createProdutoSemDatas()
        supabase.from.mockImplementation((table) => {
          if (table === 'produtos') {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: mockProduto, error: null })
            }
          } else if (table === 'documentos') {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: [], error: null })
            }
          }
        })

        wrapper.setData({ produtoSelecionado: mockProduto.id })
        await wrapper.vm.carregarDetalhes()

        expect(wrapper.vm.produtoDetalhes.data_emissao).toBeTruthy()
        expect(wrapper.vm.produtoDetalhes.data_validade).toBeTruthy()
        expect(wrapper.vm.produtoDetalhes.numero_edital).toBeTruthy()
      })

      it('should handle product loading error', async () => {
        supabase.from.mockReturnValue({
          select: jest.fn().mockReturnThis(),
          eq: jest.fn().mockReturnThis(),
          single: jest.fn().mockRejectedValue(new Error('Product error'))
        })
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

        wrapper.setData({ produtoSelecionado: 1 })
        await wrapper.vm.carregarDetalhes()

        expect(consoleSpy).toHaveBeenCalledWith('Erro ao carregar detalhes do produto:', expect.any(Error))
        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível carregar os detalhes do produto.'
        })
        expect(wrapper.vm.loading).toBe(false)

        consoleSpy.mockRestore()
      })
    })
  })

  describe('Status and Formatting Methods', () => {
    describe('getStatusDCB', () => {
      it('should return "EM VIGOR" for valid product', () => {
        const futureDate = new Date()
        futureDate.setFullYear(futureDate.getFullYear() + 1)
        
        wrapper = createWrapper({
          produtoDetalhes: createProduto({
            data_validade: futureDate.toISOString().split('T')[0]
          })
        })

        expect(wrapper.vm.getStatusDCB()).toBe('EM VIGOR')
      })

      it('should return "VENCIDA" for expired product', () => {
        wrapper = createWrapper({
          produtoDetalhes: createProdutoVencido()
        })

        expect(wrapper.vm.getStatusDCB()).toBe('VENCIDA')
      })

      it('should return "VENCIDA" when no product or no date', () => {
        wrapper = createWrapper({ produtoDetalhes: null })
        expect(wrapper.vm.getStatusDCB()).toBe('VENCIDA')

        wrapper.setData({ produtoDetalhes: createProduto({ data_validade: null }) })
        expect(wrapper.vm.getStatusDCB()).toBe('VENCIDA')
      })
    })

    describe('getStatusDCBClass', () => {
      it('should return correct CSS class for "EM VIGOR"', () => {
        wrapper = createWrapper()
        jest.spyOn(wrapper.vm, 'getStatusDCB').mockReturnValue('EM VIGOR')

        const classes = wrapper.vm.getStatusDCBClass()
        expect(classes).toEqual({
          'status-em-vigor': true,
          'status-vencida': false
        })
      })

      it('should return correct CSS class for "VENCIDA"', () => {
        wrapper = createWrapper()
        jest.spyOn(wrapper.vm, 'getStatusDCB').mockReturnValue('VENCIDA')

        const classes = wrapper.vm.getStatusDCBClass()
        expect(classes).toEqual({
          'status-em-vigor': false,
          'status-vencida': true
        })
      })
    })

    describe('formatarData', () => {
      it('should format valid date to Brazilian format', () => {
        wrapper = createWrapper()
        const result = wrapper.vm.formatarData('2024-01-15')
        expect(result).toBe('15/01/2024')
      })

      it('should handle null date', () => {
        wrapper = createWrapper()
        const result = wrapper.vm.formatarData(null)
        expect(result).toBe('Não informada')
      })

      it('should handle undefined date', () => {
        wrapper = createWrapper()
        const result = wrapper.vm.formatarData()
        expect(result).toBe('Não informada')
      })

      it('should handle invalid date', () => {
        wrapper = createWrapper()
        const result = wrapper.vm.formatarData('invalid-date')
        expect(result).toBe('Data inválida')
      })
    })
  })

  describe('DCB Actions', () => {
    describe('visualizarDCB', () => {
      it('should show DCB modal for approved product', async () => {
        wrapper = createWrapper({
          produtoDetalhes: createProduto({ status: 'aprovado' })
        })
        jest.spyOn(wrapper.vm, 'criarConteudoDCB').mockReturnValue('<div>DCB Content</div>')

        await wrapper.vm.visualizarDCB()

        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          title: 'Declaração de Conformidade de Bem',
          html: '<div>DCB Content</div>',
          width: '800px',
          showConfirmButton: true,
          confirmButtonText: 'Fechar',
          showCancelButton: true,
          cancelButtonText: '📥 Baixar PDF',
          cancelButtonColor: '#3498db'
        })
      })

      it('should show error for non-approved product', async () => {
        wrapper = createWrapper({
          produtoDetalhes: createProdutoRejeitado()
        })

        await wrapper.vm.visualizarDCB()

        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          icon: 'error',
          title: 'Não disponível',
          text: 'Apenas produtos aprovados possuem Declaração de Conformidade disponível.'
        })
      })

      it('should show error when no product selected', async () => {
        wrapper = createWrapper({
          produtoDetalhes: null
        })

        await wrapper.vm.visualizarDCB()

        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          icon: 'error',
          title: 'Não disponível',
          text: 'Apenas produtos aprovados possuem Declaração de Conformidade disponível.'
        })
      })
    })

    describe('baixarDCB', () => {
      beforeEach(() => {
        jsPDF.mockClear()
      })

      it('should generate PDF for approved product', async () => {
        const mockPdf = {
          setFont: jest.fn().mockReturnThis(),
          setFontSize: jest.fn().mockReturnThis(),
          text: jest.fn().mockReturnThis(),
          line: jest.fn().mockReturnThis(),
          getTextWidth: jest.fn().mockReturnValue(50),
          save: jest.fn()
        }
        jsPDF.mockImplementation(() => mockPdf)

        wrapper = createWrapper({
          produtoDetalhes: createProduto({ 
            status: 'aprovado',
            nome: 'Teste PDF',
            id: 123
          })
        })

        await wrapper.vm.baixarDCB()

        expect(jsPDF).toHaveBeenCalledWith('p', 'mm', 'a4')
        expect(mockPdf.save).toHaveBeenCalledWith('DCB_Teste PDF_123_2024.pdf')
        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          icon: 'success',
          title: 'PDF Gerado!',
          text: 'DCB baixada como: DCB_Teste PDF_123_2024.pdf',
          timer: 3000,
          showConfirmButton: false
        })
      })

      it('should show error for non-approved product', async () => {
        wrapper = createWrapper({
          produtoDetalhes: createProdutoRejeitado()
        })

        await wrapper.vm.baixarDCB()

        expect(jsPDF).not.toHaveBeenCalled()
        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          icon: 'error',
          title: 'Não disponível',
          text: 'Apenas produtos aprovados possuem Declaração de Conformidade disponível.'
        })
      })

      it('should handle PDF generation error', async () => {
        jsPDF.mockImplementation(() => {
          throw new Error('PDF Error')
        })
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

        wrapper = createWrapper({
          produtoDetalhes: createProduto({ status: 'aprovado' })
        })

        await wrapper.vm.baixarDCB()

        expect(consoleSpy).toHaveBeenCalledWith('Erro ao gerar PDF:', expect.any(Error))
        expect(wrapper.vm.$swal).toHaveBeenCalledWith({
          icon: 'error',
          title: 'Erro ao gerar PDF',
          text: 'Ocorreu um erro ao gerar o arquivo PDF.'
        })

        consoleSpy.mockRestore()
      })
    })

    describe('criarConteudoDCB', () => {
      it('should create DCB HTML content', () => {
        const produto = createProduto({
          id: 123,
          nome: 'Produto Teste HTML',
          marca: 'Marca HTML',
          modelo: 'Modelo HTML'
        })

        wrapper = createWrapper({ produtoDetalhes: produto })
        const content = wrapper.vm.criarConteudoDCB()

        expect(content).toContain('DECLARAÇÃO DE CONFORMIDADE DE BEM')
        expect(content).toContain('DCB Nº 123/2024')
        expect(content).toContain('Produto Teste HTML')
        expect(content).toContain('Marca HTML')
        expect(content).toContain('Modelo HTML')
        expect(content).toContain('PRODUTO CERTIFICADO')
        expect(content).toContain('DADOS DA CERTIFICAÇÃO')
        expect(content).toContain('DECLARAÇÃO')
      })
    })
  })

  describe('Template Rendering', () => {
    it('should render product selection dropdown', () => {
      wrapper = createWrapper({
        produtos: createProdutoList(2)
      })

      const select = wrapper.find('select#produto')
      expect(select.exists()).toBe(true)
      expect(select.findAll('option')).toHaveLength(3) // Including default option
    })

    it('should show loading message when loading', () => {
      wrapper = createWrapper({ loading: true })
      expect(wrapper.find('.loading').text()).toContain('Carregando informações...')
    })

    it('should show product details when product is selected', () => {
      wrapper = createWrapper({
        produtoDetalhes: createProduto()
      })

      expect(wrapper.find('.produto-detalhes').exists()).toBe(true)
      expect(wrapper.find('h3').text()).toBe('PRODUTO CERTIFICADO')
    })

    it('should disable buttons for non-approved products', () => {
      wrapper = createWrapper({
        produtoDetalhes: createProdutoRejeitado()
      })

      const visualizarBtn = wrapper.find('.btn-primary')
      const baixarBtn = wrapper.find('.btn-secondary')

      expect(visualizarBtn.attributes('disabled')).toBe('disabled')
      expect(baixarBtn.attributes('disabled')).toBe('disabled')
    })

    it('should show warning message for non-approved products', () => {
      wrapper = createWrapper({
        produtoDetalhes: createProdutoRejeitado()
      })

      const aviso = wrapper.find('.aviso')
      expect(aviso.exists()).toBe(true)
      expect(aviso.text()).toContain('Somente produtos aprovados possuem Declaração de Conformidade disponível')
    })

    it('should render documents list when available', () => {
      wrapper = createWrapper({
        produtoDetalhes: createProduto(),
        documentos: createDocumentoList(2)
      })

      const documentosList = wrapper.find('.documentos')
      expect(documentosList.exists()).toBe(true)
      expect(wrapper.findAll('.documento-item')).toHaveLength(2)
    })
  })

  describe('User Interactions', () => {
    it('should call carregarDetalhes when product selection changes', async () => {
      wrapper = createWrapper({
        produtos: createProdutoList(2)
      })

      const carregarDetalhesSpy = jest.spyOn(wrapper.vm, 'carregarDetalhes')
      const select = wrapper.find('select#produto')

      await select.setValue('1')
      expect(carregarDetalhesSpy).toHaveBeenCalled()
    })

    it('should call visualizarDCB when visualizar button is clicked', async () => {
      wrapper = createWrapper({
        produtoDetalhes: createProduto({ status: 'aprovado' })
      })

      const visualizarSpy = jest.spyOn(wrapper.vm, 'visualizarDCB')
      const button = wrapper.find('.btn-primary')

      await button.trigger('click')
      expect(visualizarSpy).toHaveBeenCalled()
    })

    it('should call baixarDCB when download button is clicked', async () => {
      wrapper = createWrapper({
        produtoDetalhes: createProduto({ status: 'aprovado' })
      })

      const baixarSpy = jest.spyOn(wrapper.vm, 'baixarDCB')
      const button = wrapper.find('.btn-secondary')

      await button.trigger('click')
      expect(baixarSpy).toHaveBeenCalled()
    })
  })
})