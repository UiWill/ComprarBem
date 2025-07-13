<template>
  <div class="pesquisa-bot">
    <!-- Cabeçalho -->
    <div class="header">
      <div class="icon">
        <i class="fas fa-search"></i>
      </div>
      <div class="title">
        <h2>PesquisaBot</h2>
        <p>Assistente especializado em pesquisas técnicas de produtos</p>
      </div>
    </div>

    <!-- Formulário de Pesquisa -->
    <div class="search-form">
      <div class="form-group">
        <label for="produto">Produto *</label>
        <input 
          id="produto"
          v-model="formData.produto" 
          type="text" 
          placeholder="Ex: Luvas de procedimento, Máscara N95, etc."
          required
        >
      </div>

      <div class="form-group">
        <label for="marca">Marca *</label>
        <input 
          id="marca"
          v-model="formData.marca" 
          type="text" 
          placeholder="Ex: 3M, Medline, etc."
          required
        >
      </div>

      <div class="form-group">
        <label for="especificacoes">Especificações Técnicas (opcional)</label>
        <textarea 
          id="especificacoes"
          v-model="formData.especificacoes" 
          placeholder="Descreva especificações técnicas específicas que deseja pesquisar..."
          rows="3"
        ></textarea>
      </div>

      <!-- Seleção de Categorias -->
      <div class="form-group">
        <label>Categorias de Busca</label>
        <div class="categories-grid">
          <div 
            v-for="categoria in categorias" 
            :key="categoria.id"
            class="category-item"
          >
            <input 
              :id="categoria.id"
              v-model="categoriasEscolhidas"
              :value="categoria.id"
              type="checkbox"
            >
            <label :for="categoria.id">
              <strong>{{ categoria.nome }}</strong>
              <span>{{ categoria.descricao }}</span>
            </label>
          </div>
        </div>
      </div>

      <!-- Botões de Ação -->
      <div class="action-buttons">
        <button 
          @click="selecionarTodas"
          type="button"
          class="btn-secondary"
        >
          Selecionar Todas
        </button>
        
        <button 
          @click="limparSelecao"
          type="button"
          class="btn-secondary"
        >
          Limpar Seleção
        </button>
        
        <button 
          @click="buscarInformacoes"
          :disabled="!podeRealizar || carregando"
          class="btn-primary"
        >
          <i v-if="carregando" class="fas fa-spinner fa-spin"></i>
          <i v-else class="fas fa-search"></i>
          {{ carregando ? 'Pesquisando...' : 'Pesquisar' }}
        </button>
      </div>
    </div>

    <!-- Status da Pesquisa -->
    <div v-if="carregando" class="loading-status">
      <div class="progress-info">
        <p>{{ statusAtual }}</p>
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: progresso + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Resultados -->
    <div v-if="resultados.length > 0" class="results-section">
      <h3>Resultados da Pesquisa</h3>
      
      <!-- Botão para Relatório Consolidado -->
      <div class="consolidation-section">
        <button 
          @click="gerarRelatorioConsolidado"
          :disabled="gerandoRelatorio"
          class="btn-consolidate"
        >
          <i v-if="gerandoRelatorio" class="fas fa-spinner fa-spin"></i>
          <i v-else class="fas fa-file-alt"></i>
          {{ gerandoRelatorio ? 'Gerando Relatório...' : 'Gerar Relatório Consolidado' }}
        </button>
      </div>

      <!-- Relatório Consolidado -->
      <div v-if="relatorioConsolidado" class="consolidated-report">
        <h4>Relatório Consolidado</h4>
        <div class="report-content" v-html="formatarTexto(relatorioConsolidado.relatorio)"></div>
        <div class="report-meta">
          <small>Gerado em: {{ formatarData(relatorioConsolidado.timestamp) }}</small>
        </div>
      </div>

      <!-- Resultados por Categoria -->
      <div class="results-grid">
        <div 
          v-for="resultado in resultados" 
          :key="resultado.categoria"
          class="result-card"
        >
          <div class="result-header">
            <h4>{{ getCategoriaInfo(resultado.categoria).nome }}</h4>
            <span class="result-timestamp">{{ formatarData(resultado.timestamp) }}</span>
          </div>
          
          <div class="result-content">
            <div v-html="formatarTexto(resultado.resultado)"></div>
          </div>
          
          <div class="result-sources">
            <strong>Fontes consultadas:</strong>
            <ul>
              <li v-for="fonte in getCategoriaInfo(resultado.categoria).fontes" :key="fonte">
                {{ fonte }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <!-- Histórico de Pesquisas -->
    <div v-if="historico.length > 0" class="history-section">
      <h3>Histórico de Pesquisas</h3>
      <div class="history-list">
        <div 
          v-for="(item, index) in historico.slice(0, 5)" 
          :key="index"
          class="history-item"
          @click="carregarPesquisa(item)"
        >
          <div class="history-info">
            <strong>{{ item.produto }} - {{ item.marca }}</strong>
            <span>{{ formatarData(item.timestamp) }}</span>
          </div>
          <div class="history-categories">
            {{ item.categorias.length }} categoria(s) pesquisada(s)
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import pesquisaService from '@/services/pesquisaService';

export default {
  name: 'PesquisaBot',
  data() {
    return {
      formData: {
        produto: '',
        marca: '',
        especificacoes: ''
      },
      categorias: [],
      categoriasEscolhidas: [],
      resultados: [],
      relatorioConsolidado: null,
      historico: [],
      carregando: false,
      gerandoRelatorio: false,
      statusAtual: '',
      progresso: 0
    };
  },
  computed: {
    podeRealizar() {
      return this.formData.produto.trim() && 
             this.formData.marca.trim() && 
             this.categoriasEscolhidas.length > 0;
    }
  },
  mounted() {
    this.carregarCategorias();
    this.carregarHistorico();
  },
  methods: {
    carregarCategorias() {
      this.categorias = pesquisaService.getCategoriasBusca();
      // Selecionar algumas categorias por padrão
      this.categoriasEscolhidas = ['manuais', 'laudos', 'normas'];
    },

    carregarHistorico() {
      const historico = localStorage.getItem('pesquisa-historico');
      if (historico) {
        this.historico = JSON.parse(historico);
      }
    },

    salvarHistorico() {
      localStorage.setItem('pesquisa-historico', JSON.stringify(this.historico));
    },

    selecionarTodas() {
      this.categoriasEscolhidas = this.categorias.map(cat => cat.id);
    },

    limparSelecao() {
      this.categoriasEscolhidas = [];
    },

    async buscarInformacoes() {
      if (!this.podeRealizar) return;

      this.carregando = true;
      this.resultados = [];
      this.relatorioConsolidado = null;
      this.progresso = 0;

      console.log('🔍 Iniciando pesquisa:', {
        produto: this.formData.produto,
        marca: this.formData.marca,
        categorias: this.categoriasEscolhidas
      });

      try {
        const totalCategorias = this.categoriasEscolhidas.length;
        let categoriasProcessadas = 0;

        this.statusAtual = 'Iniciando pesquisa...';
        
        const promisses = this.categoriasEscolhidas.map(async (categoria) => {
          this.statusAtual = `Pesquisando ${this.getCategoriaInfo(categoria).nome}...`;
          
          console.log(`🔍 Pesquisando categoria: ${categoria}`);
          
          const resultado = await pesquisaService.buscarInformacoesTecnicas(
            categoria,
            this.formData.produto,
            this.formData.marca,
            this.formData.especificacoes
          );

          console.log(`📊 Resultado da categoria ${categoria}:`, resultado);

          categoriasProcessadas++;
          this.progresso = (categoriasProcessadas / totalCategorias) * 100;

          return resultado;
        });

        const resultados = await Promise.all(promisses);
        
        console.log('📋 Todos os resultados:', resultados);
        
        this.resultados = resultados.filter(r => r.success);
        
        console.log('✅ Resultados filtrados (success):', this.resultados);

        // Salvar no histórico
        this.historico.unshift({
          produto: this.formData.produto,
          marca: this.formData.marca,
          especificacoes: this.formData.especificacoes,
          categorias: this.categoriasEscolhidas,
          timestamp: new Date().toISOString(),
          resultados: this.resultados.length
        });

        // Manter apenas os últimos 10 itens
        this.historico = this.historico.slice(0, 10);
        this.salvarHistorico();

        this.statusAtual = 'Pesquisa concluída!';
        
        if (this.resultados.length === 0) {
          console.warn('⚠️ Nenhum resultado encontrado');
          this.$swal({
            title: '⚠️ Aviso',
            text: 'Nenhum resultado encontrado. Verifique sua conexão com a internet ou tente novamente.',
            icon: 'warning'
          });
        }
        
      } catch (error) {
        console.error('❌ Erro na pesquisa:', error);
        this.statusAtual = 'Erro na pesquisa. Tente novamente.';
        
        this.$swal({
          title: '❌ Erro',
          text: 'Erro na pesquisa: ' + error.message,
          icon: 'error'
        });
      } finally {
        this.carregando = false;
        setTimeout(() => {
          this.statusAtual = '';
          this.progresso = 0;
        }, 2000);
      }
    },

    async gerarRelatorioConsolidado() {
      if (this.resultados.length === 0) return;

      this.gerandoRelatorio = true;
      
      try {
        const relatorio = await pesquisaService.gerarRelatorioConsolidado(
          this.formData.produto,
          this.formData.marca,
          this.formData.especificacoes
        );

        if (relatorio.success) {
          this.relatorioConsolidado = relatorio;
        }
      } catch (error) {
        console.error('Erro ao gerar relatório:', error);
      } finally {
        this.gerandoRelatorio = false;
      }
    },

    getCategoriaInfo(categoriaId) {
      return this.categorias.find(cat => cat.id === categoriaId) || {};
    },

    formatarTexto(texto) {
      if (!texto) return '';
      
      return texto
        .replace(/\n/g, '<br>')
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\*(.*?)\*/g, '<em>$1</em>')
        .replace(/(\d+\.)/g, '<br><strong>$1</strong>');
    },

    formatarData(timestamp) {
      return new Date(timestamp).toLocaleString('pt-BR');
    },

    carregarPesquisa(item) {
      this.formData.produto = item.produto;
      this.formData.marca = item.marca;
      this.formData.especificacoes = item.especificacoes;
      this.categoriasEscolhidas = [...item.categorias];
    },

    limparFormulario() {
      this.formData = {
        produto: '',
        marca: '',
        especificacoes: ''
      };
      this.categoriasEscolhidas = ['manuais', 'laudos', 'normas'];
      this.resultados = [];
      this.relatorioConsolidado = null;
    }
  }
};
</script>

<style scoped>
.pesquisa-bot {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.header {
  display: flex;
  align-items: center;
  margin-bottom: 30px;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 10px;
  color: white;
}

.header .icon {
  font-size: 2.5rem;
  margin-right: 20px;
}

.header .title h2 {
  margin: 0;
  font-size: 2rem;
}

.header .title p {
  margin: 5px 0 0 0;
  opacity: 0.9;
}

.search-form {
  background: white;
  padding: 30px;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.form-group {
  margin-bottom: 25px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #333;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 12px;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
}

.categories-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 15px;
  margin-top: 10px;
}

.category-item {
  display: flex;
  align-items: flex-start;
  padding: 15px;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  transition: all 0.3s;
}

.category-item:hover {
  border-color: #667eea;
  background-color: #f8f9ff;
}

.category-item input[type="checkbox"] {
  width: auto;
  margin-right: 12px;
  margin-top: 2px;
}

.category-item label {
  flex: 1;
  margin-bottom: 0;
  cursor: pointer;
}

.category-item label strong {
  display: block;
  color: #333;
  margin-bottom: 5px;
}

.category-item label span {
  display: block;
  color: #666;
  font-size: 14px;
}

.action-buttons {
  display: flex;
  gap: 15px;
  justify-content: flex-end;
  margin-top: 30px;
}

.btn-primary,
.btn-secondary,
.btn-consolidate {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  background: #f8f9fa;
  color: #333;
  border: 2px solid #e1e5e9;
}

.btn-secondary:hover {
  background: #e9ecef;
  border-color: #adb5bd;
}

.btn-consolidate {
  background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
  color: white;
  margin-bottom: 20px;
}

.btn-consolidate:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(40, 167, 69, 0.4);
}

.loading-status {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.progress-info p {
  margin: 0 0 10px 0;
  font-weight: 600;
  color: #333;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e1e5e9;
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  transition: width 0.3s;
}

.results-section {
  background: white;
  padding: 30px;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.consolidation-section {
  margin-bottom: 30px;
}

.consolidated-report {
  background: #f8f9ff;
  padding: 25px;
  border-radius: 10px;
  border-left: 4px solid #667eea;
  margin-bottom: 30px;
}

.consolidated-report h4 {
  margin-top: 0;
  color: #333;
}

.report-content {
  line-height: 1.6;
  color: #333;
}

.report-meta {
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #e1e5e9;
}

.results-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
}

.result-card {
  border: 1px solid #e1e5e9;
  border-radius: 10px;
  overflow: hidden;
  transition: transform 0.3s;
}

.result-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
}

.result-header {
  background: #f8f9fa;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e1e5e9;
}

.result-header h4 {
  margin: 0;
  color: #333;
}

.result-timestamp {
  font-size: 12px;
  color: #666;
}

.result-content {
  padding: 20px;
  line-height: 1.6;
  color: #333;
}

.result-sources {
  padding: 15px;
  background: #f8f9fa;
  border-top: 1px solid #e1e5e9;
}

.result-sources ul {
  margin: 5px 0 0 0;
  padding-left: 20px;
}

.result-sources li {
  margin-bottom: 5px;
  color: #666;
}

.history-section {
  background: white;
  padding: 30px;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.history-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.history-item {
  padding: 15px;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.history-item:hover {
  background: #f8f9ff;
  border-color: #667eea;
}

.history-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 5px;
}

.history-info strong {
  color: #333;
}

.history-info span {
  font-size: 12px;
  color: #666;
}

.history-categories {
  font-size: 14px;
  color: #666;
}

@media (max-width: 768px) {
  .categories-grid {
    grid-template-columns: 1fr;
  }
  
  .results-grid {
    grid-template-columns: 1fr;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .history-info {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style> 