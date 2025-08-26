import { supabase, getTenantId } from './supabase'
import PerfilUsuarioService from './perfilUsuarioService'
import EmailNotificationService from './emailNotificationService'

/**
 * Serviço para gerenciamento de tramitação de processos administrativos
 */
export class TramitacaoProcessosService {
  
  // =====================================================
  // FLUXOS DE STATUS POR TIPO DE PROCESSO
  // =====================================================
  
  static FLUXO_PADRONIZACAO = [
    'em_criacao',              // Em Criação
    'criado_cpm',              // Criado pela CPM
    'submetido_autoridade',    // Submetido à Autoridade Competente (era: aguardando_assinatura_orgao)
    'abertura_autorizada',     // Abertura Autorizada (era: assinado_admin)
    'edital_chamamento',       // Edital de Chamamento Público
    'analise_juridica',        // Em Análise Jurídica
    'edital_publicado',        // Com Edital Publicado
    'com_impugnacao',          // Com Impugnação ao Edital
    'recebendo_amostras',      // Recebendo Amostras e Documentação
    'avaliacao_cpm',           // Com Avaliação e Relatório da CPM
    'julgamento_ccl',          // Submetido ao Julgamento da CCL
    'ata_ccl',                 // Ata de Julgamento da CCL
    'publicacao_ata',          // Publicação da Ata e Prazo Recursal
    'com_recurso',             // Com Recurso Administrativo
    'homologado',              // Com Homologação
    'expedindo_dcbs',          // Expedindo as DCBs
    'incluindo_marcas',        // Incluindo Marcas no Catálogo
    'finalizado',              // Processo Finalizado
    
    // STATUS DE DEVOLUÇÃO - Não seguem fluxo linear
    'devolvido_pelo_orgao',    // Devolvido pelo Órgão Administrativo
    'devolvido_pela_ccl',      // Devolvido pela CCL
    'devolvido_pelo_juridico'  // Devolvido pela Assessoria Jurídica
  ]
  
  static FLUXO_DESPADRONIZACAO = [
    'em_criacao_desp',            // Em Criação
    'criado_cpm_desp',            // Criado pela CPM
    'submetido_autoridade_desp',  // Submetido à Autoridade Competente
    'abertura_autorizada_desp',   // Abertura Autorizada
    'aviso_publicado_desp',       // Com Aviso Publicado
    'com_recurso_desp',           // Com Recurso Administrativo
    'homologado_desp',            // Com Homologação
    'excluindo_marcas'            // Excluindo Marcas do Catálogo
  ]

  // =====================================================
  // MAPEAMENTO STATUS -> PERFIL RESPONSÁVEL
  // =====================================================
  
  static RESPONSAVEL_POR_STATUS = {
    // PADRONIZAÇÃO - Novos status conforme especificação do cliente
    'em_criacao': PerfilUsuarioService.PERFIS.CPM,
    'criado_cpm': PerfilUsuarioService.PERFIS.CPM,           // CPM pode enviar para órgão
    'submetido_autoridade': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão deve autorizar
    'abertura_autorizada': PerfilUsuarioService.PERFIS.CPM,   // CPM prepara edital
    'edital_chamamento': PerfilUsuarioService.PERFIS.CPM, // CPM publica edital
    'analise_juridica': PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA, // Jurídico analisa
    'edital_publicado': PerfilUsuarioService.PERFIS.CPM,      // CPM gerencia publicação
    'com_impugnacao': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão decide impugnações conforme cliente
    'recebendo_amostras': PerfilUsuarioService.PERFIS.CPM,    // CPM recebe amostras
    'avaliacao_cpm': PerfilUsuarioService.PERFIS.CPM,         // CPM avalia e faz relatório
    'julgamento_ccl': PerfilUsuarioService.PERFIS.CCL,        // CCL julga
    'ata_ccl': PerfilUsuarioService.PERFIS.CCL,               // CCL emite ata
    'publicacao_ata': PerfilUsuarioService.PERFIS.CCL, // CCL publica ata conforme cliente
    'com_recurso': PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA, // Jurídico analisa recursos
    'homologado': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão homologa
    'expedindo_dcbs': PerfilUsuarioService.PERFIS.CPM,        // CPM expede DCBs
    'incluindo_marcas': PerfilUsuarioService.PERFIS.CPM,      // CPM inclui no catálogo
    'finalizado': null,                                       // Processo finalizado - nenhum perfil pode alterar
    
    // STATUS DE DEVOLUÇÃO - CPM deve corrigir e reenviar
    'devolvido_pelo_orgao': PerfilUsuarioService.PERFIS.CPM,     // CPM deve corrigir
    'devolvido_pela_ccl': PerfilUsuarioService.PERFIS.CPM,       // CPM deve corrigir
    'devolvido_pelo_juridico': PerfilUsuarioService.PERFIS.CPM,  // CPM deve corrigir
    
    // STATUS ANTIGOS (compatibilidade)
    'assinado_admin': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Status antigo ainda pode existir
    'aguardando_assinatura_orgao': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Status antigo ainda pode existir
    
    // DESPADRONIZAÇÃO - Novos status conforme especificação do cliente
    'em_criacao_desp': PerfilUsuarioService.PERFIS.CPM,
    'criado_cpm_desp': PerfilUsuarioService.PERFIS.CPM, // CPM pode enviar para órgão
    'submetido_autoridade_desp': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão deve autorizar
    'abertura_autorizada_desp': PerfilUsuarioService.PERFIS.CPM, // CPM publica aviso
    'aviso_publicado_desp': PerfilUsuarioService.PERFIS.CPM, // CPM gerencia processo
    'com_recurso_desp': PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA, // Jurídico analisa recursos
    'homologado_desp': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão homologa
    'excluindo_marcas': PerfilUsuarioService.PERFIS.CPM // CPM exclui marcas
  }

  // =====================================================
  // TRAMITAÇÃO DE PROCESSOS
  // =====================================================

  /**
   * Enviar processo para próxima etapa
   */
  static async enviarProcesso(processoId, observacoes = '') {
    try {
      console.log('🚀 Enviando processo para próxima etapa:', processoId)
      
      // Obter dados do processo
      const { data: processo, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('id', processoId)
        .single()
      
      if (errorProcesso) throw errorProcesso
      
      // Determinar próximo status
      const proximoStatus = this.obterProximoStatus(processo.status, processo.tipo_processo)
      
      if (!proximoStatus) {
        throw new Error(`Não há próxima etapa disponível para este processo. Status atual: ${processo.status}`)
      }
      
      // Atualizar status do processo
      const { error: errorUpdate } = await supabase
        .from('processos_administrativos')
        .update({
          status: proximoStatus
        })
        .eq('id', processoId)
      
      if (errorUpdate) throw errorUpdate
      
      // ✨ LÓGICA ESPECIAL: Inclusão automática no catálogo
      if (proximoStatus === 'incluindo_marcas') {
        console.log('🎯 Status "incluindo_marcas" detectado - incluindo produtos no catálogo automaticamente')
        await this.incluirProdutosNoCatalogo(processoId)
        
        // Após incluir no catálogo, finalizar automaticamente o processo
        console.log('🏁 Finalizando processo automaticamente após inclusão no catálogo')
        const { error: errorFinalizar } = await supabase
          .from('processos_administrativos')
          .update({
            status: 'finalizado',
            finalizado_em: new Date().toISOString()
          })
          .eq('id', processoId)
        
        if (errorFinalizar) {
          console.error('❌ Erro ao finalizar processo automaticamente:', errorFinalizar)
        } else {
          // Registrar tramitação para finalização
          await this.registrarTramitacao(processoId, 'incluindo_marcas', 'finalizado', 'FINALIZACAO_AUTOMATICA', 'Processo finalizado automaticamente após inclusão das marcas no catálogo')
          console.log('✅ Processo finalizado automaticamente')
        }
      }
      
      // Registrar histórico de tramitação
      await this.registrarTramitacao(processoId, processo.status, proximoStatus, 'ENVIADO', observacoes)
      
      // Enviar notificação por email
      await EmailNotificationService.enviarNotificacaoTramitacao(processoId, processo.status, proximoStatus, observacoes)
      
      console.log(`✅ Processo ${processoId} enviado: ${processo.status} → ${proximoStatus}`)
      
      return {
        sucesso: true,
        statusAnterior: processo.status,
        statusNovo: proximoStatus,
        proximoResponsavel: this.RESPONSAVEL_POR_STATUS[proximoStatus]
      }
      
    } catch (error) {
      console.error('❌ Erro ao enviar processo:', error)
      throw error
    }
  }

  /**
   * Enviar processo para status específico (tramitação flexível)
   */
  static async enviarProcessoFlexivel(processoId, statusDestino, tipoFlexivel, observacoes = '') {
    try {
      console.log('🔄 Enviando processo flexível:', processoId, statusDestino, tipoFlexivel)
      
      // Obter dados do processo
      const { data: processo, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('id', processoId)
        .single()
      
      if (errorProcesso) throw errorProcesso
      
      // Atualizar status do processo
      const { error: errorUpdate } = await supabase
        .from('processos_administrativos')
        .update({
          status: statusDestino
        })
        .eq('id', processoId)
      
      if (errorUpdate) throw errorUpdate
      
      // ✨ LÓGICA ESPECIAL: Inclusão automática no catálogo
      if (statusDestino === 'incluindo_marcas') {
        console.log('🎯 Status "incluindo_marcas" detectado no envio flexível - incluindo produtos no catálogo automaticamente')
        await this.incluirProdutosNoCatalogo(processoId)
        
        // Após incluir no catálogo, finalizar automaticamente o processo
        console.log('🏁 Finalizando processo automaticamente após inclusão no catálogo (tramitação flexível)')
        const { error: errorFinalizar } = await supabase
          .from('processos_administrativos')
          .update({
            status: 'finalizado',
            finalizado_em: new Date().toISOString()
          })
          .eq('id', processoId)
        
        if (errorFinalizar) {
          console.error('❌ Erro ao finalizar processo automaticamente:', errorFinalizar)
        } else {
          // Registrar tramitação para finalização
          await this.registrarTramitacao(processoId, 'incluindo_marcas', 'finalizado', 'FINALIZACAO_AUTOMATICA_FLEXIVEL', 'Processo finalizado automaticamente após inclusão das marcas no catálogo (tramitação flexível)')
          console.log('✅ Processo finalizado automaticamente (tramitação flexível)')
        }
      }
      
      // Registrar histórico de tramitação
      await this.registrarTramitacao(
        processoId, 
        processo.status, 
        statusDestino, 
        `FLEXÍVEL_${tipoFlexivel}`, 
        observacoes
      )
      
      // Enviar notificação por email
      await EmailNotificationService.enviarNotificacaoTramitacao(
        processoId, 
        processo.status, 
        statusDestino, 
        observacoes
      )
      
      console.log(`✅ Processo ${processoId} tramitado flexível: ${processo.status} → ${statusDestino} (${tipoFlexivel})`)
      
      return {
        sucesso: true,
        statusAnterior: processo.status,
        statusNovo: statusDestino,
        tipoFlexivel: tipoFlexivel,
        proximoResponsavel: this.RESPONSAVEL_POR_STATUS[statusDestino]
      }
      
    } catch (error) {
      console.error('❌ Erro ao enviar processo flexível:', error)
      throw error
    }
  }

  /**
   * Devolver processo para etapa anterior com status específico de devolução
   */
  static async devolverProcesso(processoId, motivo, observacoes = '') {
    try {
      console.log('↩️ Devolvendo processo:', processoId)
      
      // Obter dados do processo
      const { data: processo, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('id', processoId)
        .single()
      
      if (errorProcesso) throw errorProcesso
      
      // Obter perfil do usuário que está devolvendo
      const perfilUsuario = await PerfilUsuarioService.obterPerfilUsuarioAtual()
      
      // Determinar status de devolução baseado no perfil que devolveu
      let statusDevolucao
      let motivoCompleto = motivo
      
      switch (perfilUsuario.perfil_usuario) {
        case PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO:
          statusDevolucao = 'devolvido_pelo_orgao'
          motivoCompleto = `DEVOLVIDO PELO ÓRGÃO ADMINISTRATIVO: ${motivo}`
          break
        case PerfilUsuarioService.PERFIS.CCL:
          statusDevolucao = 'devolvido_pela_ccl'
          motivoCompleto = `DEVOLVIDO PELA CCL: ${motivo}`
          break
        case PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA:
          statusDevolucao = 'devolvido_pelo_juridico'
          motivoCompleto = `DEVOLVIDO PELA ASSESSORIA JURÍDICA: ${motivo}`
          break
        default:
          // Fallback para o sistema antigo se o perfil não for reconhecido
          statusDevolucao = processo.tipo_processo === 'padronizacao' ? 'criado_cpm' : 'criado_cpm_desp'
          motivoCompleto = `DEVOLVIDO: ${motivo}`
      }
      
      // Atualizar status do processo com campos de devolução
      const { error: errorUpdate } = await supabase
        .from('processos_administrativos')
        .update({
          status: statusDevolucao,
          motivo_devolucao: motivoCompleto,
          observacoes_devolucao: observacoes,
          devolvido_por: perfilUsuario.perfil_usuario,
          data_devolucao: new Date().toISOString()
        })
        .eq('id', processoId)
      
      if (errorUpdate) throw errorUpdate
      
      // Registrar histórico de tramitação
      await this.registrarTramitacao(processoId, processo.status, statusDevolucao, 'DEVOLVIDO', `${motivoCompleto}. ${observacoes}`)
      
      // Enviar notificação por email
      await EmailNotificationService.enviarNotificacaoTramitacao(processoId, processo.status, statusDevolucao, `${motivoCompleto}. ${observacoes}`)
      
      console.log(`↩️ Processo ${processoId} devolvido: ${processo.status} → ${statusDevolucao}`)
      
      return {
        sucesso: true,
        statusAnterior: processo.status,
        statusNovo: statusDevolucao,
        motivo: motivoCompleto,
        devolvido_por: perfilUsuario.perfil_usuario
      }
      
    } catch (error) {
      console.error('❌ Erro ao devolver processo:', error)
      throw error
    }
  }
  
  /**
   * Reenviar processo devolvido após correções
   */
  static async reenviarProcessoDevolvido(processoId, observacoes = '') {
    try {
      console.log('🔄 Reenviando processo devolvido:', processoId)
      
      // Obter dados do processo
      const { data: processo, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('id', processoId)
        .single()
      
      if (errorProcesso) throw errorProcesso
      
      // Determinar para onde reenviar baseado no status de devolução
      let novoStatus
      let destinatario
      
      switch (processo.status) {
        case 'devolvido_pelo_orgao':
          novoStatus = 'submetido_autoridade'
          destinatario = 'Órgão Administrativo'
          break
        case 'devolvido_pela_ccl':
          novoStatus = 'julgamento_ccl'
          destinatario = 'CCL'
          break
        case 'devolvido_pelo_juridico':
          novoStatus = 'analise_juridica'
          destinatario = 'Assessoria Jurídica'
          break
        default:
          throw new Error(`Status de devolução não reconhecido: ${processo.status}`)
      }
      
      // Atualizar status do processo e limpar dados de devolução
      const { error: errorUpdate } = await supabase
        .from('processos_administrativos')
        .update({
          status: novoStatus,
          motivo_devolucao: null,
          observacoes_devolucao: null,
          devolvido_por: null,
          data_devolucao: null
        })
        .eq('id', processoId)
      
      if (errorUpdate) throw errorUpdate
      
      // Registrar histórico de tramitação
      await this.registrarTramitacao(
        processoId, 
        processo.status, 
        novoStatus, 
        'REENVIADO', 
        `Processo reenviado após correções. ${observacoes}`
      )
      
      // Enviar notificação por email
      await EmailNotificationService.enviarNotificacaoTramitacao(
        processoId, 
        processo.status, 
        novoStatus, 
        `Processo reenviado após correções para ${destinatario}. ${observacoes}`
      )
      
      console.log(`🔄 Processo ${processoId} reenviado: ${processo.status} → ${novoStatus}`)
      
      return {
        sucesso: true,
        statusAnterior: processo.status,
        statusNovo: novoStatus,
        destinatario: destinatario
      }
      
    } catch (error) {
      console.error('❌ Erro ao reenviar processo:', error)
      throw error
    }
  }

  /**
   * Rejeitar processo
   */
  static async rejeitarProcesso(processoId, motivo, observacoes = '') {
    try {
      console.log('❌ Rejeitando processo:', processoId)
      
      // Obter dados do processo
      const { data: processo, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('id', processoId)
        .single()
      
      if (errorProcesso) throw errorProcesso
      
      // Determinar perfil atual para definir tipo de rejeição
      const perfilAtual = await PerfilUsuarioService.obterPerfilUsuarioAtual()
      let statusRejeicao
      
      switch (perfilAtual.perfil_usuario) {
        case PerfilUsuarioService.PERFIS.CPM:
          statusRejeicao = 'rejeitado_cpm'
          break
        case PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO:
          statusRejeicao = 'rejeitado_admin'
          break
        case PerfilUsuarioService.PERFIS.CCL:
          statusRejeicao = 'rejeitado_ccl'
          break
        case PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA:
          statusRejeicao = 'rejeitado_juridico'
          break
        default:
          statusRejeicao = 'rejeitado_final'
      }
      
      // Atualizar status do processo
      const { error: errorUpdate } = await supabase
        .from('processos_administrativos')
        .update({
          status: statusRejeicao
        })
        .eq('id', processoId)
      
      if (errorUpdate) throw errorUpdate
      
      // Registrar histórico de tramitação
      await this.registrarTramitacao(processoId, processo.status, statusRejeicao, 'REJEITADO', `${motivo}. ${observacoes}`)
      
      // Enviar notificação por email
      await EmailNotificationService.enviarNotificacaoTramitacao(processoId, processo.status, statusRejeicao, `${motivo}. ${observacoes}`)
      
      console.log(`❌ Processo ${processoId} rejeitado: ${processo.status} → ${statusRejeicao}`)
      
      return {
        sucesso: true,
        statusAnterior: processo.status,
        statusNovo: statusRejeicao,
        motivo: motivo
      }
      
    } catch (error) {
      console.error('❌ Erro ao rejeitar processo:', error)
      throw error
    }
  }

  // =====================================================
  // UTILITÁRIOS
  // =====================================================

  /**
   * Obter próximo status na sequência (com flexibilidade para circunstâncias especiais)
   */
  static obterProximoStatus(statusAtual, tipoProcesso) {
    // Converter status antigos para novos equivalentes
    const statusConvertido = this.converterStatusAntigo(statusAtual)
    
    // Se já está finalizado, não há próximo status
    if (statusConvertido === 'finalizado') {
      return null
    }
    
    const fluxo = tipoProcesso === 'padronizacao' ? this.FLUXO_PADRONIZACAO : this.FLUXO_DESPADRONIZACAO
    const indiceAtual = fluxo.indexOf(statusConvertido)
    
    if (indiceAtual === -1 || indiceAtual === fluxo.length - 1) {
      return null // Não há próximo status
    }
    
    return fluxo[indiceAtual + 1]
  }

  /**
   * Converter status antigos para novos equivalentes
   */
  static converterStatusAntigo(status) {
    const conversoes = {
      'assinado_admin': 'abertura_autorizada',
      'aguardando_assinatura_orgao': 'submetido_autoridade'
    }
    
    return conversoes[status] || status
  }

  /**
   * Obter opções flexíveis de tramitação baseado no status atual
   * Permite "saltos" conforme circunstâncias do processo
   */
  static obterOpcoesFlexiveis(statusAtual, tipoProcesso) {
    const opcoes = []
    
    // Próximo status normal
    const proximoNormal = this.obterProximoStatus(statusAtual, tipoProcesso)
    if (proximoNormal) {
      opcoes.push({
        status: proximoNormal,
        tipo: 'NORMAL',
        descricao: this.obterNomeProximaEtapa(proximoNormal)
      })
    }
    
    // Opções flexíveis baseadas em circunstâncias
    switch (statusAtual) {
      case 'edital_publicado':
        // Pode ir direto para impugnação OU para recebimento de amostras
        opcoes.push({
          status: 'com_impugnacao',
          tipo: 'IMPUGNACAO',
          descricao: 'Processar Impugnação ao Edital'
        })
        opcoes.push({
          status: 'recebendo_amostras',
          tipo: 'SEM_IMPUGNACAO', 
          descricao: 'Prosseguir para Recebimento de Amostras'
        })
        break
        
      case 'com_impugnacao':
        // Após decidir impugnação, pode voltar para correções OU prosseguir
        opcoes.push({
          status: 'analise_juridica',
          tipo: 'CORRIGIR_EDITAL',
          descricao: 'Voltar para Correção do Edital'
        })
        opcoes.push({
          status: 'recebendo_amostras',
          tipo: 'IMPUGNACAO_NEGADA',
          descricao: 'Impugnação Negada - Prosseguir'
        })
        break
        
      case 'ata_ccl':
        // CCL pode publicar diretamente OU enviar para órgão homologar
        opcoes.push({
          status: 'publicacao_ata',
          tipo: 'PUBLICAR_DIRETA',
          descricao: 'CCL Publica Ata Diretamente'
        })
        opcoes.push({
          status: 'homologado',
          tipo: 'HOMOLOGACAO_DIRETA',
          descricao: 'Enviar para Homologação do Órgão'
        })
        break
        
      case 'publicacao_ata':
        // Após publicar, pode ter recurso OU homologar direto
        opcoes.push({
          status: 'com_recurso',
          tipo: 'COM_RECURSO',
          descricao: 'Processar Recurso Administrativo'
        })
        opcoes.push({
          status: 'homologado',
          tipo: 'SEM_RECURSO',
          descricao: 'Homologar (sem recursos)'
        })
        break
    }
    
    return opcoes
  }

  /**
   * Verificar se usuário pode tramitar processo
   */
  static async podeUsuarioTramitar(processo) {
    try {
      // Se o processo está finalizado, ninguém pode tramitar
      if (processo.status === 'finalizado') {
        console.log(`🏁 Processo ${processo.numero_processo} está finalizado - tramitação bloqueada`)
        return false
      }
      
      const perfilUsuario = await PerfilUsuarioService.obterPerfilUsuarioAtual()
      const perfilResponsavel = this.RESPONSAVEL_POR_STATUS[processo.status]
      
      // Se o perfil responsável é null (como no caso de finalizado), ninguém pode tramitar
      if (perfilResponsavel === null) {
        console.log(`🚫 Status ${processo.status} não permite tramitação por nenhum perfil`)
        return false
      }
      
      // Log específico para o status "Submetido à Autoridade Competente"
      if (processo.status === 'submetido_autoridade') {
        console.log(`🚨 DEBUG ESPECÍFICO - Status "submetido_autoridade":`, {
          statusProcesso: processo.status,
          perfilUsuario: perfilUsuario.perfil_usuario,
          perfilResponsavel: perfilResponsavel,
          perfilEsperado: PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO,
          podeTrampitar: perfilUsuario.perfil_usuario === perfilResponsavel,
          statusExisteNoMapeamento: !!this.RESPONSAVEL_POR_STATUS[processo.status],
          tipoPerfilUsuario: typeof perfilUsuario.perfil_usuario,
          tipoPerfilResponsavel: typeof perfilResponsavel,
          constante_ORGAO: PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO,
          mapeamentoCompleto: this.RESPONSAVEL_POR_STATUS
        })
      }
      
      console.log(`🔍 DEBUG - podeUsuarioTramitar para processo ${processo.numero_processo}:`, {
        statusProcesso: processo.status,
        perfilUsuario: perfilUsuario.perfil_usuario,
        perfilResponsavel: perfilResponsavel,
        podeTrampitar: perfilUsuario.perfil_usuario === perfilResponsavel
      })
      
      return perfilUsuario.perfil_usuario === perfilResponsavel
    } catch (error) {
      console.error('Erro ao verificar permissão de tramitação:', error)
      return false
    }
  }

  /**
   * Obter ações disponíveis para um processo (com flexibilidade)
   */
  static async obterAcoesDisponiveis(processo) {
    console.log(`🔍 DEBUG - obterAcoesDisponiveis iniciado para processo ${processo.numero_processo}`)
    
    const podeTrampitar = await this.podeUsuarioTramitar(processo)
    
    if (!podeTrampitar) {
      console.log(`🔍 DEBUG - Usuário NÃO pode tramitar processo ${processo.numero_processo} - retornando array vazio`)
      return []
    }
    
    console.log(`🔍 DEBUG - Usuário PODE tramitar processo ${processo.numero_processo} - continuando...`)
    
    const acoes = []
    const perfilUsuario = await PerfilUsuarioService.obterPerfilUsuarioAtual()
    
    // Obter opções flexíveis de tramitação
    const opcoesFlexiveis = this.obterOpcoesFlexiveis(processo.status, processo.tipo_processo)
    console.log(`🔍 DEBUG - Opções flexíveis para ${processo.status}:`, opcoesFlexiveis)
    
    // Se há opções flexíveis, criar ações específicas
    if (opcoesFlexiveis.length > 0) {
      console.log(`🔍 DEBUG - Criando ${opcoesFlexiveis.length} ações flexíveis`)
      opcoesFlexiveis.forEach(opcao => {
        let label = '🚀 '
        let cor = 'primary'
        
        switch (opcao.tipo) {
          case 'IMPUGNACAO':
            label = '⚠️ '
            cor = 'warning'
            break
          case 'PUBLICAR_DIRETA':
            label = '📢 '
            cor = 'success'
            break
          case 'COM_RECURSO':
            label = '📋 '
            cor = 'info'
            break
          case 'CORRIGIR_EDITAL':
            label = '🔧 '
            cor = 'warning'
            break
        }
        
        acoes.push({
          tipo: 'ENVIAR_FLEXIVEL',
          statusDestino: opcao.status,
          tipoFlexivel: opcao.tipo,
          label: label + opcao.descricao,
          descricao: opcao.descricao,
          cor: cor
        })
      })
    } else {
      // Fluxo normal
      const proximoStatus = this.obterProximoStatus(processo.status, processo.tipo_processo)
      console.log(`🔍 DEBUG - Próximo status para ${processo.status}:`, proximoStatus)
      
      if (proximoStatus) {
        console.log(`🔍 DEBUG - Criando ação ENVIAR normal`)
        acoes.push({
          tipo: 'ENVIAR',
          label: '🚀 Enviar para Análise',
          descricao: `Enviar para ${this.obterNomeProximaEtapa(proximoStatus)}`,
          cor: 'success'
        })
      } else {
        console.log(`🔍 DEBUG - NÃO há próximo status - não criando ação de envio`)
      }
    }
    
    // Ação de devolver (exceto CPM)
    if (perfilUsuario.perfil_usuario !== PerfilUsuarioService.PERFIS.CPM) {
      console.log(`🔍 DEBUG - Adicionando ação DEVOLVER (perfil não é CPM)`)
      acoes.push({
        tipo: 'DEVOLVER',
        label: '↩️ Devolver para CPM',
        descricao: 'Devolver processo para correções',
        cor: 'warning'
      })
    } else {
      console.log(`🔍 DEBUG - NÃO adicionando ação DEVOLVER (perfil é CPM)`)
    }
    
    // Ação de rejeitar
    console.log(`🔍 DEBUG - Adicionando ação REJEITAR`)
    acoes.push({
      tipo: 'REJEITAR',
      label: '❌ Rejeitar Processo',
      descricao: 'Rejeitar processo definitivamente',
      cor: 'danger'
    })
    
    console.log(`🔍 DEBUG - obterAcoesDisponiveis finalizando para processo ${processo.numero_processo} com ${acoes.length} ações:`, acoes)
    return acoes
  }

  /**
   * Obter nome da próxima etapa
   */
  static obterNomeProximaEtapa(status) {
    const nomes = {
      // FLUXO PADRONIZAÇÃO - Novos status conforme cliente
      'em_criacao': 'CPM - Criação',
      'criado_cpm': 'Autoridade Competente',
      'submetido_autoridade': 'Autorização de Abertura',
      'abertura_autorizada': 'Edital de Chamamento',
      'edital_chamamento': 'Análise Jurídica',
      'analise_juridica': 'Publicação do Edital',
      'edital_publicado': 'Recebimento de Impugnações',
      'com_impugnacao': 'Recebimento de Amostras',
      'recebendo_amostras': 'Avaliação CPM',
      'avaliacao_cpm': 'Julgamento CCL',
      'julgamento_ccl': 'Ata de Julgamento',
      'ata_ccl': 'Publicação da Ata',
      'publicacao_ata': 'Prazo Recursal',
      'com_recurso': 'Homologação',
      'homologado': 'Expedição DCBs',
      'expedindo_dcbs': 'Inclusão no Catálogo',
      'incluindo_marcas': 'Finalização do Processo',
      
      // FLUXO DESPADRONIZAÇÃO - Novos status conforme cliente
      'em_criacao_desp': 'CPM - Criação',
      'criado_cpm_desp': 'Autoridade Competente',
      'submetido_autoridade_desp': 'Autorização de Abertura',
      'abertura_autorizada_desp': 'Publicação de Aviso',
      'aviso_publicado_desp': 'Prazo Recursal',
      'com_recurso_desp': 'Homologação',
      'homologado_desp': 'Exclusão de Marcas',
      
      // STATUS DE DEVOLUÇÃO - Reenvios
      'devolvido_pelo_orgao': 'Reenviar para Órgão',
      'devolvido_pela_ccl': 'Reenviar para CCL',
      'devolvido_pelo_juridico': 'Reenviar para Jurídico'
    }
    
    return nomes[status] || 'Próxima Etapa'
  }

  /**
   * Obter nome descritivo do botão de tramitação
   */
  static obterNomeBotaoTramitacao(statusAtual, tipoProcesso) {
    const proximoStatus = this.obterProximoStatus(statusAtual, tipoProcesso)
    if (!proximoStatus) return 'Tramitar Processo'
    
    const proximaEtapa = this.obterNomeProximaEtapa(proximoStatus)
    return `Tramitar para ${proximaEtapa}`
  }

  /**
   * Registrar histórico de tramitação
   */
  static async registrarTramitacao(processoId, statusAnterior, statusNovo, acao, observacoes = '') {
    try {
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user
      const tenantId = await getTenantId()
      
      const { error } = await supabase
        .from('historico_tramitacao')
        .insert([{
          processo_id: processoId,
          tenant_id: tenantId,
          status_anterior: statusAnterior,
          status_novo: statusNovo,
          acao: acao,
          observacoes: observacoes,
          usuario_id: user?.id,
          data_tramitacao: new Date().toISOString()
        }])
      
      if (error) {
        console.warn('Erro ao registrar histórico (tabela pode não existir):', error)
        // Não bloqueia a tramitação se não conseguir registrar histórico
      }
    } catch (error) {
      console.warn('Erro ao registrar histórico:', error)
    }
  }

  /**
   * Incluir produtos do processo no catálogo (público e de marcas)
   * Chamado automaticamente quando o status muda para 'incluindo_marcas'
   */
  static async incluirProdutosNoCatalogo(processoId) {
    try {
      console.log('🎯 Iniciando inclusão de produtos no catálogo para processo:', processoId)
      
      const tenantId = await getTenantId()
      
      // 1. Buscar todos os produtos do processo (assumindo que se chegou até aqui, já foram aprovados)
      const { data: produtosProcesso, error: errorProdutos } = await supabase
        .from('produtos_prequalificacao')
        .select('*')
        .eq('processo_id', processoId)
        .eq('tenant_id', tenantId)
      
      if (errorProdutos) throw errorProdutos
      
      if (!produtosProcesso || produtosProcesso.length === 0) {
        console.log('⚠️ Nenhum produto encontrado no processo')
        return
      }
      
      // Filtrar produtos aprovados se o campo existir
      const produtosAprovados = produtosProcesso.filter(produto => {
        // Se tem campo aprovado_em, considera aprovado
        if (produto.aprovado_em) return true
        // Se não tem campo de aprovação, considera que todos estão aprovados no final do processo
        return true
      })
      
      console.log(`📦 Encontrados ${produtosAprovados.length} produtos para inclusão no catálogo`)
      
      let produtosIncluidos = 0
      
      for (const produtoPrequalificacao of produtosAprovados) {
        // Na tabela produtos_prequalificacao, o campo pode ser 'produto_id' ou outro
        const produtoId = produtoPrequalificacao.produto_id || produtoPrequalificacao.id
        
        if (!produtoId) {
          console.warn(`⚠️ ID do produto não encontrado na pré-qualificação ${produtoPrequalificacao.id}`)
          console.log('Dados da pré-qualificação:', produtoPrequalificacao)
          continue
        }
        
        try {
          // 2. Se produto_id existe, buscar na tabela produtos
          if (produtoPrequalificacao.produto_id) {
            const { data: produto, error: errorBuscarProduto } = await supabase
              .from('produtos')
              .select('id, nome, tenant_id')
              .eq('id', produtoPrequalificacao.produto_id)
              .eq('tenant_id', tenantId)
              .single()
            
            if (errorBuscarProduto || !produto) {
              console.warn(`⚠️ Produto ${produtoPrequalificacao.produto_id} não encontrado na tabela produtos`)
            } else {
              // 3. Atualizar status do produto para "homologado"
              const { error: errorAtualizarProduto } = await supabase
                .from('produtos')
                .update({
                  status: 'homologado'
                })
                .eq('id', produto.id)
                .eq('tenant_id', tenantId)
              
              if (errorAtualizarProduto) {
                console.error(`❌ Erro ao homologar produto ${produto.id}:`, errorAtualizarProduto)
              } else {
                produtosIncluidos++
                console.log(`✅ Produto homologado: ${produto.nome}`)
              }
            }
          } else {
            // Verificar se já existe produto com as mesmas características para evitar duplicatas
            const nomeProduto = produtoPrequalificacao.nome_produto || 'Produto sem nome'
            const marca = produtoPrequalificacao.marca || ''
            const modelo = produtoPrequalificacao.modelo || ''
            const fabricante = produtoPrequalificacao.fabricante || ''
            
            const { data: produtoExistente, error: errorBuscar } = await supabase
              .from('produtos')
              .select('id, nome, status')
              .eq('tenant_id', tenantId)
              .eq('nome', nomeProduto)
              .eq('marca', marca)
              .eq('modelo', modelo)
              .eq('fabricante', fabricante)
              .maybeSingle()
            
            if (errorBuscar && errorBuscar.code !== 'PGRST116') {
              console.error(`❌ Erro ao verificar produto existente:`, errorBuscar)
            } else if (produtoExistente) {
              console.log(`⚠️ Produto já existe no catálogo: ${produtoExistente.nome}`)
              // Apenas atualizar status se necessário
              if (produtoExistente.status !== 'homologado') {
                const { error: errorAtualizar } = await supabase
                  .from('produtos')
                  .update({ status: 'homologado' })
                  .eq('id', produtoExistente.id)
                
                if (!errorAtualizar) {
                  produtosIncluidos++
                  console.log(`✅ Status do produto atualizado para homologado: ${produtoExistente.nome}`)
                }
              } else {
                console.log(`ℹ️ Produto já está homologado: ${produtoExistente.nome}`)
              }
            } else {
              // Verificar se existe produto aprovado com DCB para copiar informações
              const { data: produtoComDCB, error: errorDCB } = await supabase
                .from('produtos')
                .select('numero_dcb, validade_dcb')
                .eq('tenant_id', tenantId)
                .eq('nome', nomeProduto)
                .eq('marca', marca)
                .eq('modelo', modelo)
                .eq('fabricante', fabricante)
                .eq('status', 'aprovado')
                .not('numero_dcb', 'is', null)
                .maybeSingle()
              
              // Criar novo produto no catálogo apenas se não existir
              const novoProduto = {
                nome: nomeProduto,
                marca: marca,
                modelo: modelo,
                fabricante: fabricante,
                cnpj: produtoPrequalificacao.cnpj_fornecedor || produtoPrequalificacao.cnpj || '00.000.000/0000-00',
                status: 'homologado',
                tenant_id: tenantId
              }
              
              // Se encontrou produto com DCB, copiar as informações
              if (produtoComDCB) {
                novoProduto.numero_dcb = produtoComDCB.numero_dcb
                novoProduto.validade_dcb = produtoComDCB.validade_dcb
                console.log(`📋 DCB copiado para produto homologado: ${produtoComDCB.numero_dcb}`)
              }
              
              const { error: errorCriarProduto } = await supabase
                .from('produtos')
                .insert([novoProduto])
              
              if (errorCriarProduto) {
                console.error(`❌ Erro ao criar produto no catálogo:`, errorCriarProduto)
              } else {
                produtosIncluidos++
                const dcbInfo = novoProduto.numero_dcb ? ` (com DCB ${novoProduto.numero_dcb})` : ''
                console.log(`✅ Novo produto criado no catálogo: ${novoProduto.nome}${dcbInfo}`)
              }
            }
          }
          
        } catch (error) {
          console.error(`❌ Erro ao processar produto:`, error)
        }
      }
      
      console.log(`🎉 Inclusão no catálogo concluída:`)
      console.log(`   📦 Produtos homologados: ${produtosIncluidos}`)
      
      // 3. Registrar log da operação
      await this.registrarTramitacao(
        processoId, 
        'expedindo_dcbs', 
        'incluindo_marcas', 
        'INCLUSAO_CATALOGO', 
        `${produtosIncluidos} produtos homologados e incluídos automaticamente no catálogo`
      )
      
    } catch (error) {
      console.error('❌ Erro ao incluir produtos no catálogo:', error)
      throw new Error(`Falha na inclusão automática no catálogo: ${error.message}`)
    }
  }

  /**
   * 🔧 MÉTODO TEMPORÁRIO: Processar manualmente inclusão no catálogo para processos já tramitados
   * Usar apenas para corrigir processo 001/2025 que já foi tramitado mas não teve inclusão automática
   */
  static async processarInclusaoManual(processoId) {
    try {
      console.log('🔧 PROCESSAMENTO MANUAL - Incluindo produtos no catálogo para processo:', processoId)
      
      // Verificar se processo está em incluindo_marcas
      const { data: processo, error: errorProcesso } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('id', processoId)
        .single()
      
      if (errorProcesso) throw errorProcesso
      
      if (processo.status !== 'incluindo_marcas') {
        throw new Error(`Processo deve estar em "incluindo_marcas". Status atual: ${processo.status}`)
      }
      
      console.log(`✅ Processo ${processo.numero_processo} confirmado em status "incluindo_marcas"`)
      
      // Executar inclusão no catálogo
      await this.incluirProdutosNoCatalogo(processoId)
      
      console.log('🎉 Processamento manual concluído com sucesso!')
      
    } catch (error) {
      console.error('❌ Erro no processamento manual:', error)
      throw error
    }
  }


}

export default TramitacaoProcessosService