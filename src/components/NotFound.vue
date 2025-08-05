<template>
  <div class="not-found-container">
    <div class="not-found-content">
      <div class="icon-section">
        <div class="error-code">404</div>
        <div class="error-icon">🔍</div>
      </div>
      
      <div class="message-section">
        <h1>Página Não Encontrada</h1>
        <p class="main-message">
          A página que você está procurando não existe ou foi movida.
        </p>
        
        <div class="suggestions">
          <h3>Páginas disponíveis para você:</h3>
          <ul>
            <li v-for="item in itensMenu" :key="item.rota">
              <router-link :to="item.rota">
                {{ item.icone }} {{ item.nome }}
              </router-link>
            </li>
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
    </div>
  </div>
</template>

<script>
import { usePerfilUsuario } from '../composables/usePerfilUsuario'

export default {
  name: 'NotFound',
  setup() {
    const { obterItensMenu } = usePerfilUsuario()

    const voltarPagina = () => {
      window.history.back()
    }

    return {
      itensMenu: obterItensMenu(),
      voltarPagina
    }
  }
}
</script>

<style scoped>
.not-found-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
  color: white;
}

.not-found-content {
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

.error-code {
  font-size: 6rem;
  font-weight: 900;
  color: #e53e3e;
  margin-bottom: 1rem;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.1);
}

.error-icon {
  font-size: 3rem;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
  40% { transform: translateY(-10px); }
  60% { transform: translateY(-5px); }
}

.message-section h1 {
  color: #2d3748;
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

.suggestions {
  text-align: left;
  background: #f7fafc;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.suggestions h3 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 1.1rem;
  text-align: center;
}

.suggestions ul {
  list-style: none;
  padding: 0;
  display: grid;
  gap: 0.75rem;
}

.suggestions li {
  padding: 0.75rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  transition: all 0.3s ease;
}

.suggestions li:hover {
  border-color: #3182ce;
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.suggestions a {
  color: #3182ce;
  text-decoration: none;
  font-weight: 600;
  transition: color 0.3s ease;
  display: block;
}

.suggestions a:hover {
  color: #2c5282;
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

@media (max-width: 768px) {
  .not-found-container {
    padding: 1rem;
  }
  
  .not-found-content {
    padding: 2rem;
  }
  
  .message-section h1 {
    font-size: 2rem;
  }
  
  .error-code {
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