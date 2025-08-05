import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import Dashboard from '../views/Dashboard.vue'
import Cadastro from '../views/Cadastro.vue'
import Analise from '../views/Analise.vue'
import Catalogo from '../views/Catalogo.vue'
import Feedback from '../views/Feedback.vue'
import DCB from '../views/DCB.vue'
import CCL from '../views/CCL.vue'
import Classificacao from '../views/Classificacao.vue'
import LoginRDM from '../views/LoginRDM.vue'
import DashboardRDM from '../views/DashboardRDM.vue'
import PesquisaTecnica from '../views/PesquisaTecnica.vue'
import ProcessosAdministrativos from '../views/ProcessosAdministrativos.vue'

import { supabase } from '../services/supabase'
import PerfilUsuarioService from '../services/perfilUsuarioService'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home,
    meta: { requiresAuth: false }
  },
  // ===== ROTAS CPM (Acesso completo exceto CCL) =====
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'dashboard'
    }
  },
  {
    path: '/cadastro',
    name: 'Cadastro',
    component: Cadastro,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'cadastro_produtos'
    }
  },
  {
    path: '/analise/:id',
    name: 'Analise',
    component: Analise,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'cadastro_produtos'
    }
  },
  {
    path: '/catalogo',
    name: 'Catalogo',
    component: Catalogo,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'catalogo_marcas'
    }
  },
  {
    path: '/feedback',
    name: 'Feedback',
    component: Feedback,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'rdm'
    }
  },
  {
    path: '/dcb',
    name: 'DCB',
    component: DCB,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'dcb'
    }
  },
  {
    path: '/classificacao',
    name: 'Classificacao',
    component: Classificacao,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'classificacao'
    }
  },
  {
    path: '/produtos/:id',
    name: 'DetalheProduto',
    component: () => import('../components/produtos/DetalheProduto.vue'),
    props: true,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'cadastro_produtos'
    }
  },
  {
    path: '/pesquisa-tecnica',
    name: 'PesquisaTecnica',
    component: PesquisaTecnica,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm'],
      moduloRequired: 'cadastro_produtos'
    }
  },
  // ===== ROTAS CCL (Apenas Painel CCL) =====
  {
    path: '/ccl',
    name: 'CCL',
    component: CCL,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['ccl'],
      moduloRequired: 'painel_ccl'
    }
  },
  // ===== ROTAS PROCESSOS ADMINISTRATIVOS =====
  {
    path: '/processos-administrativos',
    name: 'ProcessosAdministrativos',
    component: ProcessosAdministrativos,
    meta: { 
      requiresAuth: true,
      requiredProfiles: ['cpm', 'orgao_administrativo', 'assessoria_juridica'],
      moduloRequired: 'processos_administrativos'
    }
  },
  // ===== ROTAS PÚBLICAS =====
  {
    path: '/registro-orgao',
    name: 'RegistroOrgao',
    component: () => import('../components/RegistroOrgao.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/validar-dcb/:numero/:ano',
    name: 'ValidarDCB',
    component: () => import('../components/ValidarDCB.vue'),
    props: true,
    meta: { requiresAuth: false }
  },
  {
    path: '/rdm',
    name: 'LoginRDM',
    component: LoginRDM,
    meta: { requiresAuth: false }
  },
  {
    path: '/dashboard-rdm',
    name: 'DashboardRDM',
    component: DashboardRDM,
    meta: { requiresAuth: false } // Autenticação personalizada dentro do componente
  },
  {
    path: '/catalogo-publico',
    name: 'CatalogoPublico',
    component: () => import('../components/catalogo/CatalogoPublico.vue'),
    meta: { requiresAuth: false }
  },
  // ===== ROTA DE ACESSO NEGADO =====
  {
    path: '/acesso-negado',
    name: 'AcessoNegado',
    component: () => import('../components/AcessoNegado.vue'),
    meta: { requiresAuth: true }
  },
  // ===== ROTA DE DEBUG (Desenvolvimento) =====
  {
    path: '/debug-usuarios',
    name: 'DebugUsuarios',
    component: () => import('../components/DebugUsuarios.vue'),
    meta: { requiresAuth: false }
  },
  // ===== ROTA 404 =====
  {
    path: '*',
    name: 'NotFound',
    component: () => import('../components/NotFound.vue'),
    meta: { requiresAuth: false }
  }
]

const router = new VueRouter({
  mode: process.env.NODE_ENV === 'production' ? 'hash' : 'history',
  base: process.env.BASE_URL,
  routes
})

// Navegação guard para verificar autenticação e perfis
router.beforeEach(async (to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  
  // Pular verificação de auth para rotas públicas
  if (!requiresAuth) {
    next()
    return
  }

  try {
    const { data } = await supabase.auth.getSession()
    const user = data?.session?.user

    // Verificar se está autenticado
    if (requiresAuth && !user) {
      next('/')
      return
    }

    // Verificar perfil de acesso para rotas protegidas
    const requiredProfiles = to.meta.requiredProfiles
    const moduloRequired = to.meta.moduloRequired

    if (requiredProfiles || moduloRequired) {
      try {
        // Obter perfil do usuário
        const perfilUsuario = await PerfilUsuarioService.obterPerfilUsuarioAtual()
        
        if (!perfilUsuario) {
          console.warn('Usuário sem perfil definido')
          next('/acesso-negado')
          return
        }

        // REGRAS ESPECIAIS DE REDIRECIONAMENTO POR PERFIL
        
        // CCL: só pode acessar painel CCL
        if (perfilUsuario.perfil_usuario === 'ccl' && to.path !== '/ccl') {
          console.log('Usuário CCL redirecionado para painel exclusivo')
          next('/ccl')
          return
        }
        
        // Órgão Admin e Assessoria: se tentar ir para dashboard, redirecionar para processos
        if ((perfilUsuario.perfil_usuario === 'orgao_administrativo' || 
             perfilUsuario.perfil_usuario === 'assessoria_juridica') && 
             to.path === '/dashboard') {
          console.log(`Usuário ${perfilUsuario.perfil_usuario} redirecionado para processos administrativos`)
          next('/processos-administrativos')
          return
        }

        // Verificar se o perfil está na lista de perfis permitidos
        if (requiredProfiles && !requiredProfiles.includes(perfilUsuario.perfil_usuario)) {
          console.warn(`Acesso negado: perfil ${perfilUsuario.perfil_usuario} não permitido para rota ${to.path}`)
          next('/acesso-negado')
          return
        }

        // Verificar acesso ao módulo específico
        if (moduloRequired) {
          const temAcesso = await PerfilUsuarioService.verificarAcessoModulo(moduloRequired)
          
          if (!temAcesso) {
            console.warn(`Acesso negado: usuário não tem acesso ao módulo ${moduloRequired}`)
            next('/acesso-negado')
            return
          }
        }

        // Tudo ok, permitir acesso
        next()

      } catch (error) {
        console.error('Erro ao verificar permissões:', error)
        next('/acesso-negado')
        return
      }
    } else {
      // Rota autenticada mas sem restrições de perfil
      next()
    }

  } catch (error) {
    console.error('Erro na verificação de autenticação:', error)
    // Se houver erro no Supabase, permitir acesso para rotas públicas
    if (!requiresAuth) {
      next()
    } else {
      next('/')
    }
  }
})

export default router 