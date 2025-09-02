// Integration tests for FormularioDCB component

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

describe('FormularioDCB.vue - Integration Tests', () => {
  let wrapper

  const createWrapper = () => {
    return mount(FormularioDCB, {
      localVue
    })
  }

  beforeEach(() => {
    resetAllMocks()
  })

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy()
    }
  })

  describe('Full Component Workflow', () => {
    it('should complete full DCB generation workflow for approved product', async () => {
      // Mock successful authentication
      const authResponse = createAuthResponse({
        session: {
          user: {
            user_metadata: { tenant_id: 'integration-tenant' }
          }
        }
      })
      supabase.auth.getSession.mockResolvedValue(authResponse)

      // Mock successful products loading
      const mockProdutos = createProdutoList(3, { tenant_id: 'integration-tenant' })
      const mockProduto = mockProdutos[0]
      const mockDocumentos = createDocumentoList(2, mockProduto.id)

      // Setup Supabase mocks for different calls
      supabase.from.mockImplementation((table) => {
        if (table === 'produtos') {
          // For carregarProdutos
          if (supabase.from.mock.calls.length <= 1) {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              order: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: mockProdutos, error: null })
            }
          }
          // For carregarDetalhes
          else {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: mockProduto, error: null })
            }
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: mockDocumentos, error: null })
          }
        }
        return {
          select: jest.fn().mockReturnThis(),
          eq: jest.fn().mockReturnThis(),
          single: jest.fn().mockReturnThis(),
          then: jest.fn().mockResolvedValue({ data: null, error: null })
        }
      })

      // Mock PDF generation
      const mockPdf = {
        setFont: jest.fn().mockReturnThis(),
        setFontSize: jest.fn().mockReturnThis(),
        text: jest.fn().mockReturnThis(),
        line: jest.fn().mockReturnThis(),
        getTextWidth: jest.fn().mockReturnValue(50),
        save: jest.fn()
      }
      jsPDF.mockImplementation(() => mockPdf)

      // Create component
      wrapper = createWrapper()
      await flushPromises()

      // Verify initial setup completed
      expect(wrapper.vm.currentTenantId).toBe('integration-tenant')
      expect(wrapper.vm.produtos).toEqual(mockProdutos)

      // Select a product
      const select = wrapper.find('select#produto')
      await select.setValue(mockProduto.id.toString())
      await flushPromises()

      // Verify product details loaded
      expect(wrapper.vm.produtoDetalhes).toEqual(mockProduto)
      expect(wrapper.vm.documentos).toEqual(mockDocumentos)

      // Verify UI shows product details
      expect(wrapper.find('.produto-detalhes').exists()).toBe(true)
      expect(wrapper.text()).toContain(mockProduto.nome)
      expect(wrapper.text()).toContain(mockProduto.marca)

      // Test DCB visualization
      const visualizarBtn = wrapper.find('.btn-primary')
      expect(visualizarBtn.attributes('disabled')).toBeUndefined()
      
      await visualizarBtn.trigger('click')
      expect(wrapper.vm.$swal).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'Declaração de Conformidade de Bem',
          html: expect.stringContaining('DECLARAÇÃO DE CONFORMIDADE DE BEM')
        })
      )

      // Test PDF generation
      const baixarBtn = wrapper.find('.btn-secondary')
      await baixarBtn.trigger('click')
      
      expect(jsPDF).toHaveBeenCalledWith('p', 'mm', 'a4')
      expect(mockPdf.save).toHaveBeenCalled()
      expect(wrapper.vm.$swal).toHaveBeenCalledWith(
        expect.objectContaining({
          icon: 'success',
          title: 'PDF Gerado!'
        })
      )
    })

    it('should handle complete workflow with rejected product', async () => {
      // Mock authentication
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      // Mock rejected product
      const rejectedProduto = createProdutoRejeitado()
      const mockProdutos = [rejectedProduto]

      supabase.from.mockImplementation((table) => {
        if (table === 'produtos') {
          if (supabase.from.mock.calls.length <= 1) {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              order: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: mockProdutos, error: null })
            }
          } else {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: rejectedProduto, error: null })
            }
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: [], error: null })
          }
        }
      })

      wrapper = createWrapper()
      await flushPromises()

      // Select rejected product
      const select = wrapper.find('select#produto')
      await select.setValue(rejectedProduto.id.toString())
      await flushPromises()

      // Verify buttons are disabled
      const visualizarBtn = wrapper.find('.btn-primary')
      const baixarBtn = wrapper.find('.btn-secondary')

      expect(visualizarBtn.attributes('disabled')).toBe('disabled')
      expect(baixarBtn.attributes('disabled')).toBe('disabled')

      // Verify warning message is shown
      expect(wrapper.find('.aviso').exists()).toBe(true)
      expect(wrapper.find('.aviso').text()).toContain('Somente produtos aprovados possuem Declaração de Conformidade disponível')

      // Try to click buttons (should show error)
      await visualizarBtn.trigger('click')
      expect(wrapper.vm.$swal).toHaveBeenCalledWith({
        icon: 'error',
        title: 'Não disponível',
        text: 'Apenas produtos aprovados possuem Declaração de Conformidade disponível.'
      })
    })
  })

  describe('Error Handling Integration', () => {
    it('should handle authentication failure gracefully', async () => {
      // Mock authentication failure
      supabase.auth.getSession.mockResolvedValue({
        data: { session: null },
        error: null
      })

      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

      wrapper = createWrapper()
      await flushPromises()

      expect(wrapper.vm.currentTenantId).toBeNull()
      expect(consoleSpy).toHaveBeenCalledWith('Usuário não está autenticado')

      consoleSpy.mockRestore()
    })

    it('should handle database errors during product loading', async () => {
      // Mock successful auth but failed product loading
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      supabase.from.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        order: jest.fn().mockReturnThis(),
        then: jest.fn().mockRejectedValue(new Error('Database connection failed'))
      })

      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

      wrapper = createWrapper()
      await flushPromises()

      expect(consoleSpy).toHaveBeenCalledWith(
        'Erro ao carregar produtos:', 
        expect.any(Error)
      )
      expect(wrapper.vm.$swal).toHaveBeenCalledWith({
        icon: 'error',
        title: 'Erro',
        text: 'Não foi possível carregar os produtos.'
      })

      consoleSpy.mockRestore()
    })

    it('should handle network errors during product details loading', async () => {
      // Mock successful initial setup
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      const mockProdutos = createProdutoList(1)
      
      supabase.from.mockImplementation((table) => {
        if (table === 'produtos' && supabase.from.mock.calls.length <= 1) {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            order: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: mockProdutos, error: null })
          }
        } else {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            single: jest.fn().mockRejectedValue(new Error('Network timeout'))
          }
        }
      })

      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

      wrapper = createWrapper()
      await flushPromises()

      // Try to select a product (should fail)
      const select = wrapper.find('select#produto')
      await select.setValue(mockProdutos[0].id.toString())
      await flushPromises()

      expect(consoleSpy).toHaveBeenCalledWith(
        'Erro ao carregar detalhes do produto:', 
        expect.any(Error)
      )
      expect(wrapper.vm.$swal).toHaveBeenCalledWith({
        icon: 'error',
        title: 'Erro',
        text: 'Não foi possível carregar os detalhes do produto.'
      })

      consoleSpy.mockRestore()
    })
  })

  describe('Multi-tenant Integration', () => {
    it('should properly filter products by tenant', async () => {
      const tenant1Products = createProdutoList(2, { tenant_id: 'tenant-1' })
      const tenant2Products = createProdutoList(2, { tenant_id: 'tenant-2' })
      
      // Mock user from tenant-1
      const authResponse = createAuthResponse({
        session: {
          user: {
            user_metadata: { tenant_id: 'tenant-1' }
          }
        }
      })
      supabase.auth.getSession.mockResolvedValue(authResponse)

      // Mock database call - should only return tenant-1 products
      supabase.from.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        eq: jest.fn((field, value) => {
          expect(field).toBe('tenant_id')
          expect(value).toBe('tenant-1')
          return {
            eq: jest.fn().mockReturnThis(),
            order: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: tenant1Products, error: null })
          }
        }),
        order: jest.fn().mockReturnThis(),
        then: jest.fn().mockResolvedValue({ data: tenant1Products, error: null })
      })

      wrapper = createWrapper()
      await flushPromises()

      expect(wrapper.vm.produtos).toEqual(tenant1Products)
      expect(wrapper.vm.produtos.length).toBe(2)
      expect(wrapper.vm.produtos.every(p => p.tenant_id === 'tenant-1')).toBe(true)
    })

    it('should handle user without tenant_id in metadata', async () => {
      const authResponse = createAuthResponse({
        session: {
          user: createUserWithoutTenant({ email: 'tenant-user@test.com' })
        }
      })
      supabase.auth.getSession.mockResolvedValue(authResponse)

      // Mock database call to usuarios table
      supabase.from.mockImplementation((table) => {
        if (table === 'usuarios') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn((field, value) => {
              expect(field).toBe('email')
              expect(value).toBe('tenant-user@test.com')
              return {
                single: jest.fn().mockResolvedValue({ 
                  data: { tenant_id: 'fetched-tenant' }, 
                  error: null 
                })
              }
            })
          }
        } else if (table === 'produtos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            order: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: [], error: null })
          }
        }
      })

      wrapper = createWrapper()
      await flushPromises()

      expect(wrapper.vm.currentTenantId).toBe('fetched-tenant')
    })
  })

  describe('Date and Status Integration', () => {
    it('should correctly determine DCB status based on validity date', async () => {
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      // Test with expired product
      const expiredProduct = createProdutoVencido()
      
      supabase.from.mockImplementation((table) => {
        if (table === 'produtos') {
          if (supabase.from.mock.calls.length <= 1) {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              order: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: [expiredProduct], error: null })
            }
          } else {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: expiredProduct, error: null })
            }
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: [], error: null })
          }
        }
      })

      wrapper = createWrapper()
      await flushPromises()

      const select = wrapper.find('select#produto')
      await select.setValue(expiredProduct.id.toString())
      await flushPromises()

      // Verify expired status is shown
      expect(wrapper.text()).toContain('VENCIDA')
      expect(wrapper.find('.status-vencida').exists()).toBe(true)
    })

    it('should handle products with missing dates gracefully', async () => {
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      const productWithoutDates = createProduto({
        data_emissao: null,
        data_validade: null,
        numero_edital: null
      })
      
      supabase.from.mockImplementation((table) => {
        if (table === 'produtos') {
          if (supabase.from.mock.calls.length <= 1) {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              order: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: [productWithoutDates], error: null })
            }
          } else {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: productWithoutDates, error: null })
            }
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: [], error: null })
          }
        }
      })

      wrapper = createWrapper()
      await flushPromises()

      const select = wrapper.find('select#produto')
      await select.setValue(productWithoutDates.id.toString())
      await flushPromises()

      // Verify dates were auto-generated
      expect(wrapper.vm.produtoDetalhes.data_emissao).toBeTruthy()
      expect(wrapper.vm.produtoDetalhes.data_validade).toBeTruthy()
      expect(wrapper.vm.produtoDetalhes.numero_edital).toBeTruthy()
    })
  })

  describe('Document Management Integration', () => {
    it('should display documents when available', async () => {
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      const mockProduto = createProduto()
      const mockDocuments = createDocumentoList(3, mockProduto.id)

      supabase.from.mockImplementation((table) => {
        if (table === 'produtos') {
          if (supabase.from.mock.calls.length <= 1) {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              order: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: [mockProduto], error: null })
            }
          } else {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: mockProduto, error: null })
            }
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: mockDocuments, error: null })
          }
        }
      })

      wrapper = createWrapper()
      await flushPromises()

      const select = wrapper.find('select#produto')
      await select.setValue(mockProduto.id.toString())
      await flushPromises()

      // Verify documents section is displayed
      expect(wrapper.find('.documentos').exists()).toBe(true)
      expect(wrapper.find('h3').text()).toContain('Documentos Anexos')
      expect(wrapper.findAll('.documento-item')).toHaveLength(3)

      // Verify document links
      const documentLinks = wrapper.findAll('.btn-download')
      expect(documentLinks).toHaveLength(3)
      mockDocuments.forEach((doc, index) => {
        expect(documentLinks.at(index).attributes('href')).toBe(doc.arquivo_url)
      })
    })

    it('should handle empty document list', async () => {
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      const mockProduto = createProduto()

      supabase.from.mockImplementation((table) => {
        if (table === 'produtos') {
          if (supabase.from.mock.calls.length <= 1) {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              order: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: [mockProduto], error: null })
            }
          } else {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockResolvedValue({ data: mockProduto, error: null })
            }
          }
        } else if (table === 'documentos') {
          return {
            select: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            then: jest.fn().mockResolvedValue({ data: [], error: null })
          }
        }
      })

      wrapper = createWrapper()
      await flushPromises()

      const select = wrapper.find('select#produto')
      await select.setValue(mockProduto.id.toString())
      await flushPromises()

      // Verify documents section is not displayed when empty
      expect(wrapper.find('.documentos').exists()).toBe(false)
    })
  })

  describe('Loading States Integration', () => {
    it('should show loading state during product details fetch', async () => {
      const authResponse = createAuthResponse()
      supabase.auth.getSession.mockResolvedValue(authResponse)

      const mockProduto = createProduto()

      // Mock slow response
      let resolveProductCall
      const productPromise = new Promise((resolve) => {
        resolveProductCall = resolve
      })

      supabase.from.mockImplementation((table) => {
        if (table === 'produtos') {
          if (supabase.from.mock.calls.length <= 1) {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              order: jest.fn().mockReturnThis(),
              then: jest.fn().mockResolvedValue({ data: [mockProduto], error: null })
            }
          } else {
            return {
              select: jest.fn().mockReturnThis(),
              eq: jest.fn().mockReturnThis(),
              single: jest.fn().mockImplementation(() => productPromise)
            }
          }
        }
      })

      wrapper = createWrapper()
      await flushPromises()

      const select = wrapper.find('select#produto')
      await select.setValue(mockProduto.id.toString())
      
      // Should be loading
      expect(wrapper.vm.loading).toBe(true)
      expect(wrapper.find('.loading').exists()).toBe(true)

      // Resolve the promise
      resolveProductCall({ data: mockProduto, error: null })
      await flushPromises()

      // Should no longer be loading
      expect(wrapper.vm.loading).toBe(false)
      expect(wrapper.find('.loading').exists()).toBe(false)
    })
  })
})