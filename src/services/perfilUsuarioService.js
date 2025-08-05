import { supabase, getTenantId } from './supabase'

/**
 * Serviço para gerenciamento de perfis de usuário
 * 4 Perfis: CPM, CCL, Órgão Administrativo, Assessoria Jurídica
 */
export class PerfilUsuarioService {
  
  // =====================================================
  // CONSTANTES DOS PERFIS
  // =====================================================
  
  static PERFIS = {
    CPM: 'cpm',
    CCL: 'ccl', 
    ORGAO_ADMINISTRATIVO: 'orgao_administrativo',
    ASSESSORIA_JURIDICA: 'assessoria_juridica'
  }

  static PERFIS_INFO = {
    [this.PERFIS.CPM]: {
      nome: 'CPM - Comissão Permanente de Padronização',
      descricao: 'Acesso completo exceto Painel CCL',
      cor: 'blue',
      icone: '🔧'
    },
    [this.PERFIS.CCL]: {
      nome: 'CCL - Comissão de Contratação e Licitação', 
      descricao: 'Acesso exclusivo ao Painel CCL',
      cor: 'green',
      icone: '⚖️'
    },
    [this.PERFIS.ORGAO_ADMINISTRATIVO]: {
      nome: 'Órgão Administrativo',
      descricao: 'Processos para assinatura e homologação',
      cor: 'purple', 
      icone: '📋'
    },
    [this.PERFIS.ASSESSORIA_JURIDICA]: {
      nome: 'Assessoria Jurídica',
      descricao: 'Análise jurídica de processos',
      cor: 'orange',
      icone: '⚖️'
    }
  }

  // =====================================================
  // GESTÃO DE PERFIS
  // =====================================================

  /**
   * Obter perfil do usuário atual
   */
  static async obterPerfilUsuarioAtual() {
    try {
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!user) {
        throw new Error('Usuário não autenticado')
      }

      const { data, error } = await supabase
        .from('vw_usuarios_perfis')
        .select('*')
        .eq('id', user.id)
        .single()

      if (error) {
        console.error('Erro ao obter perfil do usuário:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de perfil:', error)
      throw error
    }
  }

  /**
   * Verificar se usuário tem acesso a um módulo
   */
  static async verificarAcessoModulo(modulo, acao = null) {
    try {
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!user) {
        return false
      }

      const { data, error } = await supabase.rpc('verificar_permissao_usuario', {
        p_user_id: user.id,
        p_modulo: modulo,
        p_acao: acao
      })

      if (error) {
        console.error('Erro ao verificar permissão:', error)
        return false
      }

      return data
    } catch (error) {
      console.error('Erro ao verificar acesso:', error)
      return false
    }
  }

  /**
   * Obter módulos permitidos para o usuário atual
   */
  static async obterModulosPermitidos() {
    try {
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user

      if (!user) {
        return []
      }

      const { data, error } = await supabase.rpc('obter_modulos_usuario', {
        p_user_id: user.id
      })

      if (error) {
        console.error('Erro ao obter módulos:', error)
        return []
      }

      return data || []
    } catch (error) {
      console.error('Erro ao obter módulos:', error)
      return []
    }
  }

  /**
   * Atualizar perfil de um usuário
   */
  static async atualizarPerfilUsuario(userId, novoPerfil) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      const { data, error } = await supabase.rpc('atualizar_perfil_usuario', {
        p_user_id: userId,
        p_novo_perfil: novoPerfil
      })

      if (error) {
        console.error('Erro ao atualizar perfil:', error)
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro no serviço de perfil:', error)
      throw error
    }
  }

  /**
   * Listar usuários com seus perfis
   */
  static async listarUsuariosPerfis(filtros = {}) {
    try {
      const tenantId = await getTenantId()
      if (!tenantId) {
        throw new Error('Usuário não autenticado ou sem tenant')
      }

      let query = supabase
        .from('vw_usuarios_perfis')
        .select('*')
        .eq('tenant_id', tenantId)
        .order('nome')

      // Aplicar filtros
      if (filtros.perfil) {
        query = query.eq('perfil_usuario', filtros.perfil)
      }

      if (filtros.busca) {
        query = query.or(`nome.ilike.%${filtros.busca}%,email.ilike.%${filtros.busca}%`)
      }

      const { data, error } = await query

      if (error) {
        console.error('Erro ao listar usuários:', error)
        throw error
      }

      return data || []
    } catch (error) {
      console.error('Erro no serviço de usuários:', error)
      throw error
    }
  }

  // =====================================================
  // VERIFICAÇÕES DE ACESSO ESPECÍFICAS
  // =====================================================

  /**
   * Verificar se é perfil CPM
   */
  static async isCPM() {
    const perfil = await this.obterPerfilUsuarioAtual()
    return perfil?.perfil_usuario === this.PERFIS.CPM
  }

  /**
   * Verificar se é perfil CCL
   */
  static async isCCL() {
    const perfil = await this.obterPerfilUsuarioAtual()
    return perfil?.perfil_usuario === this.PERFIS.CCL
  }

  /**
   * Verificar se é Órgão Administrativo
   */
  static async isOrgaoAdministrativo() {
    const perfil = await this.obterPerfilUsuarioAtual()
    return perfil?.perfil_usuario === this.PERFIS.ORGAO_ADMINISTRATIVO
  }

  /**
   * Verificar se é Assessoria Jurídica
   */
  static async isAssessoriaJuridica() {
    const perfil = await this.obterPerfilUsuarioAtual()
    return perfil?.perfil_usuario === this.PERFIS.ASSESSORIA_JURIDICA
  }

  /**
   * Verificar se pode acessar Painel CCL
   */
  static async podeAcessarPainelCCL() {
    return await this.verificarAcessoModulo('painel_ccl')
  }

  /**
   * Verificar se pode criar processos
   */
  static async podeCriarProcessos() {
    return await this.verificarAcessoModulo('processos', 'criar')
  }

  /**
   * Verificar se pode assinar digitalmente
   */
  static async podeAssinarDigitalmente() {
    return await this.verificarAcessoModulo('processos', 'assinar_digital') ||
           await this.verificarAcessoModulo('processos', 'assinar')
  }

  /**
   * Verificar se pode julgar processos (CCL)
   */
  static async podeJulgarProcessos() {
    return await this.verificarAcessoModulo('processos', 'julgar')
  }

  /**
   * Verificar se pode homologar (Órgão Administrativo)
   */
  static async podeHomologar() {
    return await this.verificarAcessoModulo('processos', 'homologar')
  }

  /**
   * Verificar se pode emitir parecer jurídico
   */
  static async podeEmitirParecerJuridico() {
    return await this.verificarAcessoModulo('processos', 'emitir_parecer')
  }

  // =====================================================
  // UTILITÁRIOS
  // =====================================================

  /**
   * Obter informações de um perfil
   */
  static obterInfoPerfil(perfil) {
    return this.PERFIS_INFO[perfil] || {
      nome: 'Perfil Desconhecido',
      descricao: '',
      cor: 'gray',
      icone: '❓'
    }
  }

  /**
   * Obter lista de todos os perfis disponíveis
   */
  static obterTodosPerfis() {
    return Object.entries(this.PERFIS_INFO).map(([codigo, info]) => ({
      codigo,
      ...info
    }))
  }

  /**
   * Formatar perfil para exibição
   */
  static formatarPerfil(perfil) {
    const info = this.obterInfoPerfil(perfil)
    return `${info.icone} ${info.nome}`
  }

  /**
   * Verificar se perfil permite acesso completo (CPM)
   */
  static isPerfilCompleto(perfil) {
    return perfil === this.PERFIS.CPM
  }

  /**
   * Verificar se perfil é restrito a um módulo específico
   */
  static isPerfilRestrito(perfil) {
    return [
      this.PERFIS.CCL,
      this.PERFIS.ORGAO_ADMINISTRATIVO, 
      this.PERFIS.ASSESSORIA_JURIDICA
    ].includes(perfil)
  }

  /**
   * Obter rotas permitidas baseadas no perfil
   */
  static async obterRotasPermitidas() {
    const modulos = await this.obterModulosPermitidos()
    
    const rotasMap = {
      'dashboard': ['/dashboard'],
      'cadastro_produtos': ['/produtos', '/produtos/novo', '/produtos/editar'],
      'catalogo_marcas': ['/marcas', '/marcas/novo'],
      'classificacao': ['/classificacao'],
      'dcb': ['/dcb', '/dcb/novo'],
      'rdm': ['/rdm', '/feedback'],
      'processos_administrativos': ['/processos', '/processos/novo'],
      'painel_ccl': ['/ccl', '/ccl/processos'],
      'processos_administrativos_admin': ['/processos/administrativo'],
      'processos_administrativos_juridico': ['/processos/juridico']
    }

    const rotasPermitidas = []
    modulos.forEach(modulo => {
      if (rotasMap[modulo]) {
        rotasPermitidas.push(...rotasMap[modulo])
      }
    })

    return rotasPermitidas
  }
}

export default PerfilUsuarioService