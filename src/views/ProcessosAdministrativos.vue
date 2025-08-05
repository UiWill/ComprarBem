<template>
  <div class="processos-view">
    <header class="app-header">
      <div class="logo">
        <div class="logo-content">
          <h1>Comprar Bem</h1>
          <span class="subtitle">Compras Públicas Inteligentes</span>
        </div>
      </div>
      <nav class="main-nav" v-if="!isUsuarioProcessosOnly">
        <router-link to="/dashboard">Painel CPM</router-link>
        <router-link to="/cadastro">Cadastrar Produto</router-link>
        <router-link to="/catalogo" class="nav-item">
          <span>Catálogo</span>
          <span class="nav-subtitle">de Marcas</span>
        </router-link>
        <router-link to="/classificacao" class="nav-item">
          <span>Classificação</span>
          <span class="nav-subtitle">de Bens</span>
        </router-link>
        <router-link to="/dcb">DCB</router-link>
        <router-link to="/feedback">RDM</router-link>
        <router-link to="/processos-administrativos" class="nav-item">
          <span>Processos</span>
          <span class="nav-subtitle">Administrativos</span>
        </router-link>
      </nav>
      
      <!-- Indicador para usuários de Processos -->
      <div v-if="isUsuarioProcessosOnly" class="processos-indicator">
        <span class="processos-badge" v-if="perfilUsuario === 'orgao_administrativo'">
          📋 Órgão Administrativo - Assinaturas e Homologações
        </span>
        <span class="processos-badge" v-if="perfilUsuario === 'assessoria_juridica'">
          ⚖️ Assessoria Jurídica - Análise Legal
        </span>
      </div>
      <div class="user-menu">
        <div class="profile-dropdown">
          <button @click="toggleDropdown" class="profile-btn">
            <div class="profile-avatar">
              👤
            </div>
            <div class="profile-info">
              <span class="profile-name">{{ nomeUsuario }}</span>
              <span class="profile-email">{{ emailUsuario }}</span>
            </div>
            <span class="dropdown-arrow" :class="{ rotated: dropdownOpen }">▼</span>
          </button>
          
          <div v-if="dropdownOpen" class="dropdown-menu">
            <a href="#" @click.prevent="abrirConfiguracaoEmail" class="dropdown-item">
              ⚙️ Configuração
            </a>
            <a href="#" @click.prevent="abrirConfiguracaoEmail" class="dropdown-item">
              📧 Configurar Email
            </a>
            <hr class="dropdown-divider">
            <a href="#" @click.prevent="logout" class="dropdown-item logout">
              🚪 Sair
            </a>
          </div>
        </div>
      </div>
    </header>

    <main class="main-content">
      <ProcessosAdministrativosComponent />
    </main>
  </div>
</template>

<script>
import { supabase } from '../services/supabase'
import ProcessosAdministrativosComponent from '../components/processos/ProcessosAdministrativosComponent.vue'

export default {
  name: 'ProcessosAdministrativos',
  components: {
    ProcessosAdministrativosComponent
  },
  data() {
    return {
      nomeUsuario: '',
      emailUsuario: '',
      dropdownOpen: false,
      isUsuarioProcessosOnly: false,
      perfilUsuario: ''
    }
  },
  
  async mounted() {
    await this.verificarAutenticacao()
    document.addEventListener('click', this.fecharDropdownFora)
  },
  
  beforeUnmount() {
    document.removeEventListener('click', this.fecharDropdownFora)
  },
  
  methods: {
    async verificarAutenticacao() {
      try {
        const { data } = await supabase.auth.getSession()
        const user = data?.session?.user
        
        if (!user) {
          this.$router.push('/')
          return
        }
        
        this.nomeUsuario = user.user_metadata?.nome || user.email?.split('@')[0] || 'Usuário'
        this.emailUsuario = user.email || ''
        
        // Verificar perfil do usuário
        const { data: usuario } = await supabase
          .from('usuarios')
          .select('perfil_usuario')
          .eq('id', user.id)
          .single()
        
        this.perfilUsuario = usuario?.perfil_usuario || ''
        
        // Verificar se é usuário que só acessa processos
        this.isUsuarioProcessosOnly = ['orgao_administrativo', 'assessoria_juridica'].includes(this.perfilUsuario)
        
        if (this.isUsuarioProcessosOnly) {
          console.log(`🔒 Usuário ${this.perfilUsuario} logado - Acesso restrito a Processos Administrativos`)
        }
        
      } catch (error) {
        console.error('Erro na verificação de autenticação:', error)
        this.$router.push('/')
      }
    },
    
    toggleDropdown() {
      this.dropdownOpen = !this.dropdownOpen
    },
    
    fecharDropdownFora(event) {
      const dropdown = this.$el?.querySelector('.profile-dropdown')
      if (dropdown && !dropdown.contains(event.target)) {
        this.dropdownOpen = false
      }
    },
    
    abrirConfiguracaoEmail() {
      alert('Configuração de email em desenvolvimento')
      this.dropdownOpen = false
    },
    
    async logout() {
      try {
        await supabase.auth.signOut()
        this.$router.push('/')
      } catch (error) {
        console.error('Erro ao fazer logout:', error)
      }
      this.dropdownOpen = false
    }
  }
}
</script>

<style scoped>
.processos-view {
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
}

.main-nav a {
  color: white;
  text-decoration: none;
  height: 60px;
  display: flex;
  align-items: center;
  transition: background-color 0.3s;
}

.main-nav a:not(.nav-item) {
  padding: 0 15px;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  line-height: 1.2;
  padding: 0 15px;
}

.nav-subtitle {
  font-size: 0.65rem;
  opacity: 0.9;
}

.main-nav a:hover,
.main-nav a.router-link-active {
  background-color: #34495e;
}

.user-menu {
  margin-left: auto;
  position: relative;
}

.profile-dropdown {
  position: relative;
}

.profile-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 10px;
  transition: all 0.3s ease;
  min-width: 200px;
}

.profile-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
}

.profile-avatar {
  width: 32px;
  height: 32px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
}

.profile-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  line-height: 1.2;
}

.profile-name {
  font-weight: 600;
  font-size: 14px;
}

.profile-email {
  font-size: 11px;
  opacity: 0.8;
}

.dropdown-arrow {
  font-size: 10px;
  transition: transform 0.3s ease;
}

.dropdown-arrow.rotated {
  transform: rotate(180deg);
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  padding: 8px 0;
  min-width: 200px;
  z-index: 1000;
}

.dropdown-item {
  display: block;
  padding: 8px 16px;
  text-decoration: none;
  color: #333;
  font-size: 14px;
  transition: background-color 0.2s ease;
  cursor: pointer;
  border: none;
  background: none;
  width: 100%;
  text-align: left;
}

.dropdown-item:hover {
  background-color: #f8f9fa;
}

.dropdown-item.logout {
  color: #dc3545;
}

.dropdown-item.logout:hover {
  background-color: #fff5f5;
}

.dropdown-divider {
  margin: 8px 0;
  border: none;
  border-top: 1px solid #eee;
}

.main-content {
  flex: 1;
  background-color: #f5f7fa;
}

/* Indicadores de Processos */
.processos-indicator {
  display: flex;
  justify-content: center;
  padding: 0.5rem 2rem;
  background: rgba(52, 152, 219, 0.1);
  border-bottom: 1px solid #3498db;
}

.processos-badge {
  background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 600;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
</style>