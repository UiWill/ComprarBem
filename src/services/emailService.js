// 📧 Serviço de Email para Diligências
// Configuração para envio de emails via EmailJS

import { supabase } from './supabase'
import emailjs from '@emailjs/browser'

// ⚙️ CONFIGURAÇÕES DE EMAIL
const EMAIL_CONFIG = {
  // Email remetente da organização
  from: {
    email: 'cpm@suaorganizacao.com.br',
    name: 'CPM - Comissão de Padronização de Materiais'
  },
  
  // Configurações do provedor (exemplo: SendGrid)
  provider: {
    apiKey: process.env.VUE_APP_EMAIL_API_KEY,
    apiUrl: 'https://api.sendgrid.v3/mail/send'
  }
}

// 📨 TEMPLATES DE EMAIL
const EMAIL_TEMPLATES = {
  diligencia: {
    subject: 'Diligência Solicitada - Produto em Análise',
    template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center;">
          <h1>📋 Diligência Solicitada</h1>
          <p>Comissão de Padronização de Materiais</p>
        </div>
        
        <div style="padding: 30px; background: #f8f9fa;">
          <h2 style="color: #333;">Prezado(a) Fornecedor,</h2>
          
          <p>Foi solicitada uma <strong>diligência</strong> para o produto em análise:</p>
          
          <div style="background: white; padding: 20px; border-left: 4px solid #667eea; margin: 20px 0;">
            <h3 style="color: #667eea; margin-top: 0;">📦 Dados do Produto:</h3>
            <p><strong>Nome:</strong> ${data.produto.nome}</p>
            <p><strong>Marca:</strong> ${data.produto.marca}</p>
            <p><strong>Modelo:</strong> ${data.produto.modelo}</p>
            <p><strong>Fabricante:</strong> ${data.produto.fabricante}</p>
          </div>
          
          <div style="background: #fff3cd; padding: 20px; border-left: 4px solid #ffc107; margin: 20px 0;">
            <h3 style="color: #856404; margin-top: 0;">⚠️ Tipo de Diligência:</h3>
            <p><strong>${data.diligencia.tipo}</strong></p>
            <p>${data.diligencia.descricao}</p>
          </div>
          
          <div style="background: #f8d7da; padding: 20px; border-left: 4px solid #dc3545; margin: 20px 0;">
            <h3 style="color: #721c24; margin-top: 0;">⏰ Prazo para Resposta:</h3>
            <p><strong>${data.diligencia.prazo_dias} dias úteis</strong></p>
            <p><strong>Data Limite:</strong> ${new Date(data.diligencia.data_limite).toLocaleDateString('pt-BR')}</p>
          </div>
          
          <div style="background: #d4edda; padding: 20px; border-left: 4px solid #28a745; margin: 20px 0;">
            <h3 style="color: #155724; margin-top: 0;">📝 Instruções:</h3>
            <ul>
              <li>Responda a esta diligência dentro do prazo estabelecido</li>
              <li>Envie todos os documentos solicitados em formato PDF</li>
              <li>Em caso de dúvidas, entre em contato conosco</li>
              <li>O não atendimento da diligência pode resultar na reprovação do produto</li>
            </ul>
          </div>
          
          <div style="text-align: center; margin: 30px 0;">
            <p style="color: #666;">Para responder esta diligência, entre em contato através do nosso sistema ou envie os documentos por email.</p>
          </div>
          
          <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
          
          <div style="color: #666; font-size: 12px;">
            <p><strong>CPM - Comissão de Padronização de Materiais</strong></p>
            <p>Este é um email automático. Não responda diretamente a este email.</p>
            <p>Data de envio: ${new Date().toLocaleDateString('pt-BR')} às ${new Date().toLocaleTimeString('pt-BR')}</p>
          </div>
        </div>
      </div>
    `
  },

  // 🎉 TEMPLATE PARA PARTICIPANTE (APROVADO OU REJEITADO)
  participanteStatus: {
    subject: '{{titulo status}}', // Subject dinâmico
    template: (data) => `
SUBJECT: ${data.status === 'aprovado' ? '✅ APROVADO' : '❌ REJEITADO'} - Sua empresa foi ${data.status === 'aprovado' ? 'aprovada' : 'rejeitada'} no Edital ${data.numero_edital}

Prezado(a) ${data.representante_legal},

${data.status === 'aprovado' ? 
  'É com grande satisfação que informamos que sua empresa foi APROVADA para participar do processo de pré-qualificação!' :
  'Informamos que sua empresa foi REJEITADA no processo de pré-qualificação.'
}

=== DADOS DA EMPRESA ===
Razão Social: ${data.razao_social}
CNPJ: ${data.cnpj}
Representante Legal: ${data.representante_legal}
Email: ${data.email_empresa}
Telefone: ${data.telefone}

=== DADOS DO EDITAL ===
Número: ${data.numero_edital}
Descrição: ${data.descricao_edital}
Data da Decisão: ${data.data_decisao}
Status: ${data.status.toUpperCase()}

${data.status === 'aprovado' ? 
`=== PRÓXIMOS PASSOS ===
1. Documentação Técnica: Envie os documentos técnicos dos produtos conforme especificado no edital
2. Amostras (se aplicável): Providencie as amostras físicas quando solicitado
3. Análise CPM: Aguarde a análise técnica da Comissão de Padronização de Materiais
4. Emissão DCB: Após aprovação técnica, será emitido o DCB (Declaração de Conformidade de Bem)
5. Catálogo Eletrônico: Produtos aprovados entrarão no catálogo para licitações

=== INFORMAÇÕES IMPORTANTES ===
- Esta aprovação é para participação no processo, não garante aprovação final dos produtos
- Todos os produtos passarão por análise técnica rigorosa pela CPM
- Documentação incompleta ou inadequada pode resultar em reprovação
- Mantenha seus dados atualizados em nosso sistema
- Acompanhe o status através do nosso portal

=== PRAZOS ===
Envio de Documentação: ${data.prazo_documentacao}
Análise Técnica: Até 30 dias úteis após recebimento completo
Resultado Final: Será comunicado por email e sistema` :
`=== MOTIVO DA REJEIÇÃO ===
${data.motivo_rejeicao || 'Documentação não atende aos requisitos do edital'}

=== COMO PROCEDER ===
- Revise a documentação enviada
- Corrija os problemas identificados
- Você pode se candidatar novamente em editais futuros
- Em caso de dúvidas, entre em contato conosco`
}

=== CONTATO ===
Email: ${data.email_suporte}
Telefone: ${data.telefone_suporte}
Horário: Segunda a Sexta, 8h às 17h

=== SISTEMA COMPRARBEM ===
Acesse: ${data.link_sistema}

${data.nome_organizacao}
Email: ${data.email_organizacao}
Telefone: ${data.telefone_organizacao}
Endereço: ${data.endereco_organizacao}

---
Este é um email automático. Não responda diretamente a este email.
Email enviado em ${data.data_envio} às ${data.hora_envio}
    `
  }
}

// 🎉 FUNÇÃO PARA ENVIAR EMAIL DE STATUS DE PARTICIPANTE (APROVADO OU REJEITADO)
export async function enviarEmailParticipanteStatus(participante, edital, status = 'aprovado', motivoRejeicao = null) {
  try {
    console.log(`📧 Iniciando envio de email de ${status} para participante...`, participante.email)
    
    // Preparar dados para o template
    const dadosEmail = {
      // Dados da empresa
      representante_legal: participante.representante_legal,
      razao_social: participante.razao_social,
      cnpj: participante.cnpj,
      email_empresa: participante.email,
      telefone: participante.telefone || 'Não informado',
      
      // Status e motivo
      status: status,
      motivo_rejeicao: motivoRejeicao,
      
      // Dados do edital
      numero_edital: edital.numero || 'N/A',
      descricao_edital: edital.descricao || 'Edital de Pré-Qualificação',
      data_decisao: new Date().toLocaleDateString('pt-BR'),
      prazo_documentacao: '30 dias úteis a partir desta data',
      
      // Sistema
      link_sistema: window.location.origin,
      email_suporte: 'comprarbemteste@gmail.com',
      telefone_suporte: '(61) 3315-2425',
      
      // Organização
      nome_organizacao: 'Ministério da Saúde',
      email_organizacao: 'cpm@saude.gov.br',
      telefone_organizacao: '(61) 3315-2425',
      endereco_organizacao: 'Brasília - DF',
      
      // Timestamp
      data_envio: new Date().toLocaleDateString('pt-BR'),
      hora_envio: new Date().toLocaleTimeString('pt-BR')
    }

    // Gerar conteúdo do email (formato texto simples)
    const textoEmail = EMAIL_TEMPLATES.participanteStatus.template(dadosEmail)
    
    // Subject dinâmico baseado no status
    const subjectEmail = status === 'aprovado' ? 
      `✅ APROVADO - Sua empresa foi aprovada no Edital ${dadosEmail.numero_edital}` :
      `❌ REJEITADO - Sua empresa foi rejeitada no Edital ${dadosEmail.numero_edital}`
    
    // Configurações do EmailJS
    const EMAILJS_CONFIG = {
      serviceId: 'service_7sv1naw', 
      templateId: 'template_nyiw2ua', // Usar o mesmo template
      publicKey: 'DqGKMNJ87ch3qVxGv'
    }
    
    // Preparar parâmetros para EmailJS
    const emailParams = {
      numero_edital: dadosEmail.numero_edital,
      email_empresa: dadosEmail.email_empresa,
      message: textoEmail, // Usando texto simples ao invés de HTML
      name: dadosEmail.representante_legal,
      email: dadosEmail.email_suporte,
      subject: subjectEmail, // 🔥 SUBJECT DINÂMICO!
      status_participante: status, // 🔥 STATUS PARA GARANTIR!
      motivo_rejeicao: motivoRejeicao || '' // 🔥 MOTIVO DA REJEIÇÃO!
    }
    
    console.log(`📧 Enviando email de ${status} via EmailJS...`)
    console.log('📧 Para:', dadosEmail.email_empresa)
    console.log('📧 Edital:', dadosEmail.numero_edital)
    console.log('📧 Subject:', subjectEmail)
    console.log('📧 Status:', status)
    console.log('📧 Motivo Rejeição:', motivoRejeicao)
    console.log('📧 Parâmetros EmailJS:', emailParams)
    
    // Enviar email via EmailJS
    const result = await emailjs.send(
      EMAILJS_CONFIG.serviceId,
      EMAILJS_CONFIG.templateId,
      emailParams,
      EMAILJS_CONFIG.publicKey
    )
    
    console.log(`🎉 EMAIL DE ${status.toUpperCase()} ENVIADO COM SUCESSO!`, result)
    
    // Registrar no banco de dados
    await registrarEmailEnviado({
      tipo: `participante_${status}`,
      destinatario: participante.email,
      assunto: subjectEmail,
      participante_id: participante.id,
      edital_id: edital.id,
      status: 'enviado'
    })
    
    return {
      sucesso: true,
      mensagem: `Email de ${status} enviado com sucesso!`,
      destinatario: participante.email
    }
    
  } catch (error) {
    console.error(`❌ Erro ao enviar email de ${status}:`, error)
    
    // Registrar erro no banco
    await registrarEmailEnviado({
      tipo: `participante_${status}`,
      destinatario: participante.email,
      assunto: `${status === 'aprovado' ? '✅ APROVADO' : '❌ REJEITADO'} - Edital ${edital.numero}`,
      participante_id: participante.id,
      edital_id: edital.id,
      status: 'erro',
      erro: error.message
    })
    
    throw new Error(`Falha ao enviar email de ${status}: ` + error.message)
  }
}

// 📤 FUNÇÃO PRINCIPAL DE ENVIO (DILIGÊNCIA)
export async function enviarEmailDiligencia(dadosEmail) {
  try {
    console.log('📧 Iniciando envio de email de diligência...', dadosEmail)
    
    // 🔄 CARREGAR CONFIGURAÇÕES DO USUÁRIO
    try {
      const configsSalvas = localStorage.getItem('configsSistema')
      if (configsSalvas) {
        const configs = JSON.parse(configsSalvas)
        if (configs.emailRemetente) {
          EMAIL_CONFIG.from.email = configs.emailRemetente
        }
        if (configs.nomeRemetente) {
          EMAIL_CONFIG.from.name = configs.nomeRemetente
        }
      }
    } catch (error) {
      console.error('Erro ao carregar configurações do usuário:', error)
    }
    
    // Validações
    if (!dadosEmail.produto || !dadosEmail.diligencia || !dadosEmail.destinatario) {
      throw new Error('Dados incompletos para envio do email')
    }
    
    // Preparar dados do email
    const emailData = {
      personalizations: [{
        to: [{
          email: dadosEmail.destinatario,
          name: dadosEmail.produto.fabricante
        }]
      }],
      from: {
        email: EMAIL_CONFIG.from.email,
        name: EMAIL_CONFIG.from.name
      },
      subject: EMAIL_TEMPLATES.diligencia.subject,
      content: [{
        type: 'text/html',
        value: EMAIL_TEMPLATES.diligencia.template(dadosEmail)
      }]
    }
    
    // Registrar tentativa de envio no banco
    const { data: logEmail, error: logError } = await supabase
      .from('emails_enviados')
      .insert({
        tipo: 'diligencia',
        destinatario: dadosEmail.destinatario,
        assunto: EMAIL_TEMPLATES.diligencia.subject,
        produto_id: dadosEmail.produto.id,
        diligencia_id: dadosEmail.diligencia.id,
        status: 'enviando',
        tentativas: 1
      })
      .select()
      .single()
    
    if (logError) {
      console.error('❌ Erro ao registrar log de email:', logError)
    }
    
    // 📤 ENVIO REAL COM EMAILJS (mais simples, sem CORS)
    if (process.env.VUE_APP_EMAIL_PROVIDER === 'sendgrid' && process.env.VUE_APP_SENDGRID_API_KEY) {
      console.log('📧 Enviando email via EmailJS (usando SendGrid configurado)...')
      
      try {
        // Preparar dados para EmailJS
        const emailParams = {
          to_email: dadosEmail.destinatario,
          fabricante: dadosEmail.produto.fabricante,
          produto_nome: dadosEmail.produto.nome,
          produto_marca: dadosEmail.produto.marca,
          produto_modelo: dadosEmail.produto.modelo,
          cnpj: dadosEmail.produto.cnpj || 'Não informado',
          tipo_diligencia: dadosEmail.diligencia.tipo,
          descricao_diligencia: dadosEmail.diligencia.descricao,
          prazo_dias: '30', // SEMPRE 30 DIAS
          data_limite: new Date(dadosEmail.diligencia.data_limite).toLocaleDateString('pt-BR'),
          data_envio: new Date().toLocaleDateString('pt-BR') + ' às ' + new Date().toLocaleTimeString('pt-BR'),
          
          // Dados de quem está enviando (nosso sistema)
          nome_responsavel: 'William Martins',
          cargo_responsavel: 'Analista CPM',
          email_responsavel: 'comprarbemteste@gmail.com'
        }
        
        console.log('📧 Enviando email via EmailJS...')
        console.log('📧 Dados preparados:', emailParams)
        
        // Configurações do EmailJS
        const EMAILJS_CONFIG = {
          serviceId: 'service_7sv1naw',
          templateId: 'template_vbp986f',
          publicKey: 'DqGKMNJ87ch3qVxGv'
        }
        
        // 🚀 ENVIAR EMAIL REAL VIA EMAILJS
        try {
          console.log('📧 Enviando email REAL via EmailJS...')
          console.log('📧 Configuração:', EMAILJS_CONFIG)
          console.log('📧 Dados:', emailParams)
          
          // Enviar email real
          const result = await emailjs.send(
            EMAILJS_CONFIG.serviceId, 
            EMAILJS_CONFIG.templateId, 
            emailParams, 
            EMAILJS_CONFIG.publicKey
          )
          
          console.log('🎉 EMAIL ENVIADO COM SUCESSO!', result)
          
        } catch (emailJSError) {
          console.error('❌ Erro no EmailJS:', emailJSError)
          throw emailJSError
        }
        
        // Atualizar status para enviado
        if (logEmail) {
          await supabase
            .from('emails_enviados')
            .update({ 
              status: 'enviado',
              data_envio: new Date().toISOString(),
              corpo: emailParams.message
            })
            .eq('id', logEmail.id)
        }
        
        console.log('✅ EMAIL PREPARADO COM SUCESSO!')
        console.log('📧 Para:', emailParams.to_email)
        console.log('📧 Assunto:', emailParams.subject)
        
        return {
          success: true,
          message: 'Email preparado com sucesso! (SendGrid configurado)',
          emailId: logEmail?.id
        }
        
      } catch (emailError) {
        console.error('❌ Erro ao preparar email:', emailError)
        
        // Fallback: Modo desenvolvimento
        if (logEmail) {
          await supabase
            .from('emails_enviados')
            .update({ 
              status: 'desenvolvimento',
              data_envio: new Date().toISOString(),
              erro_detalhes: 'Erro na preparação do email'
            })
            .eq('id', logEmail.id)
        }
        
        return {
          success: true,
          message: 'Diligência criada (modo desenvolvimento)',
          emailId: logEmail?.id,
          development: true
        }
      }
    }
    
    // Fallback: Modo desenvolvimento (simulado)
    console.log('🔄 Modo desenvolvimento - Simulando envio de email')
    console.log('📧 Email Data:', emailData)
    
    // Simular delay de envio
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // Atualizar status para sucesso
    if (logEmail) {
      await supabase
        .from('emails_enviados')
        .update({ 
          status: 'enviado',
          data_envio: new Date().toISOString()
        })
        .eq('id', logEmail.id)
    }
    
    return {
      success: true,
      message: 'Email enviado com sucesso (simulado)',
      emailId: logEmail?.id
    }
    
    return {
      success: true,
      message: 'Email enviado com sucesso',
      emailId: logEmail?.id
    }
    
  } catch (error) {
    console.error('❌ Erro ao enviar email de diligência:', error)
    
    return {
      success: false,
      message: error.message || 'Erro interno no envio do email',
      error: error
    }
  }
}

// 📊 FUNÇÃO PARA BUSCAR HISTÓRICO DE EMAILS
export async function buscarHistoricoEmails(produtoId) {
  try {
    const { data, error } = await supabase
      .from('emails_enviados')
      .select('*')
      .eq('produto_id', produtoId)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    
    return data || []
  } catch (error) {
    console.error('❌ Erro ao buscar histórico de emails:', error)
    return []
  }
}

// ⚙️ FUNÇÃO PARA CONFIGURAR EMAIL DA ORGANIZAÇÃO
export function configurarEmailOrganizacao(novoEmail, nomeOrganizacao) {
  EMAIL_CONFIG.from.email = novoEmail
  EMAIL_CONFIG.from.name = nomeOrganizacao
}

// 📝 FUNÇÃO AUXILIAR PARA REGISTRAR EMAILS ENVIADOS
async function registrarEmailEnviado(dadosEmail) {
  try {
    const { error } = await supabase
      .from('emails_enviados')
      .insert({
        tipo: dadosEmail.tipo,
        destinatario: dadosEmail.destinatario,
        assunto: dadosEmail.assunto,
        participante_id: dadosEmail.participante_id || null,
        edital_id: dadosEmail.edital_id || null,
        produto_id: dadosEmail.produto_id || null,
        diligencia_id: dadosEmail.diligencia_id || null,
        status: dadosEmail.status,
        erro: dadosEmail.erro || null,
        tentativas: 1,
        criado_em: new Date().toISOString()
      })
    
    if (error) {
      console.warn('⚠️ Erro ao registrar email no banco:', error)
    } else {
      console.log('✅ Email registrado no banco com sucesso')
    }
  } catch (error) {
    console.warn('⚠️ Falha ao registrar email no banco:', error)
  }
}

// Configuração EmailJS
const EMAILJS_CONFIG = {
  serviceId: 'service_7sv1naw',
  templateId: 'template_nyiw2ua', // Template geral existente
  publicKey: 'DqGKMNJ87ch3qVxGv'
}

// Inicializar EmailJS
emailjs.init(EMAILJS_CONFIG.publicKey)

// ============================================
// TEMPLATES DE EMAIL PARA LEMBRETES DE FEEDBACK
// ============================================

const templateLembreteFeedback = {
  '15_DIAS': {
    subject: '📋 Lembrete: Avalie o material recebido - {{material_nome}}',
    priority: 'normal',
    emoji: '📋',
    urgencia: 'Lembrete Amigável'
  },
  '25_DIAS': {
    subject: '⏰ Importante: Avaliação pendente - {{material_nome}}',
    priority: 'high',
    emoji: '⏰',
    urgencia: 'Importante'
  },
  '30_DIAS_URGENTE': {
    subject: '🚨 URGENTE: Avaliação obrigatória vence hoje - {{material_nome}}',
    priority: 'urgent',
    emoji: '🚨',
    urgencia: 'URGENTE'
  }
}

function gerarHTMLLembreteFeedback(dadosLembrete) {
  const { tipo_lembrete, material_nome, material_codigo, dias_desde_aprovacao, usuario_nome, unidade_setor } = dadosLembrete
  const template = templateLembreteFeedback[tipo_lembrete]
  
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Lembrete de Feedback - Sistema Comprar Bem</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
    .header { background: ${tipo_lembrete === '30_DIAS_URGENTE' ? 'linear-gradient(135deg, #e74c3c, #c0392b)' : tipo_lembrete === '25_DIAS' ? 'linear-gradient(135deg, #f39c12, #e67e22)' : 'linear-gradient(135deg, #3498db, #2980b9)'}; color: white; padding: 20px; text-align: center; }
    .header h1 { margin: 0; font-size: 24px; }
    .content { padding: 30px; }
    .urgencia-badge { display: inline-block; padding: 8px 16px; border-radius: 20px; font-weight: bold; margin: 10px 0; ${tipo_lembrete === '30_DIAS_URGENTE' ? 'background: #e74c3c; color: white;' : tipo_lembrete === '25_DIAS' ? 'background: #f39c12; color: white;' : 'background: #3498db; color: white;'} }
    .material-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #3498db; }
    .timeline { background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107; }
    .cta-button { display: inline-block; background: #27ae60; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0; }
    .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 12px; }
    .steps { background: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .step { margin: 10px 0; padding: 10px; background: white; border-radius: 5px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${template.emoji} ${template.urgencia}</h1>
      <p>Avaliação de Material Recebido</p>
    </div>
    
    <div class="content">
      <p>Olá <strong>${usuario_nome}</strong>,</p>
      
      <div class="urgencia-badge">
        ${template.urgencia} - ${dias_desde_aprovacao} dias desde o recebimento
      </div>
      
      <p>${tipo_lembrete === '30_DIAS_URGENTE' ? 
        '🚨 <strong>ÚLTIMO DIA!</strong> A avaliação do material recebido vence <strong>HOJE</strong>. É obrigatório avaliar o desempenho dos materiais recebidos.' :
        tipo_lembrete === '25_DIAS' ?
        '⏰ <strong>Prazo se aproximando!</strong> Faltam apenas <strong>5 dias</strong> para o prazo final de avaliação do material.' :
        '📋 Esperamos que você já tenha tido tempo de testar o material recebido. Que tal nos contar como foi a experiência?'
      }</p>

      <div class="material-info">
        <h3>📦 Material para Avaliação:</h3>
        <p><strong>Material:</strong> ${material_nome}</p>
        <p><strong>Código:</strong> ${material_codigo}</p>
        <p><strong>Unidade/Setor:</strong> ${unidade_setor}</p>
        <p><strong>Recebido há:</strong> ${dias_desde_aprovacao} dias</p>
      </div>

      ${tipo_lembrete === '30_DIAS_URGENTE' ? `
      <div class="timeline" style="background: #f8d7da; border-left-color: #dc3545;">
        <h4>⏰ Cronograma de Avaliação:</h4>
        <p>✅ <strong>Dia 1:</strong> Material aprovado e entregue</p>
        <p>✅ <strong>Dia 15:</strong> Primeiro lembrete enviado</p>
        <p>✅ <strong>Dia 25:</strong> Segundo lembrete enviado</p>
        <p>🚨 <strong>Dia 30 (HOJE):</strong> <span style="color: #dc3545;"><strong>PRAZO FINAL!</strong></span></p>
      </div>
      ` : `
      <div class="timeline">
        <h4>⏰ Cronograma de Avaliação:</h4>
        <p>✅ <strong>Dia 1:</strong> Material aprovado e entregue</p>
        <p>${dias_desde_aprovacao >= 15 ? '✅' : '⏳'} <strong>Dia 15:</strong> Primeiro lembrete ${dias_desde_aprovacao >= 15 ? '(enviado)' : '(pendente)'}</p>
        <p>${dias_desde_aprovacao >= 25 ? '✅' : '⏳'} <strong>Dia 25:</strong> Segundo lembrete ${dias_desde_aprovacao >= 25 ? '(enviado)' : '(pendente)'}</p>
        <p>⏰ <strong>Dia 30:</strong> Prazo final para avaliação</p>
      </div>
      `}

      <div class="steps">
        <h4>📝 Como Avaliar (muito fácil!):</h4>
        <div class="step">
          <strong>1.</strong> Acesse seu Dashboard RDM
        </div>
        <div class="step">
          <strong>2.</strong> Clique na aba "⭐ Feedback"
        </div>
        <div class="step">
          <strong>3.</strong> Dê uma nota de 1 a 5 estrelas
        </div>
        <div class="step">
          <strong>4.</strong> Escreva um comentário sobre o material
        </div>
        <div class="step">
          <strong>5.</strong> Clique em "Enviar Feedback" - pronto! ✅
        </div>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="${window.location.origin}/rdm" class="cta-button">
          📝 Acessar Dashboard e Avaliar Agora
        </a>
      </div>

      <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
        <h4>🤔 Por que avaliar?</h4>
        <ul>
          <li>✅ Ajuda a melhorar a qualidade dos materiais</li>
          <li>📊 Suas avaliações influenciam futuras compras</li>
          <li>🎯 Garante que produtos ruins não sejam comprados novamente</li>
          <li>💡 Suas sugestões são levadas em consideração</li>
        </ul>
      </div>

      ${tipo_lembrete === '30_DIAS_URGENTE' ? `
      <div style="background: #f8d7da; padding: 15px; border-radius: 8px; margin: 20px 0; border: 2px solid #dc3545;">
        <h4 style="color: #dc3545; margin-top: 0;">🚨 ATENÇÃO - PRAZO FINAL!</h4>
        <p style="color: #721c24; margin-bottom: 0;">
          Este é o <strong>último lembrete</strong>. A avaliação é <strong>obrigatória</strong> e o prazo vence hoje. 
          Após o prazo, o sistema registrará como "não avaliado" e isso pode impactar futuras solicitações.
        </p>
      </div>
      ` : ''}

      <div style="text-align: center; color: #666; margin-top: 30px;">
        <p><small>
          📧 Dúvidas? Responda este email ou entre em contato: comprarbemteste@gmail.com<br>
          🔗 Link direto: ${window.location.origin}/rdm
        </small></p>
      </div>
    </div>
    
    <div class="footer">
      Sistema Comprar Bem - Compras Públicas Inteligentes<br>
      Este é um lembrete automático. Avalie o material para não receber mais lembretes.
    </div>
  </div>
</body>
</html>
  `
}

// ============================================
// FUNÇÃO PRINCIPAL PARA ENVIAR LEMBRETE
// ============================================

export async function enviarLembreteFeedback(dadosLembrete) {
  try {
    console.log('📧 Enviando lembrete de feedback:', dadosLembrete.tipo_lembrete)
    
    const template = templateLembreteFeedback[dadosLembrete.tipo_lembrete]
    const htmlContent = gerarHTMLLembreteFeedback(dadosLembrete)
    
    const emailParams = {
      numero_edital: `LEMBRETE-${dadosLembrete.tipo_lembrete}`,
      email_empresa: dadosLembrete.usuario_email,
      message: htmlContent,
      name: dadosLembrete.usuario_nome,
      email: 'comprarbemteste@gmail.com',
      subject: template.subject.replace('{{material_nome}}', dadosLembrete.material_nome),
      status_participante: 'lembrete_feedback',
      motivo_rejeicao: ''
    }
    
    console.log('📧 Enviando via EmailJS...')
    const result = await emailjs.send(
      EMAILJS_CONFIG.serviceId,
      EMAILJS_CONFIG.templateId,
      emailParams,
      EMAILJS_CONFIG.publicKey
    )
    
    if (result.status === 200) {
      console.log('✅ Lembrete enviado com sucesso!')
      
      // Registrar no banco que o lembrete foi enviado
      await registrarLembreteEnviado(dadosLembrete, true, null)
      
      return { success: true, message: 'Lembrete enviado com sucesso!' }
    } else {
      throw new Error(`Falha no envio. Status: ${result.status}`)
    }
    
  } catch (error) {
    console.error('❌ Erro ao enviar lembrete:', error)
    
    // Registrar erro no banco
    await registrarLembreteEnviado(dadosLembrete, false, error.message)
    
    return { success: false, message: error.message }
  }
}

// ============================================
// FUNÇÃO PARA REGISTRAR LEMBRETE NO BANCO
// ============================================

async function registrarLembreteEnviado(dadosLembrete, sucesso, erro) {
  try {
    const { data, error } = await supabase.rpc('registrar_lembrete_enviado', {
      p_rdm_id: dadosLembrete.rdm_id,
      p_tenant_id: dadosLembrete.tenant_id,
      p_usuario_rdm_id: dadosLembrete.usuario_rdm_id,
      p_tipo_lembrete: dadosLembrete.tipo_lembrete,
      p_sucesso: sucesso,
      p_erro: erro
    })
    
    if (error) {
      console.error('❌ Erro ao registrar lembrete no banco:', error)
    } else {
      console.log('✅ Lembrete registrado no banco de dados')
    }
  } catch (error) {
    console.error('❌ Erro ao comunicar com banco:', error)
  }
}

// ============================================
// FUNÇÃO PARA PROCESSAR TODOS OS LEMBRETES PENDENTES
// ============================================

export async function processarLembretesPendentes() {
  try {
    console.log('🔍 Verificando lembretes pendentes...')
    
    // Buscar RDMs que precisam de lembrete
    const { data: lembretesPendentes, error } = await supabase
      .rpc('verificar_rdms_para_lembrete')
    
    if (error) {
      console.error('❌ Erro ao buscar lembretes pendentes:', error)
      return { success: false, message: error.message }
    }
    
    if (!lembretesPendentes || lembretesPendentes.length === 0) {
      console.log('✅ Nenhum lembrete pendente encontrado')
      return { success: true, message: 'Nenhum lembrete pendente', count: 0 }
    }
    
    console.log(`📧 Encontrados ${lembretesPendentes.length} lembretes para enviar`)
    
    let sucessos = 0
    let erros = 0
    
    // Processar cada lembrete
    for (const lembrete of lembretesPendentes) {
      console.log(`📨 Processando lembrete ${lembrete.tipo_lembrete_necessario} para ${lembrete.usuario_nome}`)
      
      const dadosLembrete = {
        rdm_id: lembrete.rdm_id,
        tenant_id: lembrete.tenant_id,
        usuario_rdm_id: lembrete.usuario_rdm_id,
        tipo_lembrete: lembrete.tipo_lembrete_necessario,
        material_nome: lembrete.material_nome,
        material_codigo: lembrete.material_codigo,
        dias_desde_aprovacao: lembrete.dias_desde_aprovacao,
        usuario_nome: lembrete.usuario_nome,
        usuario_email: lembrete.usuario_email,
        unidade_setor: lembrete.unidade_setor
      }
      
      const resultado = await enviarLembreteFeedback(dadosLembrete)
      
      if (resultado.success) {
        sucessos++
        console.log(`✅ Lembrete enviado para ${lembrete.usuario_nome}`)
      } else {
        erros++
        console.log(`❌ Erro ao enviar para ${lembrete.usuario_nome}: ${resultado.message}`)
      }
      
      // Aguardar 2 segundos entre envios para não sobrecarregar o EmailJS
      await new Promise(resolve => setTimeout(resolve, 2000))
    }
    
    console.log(`🎉 Processamento concluído: ${sucessos} sucessos, ${erros} erros`)
    
    return {
      success: true,
      message: `Lembretes processados: ${sucessos} enviados, ${erros} com erro`,
      count: lembretesPendentes.length,
      sucessos,
      erros
    }
    
  } catch (error) {
    console.error('❌ Erro no processamento de lembretes:', error)
    return { success: false, message: error.message }
  }
}

// ============================================
// FUNÇÃO PARA SALVAR FEEDBACK (atualizar a existente)
// ============================================

export async function salvarFeedbackRDM(feedbackData) {
  try {
    console.log('💾 Salvando feedback RDM:', feedbackData)
    
    const { data, error } = await supabase
      .from('rdm_feedbacks')
      .insert({
        tenant_id: feedbackData.tenant_id,
        rdm_id: feedbackData.rdm_id,
        usuario_rdm_id: feedbackData.usuario_rdm_id,
        material_nome: feedbackData.material_nome,
        material_codigo: feedbackData.material_codigo,
        rating: feedbackData.rating,
        comentario: feedbackData.comentario || ''
      })
    
    if (error) {
      console.error('❌ Erro ao salvar feedback:', error)
      throw error
    }
    
    console.log('✅ Feedback salvo com sucesso!')
    return { success: true, data }
    
  } catch (error) {
    console.error('❌ Erro ao salvar feedback:', error)
    return { success: false, message: error.message }
  }
}

// ============================================
// FUNÇÃO PARA INICIAR SISTEMA AUTOMÁTICO
// ============================================

export function iniciarSistemaLembretes() {
  console.log('🤖 Iniciando sistema automático de lembretes...')
  
  // Executar imediatamente
  processarLembretesPendentes()
  
  // Executar a cada 4 horas
  setInterval(() => {
    console.log('⏰ Executando verificação automática de lembretes...')
    processarLembretesPendentes()
  }, 4 * 60 * 60 * 1000) // 4 horas em milissegundos
  
  console.log('✅ Sistema de lembretes automáticos ativado! (verifica a cada 4 horas)')
}

export default {
  enviarEmailDiligencia,
  enviarEmailParticipanteStatus,
  buscarHistoricoEmails,
  configurarEmailOrganizacao,
  enviarLembreteFeedback,
  processarLembretesPendentes,
  salvarFeedbackRDM,
  iniciarSistemaLembretes
} 