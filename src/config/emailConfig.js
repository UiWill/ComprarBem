// ⚙️ CONFIGURAÇÃO DE EMAIL DA ORGANIZAÇÃO
// Configure aqui os dados da sua organização para envio de emails

export const EMAIL_ORGANIZACAO = {
  // 📧 Dados do remetente
  email: 'cpm@suaorganizacao.com.br',
  nome: 'CPM - Comissão de Padronização de Materiais',
  
  // 🏢 Dados da organização
  organizacao: {
    nome: 'Sua Organização',
    cnpj: '00.000.000/0000-00',
    endereco: 'Endereço da Organização',
    telefone: '(00) 0000-0000',
    website: 'https://www.suaorganizacao.com.br'
  },
  
  // 🔧 Configurações técnicas
  provedor: {
    // Para SendGrid
    sendgrid: {
      apiKey: process.env.VUE_APP_SENDGRID_API_KEY,
      apiUrl: 'https://api.sendgrid.com/v3/mail/send'
    },
    
    // Para Mailgun  
    mailgun: {
      apiKey: process.env.VUE_APP_MAILGUN_API_KEY,
      domain: process.env.VUE_APP_MAILGUN_DOMAIN,
      apiUrl: 'https://api.mailgun.net/v3'
    },
    
    // Para SMTP genérico
    smtp: {
      host: process.env.VUE_APP_SMTP_HOST,
      port: process.env.VUE_APP_SMTP_PORT,
      secure: process.env.VUE_APP_SMTP_SECURE === 'true',
      user: process.env.VUE_APP_SMTP_USER,
      pass: process.env.VUE_APP_SMTP_PASS
    }
  }
}

// 📝 TEMPLATES DE ASSINATURA
export const ASSINATURA_EMAIL = `
<div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 12px;">
  <p><strong>${EMAIL_ORGANIZACAO.organizacao.nome}</strong></p>
  <p><strong>${EMAIL_ORGANIZACAO.nome}</strong></p>
  <p>📞 ${EMAIL_ORGANIZACAO.organizacao.telefone}</p>
  <p>📧 ${EMAIL_ORGANIZACAO.email}</p>
  <p>🌐 ${EMAIL_ORGANIZACAO.organizacao.website}</p>
  <p>📄 CNPJ: ${EMAIL_ORGANIZACAO.organizacao.cnpj}</p>
  <p>📍 ${EMAIL_ORGANIZACAO.organizacao.endereco}</p>
  <hr style="border: none; border-top: 1px solid #ddd; margin: 10px 0;">
  <p><em>Este é um email automático do sistema de gestão da CPM. Não responda diretamente a este email.</em></p>
</div>
`

// 🎨 ESTILOS CSS PARA EMAILS
export const EMAIL_STYLES = `
<style>
  .email-container {
    font-family: Arial, sans-serif;
    max-width: 600px;
    margin: 0 auto;
    background: #ffffff;
  }
  
  .email-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 20px;
    text-align: center;
  }
  
  .email-body {
    padding: 30px;
    background: #f8f9fa;
    line-height: 1.6;
  }
  
  .info-card {
    background: white;
    padding: 20px;
    border-left: 4px solid #667eea;
    margin: 20px 0;
  }
  
  .warning-card {
    background: #fff3cd;
    padding: 20px;
    border-left: 4px solid #ffc107;
    margin: 20px 0;
  }
  
  .danger-card {
    background: #f8d7da;
    padding: 20px;
    border-left: 4px solid #dc3545;
    margin: 20px 0;
  }
  
  .success-card {
    background: #d4edda;
    padding: 20px;
    border-left: 4px solid #28a745;
    margin: 20px 0;
  }
  
  .btn-primary {
    background: #667eea;
    color: white;
    padding: 12px 24px;
    text-decoration: none;
    border-radius: 5px;
    display: inline-block;
    margin: 10px 0;
  }
</style>
`

// 🔧 FUNÇÃO PARA ATUALIZAR CONFIGURAÇÕES
export function atualizarConfigEmail(novasConfigs) {
  Object.assign(EMAIL_ORGANIZACAO, novasConfigs)
}

export default {
  EMAIL_ORGANIZACAO,
  ASSINATURA_EMAIL,
  EMAIL_STYLES,
  atualizarConfigEmail
} 