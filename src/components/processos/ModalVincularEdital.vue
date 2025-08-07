<template>
  <div v-if="visivel" class="modal-overlay" @click="fechar">
    <div class="modal" @click.stop>
      <div class="modal-header">
        <h3>📄 Vincular Edital de Pré-Qualificação</h3>
        <button @click="fechar" class="btn-close">&times;</button>
      </div>
      
      <div class="modal-body">
        <div class="processo-info">
          <h4>{{ processo.numero_processo || 'Processo em criação' }}</h4>
          <p>{{ processo.tipo_processo === 'padronizacao' ? '✅ Padronização' : '❌ Despadronização' }}</p>
        </div>

        <form @submit.prevent="vincularEdital">
          <div class="form-group">
            <label>Número do Edital *</label>
            <input 
              type="text" 
              v-model="numeroEdital" 
              placeholder="001/2024"
              pattern="^\d{1,3}/\d{4}$"
              title="Formato: XXX/YYYY (ex: 001/2024)"
              required
              :class="{ 'error': erroValidacao }"
            >
            <small v-if="erroValidacao" class="error-msg">{{ erroValidacao }}</small>
            <small v-else class="help-text">Formato: 001/2024</small>
          </div>

          <div class="form-group">
            <label>Ano do Edital *</label>
            <input 
              type="number" 
              v-model="anoEdital" 
              :min="2020" 
              :max="2030"
              required
            >
          </div>

          <div class="form-group">
            <label>Data de Publicação</label>
            <input 
              type="date" 
              v-model="dataPublicacao"
            >
            <small class="help-text">Data em que o edital foi publicado no diário oficial (opcional)</small>
          </div>

          <div class="form-group">
            <label>Arquivo do Edital (PDF) *</label>
            <div class="file-upload-area" 
                 :class="{ 'dragover': dragover, 'has-file': arquivoSelecionado }"
                 @dragover.prevent="dragover = true"
                 @dragleave="dragover = false"
                 @drop.prevent="onFileDrop">
              <input 
                type="file" 
                ref="fileInput"
                @change="onFileSelect" 
                accept=".pdf"
                required
                style="display: none;"
              >
              
              <div v-if="!arquivoSelecionado" class="upload-placeholder">
                <div class="upload-icon">📄</div>
                <p>Arraste o arquivo PDF aqui ou <button type="button" @click="$refs.fileInput.click()" class="btn-link">clique para selecionar</button></p>
                <small>Apenas arquivos PDF são aceitos</small>
              </div>
              
              <div v-if="arquivoSelecionado" class="selected-file">
                <div class="file-icon">📄</div>
                <div class="file-info">
                  <strong>{{ arquivoSelecionado.name }}</strong>
                  <small>{{ formatarTamanhoArquivo(arquivoSelecionado.size) }}</small>
                </div>
                <button type="button" @click="removerArquivo" class="btn-remove">🗑️</button>
              </div>
            </div>
          </div>

          <div class="form-group">
            <label>Objeto do Edital</label>
            <textarea 
              v-model="objeto" 
              rows="3"
              placeholder="Descrição do objeto do edital (opcional - será preenchido automaticamente se não informado)"
            ></textarea>
          </div>

          <div class="form-group">
            <label>Observações</label>
            <textarea 
              v-model="observacoes" 
              rows="2"
              placeholder="Observações sobre o edital (opcional)"
            ></textarea>
          </div>

          <div v-if="processo.produtos && processo.produtos.length > 0" class="produtos-relacionados">
            <h4>📦 Produtos que serão incluídos no edital:</h4>
            <div class="produtos-lista">
              <div v-for="produto in processo.produtos" :key="produto.id" class="produto-item">
                <span class="produto-nome">{{ produto.nome_produto }}</span>
                <span class="produto-marca">{{ produto.marca }}</span>
              </div>
            </div>
          </div>

          <div class="form-actions">
            <button type="button" @click="fechar" class="btn-secondary">
              Cancelar
            </button>
            <button 
              type="submit" 
              class="btn-primary" 
              :disabled="salvando || !!erroValidacao || !arquivoSelecionado"
            >
              {{ salvando ? 'Vinculando...' : 'Vincular Edital' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { ProcessosAdministrativosService } from '@/services/ProcessosAdministrativosService'

export default {
  name: 'ModalVincularEdital',
  props: {
    visivel: {
      type: Boolean,
      default: false
    },
    processo: {
      type: Object,
      required: true
    }
  },
  
  data() {
    return {
      numeroEdital: '',
      anoEdital: new Date().getFullYear(),
      dataPublicacao: '',
      objeto: '',
      observacoes: '',
      arquivoSelecionado: null,
      dragover: false,
      salvando: false,
      erroValidacao: ''
    }
  },
  
  watch: {
    visivel(novoValor) {
      if (novoValor) {
        this.inicializar()
      }
    },
    
    numeroEdital() {
      this.validarNumero()
    }
  },
  
  methods: {
    inicializar() {
      // Resetar campos
      this.numeroEdital = ''
      this.anoEdital = new Date().getFullYear()
      this.dataPublicacao = ''
      this.objeto = ''
      this.observacoes = ''
      this.arquivoSelecionado = null
      this.erroValidacao = ''
      
      // Se já tem edital vinculado, preencher campos
      if (this.processo.edital_vinculado) {
        this.numeroEdital = this.processo.numero_edital || ''
        this.anoEdital = this.processo.ano_edital || new Date().getFullYear()
      }
    },
    
    validarNumero() {
      this.erroValidacao = ''
      
      if (!this.numeroEdital) return
      
      // Validar formato XXX/YYYY
      const regex = /^\d{1,3}\/\d{4}$/
      if (!regex.test(this.numeroEdital)) {
        this.erroValidacao = 'Formato inválido. Use XXX/YYYY (ex: 001/2024)'
        return
      }
      
      // Extrair e validar ano
      const partes = this.numeroEdital.split('/')
      const ano = parseInt(partes[1], 10)
      if (ano !== this.anoEdital) {
        this.anoEdital = ano
      }
    },
    
    onFileSelect(event) {
      const arquivo = event.target.files[0]
      this.processarArquivo(arquivo)
    },
    
    onFileDrop(event) {
      this.dragover = false
      const arquivo = event.dataTransfer.files[0]
      this.processarArquivo(arquivo)
    },
    
    processarArquivo(arquivo) {
      if (!arquivo) return
      
      // Validar tipo
      if (arquivo.type !== 'application/pdf') {
        this.$swal?.fire({
          title: 'Arquivo Inválido',
          text: 'Apenas arquivos PDF são aceitos.',
          icon: 'error'
        })
        return
      }
      
      // Validar tamanho (máx. 50MB)
      if (arquivo.size > 50 * 1024 * 1024) {
        this.$swal?.fire({
          title: 'Arquivo muito grande',
          text: 'O arquivo deve ter no máximo 50MB.',
          icon: 'error'
        })
        return
      }
      
      this.arquivoSelecionado = arquivo
    },
    
    removerArquivo() {
      this.arquivoSelecionado = null
      if (this.$refs.fileInput) {
        this.$refs.fileInput.value = ''
      }
    },
    
    formatarTamanhoArquivo(bytes) {
      if (bytes === 0) return '0 Bytes'
      const k = 1024
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    },
    
    async vincularEdital() {
      if (this.salvando) return
      
      try {
        this.salvando = true
        
        // Preparar dados
        const dadosEdital = {
          numero_edital: this.numeroEdital,
          ano_edital: this.anoEdital,
          data_publicacao: this.dataPublicacao || null,
          objeto: this.objeto || this.gerarObjetoAutomatico(),
          observacoes: this.observacoes,
          arquivo: this.arquivoSelecionado
        }
        
        // Vincular edital ao processo
        const resultado = await ProcessosAdministrativosService.vincularEditalProcesso(
          this.processo.id, 
          dadosEdital
        )
        
        this.$emit('edital-vinculado', {
          processo: resultado,
          dadosEdital: dadosEdital
        })
        
        this.fechar()
        
        // Mostrar sucesso
        this.$swal?.fire({
          title: 'Sucesso!',
          text: `Edital ${this.numeroEdital} vinculado com sucesso ao processo!`,
          icon: 'success',
          timer: 3000
        })
        
      } catch (error) {
        console.error('Erro ao vincular edital:', error)
        
        this.$swal?.fire({
          title: 'Erro',
          text: error.message || 'Erro ao vincular edital',
          icon: 'error'
        })
      } finally {
        this.salvando = false
      }
    },
    
    gerarObjetoAutomatico() {
      if (this.processo.tipo_processo === 'padronizacao') {
        return 'CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS.'
      } else {
        return 'DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE E ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS.'
      }
    },
    
    fechar() {
      this.$emit('fechar')
    }
  }
}
</script>

<style scoped>
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
  max-width: 600px;
  max-height: 90vh;
  overflow: auto;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
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
  font-size: 1.2rem;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #a0aec0;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s ease;
}

.btn-close:hover {
  background: #f7fafc;
  color: #4a5568;
}

.modal-body {
  padding: 1.5rem;
}

.processo-info {
  background: #f7fafc;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
}

.processo-info h4 {
  margin: 0 0 0.5rem;
  color: #2d3748;
  font-size: 1rem;
}

.processo-info p {
  margin: 0;
  color: #718096;
  font-size: 0.9rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #4a5568;
  font-size: 0.9rem;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-group input.error {
  border-color: #e53e3e;
  box-shadow: 0 0 0 3px rgba(229, 62, 62, 0.1);
}

.file-upload-area {
  border: 2px dashed #e2e8f0;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  transition: all 0.2s ease;
  cursor: pointer;
}

.file-upload-area.dragover {
  border-color: #667eea;
  background: rgba(102, 126, 234, 0.05);
}

.file-upload-area.has-file {
  border-color: #38a169;
  background: rgba(56, 161, 105, 0.05);
}

.upload-placeholder .upload-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.upload-placeholder p {
  margin: 0;
  color: #4a5568;
}

.btn-link {
  background: none;
  border: none;
  color: #667eea;
  cursor: pointer;
  text-decoration: underline;
}

.selected-file {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.file-icon {
  font-size: 2rem;
}

.file-info {
  flex: 1;
  text-align: left;
}

.file-info strong {
  display: block;
  color: #2d3748;
}

.file-info small {
  color: #718096;
}

.btn-remove {
  background: #fed7d7;
  border: 1px solid #fc8181;
  border-radius: 50%;
  width: 32px;
  height: 32px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.2s ease;
}

.btn-remove:hover {
  background: #feb2b2;
}

.produtos-relacionados {
  background: #f0fff4;
  padding: 1rem;
  border-radius: 8px;
  margin: 1rem 0;
}

.produtos-relacionados h4 {
  margin: 0 0 0.75rem;
  color: #2d3748;
  font-size: 0.95rem;
}

.produtos-lista {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.produto-item {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem;
  background: white;
  border-radius: 6px;
  border-left: 3px solid #38a169;
}

.produto-nome {
  font-weight: 500;
  color: #2d3748;
}

.produto-marca {
  color: #718096;
  font-size: 0.9rem;
}

.help-text {
  display: block;
  margin-top: 0.25rem;
  color: #718096;
  font-size: 0.8rem;
}

.error-msg {
  display: block;
  margin-top: 0.25rem;
  color: #e53e3e;
  font-size: 0.8rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 0.9rem;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #5a67d8;
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
</style>