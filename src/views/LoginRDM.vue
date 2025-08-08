<template>
  <div class="login-rdm-container">
    <!-- Header -->
    <header class="login-header">
      <div class="container">
        <div class="logo-section">
          <h1>🏥 Sistema Comprar Bem</h1>
          <span class="subtitle">Dashboard RDM On-line</span>
        </div>
      </div>
    </header>

    <!-- Main Login Section -->
    <main class="login-main">
      <div class="container">
        <div class="login-card">
          <div class="card-header">
            <h2>🔐 Acesso RDM</h2>
            <p>Faça login para emitir RDMs</p>
          </div>

          <!-- Formulário de Login -->
          <form @submit.prevent="fazerLogin" class="login-form">
            <div class="form-group">
              <label for="email">📧 E-mail:</label>
              <input
                type="email"
                id="email"
                v-model="loginData.email"
                placeholder="Digite seu email"
                required
                :disabled="carregando"
              />
            </div>

            <div class="form-group">
              <label for="senha">🔒 Senha:</label>
              <div class="password-input">
                <input
                  :type="mostrarSenha ? 'text' : 'password'"
                  id="senha"
                  v-model="loginData.senha"
                  placeholder="Digite sua senha"
                  required
                  :disabled="carregando"
                />
                <button
                  type="button"
                  @click="mostrarSenha = !mostrarSenha"
                  class="toggle-password"
                  :disabled="carregando"
                >
                  {{ mostrarSenha ? '🙈' : '👁️' }}
                </button>
              </div>
              <small class="password-hint" v-if="primeiroAcesso">
                💡 Use a senha temporária enviada por email
              </small>
            </div>

            <!-- Mensagens de Erro/Sucesso -->
            <div v-if="mensagem" class="alert" :class="tipoMensagem">
              {{ mensagem }}
            </div>

            <!-- Botão de Login -->
            <button
              type="submit"
              class="btn-login"
              :disabled="carregando || !loginData.email || !loginData.senha"
            >
              <span v-if="carregando">⏳ Entrando...</span>
              <span v-else>🚀 Entrar no Sistema</span>
            </button>
          </form>

          <!-- Links Auxiliares -->
          <div class="login-footer">
            <div class="links">
              <a href="#" @click.prevent="mostrarModalAjuda = true">❓ Esqueci minha senha</a>
              <a href="#" @click.prevent="mostrarModalContato = true">📞 Suporte</a>
            </div>
            <div class="info">
              <small>🔒 Acesso seguro e criptografado</small>
            </div>
          </div>
        </div>

        <!-- Cards Informativos -->
        <div class="info-cards">
          <div class="info-card">
            <h3>📝 O que você pode fazer</h3>
            <ul>
              <li>✅ Emitir RDMs on-line</li>
              <li>📊 Acompanhar status das solicitações</li>
              <li>📋 Consultar histórico</li>
              <li>🔔 Receber notificações automáticas</li>
            </ul>
          </div>

          <div class="info-card">
            <h3>⚡ Primeiro Acesso?</h3>
            <p>Informe o e-mail e senha recebidos por e-mail</p>
            <ol>
              <li>Use o e-mail e senha enviados por e-mail</li>
              <li>Altere sua senha no primeiro login</li>
              <li>Configure suas preferências</li>
              <li>Comece a usar o sistema!</li>
            </ol>
          </div>
        </div>
      </div>
    </main>

    <!-- Modal de Ajuda -->
    <div v-if="mostrarModalAjuda" class="modal-overlay" @click="mostrarModalAjuda = false">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>❓ Esqueci minha senha</h3>
          <button @click="mostrarModalAjuda = false" class="btn-close">✕</button>
        </div>
        <div class="modal-body">
          <p>Entre em contato com o CPM para redefinir sua senha:</p>
          <div class="contact-info">
            <p>📧 <strong>E-mail:</strong> comprarbemteste@gmail.com</p>
            <p>📞 <strong>Telefone:</strong> (61) 3315-2425</p>
          </div>
          <p><small>💡 Informe seu nome completo e unidade/setor</small></p>
        </div>
      </div>
    </div>

    <!-- Modal de Contato -->
    <div v-if="mostrarModalContato" class="modal-overlay" @click="mostrarModalContato = false">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>📞 Suporte Técnico</h3>
          <button @click="mostrarModalContato = false" class="btn-close">✕</button>
        </div>
        <div class="modal-body">
          <div class="contact-info">
            <h4>💬 Canais de Atendimento:</h4>
            <p>📧 <strong>E-mail:</strong> comprarbemteste@gmail.com</p>
            <p>📞 <strong>Telefone:</strong> (61) 3315-2425</p>
            <p>🕐 <strong>Horário:</strong> Segunda a Sexta, 8h às 17h</p>
          </div>
          <div class="faq">
            <h4>❓ Problemas Comuns:</h4>
            <ul>
              <li><strong>Não recebi o email:</strong> Verifique spam/lixeira</li>
              <li><strong>Senha não funciona:</strong> Certifique-se de usar a senha temporária</li>
              <li><strong>Conta bloqueada:</strong> Contate o CPM</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'LoginRDM',
  data() {
    return {
      loginData: {
        email: '',
        senha: ''
      },
      carregando: false,
      mostrarSenha: false,
      mensagem: '',
      tipoMensagem: '',
      primeiroAcesso: false,
      mostrarModalAjuda: false,
      mostrarModalContato: false
    }
  },
  async mounted() {
    await this.verificarSessaoExistente()
  },
  methods: {
    async verificarSessaoExistente() {
      try {
        const { data } = await supabase.auth.getSession()
        if (data?.session?.user) {
          const { data: usuario, error } = await supabase
            .from('usuarios_rdm')
            .select('*')
            .eq('email', data.session.user.email)
            .single()
          
          if (!error && usuario) {
            console.log('Usuário RDM já logado, redirecionando...')
            this.$router.push('/dashboard-rdm')
          }
        }
      } catch (error) {
        console.log('Nenhuma sessão ativa encontrada')
      }
    },

    async fazerLogin() {
      if (this.carregando) return
      
      this.carregando = true
      this.mensagem = ''
      
      try {
        console.log('🔐 Tentativa de login RDM:', this.loginData.email)
        
        // Buscar usuário RDM - query simplificada
        console.log('🔍 Buscando usuário RDM no banco:', this.loginData.email)
        
        const { data: usuarios, error: errorUsuario } = await supabase
          .from('usuarios_rdm')
          .select('*')
          .eq('email', this.loginData.email)
        
        const usuarioRDM = usuarios && usuarios.length > 0 ? usuarios[0] : null
        
        console.log('🔍 Resultado da busca:', {
          encontrou: !!usuarioRDM,
          erro: errorUsuario?.message || 'Nenhum erro',
          dados: usuarioRDM ? {
            id: usuarioRDM.id,
            nome: usuarioRDM.nome_usuario,
            email: usuarioRDM.email,
            ativo: usuarioRDM.ativo,
            tem_senha: !!usuarioRDM.senha_temporaria
          } : null
        })
        
        if (errorUsuario) {
          console.error('❌ Erro na consulta ao banco:', errorUsuario)
          throw new Error('Erro ao consultar banco de dados. Tente novamente.')
        }
        
        if (!usuarioRDM) {
          throw new Error('Email não encontrado. Verifique se o email está correto ou contate o CPM.')
        }
        
        if (!usuarioRDM.ativo) {
          throw new Error('Usuário inativo. Contate o CPM para ativar sua conta.')
        }
        
        console.log('✅ Usuário RDM encontrado:', usuarioRDM.nome_usuario)
        
        // SISTEMA SIMPLIFICADO: Verificar apenas a senha fixa
        if (usuarioRDM.senha_temporaria !== this.loginData.senha) {
          throw new Error('Senha incorreta. Verifique sua senha cadastrada.')
        }
        
        console.log('✅ Login realizado com sucesso - senha validada')
        
        // Salvar dados do usuário no localStorage
        localStorage.setItem('usuarioRDM', JSON.stringify({
          id: usuarioRDM.id,
          user_id: usuarioRDM.user_id,
          nome_usuario: usuarioRDM.nome_usuario,
          email: usuarioRDM.email,
          unidade_setor: usuarioRDM.unidade_setor,
          nome_coordenador: usuarioRDM.nome_coordenador,
          materiais: usuarioRDM.materiais,
          tenant_id: usuarioRDM.tenant_id
        }))
        
        // Atualizar última atividade
        await supabase
          .from('usuarios_rdm')
          .update({ 
            atualizado_em: new Date().toISOString(),
            convite_aceito: true // Sempre marcar como aceito após login
          })
          .eq('id', usuarioRDM.id)
        
        this.mensagem = `🎉 Bem-vindo(a), ${usuarioRDM.nome_usuario}!`
        this.tipoMensagem = 'success'
        
        console.log('✅ Login RDM realizado com sucesso!')
        
        setTimeout(() => {
          this.$router.push('/dashboard-rdm')
        }, 1500)
        
      } catch (error) {
        console.error('❌ Erro no login RDM:', error)
        this.mensagem = error.message
        this.tipoMensagem = 'error'
      } finally {
        this.carregando = false
      }
    }
  }
}
</script>

<style scoped>
.login-rdm-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  font-family: 'Arial', sans-serif;
}

.login-header {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  padding: 1rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

.logo-section h1 {
  color: white;
  margin: 0;
  font-size: 2rem;
  font-weight: bold;
}

.subtitle {
  color: rgba(255, 255, 255, 0.8);
  font-size: 1rem;
}

.login-main {
  padding: 3rem 0;
  display: flex;
  align-items: center;
  min-height: calc(100vh - 100px);
}

.login-card {
  background: white;
  border-radius: 20px;
  padding: 2.5rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  max-width: 450px;
  margin: 0 auto;
}

.card-header {
  text-align: center;
  margin-bottom: 2rem;
}

.card-header h2 {
  color: #333;
  margin: 0 0 0.5rem;
  font-size: 1.8rem;
}

.card-header p {
  color: #666;
  margin: 0;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  color: #333;
  margin-bottom: 0.5rem;
  font-weight: 600;
}

.form-group input {
  width: 100%;
  padding: 1rem;
  border: 2px solid #e1e5e9;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.3s;
  box-sizing: border-box;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
}

.password-input {
  position: relative;
}

.toggle-password {
  position: absolute;
  right: 1rem;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1.2rem;
}

.password-hint {
  color: #28a745;
  font-style: italic;
  margin-top: 0.5rem;
  display: block;
}

.alert {
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1rem;
  text-align: center;
  font-weight: 500;
}

.alert.success {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.alert.error {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.btn-login {
  width: 100%;
  padding: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-login:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
}

.btn-login:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.login-footer {
  text-align: center;
  margin-top: 2rem;
}

.links {
  margin-bottom: 1rem;
}

.links a {
  color: #667eea;
  text-decoration: none;
  margin: 0 1rem;
  font-size: 0.9rem;
}

.links a:hover {
  text-decoration: underline;
}

.info small {
  color: #666;
}

.info-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin-top: 2rem;
}

.info-card {
  background: rgba(255, 255, 255, 0.95);
  padding: 2rem;
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

.info-card h3 {
  color: #333;
  margin: 0 0 1rem;
  font-size: 1.3rem;
}

.info-card ul,
.info-card ol {
  color: #555;
  padding-left: 1.5rem;
}

.info-card li {
  margin-bottom: 0.5rem;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 15px;
  max-width: 500px;
  margin: 1rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #eee;
}

.modal-header h3 {
  margin: 0;
  color: #333;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #999;
}

.btn-close:hover {
  color: #333;
}

.modal-body {
  padding: 2rem;
}

.contact-info {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 8px;
  margin: 1rem 0;
}

.contact-info p {
  margin: 0.5rem 0;
}

.faq {
  margin-top: 1.5rem;
}

.faq h4 {
  color: #333;
  margin-bottom: 1rem;
}

.faq ul {
  color: #555;
}

.faq li {
  margin-bottom: 0.5rem;
}

/* Responsive */
@media (max-width: 768px) {
  .login-card {
    margin: 1rem;
    padding: 2rem;
  }
  
  .info-cards {
    grid-template-columns: 1fr;
    margin: 1rem;
  }
  
  .login-main {
    padding: 2rem 0;
  }
}
</style> 