<template>
  <div class="processos-container">
    <div class="page-header">
      <h2>📚 Biblioteca de Documentos</h2>
      <p>Manuais, templates e instruções para processos administrativos</p>
    </div>

    <div class="content-wrapper">
      <aside class="sidebar">
        <div class="filter-section">
          <h3>Filtros</h3>
          
          <div class="filter-group">
            <label>Categoria</label>
            <select v-model="filtroCategoria" @change="filtrarDocumentos">
              <option value="">Todas as categorias</option>
              <option value="manual">Manuais</option>
              <option value="template">Templates</option>
              <option value="instrucao">Instruções</option>
              <option value="normativa">Normativas</option>
              <option value="formulario">Formulários</option>
            </select>
          </div>

          <div class="filter-group">
            <label>Buscar</label>
            <input 
              type="text" 
              v-model="termoBusca" 
              @input="filtrarDocumentos"
              placeholder="Digite para buscar..."
              class="search-input"
            >
          </div>
        </div>

        <div class="upload-section" v-if="podeUpload">
          <h3>Adicionar Documento</h3>
          <button @click="abrirModalUpload" class="btn-upload">
            📄 Novo Documento
          </button>
        </div>
      </aside>

      <section class="documents-section">
        <div class="documents-header">
          <h3>Documentos ({{ documentosFiltrados.length }})</h3>
          <div class="view-options">
            <button @click="visualizacao = 'grid'" :class="{ active: visualizacao === 'grid' }">
              ⊞ Grade
            </button>
            <button @click="visualizacao = 'list'" :class="{ active: visualizacao === 'list' }">
              ☰ Lista
            </button>
          </div>
        </div>

        <div v-if="carregando" class="loading">
          <div class="spinner"></div>
          <p>Carregando documentos...</p>
        </div>

        <div v-else-if="documentosFiltrados.length === 0" class="empty-state">
          <div class="empty-icon">📂</div>
          <h4>Nenhum documento encontrado</h4>
          <p>Tente ajustar os filtros ou adicione novos documentos</p>
        </div>

        <div v-else class="documents-container" :class="visualizacao">
          <div 
            v-for="documento in documentosFiltrados" 
            :key="documento.id"
            @click="visualizarDocumento(documento)"
            class="document-card"
          >
            <div class="document-icon">
              {{ getIconeCategoria(documento.categoria) }}
            </div>
            <div class="document-info">
              <h4>{{ documento.titulo }}</h4>
              <p class="document-desc">{{ documento.descricao }}</p>
              <div class="document-meta">
                <span class="categoria">{{ getNomeCategoria(documento.categoria) }}</span>
                <span class="data">{{ formatarData(documento.criado_em) }}</span>
              </div>
            </div>
            <div class="document-actions">
              <button @click.stop="baixarDocumento(documento)" class="btn-action">
                ⬇️
              </button>
              <button v-if="podeEditar" @click.stop="editarDocumento(documento)" class="btn-action">
                ✏️
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>

    <!-- Modal de Upload -->
    <div v-if="modalUploadAberto" class="modal-overlay" @click="fecharModalUpload">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>Adicionar Documento</h3>
          <button @click="fecharModalUpload" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="uploadDocumento">
            <div class="form-group">
              <label>Título *</label>
              <input type="text" v-model="novoDocumento.titulo" required>
            </div>
            
            <div class="form-group">
              <label>Descrição</label>
              <textarea v-model="novoDocumento.descricao" rows="3"></textarea>
            </div>
            
            <div class="form-group">
              <label>Categoria *</label>
              <select v-model="novoDocumento.categoria" required>
                <option value="">Selecione uma categoria</option>
                <option value="manual">Manual</option>
                <option value="template">Template</option>
                <option value="instrucao">Instrução</option>
                <option value="normativa">Normativa</option>
                <option value="formulario">Formulário</option>
              </select>
            </div>
            
            <div class="form-group">
              <label>Arquivo *</label>
              <input 
                type="file" 
                @change="selecionarArquivo" 
                accept=".pdf,.doc,.docx,.xlsx,.xls"
                required
              >
              <small>Formatos aceitos: PDF, DOC, DOCX, XLS, XLSX</small>
            </div>
            
            <div class="form-actions">
              <button type="button" @click="fecharModalUpload" class="btn-secondary">
                Cancelar
              </button>
              <button type="submit" :disabled="enviandoUpload" class="btn-primary">
                {{ enviandoUpload ? 'Enviando...' : 'Salvar' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Modal de Visualização -->
    <div v-if="documentoSelecionado" class="modal-overlay" @click="fecharVisualizacao">
      <div class="modal modal-large" @click.stop>
        <div class="modal-header">
          <h3>{{ documentoSelecionado.titulo }}</h3>
          <button @click="fecharVisualizacao" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <div class="document-details">
            <p><strong>Descrição:</strong> {{ documentoSelecionado.descricao }}</p>
            <p><strong>Categoria:</strong> {{ getNomeCategoria(documentoSelecionado.categoria) }}</p>
            <p><strong>Data:</strong> {{ formatarData(documentoSelecionado.criado_em) }}</p>
          </div>
          
          <div class="document-actions-modal">
            <button @click="baixarDocumento(documentoSelecionado)" class="btn-primary">
              ⬇️ Baixar Documento
            </button>
            <button v-if="podeEditar" @click="editarDocumento(documentoSelecionado)" class="btn-secondary">
              ✏️ Editar
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import DocumentosAdministrativosService from '../../services/documentosAdministrativos'

export default {
  name: 'ProcessosAdministrativosComponent',
  data() {
    return {
      documentos: [],
      documentosFiltrados: [],
      carregando: true,
      
      filtroCategoria: '',
      termoBusca: '',
      visualizacao: 'grid',
      
      modalUploadAberto: false,
      enviandoUpload: false,
      documentoSelecionado: null,
      
      novoDocumento: {
        titulo: '',
        descricao: '',
        categoria: '',
        arquivo: null
      },
      
      podeUpload: true,
      podeEditar: true
    }
  },
  
  async mounted() {
    await this.carregarDocumentos()
  },
  
  methods: {
    async carregarDocumentos() {
      try {
        this.carregando = true
        this.documentos = await DocumentosAdministrativosService.listarDocumentos()
        this.filtrarDocumentos()
      } catch (error) {
        console.error('Erro ao carregar documentos:', error)
        this.documentos = []
        alert('Erro ao carregar documentos. Tente novamente.')
      } finally {
        this.carregando = false
      }
    },
    
    async filtrarDocumentos() {
      try {
        const filtros = {}
        if (this.filtroCategoria) {
          filtros.categoria = this.filtroCategoria
        }
        if (this.termoBusca) {
          filtros.busca = this.termoBusca
        }
        
        this.documentosFiltrados = await DocumentosAdministrativosService.buscarDocumentos(
          this.termoBusca, 
          filtros
        )
      } catch (error) {
        console.error('Erro ao filtrar documentos:', error)
        // Fallback para filtro local
        let filtrados = [...this.documentos]
        
        if (this.filtroCategoria) {
          filtrados = filtrados.filter(doc => doc.categoria === this.filtroCategoria)
        }
        
        if (this.termoBusca) {
          const termo = this.termoBusca.toLowerCase()
          filtrados = filtrados.filter(doc => 
            doc.titulo.toLowerCase().includes(termo) ||
            (doc.descricao && doc.descricao.toLowerCase().includes(termo))
          )
        }
        
        this.documentosFiltrados = filtrados
      }
    },
    
    getIconeCategoria(categoria) {
      return DocumentosAdministrativosService.obterIconeCategoria(categoria)
    },
    
    getNomeCategoria(categoria) {
      return DocumentosAdministrativosService.obterNomeCategoria(categoria)
    },
    
    formatarData(data) {
      return new Date(data).toLocaleDateString('pt-BR')
    },
    
    abrirModalUpload() {
      this.modalUploadAberto = true
      this.novoDocumento = {
        titulo: '',
        descricao: '',
        categoria: '',
        arquivo: null
      }
    },
    
    fecharModalUpload() {
      this.modalUploadAberto = false
    },
    
    selecionarArquivo(event) {
      const arquivo = event.target.files[0]
      if (arquivo) {
        try {
          DocumentosAdministrativosService.validarArquivo(arquivo)
          this.novoDocumento.arquivo = arquivo
        } catch (error) {
          alert(error.message)
          event.target.value = ''
        }
      }
    },
    
    async uploadDocumento() {
      if (!this.novoDocumento.arquivo) {
        alert('Selecione um arquivo para fazer upload')
        return
      }
      
      try {
        this.enviandoUpload = true
        
        // Validar arquivo
        DocumentosAdministrativosService.validarArquivo(this.novoDocumento.arquivo)
        
        // Upload do arquivo
        const resultadoUpload = await DocumentosAdministrativosService.uploadArquivo(
          this.novoDocumento.arquivo
        )
        
        // Criar documento com metadados
        await DocumentosAdministrativosService.criarDocumento({
          titulo: this.novoDocumento.titulo,
          descricao: this.novoDocumento.descricao,
          categoria: this.novoDocumento.categoria,
          nome_arquivo: resultadoUpload.nome_original,
          tamanho_arquivo: resultadoUpload.tamanho,
          tipo_mime: resultadoUpload.tipo_mime,
          url_arquivo: resultadoUpload.url
        })
        
        await this.carregarDocumentos()
        this.fecharModalUpload()
        alert('Documento enviado com sucesso!')
        
      } catch (error) {
        console.error('Erro no upload:', error)
        alert(`Erro ao fazer upload: ${error.message}`)
      } finally {
        this.enviandoUpload = false
      }
    },
    
    visualizarDocumento(documento) {
      this.documentoSelecionado = documento
    },
    
    fecharVisualizacao() {
      this.documentoSelecionado = null
    },
    
    async baixarDocumento(documento) {
      try {
        if (!documento.url_arquivo) {
          alert('URL do arquivo não disponível')
          return
        }
        
        const blob = await DocumentosAdministrativosService.baixarArquivo(documento.url_arquivo)
        
        // Criar link temporário para download
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.style.display = 'none'
        a.href = url
        a.download = documento.nome_arquivo || 'documento'
        document.body.appendChild(a)
        a.click()
        window.URL.revokeObjectURL(url)
        document.body.removeChild(a)
        
      } catch (error) {
        console.error('Erro no download:', error)
        alert(`Erro ao baixar arquivo: ${error.message}`)
      }
    },
    
    async editarDocumento(documento) {
      // Por enquanto, permitir apenas edição de título e descrição
      const novoTitulo = prompt('Novo título:', documento.titulo)
      if (novoTitulo && novoTitulo !== documento.titulo) {
        try {
          await DocumentosAdministrativosService.atualizarDocumento(documento.id, {
            titulo: novoTitulo
          })
          await this.carregarDocumentos()
          alert('Documento atualizado com sucesso!')
        } catch (error) {
          console.error('Erro ao editar:', error)
          alert(`Erro ao editar documento: ${error.message}`)
        }
      }
    }
  }
}
</script>

<style scoped>
.processos-container {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 2rem;
  color: #2c3e50;
}

.page-header h2 {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
  font-weight: 700;
}

.page-header p {
  font-size: 1.1rem;
  color: #718096;
}

.content-wrapper {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 2rem;
  align-items: start;
}

.sidebar {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.filter-section h3,
.upload-section h3 {
  margin-bottom: 1rem;
  color: #2d3748;
  font-size: 1.1rem;
}

.filter-group {
  margin-bottom: 1rem;
}

.filter-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #4a5568;
}

.filter-group select,
.search-input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
}

.upload-section {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.btn-upload {
  width: 100%;
  padding: 0.75rem;
  background: #2c3e50;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.btn-upload:hover {
  background: #34495e;
}

.documents-section {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.documents-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.documents-header h3 {
  color: #2d3748;
  margin: 0;
}

.view-options {
  display: flex;
  gap: 0.5rem;
}

.view-options button {
  padding: 0.5rem 1rem;
  border: 1px solid #e2e8f0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
  transition: all 0.3s ease;
}

.view-options button.active {
  background: #2c3e50;
  color: white;
  border-color: #2c3e50;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: #718096;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e2e8f0;
  border-top: 4px solid #2c3e50;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 3rem;
  color: #718096;
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.documents-container.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

.documents-container.list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.document-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.document-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.document-icon {
  font-size: 2rem;
  flex-shrink: 0;
}

.document-info {
  flex: 1;
}

.document-info h4 {
  margin: 0 0 0.5rem;
  color: #2d3748;
  font-size: 1rem;
}

.document-desc {
  margin: 0 0 0.75rem;
  color: #718096;
  font-size: 0.9rem;
  line-height: 1.4;
}

.document-meta {
  display: flex;
  gap: 1rem;
  font-size: 0.8rem;
}

.categoria {
  background: #e2e8f0;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  color: #4a5568;
}

.data {
  color: #a0aec0;
}

.document-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.btn-action {
  width: 2rem;
  height: 2rem;
  border: none;
  background: #f7fafc;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.btn-action:hover {
  background: #e2e8f0;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow: auto;
}

.modal-large {
  max-width: 800px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e2e8f0;
}

.modal-header h3 {
  margin: 0;
  color: #2d3748;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #a0aec0;
}

.modal-body {
  padding: 1.5rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #4a5568;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
}

.form-group small {
  display: block;
  margin-top: 0.25rem;
  color: #718096;
  font-size: 0.8rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1.5rem;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.btn-primary {
  background: #2c3e50;
  color: white;
}

.btn-primary:hover {
  background: #34495e;
}

.btn-primary:disabled {
  background: #a0aec0;
  cursor: not-allowed;
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover {
  background: #cbd5e0;
}

.document-details {
  margin-bottom: 1.5rem;
}

.document-details p {
  margin-bottom: 0.75rem;
  line-height: 1.5;
}

.document-actions-modal {
  display: flex;
  gap: 1rem;
}

@media (max-width: 768px) {
  .content-wrapper {
    grid-template-columns: 1fr;
  }
  
  .documents-container.grid {
    grid-template-columns: 1fr;
  }
}
</style>