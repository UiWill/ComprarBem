import { supabase, getTenantId } from './supabase'

export class EditaisService {
  
  /**
   * Gera sugestão de próximo número de edital
   * @param {number} ano - Ano desejado (opcional, padrão é ano atual)
   * @returns {Promise<string>} Número sugerido no formato "001/2024"
   */
  static async gerarSugestaoNumero(ano = null) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const anoParam = ano || new Date().getFullYear()

      const { data, error } = await supabase
        .rpc('gerar_sugestao_edital', {
          tenant_uuid: tenantId,
          ano_desejado: anoParam
        })

      if (error) {
        console.error('Erro ao gerar sugestão de edital:', error)
        throw error
      }

      return data || '001/' + anoParam
    } catch (error) {
      console.error('Erro no serviço de editais:', error)
      throw error
    }
  }

  /**
   * Verifica se número de edital já existe
   * @param {string} numeroEdital - Número a verificar
   * @param {number} anoEdital - Ano do edital
   * @param {string} produtoIdExcluir - ID do produto a excluir da verificação (opcional)
   * @returns {Promise<boolean>} True se já existe
   */
  static async verificarEditalExistente(numeroEdital, anoEdital, produtoIdExcluir = null) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .rpc('verificar_edital_existente', {
          tenant_uuid: tenantId,
          numero_edital_param: numeroEdital,
          ano_edital_param: anoEdital,
          produto_id_excluir: produtoIdExcluir
        })

      if (error) {
        console.error('Erro ao verificar edital existente:', error)
        throw error
      }

      return data === true
    } catch (error) {
      console.error('Erro no serviço de editais:', error)
      throw error
    }
  }

  /**
   * Vincula edital a um produto
   * @param {string} produtoId - ID do produto
   * @param {string} numeroEdital - Número do edital
   * @param {number} anoEdital - Ano do edital
   * @returns {Promise<object>} Produto atualizado
   */
  static async vincularEdital(produtoId, numeroEdital, anoEdital) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Verificar se edital já existe
      const jaExiste = await this.verificarEditalExistente(numeroEdital, anoEdital, produtoId)
      if (jaExiste) {
        throw new Error(`Edital ${numeroEdital} já está sendo utilizado por outro produto`)
      }

      const { data, error } = await supabase
        .from('produtos')
        .update({
          numero_edital: numeroEdital,
          ano_edital: anoEdital,
          tem_edital: true
        })
        .eq('id', produtoId)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (error) {
        console.error('Erro ao vincular edital:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de editais:', error)
      throw error
    }
  }

  /**
   * Remove vinculação de edital de um produto
   * @param {string} produtoId - ID do produto
   * @returns {Promise<object>} Produto atualizado
   */
  static async desvincularEdital(produtoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('produtos')
        .update({
          numero_edital: null,
          ano_edital: null,
          tem_edital: false
        })
        .eq('id', produtoId)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (error) {
        console.error('Erro ao desvincular edital:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de editais:', error)
      throw error
    }
  }

  /**
   * Lista produtos com editais
   * @param {object} filtros - Filtros opcionais
   * @returns {Promise<Array>} Lista de produtos
   */
  static async listarProdutosComEditais(filtros = {}) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      let query = supabase
        .from('produtos')
        .select('*')
        .eq('tenant_id', tenantId)
        .eq('tem_edital', true)
        .order('ano_edital', { ascending: false })
        .order('numero_edital', { ascending: false })

      // Aplicar filtros
      if (filtros.ano) {
        query = query.eq('ano_edital', filtros.ano)
      }

      if (filtros.numeroEdital) {
        query = query.eq('numero_edital', filtros.numeroEdital)
      }

      const { data, error } = await query

      if (error) {
        console.error('Erro ao listar produtos com editais:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de editais:', error)
      throw error
    }
  }

  /**
   * Obtém estatísticas de editais
   * @returns {Promise<object>} Estatísticas
   */
  static async obterEstatisticas() {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('produtos')
        .select('numero_edital, ano_edital')
        .eq('tenant_id', tenantId)
        .eq('tem_edital', true)

      if (error) {
        console.error('Erro ao obter estatísticas:', error)
        throw error
      }

      const produtos = data || []
      const totalEditais = produtos.length
      
      // Agrupar por ano
      const porAno = produtos.reduce((acc, produto) => {
        const ano = produto.ano_edital
        acc[ano] = (acc[ano] || 0) + 1
        return acc
      }, {})

      // Edital mais recente
      const maisRecente = produtos.length > 0 ? 
        produtos.sort((a, b) => {
          if (a.ano_edital !== b.ano_edital) {
            return b.ano_edital - a.ano_edital
          }
          return b.numero_edital.localeCompare(a.numero_edital)
        })[0] : null

      return {
        total: totalEditais,
        porAno,
        maisRecente: maisRecente ? `${maisRecente.numero_edital}` : null
      }
    } catch (error) {
      console.error('Erro no serviço de editais:', error)
      throw error
    }
  }

  /**
   * Formata número de edital para exibição
   * @param {string} numeroEdital - Número do edital
   * @param {number} anoEdital - Ano do edital
   * @returns {string} Texto formatado
   */
  static formatarNumeroEdital(numeroEdital, anoEdital) {
    if (!numeroEdital || !anoEdital) {
      return 'Sem edital vinculado'
    }
    return `Edital de Pré-Qualificação de Bens nº ${numeroEdital}`
  }

  /**
   * Valida formato do número de edital
   * @param {string} numeroEdital - Número a validar
   * @returns {boolean} True se válido
   */
  static validarFormatoNumero(numeroEdital) {
    if (!numeroEdital) return false
    
    // Formato esperado: XXX/YYYY ou similar
    const regex = /^\d{1,3}\/\d{4}$/
    return regex.test(numeroEdital)
  }

  /**
   * Extrai partes do número de edital
   * @param {string} numeroEdital - Número completo (ex: "001/2024")
   * @returns {object} {sequencial, ano}
   */
  static extrairPartesNumero(numeroEdital) {
    if (!numeroEdital || !this.validarFormatoNumero(numeroEdital)) {
      return { sequencial: null, ano: null }
    }

    const partes = numeroEdital.split('/')
    return {
      sequencial: parseInt(partes[0], 10),
      ano: parseInt(partes[1], 10)
    }
  }

  /**
   * Formata número com zeros à esquerda
   * @param {number} numero - Número sequencial
   * @param {number} ano - Ano
   * @returns {string} Número formatado
   */
  static formatarNumero(numero, ano) {
    const numeroFormatado = numero.toString().padStart(3, '0')
    return `${numeroFormatado}/${ano}`
  }
}

export default EditaisService