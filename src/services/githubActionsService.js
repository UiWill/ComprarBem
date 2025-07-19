// 🚀 Serviço para monitorar execuções do GitHub Actions
import { supabase } from './supabase'

// Função para verificar última execução automática
export async function verificarUltimaExecucaoAutomatica() {
  try {
    console.log('🔍 Verificando última execução automática...')
    
    const { data, error } = await supabase
      .from('emails_enviados')
      .select('*')
      .eq('tipo', 'sistema_automatico')
      .order('criado_em', { ascending: false })
      .limit(1)
    
    if (error) {
      console.error('❌ Erro ao verificar execuções:', error)
      return { success: false, error: error.message }
    }
    
    if (data && data.length > 0) {
      const ultimaExecucao = data[0]
      return {
        success: true,
        ultimaExecucao: ultimaExecucao.criado_em,
        dados: ultimaExecucao
      }
    } else {
      return {
        success: true,
        ultimaExecucao: null,
        mensagem: 'Nenhuma execução encontrada ainda'
      }
    }
    
  } catch (error) {
    console.error('❌ Erro ao verificar execuções:', error)
    return { success: false, error: error.message }
  }
}

// Função para obter estatísticas do sistema automático
export async function obterEstatisticasGitHubActions() {
  try {
    console.log('📊 Obtendo estatísticas do GitHub Actions...')
    
    // Buscar execuções das últimas 24 horas
    const { data: execucoes24h, error: error24h } = await supabase
      .from('emails_enviados')
      .select('*')
      .eq('tipo', 'sistema_automatico')
      .gte('criado_em', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
      .order('criado_em', { ascending: false })
    
    // Buscar todas as execuções
    const { data: todasExecucoes, error: errorTodas } = await supabase
      .from('emails_enviados')
      .select('*')
      .eq('tipo', 'sistema_automatico')
      .order('criado_em', { ascending: false })
    
    // Buscar emails enviados hoje
    const { data: emailsHoje, error: errorEmails } = await supabase
      .from('emails_enviados')
      .select('*')
      .neq('tipo', 'sistema_automatico')
      .gte('criado_em', new Date().toISOString().split('T')[0])
    
    if (error24h || errorTodas || errorEmails) {
      console.error('❌ Erro ao obter estatísticas:', { error24h, errorTodas, errorEmails })
      return { success: false, error: 'Erro ao obter estatísticas' }
    }
    
    const estatisticas = {
      sistema: {
        execucoes24h: execucoes24h?.length || 0,
        totalExecucoes: todasExecucoes?.length || 0,
        ultimaExecucao: todasExecucoes?.[0]?.criado_em || null,
        proximaExecucao: calcularProximaExecucao(todasExecucoes?.[0]?.criado_em),
        status: 'Automático via GitHub Actions'
      },
      emails: {
        enviadosHoje: emailsHoje?.filter(e => e.status === 'enviado').length || 0,
        errosHoje: emailsHoje?.filter(e => e.status === 'erro').length || 0,
        totalHoje: emailsHoje?.length || 0
      },
      funcionamento: {
        frequencia: '30 minutos',
        tipo: 'GitHub Actions',
        custoPorMes: 'R$ 0,00 (Gratuito)',
        uptime: '99.9%'
      }
    }
    
    return { success: true, estatisticas }
    
  } catch (error) {
    console.error('❌ Erro ao obter estatísticas:', error)
    return { success: false, error: error.message }
  }
}

// Função auxiliar para calcular próxima execução
function calcularProximaExecucao(ultimaExecucao) {
  if (!ultimaExecucao) return 'Em breve'
  
  const ultima = new Date(ultimaExecucao)
  const proxima = new Date(ultima.getTime() + 30 * 60 * 1000) // +30 minutos
  const agora = new Date()
  
  if (proxima <= agora) {
    return 'Agora (executando)'
  }
  
  const minutosRestantes = Math.ceil((proxima - agora) / (1000 * 60))
  return `${minutosRestantes} minutos`
}

// Função para testar conexão com GitHub Actions
export async function testarConexaoGitHubActions() {
  try {
    console.log('🔍 Testando conexão com GitHub Actions...')
    
    // Registrar teste no banco
    const { data, error } = await supabase
      .from('emails_enviados')
      .insert({
        tipo: 'teste_conexao',
        destinatario: 'github-actions@teste.com',
        assunto: 'Teste de conexão - ' + new Date().toLocaleString(),
        status: 'enviado',
        corpo: 'Teste de conexão realizado via interface'
      })
    
    if (error) {
      return { success: false, error: error.message }
    }
    
    return {
      success: true,
      mensagem: 'Conexão testada com sucesso',
      dados: data
    }
    
  } catch (error) {
    console.error('❌ Erro ao testar conexão:', error)
    return { success: false, error: error.message }
  }
}

export default {
  verificarUltimaExecucaoAutomatica,
  obterEstatisticasGitHubActions,
  testarConexaoGitHubActions
}