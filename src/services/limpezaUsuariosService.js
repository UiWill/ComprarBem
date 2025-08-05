import { supabase } from './supabase'

/**
 * Serviço para limpeza de usuários órfãos
 * Remove usuários que ficaram no Auth mas não na tabela usuarios
 */
export class LimpezaUsuariosService {

  /**
   * Limpar usuários específicos por email
   */
  static async limparUsuariosPorEmails(emails) {
    console.log('🧹 Iniciando limpeza de usuários órfãos para emails:', emails)
    
    const resultados = []
    
    for (const email of emails) {
      try {
        console.log(`🔍 Verificando usuário: ${email}`)
        
        // 1. Verificar se existe na tabela usuarios
        const { data: usuarioTabela } = await supabase
          .from('usuarios')
          .select('email')
          .eq('email', email)
          .maybeSingle()
        
        // 2. Se não existe na tabela mas existe no Auth, podemos tentar remover
        if (!usuarioTabela) {
          console.log(`❌ Usuário ${email} não encontrado na tabela usuarios - pode ser órfão no Auth`)
          
          // Nota: O Supabase não permite delete direto do Auth via JavaScript
          // Mas podemos registrar o problema
          resultados.push({
            email,
            status: 'orfao_detectado',
            mensagem: 'Usuário existe no Auth mas não na tabela usuarios'
          })
        } else {
          console.log(`✅ Usuário ${email} existe corretamente na tabela`)
          resultados.push({
            email,
            status: 'ok',
            mensagem: 'Usuário existe corretamente'
          })
        }
        
      } catch (error) {
        console.error(`Erro ao verificar ${email}:`, error)
        resultados.push({
          email,
          status: 'erro',
          mensagem: error.message
        })
      }
    }
    
    return resultados
  }

  /**
   * Verificar se email está livre para uso
   */
  static async emailEstaLivre(email) {
    try {
      // Verificar na tabela usuarios
      const { data: usuarioTabela } = await supabase
        .from('usuarios')
        .select('email')
        .eq('email', email)
        .maybeSingle()
      
      return !usuarioTabela
    } catch (error) {
      console.error('Erro ao verificar email:', error)
      return false
    }
  }

  /**
   * Listar todos os usuários da tabela usuarios
   */
  static async listarUsuariosTabela() {
    try {
      const { data, error } = await supabase
        .from('usuarios')
        .select('id, email, nome, tipo, perfil_usuario, tenant_id, ativo')
        .order('criado_em', { ascending: false })
      
      if (error) throw error
      
      return data || []
    } catch (error) {
      console.error('Erro ao listar usuários:', error)
      throw error
    }
  }

  /**
   * Remover usuário específico da tabela usuarios
   */
  static async removerUsuarioTabela(email) {
    try {
      console.log(`🗑️ Removendo usuário ${email} da tabela usuarios`)
      
      const { error } = await supabase
        .from('usuarios')
        .delete()
        .eq('email', email)
      
      if (error) throw error
      
      console.log(`✅ Usuário ${email} removido da tabela usuarios`)
      return true
    } catch (error) {
      console.error(`Erro ao remover usuário ${email}:`, error)
      throw error
    }
  }

  /**
   * Limpar tenant específico
   */
  static async removerTenant(tenantId) {
    try {
      console.log(`🗑️ Removendo tenant ${tenantId}`)
      
      // Primeiro remover usuários do tenant
      await supabase
        .from('usuarios')
        .delete()
        .eq('tenant_id', tenantId)
      
      // Depois remover o tenant
      const { error } = await supabase
        .from('tenants')
        .delete()
        .eq('id', tenantId)
      
      if (error) throw error
      
      console.log(`✅ Tenant ${tenantId} removido`)
      return true
    } catch (error) {
      console.error(`Erro ao remover tenant ${tenantId}:`, error)
      throw error
    }
  }

  /**
   * Função de limpeza completa para teste
   */
  static async limpezaCompleta(emailsParaLimpar) {
    console.log('🧹 LIMPEZA COMPLETA INICIADA')
    console.log('Emails para limpar:', emailsParaLimpar)
    
    try {
      // 1. Remover da tabela usuarios
      for (const email of emailsParaLimpar) {
        try {
          await this.removerUsuarioTabela(email)
        } catch (error) {
          console.warn(`Aviso: não foi possível remover ${email} da tabela usuarios`)
        }
      }
      
      // 2. Verificar se ficou algum tenant órfão
      const { data: tenantsOrfaos } = await supabase
        .from('tenants')
        .select('id, nome')
        .not('id', 'in', `(${
          (await supabase.from('usuarios').select('tenant_id').neq('tenant_id', null))
            .data?.map(u => `'${u.tenant_id}'`).join(',') || "''"
        })`)
      
      if (tenantsOrfaos && tenantsOrfaos.length > 0) {
        console.log('🗑️ Removendo tenants órfãos:', tenantsOrfaos)
        for (const tenant of tenantsOrfaos) {
          try {
            await this.removerTenant(tenant.id)
          } catch (error) {
            console.warn(`Aviso: erro ao remover tenant órfão ${tenant.id}`)
          }
        }
      }
      
      console.log('✅ LIMPEZA COMPLETA FINALIZADA')
      return true
      
    } catch (error) {
      console.error('Erro na limpeza completa:', error)
      throw error
    }
  }
}

export default LimpezaUsuariosService