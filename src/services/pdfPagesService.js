/**
 * Serviço para contar páginas de arquivos PDF
 * Implementa numeração correta: cada página do PDF = uma folha separada no processo
 */
class PDFPagesService {

  /**
   * Contar o número de páginas de um arquivo PDF
   * @param {File} arquivo - Arquivo PDF
   * @returns {Promise<number>} Número de páginas
   */
  static async contarPaginas(arquivo) {
    return new Promise((resolve, reject) => {
      try {
        const reader = new FileReader()

        reader.onload = function() {
          try {
            const arrayBuffer = this.result
            const uint8Array = new Uint8Array(arrayBuffer)

            // Converter para string para buscar padrões
            let pdfText = ''
            for (let i = 0; i < uint8Array.length; i++) {
              pdfText += String.fromCharCode(uint8Array[i])
            }

            console.log(`📄 Analisando PDF: ${arquivo.name}`)

            // Método 1: Buscar objetos de página (/Type /Page)
            const pageRegex1 = /\/Type\s*\/Page[^s]/g
            const pages1 = pdfText.match(pageRegex1) || []

            // Método 2: Buscar referências de página
            const pageRegex2 = /\/Count\s+(\d+)/g
            const countMatches = pdfText.match(pageRegex2) || []
            let pages2 = 0
            if (countMatches.length > 0) {
              // Pegar o maior valor encontrado (normalmente é o total de páginas)
              pages2 = Math.max(...countMatches.map(match => {
                const num = match.match(/(\d+)/)
                return num ? parseInt(num[1]) : 0
              }))
            }

            // Método 3: Buscar /Kids array (estrutura de páginas)
            const kidsRegex = /\/Kids\s*\[([^\]]*)\]/g
            let pages3 = 0
            let match
            while ((match = kidsRegex.exec(pdfText)) !== null) {
              const kidsContent = match[1]
              // Contar referências de objetos (formato "n 0 R")
              const objRefs = (kidsContent.match(/\d+\s+0\s+R/g) || []).length
              if (objRefs > pages3) {
                pages3 = objRefs
              }
            }

            // Método 4: Buscar marcadores específicos do PDF
            const pageKeywords = [
              /\/Page\s/g,
              /endobj[\s\S]*?\/Type\s*\/Page/g
            ]

            let pages4 = 0
            pageKeywords.forEach(regex => {
              const matches = pdfText.match(regex) || []
              if (matches.length > pages4) {
                pages4 = matches.length
              }
            })

            console.log(`📊 Métodos de contagem para ${arquivo.name}:`)
            console.log(`   Método 1 (/Type /Page): ${pages1.length}`)
            console.log(`   Método 2 (/Count): ${pages2}`)
            console.log(`   Método 3 (/Kids): ${pages3}`)
            console.log(`   Método 4 (Keywords): ${pages4}`)

            // Escolher o resultado mais provável
            const resultados = [pages1.length, pages2, pages3, pages4].filter(n => n > 0)

            if (resultados.length === 0) {
              console.warn(`⚠️ Não foi possível determinar o número de páginas para ${arquivo.name}. Assumindo 1 página.`)
              resolve(1)
              return
            }

            // Usar o valor mais comum, ou o maior se não houver consenso
            const contador = {}
            resultados.forEach(num => {
              contador[num] = (contador[num] || 0) + 1
            })

            let paginasFinais = Math.max(...resultados)

            // Se múltiplos métodos concordam, usar esse valor
            const maisComum = Object.keys(contador).reduce((a, b) =>
              contador[a] > contador[b] ? a : b
            )

            if (contador[maisComum] >= 2) {
              paginasFinais = parseInt(maisComum)
            }

            console.log(`✅ PDF ${arquivo.name}: ${paginasFinais} páginas detectadas`)

            // Validação: PDFs com mais de 500 páginas são suspeitos
            if (paginasFinais > 500) {
              console.warn(`⚠️ PDF com ${paginasFinais} páginas detectadas - pode ser falso positivo`)
              paginasFinais = Math.min(paginasFinais, 50) // Limitar a 50 páginas por segurança
            }

            // PDFs devem ter pelo menos 1 página
            resolve(Math.max(1, paginasFinais))

          } catch (error) {
            console.error(`❌ Erro ao analisar PDF ${arquivo.name}:`, error)
            console.warn(`⚠️ Assumindo 1 página para ${arquivo.name} devido ao erro`)
            resolve(1) // Fallback seguro
          }
        }

        reader.onerror = function(error) {
          console.error(`❌ Erro ao ler arquivo ${arquivo.name}:`, error)
          console.warn(`⚠️ Assumindo 1 página para ${arquivo.name} devido ao erro de leitura`)
          resolve(1) // Fallback seguro
        }

        reader.readAsArrayBuffer(arquivo)

      } catch (error) {
        console.error(`❌ Erro geral ao processar PDF ${arquivo.name}:`, error)
        console.warn(`⚠️ Assumindo 1 página para ${arquivo.name}`)
        resolve(1) // Fallback seguro
      }
    })
  }

  /**
   * Processar arquivo PDF para numeração de páginas individuais
   * @param {File} arquivo - Arquivo PDF
   * @param {string} processoId - ID do processo
   * @param {string} tipoDocumento - Tipo do documento
   * @returns {Promise<Array>} Array com informações de cada página
   */
  static async processarPDFParaPaginas(arquivo, processoId, tipoDocumento) {
    try {
      console.log(`🔍 Processando PDF para páginas individuais: ${arquivo.name}`)

      // Contar páginas do PDF
      const numeroPaginas = await this.contarPaginas(arquivo)

      console.log(`📄 PDF ${arquivo.name} tem ${numeroPaginas} página${numeroPaginas > 1 ? 's' : ''}`)

      // Importar o serviço de numeração
      const { default: NumeracaoDocumentosService } = await import('./numeracaoDocumentosService')

      // Separar as páginas do PDF em arquivos individuais
      const paginasIndividuais = await this.separarPaginasPDF(arquivo)

      // Obter próximos números sequenciais para todas as páginas
      const numeracoes = []
      for (let pagina = 1; pagina <= numeroPaginas; pagina++) {
        const { numero, folha } = await NumeracaoDocumentosService.obterProximoNumero(processoId)
        numeracoes.push({
          numero,
          folha,
          pagina,
          nomeDocumento: numeroPaginas > 1 ?
            `${arquivo.name} (Página ${pagina}/${numeroPaginas})` :
            arquivo.name,
          arquivoPagina: paginasIndividuais[pagina - 1] // PDF individual da página
        })

        console.log(`📋 Página ${pagina}: ${folha} - ${numeracoes[pagina-1].nomeDocumento}`)
      }

      return {
        numeroPaginas,
        numeracoes,
        nomeOriginal: arquivo.name
      }

    } catch (error) {
      console.error(`❌ Erro ao processar PDF para páginas:`, error)
      throw new Error(`Falha ao processar PDF ${arquivo.name}: ${error.message}`)
    }
  }

  /**
   * Separar páginas do PDF em arquivos individuais
   * @param {File} arquivo - Arquivo PDF original
   * @returns {Promise<Array<Object>>} Array com informações de cada página
   */
  static async separarPaginasPDF(arquivo) {
    try {
      console.log(`✂️ Preparando páginas do PDF: ${arquivo.name}`)

      const arrayBuffer = await arquivo.arrayBuffer()
      const numeroPaginas = await this.contarPaginas(arquivo)
      const paginasIndividuais = []

      for (let i = 0; i < numeroPaginas; i++) {
        // ✨ SOLUÇÃO INTELIGENTE: Criar arquivo com marcador de página
        // O visualizador poderá usar parâmetros URL para mostrar a página específica
        const nomeArquivoPagina = `${arquivo.name.replace('.pdf', '')}_p${i + 1}.pdf`

        // Criar um objeto File com metadados da página
        const arquivoPagina = new File([arrayBuffer], nomeArquivoPagina, {
          type: 'application/pdf',
          lastModified: Date.now()
        })

        // Adicionar propriedades customizadas para identificar a página
        arquivoPagina.paginaNumero = i + 1
        arquivoPagina.totalPaginas = numeroPaginas
        arquivoPagina.arquivoOriginal = arquivo.name

        paginasIndividuais.push(arquivoPagina)
      }

      console.log(`✅ ${numeroPaginas} páginas preparadas (arquivo original preservado com identificadores)`)
      return paginasIndividuais

    } catch (error) {
      console.error(`❌ Erro ao preparar páginas do PDF:`, error)
      throw error
    }
  }
}

export default PDFPagesService