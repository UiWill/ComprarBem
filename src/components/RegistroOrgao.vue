<template>
  <div class="registro-container">
    <div class="registro-header">
      <h1>🏛️ Cadastro de Órgão Público</h1>
      <p class="subtitle">
        Registre seu órgão e crie automaticamente os 4 perfis de acesso necessários
      </p>
    </div>

    <div class="progress-indicator" v-if="!registroCompleto">
      <div class="step" :class="{ active: etapaAtual === 1 }">
        <div class="step-number">1</div>
        <div class="step-label">Dados do Órgão</div>
      </div>
      <div class="step" :class="{ active: etapaAtual === 2 }">
        <div class="step-number">2</div>
        <div class="step-label">Usuários e Acessos</div>
      </div>
      <div class="step" :class="{ active: etapaAtual === 3 }">
        <div class="step-number">3</div>
        <div class="step-label">Confirmação</div>
      </div>
    </div>

    <!-- ETAPA 1: DADOS DO ÓRGÃO -->
    <div v-if="etapaAtual === 1" class="etapa-container">
      <div class="card">
        <h2>📋 Informações do Órgão</h2>
        
        <div class="form-group">
          <label>Nome do Órgão *</label>
          <input 
            type="text" 
            v-model="dadosOrgao.nome_orgao"
            placeholder="Ex: Prefeitura Municipal de Nova Lima"
            required
          >
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Tipo de Órgão *</label>
            <select v-model="dadosOrgao.tipo_orgao" required>
              <option value="municipal">Municipal</option>
              <option value="estadual">Estadual</option>
              <option value="federal">Federal</option>
              <option value="publico">Outros Órgãos Públicos</option>
            </select>
          </div>
          
          <div class="form-group">
            <label>CNPJ</label>
            <input 
              type="text" 
              v-model="dadosOrgao.cnpj"
              placeholder="00.000.000/0000-00"
              @input="formatarCNPJ"
            >
          </div>
        </div>

        <div class="form-group">
          <label>Endereço</label>
          <textarea 
            v-model="dadosOrgao.endereco"
            rows="2"
            placeholder="Endereço completo do órgão..."
          ></textarea>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Telefone</label>
            <input 
              type="tel" 
              v-model="dadosOrgao.telefone"
              placeholder="(31) 9999-9999"
            >
          </div>
          
          <div class="form-group">
            <label>Email de Contato</label>
            <input 
              type="email" 
              v-model="dadosOrgao.email_contato"
              placeholder="contato@orgao.gov.br"
            >
          </div>
        </div>

        <div class="form-actions">
          <button @click="proximaEtapa" :disabled="!dadosOrgaoValidos" class="btn-primary">
            Próximo: Configurar Usuários →
          </button>
        </div>
      </div>
    </div>

    <!-- ETAPA 2: USUÁRIOS E ACESSOS -->
    <div v-if="etapaAtual === 2" class="etapa-container">
      <div class="usuarios-info">
        <h2>👥 Configuração de Usuários</h2>
        <p class="info-text">
          Serão criados 4 usuários com acessos específicos para seu órgão:
        </p>
      </div>

      <!-- CPM -->
      <div class="card usuario-card cpm">
        <div class="usuario-header">
          <div class="usuario-icon">🔧</div>
          <div class="usuario-info">
            <h3>CPM - Comissão Permanente de Padronização</h3>
            <p>Acesso completo ao sistema (exceto Painel CCL)</p>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-group">
            <label>Email CPM *</label>
            <input 
              type="email" 
              v-model="dadosOrgao.email_cpm"
              placeholder="cpm@orgao.gov.br"
              required
            >
          </div>
          <div class="form-group">
            <label>Senha CPM *</label>
            <input 
              type="password" 
              v-model="dadosOrgao.senha_cpm"
              placeholder="Mínimo 6 caracteres"
              required
            >
          </div>
        </div>
        
        <div class="form-group">
          <label>Nome do Responsável</label>
          <input 
            type="text" 
            v-model="dadosOrgao.nome_responsavel_cpm"
            placeholder="Nome do Presidente da CPM"
          >
        </div>
      </div>

      <!-- CCL -->
      <div class="card usuario-card ccl">
        <div class="usuario-header">
          <div class="usuario-icon">⚖️</div>
          <div class="usuario-info">
            <h3>CCL - Comissão de Contratação e Licitação</h3>
            <p>Acesso exclusivo ao Painel CCL</p>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-group">
            <label>Email CCL *</label>
            <input 
              type="email" 
              v-model="dadosOrgao.email_ccl"
              placeholder="ccl@orgao.gov.br"
              required
            >
          </div>
          <div class="form-group">
            <label>Senha CCL *</label>
            <input 
              type="password" 
              v-model="dadosOrgao.senha_ccl"
              placeholder="Mínimo 6 caracteres"
              required
            >
          </div>
        </div>
        
        <div class="form-group">
          <label>Nome do Responsável</label>
          <input 
            type="text" 
            v-model="dadosOrgao.nome_responsavel_ccl"
            placeholder="Nome do Presidente da CCL"
          >
        </div>
      </div>

      <!-- ÓRGÃO ADMINISTRATIVO -->
      <div class="card usuario-card admin">
        <div class="usuario-header">
          <div class="usuario-icon">📋</div>
          <div class="usuario-info">
            <h3>Órgão Administrativo</h3>
            <p>Assinaturas digitais e homologações</p>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-group">
            <label>Email Autoridade *</label>
            <input 
              type="email" 
              v-model="dadosOrgao.email_orgao_admin"
              placeholder="autoridade@orgao.gov.br"
              required
            >
          </div>
          <div class="form-group">
            <label>Senha *</label>
            <input 
              type="password" 
              v-model="dadosOrgao.senha_orgao_admin"
              placeholder="Mínimo 6 caracteres"
              required
            >
          </div>
        </div>
        
        <div class="form-group">
          <label>Nome da Autoridade</label>
          <input 
            type="text" 
            v-model="dadosOrgao.nome_responsavel_admin"
            placeholder="Nome da Autoridade Competente"
          >
        </div>
      </div>

      <!-- ASSESSORIA JURÍDICA -->
      <div class="card usuario-card juridico">
        <div class="usuario-header">
          <div class="usuario-icon">⚖️</div>
          <div class="usuario-info">
            <h3>Assessoria Jurídica</h3>
            <p>Análise de minutas e editais</p>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-group">
            <label>Email Assessoria *</label>
            <input 
              type="email" 
              v-model="dadosOrgao.email_assessoria"
              placeholder="juridico@orgao.gov.br"
              required
            >
          </div>
          <div class="form-group">
            <label>Senha *</label>
            <input 
              type="password" 
              v-model="dadosOrgao.senha_assessoria"
              placeholder="Mínimo 6 caracteres"
              required
            >
          </div>
        </div>
        
        <div class="form-group">
          <label>Nome do Responsável</label>
          <input 
            type="text" 
            v-model="dadosOrgao.nome_responsavel_assessoria"
            placeholder="Nome do Assessor Jurídico"
          >
        </div>
      </div>

      <div class="form-actions">
        <button @click="voltarEtapa" class="btn-secondary">
          ← Voltar
        </button>
        <button @click="proximaEtapa" :disabled="!usuariosValidos" class="btn-primary">
          Revisar e Confirmar →
        </button>
      </div>
    </div>

    <!-- ETAPA 3: CONFIRMAÇÃO -->
    <div v-if="etapaAtual === 3" class="etapa-container">
      <div class="card">
        <h2>✅ Revisão e Confirmação</h2>
        
        <div class="revisao-secao">
          <h3>🏛️ Dados do Órgão</h3>
          <div class="revisao-item">
            <strong>Nome:</strong> {{ dadosOrgao.nome_orgao }}
          </div>
          <div class="revisao-item">
            <strong>Tipo:</strong> {{ dadosOrgao.tipo_orgao }}
          </div>
          <div v-if="dadosOrgao.cnpj" class="revisao-item">
            <strong>CNPJ:</strong> {{ dadosOrgao.cnpj }}
          </div>
        </div>

        <div class="revisao-secao">
          <h3>👥 Usuários que serão criados</h3>
          <div class="usuarios-resumo">
            <div class="usuario-resumo cpm">
              <div class="usuario-resumo-header">
                <span class="icon">🔧</span>
                <strong>CPM</strong>
              </div>
              <div>{{ dadosOrgao.email_cpm }}</div>
              <small>Acesso completo (exceto CCL)</small>
            </div>
            
            <div class="usuario-resumo ccl">
              <div class="usuario-resumo-header">
                <span class="icon">⚖️</span>
                <strong>CCL</strong>
              </div>
              <div>{{ dadosOrgao.email_ccl }}</div>
              <small>Apenas Painel CCL</small>
            </div>
            
            <div class="usuario-resumo admin">
              <div class="usuario-resumo-header">
                <span class="icon">📋</span>
                <strong>Órgão Administrativo</strong>
              </div>
              <div>{{ dadosOrgao.email_orgao_admin }}</div>
              <small>Assinaturas e homologações</small>
            </div>
            
            <div class="usuario-resumo juridico">
              <div class="usuario-resumo-header">
                <span class="icon">⚖️</span>
                <strong>Assessoria Jurídica</strong>
              </div>
              <div>{{ dadosOrgao.email_assessoria }}</div>
              <small>Análise jurídica</small>
            </div>
          </div>
        </div>

        <div class="alerta-importante">
          <div class="alerta-icon">⚠️</div>
          <div class="alerta-conteudo">
            <strong>Importante:</strong>
            <ul>
              <li>Todos os dados serão salvos e não poderão ser alterados</li>
              <li>Os emails de acesso serão enviados para cada responsável</li>
              <li>Cada usuário terá acesso apenas às funcionalidades do seu perfil</li>
              <li>Anote as senhas em local seguro</li>
            </ul>
          </div>
        </div>

        <div class="form-actions">
          <button @click="voltarEtapa" class="btn-secondary" :disabled="processando">
            ← Voltar
          </button>
          <button @click="confirmarRegistro" class="btn-success" :disabled="processando">
            {{ processando ? 'Registrando...' : '🎉 Confirmar e Criar Órgão' }}
          </button>
        </div>
      </div>
    </div>

    <!-- RESULTADO DO REGISTRO -->
    <div v-if="registroCompleto" class="resultado-container">
      <div class="card resultado-card">
        <div class="resultado-header">
          <div class="resultado-icon success">🎉</div>
          <h1>Órgão Registrado com Sucesso!</h1>
          <p>{{ dadosOrgao.nome_orgao }} foi cadastrado no sistema.</p>
        </div>

        <div class="credenciais-acesso">
          <h3>🔑 Credenciais de Acesso</h3>
          <div class="credenciais-lista">
            <div class="credencial-item cpm">
              <div class="credencial-header">
                <span class="icon">🔧</span>
                <strong>CPM - Comissão Permanente</strong>
              </div>
              <div class="credencial-info">
                <div><strong>Email:</strong> {{ dadosOrgao.email_cpm }}</div>
                <div><strong>Senha:</strong> {{ dadosOrgao.senha_cpm }}</div>
                <div><strong>Acesso:</strong> Sistema completo (exceto CCL)</div>
              </div>
            </div>

            <div class="credencial-item ccl">
              <div class="credencial-header">
                <span class="icon">⚖️</span>
                <strong>CCL - Comissão de Contratação</strong>
              </div>
              <div class="credencial-info">
                <div><strong>Email:</strong> {{ dadosOrgao.email_ccl }}</div>
                <div><strong>Senha:</strong> {{ dadosOrgao.senha_ccl }}</div>
                <div><strong>Acesso:</strong> Apenas Painel CCL</div>
              </div>
            </div>

            <div class="credencial-item admin">
              <div class="credencial-header">
                <span class="icon">📋</span>
                <strong>Órgão Administrativo</strong>
              </div>
              <div class="credencial-info">
                <div><strong>Email:</strong> {{ dadosOrgao.email_orgao_admin }}</div>
                <div><strong>Senha:</strong> {{ dadosOrgao.senha_orgao_admin }}</div>
                <div><strong>Acesso:</strong> Processos para assinatura</div>
              </div>
            </div>

            <div class="credencial-item juridico">
              <div class="credencial-header">
                <span class="icon">⚖️</span>
                <strong>Assessoria Jurídica</strong>
              </div>
              <div class="credencial-info">
                <div><strong>Email:</strong> {{ dadosOrgao.email_assessoria }}</div>
                <div><strong>Senha:</strong> {{ dadosOrgao.senha_assessoria }}</div>
                <div><strong>Acesso:</strong> Análise jurídica de processos</div>
              </div>
            </div>
          </div>
        </div>

        <div class="proximos-passos">
          <h3>🚀 Próximos Passos</h3>
          <ol>
            <li>Distribua as credenciais para cada responsável</li>
            <li>Oriente sobre o primeiro acesso ao sistema</li>
            <li>Configure os dados específicos de cada módulo</li>
            <li>Inicie o cadastro de produtos e processos</li>
          </ol>
        </div>

        <div class="form-actions">
          <button @click="novoRegistro" class="btn-secondary">
            Registrar Outro Órgão
          </button>
          <router-link to="/" class="btn-primary">
            Ir para o Sistema
          </router-link>
        </div>
      </div>
    </div>

    <!-- ERRO -->
    <div v-if="erro" class="erro-container">
      <div class="card erro-card">
        <div class="erro-header">
          <div class="erro-icon">❌</div>
          <h2>Erro no Registro</h2>
          <p>{{ erro }}</p>
        </div>
        <div class="form-actions">
          <button @click="erro = null" class="btn-primary">
            Tentar Novamente
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import RegistroOrgaoService from '../services/registroOrgaoService'

export default {
  name: 'RegistroOrgao',
  data() {
    return {
      etapaAtual: 1,
      processando: false,
      registroCompleto: false,
      erro: null,
      dadosOrgao: RegistroOrgaoService.obterTemplateDados()
    }
  },
  
  computed: {
    dadosOrgaoValidos() {
      return this.dadosOrgao.nome_orgao && 
             this.dadosOrgao.nome_orgao.trim().length > 0
    },
    
    usuariosValidos() {
      const emails = [
        this.dadosOrgao.email_cpm,
        this.dadosOrgao.email_ccl, 
        this.dadosOrgao.email_orgao_admin,
        this.dadosOrgao.email_assessoria
      ]
      
      const senhas = [
        this.dadosOrgao.senha_cpm,
        this.dadosOrgao.senha_ccl,
        this.dadosOrgao.senha_orgao_admin,
        this.dadosOrgao.senha_assessoria
      ]
      
      // Verificar se todos os emails estão preenchidos
      const emailsPreenchidos = emails.every(email => email && email.trim().length > 0)
      
      // Verificar se todas as senhas estão preenchidas e têm pelo menos 6 caracteres
      const senhasValidas = senhas.every(senha => senha && senha.length >= 6)
      
      // Verificar se emails são únicos
      const emailsUnicos = new Set(emails).size === emails.length
      
      return emailsPreenchidos && senhasValidas && emailsUnicos
    }
  },
  
  methods: {
    proximaEtapa() {
      if (this.etapaAtual < 3) {
        this.etapaAtual++
      }
    },
    
    voltarEtapa() {
      if (this.etapaAtual > 1) {
        this.etapaAtual--
      }
    },
    
    async confirmarRegistro() {
      try {
        this.processando = true
        this.erro = null
        
        const resultado = await RegistroOrgaoService.registrarOrgaoCompleto(this.dadosOrgao)
        
        if (resultado.sucesso) {
          this.registroCompleto = true
        } else {
          this.erro = resultado.mensagem || 'Erro desconhecido no registro'
        }
        
      } catch (error) {
        console.error('Erro no registro:', error)
        this.erro = error.message || 'Erro inesperado durante o registro'
      } finally {
        this.processando = false
      }
    },
    
    novoRegistro() {
      this.etapaAtual = 1
      this.registroCompleto = false
      this.erro = null
      this.dadosOrgao = RegistroOrgaoService.obterTemplateDados()
    },
    
    formatarCNPJ() {
      let cnpj = this.dadosOrgao.cnpj.replace(/\D/g, '')
      cnpj = cnpj.replace(/^(\d{2})(\d)/, '$1.$2')
      cnpj = cnpj.replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
      cnpj = cnpj.replace(/\.(\d{3})(\d)/, '.$1/$2')
      cnpj = cnpj.replace(/(\d{4})(\d)/, '$1-$2')
      this.dadosOrgao.cnpj = cnpj
    }
  }
}
</script>

<style scoped>
.registro-container {
  max-width: 1000px;
  margin: 0 auto;
  padding: 2rem;
  background: #f8fafc;
  min-height: 100vh;
}

.registro-header {
  text-align: center;
  margin-bottom: 3rem;
}

.registro-header h1 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 2.5rem;
}

.subtitle {
  color: #718096;
  font-size: 1.1rem;
  max-width: 600px;
  margin: 0 auto;
}

.progress-indicator {
  display: flex;
  justify-content: center;
  margin-bottom: 3rem;
  gap: 2rem;
}

.step {
  display: flex;
  flex-direction: column;
  align-items: center;
  opacity: 0.5;
  transition: all 0.3s ease;
}

.step.active {
  opacity: 1;
}

.step-number {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #e2e8f0;
  color: #4a5568;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.step.active .step-number {
  background: #3182ce;
  color: white;
}

.step-label {
  font-size: 0.9rem;
  color: #4a5568;
  text-align: center;
}

.etapa-container {
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  margin-bottom: 2rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  border: 1px solid #e2e8f0;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #374151;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: border-color 0.3s ease;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3182ce;
  box-shadow: 0 0 0 3px rgba(49, 130, 206, 0.1);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.usuarios-info {
  text-align: center;
  margin-bottom: 2rem;
}

.info-text {
  color: #4a5568;
  font-size: 1.1rem;
}

.usuario-card {
  border-left: 4px solid #e2e8f0;
  margin-bottom: 2rem;
}

.usuario-card.cpm { border-left-color: #3182ce; }
.usuario-card.ccl { border-left-color: #48bb78; }
.usuario-card.admin { border-left-color: #ed8936; }
.usuario-card.juridico { border-left-color: #9f7aea; }

.usuario-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.usuario-icon {
  font-size: 2rem;
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f7fafc;
}

.usuario-info h3 {
  margin: 0 0 0.25rem 0;
  color: #2d3748;
}

.usuario-info p {
  margin: 0;
  color: #718096;
  font-size: 0.9rem;
}

.revisao-secao {
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid #e2e8f0;
}

.revisao-secao:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.revisao-secao h3 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.revisao-item {
  margin-bottom: 0.75rem;
  display: flex;
  gap: 0.5rem;
}

.revisao-item strong {
  color: #4a5568;
  min-width: 80px;
}

.usuarios-resumo {
  display: grid;
  gap: 1rem;
}

.usuario-resumo {
  padding: 1rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.usuario-resumo.cpm { background: #ebf8ff; }
.usuario-resumo.ccl { background: #f0fff4; }
.usuario-resumo.admin { background: #fffaf0; }
.usuario-resumo.juridico { background: #faf5ff; }

.usuario-resumo-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.usuario-resumo small {
  color: #718096;
  font-style: italic;
}

.alerta-importante {
  display: flex;
  gap: 1rem;
  padding: 1.5rem;
  background: #fef5e7;
  border: 1px solid #f6ad55;
  border-radius: 8px;
  margin: 2rem 0;
}

.alerta-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.alerta-conteudo ul {
  margin: 0.5rem 0 0 0;
  padding-left: 1.5rem;
}

.alerta-conteudo li {
  margin-bottom: 0.25rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
  flex-wrap: wrap;
}

.btn-primary,
.btn-secondary,
.btn-success {
  padding: 0.75rem 2rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  border: none;
  text-decoration: none;
  text-align: center;
}

.btn-primary {
  background: #3182ce;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2c5282;
  transform: translateY(-1px);
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover:not(:disabled) {
  background: #cbd5e0;
}

.btn-success {
  background: #48bb78;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #38a169;
  transform: translateY(-1px);
}

.btn-primary:disabled,
.btn-secondary:disabled,
.btn-success:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.resultado-container,
.erro-container {
  animation: slideIn 0.5s ease-out;
}

.resultado-card {
  text-align: center;
}

.resultado-header {
  margin-bottom: 2rem;
}

.resultado-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.resultado-icon.success {
  animation: bounce 0.6s ease-out;
}

@keyframes bounce {
  0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
  40% { transform: translateY(-10px); }
  60% { transform: translateY(-5px); }
}

.credenciais-acesso {
  text-align: left;
  margin: 2rem 0;
}

.credenciais-lista {
  display: grid;
  gap: 1rem;
}

.credencial-item {
  padding: 1.5rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.credencial-item.cpm { background: #ebf8ff; border-color: #3182ce; }
.credencial-item.ccl { background: #f0fff4; border-color: #48bb78; }
.credencial-item.admin { background: #fffaf0; border-color: #ed8936; }
.credencial-item.juridico { background: #faf5ff; border-color: #9f7aea; }

.credencial-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.credencial-info div {
  margin-bottom: 0.25rem;
}

.proximos-passos {
  text-align: left;
  margin: 2rem 0;
}

.proximos-passos ol {
  padding-left: 1.5rem;
}

.proximos-passos li {
  margin-bottom: 0.5rem;
}

.erro-card {
  text-align: center;
}

.erro-header {
  margin-bottom: 2rem;
}

.erro-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

@media (max-width: 768px) {
  .registro-container {
    padding: 1rem;
  }
  
  .progress-indicator {
    flex-direction: column;
    gap: 1rem;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .usuario-header {
    flex-direction: column;
    text-align: center;
  }
  
  .form-actions {
    flex-direction: column;
  }
  
  .btn-primary,
  .btn-secondary,
  .btn-success {
    width: 100%;
  }
}
</style>