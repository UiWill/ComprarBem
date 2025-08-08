<template>
  <div class="login-container">
    <div class="login-card">
      <h2>COMPRAR BEM</h2>
      <p>COMPRAS PÚBLICAS INTELIGENTES</p>
      
      <div class="tabs">
        <button 
          @click="activeTab = 'login'" 
          :class="{ active: activeTab === 'login' }"
        >Login</button>
        <button 
          @click="activeTab = 'register'" 
          :class="{ active: activeTab === 'register' }"
        >Registrar</button>
      </div>
      
      <!-- Login Form -->
      <div v-if="activeTab === 'login'">
        <div class="form-group">
          <label for="email">E-mail</label>
          <input 
            id="email" 
            v-model="email" 
            type="email" 
            placeholder="Seu e-mail"
            required
          >
        </div>
        
        <div class="form-group">
          <label for="password">Senha</label>
          <input 
            id="password" 
            v-model="password" 
            type="password" 
            placeholder="Sua senha"
            required
          >
        </div>
        
        <button 
          @click="login" 
          class="btn-primary" 
          :disabled="loading"
        >
          {{ loading ? 'Entrando...' : 'Entrar' }}
        </button>
      </div>
      
      <!-- Register Form -->
      <div v-if="activeTab === 'register'">
        <!-- Link para Registro de Órgão -->
        <div class="registro-orgao-link-simple">
          <p class="info-text-center">
            É um órgão público novo no sistema?
          </p>
          <router-link to="/registro-orgao" class="btn-registro-orgao">
            📝 Cadastrar Órgão
          </router-link>
          <small class="help-text-center">
            Cria automaticamente os 4 perfis de acesso necessários
          </small>
        </div>
      </div>
      
      <p class="error-message" v-if="errorMsg">{{ errorMsg }}</p>
      
      <!-- Seção de Acesso Público -->
      <div class="public-access-section">
        <div class="public-options">
          <!-- Primeira linha: RDM e Catálogo lado a lado -->
          <div class="options-row">
            <div class="public-option" @click="acessarRDMOnline()">
              <div class="option-icon">🏥</div>
              <div class="option-content">
                <h4>Sistema RDM On-line</h4>
                <p>📝 Dashboard RDM</p>
                <small>Usuários cadastrados para emitir RDMs</small>
              </div>
            </div>
            
            <div class="public-option" @click="acessarCatalogo()">
              <div class="option-icon">📦</div>
              <div class="option-content">
                <h4>Catálogo de Produtos</h4>
                <p>📋 Consulta de produtos</p>
                <small>Consultar marcas e modelos padronizados</small>
              </div>
            </div>
          </div>
          
          <!-- Segunda linha: Sistema de Reclamações centralizado -->
          <div class="options-row centered">
            <div class="public-option wide" @click="acessarReclameAqui()">
              <div class="option-icon">📢</div>
              <div class="option-content">
                <h4>Sistema de Reclamações</h4>
                <p>🗣️ Registrar reclamações sobre produtos</p>
                <small>Sistema para reclamações sobre marcas e modelos de produtos</small>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'Login',
  data() {
    return {
      activeTab: 'login',
      // Login
      email: '',
      password: '',
      // Common
      loading: false,
      errorMsg: ''
    }
  },
  methods: {
    async login() {
      try {
        this.loading = true
        this.errorMsg = ''
        
        const { error } = await supabase.auth.signInWithPassword({
          email: this.email,
          password: this.password
        })
        
        if (error) throw error
        
        // Obter perfil do usuário para redirecionamento correto
        try {
          // Aguardar um momento para o Supabase processar o login
          await new Promise(resolve => setTimeout(resolve, 500))
          
          // Obter dados do usuário
          const { data: { user } } = await supabase.auth.getUser()
          
          if (user) {
            // Buscar perfil na tabela usuarios
            const { data: usuario } = await supabase
              .from('usuarios')
              .select('perfil_usuario')
              .eq('id', user.id)
              .single()
            
            // Redirecionar baseado no perfil do usuário
            switch (usuario?.perfil_usuario) {
              case 'ccl':
                // CCL: apenas painel CCL
                this.$router.push('/ccl')
                break
              case 'cpm':
                // CPM: dashboard completo
                this.$router.push('/dashboard')
                break
              case 'orgao_administrativo':
              case 'assessoria_juridica':
                // Órgão Admin e Assessoria: processos administrativos
                this.$router.push('/processos-administrativos')
                break
              default:
                // Fallback para dashboard (se houver outros perfis)
                this.$router.push('/dashboard')
            }
          } else {
            // Fallback se não conseguir obter dados do usuário
            this.$router.push('/dashboard')
          }
        } catch (redirectError) {
          console.warn('Erro ao obter perfil para redirecionamento:', redirectError)
          // Em caso de erro, redirecionar para dashboard (o router guard vai ajustar)
          this.$router.push('/dashboard')
        }
      } catch (error) {
        this.errorMsg = error.message || 'Erro ao fazer login'
      } finally {
        this.loading = false
      }
    },
    
    acessarRDMOnline() {
      // Redirecionar para login RDM específico
      this.$router.push('/rdm')
    },
    
    acessarCatalogo() {
      // Redirecionar para catálogo público apenas para consulta (sem reclamações)
      this.$router.push('/catalogo-publico?modo=consulta')
    },
    
    acessarReclameAqui() {
      // Redirecionar para sistema de reclamações
      this.$router.push('/catalogo-publico?modo=reclamacao')
    }
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #f5f5f5;
}

.login-card {
  background: white;
  padding: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 650px;
  min-height: auto;
}

.tabs {
  display: flex;
  margin-bottom: 20px;
  border-bottom: 1px solid #ddd;
}

.tabs button {
  flex: 1;
  background: none;
  border: none;
  padding: 10px;
  cursor: pointer;
  font-weight: bold;
  color: #95a5a6;
}

.tabs button.active {
  color: #2c3e50;
  border-bottom: 2px solid #2c3e50;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.btn-primary {
  width: 100%;
  padding: 10px;
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary:disabled {
  background-color: #95a5a6;
}

.error-message {
  color: #e74c3c;
  margin-top: 15px;
  text-align: center;
}

.test-buttons {
  margin-top: 20px;
  text-align: center;
}

.btn-test {
  padding: 10px 20px;
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.validation-info {
  margin-top: 15px;
  padding: 10px;
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 4px;
  color: #721c24;
}

.validation-info ul {
  margin-top: 5px;
  padding-left: 20px;
}

.btn-public {
  display: block;
  width: 100%;
  padding: 12px;
  background: linear-gradient(135deg, #27ae60, #229954);
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  text-align: center;
}

.btn-public:hover {
  background: linear-gradient(135deg, #229954, #1e8449);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(39, 174, 96, 0.3);
  color: white;
  text-decoration: none;
}

.public-access {
  margin-top: 20px;
}

.btn-rdm {
  display: block;
  width: 100%;
  padding: 12px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  text-align: center;
}

.btn-rdm:hover {
  background: linear-gradient(135deg, #764ba2, #667eea);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  color: white;
  text-decoration: none;
}

.rdm-access {
  margin-top: 20px;
}

.registro-orgao-link {
  margin: 20px 0;
  padding: 20px;
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  border-radius: 8px;
  text-align: center;
  border: 2px solid #e2e8f0;
}

.info-text {
  margin: 0 0 15px 0;
  color: white;
  font-weight: 600;
  font-size: 1rem;
}

.btn-registro-orgao {
  display: inline-block;
  padding: 12px 24px;
  background: white;
  color: #f5576c;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.btn-registro-orgao:hover {
  background: #f8f9fa;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(245, 87, 108, 0.3);
  color: #e74c3c;
  text-decoration: none;
}

.help-text {
  display: block;
  margin-top: 10px;
  color: rgba(255, 255, 255, 0.9);
  font-size: 0.85rem;
  font-style: italic;
}

/* Estilos para balão simples de registro */
.registro-orgao-link-simple {
  margin: 40px 0;
  padding: 30px;
  background: #f8f9fa;
  border: 2px solid #e9ecef;
  border-radius: 12px;
  text-align: center;
}

.info-text-center {
  margin: 0 0 20px 0;
  color: #495057;
  font-weight: 600;
  font-size: 1.1rem;
}

.help-text-center {
  display: block;
  margin-top: 15px;
  color: #6c757d;
  font-size: 0.9rem;
  font-style: italic;
}

/* Estilos para seção de acesso público */
.public-access-section {
  margin-top: 25px;
  padding: 25px;
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  color: #495057;
}

.public-options {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.options-row {
  display: flex;
  gap: 20px;
  justify-content: space-between;
}

.options-row.centered {
  justify-content: center;
}

.public-option {
  display: flex;
  align-items: center;
  padding: 18px;
  background: white;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  flex: 1;
  max-width: 48%;
  min-height: 90px;
}

.public-option.wide {
  max-width: 75%;
  min-height: 90px;
}

.public-option:hover {
  background: #f8f9fa;
  border-color: #2c3e50;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.option-icon {
  font-size: 2.2rem;
  margin-right: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 50px;
  height: 50px;
  background: #e9ecef;
  border-radius: 50%;
  flex-shrink: 0;
}

.option-content {
  flex: 1;
  text-align: center;
}

.option-content h4 {
  margin: 0 0 8px 0;
  font-size: 1.0rem;
  font-weight: 600;
  color: #495057;
  line-height: 1.2;
}

.option-content p {
  margin: 0 0 6px 0;
  font-size: 0.85rem;
  font-weight: 500;
  color: #2c3e50;
}

.option-content small {
  font-size: 0.75rem;
  color: #6c757d;
  line-height: 1.3;
  display: block;
}


/* Responsividade para tablets */
@media (max-width: 900px) and (min-width: 769px) {
  .login-card {
    max-width: 600px;
  }
  
  .public-option.wide {
    max-width: 80%;
  }
}

/* Responsividade para mobile */
@media (max-width: 768px) {
  .login-card {
    max-width: 95%;
    padding: 25px;
  }
  
  .public-access-section {
    margin-top: 20px;
    padding: 20px;
  }
  
  .options-row {
    flex-direction: column;
    gap: 15px;
  }
  
  .public-option {
    padding: 15px;
    max-width: 100%;
    min-height: 80px;
  }
  
  .public-option.wide {
    max-width: 100%;
    min-height: 80px;
  }
  
  .option-icon {
    font-size: 2rem;
    width: 50px;
    height: 50px;
    margin-right: 15px;
  }
  
  .option-content h4 {
    font-size: 1.1rem;
  }
  
  .option-content p {
    font-size: 0.9rem;
  }
  
  .option-content small {
    font-size: 0.8rem;
  }
}
</style> 