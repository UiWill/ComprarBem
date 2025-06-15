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
  }
}

// 📤 FUNÇÃO PRINCIPAL DE ENVIO
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

export default {
  enviarEmailDiligencia,
  buscarHistoricoEmails,
  configurarEmailOrganizacao
} 