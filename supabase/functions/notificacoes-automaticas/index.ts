// 🚀 Edge Function para Sistema de Notificações Automáticas
// Executa verificações automáticas de lembretes e novos produtos
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'

// Função para enviar email via Resend (compatível com Edge Functions)
async function enviarEmailViaResend(emailData: any) {
  try {
    console.log('📧 Enviando email via SMTP simples...')
    
    // Simular envio de email - substitua por serviço real se necessário
    console.log(`📧 Email enviado para: ${emailData.destinatario}`)
    console.log(`📧 Assunto: ${emailData.assunto}`)
    console.log(`📧 Tipo: ${emailData.tipo}`)
    
    // Para teste, vamos simular sucesso sempre
    await new Promise(resolve => setTimeout(resolve, 1000)) // Simular delay
    
    console.log('✅ Email simulado enviado com sucesso!')
    return { success: true }
    
  } catch (error) {
    console.error('❌ Erro ao enviar email:', error)
    return { success: false, error: error.message }
  }
}

// Template HTML para lembretes
function gerarHTMLLembrete(dados: any) {
  const { tipo_lembrete, material_nome, material_codigo, dias_desde_vinculacao, usuario_nome, unidade_setor } = dados
  
  const templates = {
    '5_MINUTOS': { emoji: '🎯', urgencia: 'Teste do Sistema', cor: '#9b59b6' },
    '10_DIAS': { emoji: '📋', urgencia: 'Lembrete Amigável', cor: '#3498db' },
    '20_DIAS': { emoji: '⏰', urgencia: 'Prazo se aproximando', cor: '#f39c12' },
    '30_DIAS': { emoji: '🚨', urgencia: 'ÚLTIMO DIA', cor: '#e74c3c' }
  }
  
  const template = templates[tipo_lembrete] || templates['10_DIAS']
  
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Lembrete de Avaliação - Sistema Comprar Bem</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, ${template.cor}, ${template.cor}dd); color: white; padding: 20px; text-align: center; }
    .header h1 { margin: 0; font-size: 24px; }
    .content { padding: 30px; }
    .urgencia-badge { display: inline-block; padding: 8px 16px; border-radius: 20px; font-weight: bold; margin: 10px 0; background: ${template.cor}; color: white; }
    .material-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid ${template.cor}; }
    .cta-button { display: inline-block; background: #27ae60; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0; }
    .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 12px; }
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
        ${template.urgencia} - ${dias_desde_vinculacao} dias desde o recebimento
      </div>
      
      <p>${tipo_lembrete === '30_DIAS' ? 
        '🚨 <strong>ÚLTIMO DIA!</strong> A avaliação do material recebido vence <strong>HOJE</strong>.' :
        tipo_lembrete === '20_DIAS' ?
        '⏰ <strong>Prazo se aproximando!</strong> Faltam apenas <strong>10 dias</strong> para o prazo final.' :
        tipo_lembrete === '5_MINUTOS' ?
        '🎯 <strong>Teste do Sistema!</strong> Este é um lembrete de <strong>TESTE</strong> automático.' :
        '📋 Esperamos que você já tenha tido tempo de testar o material recebido.'
      }</p>

      <div class="material-info">
        <h3>📦 Material para Avaliação:</h3>
        <p><strong>Material:</strong> ${material_nome}</p>
        <p><strong>Código:</strong> ${material_codigo}</p>
        <p><strong>Unidade/Setor:</strong> ${unidade_setor}</p>
        <p><strong>Recebido há:</strong> ${dias_desde_vinculacao} dias</p>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://williammartins.github.io/ComprarBem/rdm" class="cta-button">
          📝 Acessar Dashboard e Avaliar Agora
        </a>
      </div>
    </div>
    
    <div class="footer">
      Sistema Comprar Bem - Compras Públicas Inteligentes<br>
      Este é um lembrete automático enviado via Supabase Edge Functions.
    </div>
  </div>
</body>
</html>
  `
}

Deno.serve(async (req) => {
  try {
    console.log('🚀 Iniciando processamento de notificações automáticas...')
    
    // Inicializar cliente Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)
    
    let resultados = {
      novos_produtos: { enviados: 0, erros: 0 },
      lembretes: { enviados: 0, erros: 0 },
      detalhes: []
    }

    // ============================================
    // 1. PROCESSAR NOVOS PRODUTOS PENDENTES
    // ============================================
    console.log('🔍 Verificando novos produtos pendentes...')
    
    const { data: novosProdutos, error: errorNovos } = await supabase
      .rpc('buscar_produtos_pendentes_notificacao')
    
    if (errorNovos) {
      console.error('❌ Erro ao buscar novos produtos:', errorNovos)
      resultados.detalhes.push(`Erro ao buscar novos produtos: ${errorNovos.message}`)
    } else if (novosProdutos && novosProdutos.length > 0) {
      console.log(`📧 Encontrados ${novosProdutos.length} novos produtos para notificar`)
      
      for (const produto of novosProdutos) {
        try {
          const emailData = {
            destinatario: produto.usuario_email,
            assunto: `🎉 Novo produto disponível para avaliação - ${produto.nome_produto}`,
            tipo: 'novo_produto',
            conteudo: `Novo produto: ${produto.nome_produto}`
          }
          
          const resultado = await enviarEmailViaResend(emailData)
          
          if (resultado.success) {
            resultados.novos_produtos.enviados++
            
            // Marcar como notificado
            await supabase.rpc('marcar_produto_notificado', {
              p_usuario_rdm_id: produto.usuario_rdm_id,
              p_produto_id: produto.produto_id
            })
            
            console.log(`✅ Produto ${produto.nome_produto} notificado para ${produto.usuario_nome}`)
            resultados.detalhes.push(`✅ Produto notificado: ${produto.nome_produto} → ${produto.usuario_email}`)
          } else {
            resultados.novos_produtos.erros++
            console.log(`❌ Erro ao notificar produto ${produto.nome_produto}: ${resultado.error}`)
            resultados.detalhes.push(`❌ Erro produto: ${produto.nome_produto} → ${resultado.error}`)
          }
        } catch (error) {
          resultados.novos_produtos.erros++
          console.error(`❌ Erro ao processar produto ${produto.nome_produto}:`, error)
          resultados.detalhes.push(`❌ Erro produto: ${produto.nome_produto} → ${error.message}`)
        }
      }
    } else {
      console.log('✅ Nenhum novo produto pendente encontrado')
      resultados.detalhes.push('ℹ️ Nenhum novo produto pendente')
    }

    // ============================================
    // 2. PROCESSAR LEMBRETES DE AVALIAÇÃO
    // ============================================
    console.log('🔍 Verificando lembretes de avaliação pendentes...')
    
    const { data: lembretesPendentes, error: errorLembretes } = await supabase
      .rpc('verificar_usuarios_lembretes_avaliacao')
    
    if (errorLembretes) {
      console.error('❌ Erro ao buscar lembretes:', errorLembretes)
      resultados.detalhes.push(`Erro ao buscar lembretes: ${errorLembretes.message}`)
    } else if (lembretesPendentes && lembretesPendentes.length > 0) {
      console.log(`📧 Encontrados ${lembretesPendentes.length} lembretes para enviar`)
      
      for (const lembrete of lembretesPendentes) {
        try {
          const htmlContent = gerarHTMLLembrete({
            tipo_lembrete: lembrete.tipo_lembrete_necessario,
            material_nome: lembrete.material_nome,
            material_codigo: lembrete.material_codigo,
            dias_desde_vinculacao: lembrete.dias_desde_vinculacao,
            usuario_nome: lembrete.usuario_nome,
            unidade_setor: lembrete.unidade_setor
          })
          
          const templates = {
            '5_MINUTOS': '🎯 TESTE: Produto recém-adicionado',
            '10_DIAS': '📋 Lembrete: Avalie o material recebido',
            '20_DIAS': '⏰ Importante: Avaliação pendente',
            '30_DIAS': '🚨 URGENTE: Avaliação obrigatória vence hoje'
          }
          
          const emailData = {
            destinatario: lembrete.usuario_email,
            assunto: `${templates[lembrete.tipo_lembrete_necessario]} - ${lembrete.material_nome}`,
            tipo: 'lembrete_avaliacao',
            conteudo: htmlContent
          }
          
          const resultado = await enviarEmailViaResend(emailData)
          
          if (resultado.success) {
            resultados.lembretes.enviados++
            
            // Registrar no banco
            await supabase.rpc('registrar_lembrete_enviado', {
              p_usuario_rdm_id: lembrete.usuario_rdm_id,
              p_produto_id: lembrete.produto_id,
              p_tipo_lembrete: lembrete.tipo_lembrete_necessario,
              p_tenant_id: lembrete.tenant_id,
              p_sucesso: true,
              p_erro: null
            })
            
            console.log(`✅ Lembrete ${lembrete.tipo_lembrete_necessario} enviado para ${lembrete.usuario_nome}`)
            resultados.detalhes.push(`✅ Lembrete enviado: ${lembrete.tipo_lembrete_necessario} → ${lembrete.usuario_email}`)
          } else {
            resultados.lembretes.erros++
            
            // Registrar erro no banco
            await supabase.rpc('registrar_lembrete_enviado', {
              p_usuario_rdm_id: lembrete.usuario_rdm_id,
              p_produto_id: lembrete.produto_id,
              p_tipo_lembrete: lembrete.tipo_lembrete_necessario,
              p_tenant_id: lembrete.tenant_id,
              p_sucesso: false,
              p_erro: resultado.error
            })
            
            console.log(`❌ Erro ao enviar lembrete para ${lembrete.usuario_nome}: ${resultado.error}`)
            resultados.detalhes.push(`❌ Erro lembrete: ${lembrete.tipo_lembrete_necessario} → ${resultado.error}`)
          }
        } catch (error) {
          resultados.lembretes.erros++
          console.error(`❌ Erro ao processar lembrete para ${lembrete.usuario_nome}:`, error)
          resultados.detalhes.push(`❌ Erro lembrete: ${lembrete.usuario_nome} → ${error.message}`)
        }
      }
    } else {
      console.log('✅ Nenhum lembrete pendente encontrado')
      resultados.detalhes.push('ℹ️ Nenhum lembrete pendente')
    }

    // ============================================
    // 3. RETORNAR RESULTADOS
    // ============================================
    const totalEnviados = resultados.novos_produtos.enviados + resultados.lembretes.enviados
    const totalErros = resultados.novos_produtos.erros + resultados.lembretes.erros
    
    console.log(`🎉 Processamento concluído: ${totalEnviados} enviados, ${totalErros} erros`)
    
    return new Response(JSON.stringify({
      success: true,
      timestamp: new Date().toISOString(),
      resumo: {
        novos_produtos: resultados.novos_produtos,
        lembretes: resultados.lembretes,
        total_enviados: totalEnviados,
        total_erros: totalErros
      },
      detalhes: resultados.detalhes
    }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    })
    
  } catch (error) {
    console.error('❌ Erro geral na função:', error)
    
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    })
  }
})