import { supabase, getTenantId } from './supabase'

export class DocumentosAdministrativosService {
  static async listarDocumentos(filtros = {}) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      let query = supabase
        .from('documentos_administrativos')
        .select(`
          id,
          titulo,
          descricao,
          categoria,
          nome_arquivo,
          tamanho_arquivo,
          tipo_mime,
          url_arquivo,
          visibilidade,
          status,
          tags,
          criado_em,
          atualizado_em,
          usuario_id
        `)
        .or(`tenant_id.eq.${tenantId},tenant_id.is.null`)
        .eq('status', 'ativo')
        .order('criado_em', { ascending: false })

      // Aplicar filtros
      if (filtros.categoria) {
        query = query.eq('categoria', filtros.categoria)
      }

      if (filtros.busca) {
        query = query.or(`titulo.ilike.%${filtros.busca}%,descricao.ilike.%${filtros.busca}%`)
      }

      if (filtros.tags && filtros.tags.length > 0) {
        query = query.overlaps('tags', filtros.tags)
      }

      const { data, error } = await query

      if (error) {
        console.error('Erro ao listar documentos:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de documentos:', error)
      throw error
    }
  }

  static async obterDocumento(id) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('documentos_administrativos')
        .select('*')
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .single()

      if (error) {
        console.error('Erro ao obter documento:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de documentos:', error)
      throw error
    }
  }

  static async criarDocumento(documentoData) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const documento = {
        ...documentoData,
        tenant_id: tenantId,
        usuario_id: user.id,
        status: 'ativo'
      }

      const { data, error } = await supabase
        .from('documentos_administrativos')
        .insert(documento)
        .select()
        .single()

      if (error) {
        console.error('Erro ao criar documento:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de documentos:', error)
      throw error
    }
  }

  static async atualizarDocumento(id, updates) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('documentos_administrativos')
        .update(updates)
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (error) {
        console.error('Erro ao atualizar documento:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de documentos:', error)
      throw error
    }
  }

  static async excluirDocumento(id) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Soft delete - apenas marca como inativo
      const { data, error } = await supabase
        .from('documentos_administrativos')
        .update({ status: 'arquivado' })
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (error) {
        console.error('Erro ao excluir documento:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de documentos:', error)
      throw error
    }
  }

  static async uploadArquivo(arquivo, pasta = 'documentos') {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Gerar nome único para o arquivo
      const timestamp = Date.now()
      const nomeArquivo = `${timestamp}_${arquivo.name}`
      const caminhoArquivo = `${tenantId}/${pasta}/${nomeArquivo}`

      const { data, error } = await supabase.storage
        .from('documentos-administrativos')
        .upload(caminhoArquivo, arquivo, {
          cacheControl: '3600',
          upsert: false
        })

      if (error) {
        console.error('Erro no upload:', error)
        throw error
      }

      // Obter URL pública do arquivo
      const { data: urlData } = supabase.storage
        .from('documentos-administrativos')
        .getPublicUrl(caminhoArquivo)

      return {
        path: data.path,
        url: urlData.publicUrl,
        nome_original: arquivo.name,
        tamanho: arquivo.size,
        tipo_mime: arquivo.type
      }
    } catch (error) {
      console.error('Erro no upload de arquivo:', error)
      throw error
    }
  }

  static async baixarArquivo(url) {
    try {
      if (!url) {
        throw new Error('URL do arquivo não fornecida')
      }

      // Se for URL do Supabase Storage, usar método específico
      if (url.includes('supabase')) {
        const response = await fetch(url)
        if (!response.ok) {
          throw new Error('Erro ao baixar arquivo')
        }
        return response.blob()
      }

      // Para outras URLs, usar fetch direto
      const response = await fetch(url)
      if (!response.ok) {
        throw new Error('Erro ao baixar arquivo')
      }
      return response.blob()
    } catch (error) {
      console.error('Erro ao baixar arquivo:', error)
      throw error
    }
  }

  static async buscarDocumentos(termo, filtros = {}) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      let query = supabase
        .from('documentos_administrativos')
        .select('*')
        .or(`tenant_id.eq.${tenantId},tenant_id.is.null`)
        .eq('status', 'ativo')

      // Busca por termo nos campos título e descrição
      if (termo) {
        query = query.or(`titulo.ilike.%${termo}%,descricao.ilike.%${termo}%`)
      }

      // Aplicar filtros adicionais
      if (filtros.categoria) {
        query = query.eq('categoria', filtros.categoria)
      }

      if (filtros.visibilidade) {
        query = query.eq('visibilidade', filtros.visibilidade)
      }

      if (filtros.dataInicio) {
        query = query.gte('criado_em', filtros.dataInicio)
      }

      if (filtros.dataFim) {
        query = query.lte('criado_em', filtros.dataFim)
      }

      query = query.order('criado_em', { ascending: false })

      const { data, error } = await query

      if (error) {
        console.error('Erro na busca:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de busca:', error)
      throw error
    }
  }

  static async obterEstatisticas() {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Total de documentos por categoria
      const { data: totalPorCategoria, error: errorCategoria } = await supabase
        .from('documentos_administrativos')
        .select('categoria')
        .or(`tenant_id.eq.${tenantId},tenant_id.is.null`)
        .eq('status', 'ativo')

      if (errorCategoria) {
        throw errorCategoria
      }

      // Total geral
      const total = totalPorCategoria.length

      // Contar por categoria
      const estatisticasCategorias = totalPorCategoria.reduce((acc, doc) => {
        acc[doc.categoria] = (acc[doc.categoria] || 0) + 1
        return acc
      }, {})

      // Documentos recentes (últimos 7 dias)
      const seteDiasAtras = new Date()
      seteDiasAtras.setDate(seteDiasAtras.getDate() - 7)

      const { data: recentes, error: errorRecentes } = await supabase
        .from('documentos_administrativos')
        .select('id')
        .or(`tenant_id.eq.${tenantId},tenant_id.is.null`)
        .eq('status', 'ativo')
        .gte('criado_em', seteDiasAtras.toISOString())

      if (errorRecentes) {
        throw errorRecentes
      }

      return {
        total,
        categorias: estatisticasCategorias,
        recentes: recentes.length
      }
    } catch (error) {
      console.error('Erro ao obter estatísticas:', error)
      throw error
    }
  }

  // Utilitários
  static formatarTamanhoArquivo(bytes) {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  static obterIconeCategoria(categoria) {
    const icones = {
      manual: '📖',
      template: '📄',
      instrucao: '📋',
      normativa: '⚖️',
      formulario: '📝'
    }
    return icones[categoria] || '📄'
  }

  static obterNomeCategoria(categoria) {
    const nomes = {
      manual: 'Manual',
      template: 'Template',
      instrucao: 'Instrução',
      normativa: 'Normativa',
      formulario: 'Formulário'
    }
    return nomes[categoria] || categoria
  }

  static validarArquivo(arquivo) {
    const tiposPermitidos = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain'
    ]

    const tamanhoMaximo = 10 * 1024 * 1024 // 10MB

    if (!tiposPermitidos.includes(arquivo.type)) {
      throw new Error('Tipo de arquivo não permitido. Use PDF, DOC, DOCX, XLS, XLSX ou TXT.')
    }

    if (arquivo.size > tamanhoMaximo) {
      throw new Error('Arquivo muito grande. Tamanho máximo: 10MB.')
    }

    return true
  }
}

export default DocumentosAdministrativosService