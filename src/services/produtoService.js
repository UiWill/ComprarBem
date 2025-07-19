// 📦 Serviço para Gerenciamento de Produtos e Usuários RDM
// Integração com sistema de notificações automáticas

import { supabase } from './supabase'
import { enviarEmailNovoProduto } from './emailService'

// ============================================
// FUNÇÃO PARA ADICIONAR PRODUTO A USUÁRIO RDM
// ============================================

export async function adicionarProdutoUsuarioRDM(produtoData) {
  try {
    console.log('📦 Adicionando produto ao usuário RDM:', produtoData)
    
    const {
      tenant_id,
      usuario_rdm_id,
      produto_id,
      nome_produto,
      codigo_produto,
      descricao_produto,
      categoria_produto,
      data_recebimento = null
    } = produtoData
    
    // Validações
    if (!tenant_id || !usuario_rdm_id || !produto_id) {
      throw new Error('Dados obrigatórios não fornecidos')
    }
    
    // Buscar dados do usuário RDM
    const { data: usuarioRDM, error: usuarioError } = await supabase
      .from('usuarios_rdm')
      .select('*')
      .eq('id', usuario_rdm_id)
      .eq('tenant_id', tenant_id)
      .single()
    
    if (usuarioError || !usuarioRDM) {
      throw new Error('Usuário RDM não encontrado')
    }
    
    // Adicionar produto ao usuário usando a função do banco
    const { data: vinculo, error: vinculoError } = await supabase
      .rpc('adicionar_produto_usuario_rdm', {
        p_tenant_id: tenant_id,
        p_usuario_rdm_id: usuario_rdm_id,
        p_produto_id: produto_id,
        p_data_recebimento: data_recebimento
      })
    
    if (vinculoError) {
      throw new Error('Erro ao vincular produto ao usuário: ' + vinculoError.message)
    }
    
    console.log('✅ Produto vinculado ao usuário RDM com sucesso!')
    
    // Enviar notificação por email automaticamente
    const dadosNotificacao = {
      produto_id: produto_id,
      usuario_rdm_id: usuario_rdm_id,
      usuario_nome: usuarioRDM.nome_usuario,
      usuario_email: usuarioRDM.email,
      nome_produto: nome_produto || 'Produto Aprovado',
      codigo_produto: codigo_produto || `PROD-${produto_id}`,
      descricao_produto: descricao_produto || 'Produto aprovado e disponível para avaliação',
      categoria_produto: categoria_produto || 'Categoria Geral',
      unidade_setor: usuarioRDM.unidade_setor || 'Não informado',
      data_sincronizacao: new Date().toLocaleDateString('pt-BR')
    }
    
    // Enviar email de notificação
    try {
      console.log('📧 Enviando notificação de novo produto por email...')
      const resultadoEmail = await enviarEmailNovoProduto(dadosNotificacao)
      
      if (resultadoEmail.success) {
        console.log('✅ Email de notificação enviado com sucesso!')
        
        // Marcar como notificado no banco
        await supabase
          .from('usuarios_rdm_produtos')
          .update({ 
            notificado_email: true, 
            data_notificacao: new Date().toISOString() 
          })
          .eq('usuario_rdm_id', usuario_rdm_id)
          .eq('produto_id', produto_id)
      } else {
        console.warn('⚠️ Erro ao enviar email de notificação:', resultadoEmail.message)
      }
    } catch (emailError) {
      console.warn('⚠️ Erro ao enviar email de notificação:', emailError.message)
      // Não falhar o processo principal por causa do email
    }
    
    return {
      success: true,
      message: 'Produto adicionado ao usuário RDM com sucesso!',
      vinculo_id: vinculo,
      usuario: usuarioRDM,
      produto: {
        id: produto_id,
        nome: nome_produto,
        codigo: codigo_produto
      }
    }
    
  } catch (error) {
    console.error('❌ Erro ao adicionar produto ao usuário RDM:', error)
    return {
      success: false,
      message: error.message,
      error: error
    }
  }
}

// ============================================
// FUNÇÃO PARA ADICIONAR PRODUTO A MÚLTIPLOS USUÁRIOS
// ============================================

export async function adicionarProdutoMultiplosUsuarios(produtoData, usuariosRDM) {
  try {
    console.log('📦 Adicionando produto a múltiplos usuários RDM:', produtoData, usuariosRDM)
    
    const resultados = []
    
    for (const usuarioRDM of usuariosRDM) {
      const dadosCompletos = {
        ...produtoData,
        usuario_rdm_id: usuarioRDM.id,
        tenant_id: usuarioRDM.tenant_id
      }
      
      const resultado = await adicionarProdutoUsuarioRDM(dadosCompletos)
      resultados.push({
        usuario_rdm_id: usuarioRDM.id,
        usuario_nome: usuarioRDM.nome_usuario,
        usuario_email: usuarioRDM.email,
        ...resultado
      })
      
      // Aguardar 1 segundo entre cada adição para não sobrecarregar o sistema
      await new Promise(resolve => setTimeout(resolve, 1000))
    }
    
    const sucessos = resultados.filter(r => r.success).length
    const erros = resultados.filter(r => !r.success).length
    
    return {
      success: sucessos > 0,
      message: `Produto adicionado: ${sucessos} sucessos, ${erros} erros`,
      resultados: resultados,
      estatisticas: {
        total: resultados.length,
        sucessos: sucessos,
        erros: erros
      }
    }
    
  } catch (error) {
    console.error('❌ Erro ao adicionar produto a múltiplos usuários:', error)
    return {
      success: false,
      message: error.message,
      error: error
    }
  }
}

// ============================================
// FUNÇÃO PARA BUSCAR PRODUTOS DO USUÁRIO RDM
// ============================================

export async function buscarProdutosUsuarioRDM(usuarioRDMId, tenantId) {
  try {
    const { data: produtos, error } = await supabase
      .from('usuarios_rdm_produtos')
      .select(`
        *,
        usuarios_rdm (
          nome_usuario,
          email,
          unidade_setor
        )
      `)
      .eq('usuario_rdm_id', usuarioRDMId)
      .eq('tenant_id', tenantId)
      .order('data_vinculacao', { ascending: false })
    
    if (error) {
      throw new Error('Erro ao buscar produtos do usuário: ' + error.message)
    }
    
    return {
      success: true,
      produtos: produtos || [],
      total: produtos?.length || 0
    }
    
  } catch (error) {
    console.error('❌ Erro ao buscar produtos do usuário RDM:', error)
    return {
      success: false,
      message: error.message,
      produtos: [],
      total: 0
    }
  }
}

// ============================================
// FUNÇÃO PARA MARCAR PRODUTO COMO AVALIADO
// ============================================

export async function marcarProdutoAvaliado(usuarioRDMId, produtoId) {
  try {
    console.log('✅ Marcando produto como avaliado:', { usuarioRDMId, produtoId })
    
    const { data, error } = await supabase
      .rpc('marcar_produto_avaliado', {
        p_usuario_rdm_id: usuarioRDMId,
        p_produto_id: produtoId
      })
    
    if (error) {
      throw new Error('Erro ao marcar produto como avaliado: ' + error.message)
    }
    
    console.log('✅ Produto marcado como avaliado com sucesso!')
    
    return {
      success: true,
      message: 'Produto marcado como avaliado com sucesso!'
    }
    
  } catch (error) {
    console.error('❌ Erro ao marcar produto como avaliado:', error)
    return {
      success: false,
      message: error.message
    }
  }
}

// ============================================
// FUNÇÃO PARA BUSCAR USUÁRIOS RDM ATIVOS
// ============================================

export async function buscarUsuariosRDMAtivos(tenantId) {
  try {
    const { data: usuarios, error } = await supabase
      .from('usuarios_rdm')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('ativo', true)
      .order('nome_usuario')
    
    if (error) {
      throw new Error('Erro ao buscar usuários RDM: ' + error.message)
    }
    
    return {
      success: true,
      usuarios: usuarios || [],
      total: usuarios?.length || 0
    }
    
  } catch (error) {
    console.error('❌ Erro ao buscar usuários RDM ativos:', error)
    return {
      success: false,
      message: error.message,
      usuarios: [],
      total: 0
    }
  }
}

// ============================================
// FUNÇÃO PARA REMOVER PRODUTO DO USUÁRIO RDM
// ============================================

export async function removerProdutoUsuarioRDM(usuarioRDMId, produtoId, tenantId) {
  try {
    console.log('🗑️ Removendo produto do usuário RDM:', { usuarioRDMId, produtoId })
    
    const { error } = await supabase
      .from('usuarios_rdm_produtos')
      .delete()
      .eq('usuario_rdm_id', usuarioRDMId)
      .eq('produto_id', produtoId)
      .eq('tenant_id', tenantId)
    
    if (error) {
      throw new Error('Erro ao remover produto do usuário: ' + error.message)
    }
    
    console.log('✅ Produto removido do usuário RDM com sucesso!')
    
    return {
      success: true,
      message: 'Produto removido do usuário com sucesso!'
    }
    
  } catch (error) {
    console.error('❌ Erro ao remover produto do usuário RDM:', error)
    return {
      success: false,
      message: error.message
    }
  }
}

// ============================================
// FUNÇÃO PARA OBTER RELATÓRIO DE PRODUTOS
// ============================================

export async function obterRelatorioProdutos(tenantId) {
  try {
    const { data: relatorio, error } = await supabase
      .from('vw_avaliacoes_pendentes')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('data_vinculacao', { ascending: false })
    
    if (error) {
      throw new Error('Erro ao obter relatório de produtos: ' + error.message)
    }
    
    const estatisticas = {
      total: relatorio?.length || 0,
      avaliados: relatorio?.filter(r => r.avaliado).length || 0,
      pendentes: relatorio?.filter(r => !r.avaliado).length || 0,
      vencidos: relatorio?.filter(r => r.status_avaliacao === 'Vencido').length || 0,
      urgentes: relatorio?.filter(r => r.status_avaliacao === 'Urgente').length || 0
    }
    
    return {
      success: true,
      relatorio: relatorio || [],
      estatisticas: estatisticas
    }
    
  } catch (error) {
    console.error('❌ Erro ao obter relatório de produtos:', error)
    return {
      success: false,
      message: error.message,
      relatorio: [],
      estatisticas: {}
    }
  }
}

// ============================================
// FUNÇÃO AUXILIAR PARA GERAR CÓDIGO DE PRODUTO
// ============================================

export function gerarCodigoProduto(nome, categoria = 'GERAL') {
  const timestamp = Date.now()
  const nomeSlug = nome.toLowerCase()
    .replace(/[^a-z0-9]/g, '')
    .substring(0, 8)
  
  return `${categoria.toUpperCase()}-${nomeSlug}-${timestamp}`.substring(0, 50)
}

// ============================================
// FUNÇÃO PARA SINCRONIZAR PRODUTO EXISTENTE
// ============================================

export async function sincronizarProdutoExistente(produtoId, usuariosRDMIds, tenantId) {
  try {
    console.log('🔄 Sincronizando produto existente:', { produtoId, usuariosRDMIds, tenantId })
    
    const resultados = []
    
    for (const usuarioRDMId of usuariosRDMIds) {
      const dadosProduto = {
        tenant_id: tenantId,
        usuario_rdm_id: usuarioRDMId,
        produto_id: produtoId,
        nome_produto: 'Produto Sincronizado',
        codigo_produto: gerarCodigoProduto('Produto Sincronizado'),
        descricao_produto: 'Produto sincronizado automaticamente',
        categoria_produto: 'Sincronização'
      }
      
      const resultado = await adicionarProdutoUsuarioRDM(dadosProduto)
      resultados.push({
        usuario_rdm_id: usuarioRDMId,
        ...resultado
      })
      
      // Aguardar 1 segundo entre cada sincronização
      await new Promise(resolve => setTimeout(resolve, 1000))
    }
    
    const sucessos = resultados.filter(r => r.success).length
    const erros = resultados.filter(r => !r.success).length
    
    return {
      success: sucessos > 0,
      message: `Produto sincronizado: ${sucessos} sucessos, ${erros} erros`,
      resultados: resultados,
      estatisticas: {
        total: resultados.length,
        sucessos: sucessos,
        erros: erros
      }
    }
    
  } catch (error) {
    console.error('❌ Erro ao sincronizar produto existente:', error)
    return {
      success: false,
      message: error.message,
      error: error
    }
  }
}

// ============================================
// EXPORTS PRINCIPAIS
// ============================================

export default {
  adicionarProdutoUsuarioRDM,
  adicionarProdutoMultiplosUsuarios,
  buscarProdutosUsuarioRDM,
  marcarProdutoAvaliado,
  buscarUsuariosRDMAtivos,
  removerProdutoUsuarioRDM,
  obterRelatorioProdutos,
  gerarCodigoProduto,
  sincronizarProdutoExistente
}