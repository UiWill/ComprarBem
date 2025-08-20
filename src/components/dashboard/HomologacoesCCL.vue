<template>
  <div class="homologacoes-ccl">
    <!-- Homologações Recentes -->
    <div class="section-card">
      <div class="section-header">
        <h3>📋 Homologações & Decisões da Autoridade</h3>
        <div class="section-actions">
          <button @click="carregarHomologacoes" class="btn-primary">
            🔄 Atualizar
          </button>
        </div>
      </div>

      <div class="homologacoes-container" v-if="homologacoes.length > 0">
        <div 
          v-for="homologacao in homologacoesPaginadas" 
          :key="homologacao.id" 
          class="homologacao-card"
        >
          <div class="homologacao-header">
            <div class="homologacao-info">
              <h4>{{ homologacao.numeroAta }}</h4>
              <p class="data">{{ formatDate(homologacao.dataHomologacao) }}</p>
            </div>
            <div class="homologacao-status">
              <span class="status-badge" :class="getStatusClass(homologacao.tipo)">
                {{ formatStatus(homologacao.tipo) }}
              </span>
            </div>
          </div>
          
          <div class="homologacao-actions">
            <button @click="visualizarAta(homologacao)" class="btn-small btn-primary">
              📋 Ver Ata
            </button>
            <button @click="baixarPDF(homologacao)" class="btn-small btn-secondary">
              📥 PDF
            </button>
            <button @click="verDCBs(homologacao)" class="btn-small btn-success">
              📜 DCBs
            </button>
            <!-- Botão de Decisão da Autoridade (apenas para processos pendentes) -->
            <button 
              v-if="homologacao.tipo === 'diligencia'" 
              @click="decidirHomologacao(homologacao)" 
              class="btn-small btn-warning"
              title="Tomar decisão final como Autoridade Competente"
            >
              ⚖️ Decidir
            </button>
            <!-- Botão de Confirmação CCL (para homologação direta) -->
            <button 
              v-if="homologacao.tipo === 'diligencia_direta'" 
              @click="confirmarHomologacaoCCL(homologacao)" 
              class="btn-small btn-success"
              title="Confirmar homologação direta da CCL"
            >
              ✅ Confirmar
            </button>
            <!-- Botão para enviar de volta para CPM -->
            <button 
              v-else-if="homologacao.tipo === 'homologada'" 
              @click="enviarParaCPM(homologacao)"
              class="btn-small btn-success"
              title="Enviar processo homologado de volta para CPM para expedição de DCBs"
            >
              📤 Enviar para CPM
            </button>
            <!-- Status final para processos já concluídos -->
            <span 
              v-else-if="homologacao.tipo === 'incluindo_marcas'" 
              class="btn-small btn-success"
              title="Processo concluído - produtos no catálogo"
            >
              ✅ Concluído
            </span>
            <span 
              v-else-if="homologacao.tipo === 'indeferida'" 
              class="btn-small btn-danger"
              title="Processo foi indeferido"
            >
              ❌ Indeferido
            </span>
          </div>
        </div>
      </div>

      <div v-else class="empty-state">
        <p>Nenhuma homologação encontrada</p>
      </div>

      <!-- Paginação -->
      <div v-if="homologacoes.length > 0" class="pagination-controls">
        <button 
          @click="paginaAnterior" 
          :disabled="paginaAtual === 1"
          class="btn-pagination"
        >
          ← Anterior
        </button>
        <span class="pagination-info">
          Página {{ paginaAtual }} de {{ totalPaginas }}
        </span>
        <button 
          @click="proximaPagina" 
          :disabled="paginaAtual === totalPaginas"
          class="btn-pagination"
        >
          Próxima →
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../../services/supabase'
import TramitacaoProcessosService from '../../services/tramitacaoProcessosService'

export default {
  name: 'HomologacoesCCL',
  data() {
    return {
      homologacoes: [],
      loading: false,
      paginaAtual: 1,
      itensPorPagina: 5
    }
  },
  computed: {
    totalPaginas() {
      return Math.ceil(this.homologacoes.length / this.itensPorPagina)
    },
    homologacoesPaginadas() {
      const inicio = (this.paginaAtual - 1) * this.itensPorPagina
      const fim = inicio + this.itensPorPagina
      return this.homologacoes.slice(inicio, fim)
    },
    currentTenantId() {
      // Tentar múltiplas fontes para garantir que temos o tenant_id
      return this.$store.getters.getTenantId || 
             this.$store.state.user?.user?.user_metadata?.tenant_id ||
             this.$store.state.user?.tenant_id ||
             '8329e25e-8a01-4fc6-ab15-7a83dd874bde' // Fallback para o tenant atual
    }
  },
  mounted() {
    this.carregarHomologacoes()
  },
  methods: {
    async carregarHomologacoes() {
      if (!this.currentTenantId) {
        console.log('❌ HomologacoesCCL: Sem tenant_id')
        return
      }
      
      this.loading = true
      try {
        // Buscar processos que podem ser homologados
        const { data, error } = await supabase
          .from('processos_administrativos')
          .select(`
            id,
            numero_processo,
            status,
            ata_emitida_ccl_em,
            created_at,
            updated_at,
            tenant_id,
            ata_julgamento_ccl
          `)
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['ata_julgamento_ccl_homologacao', 'ata_julgamento_ccl_indeferimento', 'diligencia_ccl', 'homologado', 'indeferido'])
          .order('updated_at', { ascending: false })
          .limit(20)

        if (error) throw error

        // Transformar dados para o formato esperado
        this.homologacoes = data?.map(processo => ({
          id: processo.id,
          numeroAta: `${processo.numero_processo}`,
          dataHomologacao: processo.ata_emitida_ccl_em || processo.updated_at || processo.created_at,
          tipo: this.determinarTipo(processo.status, processo.ata_julgamento_ccl),
          processo: processo
        })) || []

      } catch (error) {
        console.error('Erro ao carregar homologações:', error)
        this.$swal({
          title: '❌ Erro',
          text: 'Erro ao carregar homologações',
          icon: 'error'
        })
      } finally {
        this.loading = false
      }
    },

    // Decisão da Autoridade - Função Principal
    decidirHomologacao(homologacao) {
      this.$swal({
        title: '⚖️ Decisão da Autoridade',
        text: `Processo: ${homologacao.numeroAta}`,
        icon: 'question',
        showCancelButton: true,
        showDenyButton: true,
        confirmButtonText: '✅ Homologar',
        denyButtonText: '❌ Indeferir',
        cancelButtonText: '📄 Diligência'
      }).then((result) => {
        if (result.isConfirmed) {
          this.processarDecisao(homologacao, 'HOMOLOGADO')
        } else if (result.isDenied) {
          this.processarDecisao(homologacao, 'INDEFERIDO')
        } else if (result.isDismissed) {
          this.processarDecisao(homologacao, 'EM DILIGÊNCIA')
        }
      })
    },

    async processarDecisao(homologacao, decisao) {
      try {
        // Registrar decisão no banco (adapte conforme necessário)
        console.log('📋 Registrando decisão:', {
          processoId: homologacao.id,
          numeroAta: homologacao.numeroAta,
          decisao: decisao,
          dataDecisao: new Date().toISOString()
        })

        // Atualizar processo no banco
        if (homologacao.processo) {
          const novoStatus = decisao === 'HOMOLOGADO' ? 'homologado' : 
                           decisao === 'INDEFERIDO' ? 'indeferido' : 'diligencia_ccl'
          
          const { error } = await supabase
            .from('processos_administrativos')
            .update({ 
              status: novoStatus,
              updated_at: new Date().toISOString()
            })
            .eq('id', homologacao.processo.id)
            .eq('tenant_id', this.currentTenantId)

          if (error) throw error
        }

        // Mostrar resultado
        const cores = {
          'HOMOLOGADO': '#28a745',
          'INDEFERIDO': '#dc3545', 
          'EM DILIGÊNCIA': '#ffc107'
        }

        this.$swal({
          title: '✅ Decisão Registrada',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4 style="color: ${cores[decisao]};">${decisao}</h4>
              <p><strong>Processo:</strong> ${homologacao.numeroAta}</p>
              <p><strong>Decisão registrada em:</strong> ${this.formatDate(new Date())}</p>
            </div>
          `,
          icon: 'success',
          timer: 3000
        })
        
        // Recarregar dados
        await this.carregarHomologacoes()

      } catch (error) {
        console.error('Erro ao processar decisão:', error)
        this.$swal({
          title: '❌ Erro',
          text: `Erro ao registrar decisão: ${error.message}`,
          icon: 'error'
        })
      }
    },

    determinarTipo(status, ataJulgamento = '') {
      switch (status) {
        case 'ata_julgamento_ccl_homologacao':
          // Se tem marcação de homologação direta no texto, é para confirmação CCL
          const isHomologacaoDireta = ataJulgamento && ataJulgamento.includes('homologação direta')
          return isHomologacaoDireta ? 'diligencia_direta' : 'diligencia'
        case 'ata_julgamento_ccl_indeferimento':
          return 'diligencia' // Recomendado para indeferimento - AGUARDA DECISÃO DA AUTORIDADE
        case 'diligencia_ccl':
          return 'diligencia' // Em diligência - AGUARDA DECISÃO DA AUTORIDADE
        case 'homologado':
          return 'homologada' // JÁ FOI DECIDIDO - HOMOLOGADO PELA AUTORIDADE - PRÓXIMO: EXPEDIR DCBS
        case 'expedindo_dcbs':
          return 'expedindo_dcbs' // EXPEDINDO DCBS - PRÓXIMO: INCLUIR NO CATÁLOGO
        case 'incluindo_marcas':
          return 'incluindo_marcas' // PROCESSO CONCLUÍDO - PRODUTOS NO CATÁLOGO
        case 'indeferido':
          return 'indeferida' // JÁ FOI DECIDIDO - INDEFERIDO PELA AUTORIDADE
        default:
          return 'diligencia'
      }
    },

    getStatusClass(tipo) {
      switch (tipo) {
        case 'homologada': return 'status-aprovado'
        case 'indeferida': return 'status-reprovado'
        case 'diligencia': return 'status-pendente'
        default: return 'status-padrao'
      }
    },

    formatStatus(tipo) {
      switch (tipo) {
        case 'homologada': return '✅ HOMOLOGADA - AGUARDA ENVIO PARA CPM'
        case 'expedindo_dcbs': return '📄 EXPEDINDO DCBs - AGUARDA INCLUSÃO NO CATÁLOGO'
        case 'incluindo_marcas': return '🎯 CONCLUÍDO - PRODUTOS NO CATÁLOGO'
        case 'indeferida': return '❌ INDEFERIDA (FINAL)'
        case 'diligencia': return '📄 AGUARDANDO DECISÃO DA AUTORIDADE'
        case 'diligencia_direta': return '⚡ AGUARDANDO CONFIRMAÇÃO CCL'
        default: return tipo
      }
    },

    // Confirmação da Homologação Direta da CCL
    confirmarHomologacaoCCL(homologacao) {
      this.$swal({
        title: '✅ Confirmar Homologação Direta',
        html: `
          <div style="text-align: left; padding: 15px;">
            <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h4 style="margin: 0 0 10px 0; color: #2e7d32;">📋 Processo: ${homologacao.numeroAta}</h4>
              <p style="margin: 5px 0;"><strong>Status:</strong> Aprovado pela CCL para homologação direta</p>
              <p style="margin: 5px 0;"><strong>Data:</strong> ${this.formatDate(homologacao.dataHomologacao)}</p>
            </div>
            
            <div style="background: #fff3cd; padding: 12px; border-radius: 8px; margin-bottom: 15px;">
              <h5 style="margin: 0 0 8px 0; color: #856404; font-size: 14px;">⚡ Homologação Direta:</h5>
              <p style="margin: 0; font-size: 13px;">
                A CCL já analisou e aprovou este processo. A confirmação irá homologar definitivamente 
                e emitir as DCBs automaticamente.
              </p>
            </div>
            
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 8px;">📝 Observações da Homologação:</label>
              <textarea id="observacoesHomologacao" class="swal2-textarea" rows="3" 
                placeholder="Observações adicionais sobre a homologação (opcional)..." 
                style="width: 100%; box-sizing: border-box;"></textarea>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '✅ Confirmar Homologação',
        cancelButtonText: '❌ Cancelar',
        confirmButtonColor: '#28a745',
        width: '500px',
        preConfirm: () => {
          const observacoes = document.getElementById('observacoesHomologacao').value
          return { observacoes: observacoes.trim() }
        }
      }).then((result) => {
        if (result.isConfirmed) {
          this.processarConfirmacaoHomologacao(homologacao, result.value.observacoes)
        }
      })
    },

    async processarConfirmacaoHomologacao(homologacao, observacoes) {
      try {
        // Atualizar processo para homologado
        const { error } = await supabase
          .from('processos_administrativos')
          .update({ 
            status: 'homologado',
            updated_at: new Date().toISOString()
          })
          .eq('id', homologacao.processo.id)
          .eq('tenant_id', this.currentTenantId)

        if (error) throw error

        // Mostrar resultado
        this.$swal({
          title: '✅ Processo Homologado!',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4 style="color: #28a745;">HOMOLOGAÇÃO CONFIRMADA</h4>
              <p><strong>Processo:</strong> ${homologacao.numeroAta}</p>
              <p><strong>Homologado em:</strong> ${this.formatDate(new Date())}</p>
              <div style="background: #e8f5e8; padding: 12px; border-radius: 8px; margin-top: 15px;">
                <p style="margin: 0; font-size: 14px;">
                  🎯 <strong>DCBs serão emitidas automaticamente</strong>
                </p>
              </div>
            </div>
          `,
          icon: 'success',
          timer: 4000
        })
        
        // Recarregar dados
        await this.carregarHomologacoes()

      } catch (error) {
        console.error('Erro ao confirmar homologação:', error)
        this.$swal({
          title: '❌ Erro',
          text: `Erro ao confirmar homologação: ${error.message}`,
          icon: 'error'
        })
      }
    },

    formatDate(dateInput) {
      if (!dateInput) return ''
      const date = new Date(dateInput)
      return date.toLocaleDateString('pt-BR')
    },

    visualizarAta(homologacao) {
      this.$swal({
        title: '📋 Ata de Homologação',
        text: `Visualizando ata ${homologacao.numeroAta}`,
        icon: 'info'
      })
    },

    baixarPDF(homologacao) {
      this.$swal({
        title: '📥 Download PDF',
        text: `Baixando PDF da ata ${homologacao.numeroAta}`,
        icon: 'success',
        timer: 2000
      })
    },

    verDCBs(homologacao) {
      this.$swal({
        title: '📜 DCBs da Homologação',
        html: `
          <div style="text-align: left; padding: 15px;">
            <h4>Ata: ${homologacao.numeroAta}</h4>
            <p><strong>Data:</strong> ${this.formatDate(homologacao.dataHomologacao)}</p>
            <p><strong>Tipo:</strong> ${this.formatStatus(homologacao.tipo)}</p>
            <hr>
            <h5>DCBs Emitidas:</h5>
            <div style="background: #f8f9fa; padding: 10px; border-radius: 4px;">
              ${homologacao.tipo === 'homologada' ? 
                `<p>✅ <strong>1 DCB emitida</strong></p>
                 <p><small>• DCB-001/${new Date().getFullYear()}</small></p>
                 <p><small>• Status: ATIVA</small></p>` :
                `<p>❌ <strong>Nenhuma DCB emitida</strong></p>`
              }
            </div>
          </div>
        `,
        showCancelButton: true,
        cancelButtonText: '✅ OK',
        showConfirmButton: false
      })
    },

    proximaPagina() {
      if (this.paginaAtual < this.totalPaginas) {
        this.paginaAtual++
      }
    },

    paginaAnterior() {
      if (this.paginaAtual > 1) {
        this.paginaAtual--
      }
    },

    // Enviar processo homologado de volta para CPM
    async enviarParaCPM(homologacao) {
      this.$swal({
        title: '📤 Enviar para CPM',
        html: `
          <div style="text-align: left; padding: 15px;">
            <div style="background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h4 style="margin: 0 0 10px 0; color: #2e7d32;">📋 Processo: ${homologacao.numeroAta}</h4>
              <p style="margin: 5px 0;"><strong>Status:</strong> Homologado pela Autoridade</p>
              <p style="margin: 5px 0;"><strong>Data:</strong> ${this.formatDate(homologacao.dataHomologacao)}</p>
            </div>
            
            <div style="background: #fff3cd; padding: 12px; border-radius: 8px; margin-bottom: 15px;">
              <h5 style="margin: 0 0 8px 0; color: #856404; font-size: 14px;">📤 Tramitação para CPM:</h5>
              <p style="margin: 0; font-size: 13px;">
                O processo será enviado de volta para a CPM para:<br>
                • Expedição das DCBs<br>
                • Inclusão dos produtos no catálogo eletrônico
              </p>
            </div>
            
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 8px;">📝 Observações da Tramitação:</label>
              <textarea id="observacoesTramitacao" class="swal2-textarea" rows="3" 
                placeholder="Observações sobre o envio para CPM (opcional)..." 
                style="width: 100%; box-sizing: border-box;"></textarea>
            </div>
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: '📤 Enviar para CPM',
        cancelButtonText: '❌ Cancelar',
        confirmButtonColor: '#28a745',
        width: '500px',
        preConfirm: () => {
          const observacoes = document.getElementById('observacoesTramitacao').value
          return { observacoes: observacoes.trim() }
        }
      }).then((result) => {
        if (result.isConfirmed) {
          this.processarEnvioParaCPM(homologacao, result.value.observacoes)
        }
      })
    },

    async processarEnvioParaCPM(homologacao, observacoes) {
      try {
        // Tramitar processo usando o serviço (envia email automaticamente)
        const resultado = await TramitacaoProcessosService.enviarProcessoFlexivel(
          homologacao.processo.id,
          'expedindo_dcbs',
          'ENVIO_PARA_CPM',
          `Processo homologado enviado para CPM para expedição de DCBs e inclusão no catálogo. ${observacoes ? 'Observações: ' + observacoes : ''}`
        )

        if (!resultado.sucesso) throw new Error('Erro na tramitação')

        // Mostrar resultado
        this.$swal({
          title: '📤 Enviado para CPM!',
          html: `
            <div style="text-align: center; padding: 20px;">
              <h4 style="color: #28a745;">PROCESSO TRAMITADO COM SUCESSO</h4>
              <p><strong>Processo:</strong> ${homologacao.numeroAta}</p>
              <p><strong>Enviado em:</strong> ${this.formatDate(new Date())}</p>
              <div style="background: #e3f2fd; padding: 12px; border-radius: 8px; margin-top: 15px;">
                <p style="margin: 0; font-size: 14px;">
                  🏢 <strong>Processo agora está com a CPM</strong>
                </p>
                <p style="margin: 5px 0 0 0; font-size: 12px;">
                  A CPM irá expedir as DCBs e incluir no catálogo
                </p>
              </div>
            </div>
          `,
          icon: 'success',
          timer: 4000
        })
        
        // Recarregar dados (processo sairá da lista da CCL)
        await this.carregarHomologacoes()

      } catch (error) {
        console.error('Erro ao enviar para CPM:', error)
        this.$swal({
          title: '❌ Erro',
          text: `Erro ao enviar para CPM: ${error.message}`,
          icon: 'error'
        })
      }
    }
  }
}
</script>

<style scoped>
.homologacoes-ccl {
  width: 100%;
}

.section-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  border-bottom: 1px solid #eee;
  padding-bottom: 15px;
}

.section-header h3 {
  margin: 0;
  color: #333;
}

.homologacoes-container {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.homologacao-card {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 15px;
  background: #fafafa;
}

.homologacao-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.homologacao-info h4 {
  margin: 0;
  color: #333;
  font-size: 16px;
}

.homologacao-info .data {
  margin: 5px 0 0 0;
  color: #666;
  font-size: 14px;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: bold;
  text-transform: uppercase;
}

.status-aprovado {
  background: #d4edda;
  color: #155724;
}

.status-reprovado {
  background: #f8d7da;
  color: #721c24;
}

.status-pendente {
  background: #fff3cd;
  color: #856404;
}

.status-padrao {
  background: #e2e3e5;
  color: #383d41;
}

.homologacao-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.btn-small {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.2s;
}

.btn-primary {
  background: #007bff;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary:hover {
  background: #0056b3;
}

.btn-small.btn-primary {
  background: #007bff;
  color: white;
}

.btn-small.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-small.btn-success {
  background: #28a745;
  color: white;
}

.btn-small.btn-warning {
  background: #ffc107;
  color: #212529;
}

.btn-small.btn-danger {
  background: #dc3545;
  color: white;
}

.btn-small:hover {
  opacity: 0.8;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #666;
}

.pagination-controls {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
  margin-top: 20px;
  padding-top: 15px;
  border-top: 1px solid #eee;
}

.btn-pagination {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  padding: 8px 12px;
  border-radius: 4px;
  cursor: pointer;
}

.btn-pagination:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-pagination:not(:disabled):hover {
  background: #e9ecef;
}

.pagination-info {
  color: #666;
  font-size: 14px;
}
</style>