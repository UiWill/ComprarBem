<template>
  <div v-if="visivel" class="modal-overlay" @click="fechar">
    <div class="modal" @click.stop>
      <div class="modal-header">
        <h3>
          {{ produto.tem_edital ? 'Editar' : 'Vincular' }} Edital de Pré-Qualificação
        </h3>
        <button @click="fechar" class="btn-close">&times;</button>
      </div>
      
      <div class="modal-body">
        <div class="produto-info">
          <h4>{{ produto.nome }}</h4>
          <p>{{ produto.descricao }}</p>
        </div>

        <form @submit.prevent="salvar">
          <div class="form-group">
            <label>Número do Edital *</label>
            <div class="input-with-suggestion">
              <input 
                type="text" 
                v-model="numeroEdital" 
                placeholder="001/2024"
                pattern="^\d{1,3}/\d{4}$"
                title="Formato: XXX/YYYY (ex: 001/2024)"
                required
                :class="{ 'error': erroValidacao }"
              >
              <button 
                type="button" 
                @click="aplicarSugestao" 
                class="btn-suggestion"
                :disabled="carregandoSugestao"
              >
                {{ carregandoSugestao ? 'Carregando...' : `Sugerir: ${sugestao}` }}
              </button>
            </div>
            <small v-if="erroValidacao" class="error-msg">{{ erroValidacao }}</small>
            <small v-else class="help-text">Formato: 001/2024</small>
          </div>

          <div class="form-group">
            <label>Ano *</label>
            <input 
              type="number" 
              v-model="anoEdital" 
              :min="2020" 
              :max="2030"
              @change="atualizarSugestao"
              required
            >
          </div>

          <div v-if="avisoExistente" class="alert alert-warning">
            ⚠️ Este número de edital já está sendo utilizado por outro produto.
          </div>

          <div class="form-actions">
            <button 
              v-if="produto.tem_edital" 
              type="button" 
              @click="desvincular" 
              class="btn-danger"
              :disabled="salvando"
            >
              Desvincular Edital
            </button>
            
            <div class="actions-right">
              <button type="button" @click="fechar" class="btn-secondary">
                Cancelar
              </button>
              <button 
                type="submit" 
                class="btn-primary" 
                :disabled="salvando || !!erroValidacao"
              >
                {{ salvando ? 'Salvando...' : 'Salvar' }}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import EditaisService from '../../services/editaisService'

export default {
  name: 'ModalVincularEdital',
  props: {
    visivel: {
      type: Boolean,
      default: false
    },
    produto: {
      type: Object,
      required: true
    }
  },
  
  data() {
    return {
      numeroEdital: '',
      anoEdital: new Date().getFullYear(),
      sugestao: '',
      carregandoSugestao: false,
      salvando: false,
      erroValidacao: '',
      avisoExistente: false
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
    async inicializar() {
      // Se produto já tem edital, preencher campos
      if (this.produto.tem_edital) {
        this.numeroEdital = this.produto.numero_edital || ''
        this.anoEdital = this.produto.ano_edital || new Date().getFullYear()
      } else {
        this.numeroEdital = ''
        this.anoEdital = new Date().getFullYear()
      }
      
      await this.atualizarSugestao()
    },
    
    async atualizarSugestao() {
      try {
        this.carregandoSugestao = true
        this.sugestao = await EditaisService.gerarSugestaoNumero(this.anoEdital)
      } catch (error) {
        console.error('Erro ao gerar sugestão:', error)
        this.sugestao = '001/' + this.anoEdital
      } finally {
        this.carregandoSugestao = false
      }
    },
    
    aplicarSugestao() {
      this.numeroEdital = this.sugestao
    },
    
    async validarNumero() {
      this.erroValidacao = ''
      this.avisoExistente = false
      
      if (!this.numeroEdital) return
      
      // Validar formato
      if (!EditaisService.validarFormatoNumero(this.numeroEdital)) {
        this.erroValidacao = 'Formato inválido. Use XXX/YYYY (ex: 001/2024)'
        return
      }
      
      // Extrair ano do número
      const partes = EditaisService.extrairPartesNumero(this.numeroEdital)
      if (partes.ano && partes.ano !== this.anoEdital) {
        this.anoEdital = partes.ano
      }
      
      // Verificar se já existe
      try {
        const jaExiste = await EditaisService.verificarEditalExistente(
          this.numeroEdital, 
          this.anoEdital,
          this.produto.id
        )
        
        if (jaExiste) {
          this.avisoExistente = true
        }
      } catch (error) {
        console.error('Erro ao verificar edital:', error)
      }
    },
    
    async salvar() {
      if (this.salvando) return
      
      try {
        this.salvando = true
        
        await EditaisService.vincularEdital(
          this.produto.id,
          this.numeroEdital,
          this.anoEdital
        )
        
        this.$emit('edital-vinculado', {
          produto: this.produto,
          numeroEdital: this.numeroEdital,
          anoEdital: this.anoEdital
        })
        
        this.fechar()
        
        // Mostrar sucesso
        this.$swal?.fire({
          title: 'Sucesso!',
          text: `Edital ${this.numeroEdital} vinculado com sucesso!`,
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
    
    async desvincular() {
      const confirmacao = await this.$swal?.fire({
        title: 'Desvincular Edital?',
        text: 'O produto ficará sem edital vinculado. Esta ação pode ser revertida.',
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Sim, desvincular',
        cancelButtonText: 'Cancelar'
      })
      
      if (!confirmacao?.isConfirmed) return
      
      try {
        this.salvando = true
        
        await EditaisService.desvincularEdital(this.produto.id)
        
        this.$emit('edital-desvinculado', this.produto)
        
        this.fechar()
        
        this.$swal?.fire({
          title: 'Desvinculado!',
          text: 'Edital removido com sucesso.',
          icon: 'success',
          timer: 3000
        })
        
      } catch (error) {
        console.error('Erro ao desvincular edital:', error)
        
        this.$swal?.fire({
          title: 'Erro',
          text: 'Erro ao desvincular edital',
          icon: 'error'
        })
      } finally {
        this.salvando = false
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
  max-width: 500px;
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

.produto-info {
  background: #f7fafc;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
}

.produto-info h4 {
  margin: 0 0 0.5rem;
  color: #2d3748;
  font-size: 1rem;
}

.produto-info p {
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

.input-with-suggestion {
  display: flex;
  gap: 0.5rem;
  align-items: stretch;
}

.input-with-suggestion input {
  flex: 1;
}

.form-group input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-group input.error {
  border-color: #e53e3e;
  box-shadow: 0 0 0 3px rgba(229, 62, 62, 0.1);
}

.btn-suggestion {
  padding: 0.75rem 1rem;
  background: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.85rem;
  color: #4a5568;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.btn-suggestion:hover:not(:disabled) {
  background: #edf2f7;
  border-color: #cbd5e0;
}

.btn-suggestion:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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

.alert {
  padding: 0.75rem;
  border-radius: 8px;
  margin-bottom: 1rem;
  font-size: 0.9rem;
}

.alert-warning {
  background: #fffbeb;
  border: 1px solid #fbbf24;
  color: #92400e;
}

.form-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}

.actions-right {
  display: flex;
  gap: 0.75rem;
}

.btn-primary,
.btn-secondary,
.btn-danger {
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

.btn-danger {
  background: #e53e3e;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #c53030;
}

.btn-danger:disabled {
  background: #a0aec0;
  cursor: not-allowed;
}
</style>