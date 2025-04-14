<template>
  <div class="login-container">
    <div class="login-card">
      <h2>Comprar Bem: Compras Inteligentes</h2>
      <p>Saúde e Administração</p>
      
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
        <div class="form-group">
          <label for="registerEmail">E-mail</label>
          <input 
            id="registerEmail" 
            v-model="registerEmail" 
            type="email" 
            placeholder="Seu e-mail"
            required
          >
        </div>
        
        <div class="form-group">
          <label for="registerPassword">Senha</label>
          <input 
            id="registerPassword" 
            v-model="registerPassword" 
            type="password" 
            placeholder="Sua senha"
            required
          >
        </div>
        
        <div class="form-group">
          <label for="confirmPassword">Confirmar Senha</label>
          <input 
            id="confirmPassword" 
            v-model="confirmPassword" 
            type="password" 
            placeholder="Confirme sua senha"
            required
          >
        </div>
        
        <div class="form-group">
          <label for="nomeInstitucional">Nome da Instituição</label>
          <input 
            id="nomeInstitucional" 
            v-model="nomeInstitucional" 
            type="text" 
            placeholder="Nome da sua instituição"
            required
          >
        </div>
        
        <button 
          @click="register" 
          class="btn-primary" 
          type="button"
        >
          {{ loading ? 'Registrando...' : 'Registrar' }}
        </button>
        
        <button 
          @click="testeSimples" 
          class="btn-test" 
          style="margin-top: 10px;"
        >
          Teste Simples
        </button>
        
        <div v-if="!validRegistration" class="validation-info">
          <p>O formulário não está válido porque:</p>
          <ul>
            <li v-if="!registerEmail">Falta o e-mail</li>
            <li v-if="!registerPassword">Falta a senha</li>
            <li v-if="registerPassword && registerPassword.length < 6">A senha precisa ter pelo menos 6 caracteres</li>
            <li v-if="registerPassword !== confirmPassword">As senhas não conferem</li>
            <li v-if="!nomeInstitucional">Falta o nome da instituição</li>
          </ul>
        </div>
      </div>
      
      <p class="error-message" v-if="errorMsg">{{ errorMsg }}</p>
      
      <!-- Botão para teste -->
      <div class="test-buttons" v-if="activeTab === 'register'">
        <button @click="testarSupabase" class="btn-test">Testar Conexão Supabase</button>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { v4 as uuidv4 } from 'uuid'

export default {
  name: 'Login',
  data() {
    return {
      activeTab: 'login',
      // Login
      email: '',
      password: '',
      // Register
      registerEmail: '',
      registerPassword: '',
      confirmPassword: '',
      nomeInstitucional: '',
      // Common
      loading: false,
      errorMsg: ''
    }
  },
  computed: {
    validRegistration() {
      return this.registerEmail && 
             this.registerPassword && 
             this.registerPassword === this.confirmPassword &&
             this.nomeInstitucional &&
             this.registerPassword.length >= 6
    }
  },
  mounted() {
    console.log('Componente Login montado', {
      activeTab: this.activeTab
    })
  },
  watch: {
    activeTab(newVal) {
      console.log('Aba ativa alterada para:', newVal)
    },
    registerEmail(newVal) {
      console.log('E-mail de registro alterado:', newVal)
    },
    registerPassword(newVal) {
      console.log('Senha de registro alterada:', newVal ? '****' : '')
    }
  },
  methods: {
    async testarSupabase() {
      console.log('Testando conexão com Supabase...')
      try {
        // Verificar se a tabela tenants existe
        const { data, error } = await supabase
          .from('tenants')
          .select('*')
          .limit(1)
        
        console.log('Resultado do teste tabela tenants:', { data, error })
        
        if (error) {
          alert(`Erro ao acessar tabela: ${error.message}`)
        } else {
          alert(`Conexão OK! ${data ? data.length : 0} registros encontrados.`)
        }
        
        // Testar criação de um UUID
        const testUuid = uuidv4()
        console.log('Teste UUID gerado:', testUuid)
        
      } catch (err) {
        console.error('Erro no teste:', err)
        alert(`Erro na conexão: ${err.message}`)
      }
    },
    async login() {
      try {
        this.loading = true
        this.errorMsg = ''
        
        const { error } = await supabase.auth.signInWithPassword({
          email: this.email,
          password: this.password
        })
        
        if (error) throw error
        
        // Redirecionar para Dashboard
        this.$router.push('/dashboard')
      } catch (error) {
        this.errorMsg = error.message || 'Erro ao fazer login'
      } finally {
        this.loading = false
      }
    },
    async register() {
      console.log('Método register chamado', { 
        email: this.registerEmail,
        password: '****', 
        nomeInstitucional: this.nomeInstitucional 
      })
      
      if (!this.validRegistration) {
        console.log('Formulário inválido')
        this.errorMsg = 'Verifique os campos do formulário'
        return
      }
      
      try {
        this.loading = true
        this.errorMsg = ''
        
        // PASSO 1: Criar o usuário básico no sistema de autenticação
        console.log('Iniciando registro de usuário no Supabase...')
        const { data: authData, error: authError } = await supabase.auth.signUp({
          email: this.registerEmail,
          password: this.registerPassword
        })
        
        console.log('Resposta do registro de usuário:', { authData, authError })
        
        if (authError) {
          if (!authError.message.includes('already registered')) {
            throw authError
          }
        }
        
        // Pegar o ID da autenticação (será usado depois para o tenant)
        const authUserId = authData?.user?.id
        console.log('ID da autenticação:', authUserId)
        
        // PASSO 2: Gerar UUIDs
        const tenantId = uuidv4()
        const usuarioId = uuidv4()
        
        // PASSOS 3 e 4: Primeiro criar o tenant, depois criar ou atualizar o usuário
        
        // Primeiro, remover qualquer usuário existente com este email
        try {
          const { error: deleteError } = await supabase
            .from('usuarios')
            .delete()
            .eq('email', this.registerEmail)
          
          if (deleteError) {
            console.warn('Aviso ao tentar remover usuário existente:', deleteError)
          }
        } catch (e) {
          console.warn('Erro ao tentar remover usuário:', e)
        }
        
        // Criar tenant
        console.log('Criando tenant...')
        const { data: tenantData, error: tenantError } = await supabase
          .from('tenants')
          .insert({
            id: tenantId,
            nome: this.nomeInstitucional,
            descricao: `Tenant para ${this.registerEmail}`,
            ativo: true
          })
          .select()
        
        if (tenantError) {
          throw new Error(`Erro ao criar tenant: ${tenantError.message}`)
        }
        
        // Agora criar o usuário
        console.log('Criando usuário...')
        const { data: userData, error: userError } = await supabase
          .from('usuarios')
          .insert({
            id: usuarioId,
            email: this.registerEmail,
            nome: this.nomeInstitucional,
            tenant_id: tenantId,
            tipo: 'admin',
            ativo: true
          })
          .select()
        
        if (userError) {
          if (userError.message.includes('duplicate key')) {
            this.errorMsg = 'Este email já está registrado. Por favor, contate o suporte.'
            throw new Error(`Email já existe na base de dados: ${userError.message}`)
          } else {
            throw new Error(`Erro ao criar usuário: ${userError.message}`)
          }
        }
        
        // Atualizar o tenant com o user_id (usando o ID da autenticação do Supabase)
        console.log('Atualizando tenant com user_id...')
        const { error: updateTenantError } = await supabase
          .from('tenants')
          .update({ user_id: authUserId })
          .eq('id', tenantId)
        
        if (updateTenantError) {
          console.warn('Aviso: Não foi possível atualizar o tenant com user_id:', updateTenantError)
          // Continuamos mesmo com esse erro
        }
        
        console.log('Registro concluído com sucesso!')
        alert('Registro realizado com sucesso! Verifique seu e-mail para confirmar a conta.')
        this.activeTab = 'login'
        this.email = this.registerEmail
      } catch (error) {
        console.error('Erro detalhado no registro:', error)
        this.errorMsg = this.errorMsg || error.message || 'Erro ao fazer registro'
      } finally {
        this.loading = false
      }
    },
    testeSimples() {
      console.log('Botão de teste simples clicado')
      alert('Teste de evento de clique funcionando!')
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
  max-width: 400px;
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
</style> 