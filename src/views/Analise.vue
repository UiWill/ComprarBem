<template>
  <div class="analise-view">
    <header class="app-header">
      <div class="logo">
        <h1>Comprar Bem: Compras Inteligentes</h1>
      </div>
      <nav class="main-nav">
        <router-link to="/dashboard">Dashboard</router-link>
        <router-link to="/cadastro">Cadastrar Produto</router-link>
        <router-link to="/catalogo">Catálogo</router-link>
        <router-link to="/feedback">RDM</router-link>
      </nav>
      <div class="user-menu">
        <button @click="logout" class="btn-logout">Sair</button>
      </div>
    </header>
    
    <main class="main-content">
      <AnaliseProduto :id="produtoId" />
    </main>
  </div>
</template>

<script>
import AnaliseProduto from '@/components/analise/AnaliseProduto.vue'
import { supabase } from '@/services/supabase'

export default {
  name: 'Analise',
  components: {
    AnaliseProduto
  },
  computed: {
    produtoId() {
      return this.$route.params.id
    }
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
.analise-view {
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

.logo h1 {
  margin: 0;
  font-size: 1.5rem;
}

.main-nav {
  margin-left: 40px;
  display: flex;
  flex: 1;
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