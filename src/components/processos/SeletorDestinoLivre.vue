<template>
  <div class="seletor-destino-livre">
    <!-- Modal de Seleção de Destino -->
    <div v-if="showModal" class="modal-overlay" @click="fecharModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>🚀 Enviar Processo</h3>
          <button @click="fecharModal" class="btn-close">✕</button>
        </div>

        <div class="modal-body">
          <div class="processo-info">
            <p><strong>Processo:</strong> {{ processo.numero_processo }}</p>
            <p><strong>Status Atual:</strong> {{ obterNomeStatus(processo.status) }}</p>
            <p><strong>Tipo:</strong> {{ processo.tipo_processo === 'padronizacao' ? 'Padronização' : 'Despadronização' }}</p>
          </div>

          <div class="destinos-section">
            <h4>📋 Selecione o destino:</h4>
            <div class="destinos-grid">
              <div
                v-for="opcao in opcoesDestino"
                :key="opcao.status"
                class="destino-card"
                :class="{ 'selected': destinoSelecionado === opcao.status }"
                @click="selecionarDestino(opcao)"
              >
                <div class="destino-icone">{{ opcao.icone }}</div>
                <div class="destino-info">
                  <div class="destino-nome">{{ opcao.nomeEtapa }}</div>
                  <div class="destino-responsavel">{{ opcao.nomeResponsavel }}</div>
                </div>
              </div>
            </div>
          </div>

          <div class="observacoes-section">
            <label for="observacoes">📝 Observações (opcional):</label>
            <textarea
              id="observacoes"
              v-model="observacoes"
              placeholder="Digite observações sobre esta tramitação..."
              rows="3"
            ></textarea>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="fecharModal" class="btn btn-secondary">
            ❌ Cancelar
          </button>
          <button
            @click="confirmarEnvio"
            class="btn btn-primary"
            :disabled="!destinoSelecionado || enviando"
          >
            {{ enviando ? '⏳ Enviando...' : '🚀 Enviar Processo' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Botão principal para abrir modal -->
    <button @click="abrirModal" class="btn-enviar-livre" :disabled="!podeEnviar">
      🚀 Enviar para Próxima Etapa
    </button>
  </div>
</template>

<script>
import TramitacaoProcessosService from '../../services/tramitacaoProcessosService'

export default {
  name: 'SeletorDestinoLivre',
  props: {
    processo: {
      type: Object,
      required: true
    },
    podeEnviar: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      showModal: false,
      opcoesDestino: [],
      destinoSelecionado: null,
      destinoEscolhido: null,
      observacoes: '',
      enviando: false
    }
  },
  methods: {
    async abrirModal() {
      try {
        // Carregar opções de destino
        this.opcoesDestino = TramitacaoProcessosService.obterOpcoesDestinoLivre(this.processo.tipo_processo)

        // Filtrar opções que são diferentes do status atual
        this.opcoesDestino = this.opcoesDestino.filter(opcao => opcao.status !== this.processo.status)

        if (this.opcoesDestino.length === 0) {
          this.$emit('erro', 'Não há destinos disponíveis para este processo.')
          return
        }

        this.showModal = true
        this.destinoSelecionado = null
        this.destinoEscolhido = null
        this.observacoes = ''

      } catch (error) {
        console.error('Erro ao carregar opções de destino:', error)
        this.$emit('erro', 'Erro ao carregar opções de destino.')
      }
    },

    fecharModal() {
      this.showModal = false
      this.destinoSelecionado = null
      this.destinoEscolhido = null
      this.observacoes = ''
    },

    selecionarDestino(opcao) {
      this.destinoSelecionado = opcao.status
      this.destinoEscolhido = opcao
    },

    async confirmarEnvio() {
      if (!this.destinoSelecionado || !this.destinoEscolhido) {
        alert('Por favor, selecione um destino.')
        return
      }

      this.enviando = true

      try {
        console.log('🚀 Enviando processo com fluxo livre:', {
          processoId: this.processo.id,
          statusDestino: this.destinoSelecionado,
          observacoes: this.observacoes
        })

        const resultado = await TramitacaoProcessosService.enviarProcessoLivre(
          this.processo.id,
          this.destinoSelecionado,
          this.observacoes
        )

        console.log('✅ Processo enviado com sucesso:', resultado)

        // ✨ VALIDAÇÃO: Verificar se destinoEscolhido existe e tem nomeEtapa
        const destinoValidado = {
          nomeEtapa: (resultado.destinoEscolhido && resultado.destinoEscolhido.nomeEtapa) ||
                     this.destinoEscolhido?.nomeEtapa ||
                     'Etapa não identificada',
          nomeResponsavel: (resultado.destinoEscolhido && resultado.destinoEscolhido.nomeResponsavel) ||
                          this.destinoEscolhido?.nomeResponsavel ||
                          'Responsável não informado'
        }

        this.$emit('processo-enviado', {
          statusAnterior: resultado.statusAnterior,
          statusNovo: resultado.statusNovo,
          destinoEscolhido: destinoValidado,
          observacoes: this.observacoes
        })

        this.fecharModal()

        // Mostrar mensagem de sucesso
        alert(`✅ Processo enviado com sucesso para ${destinoValidado.nomeEtapa} (${destinoValidado.nomeResponsavel})!`)

      } catch (error) {
        console.error('❌ Erro ao enviar processo:', error)
        this.$emit('erro', `Erro ao enviar processo: ${error.message}`)
        alert(`❌ Erro ao enviar processo: ${error.message}`)
      } finally {
        this.enviando = false
      }
    },

    obterNomeStatus(status) {
      // Usar o serviço para obter nome amigável do status
      return TramitacaoProcessosService.obterNomeProximaEtapa(status) || status
    }
  }
}
</script>

<style scoped>
.seletor-destino-livre {
  display: inline-block;
}

.btn-enviar-livre {
  background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 14px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-enviar-livre:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(40, 167, 69, 0.3);
}

.btn-enviar-livre:disabled {
  background: #6c757d;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 600px;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
}

.modal-header {
  padding: 20px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  margin: 0;
  color: #333;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #999;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s ease;
}

.btn-close:hover {
  color: #333;
  background: #f0f0f0;
}

.modal-body {
  padding: 20px;
}

.processo-info {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 20px;
}

.processo-info p {
  margin: 8px 0;
  font-size: 14px;
}

.destinos-section {
  margin-bottom: 20px;
}

.destinos-section h4 {
  margin: 0 0 16px 0;
  color: #333;
}

.destinos-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  max-height: 300px;
  overflow-y: auto;
  padding-right: 8px;
}

.destino-card {
  border: 2px solid #e9ecef;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 16px;
}

.destino-card:hover {
  border-color: #28a745;
  background: #f8fff9;
}

.destino-card.selected {
  border-color: #28a745;
  background: #e8f5e8;
  box-shadow: 0 2px 8px rgba(40, 167, 69, 0.2);
}

.destino-icone {
  font-size: 24px;
  min-width: 32px;
  text-align: center;
}

.destino-info {
  flex: 1;
}

.destino-nome {
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
}

.destino-responsavel {
  font-size: 12px;
  color: #666;
}

.observacoes-section {
  margin-bottom: 20px;
}

.observacoes-section label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #333;
}

.observacoes-section textarea {
  width: 100%;
  border: 1px solid #ddd;
  border-radius: 6px;
  padding: 12px;
  font-family: inherit;
  resize: vertical;
  min-height: 80px;
}

.observacoes-section textarea:focus {
  outline: none;
  border-color: #28a745;
  box-shadow: 0 0 0 2px rgba(40, 167, 69, 0.2);
}

.modal-footer {
  padding: 20px;
  border-top: 1px solid #eee;
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.btn {
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #5a6268;
}

.btn-primary {
  background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(40, 167, 69, 0.3);
}

.btn-primary:disabled {
  background: #6c757d;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* Scrollbar personalizada para destinos */
.destinos-grid::-webkit-scrollbar {
  width: 6px;
}

.destinos-grid::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.destinos-grid::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.destinos-grid::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style>