import { supabase } from './supabase'

/**
 * Serviço para gerenciar numeração sequencial automática de documentos em processos administrativos
 * Garante que cada documento tenha uma numeração única e sequencial (Fl. 001, 002, 003, etc.)
 */
class NumeracaoDocumentosService {
  
  /**
   * Obter próximo número sequencial para um processo
   * @param {string} processoId - ID do processo administrativo
   * @returns {Promise<{numero: number, folha: string}>} Próximo número e formatação
   */
  async obterProximoNumero(processoId) {
    try {
      // Buscar documentos existentes do processo ordenados por numero_sequencial
      const { data: documentos, error } = await supabase
        .from('documentos_processo')
        .select('numero_sequencial')
        .eq('processo_id', processoId)
        .order('numero_sequencial', { ascending: false })
        .limit(1)

      if (error) throw error

      // Se não há documentos, começar do 1 (Folha de Rosto já é Fl. 001)
      let proximoNumero = 1
      
      if (documentos && documentos.length > 0) {
        proximoNumero = documentos[0].numero_sequencial + 1
      }

      return {
        numero: proximoNumero,
        folha: this.formatarNumeroFolha(proximoNumero)
      }
    } catch (error) {
      console.error('Erro ao obter próximo número sequencial:', error)
      throw new Error('Erro ao gerar numeração sequencial: ' + error.message)
    }
  }

  /**
   * Registrar novo documento com numeração sequencial
   * @param {Object} dadosDocumento - Dados do documento
   * @param {string} dadosDocumento.processo_id - ID do processo
   * @param {string} dadosDocumento.tipo_documento - Tipo do documento (DFD, EDITAL, ATA, etc.)
   * @param {string} dadosDocumento.nome_documento - Nome do documento
   * @param {string} dadosDocumento.conteudo - Conteúdo do documento (JSON ou HTML)
   * @param {string} dadosDocumento.arquivo_url - URL do arquivo (se houver)
   * @param {string} dadosDocumento.tenant_id - ID do tenant
   * @returns {Promise<Object>} Documento criado com numeração
   */
  async registrarDocumento(dadosDocumento) {
    try {
      // Obter próximo número sequencial
      const { numero, folha } = await this.obterProximoNumero(dadosDocumento.processo_id)

      // Criar objeto documento com numeração
      const documentoCompleto = {
        ...dadosDocumento,
        numero_sequencial: numero,
        folha_numero: folha,
        data_criacao: new Date().toISOString(),
        status: 'ativo'
      }

      console.log('🔍 DEBUG registrarDocumento - dados completos para inserção:', documentoCompleto)

      // Inserir documento na tabela
      const { data: documentoCriado, error } = await supabase
        .from('documentos_processo')
        .insert(documentoCompleto)
        .select()
        .single()

      console.log('🔍 DEBUG registrarDocumento - resultado da inserção:', { documentoCriado, error })

      if (error) {
        console.error('❌ DEBUG registrarDocumento - erro detalhado:', {
          message: error.message,
          details: error.details,
          hint: error.hint,
          code: error.code
        })
        throw error
      }

      console.log(`Documento criado: ${folha} - ${dadosDocumento.nome_documento}`)
      
      return documentoCriado
    } catch (error) {
      console.error('Erro ao registrar documento:', error)
      throw new Error('Erro ao registrar documento: ' + error.message)
    }
  }

  /**
   * Listar todos os documentos de um processo em ordem sequencial
   * @param {string} processoId - ID do processo
   * @returns {Promise<Array>} Lista de documentos ordenados
   */
  async listarDocumentosProcesso(processoId) {
    try {
      const { data: documentos, error } = await supabase
        .from('documentos_processo')
        .select('*')
        .eq('processo_id', processoId)
        .eq('status', 'ativo')
        .order('numero_sequencial', { ascending: true })

      if (error) throw error

      return documentos || []
    } catch (error) {
      console.error('Erro ao listar documentos do processo:', error)
      throw new Error('Erro ao listar documentos: ' + error.message)
    }
  }

  /**
   * Atualizar documento existente (mantém numeração)
   * @param {string} documentoId - ID do documento
   * @param {Object} dadosAtualizacao - Dados para atualizar
   * @returns {Promise<Object>} Documento atualizado
   */
  async atualizarDocumento(documentoId, dadosAtualizacao) {
    try {
      const { data: documentoAtualizado, error } = await supabase
        .from('documentos_processo')
        .update({
          ...dadosAtualizacao,
          data_atualizacao: new Date().toISOString()
        })
        .eq('id', documentoId)
        .select()
        .single()

      if (error) throw error

      return documentoAtualizado
    } catch (error) {
      console.error('Erro ao atualizar documento:', error)
      throw new Error('Erro ao atualizar documento: ' + error.message)
    }
  }

  /**
   * Remover documento (marca como inativo)
   * @param {string} documentoId - ID do documento
   * @returns {Promise<void>}
   */
  async removerDocumento(documentoId) {
    try {
      const { error } = await supabase
        .from('documentos_processo')
        .update({ 
          status: 'inativo',
          data_remocao: new Date().toISOString()
        })
        .eq('id', documentoId)

      if (error) throw error

      console.log('Documento removido com sucesso')
    } catch (error) {
      console.error('Erro ao remover documento:', error)
      throw new Error('Erro ao remover documento: ' + error.message)
    }
  }

  /**
   * Reordenar documentos (para casos excepcionais)
   * @param {string} processoId - ID do processo
   * @returns {Promise<void>}
   */
  async reordenarDocumentos(processoId) {
    try {
      // Buscar todos os documentos ativos
      const documentos = await this.listarDocumentosProcesso(processoId)

      // Reordenar e atualizar numeração
      for (let i = 0; i < documentos.length; i++) {
        const novoNumero = i + 1
        const novaFolha = this.formatarNumeroFolha(novoNumero)

        await supabase
          .from('documentos_processo')
          .update({
            numero_sequencial: novoNumero,
            folha_numero: novaFolha
          })
          .eq('id', documentos[i].id)
      }

      console.log('Documentos reordenados com sucesso')
    } catch (error) {
      console.error('Erro ao reordenar documentos:', error)
      throw new Error('Erro ao reordenar documentos: ' + error.message)
    }
  }

  /**
   * Gerar relatório de documentos do processo
   * @param {string} processoId - ID do processo
   * @returns {Promise<Object>} Relatório com estatísticas
   */
  async gerarRelatorioDocumentos(processoId) {
    try {
      const documentos = await this.listarDocumentosProcesso(processoId)

      const relatorio = {
        total_documentos: documentos.length,
        ultimo_numero: documentos.length > 0 ? Math.max(...documentos.map(d => d.numero_sequencial)) : 0,
        proxima_folha: this.formatarNumeroFolha((documentos.length > 0 ? Math.max(...documentos.map(d => d.numero_sequencial)) : 0) + 1),
        tipos_documento: {},
        documentos_por_data: {},
        sequencia_completa: true
      }

      // Analisar tipos de documento
      documentos.forEach(doc => {
        relatorio.tipos_documento[doc.tipo_documento] = 
          (relatorio.tipos_documento[doc.tipo_documento] || 0) + 1
      })

      // Verificar se sequência está completa (sem lacunas)
      for (let i = 1; i <= relatorio.ultimo_numero; i++) {
        const temDocumento = documentos.some(d => d.numero_sequencial === i)
        if (!temDocumento) {
          relatorio.sequencia_completa = false
          relatorio.lacunas = relatorio.lacunas || []
          relatorio.lacunas.push(i)
        }
      }

      return relatorio
    } catch (error) {
      console.error('Erro ao gerar relatório:', error)
      throw new Error('Erro ao gerar relatório: ' + error.message)
    }
  }

  /**
   * Formatar número da folha (001, 002, 003, etc.)
   * @param {number} numero - Número sequencial
   * @returns {string} Número formatado
   */
  formatarNumeroFolha(numero) {
    return `Fl. ${numero.toString().padStart(3, '0')}`
  }

  /**
   * Extrair número sequencial de uma string de folha
   * @param {string} folha - String da folha (ex: "Fl. 001")
   * @returns {number} Número sequencial
   */
  extrairNumeroSequencial(folha) {
    const match = folha.match(/Fl\.\s*(\d+)/)
    return match ? parseInt(match[1], 10) : 0
  }

  /**
   * Validar numeração sequencial
   * @param {string} processoId - ID do processo
   * @returns {Promise<{valida: boolean, problemas: Array}>}
   */
  async validarNumeracao(processoId) {
    try {
      const documentos = await this.listarDocumentosProcesso(processoId)
      const problemas = []

      // Verificar duplicatas
      const numeros = documentos.map(d => d.numero_sequencial)
      const numerosUnicos = [...new Set(numeros)]
      
      if (numeros.length !== numerosUnicos.length) {
        problemas.push('Existem números duplicados na sequência')
      }

      // Verificar lacunas
      const numeroMaximo = Math.max(...numeros)
      for (let i = 1; i <= numeroMaximo; i++) {
        if (!numeros.includes(i)) {
          problemas.push(`Lacuna na sequência: Fl. ${i.toString().padStart(3, '0')} não encontrada`)
        }
      }

      // Verificar ordem cronológica
      for (let i = 1; i < documentos.length; i++) {
        const docAnterior = documentos[i - 1]
        const docAtual = documentos[i]
        
        if (new Date(docAnterior.data_criacao) > new Date(docAtual.data_criacao)) {
          problemas.push(`Ordem cronológica incorreta entre ${docAnterior.folha_numero} e ${docAtual.folha_numero}`)
        }
      }

      return {
        valida: problemas.length === 0,
        problemas
      }
    } catch (error) {
      console.error('Erro ao validar numeração:', error)
      return {
        valida: false,
        problemas: ['Erro ao validar numeração: ' + error.message]
      }
    }
  }
}

export default new NumeracaoDocumentosService()