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
    'rascunho',
    'criado_cpm',           // CPM criou/aprovou o processo (status final do assistente)
    'aguardando_assinatura_orgao', // Aguardando órgão competente assinar
    'assinado_admin',       // Órgão assinou
    'julgamento_ccl',       // CCL analisa
    'aprovado_ccl',         // CCL aprovou
    'aprovado_juridico',    // Jurídico aprovou
    'edital_publicado',     // Edital publicado
    'homologado',           // Processo homologado
    'finalizado',           // Processo finalizado
    
    // STATUS DE DEVOLUÇÃO - Não seguem fluxo linear
    'devolvido_pelo_orgao',    // Devolvido pelo Órgão Administrativo
    'devolvido_pela_ccl',      // Devolvido pela CCL
    'devolvido_pelo_juridico'  // Devolvido pela Assessoria Jurídica
  ]
  
  static FLUXO_DESPADRONIZACAO = [
    'rascunho',
    'criado_cpm_desp',      // CPM criou/aprovou o processo de despadronização (status final do assistente)
    'aguardando_assinatura_orgao_desp', // Aguardando órgão autorizar abertura
    'abertura_autorizada_desp',   // Órgão autorizou abertura
    'aviso_publicado',            // Aviso publicado
    'com_recurso_desp',           // Processo com recursos
    'homologado_desp',            // Processo homologado
    'excluindo_marcas'            // Excluindo marcas do sistema
  ]

  // =====================================================
  // MAPEAMENTO STATUS -> PERFIL RESPONSÁVEL
  // =====================================================
  
  static RESPONSAVEL_POR_STATUS = {
    // PADRONIZAÇÃO
    'rascunho': PerfilUsuarioService.PERFIS.CPM,
    'criado_cpm': PerfilUsuarioService.PERFIS.CPM,           // CPM pode enviar para órgão
    'aguardando_assinatura_orgao': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão deve assinar
    'assinado_admin': PerfilUsuarioService.PERFIS.CCL,       // CCL deve analisar
    'julgamento_ccl': PerfilUsuarioService.PERFIS.CCL,       // CCL deve julgar
    'aprovado_ccl': PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA, // Jurídico deve analisar
    'aprovado_juridico': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão deve homologar
    'edital_publicado': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO,  // Órgão gerencia
    'homologado': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO,        // Órgão gerencia
    
    // STATUS DE DEVOLUÇÃO - CPM deve corrigir e reenviar
    'devolvido_pelo_orgao': PerfilUsuarioService.PERFIS.CPM,     // CPM deve corrigir
    'devolvido_pela_ccl': PerfilUsuarioService.PERFIS.CPM,       // CPM deve corrigir
    'devolvido_pelo_juridico': PerfilUsuarioService.PERFIS.CPM,  // CPM deve corrigir
    
    // DESPADRONIZAÇÃO
    'criado_cpm_desp': PerfilUsuarioService.PERFIS.CPM, // CPM pode enviar para órgão
    'aguardando_assinatura_orgao_desp': PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO, // Órgão deve autorizar
    'abertura_autorizada_desp': PerfilUsuarioService.PERFIS.CCL, // CCL deve publicar aviso
    'aviso_publicado': PerfilUsuarioService.PERFIS.CCL, // CCL gerencia processo
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
          status: proximoStatus,
          data_ultima_tramitacao: new Date().toISOString()
        })
        .eq('id', processoId)
      
      if (errorUpdate) throw errorUpdate
      
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
          data_ultima_tramitacao: new Date().toISOString(),
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
          novoStatus = 'aguardando_assinatura_orgao'
          destinatario = 'Órgão Administrativo'
          break
        case 'devolvido_pela_ccl':
          novoStatus = 'julgamento_ccl'
          destinatario = 'CCL'
          break
        case 'devolvido_pelo_juridico':
          novoStatus = 'aprovado_ccl'
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
          data_ultima_tramitacao: new Date().toISOString(),
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
          status: statusRejeicao,
          data_ultima_tramitacao: new Date().toISOString()
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
   * Obter próximo status na sequência
   */
  static obterProximoStatus(statusAtual, tipoProcesso) {
    const fluxo = tipoProcesso === 'padronizacao' ? this.FLUXO_PADRONIZACAO : this.FLUXO_DESPADRONIZACAO
    const indiceAtual = fluxo.indexOf(statusAtual)
    
    if (indiceAtual === -1 || indiceAtual === fluxo.length - 1) {
      return null // Não há próximo status
    }
    
    return fluxo[indiceAtual + 1]
  }

  /**
   * Verificar se usuário pode tramitar processo
   */
  static async podeUsuarioTramitar(processo) {
    try {
      const perfilUsuario = await PerfilUsuarioService.obterPerfilUsuarioAtual()
      const perfilResponsavel = this.RESPONSAVEL_POR_STATUS[processo.status]
      
      return perfilUsuario.perfil_usuario === perfilResponsavel
    } catch (error) {
      console.error('Erro ao verificar permissão de tramitação:', error)
      return false
    }
  }

  /**
   * Obter ações disponíveis para um processo
   */
  static async obterAcoesDisponiveis(processo) {
    const podeTrampitar = await this.podeUsuarioTramitar(processo)
    
    if (!podeTrampitar) {
      return []
    }
    
    const acoes = []
    const proximoStatus = this.obterProximoStatus(processo.status, processo.tipo_processo)
    
    // Ação de enviar para próxima etapa
    if (proximoStatus) {
      acoes.push({
        tipo: 'ENVIAR',
        label: '🚀 Enviar para Análise',
        descricao: `Enviar para ${this.obterNomeProximaEtapa(proximoStatus)}`,
        cor: 'success'
      })
    }
    
    // Ação de devolver (exceto CPM)
    const perfilUsuario = await PerfilUsuarioService.obterPerfilUsuarioAtual()
    if (perfilUsuario.perfil_usuario !== PerfilUsuarioService.PERFIS.CPM) {
      acoes.push({
        tipo: 'DEVOLVER',
        label: '↩️ Devolver para CPM',
        descricao: 'Devolver processo para correções',
        cor: 'warning'
      })
    }
    
    // Ação de rejeitar
    acoes.push({
      tipo: 'REJEITAR',
      label: '❌ Rejeitar Processo',
      descricao: 'Rejeitar processo definitivamente',
      cor: 'danger'
    })
    
    return acoes
  }

  /**
   * Obter nome da próxima etapa
   */
  static obterNomeProximaEtapa(status) {
    const nomes = {
      // FLUXO PADRONIZAÇÃO
      'aguardando_aprovacao': 'CPM - Aprovação',
      'criado_cpm': 'Órgão Administrativo',
      'aguardando_assinatura_orgao': 'Órgão Administrativo', 
      'assinado_admin': 'CCL - Julgamento',
      'julgamento_ccl': 'CCL - Aprovação',
      'aprovado_ccl': 'Assessoria Jurídica',
      'aprovado_juridico': 'Órgão - Homologação',
      'edital_publicado': 'Homologação Final',
      'homologado': 'Finalização',
      
      // FLUXO DESPADRONIZAÇÃO  
      'criado_cpm_desp': 'Órgão - Autorização',
      'aguardando_assinatura_orgao_desp': 'Órgão Administrativo',
      'abertura_autorizada_desp': 'CCL - Publicação',
      'aviso_publicado': 'Análise de Recursos',
      'com_recurso_desp': 'Assessoria Jurídica',
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

}

export default TramitacaoProcessosService