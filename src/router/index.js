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

import { supabase } from '../services/supabase'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home,
    meta: { requiresAuth: false }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard,
    meta: { requiresAuth: true }
  },
  {
    path: '/ccl',
    name: 'CCL',
    component: CCL,
    meta: { requiresAuth: true }
  },
  {
    path: '/cadastro',
    name: 'Cadastro',
    component: Cadastro,
    meta: { requiresAuth: true }
  },
  {
    path: '/analise/:id',
    name: 'Analise',
    component: Analise,
    meta: { requiresAuth: true }
  },
  {
    path: '/catalogo',
    name: 'Catalogo',
    component: Catalogo,
    meta: { requiresAuth: true }
  },
  {
    path: '/feedback',
    name: 'Feedback',
    component: Feedback,
    meta: { requiresAuth: true }
  },
  {
    path: '/dcb',
    name: 'DCB',
    component: DCB,
    meta: { requiresAuth: true }
  },
  {
    path: '/classificacao',
    name: 'Classificacao',
    component: Classificacao,
    meta: { requiresAuth: true }
  },
  {
    path: '/produtos/:id',
    name: 'DetalheProduto',
    component: () => import('../components/produtos/DetalheProduto.vue'),
    props: true,
    meta: { requiresAuth: true }
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
    path: '/pesquisa-tecnica',
    name: 'PesquisaTecnica',
    component: PesquisaTecnica,
    meta: { requiresAuth: true }
  }
]

const router = new VueRouter({
  mode: process.env.NODE_ENV === 'production' ? 'hash' : 'history',
  base: process.env.BASE_URL,
  routes
})

// Navegação guard para verificar autenticação
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

    if (requiresAuth && !user) {
      next('/')
    } else {
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