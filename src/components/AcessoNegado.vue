<template>
  <div class="acesso-negado-container">
    <div class="acesso-negado-content">
      <div class="icon-section">
        <div class="access-denied-icon">🚫</div>
      </div>
      
      <div class="message-section">
        <h1>Acesso Negado</h1>
        <p class="main-message">
          Você não tem permissão para acessar esta página.
        </p>
        
        <div v-if="perfilUsuario" class="perfil-info">
          <div class="current-profile">
            <strong>Seu perfil atual:</strong> {{ nomePerfilFormatado }}
          </div>
          <div class="profile-description">
            {{ infoPerfil?.descricao }}
          </div>
        </div>
        
        <div class="suggestions">
          <h3>O que você pode fazer:</h3>
          <ul>
            <li v-if="isCPM">
              <router-link to="/dashboard">Ir para o Dashboard</router-link>
            </li>
            <li v-if="isCCL">
              <router-link to="/ccl">Ir para o Painel CCL</router-link>
            </li>
            <li v-if="isOrgaoAdministrativo">
              <router-link to="/processos-administrativos">Ver Processos Administrativos</router-link>
            </li>
            <li v-if="isAssessoriaJuridica">
              <router-link to="/processos-administrativos">Ver Processos para Análise Jurídica</router-link>
            </li>
            <li>Entrar em contato com o administrador do sistema</li>
            <li>Verificar se você está logado com o usuário correto</li>
          </ul>
        </div>
        
        <div class="actions">
          <button @click="voltarPagina" class="btn-secondary">
            ← Voltar
          </button>
          <router-link to="/" class="btn-primary">
            🏠 Página Inicial
          </router-link>
        </div>
      </div>
    </div>
    
    <div class="footer-info">
      <p>
        <strong>Sistema Comprar Bem</strong> • 
        Gerenciamento de Compras Públicas
      </p>
      <p class="tech-info">
        Para suporte técnico, entre em contato com a equipe de TI.
      </p>
    </div>
  </div>
</template>

<script>
import { usePerfilUsuario } from '../composables/usePerfilUsuario'

export default {
  name: 'AcessoNegado',
  setup() {
    const {
      perfilUsuario,
      isCPM,
      isCCL,
      isOrgaoAdministrativo,
      isAssessoriaJuridica,
      infoPerfil,
      nomePerfilFormatado
    } = usePerfilUsuario()

    const voltarPagina = () => {
      window.history.back()
    }

    return {
      perfilUsuario,
      isCPM,
      isCCL,
      isOrgaoAdministrativo,
      isAssessoriaJuridica,
      infoPerfil,
      nomePerfilFormatado,
      voltarPagina
    }
  }
}
</script>

<style scoped>
.acesso-negado-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
  color: white;
}

.acesso-negado-content {
  background: white;
  border-radius: 20px;
  padding: 3rem;
  max-width: 600px;
  width: 100%;
  text-align: center;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  color: #2d3748;
}

.icon-section {
  margin-bottom: 2rem;
}

.access-denied-icon {
  font-size: 5rem;
  margin-bottom: 1rem;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { transform: scale(1); }
}

.message-section h1 {
  color: #e53e3e;
  margin-bottom: 1rem;
  font-size: 2.5rem;
  font-weight: 700;
}

.main-message {
  font-size: 1.2rem;
  color: #4a5568;
  margin-bottom: 2rem;
  line-height: 1.6;
}

.perfil-info {
  background: #f7fafc;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  border-left: 4px solid #3182ce;
}

.current-profile {
  font-size: 1.1rem;
  color: #2d3748;
  margin-bottom: 0.5rem;
}

.profile-description {
  color: #718096;
  font-size: 0.95rem;
}

.suggestions {
  text-align: left;
  background: #edf2f7;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.suggestions h3 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 1.1rem;
}

.suggestions ul {
  list-style: none;
  padding: 0;
}

.suggestions li {
  margin-bottom: 0.75rem;
  padding-left: 1.5rem;
  position: relative;
}

.suggestions li::before {
  content: '💡';
  position: absolute;
  left: 0;
}

.suggestions a {
  color: #3182ce;
  text-decoration: none;
  font-weight: 600;
  transition: color 0.3s ease;
}

.suggestions a:hover {
  color: #2c5282;
  text-decoration: underline;
}

.actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 2rem;
  border-radius: 8px;
  font-weight: 600;
  text-decoration: none;
  cursor: pointer;
  transition: all 0.3s ease;
  border: none;
  font-size: 1rem;
}

.btn-primary {
  background: #3182ce;
  color: white;
}

.btn-primary:hover {
  background: #2c5282;
  transform: translateY(-2px);
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover {
  background: #cbd5e0;
}

.footer-info {
  margin-top: 2rem;
  text-align: center;
  opacity: 0.8;
}

.footer-info p {
  margin: 0.5rem 0;
}

.tech-info {
  font-size: 0.9rem;
  opacity: 0.7;
}

@media (max-width: 768px) {
  .acesso-negado-container {
    padding: 1rem;
  }
  
  .acesso-negado-content {
    padding: 2rem;
  }
  
  .message-section h1 {
    font-size: 2rem;
  }
  
  .access-denied-icon {
    font-size: 4rem;
  }
  
  .actions {
    flex-direction: column;
  }
  
  .btn-primary,
  .btn-secondary {
    width: 100%;
    text-align: center;
  }
}
</style>