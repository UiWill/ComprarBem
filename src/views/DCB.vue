<template>
  <div class="dcb-view">
    <header class="app-header">
      <div class="logo">
        <div class="logo-content">
          <h1>Comprar Bem</h1>
          <span class="subtitle">Compras Inteligentes</span>
        </div>
      </div>
      <nav class="main-nav">
        <router-link to="/dashboard">Painel CPM</router-link>
        <router-link to="/ccl">Painel CCL</router-link>
        <router-link to="/cadastro">Cadastrar Produto</router-link>
        <router-link to="/catalogo">Catálogo</router-link>
        <router-link to="/classificacao">Classificação</router-link>
        <router-link to="/dcb">DCB</router-link>
        <router-link to="/feedback">RDM</router-link>
      </nav>
      <div class="user-menu">
        <button @click="logout" class="btn-logout">Sair</button>
      </div>
    </header>
    
    <main class="main-content">
      <FormularioDCB />
    </main>
  </div>
</template>

<script>
import FormularioDCB from '@/components/dcb/FormularioDCB.vue'
import { supabase } from '@/services/supabase'

export default {
  name: 'DCB',
  components: {
    FormularioDCB
  },
  methods: {
    async logout() {
      try {
        await supabase.auth.signOut()
        this.$router.push('/')
      } catch (error) {
        console.error('Erro ao fazer logout:', error)
      }
    }
  }
}
</script>

<style scoped>
.dcb-view {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background-color: #2c3e50;
  color: white;
  padding: 0 20px;
  display: flex;
  align-items: center;
  height: 60px;
}

.logo {
  margin-left: 40px;
  display: flex;
  align-items: center;
}

.logo-content {
  display: flex;
  flex-direction: column;
  line-height: 1;
}

.logo-content h1 {
  margin: 0;
  font-size: 1.4rem;
}

.logo-content .subtitle {
  font-size: 0.75rem;
  opacity: 0.9;
}

.main-nav {
  margin-left: 40px;
  display: flex;
  flex: 1;
  overflow-x: auto;
  white-space: nowrap;
}

.main-nav a {
  color: white;
  text-decoration: none;
  padding: 0 15px;
  height: 60px;
  display: flex;
  align-items: center;
  transition: background-color 0.3s;
}

.main-nav a:hover,
.main-nav a.router-link-active {
  background-color: #34495e;
}

.user-menu {
  margin-left: auto;
}

.btn-logout {
  background: none;
  border: 1px solid white;
  color: white;
  padding: 5px 10px;
  border-radius: 4px;
  cursor: pointer;
}

.btn-logout:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.main-content {
  flex: 1;
  background-color: #f5f7fa;
}
</style> 