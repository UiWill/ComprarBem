import { supabase, getTenantId } from './supabase'

export class EmailNotificationService {
  
  // =====================================================
  // CONFIGURAÇÃO DE TEMPLATES DE EMAIL
  // =====================================================

  static obterTemplateEmail(tipoNotificacao) {
    const templates = {
      'processo_tramitado': {
        assunto: 'Processo #{numeroProcesso} foi tramitado para seu setor',
        template: `
          <h2>🏛️ Notificação de Tramitação de Processo</h2>
          <p><strong>Processo:</strong> #{numeroProcesso}</p>
          <p><strong>Tipo:</strong> #{tipoProcesso}</p>
          <p><strong>Status Atual:</strong> #{statusAtual}</p>
          <p><strong>Órgão:</strong> #{nomeOrgao}</p>
          <hr>
          <p><strong>Ação Necessária:</strong> #{acaoNecessaria}</p>
          <p><strong>Observações:</strong> #{observacoes}</p>
          <hr>
          <p>Acesse o sistema para processar esta solicitação.</p>
          <p><em>Sistema Comprar Bem - Processos Administrativos</em></p>
        `
      },
      'processo_pendente': {
        assunto: 'Lembrete: Processo #{numeroProcesso} aguarda sua análise',
        template: `
          <h2>⏰ Lembrete de Processo Pendente</h2>
          <p>O processo <strong>#{numeroProcesso}</strong> está aguardando sua análise há #{diasPendente} dias.</p>
          <p><strong>Status:</strong> #{statusAtual}</p>
          <p><strong>Órgão:</strong> #{nomeOrgao}</p>
          <hr>
          <p>Por favor, acesse o sistema para dar andamento ao processo.</p>
          <p><em>Sistema Comprar Bem - Processos Administrativos</em></p>
        `
      },
      'processo_aprovado': {
        assunto: 'Processo #{numeroProcesso} foi aprovado/homologado',
        template: `
          <h2>✅ Processo Aprovado/Homologado</h2>
          <p>O processo <strong>#{numeroProcesso}</strong> foi aprovado com sucesso!</p>
          <p><strong>Status Final:</strong> #{statusAtual}</p>
          <p><strong>Responsável:</strong> #{responsavelAprovacao}</p>
          <hr>
          <p>O processo foi finalizado e pode ser consultado no sistema.</p>
          <p><em>Sistema Comprar Bem - Processos Administrativos</em></p>
        `
      },
      'processo_rejeitado': {
        assunto: 'Processo #{numeroProcesso} foi rejeitado',
        template: `
          <h2>❌ Processo Rejeitado</h2>
          <p>O processo <strong>#{numeroProcesso}</strong> foi rejeitado.</p>
          <p><strong>Status:</strong> #{statusAtual}</p>
          <p><strong>Motivo:</strong> #{observacoes}</p>
          <hr>
          <p>O processo foi devolvido para correções. Acesse o sistema para mais detalhes.</p>
          <p><em>Sistema Comprar Bem - Processos Administrativos</em></p>
        `
      }
    }

    return templates[tipoNotificacao] || templates['processo_tramitado']
  }

  // =====================================================
  // IDENTIFICAÇÃO DE DESTINATÁRIOS
  // =====================================================

  static async obterDestinatariosPorStatus(status, tenantId) {
    try {
      // Mapear status para perfis responsáveis
      const responsaveisPorStatus = {
        'criado_cpm': ['cpm'], // CPM deve analisar
        'aprovado_cpm': ['orgao_administrativo'], // Órgão deve assinar
        'assinado_admin': ['assessoria_juridica', 'cpm'], // Jurídico pode aprovar, CPM pode enviar para CCL
        'julgamento_ccl': ['ccl'], // CCL deve julgar
        'aprovado_ccl': ['orgao_administrativo'], // Órgão deve homologar
        'aprovado_juridico': ['orgao_administrativo'], // Órgão deve homologar
        'rejeitado_cpm': ['cpm'], // CPM deve corrigir
        'rejeitado_admin': ['cpm'], // CPM deve corrigir
        'rejeitado_ccl': ['cpm'], // CPM deve corrigir
        'rejeitado_juridico': ['cpm'] // CPM deve corrigir
      }

      const perfisResponsaveis = responsaveisPorStatus[status] || []
      
      if (perfisResponsaveis.length === 0) {
        return []
      }

      // Buscar usuários com os perfis responsáveis
      const { data: usuarios, error } = await supabase
        .from('usuarios')
        .select('id, nome, email, perfil_usuario')
        .eq('tenant_id', tenantId)
        .in('perfil_usuario', perfisResponsaveis)
        .eq('ativo', true)
        .not('email', 'is', null)

      if (error) {
        console.error('Erro ao buscar destinatários:', error)
        return []
      }

      return usuarios || []
    } catch (error) {
      console.error('Erro ao obter destinatários:', error)
      return []
    }
  }

  // =====================================================
  // ENVIO DE NOTIFICAÇÕES
  // =====================================================

  static async enviarNotificacaoTramitacao(processoId, statusAnterior, statusNovo, observacoes = '') {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Tenant não identificado')
      }

      // Obter dados do processo
      const { data: processo, error: processoError } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('id', processoId)
        .eq('tenant_id', tenantId)
        .single()

      if (processoError || !processo) {
        console.error('Erro ao obter processo:', processoError)
        return false
      }

      // Obter destinatários baseado no novo status
      const destinatarios = await this.obterDestinatariosPorStatus(statusNovo, tenantId)
      
      if (destinatarios.length === 0) {
        console.log('Nenhum destinatário encontrado para o status:', statusNovo)
        return false
      }

      // Determinar tipo de notificação
      let tipoNotificacao = 'processo_tramitado'
      if (statusNovo === 'homologado') {
        tipoNotificacao = 'processo_aprovado'
      } else if (statusNovo.includes('rejeitado')) {
        tipoNotificacao = 'processo_rejeitado'
      }

      // Obter template
      const template = this.obterTemplateEmail(tipoNotificacao)

      // Preparar dados para substituição no template
      const dadosTemplate = {
        numeroProcesso: processo.numero_processo || 'Sem número',
        tipoProcesso: processo.tipo_processo === 'padronizacao' ? 'Padronização' : 'Despadronização',
        statusAtual: this.obterLabelStatus(statusNovo),
        nomeOrgao: processo.nome_orgao,
        observacoes: observacoes || 'Nenhuma observação',
        acaoNecessaria: this.obterAcaoNecessaria(statusNovo)
      }

      // Enviar para cada destinatário
      const envios = []
      for (const destinatario of destinatarios) {
        const emailPersonalizado = this.substituirVariaveisTemplate(template.template, dadosTemplate)
        const assuntoPersonalizado = this.substituirVariaveisTemplate(template.assunto, dadosTemplate)

        // Registrar notificação no banco (para auditoria)
        await this.registrarNotificacao({
          processo_id: processoId,
          destinatario_id: destinatario.id,
          tipo_notificacao: tipoNotificacao,
          assunto: assuntoPersonalizado,
          conteudo: emailPersonalizado,
          status_processo: statusNovo,
          tenant_id: tenantId
        })

        envios.push({
          destinatario: destinatario.email,
          nome: destinatario.nome,
          assunto: assuntoPersonalizado,
          conteudo: emailPersonalizado
        })
      }

      // Aqui seria integrado com EmailJS ou outro serviço de email
      console.log('Notificações preparadas:', envios)
      
      // Por enquanto, apenas simular o envio
      await this.simularEnvioEmail(envios)

      return true
    } catch (error) {
      console.error('Erro ao enviar notificação de tramitação:', error)
      return false
    }
  }

  static async registrarNotificacao(dadosNotificacao) {
    try {
      const { data, error } = await supabase
        .from('notificacoes_processo')
        .insert({
          ...dadosNotificacao,
          enviado_em: new Date().toISOString(),
          status_envio: 'enviado'
        })

      if (error) {
        console.error('Erro ao registrar notificação:', error)
      }

      return data
    } catch (error) {
      console.error('Erro ao registrar notificação:', error)
      return null
    }
  }

  static substituirVariaveisTemplate(template, dados) {
    let resultado = template
    
    Object.keys(dados).forEach(chave => {
      const regex = new RegExp(`#{${chave}}`, 'g')
      resultado = resultado.replace(regex, dados[chave] || '')
    })

    return resultado
  }

  static obterLabelStatus(status) {
    const labels = {
      'rascunho': 'Em Criação',
      'criado_cpm': 'Criado pela CPM',
      'aprovado_cpm': 'Aprovado pela CPM',
      'assinado_admin': 'Assinado pelo Órgão',
      'julgamento_ccl': 'Julgamento CCL',
      'aprovado_ccl': 'Aprovado pela CCL',
      'aprovado_juridico': 'Aprovado Juridicamente',
      'homologado': 'Homologado',
      'rejeitado_cpm': 'Rejeitado pela CPM',
      'rejeitado_admin': 'Rejeitado pelo Órgão',
      'rejeitado_ccl': 'Rejeitado pela CCL',
      'rejeitado_juridico': 'Rejeitado Juridicamente',
      'rejeitado_final': 'Rejeitado Final'
    }

    return labels[status] || status
  }

  static obterAcaoNecessaria(status) {
    const acoes = {
      'criado_cpm': 'Analisar e aprovar ou rejeitar o processo',
      'aprovado_cpm': 'Assinar ou rejeitar o processo administrativo',
      'assinado_admin': 'Processo assinado - pode ser enviado para CCL ou análise jurídica',
      'julgamento_ccl': 'Realizar julgamento técnico do processo',
      'aprovado_ccl': 'Homologar o processo aprovado pela CCL',
      'aprovado_juridico': 'Homologar o processo aprovado juridicamente',
      'rejeitado_cpm': 'Corrigir os problemas apontados pela CPM',
      'rejeitado_admin': 'Corrigir os problemas apontados pelo Órgão',
      'rejeitado_ccl': 'Corrigir os problemas apontados pela CCL',
      'rejeitado_juridico': 'Corrigir os problemas apontados pelo Jurídico'
    }

    return acoes[status] || 'Consultar detalhes no sistema'
  }

  // =====================================================
  // SIMULAÇÃO DE ENVIO (SUBSTITUIR POR EMAILJS OU OUTRO)
  // =====================================================

  static async simularEnvioEmail(envios) {
    // Por enquanto apenas log - aqui seria integrado EmailJS
    console.log('🔔 NOTIFICAÇÕES DE EMAIL SIMULADAS:')
    console.log('=====================================')
    
    envios.forEach((envio, index) => {
      console.log(`📧 Email ${index + 1}:`)
      console.log(`Para: ${envio.destinatario} (${envio.nome})`)
      console.log(`Assunto: ${envio.assunto}`)
      console.log(`Conteúdo: ${envio.conteudo.substring(0, 100)}...`)
      console.log('---')
    })

    // Simular delay de envio
    await new Promise(resolve => setTimeout(resolve, 500))
    
    console.log('✅ Todos os emails foram "enviados" com sucesso!')
    return true
  }

  // =====================================================
  // LEMBRETES AUTOMÁTICOS
  // =====================================================

  static async verificarProcessosPendentes() {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) return

      const seteDiasAtras = new Date()
      seteDiasAtras.setDate(seteDiasAtras.getDate() - 7)

      // Buscar processos parados há mais de 7 dias
      const { data: processosPendentes, error } = await supabase
        .from('processos_administrativos')
        .select('*')
        .eq('tenant_id', tenantId)
        .lt('atualizado_em', seteDiasAtras.toISOString())
        .not('status', 'in', '(homologado,rejeitado_final)')

      if (error) {
        console.error('Erro ao buscar processos pendentes:', error)
        return
      }

      for (const processo of processosPendentes || []) {
        await this.enviarLembretePendencia(processo)
      }
    } catch (error) {
      console.error('Erro ao verificar processos pendentes:', error)
    }
  }

  static async enviarLembretePendencia(processo) {
    try {
      const diasPendente = Math.floor(
        (new Date() - new Date(processo.atualizado_em)) / (1000 * 60 * 60 * 24)
      )

      const template = this.obterTemplateEmail('processo_pendente')
      const destinatarios = await this.obterDestinatariosPorStatus(processo.status, processo.tenant_id)

      if (destinatarios.length === 0) return

      const dadosTemplate = {
        numeroProcesso: processo.numero_processo || 'Sem número',
        statusAtual: this.obterLabelStatus(processo.status),
        nomeOrgao: processo.nome_orgao,
        diasPendente: diasPendente.toString()
      }

      for (const destinatario of destinatarios) {
        const emailPersonalizado = this.substituirVariaveisTemplate(template.template, dadosTemplate)
        const assuntoPersonalizado = this.substituirVariaveisTemplate(template.assunto, dadosTemplate)

        await this.registrarNotificacao({
          processo_id: processo.id,
          destinatario_id: destinatario.id,
          tipo_notificacao: 'processo_pendente',
          assunto: assuntoPersonalizado,
          conteudo: emailPersonalizado,
          status_processo: processo.status,
          tenant_id: processo.tenant_id
        })
      }
    } catch (error) {
      console.error('Erro ao enviar lembrete de pendência:', error)
    }
  }
}

export default EmailNotificationService