import { ref, computed, onMounted } from 'vue'
import PerfilUsuarioService from '../services/perfilUsuarioService'

/**
 * Composable para gerenciar perfis de usuário
 * Facilita o uso do sistema de perfis nos componentes Vue
 */
export function usePerfilUsuario() {
  // =====================================================
  // STATE
  // =====================================================
  
  const perfilUsuario = ref(null)
  const modulosPermitidos = ref([])
  const carregandoPerfil = ref(false)
  const erroPerfil = ref(null)

  // =====================================================
  // COMPUTED
  // =====================================================

  /**
   * Verificar se é perfil CPM
   */
  const isCPM = computed(() => {
    return perfilUsuario.value?.perfil_usuario === PerfilUsuarioService.PERFIS.CPM
  })

  /**
   * Verificar se é perfil CCL
   */
  const isCCL = computed(() => {
    return perfilUsuario.value?.perfil_usuario === PerfilUsuarioService.PERFIS.CCL
  })

  /**
   * Verificar se é Órgão Administrativo
   */
  const isOrgaoAdministrativo = computed(() => {
    return perfilUsuario.value?.perfil_usuario === PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO
  })

  /**
   * Verificar se é Assessoria Jurídica
   */
  const isAssessoriaJuridica = computed(() => {
    return perfilUsuario.value?.perfil_usuario === PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA
  })

  /**
   * Obter informações formatadas do perfil
   */
  const infoPerfil = computed(() => {
    if (!perfilUsuario.value?.perfil_usuario) return null
    return PerfilUsuarioService.obterInfoPerfil(perfilUsuario.value.perfil_usuario)
  })

  /**
   * Verificar se tem acesso completo (CPM)
   */
  const temAcessoCompleto = computed(() => {
    return isCPM.value
  })

  /**
   * Verificar se perfil é restrito
   */
  const isPerfilRestrito = computed(() => {
    if (!perfilUsuario.value?.perfil_usuario) return false
    return PerfilUsuarioService.isPerfilRestrito(perfilUsuario.value.perfil_usuario)
  })

  /**
   * Nome formatado do perfil
   */
  const nomePerfilFormatado = computed(() => {
    if (!perfilUsuario.value?.perfil_usuario) return ''
    return PerfilUsuarioService.formatarPerfil(perfilUsuario.value.perfil_usuario)
  })

  // =====================================================
  // METHODS
  // =====================================================

  /**
   * Carregar perfil do usuário atual
   */
  const carregarPerfil = async () => {
    try {
      carregandoPerfil.value = true
      erroPerfil.value = null
      
      const [perfil, modulos] = await Promise.all([
        PerfilUsuarioService.obterPerfilUsuarioAtual(),
        PerfilUsuarioService.obterModulosPermitidos()
      ])
      
      perfilUsuario.value = perfil
      modulosPermitidos.value = modulos
      
    } catch (error) {
      console.error('Erro ao carregar perfil:', error)
      erroPerfil.value = error.message
    } finally {
      carregandoPerfil.value = false
    }
  }

  /**
   * Verificar acesso a um módulo
   */
  const verificarAcesso = async (modulo, acao = null) => {
    try {
      return await PerfilUsuarioService.verificarAcessoModulo(modulo, acao)
    } catch (error) {
      console.error('Erro ao verificar acesso:', error)
      return false
    }
  }

  /**
   * Verificar se pode acessar uma rota
   */
  const podeAcessarRota = (rota) => {
    // Rotas públicas sempre permitidas
    const rotasPublicas = ['/', '/login', '/sobre', '/contato']
    if (rotasPublicas.includes(rota)) return true

    // CPM tem acesso a tudo exceto CCL
    if (isCPM.value) {
      return !rota.includes('/ccl')
    }

    // CCL só acessa rotas do painel CCL
    if (isCCL.value) {
      return rota.includes('/ccl')
    }

    // Órgão Administrativo só acessa processos administrativos
    if (isOrgaoAdministrativo.value) {
      return rota.includes('/processos') && rota.includes('/administrativo')
    }

    // Assessoria Jurídica só acessa processos jurídicos
    if (isAssessoriaJuridica.value) {
      return rota.includes('/processos') && rota.includes('/juridico')
    }

    return false
  }

  /**
   * Verificações específicas de permissão
   */
  const podeAcessarPainelCCL = async () => {
    return await verificarAcesso('painel_ccl')
  }

  const podeCriarProcessos = async () => {
    return await verificarAcesso('processos', 'criar')
  }

  const podeAssinarDigitalmente = async () => {
    return await verificarAcesso('processos', 'assinar_digital') ||
           await verificarAcesso('processos', 'assinar')
  }

  const podeJulgarProcessos = async () => {
    return await verificarAcesso('processos', 'julgar')
  }

  const podeHomologar = async () => {
    return await verificarAcesso('processos', 'homologar')
  }

  const podeEmitirParecerJuridico = async () => {
    return await verificarAcesso('processos', 'emitir_parecer')
  }

  /**
   * Obter itens de menu baseados no perfil
   */
  const obterItensMenu = () => {
    const itensBase = []

    // CPM - Acesso completo exceto CCL
    if (isCPM.value) {
      itensBase.push(
        { nome: 'Dashboard', rota: '/dashboard', icone: '📊' },
        { nome: 'Cadastro de Produtos', rota: '/produtos', icone: '📦' },
        { nome: 'Catálogo de Marcas', rota: '/marcas', icone: '🏷️' },
        { nome: 'Classificação', rota: '/classificacao', icone: '📋' },
        { nome: 'DCB', rota: '/dcb', icone: '📄' },
        { nome: 'RDM / Feedback', rota: '/feedback', icone: '📝' },
        { nome: 'Processos Administrativos', rota: '/processos', icone: '⚖️' }
      )
    }

    // CCL - Apenas Painel CCL
    if (isCCL.value) {
      itensBase.push(
        { nome: 'Painel CCL', rota: '/ccl', icone: '⚖️' }
      )
    }

    // Órgão Administrativo - Apenas Processos para assinatura
    if (isOrgaoAdministrativo.value) {
      itensBase.push(
        { nome: 'Processos Administrativos', rota: '/processos/administrativo', icone: '📋' }
      )
    }

    // Assessoria Jurídica - Apenas Processos para análise jurídica
    if (isAssessoriaJuridica.value) {
      itensBase.push(
        { nome: 'Processos Administrativos', rota: '/processos/juridico', icone: '⚖️' }
      )
    }

    return itensBase
  }

  /**
   * Obter mensagem de boas-vindas personalizada
   */
  const obterMensagemBoasVindas = () => {
    if (!perfilUsuario.value) return 'Bem-vindo!'
    
    const nome = perfilUsuario.value.nome?.split(' ')[0] || 'Usuário'
    const perfil = infoPerfil.value?.nome || 'Sistema'
    
    return `Olá, ${nome}! Você está acessando como ${perfil}.`
  }

  // =====================================================
  // LIFECYCLE
  // =====================================================

  onMounted(() => {
    carregarPerfil()
  })

  // =====================================================
  // RETURN
  // =====================================================

  return {
    // State
    perfilUsuario,
    modulosPermitidos,
    carregandoPerfil,
    erroPerfil,

    // Computed
    isCPM,
    isCCL,
    isOrgaoAdministrativo,
    isAssessoriaJuridica,
    infoPerfil,
    temAcessoCompleto,
    isPerfilRestrito,
    nomePerfilFormatado,

    // Methods
    carregarPerfil,
    verificarAcesso,
    podeAcessarRota,
    podeAcessarPainelCCL,
    podeCriarProcessos,
    podeAssinarDigitalmente,
    podeJulgarProcessos,
    podeHomologar,
    podeEmitirParecerJuridico,
    obterItensMenu,
    obterMensagemBoasVindas,

    // Constants
    PERFIS: PerfilUsuarioService.PERFIS,
    PERFIS_INFO: PerfilUsuarioService.PERFIS_INFO
  }
}

export default usePerfilUsuario