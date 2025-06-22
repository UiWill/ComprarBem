<template>
  <div class="validar-dcb-container">
    <!-- Cabeçalho Sistema -->
    <div class="header-oficial">
      <div class="brasao">🏥</div>
      <div class="header-text">
        <h1>SISTEMA COMPRAR BEM</h1>
        <h2>VALIDAÇÃO DE DCB</h2>
        <h3>Declaração de Conformidade de Bem</h3>
      </div>
    </div>

    <div class="validacao-content">
      <!-- Loading -->
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <h3>🔍 Validando DCB...</h3>
        <p>Verificando autenticidade do documento DCB {{ numeroCompleto }}</p>
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
            <div class="numero-dcb">DCB Nº {{ numeroCompleto }}</div>
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
            <h4>⚖️ DECLARAÇÃO DE CONFORMIDADE</h4>
            <p>
              Este documento certifica que o produto foi submetido à análise técnica pela 
              Comissão de Padronização de Materiais (CPM) e foi <strong>APROVADO</strong> 
              para utilização em processos licitatórios, conforme:
            </p>
            <ul class="legislacao-list">
              <li>Lei Federal nº 14.133/2021 (Lei de Licitações e Contratos)</li>
              <li>Programa "Comprar Bem - Compras Públicas Inteligentes"</li>
              <li>Normas técnicas específicas da categoria do produto</li>
            </ul>
            <p class="conformidade-status">
              <strong>Status de Conformidade:</strong> 
              <span :class="verificarConformidadeLegal() ? 'conforme' : 'nao-conforme'">
                {{ verificarConformidadeLegal() ? '✅ CONFORME' : '❌ NÃO CONFORME' }}
              </span>
            </p>
          </div>

          <!-- Segurança e Integridade -->
          <div class="seguranca-section" v-if="dcb.hash_documento">
            <h4>🔒 VERIFICAÇÃO DE SEGURANÇA</h4>
            <div class="verificacao-item">
              <span class="label">Integridade do Documento:</span>
              <span class="value" :class="dcb.integridade_verificada ? 'verificado' : 'nao-verificado'">
                {{ dcb.integridade_verificada ? '✅ VERIFICADA' : '⚠️ NÃO VERIFICADA' }}
              </span>
            </div>
            <div v-if="dcb.alerta_seguranca" class="alerta-seguranca">
              ⚠️ {{ dcb.alerta_seguranca }}
            </div>
            <div class="hash-info">
              <small>Hash SHA-256: {{ dcb.hash_documento?.substring(0, 16) }}...</small>
            </div>
          </div>
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
          <h4>🔍 Número pesquisado: {{ numeroCompleto }}</h4>
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
import { supabase } from '../services/supabase'

export default {
  name: 'ValidarDCB',
  props: {
    numero: String,
    ano: String
  },
  data() {
    return {
      dcb: null,
      loading: true,
      erro: false
    }
  },
  computed: {
    numeroCompleto() {
      return `${this.numero}/${this.ano}`
    }
  },
  async mounted() {
    console.log('=== ValidarDCB MOUNTED ===')
    console.log('Numero:', this.numero)
    console.log('Ano:', this.ano)
    console.log('Numero completo:', this.numeroCompleto)
    
    await this.buscarDCB()
  },
  methods: {
    async buscarDCB() {
      try {
        this.loading = true
        this.erro = false

        console.log('Buscando DCB:', this.numeroCompleto)
        console.log('Parâmetros da busca:', { numero_dcb: this.numeroCompleto })

        // Buscar DCB com dados do produto (sem restrição de tenant para validação pública)
        const { data, error } = await supabase
          .from('dcb_certificados')
          .select(`
            *,
            produtos (
              nome,
              marca,
              modelo,
              fabricante,
              cnpj_fabricante,
              cnpj
            )
          `)
          .eq('numero_dcb', this.numeroCompleto)
          .single()

        console.log('Resposta do Supabase - error:', error)
        console.log('Resposta do Supabase - data:', data)

        if (error) {
          console.error('Erro ao buscar DCB:', error)
          this.erro = true
          return
        }

        if (!data) {
          console.log('Nenhum DCB encontrado para:', this.numeroCompleto)
          this.erro = true
          return
        }

        // Montar objeto DCB com dados do produto
        this.dcb = {
          ...data,
          produto_nome: data.produtos?.nome || 'N/A',
          produto_marca: data.produtos?.marca || 'N/A',
          produto_modelo: data.produtos?.modelo || 'N/A',
          produto_fabricante: data.produtos?.fabricante || 'N/A',
          produto_cnpj: data.produtos?.cnpj_fabricante || data.produtos?.cnpj || 'N/A'
        }

        // Verificar integridade do documento (se hash_documento existir)
        if (data.hash_documento) {
          await this.verificarIntegridade(data)
        }

        console.log('DCB encontrado:', this.dcb)

      } catch (error) {
        console.error('Erro na validação:', error)
        this.erro = true
      } finally {
        this.loading = false
      }
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
    },

    async verificarIntegridade(dcbData) {
      try {
        // Gerar hash dos dados principais para verificação
        const dadosParaHash = {
          numero_dcb: dcbData.numero_dcb,
          produto_id: dcbData.produto_id,
          data_emissao: dcbData.data_emissao,
          data_validade: dcbData.data_validade
        }
        
        const hashCalculado = await this.calcularHash(JSON.stringify(dadosParaHash))
        
        if (hashCalculado !== dcbData.hash_documento) {
          console.warn('⚠️ ALERTA: Hash do documento não confere - possível alteração')
          this.dcb.integridade_verificada = false
          this.dcb.alerta_seguranca = 'Documento pode ter sido alterado'
        } else {
          console.log('✅ Integridade do documento verificada')
          this.dcb.integridade_verificada = true
        }
      } catch (error) {
        console.error('Erro na verificação de integridade:', error)
        this.dcb.integridade_verificada = false
      }
    },

    async calcularHash(dados) {
      // Usar Web Crypto API para calcular hash SHA-256
      const encoder = new TextEncoder()
      const data = encoder.encode(dados)
      const hashBuffer = await crypto.subtle.digest('SHA-256', data)
      const hashArray = Array.from(new Uint8Array(hashBuffer))
      return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    },

    verificarConformidadeLegal() {
      if (!this.dcb) return false
      
      // Verificações conforme documentação "Comprar Bem"
      const verificacoes = {
        numero_dcb: !!this.dcb.numero_dcb,
        data_emissao: !!this.dcb.data_emissao,
        data_validade: !!this.dcb.data_validade,
        produto_identificado: !!(this.dcb.produto_nome && this.dcb.produto_marca),
        dentro_validade: new Date(this.dcb.data_validade) > new Date(),
        status_ativo: this.dcb.status === 'ativo'
      }
      
      return Object.values(verificacoes).every(v => v === true)
    },

    getNumeroReferencia() {
      // Formato conforme documentação: DCB nº XXX/YYYY
      return this.dcb ? `DCB nº ${this.dcb.numero_dcb}` : ''
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

/* Declaração */
.declaracao-oficial {
  background: #f8f9fa;
  padding: 25px;
  border-radius: 8px;
  border-left: 4px solid #3498db;
  margin-bottom: 20px;
}

.declaracao-oficial h4 {
  color: #2c3e50;
  margin: 0 0 15px 0;
}

.declaracao-oficial p {
  line-height: 1.6;
  margin: 0 0 10px 0;
  color: #555;
}

.legislacao-list {
  margin: 15px 0;
  padding-left: 20px;
}

.legislacao-list li {
  margin-bottom: 5px;
  color: #555;
}

.conformidade-status {
  margin-top: 15px;
  padding: 10px;
  background: #fff;
  border-radius: 5px;
  border: 1px solid #ddd;
}

.conforme {
  color: #27ae60;
  font-weight: bold;
}

.nao-conforme {
  color: #e74c3c;
  font-weight: bold;
}

/* Segurança */
.seguranca-section {
  background: #fff3cd;
  padding: 20px;
  border-radius: 8px;
  border-left: 4px solid #ffc107;
  margin-bottom: 20px;
}

.seguranca-section h4 {
  color: #856404;
  margin: 0 0 15px 0;
}

.verificacao-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.verificado {
  color: #27ae60;
  font-weight: bold;
}

.nao-verificado {
  color: #f39c12;
  font-weight: bold;
}

.alerta-seguranca {
  background: #f8d7da;
  color: #721c24;
  padding: 10px;
  border-radius: 5px;
  margin: 10px 0;
  border: 1px solid #f5c6cb;
}

.hash-info {
  margin-top: 10px;
  color: #6c757d;
  font-family: monospace;
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