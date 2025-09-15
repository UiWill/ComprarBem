import { supabase, getTenantId } from './supabase'
import EmailNotificationService from './emailNotificationService'
import NumeracaoDocumentosService from './numeracaoDocumentosService'

export class ProcessosAdministrativosService {
  
  // =====================================================
  // GESTÃO DE PROCESSOS
  // =====================================================

  static async listarProcessos(filtros = {}) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      let query = supabase
        .from('vw_processos_resumo')
        .select('*')
        .eq('tenant_id', tenantId)
        .order('data_autuacao', { ascending: false })

      // Aplicar filtros
      if (filtros.tipo_processo) {
        query = query.eq('tipo_processo', filtros.tipo_processo)
      }

      if (filtros.status) {
        query = query.eq('status', filtros.status)
      }

      if (filtros.busca) {
        query = query.or(`numero_processo.ilike.%${filtros.busca}%,objeto.ilike.%${filtros.busca}%`)
      }

      const { data, error } = await query

      if (error) {
        console.error('Erro ao listar processos:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de processos:', error)
      throw error
    }
  }

  static async obterProcesso(id) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('processos_administrativos')
        .select(`
          *,
          documentos:documentos_processo(*),
          produtos:produtos_prequalificacao(*),
          recursos:recursos_processo(*),
          dfd:dfd_processo(*),
          tramitacao:tramitacao_processo(*)
        `)
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .single()

      if (error) {
        console.error('Erro ao obter processo:', error)
        throw error
      }

      // Calcular totais
      if (data) {
        data.total_documentos = data.documentos?.length || 0
        data.total_produtos = data.produtos?.length || 0
        
        console.log(`Processo ${id} carregado:`, {
          total_documentos: data.total_documentos,
          total_produtos: data.total_produtos,
          documentos: data.documentos?.map(d => ({ id: d.id, titulo: d.titulo || d.nome_documento, numero_folha: d.numero_folha })),
          produtos: data.produtos?.map(p => ({ id: p.id, nome: p.nome }))
        })
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de processos:', error)
      throw error
    }
  }

  static async criarProcesso(dadosProcesso) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Gerar objeto padronizado baseado no tipo
      let objeto
      if (dadosProcesso.tipo_processo === 'padronizacao') {
        objeto = `CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS.`
      } else {
        objeto = `DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS.`
      }

      const processo = {
        ...dadosProcesso,
        objeto,
        tenant_id: tenantId,
        criado_por: user.id,
        atualizado_por: user.id,
        status: dadosProcesso.status || 'em_criacao'
      }

      const { data, error } = await supabase
        .from('processos_administrativos')
        .insert(processo)
        .select()
        .single()

      if (error) {
        console.error('Erro ao criar processo:', error)
        throw error
      }

      // Criar folha de rosto automaticamente
      await this.criarFolhaRosto(data.id, {
        numeroProcesso: data.numero_processo,
        tipoProcesso: data.tipo_processo,
        dadosOrgao: {
          nome: dadosProcesso.nome_orgao || 'PREFEITURA MUNICIPAL',
          departamento: 'DEPARTAMENTO DE COMPRAS E LICITAÇÕES'
        }
      })

      return data
    } catch (error) {
      console.error('Erro no serviço de processos:', error)
      throw error
    }
  }

  static async atualizarProcesso(id, dadosAtualizacao) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Primeiro verificar se o processo existe
      const { data: processoExistente, error: errorVerificacao } = await supabase
        .from('processos_administrativos')
        .select('id, tenant_id, status')
        .eq('id', id)
        
      console.log('🔍 Debug - Verificando processo existente:', {
        id,
        tenantId,
        processoExistente,
        errorVerificacao
      })
      
      if (errorVerificacao) {
        throw new Error(`Erro ao verificar processo: ${errorVerificacao.message}`)
      }
      
      if (!processoExistente || processoExistente.length === 0) {
        throw new Error(`Processo com ID ${id} não encontrado`)
      }
      
      if (processoExistente.length > 1) {
        throw new Error(`Múltiplos processos encontrados com ID ${id}`)
      }
      
      const processo = processoExistente[0]
      
      if (processo.tenant_id !== tenantId) {
        throw new Error(`Processo não pertence ao tenant atual. Esperado: ${tenantId}, Encontrado: ${processo.tenant_id}`)
      }
      
      // Agora fazer o update
      const { data, error } = await supabase
        .from('processos_administrativos')
        .update({
          ...dadosAtualizacao,
          atualizado_por: user.id,
          atualizado_em: new Date().toISOString()
        })
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (error) {
        console.error('Erro ao atualizar processo:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de processos:', error)
      throw error
    }
  }

  // =====================================================
  // GESTÃO DE EDITAIS NO PROCESSO
  // =====================================================

  static async vincularEditalProcesso(processoId, dadosEdital) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Upload do arquivo PDF do edital ou usar URL existente
      let editalUrl = dadosEdital.arquivo_url || null // Usar URL existente se fornecida
      
      if (dadosEdital.arquivo && !editalUrl) {
        const arquivo = dadosEdital.arquivo
        const nomeArquivo = `edital_${processoId}_${Date.now()}.pdf`
        
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('processos-documentos')
          .upload(nomeArquivo, arquivo, {
            cacheControl: '3600',
            upsert: false
          })

        if (uploadError) {
          throw new Error(`Erro ao fazer upload do edital: ${uploadError.message}`)
        }

        // Obter URL pública do arquivo
        const { data: urlData } = supabase.storage
          .from('processos-documentos')
          .getPublicUrl(uploadData.path)
        
        editalUrl = urlData.publicUrl
      }

      // Atualizar processo com dados do edital
      const { data, error } = await supabase
        .from('processos_administrativos')
        .update({
          numero_edital: dadosEdital.numero_edital,
          ano_edital: dadosEdital.ano_edital,
          edital_id: dadosEdital.edital_id, // ID do edital vinculado
          edital_pdf_url: editalUrl,
          edital_vinculado: true,
          data_vinculacao_edital: new Date().toISOString(),
          atualizado_por: user.id,
          atualizado_em: new Date().toISOString()
        })
        .eq('id', processoId)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (error) {
        console.error('Erro ao vincular edital:', error)
        throw error
      }

      // Criar documento do edital no processo
      const numeroFolha = await this.obterProximoNumeroFolha(processoId)
      
      const documentoEdital = {
        processo_id: processoId,
        tipo_documento: 'EDITAL',
        nome_documento: `Edital de Pré-Qualificação nº ${dadosEdital.numero_edital}`,
        titulo: `Edital de Pré-Qualificação nº ${dadosEdital.numero_edital}`,
        descricao: dadosEdital.descricao || 'Edital de Chamamento Público anexado ao processo',
        conteudo_html: this.gerarHTMLEdital(dadosEdital),
        numero_sequencial: numeroFolha,
        numero_folha: numeroFolha,
        arquivo_url: editalUrl
      }

      await this.criarDocumento(documentoEdital)

      return data
    } catch (error) {
      console.error('Erro ao vincular edital ao processo:', error)
      throw error
    }
  }

  static async obterDocumentacaoProdutos(processoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Buscar produtos do processo com sua documentação completa
      const { data: produtos, error } = await supabase
        .from('produtos_prequalificacao')
        .select(`
          *,
          produto_info:produtos!inner (
            nome,
            marca,
            modelo,
            fabricante,
            registro_anvisa,
            registro_inmetro,
            cbpf,
            norma_abnt,
            norma_regulamentadora,
            origem,
            codigo_material,
            descricao
          ),
          documentos_produto:arquivos_produto (
            id,
            nome_arquivo,
            tipo_arquivo,
            tamanho,
            url_arquivo,
            data_upload
          )
        `)
        .eq('processo_id', processoId)
        .eq('tenant_id', tenantId)

      if (error) {
        console.error('Erro ao obter documentação dos produtos:', error)
        throw error
      }

      // Estruturar dados da documentação
      const documentacaoCompleta = produtos.map(produto => ({
        produto_id: produto.produto_id,
        nome_produto: produto.produto_info.nome,
        marca: produto.produto_info.marca,
        modelo: produto.produto_info.modelo,
        fabricante: produto.produto_info.fabricante,
        
        // Documentação técnica obrigatória
        documentacao_tecnica: {
          numero_anvisa: produto.produto_info.registro_anvisa,
          certificado_inmetro: produto.produto_info.registro_inmetro,
          cbpf: produto.produto_info.cbpf,
          norma_abnt: produto.produto_info.norma_abnt,
          norma_regulamentadora: produto.produto_info.norma_regulamentadora,
          origem: produto.produto_info.origem,
          codigo_material: produto.produto_info.codigo_material,
          especificacao_detalhada: produto.produto_info.descricao
        },

        // Arquivos anexados ao produto
        documentos_anexados: produto.documentos_produto || [],

        // Checklist de documentação baseado no tipo de produto
        checklist_documentacao: this.gerarChecklistDocumentacao(produto.produto_info)
      }))

      return documentacaoCompleta
    } catch (error) {
      console.error('Erro ao obter documentação dos produtos:', error)
      throw error
    }
  }

  static gerarChecklistDocumentacao(produto) {
    const checklist = []
    
    // Documentação básica (sempre necessária)
    checklist.push({
      documento: 'Especificação técnica completa',
      obrigatório: true,
      presente: !!produto.descricao,
      valor: produto.descricao
    })

    // Documentação específica baseada no produto
    if (produto.registro_anvisa) {
      checklist.push({
        documento: 'Certificado de Registro ANVISA/MS',
        obrigatório: true,
        presente: true,
        valor: produto.registro_anvisa
      })
    }

    if (produto.registro_inmetro) {
      checklist.push({
        documento: 'Certificação/Registro INMETRO',
        obrigatório: true,
        presente: true,
        valor: produto.registro_inmetro
      })
    }

    if (produto.cbpf) {
      checklist.push({
        documento: 'Certificado de Boas Práticas de Fabricação',
        obrigatório: true,
        presente: true,
        valor: produto.cbpf
      })
    }

    if (produto.norma_abnt) {
      checklist.push({
        documento: 'Norma ABNT aplicável',
        obrigatório: true,
        presente: true,
        valor: produto.norma_abnt
      })
    }

    if (produto.norma_regulamentadora) {
      checklist.push({
        documento: 'Norma Regulamentadora',
        obrigatório: true,
        presente: true,
        valor: produto.norma_regulamentadora
      })
    }

    // Documentação adicional recomendada
    checklist.push({
      documento: 'Manual técnico em português',
      obrigatório: false,
      presente: false,
      observacao: 'Verificar se foi anexado nos documentos do produto'
    })

    checklist.push({
      documento: 'Instruções de uso',
      obrigatório: false,
      presente: false,
      observacao: 'Conforme RDC 751/2022 quando aplicável'
    })

    return checklist
  }

  static gerarHTMLEdital(dadosEdital) {
    const dataVinculacao = new Date().toLocaleDateString('pt-BR')
    
    return `
      <div class="documento-edital">
        <h1>EDITAL DE PRÉ-QUALIFICAÇÃO DE BENS</h1>
        <h2>Nº ${dadosEdital.numero_edital}</h2>
        
        <div class="secao">
          <h3>IDENTIFICAÇÃO</h3>
          <p><strong>Número do Edital:</strong> ${dadosEdital.numero_edital}</p>
          <p><strong>Data de Vinculação ao Processo:</strong> ${dataVinculacao}</p>
          ${dadosEdital.data_publicacao ? `<p><strong>Data de Publicação:</strong> ${new Date(dadosEdital.data_publicacao).toLocaleDateString('pt-BR')}</p>` : ''}
        </div>

        ${dadosEdital.objeto ? `
        <div class="secao">
          <h3>OBJETO</h3>
          <p>${dadosEdital.objeto}</p>
        </div>
        ` : ''}

        <div class="secao">
          <h3>DOCUMENTO ANEXADO</h3>
          <p>O edital completo com todos os anexos obrigatórios está disponível em formato PDF.</p>
          ${dadosEdital.arquivo_url ? `<p><strong>Link do Arquivo:</strong> <a href="${dadosEdital.arquivo_url}" target="_blank" style="color: #1976d2; text-decoration: underline;">${dadosEdital.arquivo_url}</a></p>` : ''}
          ${dadosEdital.observacoes ? `<p><strong>Observações:</strong> ${dadosEdital.observacoes}</p>` : ''}
        </div>

        <div class="assinatura">
          <p>Data: ${dataVinculacao}</p>
          <br>
          <p>_________________________________________</p>
          <p>Responsável pela vinculação do edital</p>
        </div>
      </div>
    `
  }

  // =====================================================
  // GESTÃO DE DOCUMENTOS
  // =====================================================

  static async listarDocumentosProcesso(processoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Buscar TODOS os documentos - incluindo os adicionados com 📎 "Adicionar Documento"
      const { data: documentos, error } = await supabase
        .from('documentos_processo')
        .select('*')
        .eq('processo_id', processoId)
        .eq('tenant_id', tenantId)
        .order('numero_folha', { ascending: true })

      if (error) {
        console.error('Erro ao listar documentos:', error)
        throw error
      }

      console.log(`📋 Encontrados ${documentos?.length || 0} documentos para o processo ${processoId}`)
      
      // Buscar também documentos complementares se houver tabela específica
      try {
        const { data: documentosComplementares, error: errorComplementares } = await supabase
          .from('documentos_complementares_processo')
          .select('*')
          .eq('processo_id', processoId)
          .eq('tenant_id', tenantId)
        
        if (!errorComplementares && documentosComplementares?.length > 0) {
          console.log(`📎 Encontrados ${documentosComplementares.length} documentos complementares`)
          
          // Adicionar documentos complementares à lista principal
          const documentosFormatados = documentosComplementares.map(doc => ({
            ...doc,
            tipo_documento: 'DOCUMENTO_COMPLEMENTAR',
            nome_documento: doc.nome_documento || doc.nome_arquivo || 'Documento Complementar',
            titulo: doc.titulo || doc.nome_documento || doc.nome_arquivo || 'Documento Complementar',
            descricao: doc.descricao || 'Documento complementar adicionado ao processo'
          }))
          
          documentos.push(...documentosFormatados)
        }
      } catch (errorComp) {
        // Não bloqueia se não existir tabela de documentos complementares
        console.log('Tabela de documentos complementares não encontrada ou vazia')
      }

      console.log(`📄 Total de documentos encontrados: ${documentos?.length || 0}`)
      return documentos || []
    } catch (error) {
      console.error('Erro no serviço de documentos:', error)
      throw error
    }
  }

  static async criarDocumento(dadosDocumento) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Se não foi especificado numero_folha, calcular automaticamente
      let numeroFolha = dadosDocumento.numero_folha
      if (!numeroFolha) {
        numeroFolha = await this.obterProximoNumeroFolha(dadosDocumento.processo_id)
      }

      const documento = {
        ...dadosDocumento,
        numero_folha: numeroFolha,
        tenant_id: tenantId,
        criado_por: user.id
      }

      const { data, error } = await supabase
        .from('documentos_processo')
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

  static async obterProximoNumeroFolha(processoId) {
    try {
      const { data: ultimoDoc, error } = await supabase
        .from('documentos_processo')
        .select('numero_folha')
        .eq('processo_id', processoId)
        .order('numero_folha', { ascending: false })
        .limit(1)
        .single()

      if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
        console.error('Erro ao buscar último número de folha:', error)
        return 1
      }

      const ultimoNumero = ultimoDoc?.numero_folha || 0
      return ultimoNumero + 1
    } catch (error) {
      console.error('Erro ao obter próximo número de folha:', error)
      return 1
    }
  }

  static formatarNumeroFolha(numero) {
    return `Fl. ${numero.toString().padStart(3, '0')}`
  }

  static async criarFolhaRosto(processoId) {
    try {
      // Obter dados do processo
      const processo = await this.obterProcesso(processoId)
      
      const folhaRosto = {
        processo_id: processoId,
        tipo_documento: 'folha_rosto',
        titulo: 'Folha de Rosto',
        descricao: 'Folha de rosto do processo administrativo',
        conteudo_html: this.gerarHTMLFolhaRosto(processo),
        numero_folha: 1 // Folha de rosto sempre é a primeira
      }

      return await this.criarDocumento(folhaRosto)
    } catch (error) {
      console.error('Erro ao criar folha de rosto:', error)
      throw error
    }
  }

  static gerarHTMLFolhaRosto(processo) {
    const dataAtual = new Date().toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit', 
      year: 'numeric'
    })

    // Objetos conforme INSTRUÇÃO PROCESSUAL (1).pdf
    const objetoPadronizacao = `CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS.`

    const objetoDespadronizacao = `DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE E ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS.`

    return `
      <div class="folha-rosto" style="width: 21cm; min-height: 29.7cm; margin: 0 auto; padding: 2cm; background: white; font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.6;">
        
        <!-- Formato EXATO conforme INSTRUÇÃO PROCESSUAL (1).pdf -->
        <div style="text-align: center; margin-bottom: 3cm;">
          <div style="border: 2px solid #000; padding: 1.5cm;">
            
            <div style="font-weight: bold; font-size: 14pt; margin-bottom: 1cm;">
              PROCESSO ADMINISTRATIVO Nº ${processo.numero_processo || '[número/ano]'}
            </div>
            
            <div style="margin-bottom: 1cm; text-align: left;">
              <strong>NOME DO ÓRGÃO:</strong> ${processo.nome_orgao}
            </div>
            
            <div style="margin-bottom: 1cm; text-align: left;">
              <strong>INTERESSADO(A):</strong> ${processo.unidade_interessada}
            </div>
            
            <div style="margin-bottom: 1cm; text-align: left;">
              <strong>DATA DE AUTUAÇÃO:</strong> ${dataAtual}
            </div>
            
            <div style="text-align: left;">
              <strong>OBJETO:</strong> ${(() => {
                console.log('🔍 DEBUG OBJETO:', {
                  objeto_customizado: processo.objeto_customizado,
                  tipo_processo: processo.tipo_processo,
                  campos_disponveis: Object.keys(processo)
                })
                return processo.objeto_customizado || (processo.tipo_processo === 'padronizacao' ? objetoPadronizacao : objetoDespadronizacao)
              })()}
            </div>
            
          </div>
        </div>

        <!-- Espaço para carimbo/assinatura -->
        <div style="margin-top: 4cm; text-align: center; font-size: 10pt; color: #666;">
          <p>Fl. 001</p>
        </div>
        
      </div>
    `
  }

  // =====================================================
  // GESTÃO DE DFD (DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA)
  // =====================================================

  static async criarDFD(processoId, dadosDFD) {
    try {
      console.log('🔍 DEBUG criarDFD - processoId recebido:', processoId)
      console.log('🔍 DEBUG criarDFD - dadosDFD:', dadosDFD)

      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Verificar se o processo existe antes de criar o DFD
      const { data: processoExistente, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .select('id, numero_processo')
        .eq('id', processoId)
        .eq('tenant_id', tenantId)
        .single()

      console.log('🔍 DEBUG criarDFD - processo existente:', processoExistente)
      console.log('🔍 DEBUG criarDFD - erro ao buscar processo:', errorProcesso)

      if (errorProcesso || !processoExistente) {
        throw new Error(`Processo ${processoId} não encontrado ou não pertence ao tenant atual`)
      }

      // Gerar HTML do DFD
      console.log('🔧 DEBUG criarDFD - Iniciando geração de HTML...')
      const htmlDFD = this.gerarHTMLDFD(dadosDFD)
      console.log('✅ DEBUG criarDFD - HTML gerado com sucesso:', htmlDFD.length, 'caracteres')

      // Registrar documento com numeração sequencial automática
      const documento = await NumeracaoDocumentosService.registrarDocumento({
        processo_id: processoId,
        tenant_id: tenantId,
        tipo_documento: 'DFD',
        nome_documento: `Documento de Formalização de Demanda - ${dadosDFD.modelo_usado.toUpperCase()}`,
        conteudo: dadosDFD,
        conteudo_html: htmlDFD,
        criado_por: user.id
      })

      // Criar registro específico do DFD (se necessário manter tabela separada)
      const dfd = {
        id: documento.id, // Usar mesmo ID do documento
        processo_id: processoId,
        documento_id: documento.id,
        ...dadosDFD,
        // conteudo_html: htmlDFD, // TEMPORARIAMENTE COMENTADO: coluna não existe ainda
        tenant_id: tenantId,
        folha_numero: documento.folha_numero
      }

      console.log('💾 DEBUG criarDFD - Salvando DFD com HTML:', {
        id: dfd.id,
        htmlSize: htmlDFD.length,
        justificativa: dadosDFD.justificativa?.length || 0,
        necessidade_descricao: dadosDFD.necessidade_descricao?.length || 0
      })

      const { data: dfdData, error: dfdError } = await supabase
        .from('dfd_processo')
        .insert(dfd)
        .select()
        .single()

      if (dfdError) {
        console.error('Erro ao criar registro DFD:', dfdError)
        // Se falhar, remover documento criado
        await NumeracaoDocumentosService.removerDocumento(documento.id)
        throw dfdError
      }

      console.log(`DFD criado com sucesso: ${documento.folha_numero}`)

      // Retornar os dados do DFD com informações extras
      return {
        ...dfdData,
        documento: documento,
        folha_numero: documento.folha_numero
      }
    } catch (error) {
      console.error('Erro no serviço de DFD:', error)
      throw error
    }
  }

  static async atualizarDFD(dfdId, dadosDFD) {
    try {
      console.log('🔄 Atualizando DFD:', dfdId, dadosDFD)

      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado')
      }

      // Verificar se o DFD existe e pertence ao tenant
      const { data: dfdExistente, error: errorBuscar } = await supabase
        .from('dfd_processo')
        .select('*')
        .eq('id', dfdId)
        .eq('tenant_id', tenantId)
        .single()

      if (errorBuscar || !dfdExistente) {
        throw new Error(`DFD ${dfdId} não encontrado`)
      }

      // Gerar novo HTML do DFD com dados atualizados
      console.log('🔧 DEBUG atualizarDFD - Regenerando HTML...')
      const htmlDFDAtualizado = this.gerarHTMLDFD(dadosDFD)
      console.log('✅ DEBUG atualizarDFD - HTML regenerado:', htmlDFDAtualizado.length, 'caracteres')

      // Preparar dados para atualização
      const dadosAtualizacao = {
        ...dadosDFD,
        // conteudo_html: htmlDFDAtualizado, // TEMPORARIAMENTE COMENTADO: coluna não existe ainda
        tenant_id: tenantId,
        updated_at: new Date().toISOString()
      }

      // Atualizar o DFD
      const { data: dfdAtualizado, error: errorAtualizar } = await supabase
        .from('dfd_processo')
        .update(dadosAtualizacao)
        .eq('id', dfdId)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (errorAtualizar) {
        console.error('Erro ao atualizar DFD:', errorAtualizar)
        throw errorAtualizar
      }

      console.log('✅ DFD atualizado com sucesso:', dfdAtualizado.id)

      return dfdAtualizado

    } catch (error) {
      console.error('Erro ao atualizar DFD:', error)
      throw error
    }
  }

  static gerarHTMLDFD(dadosDFD) {
    console.log('🔧 DEBUG gerarHTMLDFD - Dados recebidos:', {
      justificativa: dadosDFD.justificativa?.length || 0,
      necessidade_descricao: dadosDFD.necessidade_descricao?.length || 0,
      modelo_usado: dadosDFD.modelo_usado,
      nome_presidente: !!dadosDFD.nome_presidente,
      criterios_aceitacao: !!dadosDFD.criterios_aceitacao,
      observacoes_especiais: !!dadosDFD.observacoes_especiais
    })

    console.log('🎨 DEBUG: Aplicando NOVA formatação compacta do DFD')

    // Validar campos obrigatórios
    if (!dadosDFD.justificativa || dadosDFD.justificativa.trim().length === 0) {
      console.warn('⚠️ gerarHTMLDFD - Justificativa vazia!')
    }
    if (!dadosDFD.necessidade_descricao || dadosDFD.necessidade_descricao.trim().length === 0) {
      console.warn('⚠️ gerarHTMLDFD - Descrição da necessidade vazia!')
    }

    const html = `
      <div class="documento-dfd" style="font-family: 'Times New Roman', serif; line-height: 1.4; margin: 0; padding: 0.3cm; color: #000;">
        <h1 style="text-align: center; font-size: 14pt; font-weight: bold; margin: 0 0 0.4cm 0; text-transform: uppercase;">
          DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${dadosDFD.modelo_usado?.toUpperCase() || 'MODELO_1'}
        </h1>

        ${dadosDFD.nome_presidente ? `
        <div style="margin-bottom: 0.4cm; page-break-inside: avoid;">
          <h2 style="font-size: 12pt; font-weight: bold; margin: 0 0 0.2cm 0; text-transform: uppercase; border-bottom: 1px solid #000; padding-bottom: 0.05cm;">DADOS DO DEMANDANTE</h2>
          <div style="margin-left: 0.3cm; text-align: justify;">
            <p style="margin: 0.1cm 0;"><strong>Nome do Presidente da CPPM:</strong> ${dadosDFD.nome_presidente}</p>
            ${dadosDFD.matricula_presidente ? `<p style="margin: 0.1cm 0;"><strong>Matrícula:</strong> ${dadosDFD.matricula_presidente}</p>` : ''}
            ${dadosDFD.email_presidente ? `<p style="margin: 0.1cm 0;"><strong>E-mail:</strong> ${dadosDFD.email_presidente}</p>` : ''}
            ${dadosDFD.telefone_presidente ? `<p style="margin: 0.1cm 0;"><strong>Telefone:</strong> ${dadosDFD.telefone_presidente}</p>` : ''}
          </div>
        </div>
        ` : ''}

        <div style="margin-bottom: 0.4cm; page-break-inside: avoid;">
          <h2 style="font-size: 12pt; font-weight: bold; margin: 0 0 0.2cm 0; text-transform: uppercase; border-bottom: 1px solid #000; padding-bottom: 0.05cm;">1. JUSTIFICATIVA</h2>
          <div style="margin-left: 0.3cm; text-align: justify;">
            <p style="margin: 0.15cm 0; line-height: 1.4; text-indent: 0.8cm;">${dadosDFD.justificativa || '[CAMPO VAZIO - JUSTIFICATIVA NÃO PREENCHIDA]'}</p>
          </div>
        </div>

        <div style="margin-bottom: 0.4cm; page-break-inside: avoid;">
          <h2 style="font-size: 12pt; font-weight: bold; margin: 0 0 0.2cm 0; text-transform: uppercase; border-bottom: 1px solid #000; padding-bottom: 0.05cm;">2. DESCRIÇÃO DA NECESSIDADE</h2>
          <div style="margin-left: 0.3cm; text-align: justify;">
            <p style="margin: 0.15cm 0; line-height: 1.4; text-indent: 0.8cm;">${dadosDFD.necessidade_descricao || '[CAMPO VAZIO - DESCRIÇÃO NÃO PREENCHIDA]'}</p>
          </div>
        </div>

        ${dadosDFD.produtos_especificacao ? `
        <div class="secao">
          <h2>PRODUTOS A SEREM PRÉ-QUALIFICADOS</h2>
          <p><strong>Especificação dos Produtos/Serviços:</strong> ${dadosDFD.produtos_especificacao}</p>
        </div>
        ` : ''}

        ${dadosDFD.quantidade_amostras || dadosDFD.previsao_aquisicoes ? `
        <div class="secao">
          <h2>QUANTIDADES E AMOSTRAGEM</h2>
          ${dadosDFD.quantidade_amostras ? `<p><strong>Quantidade de Amostras para Análise:</strong> ${dadosDFD.quantidade_amostras}</p>` : ''}
          ${dadosDFD.previsao_aquisicoes ? `<p><strong>Aquisições Previstas (12 meses):</strong> ${dadosDFD.previsao_aquisicoes}</p>` : ''}
        </div>
        ` : ''}

        ${dadosDFD.especificacoes_tecnicas ? `
        <div class="secao">
          <h2>ESPECIFICAÇÕES TÉCNICAS DETALHADAS</h2>
          <p><strong>Especificações Técnicas Obrigatórias:</strong> ${dadosDFD.especificacoes_tecnicas}</p>
        </div>
        ` : ''}

        ${dadosDFD.ensaios_exigidos || dadosDFD.criterios_aceitacao ? `
        <div class="secao">
          <h2>CRITÉRIOS DE ACEITAÇÃO E ENSAIOS</h2>
          ${dadosDFD.criterios_aceitacao ? `<p><strong>Critérios de Aceitação:</strong> ${dadosDFD.criterios_aceitacao}</p>` : ''}
          ${dadosDFD.ensaios_exigidos ? `<p><strong>Ensaios e Testes Exigidos:</strong> ${dadosDFD.ensaios_exigidos}</p>` : ''}
        </div>
        ` : ''}

        ${dadosDFD.quantidade_estimada ? `
        <div class="secao">
          <h2>QUANTIDADE ESTIMADA</h2>
          <p>${dadosDFD.quantidade_estimada}</p>
        </div>
        ` : ''}

        ${dadosDFD.prazo_entrega ? `
        <div class="secao">
          <h2>PRAZO DE ENTREGA</h2>
          <p>${dadosDFD.prazo_entrega}</p>
        </div>
        ` : ''}

        ${dadosDFD.local_entrega_amostras || dadosDFD.prazo_entrega_amostras ? `
        <div class="secao">
          <h2>CONDIÇÕES DE ENTREGA</h2>
          ${dadosDFD.local_entrega_amostras ? `<p><strong>Local de Entrega das Amostras:</strong> ${dadosDFD.local_entrega_amostras}</p>` : ''}
          ${dadosDFD.prazo_entrega_amostras ? `<p><strong>Prazo para Entrega das Amostras:</strong> ${dadosDFD.prazo_entrega_amostras} dias</p>` : ''}
        </div>
        ` : ''}

        ${dadosDFD.produtos_despadronizar ? `
        <div class="secao">
          <h2>PRODUTOS A SEREM DESPADRONIZADOS</h2>
          <p><strong>Identificação dos Produtos/Serviços:</strong> ${dadosDFD.produtos_despadronizar}</p>
        </div>
        ` : ''}

        ${dadosDFD.fonte_rdm || dadosDFD.fonte_reclamacoes_usuarios || dadosDFD.fonte_sistema_comprar_bem || dadosDFD.fonte_analise_tecnica || dadosDFD.outras_fontes ? `
        <div class="secao">
          <h2>FONTE DAS INFORMAÇÕES</h2>
          <p><strong>Origem das Reclamações/Problemas:</strong></p>
          <ul>
            ${dadosDFD.fonte_rdm ? `<li>✅ Relatórios RDM (Relatório de Desempenho de Material)</li>` : ''}
            ${dadosDFD.fonte_reclamacoes_usuarios ? `<li>✅ Reclamações de usuários finais</li>` : ''}
            ${dadosDFD.fonte_sistema_comprar_bem ? `<li>✅ Sistema "Reclame Aqui" do Comprar Bem</li>` : ''}
            ${dadosDFD.fonte_analise_tecnica ? `<li>✅ Análise técnica da CPPM</li>` : ''}
            ${dadosDFD.fonte_outras ? `<li>✅ Outros</li>` : ''}
          </ul>
          ${dadosDFD.outras_fontes ? `<p><strong>Outras Fontes:</strong> ${dadosDFD.outras_fontes}</p>` : ''}
        </div>
        ` : ''}

        ${dadosDFD.descricao_problemas ? `
        <div class="secao">
          <h2>MOTIVAÇÕES PARA DESPADRONIZAÇÃO</h2>
          <p><strong>Principais Problemas Identificados:</strong> ${dadosDFD.descricao_problemas}</p>
          ${dadosDFD.frequencia_problemas ? `<p><strong>Frequência dos Problemas:</strong> ${dadosDFD.frequencia_problemas}</p>` : ''}
          ${dadosDFD.impacto_problemas ? `<p><strong>Impacto dos Problemas:</strong> ${dadosDFD.impacto_problemas}</p>` : ''}
        </div>
        ` : ''}

        ${dadosDFD.quantidade_adquirida || dadosDFD.prejuizo_estimado || dadosDFD.rdms_negativos ? `
        <div class="secao">
          <h2>DADOS QUANTITATIVOS</h2>
          ${dadosDFD.quantidade_adquirida ? `<p><strong>Quantidade Adquirida (últimos 12 meses):</strong> ${dadosDFD.quantidade_adquirida}</p>` : ''}
          ${dadosDFD.prejuizo_estimado ? `<p><strong>Prejuízo Estimado:</strong> R$ ${dadosDFD.prejuizo_estimado}</p>` : ''}
          ${dadosDFD.rdms_negativos ? `<p><strong>Número de RDMs Negativos:</strong> ${dadosDFD.rdms_negativos}</p>` : ''}
        </div>
        ` : ''}

        ${dadosDFD.parecer_tecnico || dadosDFD.alternativas_avaliadas ? `
        <div class="secao">
          <h2>ANÁLISE TÉCNICA</h2>
          ${dadosDFD.parecer_tecnico ? `<p><strong>Parecer Técnico da CPPM:</strong> ${dadosDFD.parecer_tecnico}</p>` : ''}
          ${dadosDFD.alternativas_avaliadas ? `<p><strong>Alternativas Avaliadas:</strong> ${dadosDFD.alternativas_avaliadas}</p>` : ''}
        </div>
        ` : ''}

        ${dadosDFD.local_entrega ? `
        <div class="secao">
          <h2>LOCAL DE ENTREGA</h2>
          <p>${dadosDFD.local_entrega}</p>
        </div>
        ` : ''}

        ${dadosDFD.criterios_aceitacao ? `
        <div class="secao">
          <h2>CRITÉRIOS DE ACEITAÇÃO</h2>
          <p>${dadosDFD.criterios_aceitacao}</p>
        </div>
        ` : ''}

        ${dadosDFD.base_legal ? `
        <div class="secao">
          <h2>BASE LEGAL</h2>
          <p>${dadosDFD.base_legal}</p>
        </div>
        ` : ''}

        ${dadosDFD.impacto_esperado ? `
        <div class="secao">
          <h2>IMPACTO ESPERADO</h2>
          <p>${dadosDFD.impacto_esperado}</p>
        </div>
        ` : ''}

        ${dadosDFD.riscos_identificados ? `
        <div class="secao">
          <h2>RISCOS IDENTIFICADOS</h2>
          <p>${dadosDFD.riscos_identificados}</p>
        </div>
        ` : ''}

        ${dadosDFD.medidas_mitigadoras ? `
        <div class="secao">
          <h2>MEDIDAS MITIGADORAS</h2>
          <p>${dadosDFD.medidas_mitigadoras}</p>
        </div>
        ` : ''}

        ${dadosDFD.prazo_vigencia ? `
        <div class="secao">
          <h2>PRAZO DE VIGÊNCIA</h2>
          <p>${dadosDFD.prazo_vigencia} meses</p>
        </div>
        ` : ''}

        ${dadosDFD.periodicidade_revisao ? `
        <div class="secao">
          <h2>PERIODICIDADE DE REVISÃO</h2>
          <p>${dadosDFD.periodicidade_revisao}</p>
        </div>
        ` : ''}

        ${dadosDFD.fonte_reclamacoes ? `
        <div class="secao">
          <h2>FONTE DAS RECLAMAÇÕES</h2>
          <p>${dadosDFD.fonte_reclamacoes}</p>
        </div>
        ` : ''}

        ${dadosDFD.descricao_problemas ? `
        <div class="secao">
          <h2>PROBLEMAS IDENTIFICADOS</h2>
          <p>${dadosDFD.descricao_problemas}</p>
        </div>
        ` : ''}

        ${dadosDFD.observacoes_especiais ? `
        <div class="secao">
          <h2>OBSERVAÇÕES ESPECIAIS</h2>
          <p>${dadosDFD.observacoes_especiais}</p>
        </div>
        ` : ''}

        <div class="assinatura">
          <p>Data: ${new Date().toLocaleDateString('pt-BR')}</p>
          <br>
          <p>_________________________________________</p>
          <p>Presidente da CPPM</p>
        </div>
      </div>
    `

    console.log('✅ DEBUG gerarHTMLDFD - HTML gerado:', {
      tamanho: html.length,
      temJustificativa: html.includes('JUSTIFICATIVA'),
      temDescricao: html.includes('DESCRIÇÃO DA NECESSIDADE'),
      preview: html.substring(0, 150) + '...'
    })

    return html
  }

  // =====================================================
  // GESTÃO DE PRODUTOS EM PRÉ-QUALIFICAÇÃO
  // =====================================================

  static async adicionarProduto(processoId, dadosProduto, forcarInsercao = false) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Verificar se o produto já existe na pré-qualificação
      if (dadosProduto.id) {
        const { data: produtoExistente, error: errorVerificacao } = await supabase
          .from('produtos_prequalificacao')
          .select('id, processo_id')
          .eq('id', dadosProduto.id)
          .eq('tenant_id', tenantId)
          .single()

        // Se já existe no MESMO processo, apenas retornar o produto existente
        if (produtoExistente && !errorVerificacao && produtoExistente.processo_id === processoId) {
          console.log('✅ Produto já existe no mesmo processo, retornando o existente')
          return produtoExistente
        }

        // Só dar erro se o produto foi usado em um processo DIFERENTE e não foi forçada a inserção
        if (produtoExistente && !errorVerificacao && produtoExistente.processo_id !== processoId && !forcarInsercao) {
          const error = new Error('Este produto já foi usado em um processo de pré-qualificação. Deseja reutilizá-lo mesmo assim?')
          error.code = 'PRODUTO_JA_USADO'
          error.produtoId = dadosProduto.id
          throw error
        }
      }

      const produto = {
        processo_id: processoId,
        ...dadosProduto,
        tenant_id: tenantId
      }

      const { data, error } = await supabase
        .from('produtos_prequalificacao')
        .insert(produto)
        .select()
        .single()

      if (error) {
        console.error('Erro ao adicionar produto:', error)
        
        // Se for erro de duplicate key, dar mensagem mais amigável
        if (error.code === '23505') {
          const errorMessage = new Error('Este produto já foi usado em um processo de pré-qualificação. Deseja reutilizá-lo mesmo assim?')
          errorMessage.code = 'PRODUTO_JA_USADO'
          errorMessage.produtoId = dadosProduto.id
          throw errorMessage
        }
        
        throw error
      }

      console.log('✅ Produto salvo com sucesso:', data.nome_produto)
      
      // AUTOMATICAMENTE salvar TODOS os documentos do produto no processo
      await this.vincularDocumentosProdutoProcesso(processoId, data)
      
      return data
    } catch (error) {
      console.error('Erro no serviço de produtos:', error)
      throw error
    }
  }

  static async vincularDocumentosProdutoProcesso(processoId, produto) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      console.log(`📁 Vinculando documentos do produto ${produto.nome_produto} ao processo`)

      // INVESTIGAR: Buscar documentos em TODAS as possíveis tabelas/estruturas
      console.log('🔍 INVESTIGAÇÃO - Buscando documentos em arquivos_produto')
      const { data: documentosArquivos, error: errorArquivos } = await supabase
        .from('arquivos_produto')
        .select('*')
        .eq('produto_id', produto.id)

      console.log('📋 RESULTADO arquivos_produto:', { documentosArquivos, errorArquivos })

      // Buscar também na estrutura do próprio produto
      console.log('🔍 INVESTIGAÇÃO - Buscando documentos na estrutura do produto')
      const { data: produtoCompleto, error: errorProduto } = await supabase
        .from('produtos')
        .select('*, documentos:arquivos_produto(*)')
        .eq('id', produto.id)
        .single()

      console.log('📋 RESULTADO produto completo:', { produtoCompleto, errorProduto })

      // 3. ENCONTRADOS! Verificar campo 'documentos' (sem sufixo) no produto
      console.log('🔍 INVESTIGAÇÃO 3 - Verificando campo documentos no produto salvo:', produto.documentos)
      
      // 4. Verificar se documentos estão no campo correto 'documentos'
      let documentosOriginaisCandidatos = []
      if (produto.documentos && Array.isArray(produto.documentos)) {
        console.log('🎉 SUCESSO! Documentos encontrados no campo "documentos" do produto salvo!')
        documentosOriginaisCandidatos = produto.documentos
      }
      
      console.log('📋 Documentos candidatos encontrados:', documentosOriginaisCandidatos)

      // Usar documentos encontrados (priorizar diferentes fontes por ordem de prioridade)
      let documentosOriginais = null
      
      // PRIORIDADE 1: Campo 'documentos' (JSON no produto) ✅ CORRETO!
      if (documentosOriginaisCandidatos.length > 0) {
        console.log('🎉 USANDO documentos do campo "documentos" (JSON no produto)!')
        documentosOriginais = documentosOriginaisCandidatos
      }
      // PRIORIDADE 2: Tabela arquivos_produto separada  
      else if (documentosArquivos && documentosArquivos.length > 0) {
        console.log('📋 USANDO documentos da tabela arquivos_produto')
        documentosOriginais = documentosArquivos
      }
      // PRIORIDADE 3: Relação produto->arquivos_produto
      else if (produtoCompleto?.documentos && produtoCompleto.documentos.length > 0) {
        console.log('📋 USANDO documentos da relação produto->arquivos_produto')
        documentosOriginais = produtoCompleto.documentos
      }

      if (errorArquivos) {
        console.warn('⚠️ Erro ao buscar documentos do produto:', errorArquivos)
        return
      }

      if (!documentosOriginais || documentosOriginais.length === 0) {
        console.log('ℹ️ Produto não possui documentos para vincular em nenhuma tabela investigada')
        return
      }

      console.log(`📋 Encontrados ${documentosOriginais.length} documentos do produto`)

      // Salvar TODOS os documentos na nova tabela vinculados ao processo
      const documentosParaSalvar = documentosOriginais.map(doc => ({
        processo_id: processoId,
        produto_id: produto.id,
        tenant_id: tenantId,
        // Mapear campos corretos dos documentos do produto
        nome_arquivo: doc.nome_arquivo || doc.nome, // 'nome' nos docs do produto
        tipo_arquivo: doc.tipo_arquivo || doc.tipo, // 'tipo' nos docs do produto  
        tamanho: doc.tamanho || null,
        url_arquivo: doc.url_arquivo || doc.arquivo_url, // 'arquivo_url' nos docs do produto
        nome_produto: produto.nome_produto,
        marca: produto.marca,
        fabricante: produto.fabricante,
        criado_por: user.id
      }))
      
      console.log('📋 DEBUG - Documentos mapeados para salvar:', documentosParaSalvar)

      const { data: documentosSalvos, error: errorSalvar } = await supabase
        .from('documentos_produtos_processo')
        .upsert(documentosParaSalvar, {
          onConflict: 'processo_id,produto_id,nome_arquivo,tenant_id'
        })
        .select()

      if (errorSalvar) {
        console.error('❌ Erro ao salvar documentos do produto no processo:', errorSalvar)
        throw errorSalvar
      }

      console.log(`✅ ${documentosSalvos?.length || documentosParaSalvar.length} documentos vinculados ao processo com sucesso`)

    } catch (error) {
      console.error('Erro ao vincular documentos do produto ao processo:', error)
      // Não falhar o salvamento do produto por causa dos documentos
    }
  }

  static async listarProdutosProcesso(processoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('produtos_prequalificacao')
        .select('*')
        .eq('processo_id', processoId)
        .eq('tenant_id', tenantId)

      if (error) {
        console.error('Erro ao listar produtos:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de produtos:', error)
      throw error
    }
  }

  // =====================================================
  // GESTÃO DE ASSINATURAS ELETRÔNICAS
  // =====================================================

  static async assinarDocumento(documentoId, dadosAssinatura) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Criar registro de assinatura
      const assinatura = {
        documento_id: documentoId,
        usuario_id: user.id,
        nome_completo: dadosAssinatura.nome_completo,
        cargo: dadosAssinatura.cargo,
        tipo_assinatura: dadosAssinatura.tipo_assinatura || 'eletronica',
        hash_documento: dadosAssinatura.hash_documento,
        ip_assinatura: dadosAssinatura.ip_assinatura,
        observacoes: dadosAssinatura.observacoes,
        tenant_id: tenantId
      }

      const { data: assinaturaData, error: assinaturaError } = await supabase
        .from('assinaturas_processo')
        .insert(assinatura)
        .select()
        .single()

      if (assinaturaError) {
        console.error('Erro ao criar assinatura:', assinaturaError)
        throw assinaturaError
      }

      // Atualizar documento como assinado
      const { data: documentoData, error: documentoError } = await supabase
        .from('documentos_processo')
        .update({
          assinado: true,
          data_assinatura: new Date().toISOString(),
          assinado_por: user.id,
          cargo_assinante: dadosAssinatura.cargo
        })
        .eq('id', documentoId)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (documentoError) {
        console.error('Erro ao atualizar documento:', documentoError)
        throw documentoError
      }

      return { assinatura: assinaturaData, documento: documentoData }
    } catch (error) {
      console.error('Erro no serviço de assinatura:', error)
      throw error
    }
  }

  // =====================================================
  // GESTÃO DE TRAMITAÇÃO
  // =====================================================

  static async obterTramitacao(processoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('tramitacao_processo')
        .select(`
          *,
          responsavel_info:responsavel(*)
        `)
        .eq('processo_id', processoId)
        .eq('tenant_id', tenantId)
        .order('data_tramitacao', { ascending: false })

      if (error) {
        console.error('Erro ao obter tramitação:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de tramitação:', error)
      throw error
    }
  }

  // =====================================================
  // GESTÃO DE RECURSOS ADMINISTRATIVOS
  // =====================================================

  static async criarRecurso(processoId, dadosRecurso) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const recurso = {
        processo_id: processoId,
        ...dadosRecurso,
        tenant_id: tenantId
      }

      const { data, error } = await supabase
        .from('recursos_processo')
        .insert(recurso)
        .select()
        .single()

      if (error) {
        console.error('Erro ao criar recurso:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de recursos:', error)
      throw error
    }
  }

  static async listarRecursosProcesso(processoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('recursos_processo')
        .select('*')
        .eq('processo_id', processoId)
        .eq('tenant_id', tenantId)
        .order('data_interposicao', { ascending: false })

      if (error) {
        console.error('Erro ao listar recursos:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de recursos:', error)
      throw error
    }
  }

  // =====================================================
  // GESTÃO DE FLUXO - LEI 14.133/2021 (5 FASES)
  // =====================================================

  static async obterPerfilUsuario() {
    try {
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user
      
      if (!user) {
        throw new Error('Usuário não autenticado')
      }

      const { data: usuario } = await supabase
        .from('usuarios')
        .select('perfil_usuario')
        .eq('id', user.id)
        .single()

      return usuario?.perfil_usuario || null
    } catch (error) {
      console.error('Erro ao obter perfil do usuário:', error)
      return null
    }
  }

  static async verificarPermissaoTransicao(processoId, novoStatus) {
    try {
      const perfilUsuario = await this.obterPerfilUsuario()
      const processo = await this.obterProcesso(processoId)
      
      if (!perfilUsuario || !processo) {
        return false
      }

      const statusAtual = processo.status
      
      // Regras de transição baseadas no perfil e status atual
      const regrasTransicao = {
        'cpm': {
          'rascunho': ['criado_cpm'],
          'em_criacao': ['criado_cpm'],
          'criado_cpm': ['aprovado_cpm', 'rejeitado_cpm'],
          'assinado_admin': ['julgamento_ccl'], // CPM pode enviar para CCL após assinatura administrativa
          'rejeitado_admin': ['aprovado_cpm', 'rejeitado_cpm'],
          'rejeitado_juridico': ['aprovado_cpm', 'rejeitado_cpm'],
          'rejeitado_ccl': ['aprovado_cpm', 'rejeitado_cpm'] // CPM pode corrigir após rejeição da CCL
        },
        'ccl': {
          'julgamento_ccl': ['aprovado_ccl', 'rejeitado_ccl'] // CCL pode julgar processos recebidos
        },
        'orgao_administrativo': {
          'aprovado_cpm': ['assinado_admin', 'rejeitado_admin'],
          'aprovado_ccl': ['homologado', 'rejeitado_final'], // Homologar após aprovação da CCL
          'aprovado_juridico': ['homologado', 'rejeitado_final']
        },
        'assessoria_juridica': {
          'assinado_admin': ['aprovado_juridico', 'rejeitado_juridico']
        }
      }

      const transicoesPermitidas = regrasTransicao[perfilUsuario]?.[statusAtual] || []
      return transicoesPermitidas.includes(novoStatus)
    } catch (error) {
      console.error('Erro ao verificar permissão de transição:', error)
      return false
    }
  }

  static async tramitarProcesso(processoId, novoStatus, observacoes = '') {
    try {
      const permissao = await this.verificarPermissaoTransicao(processoId, novoStatus)
      
      if (!permissao) {
        throw new Error('Usuário não tem permissão para realizar esta transição')
      }

      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user
      const perfilUsuario = await this.obterPerfilUsuario()

      // Obter processo atual para pegar status anterior
      const processo = await this.obterProcesso(processoId)
      const statusAnterior = processo.status

      // Atualizar status do processo
      const { data: processoAtualizado, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .update({
          status: novoStatus,
          atualizado_por: user.id,
          atualizado_em: new Date().toISOString()
        })
        .eq('id', processoId)
        .eq('tenant_id', tenantId)
        .select()
        .single()

      if (errorProcesso) {
        throw errorProcesso
      }

      // Registrar tramitação
      const tramitacao = {
        processo_id: processoId,
        status_anterior: statusAnterior,
        status_novo: novoStatus,
        responsavel: user.id,
        perfil_responsavel: perfilUsuario,
        observacoes: observacoes,
        data_tramitacao: new Date().toISOString(),
        tenant_id: tenantId
      }

      const { data: tramitacaoData, error: errorTramitacao } = await supabase
        .from('tramitacao_processo')
        .insert(tramitacao)
        .select()
        .single()

      if (errorTramitacao) {
        console.warn('Erro ao registrar tramitação:', errorTramitacao)
      }

      // Enviar notificações automáticas por email
      try {
        await EmailNotificationService.enviarNotificacaoTramitacao(
          processoId, 
          statusAnterior, 
          novoStatus, 
          observacoes
        )
      } catch (emailError) {
        console.warn('Erro ao enviar notificação por email:', emailError)
        // Não falhar a tramitação por causa do email
      }

      return { processo: processoAtualizado, tramitacao: tramitacaoData }
    } catch (error) {
      console.error('Erro ao tramitar processo:', error)
      throw error
    }
  }

  static async submeterParaAnalise(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'criado_cpm', observacoes)
  }

  static async aprovarCPM(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'aprovado_cpm', observacoes)
  }

  static async rejeitarCPM(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'rejeitado_cpm', observacoes)
  }

  static async assinarAdministrativo(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'assinado_admin', observacoes)
  }

  static async rejeitarAdministrativo(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'rejeitado_admin', observacoes)
  }

  static async aprovarJuridico(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'aprovado_juridico', observacoes)
  }

  static async rejeitarJuridico(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'rejeitado_juridico', observacoes)
  }

  static async homologarProcesso(processoId, observacoes = '') {
    const resultado = await this.tramitarProcesso(processoId, 'homologado', observacoes)
    
    // Se for processo de padronização, incluir produtos no catálogo e gerar DCB
    const processo = await this.obterProcesso(processoId)
    if (processo.tipo_processo === 'padronizacao') {
      await this.incluirProdutosNoCatalogo(processoId)
      await this.gerarDCB(processoId)
    }
    
    return resultado
  }

  static async rejeitarFinal(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'rejeitado_final', observacoes)
  }

  // =====================================================
  // GESTÃO DO FLUXO CCL
  // =====================================================

  static async enviarParaCCL(processoId, observacoes = '') {
    // Verificar se processo está assinado pelo órgão administrativo
    const processo = await this.obterProcesso(processoId)
    if (processo.status !== 'assinado_admin') {
      throw new Error('Processo deve estar assinado pelo Órgão Administrativo antes de ser enviado para CCL')
    }
    
    return await this.tramitarProcesso(processoId, 'julgamento_ccl', observacoes)
  }

  static async aprovarCCL(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'aprovado_ccl', observacoes)
  }

  static async rejeitarCCL(processoId, observacoes = '') {
    return await this.tramitarProcesso(processoId, 'rejeitado_ccl', observacoes)
  }

  static async incluirProdutosNoCatalogo(processoId) {
    try {
      const produtos = await this.listarProdutosProcesso(processoId)
      const tenantId = await getTenantId()

      for (const produto of produtos) {
        // Verificar se já existe no catálogo
        const { data: existente } = await supabase
          .from('produtos')
          .select('id')
          .eq('nome', produto.nome_produto)
          .eq('fabricante', produto.fabricante)
          .eq('tenant_id', tenantId)
          .single()

        if (!existente) {
          // Incluir no catálogo
          const produtoCatalogo = {
            nome: produto.nome_produto,
            fabricante: produto.fabricante,
            categoria: produto.categoria,
            subcategoria: produto.subcategoria,
            especificacoes: produto.especificacoes_tecnicas,
            status: 'ativo',
            pre_qualificado: true,
            processo_id: processoId,
            tenant_id: tenantId
          }

          await supabase
            .from('produtos')
            .insert(produtoCatalogo)
        }
      }
    } catch (error) {
      console.error('Erro ao incluir produtos no catálogo:', error)
    }
  }

  // =====================================================
  // GERAÇÃO AUTOMÁTICA DE DCB
  // =====================================================

  static async gerarDCB(processoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Obter dados do processo
      const processo = await this.obterProcesso(processoId)
      const produtos = await this.listarProdutosProcesso(processoId)

      if (produtos.length === 0) {
        console.warn('Nenhum produto encontrado para gerar DCB')
        return null
      }

      // Gerar número da DCB
      const numeroDCB = await this.gerarNumeroDCB(tenantId)

      // Obter próximo número de folha
      const numeroFolha = await this.obterProximoNumeroFolha(processoId)

      // Criar documento DCB
      const dcb = {
        processo_id: processoId,
        tipo_documento: 'dcb',
        titulo: `Declaração de Conformidade de Bem - DCB Nº ${numeroDCB}`,
        descricao: 'Declaração de Conformidade de Bem emitida após homologação',
        conteudo_html: this.gerarHTMLDCB(processo, produtos, numeroDCB),
        numero_folha: numeroFolha,
        numero_dcb: numeroDCB
      }

      const dcbDocument = await this.criarDocumento(dcb)

      // Registrar DCB na tabela específica para controle
      await this.registrarDCB({
        processo_id: processoId,
        numero_dcb: numeroDCB,
        documento_id: dcbDocument.id,
        produtos_incluidos: produtos.length,
        data_emissao: new Date().toISOString(),
        tenant_id: tenantId
      })

      console.log(`DCB Nº ${numeroDCB} gerada automaticamente para processo ${processo.numero_processo}`)
      return dcbDocument

    } catch (error) {
      console.error('Erro ao gerar DCB:', error)
      throw error
    }
  }

  static async gerarNumeroDCB(tenantId) {
    try {
      const ano = new Date().getFullYear()
      
      // Buscar último número DCB do ano
      const { data: ultimaDCB, error } = await supabase
        .from('dcb_emitidas')
        .select('numero_dcb')
        .eq('tenant_id', tenantId)
        .like('numero_dcb', `${ano}%`)
        .order('numero_dcb', { ascending: false })
        .limit(1)
        .single()

      let proximoSequencial = 1
      if (ultimaDCB && !error) {
        // Extrair número sequencial do formato YYYY/NNNN
        const partes = ultimaDCB.numero_dcb.split('/')
        if (partes.length === 2) {
          proximoSequencial = parseInt(partes[1]) + 1
        }
      }

      // Formato: YYYY/NNNN
      const numeroFormatado = `${ano}/${proximoSequencial.toString().padStart(4, '0')}`
      return numeroFormatado

    } catch (error) {
      console.error('Erro ao gerar número DCB:', error)
      // Fallback para um número simples
      return `${new Date().getFullYear()}/0001`
    }
  }

  static async registrarDCB(dadosDCB) {
    try {
      const { data, error } = await supabase
        .from('dcb_emitidas')
        .insert(dadosDCB)
        .select()
        .single()

      if (error) {
        console.error('Erro ao registrar DCB:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro ao registrar DCB:', error)
      throw error
    }
  }

  static gerarHTMLDCB(processo, produtos, numeroDCB) {
    const dataEmissao = new Date().toLocaleDateString('pt-BR')
    const anoVigencia = new Date().getFullYear() + 2 // DCB válida por 2 anos
    
    return `
      <div class="dcb-documento">
        <div class="numero-folha" style="text-align: right; margin-bottom: 20px;">
          <strong>${this.formatarNumeroFolha(processo.total_documentos + 1)}</strong>
        </div>
        
        <div class="cabecalho-dcb">
          <h1>DECLARAÇÃO DE CONFORMIDADE DE BEM</h1>
          <h2>DCB Nº ${numeroDCB}</h2>
          <p><strong>Processo Administrativo:</strong> ${processo.numero_processo}</p>
          <p><strong>Órgão:</strong> ${processo.nome_orgao}</p>
        </div>

        <div class="secao">
          <h3>IDENTIFICAÇÃO</h3>
          <p><strong>Data de Emissão:</strong> ${dataEmissao}</p>
          <p><strong>Validade:</strong> Até 31/12/${anoVigencia}</p>
          <p><strong>Base Legal:</strong> Art. 80, inciso II, da Lei Federal nº 14.133/2021</p>
        </div>

        <div class="secao">
          <h3>PRODUTOS PRÉ-QUALIFICADOS</h3>
          <p>Os produtos relacionados abaixo foram submetidos ao procedimento de pré-qualificação e atendem aos requisitos mínimos de qualidade, estética, rendimento, durabilidade, adequação ao uso e à finalidade:</p>
          
          <table border="1" style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <thead>
              <tr style="background-color: #f0f0f0;">
                <th style="padding: 8px; text-align: left;">Item</th>
                <th style="padding: 8px; text-align: left;">Produto</th>
                <th style="padding: 8px; text-align: left;">Marca/Modelo</th>
                <th style="padding: 8px; text-align: left;">Categoria</th>
              </tr>
            </thead>
            <tbody>
              ${produtos.map((produto, index) => `
                <tr>
                  <td style="padding: 8px;">${index + 1}</td>
                  <td style="padding: 8px;">${produto.nome_produto}</td>
                  <td style="padding: 8px;">${produto.marca || 'N/A'}${produto.modelo ? ` / ${produto.modelo}` : ''}</td>
                  <td style="padding: 8px;">${produto.categoria_produto || 'N/A'}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>

        <div class="secao">
          <h3>CONDIÇÕES DE VALIDADE</h3>
          <ul>
            <li>Esta DCB autoriza a inclusão dos produtos relacionados no Catálogo Eletrônico de Bens Padronizados;</li>
            <li>Os produtos mantêm a pré-qualificação enquanto não houver alteração nas especificações técnicas;</li>
            <li>A validade pode ser revogada a qualquer tempo mediante justificativa técnica;</li>
            <li>Renovação sujeita a novo procedimento de pré-qualificação conforme cronograma da CPM.</li>
          </ul>
        </div>

        <div class="observacoes">
          <h3>OBSERVAÇÕES</h3>
          <p>Esta Declaração de Conformidade foi emitida automaticamente após a homologação do processo administrativo de pré-qualificação, em conformidade com os procedimentos estabelecidos na Lei nº 14.133/2021.</p>
        </div>

        <div class="assinatura" style="margin-top: 50px;">
          <p>Data: ${dataEmissao}</p>
          <br>
          <br>
          <p>_________________________________________</p>
          <p><strong>Presidente da Comissão Permanente de Padronização de Materiais - CPM</strong></p>
          <p>${processo.nome_orgao}</p>
        </div>
      </div>
    `
  }

  static obterAcoesDisponiveis(status, perfilUsuario) {
    const acoesPorStatusPerfil = {
      'rascunho': {
        'cpm': ['submeter_analise']
      },
      'em_criacao': {
        'cpm': ['submeter_analise']
      },
      'criado_cpm': {
        'cpm': ['aprovar_cpm', 'rejeitar_cpm']
      },
      'aprovado_cpm': {
        'orgao_administrativo': ['assinar_admin', 'rejeitar_admin']
      },
      'assinado_admin': {
        'cpm': ['enviar_ccl'], // CPM pode enviar para CCL APENAS após assinatura administrativa
        'assessoria_juridica': ['aprovar_juridico', 'rejeitar_juridico']
      },
      'julgamento_ccl': {
        'ccl': ['aprovar_ccl', 'rejeitar_ccl'] // CCL pode julgar o processo
      },
      'aprovado_ccl': {
        'orgao_administrativo': ['homologar', 'rejeitar_final']
      },
      'aprovado_juridico': {
        'orgao_administrativo': ['homologar', 'rejeitar_final']
      },
      'rejeitado_cpm': {
        'cpm': ['aprovar_cpm']
      },
      'rejeitado_admin': {
        'cpm': ['aprovar_cpm']
      },
      'rejeitado_juridico': {
        'cpm': ['aprovar_cpm']
      },
      'rejeitado_ccl': {
        'cpm': ['aprovar_cpm'] // Se CCL rejeitar, volta para CPM corrigir
      }
    }

    return acoesPorStatusPerfil[status]?.[perfilUsuario] || []
  }

  // =====================================================
  // GESTÃO DE ASSINATURA DIGITAL POR PERFIL
  // =====================================================

  static async assinarDocumentoPorPerfil(documentoId, observacoes = '') {
    try {
      const perfilUsuario = await this.obterPerfilUsuario()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user
      
      if (!perfilUsuario || !user) {
        throw new Error('Usuário não autenticado ou sem perfil')
      }

      // Obter informações do usuário
      const { data: dadosUsuario } = await supabase
        .from('usuarios')
        .select('nome, perfil_usuario')
        .eq('id', user.id)
        .single()

      const cargosAssinatura = {
        'cpm': 'Presidente da CPM',
        'orgao_administrativo': 'Autoridade Administrativa Competente',
        'assessoria_juridica': 'Assessor Jurídico'
      }

      const dadosAssinatura = {
        nome_completo: dadosUsuario.nome,
        cargo: cargosAssinatura[perfilUsuario] || 'Servidor Público',
        tipo_assinatura: 'eletronica',
        ip_assinatura: '', // Seria obtido no frontend
        observacoes: observacoes
      }

      return await this.assinarDocumento(documentoId, dadosAssinatura)
    } catch (error) {
      console.error('Erro ao assinar documento por perfil:', error)
      throw error
    }
  }

  // =====================================================
  // UTILITÁRIOS
  // =====================================================

  static async getTenantId() {
    return await getTenantId()
  }

  static async obterEstatisticas() {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Processos por status
      const { data: processosPorStatus, error: errorStatus } = await supabase
        .from('processos_administrativos')
        .select('status')
        .eq('tenant_id', tenantId)

      if (errorStatus) {
        throw errorStatus
      }

      // Processos por tipo
      const { data: processosPorTipo, error: errorTipo } = await supabase
        .from('processos_administrativos')
        .select('tipo_processo')
        .eq('tenant_id', tenantId)

      if (errorTipo) {
        throw errorTipo
      }

      // Processos criados nos últimos 30 dias
      const trintaDiasAtras = new Date()
      trintaDiasAtras.setDate(trintaDiasAtras.getDate() - 30)

      const { data: processosRecentes, error: errorRecentes } = await supabase
        .from('processos_administrativos')
        .select('id')
        .eq('tenant_id', tenantId)
        .gte('criado_em', trintaDiasAtras.toISOString())

      if (errorRecentes) {
        throw errorRecentes
      }

      const estatisticas = {
        total: processosPorStatus.length,
        por_status: processosPorStatus.reduce((acc, p) => {
          acc[p.status] = (acc[p.status] || 0) + 1
          return acc
        }, {}),
        por_tipo: processosPorTipo.reduce((acc, p) => {
          acc[p.tipo_processo] = (acc[p.tipo_processo] || 0) + 1
          return acc
        }, {}),
        recentes: processosRecentes.length
      }

      return estatisticas
    } catch (error) {
      console.error('Erro ao obter estatísticas:', error)
      throw error
    }
  }

  static formatarNumeroProcesso(numero) {
    return numero || 'Aguardando numeração'
  }

  static obterStatusProcesso(status) {
    const statusMap = {
      // NOVOS STATUS - CONFORME CLIENTE VERSÃO 05/08/25
      // 🟢 PADRONIZAÇÃO - Sequência lógica do fluxo processual
      'rascunho': { label: 'Em Criação', cor: 'gray' },
      'em_criacao': { label: 'Em Criação', cor: 'gray' },
      'criado_cpm': { label: 'Criado pela CPM', cor: 'blue' },
      'aguardando_assinatura_orgao': { label: 'Aguardando Assinatura', cor: 'orange' },
      'aguardando_assinatura_orgao_desp': { label: 'Aguardando Assinatura', cor: 'orange' },
      'submetido_autoridade': { label: 'Submetido à Autoridade Competente', cor: 'yellow' },
      'abertura_autorizada': { label: 'Abertura Autorizada', cor: 'green' },
      'edital_chamamento': { label: 'Edital de Chamamento Público', cor: 'purple' },
      'analise_juridica': { label: 'Em Análise Jurídica', cor: 'orange' },
      'com_impugnacao': { label: 'Com Impugnação ao Edital', cor: 'red' },
      'recebendo_amostras': { label: 'Recebendo Amostras e Documentação', cor: 'cyan' },
      'avaliacao_cpm': { label: 'Com Avaliação e Relatório da CPM', cor: 'yellow' },
      'submetido_ccl': { label: 'Submetido ao Julgamento da CCL', cor: 'pink' },
      'ata_julgamento': { label: 'Ata de Julgamento da CCL', cor: 'purple' },
      'publicacao_ata': { label: 'Publicação da Ata e Prazo Recursal', cor: 'amber' },
      'com_recurso': { label: 'Com Recurso Administrativo', cor: 'red' },
      'expedindo_dcbs': { label: 'Expedindo as DCBs', cor: 'indigo' },
      'incluindo_marcas': { label: 'Incluindo Marcas no Catálogo', cor: 'green' },
      
      // 🔴 DESPADRONIZAÇÃO - Sequência lógica do fluxo processual
      'em_criacao_desp': { label: 'Em Criação', cor: 'gray' },
      'criado_cpm_desp': { label: 'Criado pela CPM', cor: 'blue' },
      'submetido_autoridade_desp': { label: 'Submetido à Autoridade Competente', cor: 'yellow' },
      'abertura_autorizada_desp': { label: 'Abertura Autorizada', cor: 'green' },
      'aviso_publicado': { label: 'Com Aviso Publicado', cor: 'purple' },
      'com_recurso_desp': { label: 'Com Recurso Administrativo', cor: 'red' },
      'homologado_desp': { label: 'Com Homologação', cor: 'green' },
      'excluindo_marcas': { label: 'Excluindo Marcas do Catálogo', cor: 'red' },
      'aprovado_cpm': { label: 'Aprovado pela CPM', cor: 'cyan' },
      'rejeitado_cpm': { label: 'Rejeitado pela CPM', cor: 'red' },
      'assinado_admin': { label: 'Assinado pelo Órgão', cor: 'yellow' },
      'rejeitado_admin': { label: 'Rejeitado pelo Órgão', cor: 'red' },
      'julgamento_ccl': { label: 'Julgamento CCL', cor: 'pink' },
      'aprovado_ccl': { label: 'Aprovado pela CCL', cor: 'purple' },
      'rejeitado_ccl': { label: 'Rejeitado pela CCL', cor: 'red' },
      'aprovado_juridico': { label: 'Aprovado Juridicamente', cor: 'purple' },
      'rejeitado_juridico': { label: 'Rejeitado Juridicamente', cor: 'red' },
      'homologado': { label: 'Com Homologação', cor: 'green' },
      'rejeitado_final': { label: 'Rejeitado Final', cor: 'red' },
      
      // STATUS ANTIGOS (MANTIDOS PARA COMPATIBILIDADE)
      'iniciado': { label: 'Iniciado', cor: 'blue' },
      'aguardando_aprovacao': { label: 'Criado pela CPM', cor: 'blue' },
      'analise_cppm': { label: 'Análise CPPM', cor: 'yellow' },
      'aguardando_edital': { label: 'Aguardando Edital', cor: 'purple' },
      'edital_publicado': { label: 'Com Edital Publicado', cor: 'green' },
      'recebendo_propostas': { label: 'Recebendo Propostas', cor: 'cyan' },
      'analise_tecnica': { label: 'Análise Técnica', cor: 'indigo' },
      'prazo_recursal': { label: 'Prazo Recursal', cor: 'amber' },
      'com_recursos': { label: 'Com Recursos', cor: 'red' },
      'finalizado': { label: 'Finalizado', cor: 'green' },
      'cancelado': { label: 'Cancelado', cor: 'gray' }
    }

    return statusMap[status] || { label: status, cor: 'gray' }
  }

  static obterTipoProcesso(tipo) {
    const tiposMap = {
      'padronizacao': { label: 'Padronização', icone: '✅' },
      'despadronizacao': { label: 'Despadronização', icone: '❌' }
    }

    return tiposMap[tipo] || { label: tipo, icone: '📄' }
  }

  // =====================================================
  // GESTÃO DE FOLHA DE ROSTO E NUMERAÇÃO SEQUENCIAL
  // =====================================================

  static async criarFolhaRosto(processoId, dadosFolhaRosto) {
    try {
      const tenantId = await getTenantId()
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!tenantId || !user) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      // Gerar HTML da folha de rosto
      const htmlFolhaRosto = this.gerarHTMLFolhaRosto(dadosFolhaRosto)

      // Registrar como primeiro documento (Fl. 001) sempre
      const documento = await NumeracaoDocumentosService.registrarDocumento({
        processo_id: processoId,
        tenant_id: tenantId,
        tipo_documento: 'FOLHA_ROSTO',
        nome_documento: 'Folha de Rosto do Processo Administrativo',
        conteudo: dadosFolhaRosto,
        conteudo_html: htmlFolhaRosto,
        criado_por: user.id
      })

      console.log(`Folha de Rosto criada: ${documento.folha_numero}`)
      return documento

    } catch (error) {
      console.error('Erro ao criar folha de rosto:', error)
      throw error
    }
  }

  static gerarHTMLFolhaRosto(dados) {
    const dataAtual = new Date().toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit', 
      year: 'numeric'
    })

    // Objetos conforme INSTRUÇÃO PROCESSUAL (1).pdf
    const objetoPadronizacao = `CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS.`

    const objetoDespadronizacao = `DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE E ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS.`

    return `
      <div class="folha-rosto" style="width: 21cm; min-height: 29.7cm; margin: 0 auto; padding: 2cm; background: white; font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.6;">
        
        <!-- Formato EXATO conforme INSTRUÇÃO PROCESSUAL (1).pdf -->
        <div style="text-align: center; margin-bottom: 3cm;">
          <div style="border: 2px solid #000; padding: 1.5cm;">
            
            <div style="font-weight: bold; font-size: 14pt; margin-bottom: 1cm;">
              PROCESSO ADMINISTRATIVO Nº ${dados.numeroProcesso}
            </div>
            
            <div style="margin-bottom: 1cm; text-align: left;">
              <strong>NOME DO ÓRGÃO:</strong> ${dados.dadosOrgao.nome}
            </div>
            
            <div style="margin-bottom: 1cm; text-align: left;">
              <strong>INTERESSADO(A):</strong> ${dados.dadosOrgao.departamento || 'COMISSÃO PERMANENTE DE PADRONIZAÇÃO DE MATERIAIS - CPPM'}
            </div>
            
            <div style="margin-bottom: 1cm; text-align: left;">
              <strong>DATA DE AUTUAÇÃO:</strong> ${dataAtual}
            </div>
            
            <div style="text-align: left;">
              <strong>OBJETO:</strong> ${dados.objeto_customizado || (dados.tipoProcesso === 'padronizacao' ? objetoPadronizacao : objetoDespadronizacao)}
            </div>
            
          </div>
        </div>

        <!-- Espaço para carimbo/assinatura -->
        <div style="margin-top: 4cm; text-align: center; font-size: 10pt; color: #666;">
          <p>Fl. 001</p>
        </div>
        
      </div>
    `
  }

  static async listarDocumentosComNumeracao(processoId) {
    try {
      return await NumeracaoDocumentosService.listarDocumentosProcesso(processoId)
    } catch (error) {
      console.error('Erro ao listar documentos com numeração:', error)
      throw error
    }
  }

  static async obterRelatorioNumeracao(processoId) {
    try {
      return await NumeracaoDocumentosService.gerarRelatorioDocumentos(processoId)
    } catch (error) {
      console.error('Erro ao obter relatório de numeração:', error)
      throw error
    }
  }

  static async obterHistoricoTramitacao(processoId) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase
        .from('processos_administrativos')
        .select(`
          id,
          status,
          created_at,
          updated_at
        `)
        .eq('id', processoId)
        .eq('tenant_id', tenantId)
        .single()

      if (error) {
        console.error('Erro ao buscar histórico de tramitação:', error)
        throw error
      }

      // Por enquanto, retornar dados básicos
      // TODO: Implementar tabela de histórico de tramitação completa
      const historico = [
        {
          id: 1,
          data: data.created_at,
          status_anterior: null,
          status_novo: 'em_criacao',
          responsavel: 'Sistema',
          observacoes: 'Processo criado'
        }
      ]

      if (data.updated_at && data.updated_at !== data.created_at) {
        historico.push({
          id: 2,
          data: data.updated_at,
          status_anterior: 'em_criacao',
          status_novo: data.status,
          responsavel: 'Sistema',
          observacoes: 'Status atualizado'
        })
      }

      return historico
    } catch (error) {
      console.error('Erro ao obter histórico de tramitação:', error)
      throw error
    }
  }
}

export default ProcessosAdministrativosService