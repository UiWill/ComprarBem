<template>
  <div class="ccl-view">
    <header class="app-header">
      <div class="logo">
        <div class="logo-content">
          <h1>Comprar Bem</h1>
          <span class="subtitle">Compras Públicas Inteligentes</span>
        </div>
      </div>
      <nav class="main-nav" v-if="!isUsuarioCCL">
        <router-link to="/dashboard">Painel CPM</router-link>
        <router-link to="/ccl">Painel CCL</router-link>
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
      
      <!-- Indicador para usuário CCL -->
      <div v-if="isUsuarioCCL" class="ccl-indicator">
        <span class="ccl-badge">⚖️ CCL - Acesso Exclusivo</span>
      </div>
      <div class="user-menu">
        <div class="profile-dropdown" ref="profileDropdown">
          <button 
            @click="toggleDropdown" 
            class="profile-button"
            :class="{ active: showDropdown }"
          >
            <div class="profile-avatar">
              <span class="profile-icon">👤</span>
            </div>
            <div class="profile-info">
              <span class="profile-name">{{ usuarioNome }}</span>
              <span class="profile-email">{{ usuarioEmail }}</span>
            </div>
            <span class="dropdown-arrow" :class="{ rotated: showDropdown }">▼</span>
          </button>
          
          <div v-if="showDropdown" class="dropdown-menu">
            <div class="dropdown-header">
              <div class="user-avatar-large">👤</div>
              <div class="user-details">
                <strong>{{ usuarioNome }}</strong>
                <small>{{ usuarioEmail }}</small>
              </div>
            </div>
            
            <hr class="dropdown-divider">
            
            <button @click="abrirConfiguracoes" class="dropdown-item">
              <span class="item-icon">⚙️</span>
              <span>Configurações</span>
            </button>
            
            <button @click="abrirConfiguracoesEmail" class="dropdown-item">
              <span class="item-icon">📧</span>
              <span>Configurar Email</span>
            </button>
            
            <hr class="dropdown-divider">
            
            <button @click="logout" class="dropdown-item logout-item">
              <span class="item-icon">🚪</span>
              <span>Sair</span>
            </button>
          </div>
        </div>
        
        <!-- OVERLAY PARA FECHAR DROPDOWN -->
        <div v-if="showDropdown" class="dropdown-overlay" @click="closeDropdown"></div>
      </div>
    </header>
    
    <main class="main-content">
      <DashboardCCL />
    </main>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import DashboardCCL from '@/components/dashboard/DashboardCCL.vue'

export default {
  name: 'CCL',
  components: {
    DashboardCCL
  },
  data() {
    return {
      dropdownOpen: false,
      modalEmailAberto: false,
      isUsuarioCCL: false,
      nomeUsuario: 'comprarBemTeste',
      emailUsuario: 'comprarbemteste@gmail.com',
      configEmail: {
        nomeOrganizacao: '',
        emailRemetente: '',
        nomeRemetente: '',
        assinatura: ''
      },
      showDropdown: false,
      usuarioNome: 'comprarBemTeste',
      usuarioEmail: 'comprarbemteste@gmail.com',
      emailRemetente: 'cpm@suaorganizacao.com.br',
      nomeRemetente: 'CPM - Comissão de Padronização de Materiais'
    }
  },
  async created() {
    await this.carregarDadosUsuario()
    this.carregarConfiguracoes()
  },
  mounted() {
    // Removido código antigo
  },
  beforeUnmount() {
    // Removido código antigo
  },
  methods: {
    async carregarDadosUsuario() {
      try {
        const { data: { user } } = await supabase.auth.getUser()
        if (user) {
          this.usuarioEmail = user.email
          this.usuarioNome = user.user_metadata?.nome || user.email.split('@')[0]
          
          // Verificar se é usuário CCL
          const { data: usuario, error: errorUsuario } = await supabase
            .from('usuarios')
            .select('perfil_usuario')
            .eq('id', user.id)
            .single()
          
          console.log('🔍 Dados do usuário CCL:', { usuario, errorUsuario, userId: user.id })
          
          this.isUsuarioCCL = usuario?.perfil_usuario === 'ccl'
          
          
          console.log('✅ IsUsuarioCCL:', this.isUsuarioCCL)
          
          if (this.isUsuarioCCL) {
            console.log('🔒 Usuário CCL logado - Navegação restrita')
          }
        }
      } catch (error) {
        console.error('Erro ao carregar dados do usuário:', error)
      }
    },
    
    carregarConfiguracoes() {
      try {
        const configsSalvas = localStorage.getItem('configsSistema')
        if (configsSalvas) {
          const configs = JSON.parse(configsSalvas)
          this.emailRemetente = configs.emailRemetente || this.emailRemetente
          this.nomeRemetente = configs.nomeRemetente || this.nomeRemetente
        }
      } catch (error) {
        console.error('Erro ao carregar configurações:', error)
      }
    },
    
    toggleDropdown() {
      this.showDropdown = !this.showDropdown
                 },
       
       abrirConfiguracoesEmail() {
         this.closeDropdown()
         this.mostrarConfigEmail()
       },
      
    async logout() {
      try {
        await supabase.auth.signOut()
        this.$router.push('/')
      } catch (error) {
        console.error('Erro ao fazer logout:', error)
      }
      this.closeDropdown()
    },
    
    abrirConfiguracoes() {
      this.closeDropdown()
      this.mostrarConfigEmail()
    },
    
    async mostrarConfigEmail() {
      const { value: formValues } = await this.$swal({
        title: '📧 Configurar Email do Sistema',
        html: `
          <div style="text-align: left; padding: 10px;">
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Email Remetente (CPM):</label>
              <input id="emailRemetente" class="swal2-input" value="${this.emailRemetente}" type="email" placeholder="cpm@suaorganizacao.com.br">
              <small style="color: #666; font-size: 11px;">Email que aparece como remetente das diligências</small>
            </div>
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Nome do Remetente:</label>
              <input id="nomeRemetente" class="swal2-input" value="${this.nomeRemetente}" type="text" placeholder="CPM - Comissão de Padronização de Materiais">
            </div>
          </div>
        `,
        focusConfirm: false,
        showCancelButton: true,
        confirmButtonText: '💾 Salvar',
        cancelButtonText: '❌ Cancelar',
        preConfirm: () => {
          const emailRemetente = document.getElementById('emailRemetente').value
          const nomeRemetente = document.getElementById('nomeRemetente').value
          
          if (!emailRemetente || !nomeRemetente) {
            this.$swal.showValidationMessage('Por favor, preencha todos os campos')
            return false
          }
          
          return { emailRemetente, nomeRemetente }
        }
      })
      
      if (formValues) {
        this.emailRemetente = formValues.emailRemetente
        this.nomeRemetente = formValues.nomeRemetente
        
        // Salvar no localStorage
        const configs = {
          emailRemetente: formValues.emailRemetente,
          nomeRemetente: formValues.nomeRemetente
        }
        localStorage.setItem('configsSistema', JSON.stringify(configs))
        
        this.$swal({
          title: '✅ Sucesso!',
          text: 'Configurações de email salvas com sucesso!',
          icon: 'success'
        })
      }
    },
    
    closeDropdown() {
      this.showDropdown = false
    }
  }
}
</script>

<style scoped>
.ccl-view {
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

.profile-button {
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

.profile-button:hover,
.profile-button.active {
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
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
  min-width: 280px;
  z-index: 1000;
  margin-top: 5px;
  color: #333;
}

.dropdown-header {
  padding: 15px;
  display: flex;
  align-items: center;
  gap: 12px;
  background: #f8f9fa;
  border-radius: 8px 8px 0 0;
}

.user-avatar-large {
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  color: white;
}

.user-details {
  flex: 1;
}

.user-details strong {
  display: block;
  color: #2c3e50;
  font-size: 14px;
}

.user-details small {
  color: #666;
  font-size: 12px;
}

.dropdown-divider {
  border: none;
  border-top: 1px solid #eee;
  margin: 8px 0;
}

.dropdown-item {
  width: 100%;
  padding: 12px 15px;
  border: none;
  background: none;
  text-align: left;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 10px;
  color: #333;
  font-size: 14px;
  transition: background-color 0.2s ease;
}

.dropdown-item:hover {
  background-color: #f8f9fa;
}

.logout-item {
  color: #dc3545;
}

.logout-item:hover {
  background-color: #fff5f5;
}

.item-icon {
  font-size: 16px;
  width: 20px;
  text-align: center;
}

.dropdown-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 999;
}

.main-content {
  flex: 1;
  background-color: #f5f7fa;
}

.breadcrumbs {
  margin-bottom: 1rem;
  font-size: 0.9rem;
  color: #666;
}

.dashboard-header {
  margin-bottom: 2rem;
}

.dashboard-header h2 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
}

.dashboard-header p {
  margin: 0;
  color: #666;
}

/* Indicador CCL */
.ccl-indicator {
  display: flex;
  justify-content: center;
  padding: 0.5rem 2rem;
  background: rgba(231, 76, 60, 0.1);
  border-bottom: 1px solid #e74c3c;
}

.ccl-badge {
  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
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