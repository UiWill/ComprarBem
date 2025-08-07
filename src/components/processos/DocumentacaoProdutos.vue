<template>
  <div class="documentacao-produtos">
    <div class="header">
      <h3>📋 Documentação dos Produtos Selecionados</h3>
      <button v-if="!carregando" @click="atualizarDocumentacao" class="btn-refresh">
        🔄 Atualizar
      </button>
    </div>

    <div v-if="carregando" class="loading">
      <div class="spinner"></div>
      <p>Carregando documentação dos produtos...</p>
    </div>

    <div v-else-if="documentacao.length === 0" class="empty-state">
      <div class="empty-icon">📦</div>
      <h4>Nenhum produto selecionado</h4>
      <p>Adicione produtos ao processo para visualizar sua documentação técnica.</p>
    </div>

    <div v-else class="produtos-documentacao">
      <div v-for="produto in documentacao" :key="produto.produto_id" class="produto-card">
        
        <!-- Cabeçalho do produto -->
        <div class="produto-header" @click="toggleExpansao(produto.produto_id)">
          <div class="produto-info">
            <h4>{{ produto.nome_produto }}</h4>
            <p>{{ produto.marca }} - {{ produto.modelo }} | {{ produto.fabricante }}</p>
          </div>
          <div class="status-docs">
            <span class="docs-count">{{ produto.checklist_documentacao.length }} docs</span>
            <span class="toggle-icon" :class="{ expanded: produtosExpandidos[produto.produto_id] }">
              ▼
            </span>
          </div>
        </div>

        <!-- Conteúdo expandível -->
        <div v-if="produtosExpandidos[produto.produto_id]" class="produto-content">
          
          <!-- Documentação técnica obrigatória -->
          <div class="secao-documentacao">
            <h5>🔒 Documentação Técnica Obrigatória</h5>
            <div class="docs-grid">
              
              <div v-if="produto.documentacao_tecnica.numero_anvisa" class="doc-item valido">
                <div class="doc-icon">🏥</div>
                <div class="doc-info">
                  <strong>Registro ANVISA/MS</strong>
                  <span>{{ produto.documentacao_tecnica.numero_anvisa }}</span>
                </div>
                <div class="doc-status">✅</div>
              </div>

              <div v-if="produto.documentacao_tecnica.certificado_inmetro" class="doc-item valido">
                <div class="doc-icon">⚖️</div>
                <div class="doc-info">
                  <strong>Certificação INMETRO</strong>
                  <span>{{ produto.documentacao_tecnica.certificado_inmetro }}</span>
                </div>
                <div class="doc-status">✅</div>
              </div>

              <div v-if="produto.documentacao_tecnica.cbpf" class="doc-item valido">
                <div class="doc-icon">🏭</div>
                <div class="doc-info">
                  <strong>CBPF</strong>
                  <span>{{ produto.documentacao_tecnica.cbpf }}</span>
                </div>
                <div class="doc-status">✅</div>
              </div>

              <div v-if="produto.documentacao_tecnica.norma_abnt" class="doc-item valido">
                <div class="doc-icon">📏</div>
                <div class="doc-info">
                  <strong>Norma ABNT</strong>
                  <span>{{ produto.documentacao_tecnica.norma_abnt }}</span>
                </div>
                <div class="doc-status">✅</div>
              </div>

              <div v-if="produto.documentacao_tecnica.norma_regulamentadora" class="doc-item valido">
                <div class="doc-icon">📋</div>
                <div class="doc-info">
                  <strong>Norma Regulamentadora</strong>
                  <span>{{ produto.documentacao_tecnica.norma_regulamentadora }}</span>
                </div>
                <div class="doc-status">✅</div>
              </div>

              <div v-if="produto.documentacao_tecnica.codigo_material" class="doc-item valido">
                <div class="doc-icon">🔢</div>
                <div class="doc-info">
                  <strong>Código do Material</strong>
                  <span>{{ produto.documentacao_tecnica.codigo_material }}</span>
                </div>
                <div class="doc-status">✅</div>
              </div>

            </div>
          </div>

          <!-- Especificação técnica -->
          <div v-if="produto.documentacao_tecnica.especificacao_detalhada" class="secao-documentacao">
            <h5>📝 Especificação Técnica Detalhada</h5>
            <div class="especificacao">
              <p>{{ produto.documentacao_tecnica.especificacao_detalhada }}</p>
            </div>
          </div>

          <!-- Arquivos anexados -->
          <div v-if="produto.documentos_anexados.length > 0" class="secao-documentacao">
            <h5>📎 Documentos PDF Anexados</h5>
            <div class="documentos-lista">
              <div v-for="doc in produto.documentos_anexados" :key="doc.id" class="documento-anexo">
                <div class="doc-icon">📄</div>
                <div class="doc-info">
                  <strong>{{ doc.nome_arquivo }}</strong>
                  <small>{{ formatarTamanhoArquivo(doc.tamanho) }} - {{ formatarData(doc.data_upload) }}</small>
                </div>
                <div class="doc-actions">
                  <button @click="abrirDocumento(doc.url_arquivo)" class="btn-view" title="Visualizar documento">
                    👁️
                  </button>
                  <button @click="baixarDocumento(doc.url_arquivo, doc.nome_arquivo)" class="btn-download" title="Baixar documento">
                    ⬇️
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Checklist de documentação -->
          <div class="secao-documentacao">
            <h5>✅ Checklist de Documentação - Anexo III</h5>
            <div class="checklist">
              <div v-for="(item, index) in produto.checklist_documentacao" :key="index" 
                   class="checklist-item" :class="{ obrigatorio: item.obrigatório, presente: item.presente }">
                <div class="check-icon">
                  {{ item.presente ? '✅' : (item.obrigatório ? '❌' : '⏸️') }}
                </div>
                <div class="check-info">
                  <strong>{{ item.documento }}</strong>
                  <span v-if="item.valor" class="doc-valor">{{ item.valor }}</span>
                  <small v-if="item.observacao" class="doc-obs">{{ item.observacao }}</small>
                  <span v-if="item.obrigatório" class="obrigatorio-badge">OBRIGATÓRIO</span>
                </div>
                <div class="check-status">
                  <span v-if="item.presente" class="status-ok">Presente</span>
                  <span v-else-if="item.obrigatório" class="status-faltando">Faltando</span>
                  <span v-else class="status-opcional">Opcional</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Resumo da conformidade -->
          <div class="resumo-conformidade">
            <div class="conformidade-stats">
              <div class="stat-item">
                <span class="stat-number">{{ contarDocumentosPresentes(produto.checklist_documentacao) }}</span>
                <span class="stat-label">Documentos Presentes</span>
              </div>
              <div class="stat-item">
                <span class="stat-number">{{ contarDocumentosObrigatorios(produto.checklist_documentacao) }}</span>
                <span class="stat-label">Obrigatórios</span>
              </div>
              <div class="stat-item">
                <span class="stat-number">{{ produto.documentos_anexados.length }}</span>
                <span class="stat-label">PDFs Anexados</span>
              </div>
            </div>
            
            <div class="status-geral">
              <div v-if="verificarConformidadeTotal(produto.checklist_documentacao)" class="status-conforme">
                ✅ Documentação Conforme
              </div>
              <div v-else class="status-nao-conforme">
                ⚠️ Documentação Incompleta - {{ contarDocumentosFaltando(produto.checklist_documentacao) }} obrigatório(s) faltando
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>

    <!-- Resumo geral -->
    <div v-if="documentacao.length > 0" class="resumo-geral">
      <h4>📊 Resumo Geral da Documentação</h4>
      <div class="resumo-stats">
        <div class="stat-card">
          <div class="stat-value">{{ documentacao.length }}</div>
          <div class="stat-label">Produtos Selecionados</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ contarProdutosConformes() }}</div>
          <div class="stat-label">Com Doc. Completa</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ contarTotalDocumentosPDF() }}</div>
          <div class="stat-label">PDFs Anexados</div>
        </div>
        <div class="stat-card" :class="{ 'stat-warning': contarProdutosNaoConformes() > 0 }">
          <div class="stat-value">{{ contarProdutosNaoConformes() }}</div>
          <div class="stat-label">Com Doc. Incompleta</div>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import { ProcessosAdministrativosService } from '@/services/ProcessosAdministrativosService'

export default {
  name: 'DocumentacaoProdutos',
  props: {
    processoId: {
      type: String,
      required: true
    }
  },
  
  data() {
    return {
      documentacao: [],
      carregando: false,
      produtosExpandidos: {}
    }
  },
  
  mounted() {
    this.carregarDocumentacao()
  },
  
  methods: {
    async carregarDocumentacao() {
      try {
        this.carregando = true
        this.documentacao = await ProcessosAdministrativosService.obterDocumentacaoProdutos(this.processoId)
        
        // Expandir o primeiro produto por padrão
        if (this.documentacao.length > 0) {
          this.$set(this.produtosExpandidos, this.documentacao[0].produto_id, true)
        }
        
      } catch (error) {
        console.error('Erro ao carregar documentação:', error)
        this.$swal?.fire({
          title: 'Erro',
          text: 'Erro ao carregar documentação dos produtos',
          icon: 'error'
        })
      } finally {
        this.carregando = false
      }
    },
    
    async atualizarDocumentacao() {
      await this.carregarDocumentacao()
    },
    
    toggleExpansao(produtoId) {
      this.$set(this.produtosExpandidos, produtoId, !this.produtosExpandidos[produtoId])
    },
    
    formatarTamanhoArquivo(bytes) {
      if (!bytes) return '0 Bytes'
      const k = 1024
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    },
    
    formatarData(data) {
      if (!data) return 'Data não disponível'
      return new Date(data).toLocaleDateString('pt-BR')
    },
    
    abrirDocumento(url) {
      if (url) {
        window.open(url, '_blank')
      }
    },
    
    baixarDocumento(url, nome) {
      if (url) {
        const link = document.createElement('a')
        link.href = url
        link.download = nome || 'documento.pdf'
        link.click()
      }
    },
    
    contarDocumentosPresentes(checklist) {
      return checklist.filter(item => item.presente).length
    },
    
    contarDocumentosObrigatorios(checklist) {
      return checklist.filter(item => item.obrigatório).length
    },
    
    contarDocumentosFaltando(checklist) {
      return checklist.filter(item => item.obrigatório && !item.presente).length
    },
    
    verificarConformidadeTotal(checklist) {
      const obrigatorios = checklist.filter(item => item.obrigatório)
      return obrigatorios.every(item => item.presente)
    },
    
    contarProdutosConformes() {
      return this.documentacao.filter(produto => 
        this.verificarConformidadeTotal(produto.checklist_documentacao)
      ).length
    },
    
    contarProdutosNaoConformes() {
      return this.documentacao.filter(produto => 
        !this.verificarConformidadeTotal(produto.checklist_documentacao)
      ).length
    },
    
    contarTotalDocumentosPDF() {
      return this.documentacao.reduce((total, produto) => 
        total + produto.documentos_anexados.length, 0
      )
    }
  }
}
</script>

<style scoped>
.documentacao-produtos {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.header h3 {
  margin: 0;
  color: #2d3748;
  font-size: 1.2rem;
}

.btn-refresh {
  background: #e2e8f0;
  border: 1px solid #cbd5e0;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
  transition: all 0.2s ease;
}

.btn-refresh:hover {
  background: #cbd5e0;
}

.loading {
  text-align: center;
  padding: 2rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #e2e8f0;
  border-top: 3px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 3rem;
  color: #718096;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.produtos-documentacao {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.produto-card {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.produto-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f7fafc;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.produto-header:hover {
  background: #edf2f7;
}

.produto-info h4 {
  margin: 0 0 0.25rem;
  color: #2d3748;
  font-size: 1rem;
}

.produto-info p {
  margin: 0;
  color: #718096;
  font-size: 0.9rem;
}

.status-docs {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.docs-count {
  background: #667eea;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.toggle-icon {
  transition: transform 0.2s ease;
  color: #4a5568;
}

.toggle-icon.expanded {
  transform: rotate(180deg);
}

.produto-content {
  padding: 1.5rem;
}

.secao-documentacao {
  margin-bottom: 2rem;
}

.secao-documentacao h5 {
  margin: 0 0 1rem;
  color: #4a5568;
  font-size: 1rem;
  border-bottom: 2px solid #e2e8f0;
  padding-bottom: 0.5rem;
}

.docs-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 0.75rem;
}

.doc-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.doc-item.valido {
  border-color: #68d391;
  background: rgba(104, 211, 145, 0.05);
}

.doc-icon {
  font-size: 1.2rem;
}

.doc-info {
  flex: 1;
}

.doc-info strong {
  display: block;
  color: #2d3748;
  font-size: 0.9rem;
}

.doc-info span {
  color: #718096;
  font-size: 0.8rem;
}

.doc-status {
  font-size: 1.2rem;
}

.especificacao {
  background: #f7fafc;
  padding: 1rem;
  border-radius: 6px;
  border-left: 4px solid #667eea;
}

.especificacao p {
  margin: 0;
  color: #4a5568;
  line-height: 1.6;
}

.documentos-lista {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.documento-anexo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  background: #f7fafc;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.doc-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-view,
.btn-download {
  background: none;
  border: 1px solid #e2e8f0;
  padding: 0.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.2s ease;
}

.btn-view:hover {
  background: #e2e8f0;
}

.btn-download:hover {
  background: #e2e8f0;
}

.checklist {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.checklist-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.checklist-item.presente {
  border-color: #68d391;
  background: rgba(104, 211, 145, 0.05);
}

.checklist-item.obrigatorio:not(.presente) {
  border-color: #fc8181;
  background: rgba(252, 129, 129, 0.05);
}

.check-icon {
  font-size: 1.2rem;
}

.check-info {
  flex: 1;
}

.check-info strong {
  display: block;
  color: #2d3748;
  font-size: 0.9rem;
}

.doc-valor {
  display: block;
  color: #4a5568;
  font-size: 0.8rem;
  margin-top: 0.25rem;
}

.doc-obs {
  display: block;
  color: #718096;
  font-size: 0.75rem;
  margin-top: 0.25rem;
  font-style: italic;
}

.obrigatorio-badge {
  display: inline-block;
  background: #fbd38d;
  color: #744210;
  padding: 0.15rem 0.5rem;
  border-radius: 10px;
  font-size: 0.7rem;
  font-weight: 500;
  margin-top: 0.25rem;
}

.check-status {
  font-size: 0.8rem;
  font-weight: 500;
}

.status-ok {
  color: #38a169;
}

.status-faltando {
  color: #e53e3e;
}

.status-opcional {
  color: #718096;
}

.resumo-conformidade {
  background: #f0fff4;
  padding: 1rem;
  border-radius: 6px;
  border: 1px solid #c6f6d5;
  margin-top: 1rem;
}

.conformidade-stats {
  display: flex;
  justify-content: space-around;
  margin-bottom: 1rem;
}

.stat-item {
  text-align: center;
}

.stat-number {
  display: block;
  font-size: 1.5rem;
  font-weight: bold;
  color: #2d3748;
}

.stat-label {
  font-size: 0.8rem;
  color: #718096;
}

.status-geral {
  text-align: center;
  font-weight: 500;
}

.status-conforme {
  color: #38a169;
  padding: 0.5rem;
  background: rgba(56, 161, 105, 0.1);
  border-radius: 6px;
}

.status-nao-conforme {
  color: #e53e3e;
  padding: 0.5rem;
  background: rgba(229, 62, 62, 0.1);
  border-radius: 6px;
}

.resumo-geral {
  margin-top: 2rem;
  padding: 1.5rem;
  background: #f7fafc;
  border-radius: 8px;
}

.resumo-geral h4 {
  margin: 0 0 1rem;
  color: #2d3748;
  text-align: center;
}

.resumo-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
}

.stat-card {
  background: white;
  padding: 1rem;
  border-radius: 6px;
  text-align: center;
  border: 1px solid #e2e8f0;
}

.stat-card.stat-warning {
  border-color: #fc8181;
  background: rgba(252, 129, 129, 0.05);
}

.stat-value {
  display: block;
  font-size: 2rem;
  font-weight: bold;
  color: #2d3748;
}

.stat-card.stat-warning .stat-value {
  color: #e53e3e;
}
</style>