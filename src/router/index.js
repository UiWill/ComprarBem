import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import Dashboard from '../views/Dashboard.vue'
import Cadastro from '../views/Cadastro.vue'
import Analise from '../views/Analise.vue'
import Catalogo from '../views/Catalogo.vue'
import Feedback from '../views/Feedback.vue'
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
    path: '/produtos/:id',
    name: 'DetalheProduto',
    component: () => import('../components/produtos/DetalheProduto.vue'),
    props: true,
    meta: { requiresAuth: true }
  }
]

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes
})

// Navegação guard para verificar autenticação
router.beforeEach(async (to, from, next) => {
  const { data } = await supabase.auth.getSession()
  const user = data?.session?.user
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)

  if (requiresAuth && !user) {
    next('/')
  } else {
    next()
  }
})

export default router 