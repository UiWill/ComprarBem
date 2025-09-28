// Usar PDF.js via CDN para melhor compatibilidade
let pdfjsLib = null
let loadingPromise = null

// Carregar PDF.js dinamicamente
const loadPDFJS = async () => {
  // Evitar múltiplos carregamentos simultâneos
  if (loadingPromise) {
    return await loadingPromise
  }

  if (pdfjsLib) {
    return pdfjsLib
  }

  loadingPromise = new Promise(async (resolve, reject) => {
    try {
      console.log('🔄 Iniciando carregamento do PDF.js...')

      if (typeof window === 'undefined') {
        throw new Error('PDF.js só funciona no navegador')
      }

      // Verificar se PDF.js já está carregado
      if (window.pdfjsLib) {
        console.log('✅ PDF.js já estava carregado')
        pdfjsLib = window.pdfjsLib
        resolve(pdfjsLib)
        return
      }

      // Carregar PDF.js via CDN
      console.log('📦 Carregando PDF.js do CDN...')
      const script = document.createElement('script')
      script.src = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js'

      script.onload = () => {
        try {
          console.log('📦 Script PDF.js carregado')

          // Aguardar um pouco para garantir que a biblioteca esteja disponível
          setTimeout(() => {
            if (window.pdfjsLib) {
              pdfjsLib = window.pdfjsLib

              // Configurar worker
              console.log('⚙️ Configurando worker PDF.js...')
              pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js'

              console.log('✅ PDF.js carregado e configurado com sucesso')
              resolve(pdfjsLib)
            } else {
              reject(new Error('PDF.js não está disponível após carregamento'))
            }
          }, 100)
        } catch (error) {
          console.error('❌ Erro ao configurar PDF.js:', error)
          reject(error)
        }
      }

      script.onerror = (error) => {
        console.error('❌ Erro ao carregar script PDF.js:', error)
        reject(new Error('Falha ao carregar PDF.js do CDN'))
      }

      document.head.appendChild(script)

    } catch (error) {
      console.error('❌ Erro no carregamento do PDF.js:', error)
      reject(error)
    }
  })

  return await loadingPromise
}

class PDFRenderService {
  /**
   * Testa se o PDF.js está funcionando corretamente
   * @returns {Promise<boolean>} - True se PDF.js estiver funcionando
   */
  async testPDFJS() {
    try {
      console.log('🧪 Testando PDF.js...')
      const pdfjs = await loadPDFJS()

      if (!pdfjs) {
        throw new Error('PDF.js não foi carregado')
      }

      if (!pdfjs.getDocument) {
        throw new Error('PDF.js não tem o método getDocument')
      }

      console.log('✅ PDF.js está funcionando corretamente')
      console.log('📋 Versão PDF.js:', pdfjs.version || 'desconhecida')
      return true

    } catch (error) {
      console.error('❌ Erro no teste do PDF.js:', error)
      return false
    }
  }

  /**
   * Renderiza uma página específica de um PDF como imagem base64
   * @param {string} pdfUrl - URL do PDF
   * @param {number} pageNumber - Número da página (1-based)
   * @param {number} scale - Escala de renderização (padrão: 1.5)
   * @returns {Promise<string>} - Imagem em base64
   */
  async renderPageAsImage(pdfUrl, pageNumber = 1, scale = 1.5) {
    try {
      console.log('🔄 Carregando PDF:', pdfUrl, 'Página:', pageNumber)

      // Carregar PDF.js primeiro
      const pdfjs = await loadPDFJS()
      console.log('✅ PDF.js carregado com sucesso')

      // Verificar se a URL é válida
      if (!pdfUrl || typeof pdfUrl !== 'string') {
        throw new Error('URL do PDF inválida: ' + pdfUrl)
      }

      // Carregar o documento PDF com timeout
      const loadingTask = pdfjs.getDocument({
        url: pdfUrl,
        verbosity: 0 // Reduzir logs do PDF.js
      })

      // Adicionar timeout de 30 segundos
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Timeout ao carregar PDF')), 30000)
      })

      const pdf = await Promise.race([loadingTask.promise, timeoutPromise])

      console.log('📄 PDF carregado. Total de páginas:', pdf.numPages)

      // Verificar se a página existe
      if (pageNumber > pdf.numPages || pageNumber < 1) {
        throw new Error(`Página ${pageNumber} não existe. PDF tem ${pdf.numPages} páginas.`)
      }

      // Obter a página específica
      const page = await pdf.getPage(pageNumber)

      // Obter viewport da página
      const viewport = page.getViewport({ scale })

      // Criar canvas para renderização
      const canvas = document.createElement('canvas')
      const context = canvas.getContext('2d')

      // Configurar dimensões do canvas
      canvas.width = viewport.width
      canvas.height = viewport.height

      // Configurar fundo branco
      context.fillStyle = 'white'
      context.fillRect(0, 0, canvas.width, canvas.height)

      // Renderizar a página no canvas
      const renderContext = {
        canvasContext: context,
        viewport: viewport,
        background: 'white'
      }

      await page.render(renderContext).promise

      // Converter canvas para base64
      const imageData = canvas.toDataURL('image/png', 1.0)

      console.log('✅ Página renderizada com sucesso:', pageNumber)

      return imageData

    } catch (error) {
      console.error('❌ Erro ao renderizar PDF:', error)
      console.error('URL tentada:', pdfUrl)
      console.error('Página solicitada:', pageNumber)

      // Criar uma mensagem de erro mais específica
      let errorMessage = 'Erro desconhecido ao renderizar PDF'

      if (error.message.includes('Timeout')) {
        errorMessage = 'Timeout ao carregar PDF. Verifique a conexão.'
      } else if (error.message.includes('URL')) {
        errorMessage = 'URL do PDF inválida ou inacessível'
      } else if (error.message.includes('Failed to fetch')) {
        errorMessage = 'Falha ao buscar o PDF. Verifique se o arquivo existe.'
      } else if (error.message.includes('Invalid PDF')) {
        errorMessage = 'Arquivo PDF corrompido ou inválido'
      }

      const enhancedError = new Error(errorMessage)
      enhancedError.originalError = error
      enhancedError.pdfUrl = pdfUrl
      enhancedError.pageNumber = pageNumber

      throw enhancedError
    }
  }

  /**
   * Obter informações do PDF (número de páginas, etc.)
   * @param {string} pdfUrl - URL do PDF
   * @returns {Promise<Object>} - Informações do PDF
   */
  async getPDFInfo(pdfUrl) {
    try {
      const pdfjs = await loadPDFJS()
      const loadingTask = pdfjs.getDocument(pdfUrl)
      const pdf = await loadingTask.promise

      return {
        numPages: pdf.numPages,
        title: await this.getPDFMetadata(pdf, 'Title'),
        author: await this.getPDFMetadata(pdf, 'Author'),
        subject: await this.getPDFMetadata(pdf, 'Subject')
      }
    } catch (error) {
      console.error('❌ Erro ao obter informações do PDF:', error)
      throw error
    }
  }

  /**
   * Obter metadados do PDF
   * @param {Object} pdf - Documento PDF
   * @param {string} key - Chave do metadado
   * @returns {Promise<string>} - Valor do metadado
   */
  async getPDFMetadata(pdf, key) {
    try {
      const metadata = await pdf.getMetadata()
      return metadata.info[key] || ''
    } catch (error) {
      return ''
    }
  }

  /**
   * Renderizar múltiplas páginas de um PDF
   * @param {string} pdfUrl - URL do PDF
   * @param {Array<number>} pageNumbers - Array com números das páginas
   * @param {number} scale - Escala de renderização
   * @returns {Promise<Array<string>>} - Array com imagens em base64
   */
  async renderMultiplePages(pdfUrl, pageNumbers, scale = 1.5) {
    const results = []

    for (const pageNumber of pageNumbers) {
      try {
        const imageData = await this.renderPageAsImage(pdfUrl, pageNumber, scale)
        results.push(imageData)
      } catch (error) {
        console.error(`❌ Erro ao renderizar página ${pageNumber}:`, error)
        results.push(null)
      }
    }

    return results
  }
}

export default new PDFRenderService()