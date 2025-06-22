<template>
  <div class="validar-dcb-container">
    <!-- Teste de renderização básica -->
    <div class="teste-basico">
      <h1>🔧 TESTE DE VALIDAÇÃO DCB</h1>
      <p>Se você está vendo esta mensagem, o Vue.js está funcionando!</p>
      <div class="info-debug">
        <p><strong>Número recebido:</strong> {{ numero || 'NENHUM' }}</p>
        <p><strong>Estado loading:</strong> {{ loading }}</p>
        <p><strong>Estado erro:</strong> {{ erro }}</p>
        <p><strong>DCB encontrado:</strong> {{ !!dcb }}</p>
        <p><strong>Timestamp:</strong> {{ new Date().toLocaleString('pt-BR') }}</p>
      </div>
    </div>

    <!-- Cabeçalho Oficial -->
    <div class="header-oficial">
      <div class="brasao">🇧🇷</div>
      <div class="header-text">
        <h1>REPÚBLICA FEDERATIVA DO BRASIL</h1>
        <h2>MINISTÉRIO DA SAÚDE</h2>
        <h3>Comissão de Padronização de Materiais - CPM</h3>
      </div>
    </div>

    <div class="validacao-content">
      <!-- Loading -->
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <h3>🔍 Validando DCB...</h3>
        <p>Verificando autenticidade do documento</p>
      </div>

      <!-- DCB Encontrado -->
      <div v-else-if="dcb && !erro" class="dcb-valido">
        <div class="status-validacao valido">
          <div class="status-icon">✅</div>
          <h2>DCB VÁLIDO E AUTÊNTICO</h2>
          <p>Este documento foi emitido oficialmente pela CPM</p>
        </div>

        <div class="dcb-detalhes">
          <div class="dcb-header">
            <h3>📜 DECLARAÇÃO DE CONFORMIDADE DE BEM</h3>
            <div class="numero-dcb">DCB Nº {{ dcb.numero_dcb }}</div>
          </div>

          <div class="informacoes-grid">
            <!-- Produto -->
            <div class="info-section">
              <h4>📦 PRODUTO CERTIFICADO</h4>
              <div class="info-item">
                <span class="label">Nome:</span>
                <span class="value">{{ dcb.produto_nome }}</span>
              </div>
              <div class="info-item">
                <span class="label">Marca:</span>
                <span class="value">{{ dcb.produto_marca }}</span>
              </div>
              <div class="info-item">
                <span class="label">Modelo:</span>
                <span class="value">{{ dcb.produto_modelo || 'N/A' }}</span>
              </div>
              <div class="info-item">
                <span class="label">Fabricante:</span>
                <span class="value">{{ dcb.produto_fabricante }}</span>
              </div>
            </div>

            <!-- Certificado -->
            <div class="info-section">
              <h4>📋 DADOS DO CERTIFICADO</h4>
              <div class="info-item">
                <span class="label">Data de Emissão:</span>
                <span class="value">{{ formatDate(dcb.data_emissao) }}</span>
              </div>
              <div class="info-item">
                <span class="label">Validade:</span>
                <span class="value">{{ formatDate(dcb.data_validade) }}</span>
              </div>
              <div class="info-item">
                <span class="label">Status:</span>
                <span class="value status" :class="getStatusClass(dcb.status)">
                  {{ formatStatus(dcb.status) }}
                </span>
              </div>
              <div class="info-item">
                <span class="label">Situação:</span>
                <span class="value" :class="getSituacaoClass()">
                  {{ getSituacao() }}
                </span>
              </div>
            </div>
          </div>

          <!-- Declaração -->
          <div class="declaracao-oficial">
            <h4>⚖️ DECLARAÇÃO OFICIAL</h4>
            <p>
              Este documento certifica que o produto foi submetido à análise técnica pela 
              Comissão de Padronização de Materiais (CPM) e foi <strong>APROVADO</strong> 
              para utilização em processos licitatórios, conforme Lei Federal nº 14.133/2021.
            </p>
          </div>
        </div>
      </div>

      <!-- Debug Info (temporário) -->
      <div v-else-if="!dcb && !loading && !erro" class="debug-info">
        <div class="status-validacao debug">
          <div class="status-icon">🔧</div>
          <h2>DEBUG MODE</h2>
          <p>Loading: {{ loading }}, Erro: {{ erro }}, DCB: {{ !!dcb }}</p>
          <p>Número: {{ numeroConsultado }}</p>
        </div>
      </div>

      <!-- DCB Não Encontrado -->
      <div v-else-if="erro" class="dcb-invalido">
        <div class="status-validacao invalido">
          <div class="status-icon">❌</div>
          <h2>DCB NÃO ENCONTRADO</h2>
          <p>O número de DCB informado não foi localizado em nossa base de dados</p>
        </div>

        <div class="erro-detalhes">
          <h4>🔍 Número pesquisado: {{ numeroConsultado }}</h4>
          <div class="possibilidades">
            <h5>Possíveis causas:</h5>
            <ul>
              <li>Número de DCB digitado incorretamente</li>
              <li>DCB ainda não emitido ou cancelado</li>
              <li>Documento fraudulento</li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Instruções -->
      <div class="instrucoes">
        <h4>ℹ️ Como usar esta validação</h4>
        <div class="instrucoes-grid">
          <div class="instrucao">
            <div class="instrucao-icon">📱</div>
            <h5>QR Code</h5>
            <p>Escaneie o QR Code no documento PDF oficial</p>
          </div>
          <div class="instrucao">
            <div class="instrucao-icon">🔗</div>
            <h5>Link Direto</h5>
            <p>Acesse via link fornecido no documento</p>
          </div>
          <div class="instrucao">
            <div class="instrucao-icon">🔒</div>
            <h5>Segurança</h5>
            <p>Verificação oficial pela CPM em tempo real</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Rodapé -->
    <div class="rodape-oficial">
      <p>
        Sistema ComprarBem - Plataforma Oficial de Pré-Qualificação de Bens<br>
        Ministério da Saúde - Comissão de Padronização de Materiais (CPM)
      </p>
      <small>Consulta realizada em {{ new Date().toLocaleString('pt-BR') }}</small>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ValidarDCB',
  props: {
    numero: {
      type: String,
      required: false,
      default: 'TESTE'
    }
  },
  data() {
    return {
      dcb: null,
      loading: false,
      erro: false,
      numeroConsultado: ''
    }
  },
  mounted() {
    console.log('=== ValidarDCB MOUNTED ===')
    console.log('Numero prop:', this.numero)
    console.log('Route params:', this.$route.params)
    
    this.numeroConsultado = this.numero || this.$route.params.numero || 'SEM_NUMERO'
    
    // Simular busca por agora
    setTimeout(() => {
      this.simularBusca()
    }, 2000)
  },
  methods: {
    simularBusca() {
      console.log('=== SIMULANDO BUSCA DCB ===')
      this.loading = true
      
      setTimeout(() => {
        // Simular DCB encontrado
        this.dcb = {
          numero_dcb: this.numeroConsultado,
          data_emissao: '2024-06-22',
          data_validade: '2025-06-22',
          status: 'ativo',
          produto_nome: 'Produto Teste',
          produto_marca: 'Marca Teste',
          produto_modelo: 'Modelo Teste',
          produto_fabricante: 'Fabricante Teste'
        }
        this.loading = false
        this.erro = false
        console.log('DCB simulado criado:', this.dcb)
      }, 1000)
    },

    formatDate(dateString) {
      if (!dateString) return 'N/A'
      return new Date(dateString).toLocaleDateString('pt-BR')
    },

    formatStatus(status) {
      const statusMap = {
        'ativo': 'ATIVO',
        'revogado': 'REVOGADO',
        'vencido': 'VENCIDO'
      }
      return statusMap[status] || status.toUpperCase()
    },

    getStatusClass(status) {
      return {
        'status-ativo': status === 'ativo',
        'status-revogado': status === 'revogado',
        'status-vencido': status === 'vencido'
      }
    },

    getSituacao() {
      if (!this.dcb) return 'N/A'
      
      const hoje = new Date()
      const validade = new Date(this.dcb.data_validade)
      
      if (this.dcb.status !== 'ativo') {
        return 'INVÁLIDO PARA USO'
      }
      
      if (validade < hoje) {
        return 'VENCIDO'
      }
      
      return 'VÁLIDO PARA LICITAÇÕES'
    },

    getSituacaoClass() {
      const situacao = this.getSituacao()
      return {
        'situacao-valido': situacao === 'VÁLIDO PARA LICITAÇÕES',
        'situacao-vencido': situacao === 'VENCIDO',
        'situacao-invalido': situacao === 'INVÁLIDO PARA USO'
      }
    }
  }
}
</script>

<style scoped>
.validar-dcb-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

/* Teste básico */
.teste-basico {
  background: #fff;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  border: 3px solid #e74c3c;
}

.teste-basico h1 {
  color: #e74c3c;
  margin: 0 0 15px 0;
}

.info-debug {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 5px;
  border-left: 4px solid #3498db;
}

.info-debug p {
  margin: 5px 0;
  font-family: monospace;
}

.header-oficial {
  background: white;
  padding: 30px;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 8px 32px rgba(0,0,0,0.1);
  margin-bottom: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
}

.brasao {
  font-size: 60px;
}

.header-text h1 {
  color: #2c3e50;
  font-size: 24px;
  font-weight: bold;
  margin: 0;
}

.header-text h2 {
  color: #34495e;
  font-size: 20px;
  font-weight: 600;
  margin: 5px 0;
}

.header-text h3 {
  color: #7f8c8d;
  font-size: 16px;
  font-weight: normal;
  margin: 5px 0 0 0;
}

.validacao-content {
  max-width: 1000px;
  margin: 0 auto;
}

/* Loading */
.loading-state {
  background: white;
  padding: 60px;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 8px 32px rgba(0,0,0,0.1);
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* DCB Válido */
.dcb-valido {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.status-validacao {
  padding: 30px;
  text-align: center;
}

.status-validacao.valido {
  background: linear-gradient(135deg, #27ae60, #2ecc71);
  color: white;
}

.status-validacao.invalido {
  background: linear-gradient(135deg, #e74c3c, #c0392b);
  color: white;
}

.status-icon {
  font-size: 60px;
  margin-bottom: 15px;
}

.status-validacao h2 {
  margin: 0 0 10px 0;
  font-size: 28px;
  font-weight: bold;
}

.status-validacao p {
  margin: 0;
  font-size: 16px;
  opacity: 0.9;
}

/* Detalhes do DCB */
.dcb-detalhes {
  padding: 30px;
}

.dcb-header {
  text-align: center;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 2px solid #eee;
}

.dcb-header h3 {
  color: #2c3e50;
  font-size: 24px;
  margin: 0 0 10px 0;
}

.numero-dcb {
  font-size: 20px;
  font-weight: bold;
  color: #3498db;
  padding: 10px 20px;
  background: #f8f9fa;
  border-radius: 8px;
  display: inline-block;
}

.informacoes-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  margin-bottom: 30px;
}

.info-section h4 {
  color: #2c3e50;
  font-size: 18px;
  margin: 0 0 20px 0;
  padding: 10px 0;
  border-bottom: 2px solid #3498db;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.info-item:last-child {
  border-bottom: none;
}

.label {
  font-weight: 600;
  color: #555;
}

.value {
  font-weight: normal;
  text-align: right;
  max-width: 60%;
  word-break: break-word;
}

.status-ativo { color: #27ae60; font-weight: bold; }
.status-revogado { color: #e74c3c; font-weight: bold; }
.status-vencido { color: #f39c12; font-weight: bold; }

.situacao-valido { color: #27ae60; font-weight: bold; }
.situacao-vencido { color: #f39c12; font-weight: bold; }
.situacao-invalido { color: #e74c3c; font-weight: bold; }

/* Debug */
.debug-info {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.status-validacao.debug {
  background: linear-gradient(135deg, #f39c12, #e67e22);
}

/* Declaração */
.declaracao-oficial {
  background: #f8f9fa;
  padding: 25px;
  border-radius: 8px;
  border-left: 4px solid #3498db;
}

.declaracao-oficial h4 {
  color: #2c3e50;
  margin: 0 0 15px 0;
}

.declaracao-oficial p {
  line-height: 1.6;
  margin: 0;
  color: #555;
}

/* DCB Inválido */
.dcb-invalido {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.erro-detalhes {
  padding: 30px;
}

.erro-detalhes h4 {
  color: #e74c3c;
  margin-bottom: 20px;
  font-size: 18px;
}

.possibilidades h5 {
  color: #2c3e50;
  margin-bottom: 10px;
}

.possibilidades ul {
  padding-left: 20px;
}

.possibilidades li {
  margin-bottom: 8px;
  color: #555;
}

/* Instruções */
.instrucoes {
  background: white;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.instrucoes h4 {
  color: #2c3e50;
  text-align: center;
  margin-bottom: 25px;
}

.instrucoes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.instrucao {
  text-align: center;
  padding: 20px;
  border: 2px solid #f0f0f0;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.instrucao:hover {
  border-color: #3498db;
  transform: translateY(-5px);
}

.instrucao-icon {
  font-size: 40px;
  margin-bottom: 15px;
}

.instrucao h5 {
  color: #2c3e50;
  margin: 0 0 10px 0;
}

.instrucao p {
  color: #666;
  margin: 0;
  font-size: 14px;
}

/* Rodapé */
.rodape-oficial {
  background: rgba(255,255,255,0.1);
  backdrop-filter: blur(10px);
  padding: 20px;
  border-radius: 12px;
  text-align: center;
  color: white;
}

.rodape-oficial p {
  margin: 0 0 10px 0;
  font-weight: 500;
}

.rodape-oficial small {
  opacity: 0.8;
}

/* Responsivo */
@media (max-width: 768px) {
  .header-oficial {
    flex-direction: column;
    text-align: center;
  }
  
  .brasao {
    font-size: 40px;
  }
  
  .header-text h1 {
    font-size: 20px;
  }
  
  .informacoes-grid {
    grid-template-columns: 1fr;
  }
  
  .info-item {
    flex-direction: column;
    text-align: left;
    gap: 5px;
  }
  
  .value {
    text-align: left;
    max-width: 100%;
  }
}
</style> 