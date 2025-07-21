<template>
  <div class="feedback-view">
    <header class="app-header">
      <div class="logo">
        <div class="logo-content">
          <h1>Comprar Bem</h1>
          <span class="subtitle">Compras Públicas Inteligentes</span>
        </div>
      </div>
      <nav class="main-nav">
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
      <FormularioRDM />
    </main>
    
    <!-- Modal de Configuração de Email -->
    <div v-if="modalEmailAberto" class="modal-overlay" @click="fecharModalEmail">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3><i class="fas fa-envelope"></i> Configurar Email da Organização</h3>
          <button @click="fecharModalEmail" class="btn-close">×</button>
        </div>
        
        <div class="modal-body">
          <div class="form-group">
            <label for="nomeOrganizacao">Nome da Organização</label>
            <input 
              id="nomeOrganizacao" 
              v-model="configEmail.nomeOrganizacao" 
              type="text" 
              placeholder="Ex: Prefeitura Municipal de..."
            >
          </div>
          
          <div class="form-group">
            <label for="emailRemetente">Email Remetente</label>
            <input 
              id="emailRemetente" 
              v-model="configEmail.emailRemetente" 
              type="email" 
              placeholder="Ex: licitacoes@prefeitura.gov.br"
            >
          </div>
          
          <div class="form-group">
            <label for="nomeRemetente">Nome do Remetente</label>
            <input 
              id="nomeRemetente" 
              v-model="configEmail.nomeRemetente" 
              type="text" 
              placeholder="Ex: CPM - Comissão de Padronização de Materiais"
            >
          </div>
          
          <div class="form-group">
            <label for="assinatura">Assinatura do Email</label>
            <textarea 
              id="assinatura" 
              v-model="configEmail.assinatura" 
              rows="4"
              placeholder="Ex: Atenciosamente,&#10;Comissão de Padronização de Materiais&#10;Prefeitura Municipal&#10;Telefone: (xx) xxxx-xxxx"
            ></textarea>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="fecharModalEmail" class="btn btn-secondary">Cancelar</button>
          <button @click="salvarConfiguracaoEmail" class="btn btn-primary">
            <i class="fas fa-save"></i> Salvar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import FormularioRDM from '@/components/rdm/FormularioRDM.vue'
import { supabase } from '@/services/supabase'

export default {
  name: 'Feedback',
  components: {
    FormularioRDM
  },
  data() {
    return {
      dropdownOpen: false,
      nomeUsuario: 'comprarBemTeste',
      emailUsuario: 'comprarbemteste@gmail.com',
      emailRemetente: 'cpm@suaorganizacao.com.br',
      nomeRemetente: 'CPM - Comissão de Padronização de Materiais'
    }
  },
  mounted() {
    this.carregarConfiguracoes()
  },
  methods: {
    async logout() {
      try {
        await supabase.auth.signOut()
        this.$router.push('/')
      } catch (error) {
        console.error('Erro ao fazer logout:', error)
      }
    },
    toggleDropdown() {
      this.dropdownOpen = !this.dropdownOpen
    },
    
    async abrirConfiguracaoEmail() {
      this.dropdownOpen = false
      
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
    }
  }
}
</script>

<style scoped>
.feedback-view {
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
  color: white;
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
  text-decoration: none;
}

.dropdown-item:hover {
  background-color: #f8f9fa;
}

.dropdown-divider {
  border: none;
  border-top: 1px solid #eee;
  margin: 8px 0;
}

.logout {
  color: #dc3545;
}

.logout:hover {
  background-color: #fff5f5;
}

.main-content {
  flex: 1;
  background-color: #f5f7fa;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background-color: white;
  padding: 20px;
  border-radius: 4px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  max-width: 400px;
  width: 100%;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.modal-header h3 {
  margin: 0;
  font-size: 1.2rem;
}

.btn-close {
  background: none;
  border: none;
  color: #999;
  font-size: 1.5rem;
  cursor: pointer;
}

.modal-body {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
}

.btn-secondary,
.btn-primary {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-secondary {
  background-color: #ccc;
  color: #333;
  margin-right: 10px;
}

.btn-primary {
  background-color: #3498db;
  color: white;
}
</style> 