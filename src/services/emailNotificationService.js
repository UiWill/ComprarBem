import { supabase, getTenantId } from './supabase'
import emailjs from '@emailjs/browser'

// Configuração EmailJS (usar as mesmas configs do emailService.js)
const EMAILJS_CONFIG = {
  serviceId: 'service_7sv1naw',
  templateId: 'template_nyiw2ua', // Template geral existente
  publicKey: 'DqGKMNJ87ch3qVxGv'
}

// Inicializar EmailJS
emailjs.init(EMAILJS_CONFIG.publicKey)

export class EmailNotificationService {
  
  // Controle para evitar envios duplicados
  static ultimosEnvios = new Map()
  
  // =====================================================
  // CONFIGURAÇÃO DE TEMPLATES DE EMAIL
  // =====================================================

  static obterTemplateEmail(tipoNotificacao) {
    const templates = {
      'processo_tramitado': {
        assunto: 'COMPRAR BEM: Processo #{numeroProcesso} requer sua atenção',
        template: `PROCESSO ADMINISTRATIVO - AÇÃO NECESSÁRIA

Olá,

Você tem um processo administrativo que requer sua análise no sistema Comprar Bem.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 DETALHES DO PROCESSO:
• Processo: #{numeroProcesso}
• Tipo: #{tipoProcesso}
• Status Atual: #{statusAtual}
• Órgão: #{nomeOrgao}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚡ AÇÃO NECESSÁRIA:
#{acaoNecessaria}

📝 OBSERVAÇÕES:
#{observacoes}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔗 COMO PROCEDER:
1. Acesse o sistema Comprar Bem
2. Vá para "Processos Administrativos"
3. Localize o processo #{numeroProcesso}
4. Execute a ação necessária

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sistema Comprar Bem
Compras Públicas Inteligentes
Data: #{dataAtual}

Este é um email automático do sistema. Não responda a este email.`
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
      },
      'processo_devolvido': {
        assunto: 'COMPRAR BEM: Processo #{numeroProcesso} foi devolvido para correção',
        template: `PROCESSO ADMINISTRATIVO - DEVOLVIDO PARA CORREÇÃO

Olá,

O processo administrativo #{numeroProcesso} foi devolvido para correção no sistema Comprar Bem.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 DETALHES DO PROCESSO:
• Processo: #{numeroProcesso}
• Tipo: #{tipoProcesso}
• Status Atual: #{statusAtual}
• Órgão: #{nomeOrgao}
• Objeto: #{objeto}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

↩️ MOTIVO DA DEVOLUÇÃO:
#{observacoes}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 AÇÃO NECESSÁRIA:
Corrija os pontos mencionados no motivo da devolução e reenvie o processo.

🔗 COMO PROCEDER:
1. Acesse o sistema Comprar Bem
2. Vá para "Processos Administrativos"
3. Localize o processo #{numeroProcesso}
4. Faça as correções necessárias
5. Reenvie o processo para análise

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sistema Comprar Bem
Compras Públicas Inteligentes
Data: #{dataAtual}

Este é um email automático do sistema. Não responda a este email.`
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
        // FLUXO PADRONIZAÇÃO
        'rascunho': ['cpm'],
        'aguardando_aprovacao': ['cpm'], // CPM deve aprovar processo finalizado
        'criado_cpm': ['cpm'], // CPM pode enviar para órgão
        'aguardando_assinatura_orgao': ['orgao_administrativo'], // Órgão deve assinar
        'assinado_admin': ['ccl'], // CCL deve julgar
        'julgamento_ccl': ['ccl'], // CCL deve julgar
        'aprovado_ccl': ['assessoria_juridica'], // Jurídico deve aprovar
        'aprovado_juridico': ['orgao_administrativo'], // Órgão deve homologar
        'edital_publicado': ['orgao_administrativo'], // Órgão gerencia publicação
        'homologado': ['orgao_administrativo'], // Processo finalizado
        
        // FLUXO DESPADRONIZAÇÃO
        'criado_cpm_desp': ['cpm'], // CPM pode enviar para órgão
        'aguardando_assinatura_orgao_desp': ['orgao_administrativo'], // Órgão deve autorizar abertura
        'abertura_autorizada_desp': ['ccl'], // CCL deve publicar aviso
        'aviso_publicado': ['ccl'], // CCL gerencia processo
        'com_recurso_desp': ['assessoria_juridica'], // Jurídico analisa recursos
        'homologado_desp': ['orgao_administrativo'], // Órgão homologa
        'excluindo_marcas': ['cpm'], // CPM exclui marcas
        
        // REJEIÇÕES (sempre volta para CPM corrigir)
        'rejeitado_cpm': ['cpm'], // CPM deve corrigir
        'rejeitado_admin': ['cpm'], // CPM deve corrigir
        'rejeitado_ccl': ['cpm'], // CPM deve corrigir
        'rejeitado_juridico': ['cpm'], // CPM deve corrigir
        
        // DEVOLUÇÕES (CPM deve corrigir e reenviar)
        'devolvido_pelo_orgao': ['cpm'], // CPM deve corrigir e reenviar
        'devolvido_pela_ccl': ['cpm'], // CPM deve corrigir e reenviar
        'devolvido_pelo_juridico': ['cpm'], // CPM deve corrigir e reenviar
        
        // NOVOS STATUS PADRONIZAÇÃO - Conforme cliente
        'em_criacao': ['cpm'],
        'submetido_autoridade': ['orgao_administrativo'], // Órgão deve autorizar
        'abertura_autorizada': ['cpm'], // CPM prepara edital
        'edital_chamamento': ['assessoria_juridica'], // Jurídico analisa edital
        'analise_juridica': ['assessoria_juridica'], // Jurídico analisa
        'com_impugnacao': ['assessoria_juridica'], // Jurídico analisa impugnações
        'recebendo_amostras': ['cpm'], // CPM recebe amostras
        'avaliacao_cpm': ['cpm'], // CPM avalia e faz relatório
        'ata_ccl': ['ccl'], // CCL emite ata
        'publicacao_ata': ['orgao_administrativo'], // Órgão publica ata
        'com_recurso': ['assessoria_juridica'], // Jurídico analisa recursos
        'expedindo_dcbs': ['cpm'], // CPM expede DCBs
        'incluindo_marcas': ['cpm'], // CPM inclui no catálogo
        
        // NOVOS STATUS DESPADRONIZAÇÃO - Conforme cliente
        'em_criacao_desp': ['cpm'],
        'submetido_autoridade_desp': ['orgao_administrativo'], // Órgão deve autorizar
        'aviso_publicado_desp': ['cpm'] // CPM gerencia processo
      }

      const perfisResponsaveis = responsaveisPorStatus[status] || []
      
      if (perfisResponsaveis.length === 0) {
        return []
      }

      // Buscar usuários com os perfis responsáveis na tabela usuarios
      const { data: usuarios, error } = await supabase
        .from('usuarios')
        .select('id, nome, email, perfil_usuario')
        .eq('tenant_id', tenantId)
        .in('perfil_usuario', perfisResponsaveis)
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
      console.log(`🔄 INICIANDO enviarNotificacaoTramitacao:`, { processoId, statusAnterior, statusNovo })
      
      // Verificar se não foi enviado recentemente (últimos 10 segundos)
      const chave = `${processoId}-${statusAnterior}-${statusNovo}`
      const agora = Date.now()
      const ultimoEnvio = this.ultimosEnvios.get(chave)
      
      if (ultimoEnvio && (agora - ultimoEnvio) < 10000) {
        console.log(`⚠️ DUPLICAÇÃO EVITADA: Email já enviado há ${agora - ultimoEnvio}ms`)
        return false
      }
      
      // Marcar este envio
      this.ultimosEnvios.set(chave, agora)
      
      // Limpar entradas antigas (mais de 1 minuto)
      if (this.ultimosEnvios.size > 100) {
        for (const [key, timestamp] of this.ultimosEnvios.entries()) {
          if (agora - timestamp > 60000) {
            this.ultimosEnvios.delete(key)
          }
        }
      }
      
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
      } else if (statusNovo.includes('devolvido_')) {
        tipoNotificacao = 'processo_devolvido'
      }

      // Obter template
      const template = this.obterTemplateEmail(tipoNotificacao)

      // Preparar dados para substituição no template
      const dadosTemplate = {
        numeroProcesso: processo.numero_processo || 'Sem número',
        tipoProcesso: processo.tipo_processo === 'padronizacao' ? 'Padronização' : 'Despadronização',
        statusAtual: this.obterLabelStatus(statusNovo),
        nomeOrgao: processo.nome_orgao || 'Órgão Público',
        objeto: processo.objeto || processo.descricao || 'Objeto não informado',
        observacoes: observacoes || 'Nenhuma observação',
        acaoNecessaria: this.obterAcaoNecessaria(statusNovo),
        dataAtual: new Date().toLocaleString('pt-BR', { 
          day: '2-digit', 
          month: '2-digit', 
          year: 'numeric', 
          hour: '2-digit', 
          minute: '2-digit'
        })
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

      // Enviar emails reais via EmailJS
      console.log('📧 Enviando notificações REAIS via EmailJS:', envios.length, 'destinatários')
      
      await this.enviarEmailsReais(envios)

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
      // STATUS PADRONIZAÇÃO - Novos conforme cliente
      'em_criacao': 'Em Criação',
      'criado_cpm': 'Criado pela CPM',
      'submetido_autoridade': 'Submetido à Autoridade Competente',
      'abertura_autorizada': 'Abertura Autorizada',
      'edital_chamamento': 'Edital de Chamamento Público',
      'analise_juridica': 'Em Análise Jurídica',
      'edital_publicado': 'Com Edital Publicado',
      'com_impugnacao': 'Com Impugnação ao Edital',
      'recebendo_amostras': 'Recebendo Amostras e Documentação',
      'avaliacao_cpm': 'Com Avaliação e Relatório da CPM',
      'julgamento_ccl': 'Submetido ao Julgamento da CCL',
      'ata_ccl': 'Ata de Julgamento da CCL',
      'publicacao_ata': 'Publicação da Ata e Prazo Recursal',
      'com_recurso': 'Com Recurso Administrativo',
      'homologado': 'Com Homologação',
      'expedindo_dcbs': 'Expedindo as DCBs',
      'incluindo_marcas': 'Incluindo Marcas no Catálogo',
      
      // STATUS DESPADRONIZAÇÃO - Novos conforme cliente
      'em_criacao_desp': 'Em Criação',
      'criado_cpm_desp': 'Criado pela CPM',
      'submetido_autoridade_desp': 'Submetido à Autoridade Competente',
      'abertura_autorizada_desp': 'Abertura Autorizada',
      'aviso_publicado_desp': 'Com Aviso Publicado',
      'com_recurso_desp': 'Com Recurso Administrativo',
      'homologado_desp': 'Com Homologação',
      'excluindo_marcas': 'Excluindo Marcas do Catálogo',
      
      // STATUS DE DEVOLUÇÃO
      'devolvido_pelo_orgao': 'Devolvido pelo Órgão Administrativo',
      'devolvido_pela_ccl': 'Devolvido pela CCL',
      'devolvido_pelo_juridico': 'Devolvido pela Assessoria Jurídica',
      
      // STATUS LEGADOS (compatibilidade)
      'rascunho': 'Em Criação',
      'aguardando_aprovacao': 'Aguardando Aprovação da CPM',
      'aguardando_assinatura_orgao': 'Submetido à Autoridade Competente',
      'assinado_admin': 'Abertura Autorizada',
      'aprovado_ccl': 'Ata de Julgamento da CCL',
      'aprovado_juridico': 'Em Análise Jurídica',
      'aguardando_assinatura_orgao_desp': 'Submetido à Autoridade Competente',
      'aviso_publicado': 'Com Aviso Publicado',
      'rejeitado_cpm': 'Rejeitado pela CPM',
      'rejeitado_admin': 'Rejeitado pelo Órgão',
      'rejeitado_ccl': 'Rejeitado pela CCL',
      'rejeitado_juridico': 'Rejeitado pela Assessoria Jurídica',
      'rejeitado_final': 'Rejeitado Final'
    }

    return labels[status] || status
  }

  static obterAcaoNecessaria(status) {
    const acoes = {
      'aguardando_aprovacao': 'Analisar o processo e aprovar ou rejeitar',
      'criado_cpm': 'Analisar e aprovar ou rejeitar o processo',
      'aguardando_assinatura_orgao': 'ASSINAR o processo administrativo para dar continuidade',
      'aguardando_assinatura_orgao_desp': 'AUTORIZAR a abertura do processo de despadronização',
      'aprovado_cpm': 'ASSINAR o processo para envio à CCL ou Jurídico',
      'assinado_admin': 'Processo assinado - enviar para julgamento da CCL',
      'julgamento_ccl': 'JULGAR o processo técnico (aprovar ou reprovar)',
      'aprovado_ccl': 'HOMOLOGAR o processo aprovado pela CCL',
      'aprovado_juridico': 'HOMOLOGAR o processo aprovado pelo Jurídico',
      'abertura_autorizada_desp': 'Publicar aviso de despadronização',
      'aviso_publicado': 'Aguardar prazo recursal ou prosseguir',
      'com_recurso_desp': 'ANALISAR os recursos administrativos apresentados',
      'homologado': 'Processo concluído - verificar documentação final',
      'homologado_desp': 'Executar exclusão das marcas do catálogo',
      'excluindo_marcas': 'Finalizar exclusão das marcas despadronizadas',
      'rejeitado_cpm': 'CORRIGIR os problemas apontados pela CPM e reenviar',
      'rejeitado_admin': 'CORRIGIR os problemas apontados pelo Órgão e reenviar',
      'rejeitado_ccl': 'CORRIGIR os problemas apontados pela CCL e reenviar',
      'rejeitado_juridico': 'CORRIGIR os problemas jurídicos apontados e reenviar'
    }

    return acoes[status] || 'Consultar detalhes no sistema e tomar ação necessária'
  }

  // =====================================================
  // MÉTODOS DE TESTE E DEBUG
  // =====================================================

  /**
   * Testar busca de usuários por perfil
   */
  static async testarBuscaUsuariosPorPerfil(status = 'aprovado_cpm') {
    try {
      const tenantId = await getTenantId()
      console.log('🔍 TESTE: Buscando usuários para status:', status)
      console.log('🏢 Tenant ID:', tenantId)
      
      const destinatarios = await this.obterDestinatariosPorStatus(status, tenantId)
      
      console.log('👥 USUÁRIOS ENCONTRADOS:')
      console.log('========================')
      destinatarios.forEach(user => {
        console.log(`📧 ${user.nome} (${user.email}) - Perfil: ${user.perfil_usuario}`)
      })
      
      if (destinatarios.length === 0) {
        console.log('⚠️ NENHUM USUÁRIO ENCONTRADO para o status:', status)
        console.log('Verifique se existem usuários com os perfis necessários no tenant.')
      }
      
      return destinatarios
    } catch (error) {
      console.error('❌ Erro no teste:', error)
      return []
    }
  }

  /**
   * Listar todos os usuários do tenant atual
   */
  static async listarTodosUsuarios() {
    try {
      const tenantId = await getTenantId()
      console.log('🔍 LISTANDO TODOS OS USUÁRIOS DO TENANT:', tenantId)
      
      const { data: usuarios, error } = await supabase
        .from('usuarios')
        .select('*')
        .eq('tenant_id', tenantId)
        .order('nome')
      
      if (error) {
        console.error('Erro ao listar usuários:', error)
        return []
      }
      
      console.log('👥 USUÁRIOS NO SISTEMA:')
      console.log('======================')
      usuarios.forEach(user => {
        console.log(`👤 ${user.nome} (${user.email || 'SEM EMAIL'}) - Perfil: ${user.perfil_usuario}`)
      })
      
      return usuarios || []
    } catch (error) {
      console.error('Erro ao listar usuários:', error)
      return []
    }
  }

  /**
   * TESTE COMPLETO DO SISTEMA DE TRAMITAÇÃO
   * Execute este método no console do navegador para testar tudo
   */
  static async testarSistemaCompleto() {
    try {
      console.log('🚀 INICIANDO TESTE COMPLETO DO SISTEMA DE TRAMITAÇÃO')
      console.log('='*60)
      
      // 1. Verificar usuarios no banco
      console.log('\n1️⃣ VERIFICANDO USUÁRIOS NO BANCO...')
      const usuarios = await this.listarTodosUsuarios()
      
      if (usuarios.length === 0) {
        console.log('❌ NENHUM USUÁRIO ENCONTRADO!')
        console.log('🔧 Verifique se existe ao menos um usuário com perfil_usuario preenchido')
        return false
      }
      
      // 2. Testar busca por perfil
      console.log('\n2️⃣ TESTANDO BUSCA POR PERFIL...')
      const destinatariosOrgao = await this.testarBuscaUsuariosPorPerfil('aprovado_cpm')
      
      if (destinatariosOrgao.length === 0) {
        console.log('❌ NENHUM USUÁRIO COM PERFIL "orgao_administrativo" ENCONTRADO!')
        console.log('🔧 Precisa ter ao menos um usuário com perfil_usuario = "orgao_administrativo"')
        return false
      }
      
      // 3. Testar template de email
      console.log('\n3️⃣ TESTANDO GERAÇÃO DE TEMPLATE...')
      const templateTeste = this.obterTemplateEmail('processo_tramitado')
      console.log('✅ Template gerado com sucesso!')
      
      // 4. Simular tramitação completa
      console.log('\n4️⃣ SIMULANDO TRAMITAÇÃO COMPLETA...')
      const processoTeste = {
        id: 'TESTE-001',
        numero_processo: 'PROCESSO-TESTE-001',
        tipo_processo: 'padronizacao',
        nome_orgao: 'Ministério da Saúde - TESTE'
      }
      
      const resultadoTeste = await this.enviarNotificacaoTramitacao(
        processoTeste.id,
        'criado_cpm',
        'aprovado_cpm',
        'Teste automatizado do sistema de tramitação'
      )
      
      if (resultadoTeste) {
        console.log('✅ TESTE COMPLETO REALIZADO COM SUCESSO!')
        console.log('📧 Verifique os emails dos usuários com perfil "orgao_administrativo"')
        console.log('🎉 O sistema de tramitação está funcionando!')
      } else {
        console.log('❌ FALHA NO TESTE DE ENVIO DE EMAIL')
      }
      
      console.log('\n🏁 TESTE COMPLETO FINALIZADO!')
      return resultadoTeste
      
    } catch (error) {
      console.error('❌ ERRO NO TESTE COMPLETO:', error)
      return false
    }
  }

  // =====================================================
  // ENVIO REAL DE EMAILS VIA EMAILJS
  // =====================================================

  static async enviarEmailsReais(envios) {
    console.log('📧 ENVIANDO EMAILS REAIS VIA EMAILJS:')
    console.log('=====================================')
    
    let sucessos = 0
    let erros = 0
    
    for (let i = 0; i < envios.length; i++) {
      const envio = envios[i]
      
      try {
        console.log(`📧 Enviando email ${i + 1}/${envios.length}:`)
        console.log(`Para: ${envio.destinatario} (${envio.nome})`)
        console.log(`Assunto: ${envio.assunto}`)
        
        // Preparar parâmetros para EmailJS
        const emailParams = {
          numero_edital: 'TRAMITACAO-PROCESSO',
          email_empresa: envio.destinatario,
          message: envio.conteudo,
          name: envio.nome,
          email: 'comprarbemteste@gmail.com',
          subject: envio.assunto,
          status_participante: 'tramitacao_processo',
          motivo_rejeicao: ''
        }
        
        // Enviar email via EmailJS
        const result = await emailjs.send(
          EMAILJS_CONFIG.serviceId,
          EMAILJS_CONFIG.templateId,
          emailParams,
          EMAILJS_CONFIG.publicKey
        )
        
        if (result.status === 200) {
          sucessos++
          console.log(`✅ Email enviado com sucesso para ${envio.nome}!`)
        } else {
          erros++
          console.log(`❌ Falha no envio para ${envio.nome}. Status: ${result.status}`)
        }
        
      } catch (error) {
        erros++
        console.error(`❌ Erro ao enviar para ${envio.nome}:`, error)
      }
      
      // Aguardar 2 segundos entre envios para não sobrecarregar o EmailJS
      if (i < envios.length - 1) {
        console.log('⏳ Aguardando 2 segundos antes do próximo envio...')
        await new Promise(resolve => setTimeout(resolve, 2000))
      }
    }
    
    console.log('📊 RESULTADO DO ENVIO:')
    console.log(`✅ Sucessos: ${sucessos}`)
    console.log(`❌ Erros: ${erros}`)
    console.log(`📧 Total: ${envios.length}`)
    
    return { sucessos, erros, total: envios.length }
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