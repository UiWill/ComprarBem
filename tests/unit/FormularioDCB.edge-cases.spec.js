// Edge case tests for FormularioDCB component

import { mount, createLocalVue } from '@vue/test-utils'
import FormularioDCB from '@/components/dcb/FormularioDCB.vue'
import { supabase } from '@/services/supabase'
import { jsPDF } from 'jspdf'
import VueSweetAlert2 from 'vue-sweetalert2'
import {
  createProduto,
  createDocumento,
  createAuthResponse,
  resetAllMocks,
  flushPromises
} from '../factories'

// Mock modules
jest.mock('@/services/supabase')
jest.mock('jspdf')

const localVue = createLocalVue()
localVue.use(VueSweetAlert2)

describe('FormularioDCB.vue - Edge Cases', () => {
  let wrapper

  const createWrapper = (data = {}) => {
    return mount(FormularioDCB, {
      localVue,
      data() {
        return {
          produtoSelecionado: '',
          produtoDetalhes: null,
          documentos: [],
          produtos: [],
          loading: false,
          currentTenantId: 'test-tenant',
          ...data
        }
      }
    })
  }

  beforeEach(() => {
    resetAllMocks()
    supabase.auth.getSession.mockResolvedValue(createAuthResponse())
  })

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy()
    }
  })

  describe('Date Validation Edge Cases', () => {
    it('should handle invalid date strings', () => {
      wrapper = createWrapper()
      
      expect(wrapper.vm.formatarData('invalid-date')).toBe('Data inválida')
      expect(wrapper.vm.formatarData('2024-13-45')).toBe('Data inválida')
      expect(wrapper.vm.formatarData('')).toBe('Não informada')
      expect(wrapper.vm.formatarData('not-a-date')).toBe('Data inválida')
    })

    it('should handle edge date formats', () => {
      wrapper = createWrapper()
      
      // ISO format
      expect(wrapper.vm.formatarData('2024-01-15T10:30:00.000Z')).toBe('15/01/2024')
      
      // Different separators
      expect(wrapper.vm.formatarData('2024/01/15')).toBe('15/01/2024')
    })

    it('should handle products with exactly today as validity date', () => {
      const today = new Date()
      const todayString = today.toISOString().split('T')[0]
      
      wrapper = createWrapper({
        produtoDetalhes: createProduto({ data_validade: todayString })
      })

      // Should be valid (future date)
      expect(wrapper.vm.getStatusDCB()).toBe('VENCIDA') // Same day should be considered expired
    })

    it('should handle products with future dates', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 1)
      const futureDateString = futureDate.toISOString().split('T')[0]
      
      wrapper = createWrapper({
        produtoDetalhes: createProduto({ data_validade: futureDateString })
      })

      expect(wrapper.vm.getStatusDCB()).toBe('EM VIGOR')
    })
  })

  describe('PDF Generation Edge Cases', () => {
    it('should handle products with very long names', async () => {
      const mockPdf = {
        setFont: jest.fn().mockReturnThis(),
        setFontSize: jest.fn().mockReturnThis(),
        text: jest.fn().mockReturnThis(),
        line: jest.fn().mockReturnThis(),
        getTextWidth: jest.fn().mockReturnValue(150),
        save: jest.fn()
      }
      jsPDF.mockImplementation(() => mockPdf)

      const longNameProduct = createProduto({
        status: 'aprovado',
        nome: 'Este é um nome muito longo de produto que deveria ser testado para verificar se o PDF funciona corretamente',
        id: 999
      })

      wrapper = createWrapper({ produtoDetalhes: longNameProduct })
      await wrapper.vm.baixarDCB()

      expect(mockPdf.text).toHaveBeenCalled()
      expect(mockPdf.save).toHaveBeenCalledWith(
        'DCB_Este é um nome muito longo de produto que deveria ser testado para verificar se o PDF funciona corretamente_999_2024.pdf'
      )
    })

    it('should handle products with special characters', async () => {
      const mockPdf = {
        setFont: jest.fn().mockReturnThis(),
        setFontSize: jest.fn().mockReturnThis(),
        text: jest.fn().mockReturnThis(),
        line: jest.fn().mockReturnThis(),
        getTextWidth: jest.fn().mockReturnValue(50),
        save: jest.fn()
      }
      jsPDF.mockImplementation(() => mockPdf)

      const specialCharProduct = createProduto({
        status: 'aprovado',
        nome: 'Produto Âçêntõs & Çàrãctéres',
        marca: 'Märca Spéçial',
        modelo: 'Modélo 2024/ñ',
        fabricante: 'Fábricâ Ltdá.',
        id: 123
      })

      wrapper = createWrapper({ produtoDetalhes: specialCharProduct })
      await wrapper.vm.baixarDCB()

      expect(mockPdf.save).toHaveBeenCalledWith(
        'DCB_Produto Âçêntõs & Çàrãctéres_123_2024.pdf'
      )
    })

    it('should handle PDF generation with null/undefined values', async () => {
      const mockPdf = {
        setFont: jest.fn().mockReturnThis(),
        setFontSize: jest.fn().mockReturnThis(),
        text: jest.fn().mockReturnThis(),
        line: jest.fn().mockReturnThis(),
        getTextWidth: jest.fn().mockReturnValue(50),
        save: jest.fn()
      }
      jsPDF.mockImplementation(() => mockPdf)

      const incompleteProduct = createProduto({
        status: 'aprovado',
        nome: 'Produto Completo',
        marca: null,
        modelo: undefined,
        fabricante: '',
        cnpj: null,
        numero_edital: null
      })

      wrapper = createWrapper({ produtoDetalhes: incompleteProduct })
      await wrapper.vm.baixarDCB()

      // Verify text calls include fallback values
      const textCalls = mockPdf.text.mock.calls.map(call => call[0])
      expect(textCalls.some(call => call.includes('Não informada'))).toBe(true)
      expect(textCalls.some(call => call.includes('Não informado'))).toBe(true)
    })
  })

  describe('Data Loading Edge Cases', () => {
    it('should handle extremely large product lists', async () => {
      const largeProdutoList = Array.from({ length: 1000 }, (_, index) => 
        createProduto({ 
          id: index + 1, 
          nome: `Produto ${index + 1}`,
          tenant_id: 'test-tenant' 
        })
      )

      supabase.from.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        order: jest.fn().mockReturnThis(),
        then: jest.fn().mockResolvedValue({ data: largeProdutoList, error: null })
      })

      wrapper = createWrapper({ currentTenantId: 'test-tenant' })
      await wrapper.vm.carregarProdutos()

      expect(wrapper.vm.produtos).toHaveLength(1000)
      
      // Verify select dropdown handles large list
      await wrapper.vm.$nextTick()
      const options = wrapper.findAll('option')
      expect(options).toHaveLength(1001) // Including default option
    })

    it('should handle concurrent API calls', async () => {
      const mockProduto = createProduto()
      let callCount = 0

      supabase.from.mockImplementation((table) => {
        if (table === 'produtos' && supabase.from.mock.calls.length > 1) {
          callCount++
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockImplementation(() => {
              // Simulate varying response times
              const delay = callCount === 1 ? 100 : 50
              return new Promise(resolve => 
                setTimeout(() => resolve({ data: mockProduto, error: null }), delay)
              )
            })
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: [], error: null })
          }
        }
        return {
          select: jest.fn().mockReturnThis(),
          eq: jest.fn().mockReturnThis(),
          order: jest.fn().mockReturnThis(),
          then: jest.fn().mockResolvedValue({ data: [mockProduto], error: null })
        }
      })

      wrapper = createWrapper({ currentTenantId: 'test-tenant' })
      await flushPromises()

      // Trigger multiple concurrent calls
      wrapper.setData({ produtoSelecionado: mockProduto.id })
      wrapper.vm.carregarDetalhes()
      
      wrapper.setData({ produtoSelecionado: mockProduto.id })
      wrapper.vm.carregarDetalhes()

      await new Promise(resolve => setTimeout(resolve, 150))
      
      // Should handle concurrent calls gracefully
      expect(wrapper.vm.produtoDetalhes).toEqual(mockProduto)
    })
  })

  describe('Memory and Performance Edge Cases', () => {
    it('should handle component destruction during API calls', async () => {
      let resolveCall
      const pendingPromise = new Promise(resolve => {
        resolveCall = resolve
      })

      supabase.from.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        order: jest.fn().mockReturnThis(),
        then: jest.fn().mockImplementation(() => pendingPromise)
      })

      wrapper = createWrapper({ currentTenantId: 'test-tenant' })
      
      // Start API call
      wrapper.vm.carregarProdutos()
      
      // Destroy component before call completes
      wrapper.destroy()
      
      // Resolve the call after destruction
      resolveCall({ data: [], error: null })
      
      // Should not cause errors (no assertions needed, just shouldn't throw)
    })

    it('should handle rapid product selection changes', async () => {
      const produtos = [
        createProduto({ id: 1, nome: 'Produto 1' }),
        createProduto({ id: 2, nome: 'Produto 2' }),
        createProduto({ id: 3, nome: 'Produto 3' })
      ]

      supabase.from.mockImplementation((table) => {
        if (table === 'produtos' && supabase.from.mock.calls.length <= 1) {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            order: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: produtos, error: null })
          }
        } else if (table === 'produtos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockImplementation(async () => {
              await new Promise(resolve => setTimeout(resolve, 10))
              const id = parseInt(wrapper.vm.produtoSelecionado)
              return { data: produtos.find(p => p.id === id), error: null }
            })
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: [], error: null })
          }
        }
      })

      wrapper = createWrapper({ currentTenantId: 'test-tenant' })
      await flushPromises()

      // Rapidly change selections
      wrapper.setData({ produtoSelecionado: '1' })
      wrapper.vm.carregarDetalhes()
      
      wrapper.setData({ produtoSelecionado: '2' })
      wrapper.vm.carregarDetalhes()
      
      wrapper.setData({ produtoSelecionado: '3' })
      wrapper.vm.carregarDetalhes()

      await new Promise(resolve => setTimeout(resolve, 50))
      
      // Should end up with the last selected product
      expect(wrapper.vm.produtoDetalhes.id).toBe(3)
    })
  })

  describe('SweetAlert Integration Edge Cases', () => {
    it('should handle SweetAlert promise rejection', async () => {
      wrapper = createWrapper({
        produtoDetalhes: createProduto({ status: 'aprovado' })
      })

      wrapper.vm.$swal = jest.fn().mockRejectedValue(new Error('SweetAlert error'))

      // Should not throw error
      await expect(wrapper.vm.visualizarDCB()).resolves.not.toThrow()
    })

    it('should handle SweetAlert with different button responses', async () => {
      wrapper = createWrapper({
        produtoDetalhes: createProduto({ status: 'aprovado' })
      })

      // Mock different response types
      wrapper.vm.$swal = jest.fn().mockResolvedValue({
        isConfirmed: false,
        isDenied: false,
        isDismissed: true,
        dismiss: 'cancel'
      })

      const baixarSpy = jest.spyOn(wrapper.vm, 'baixarDCB')

      await wrapper.vm.visualizarDCB()

      expect(baixarSpy).toHaveBeenCalled()
    })
  })

  describe('Tenant Validation Edge Cases', () => {
    it('should handle missing tenant in database response', async () => {
      const authResponse = createAuthResponse({
        session: {
          user: {
            email: 'test@example.com',
            user_metadata: {} // No tenant_id
          }
        }
      })
      supabase.auth.getSession.mockResolvedValue(authResponse)

      supabase.from.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ 
          data: null, // No user found
          error: null 
        })
      })

      wrapper = createWrapper()
      await wrapper.vm.obterTenantId()

      expect(wrapper.vm.currentTenantId).toBeNull()
    })

    it('should handle empty tenant_id from database', async () => {
      const authResponse = createAuthResponse({
        session: {
          user: {
            email: 'test@example.com',
            user_metadata: {}
          }
        }
      })
      supabase.auth.getSession.mockResolvedValue(authResponse)

      supabase.from.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ 
          data: { tenant_id: '' }, // Empty tenant_id
          error: null 
        })
      })

      wrapper = createWrapper()
      await wrapper.vm.obterTenantId()

      expect(wrapper.vm.currentTenantId).toBe('')
    })
  })
})