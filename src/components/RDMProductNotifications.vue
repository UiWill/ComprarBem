<template>
  <div class="rdm-notifications">
    <div class="notifications-header">
      <h3>🔔 Meus Produtos para Avaliação</h3>
      <button @click="atualizarLista" class="btn btn-refresh" :disabled="carregando">
        <i class="fas fa-sync" :class="{ 'fa-spin': carregando }"></i>
        Atualizar
      </button>
    </div>

    <!-- Filtros -->
    <div class="filters">
      <div class="filter-item">
        <label>Status:</label>
        <select v-model="filtroStatus" @change="filtrarProdutos">
          <option value="">Todos</option>
          <option value="pendente">Pendente Avaliação</option>
          <option value="avaliado">Já Avaliado</option>
          <option value="vencido">Prazo Vencido</option>
        </select>
      </div>
      
      <div class="filter-item">
        <label>Ordenar por:</label>
        <select v-model="ordenacao" @change="filtrarProdutos">
          <option value="data_desc">Data (Mais Recente)</option>
          <option value="data_asc">Data (Mais Antigo)</option>
          <option value="dias_desc">Dias Restantes</option>
          <option value="nome_asc">Nome do Produto</option>
        </select>
      </div>
    </div>

    <!-- Lista de Produtos -->
    <div class="products-list" v-if="produtosFiltrados.length > 0">
      <div
        v-for="produto in produtosFiltrados"
        :key="produto.id"
        class="product-card"
        :class="getStatusClass(produto)"
      >
        <div class="product-header">
          <div class="product-info">
            <h4>{{ produto.material_nome }}</h4>
            <p class="product-code">Código: {{ produto.material_codigo }}</p>
          </div>
          
          <div class="product-status">
            <span class="status-badge" :class="getStatusClass(produto)">
              {{ getStatusText(produto) }}
            </span>
          </div>
        </div>

        <div class="product-details">
          <div class="detail-row">
            <span class="detail-label">Unidade/Setor:</span>
            <span class="detail-value">{{ produto.unidade_setor }}</span>
          </div>
          
          <div class="detail-row">
            <span class="detail-label">Dias desde recebimento:</span>
            <span class="detail-value">{{ produto.dias_desde_vinculacao }} dias</span>
          </div>
          
          <div class="detail-row">
            <span class="detail-label">Prazo para avaliação:</span>
            <span class="detail-value" :class="getPrazoClass(produto)">
              {{ getPrazoText(produto) }}
            </span>
          </div>
        </div>

        <div class="product-actions">
          <button
            v-if="!produto.avaliado"
            @click="avaliarProduto(produto)"
            class="btn btn-primary"
          >
            ⭐ Avaliar Produto
          </button>
          
          <button
            v-else
            @click="verAvaliacao(produto)"
            class="btn btn-secondary"
          >
            👁️ Ver Avaliação
          </button>
          
          <button
            @click="verHistoricoLembretes(produto)"
            class="btn btn-info"
          >
            📧 Histórico de Lembretes
          </button>
        </div>
      </div>
    </div>

    <!-- Estado Vazio -->
    <div v-else-if="!carregando" class="empty-state">
      <div class="empty-icon">📦</div>
      <h4>Nenhum produto encontrado</h4>
      <p>Você não possui produtos para avaliação no momento.</p>
    </div>

    <!-- Loading -->
    <div v-if="carregando" class="loading-state">
      <div class="loader"></div>
      <p>Carregando produtos...</p>
    </div>

    <!-- Modal de Avaliação -->
    <div v-if="produtoParaAvaliar" class="modal-overlay" @click="fecharModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>⭐ Avaliar Produto</h3>
          <button @click="fecharModal" class="btn-close">&times;</button>
        </div>
        
        <div class="modal-body">
          <div class="product-info-modal">
            <h4>{{ produtoParaAvaliar.material_nome }}</h4>
            <p>Código: {{ produtoParaAvaliar.material_codigo }}</p>
            <p>Unidade: {{ produtoParaAvaliar.unidade_setor }}</p>
          </div>
          
          <div class="rating-section">
            <label>Como você avalia este produto?</label>
            <div class="stars-rating">
              <span
                v-for="star in 5"
                :key="star"
                class="star"
                :class="{ active: star <= avaliacao.rating }"
                @click="avaliacao.rating = star"
              >
                ⭐
              </span>
            </div>
            <div class="rating-text">
              {{ getRatingText(avaliacao.rating) }}
            </div>
          </div>
          
          <div class="comment-section">
            <label>Comentários (opcional):</label>
            <textarea
              v-model="avaliacao.comentario"
              placeholder="Conte-nos sua experiência com este produto..."
              rows="4"
            ></textarea>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="fecharModal" class="btn btn-secondary">
            Cancelar
          </button>
          <button
            @click="salvarAvaliacao"
            :disabled="!avaliacao.rating || salvandoAvaliacao"
            class="btn btn-primary"
          >
            {{ salvandoAvaliacao ? 'Salvando...' : 'Salvar Avaliação' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal de Histórico -->
    <div v-if="historicoModal" class="modal-overlay" @click="fecharHistorico">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>📧 Histórico de Lembretes</h3>
          <button @click="fecharHistorico" class="btn-close">&times;</button>
        </div>
        
        <div class="modal-body">
          <div v-if="historicoLembretes.length > 0" class="historico-list">
            <div
              v-for="lembrete in historicoLembretes"
              :key="lembrete.id"
              class="lembrete-item"
              :class="{
                'sucesso': lembrete.email_enviado && lembrete.tipo_lembrete !== '5_MINUTOS',
                'erro': !lembrete.email_enviado,
                'teste': lembrete.tipo_lembrete === '5_MINUTOS'
              }"
            >
              <div class="lembrete-info">
                <span class="lembrete-tipo">{{ formatarTipoLembrete(lembrete.tipo_lembrete) }}</span>
                <span class="lembrete-data">{{ formatarData(lembrete.criado_em) }}</span>
              </div>
              <div class="lembrete-status">
                <span class="status-icon">
                  {{ lembrete.tipo_lembrete === '5_MINUTOS' ? '🎯' : (lembrete.email_enviado ? '✅' : '❌') }}
                </span>
                <span class="status-text">
                  {{ lembrete.tipo_lembrete === '5_MINUTOS' ? 'Teste' : (lembrete.email_enviado ? 'Enviado' : 'Erro') }}
                </span>
              </div>
              <div v-if="lembrete.erro_envio" class="lembrete-erro">
                {{ lembrete.erro_envio }}
              </div>
            </div>
          </div>
          
          <div v-else class="empty-historico">
            <p>Nenhum lembrete enviado para este produto ainda.</p>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="fecharHistorico" class="btn btn-secondary">
            Fechar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { 
  buscarProdutosPendentesAvaliacao,
  buscarHistoricoLembretes,
  marcarProdutoComoAvaliado,
  salvarFeedbackRDM
} from '@/services/emailService'
import { supabase } from '@/services/supabase'

export default {
  name: 'RDMProductNotifications',
  
  data() {
    return {
      produtos: [],
      produtosFiltrados: [],
      carregando: false,
      filtroStatus: '',
      ordenacao: 'data_desc',
      
      // Modal de avaliação
      produtoParaAvaliar: null,
      avaliacao: {
        rating: 0,
        comentario: ''
      },
      salvandoAvaliacao: false,
      
      // Modal de histórico
      historicoModal: false,
      historicoLembretes: [],
      produtoHistorico: null,
      
      // Intervalo para atualização automática
      intervaloAtualizacao: null
    }
  },
  
  computed: {
    usuarioAtual() {
      return this.$store.state.user
    },
    
    tenantId() {
      return this.usuarioAtual?.user_metadata?.tenant_id
    }
  },
  
  mounted() {
    this.carregarProdutos()
    
    // Atualizar lista a cada 5 minutos
    this.intervaloAtualizacao = setInterval(() => {
      this.carregarProdutos()
    }, 5 * 60 * 1000)
  },
  
  beforeDestroy() {
    if (this.intervaloAtualizacao) {
      clearInterval(this.intervaloAtualizacao)
    }
  },
  
  methods: {
    async carregarProdutos() {
      if (!this.usuarioAtual) return
      
      this.carregando = true
      
      try {
        // Buscar produtos vinculados ao usuário atual
        const { data, error } = await supabase
          .from('usuarios_rdm_produtos')
          .select(`
            *,
            produtos:produto_id (
              nome,
              codigo_material,
              marca,
              modelo
            ),
            usuarios_rdm:usuario_rdm_id (
              nome_usuario,
              email,
              unidade_setor
            )
          `)
          .eq('tenant_id', this.tenantId)
          .order('criado_em', { ascending: false })
        
        if (error) throw error
        
        // Processar dados
        this.produtos = data.map(item => ({
          id: item.id,
          usuario_rdm_id: item.usuario_rdm_id,
          produto_id: item.produto_id,
          material_nome: item.produtos?.nome || 'Produto não encontrado',
          material_codigo: item.produtos?.codigo_material || 'N/A',
          marca: item.produtos?.marca || '',
          modelo: item.produtos?.modelo || '',
          unidade_setor: item.usuarios_rdm?.unidade_setor || 'N/A',
          data_vinculacao: item.data_vinculacao,
          data_recebimento: item.data_recebimento,
          avaliado: item.avaliado,
          data_avaliacao: item.data_avaliacao,
          notificado_email: item.notificado_email,
          data_notificacao: item.data_notificacao,
          dias_desde_vinculacao: this.calcularDias(item.data_recebimento || item.data_vinculacao)
        }))
        
        this.filtrarProdutos()
        
      } catch (error) {
        console.error('Erro ao carregar produtos:', error)
        this.$swal.fire({
          title: 'Erro',
          text: 'Não foi possível carregar os produtos',
          icon: 'error'
        })
      } finally {
        this.carregando = false
      }
    },
    
    filtrarProdutos() {
      let filtrados = [...this.produtos]
      
      // Filtrar por status
      if (this.filtroStatus) {
        filtrados = filtrados.filter(produto => {
          switch (this.filtroStatus) {
            case 'pendente':
              return !produto.avaliado && produto.dias_desde_vinculacao < 30
            case 'avaliado':
              return produto.avaliado
            case 'vencido':
              return !produto.avaliado && produto.dias_desde_vinculacao >= 30
            default:
              return true
          }
        })
      }
      
      // Ordenar
      filtrados.sort((a, b) => {
        switch (this.ordenacao) {
          case 'data_desc':
            return new Date(b.data_vinculacao) - new Date(a.data_vinculacao)
          case 'data_asc':
            return new Date(a.data_vinculacao) - new Date(b.data_vinculacao)
          case 'dias_desc':
            return b.dias_desde_vinculacao - a.dias_desde_vinculacao
          case 'nome_asc':
            return a.material_nome.localeCompare(b.material_nome)
          default:
            return 0
        }
      })
      
      this.produtosFiltrados = filtrados
    },
    
    calcularDias(dataInicial) {
      if (!dataInicial) return 0
      const hoje = new Date()
      const inicio = new Date(dataInicial)
      const diffTime = Math.abs(hoje - inicio)
      return Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    },
    
    getStatusClass(produto) {
      if (produto.avaliado) return 'avaliado'
      if (produto.dias_desde_vinculacao >= 30) return 'vencido'
      if (produto.dias_desde_vinculacao >= 20) return 'urgente'
      return 'pendente'
    },
    
    getStatusText(produto) {
      if (produto.avaliado) return 'Avaliado'
      if (produto.dias_desde_vinculacao >= 30) return 'Prazo Vencido'
      if (produto.dias_desde_vinculacao >= 20) return 'Urgente'
      return 'Pendente'
    },
    
    getPrazoClass(produto) {
      if (produto.avaliado) return 'concluido'
      if (produto.dias_desde_vinculacao >= 30) return 'vencido'
      if (produto.dias_desde_vinculacao >= 20) return 'urgente'
      return 'normal'
    },
    
    getPrazoText(produto) {
      if (produto.avaliado) return 'Concluído'
      const diasRestantes = 30 - produto.dias_desde_vinculacao
      if (diasRestantes <= 0) return 'Vencido'
      return `${diasRestantes} dias restantes`
    },
    
    avaliarProduto(produto) {
      this.produtoParaAvaliar = produto
      this.avaliacao = {
        rating: 0,
        comentario: ''
      }
    },
    
    fecharModal() {
      this.produtoParaAvaliar = null
      this.avaliacao = {
        rating: 0,
        comentario: ''
      }
    },
    
    getRatingText(rating) {
      const texts = {
        1: 'Muito Ruim',
        2: 'Ruim',
        3: 'Regular',
        4: 'Bom',
        5: 'Excelente'
      }
      return texts[rating] || 'Clique nas estrelas para avaliar'
    },
    
    async salvarAvaliacao() {
      if (!this.avaliacao.rating) return
      
      this.salvandoAvaliacao = true
      
      try {
        // Salvar feedback
        const feedbackData = {
          tenant_id: this.tenantId,
          rdm_id: this.produtoParaAvaliar.id,
          usuario_rdm_id: this.produtoParaAvaliar.usuario_rdm_id,
          material_nome: this.produtoParaAvaliar.material_nome,
          material_codigo: this.produtoParaAvaliar.material_codigo,
          rating: this.avaliacao.rating,
          comentario: this.avaliacao.comentario
        }
        
        const resultadoFeedback = await salvarFeedbackRDM(feedbackData)
        
        if (resultadoFeedback.success) {
          // Marcar produto como avaliado
          await marcarProdutoComoAvaliado(
            this.produtoParaAvaliar.usuario_rdm_id,
            this.produtoParaAvaliar.produto_id
          )
          
          this.$swal.fire({
            title: 'Sucesso!',
            text: 'Avaliação salva com sucesso!',
            icon: 'success'
          })
          
          this.fecharModal()
          this.carregarProdutos()
        } else {
          throw new Error(resultadoFeedback.message)
        }
        
      } catch (error) {
        console.error('Erro ao salvar avaliação:', error)
        this.$swal.fire({
          title: 'Erro',
          text: 'Não foi possível salvar a avaliação',
          icon: 'error'
        })
      } finally {
        this.salvandoAvaliacao = false
      }
    },
    
    async verHistoricoLembretes(produto) {
      this.produtoHistorico = produto
      this.historicoModal = true
      
      try {
        const resultado = await buscarHistoricoLembretes(produto.usuario_rdm_id, produto.produto_id)
        
        if (resultado.success) {
          this.historicoLembretes = resultado.lembretes
        } else {
          console.error('Erro ao buscar histórico:', resultado.message)
        }
        
      } catch (error) {
        console.error('Erro ao buscar histórico:', error)
      }
    },
    
    fecharHistorico() {
      this.historicoModal = false
      this.historicoLembretes = []
      this.produtoHistorico = null
    },
    
    formatarTipoLembrete(tipo) {
      const tipos = {
        '5_MINUTOS': 'Lembrete 5 minutos (Teste)',
        '10_DIAS': 'Lembrete 10 dias',
        '20_DIAS': 'Lembrete 20 dias',
        '30_DIAS': 'Lembrete 30 dias (Urgente)'
      }
      return tipos[tipo] || tipo
    },
    
    formatarData(data) {
      return new Date(data).toLocaleString('pt-BR')
    },
    
    atualizarLista() {
      this.carregarProdutos()
    },
    
    verAvaliacao(produto) {
      this.$swal.fire({
        title: 'Produto Avaliado',
        text: `Este produto foi avaliado em ${new Date(produto.data_avaliacao).toLocaleDateString('pt-BR')}`,
        icon: 'info'
      })
    }
  }
}
</script>

<style scoped>
.rdm-notifications {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.notifications-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.notifications-header h3 {
  margin: 0;
  color: #333;
}

.btn-refresh {
  background: #28a745;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-refresh:hover {
  background: #218838;
}

.btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.filters {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
  padding: 15px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.filter-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filter-item label {
  font-weight: bold;
  color: #666;
  font-size: 0.9rem;
}

.filter-item select {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
}

.products-list {
  display: grid;
  gap: 20px;
}

.product-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  border-left: 4px solid #007bff;
}

.product-card.pendente {
  border-left-color: #007bff;
}

.product-card.urgente {
  border-left-color: #ffc107;
}

.product-card.vencido {
  border-left-color: #dc3545;
}

.product-card.avaliado {
  border-left-color: #28a745;
}

.product-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.product-info h4 {
  margin: 0 0 5px 0;
  color: #333;
}

.product-code {
  margin: 0;
  color: #666;
  font-size: 0.9rem;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: bold;
}

.status-badge.pendente {
  background: #e3f2fd;
  color: #1976d2;
}

.status-badge.urgente {
  background: #fff3cd;
  color: #856404;
}

.status-badge.vencido {
  background: #f8d7da;
  color: #721c24;
}

.status-badge.avaliado {
  background: #d4edda;
  color: #155724;
}

.product-details {
  margin-bottom: 20px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}

.detail-label {
  font-weight: bold;
  color: #666;
}

.detail-value {
  color: #333;
}

.detail-value.vencido {
  color: #dc3545;
  font-weight: bold;
}

.detail-value.urgente {
  color: #ffc107;
  font-weight: bold;
}

.detail-value.concluido {
  color: #28a745;
  font-weight: bold;
}

.product-actions {
  display: flex;
  gap: 10px;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background-color 0.3s;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover {
  background: #0056b3;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #545b62;
}

.btn-info {
  background: #17a2b8;
  color: white;
}

.btn-info:hover {
  background: #138496;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 20px;
}

.loading-state {
  text-align: center;
  padding: 60px 20px;
}

.loader {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #007bff;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  max-width: 500px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eee;
}

.modal-header h3 {
  margin: 0;
  color: #333;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
}

.btn-close:hover {
  color: #333;
}

.modal-body {
  padding: 20px;
}

.product-info-modal {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 20px;
}

.product-info-modal h4 {
  margin: 0 0 10px 0;
  color: #333;
}

.product-info-modal p {
  margin: 0;
  color: #666;
}

.rating-section {
  margin-bottom: 20px;
}

.rating-section label {
  display: block;
  margin-bottom: 10px;
  font-weight: bold;
  color: #333;
}

.stars-rating {
  display: flex;
  gap: 5px;
  margin-bottom: 10px;
}

.star {
  font-size: 1.5rem;
  cursor: pointer;
  transition: opacity 0.3s;
  opacity: 0.3;
}

.star.active {
  opacity: 1;
}

.star:hover {
  opacity: 0.8;
}

.rating-text {
  color: #666;
  font-style: italic;
}

.comment-section label {
  display: block;
  margin-bottom: 10px;
  font-weight: bold;
  color: #333;
}

.comment-section textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-family: inherit;
  resize: vertical;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 20px;
  border-top: 1px solid #eee;
}

.historico-list {
  max-height: 400px;
  overflow-y: auto;
}

.lembrete-item {
  padding: 15px;
  border: 1px solid #eee;
  border-radius: 8px;
  margin-bottom: 10px;
}

.lembrete-item.sucesso {
  background: #f8f9fa;
  border-color: #28a745;
}

.lembrete-item.erro {
  background: #fff5f5;
  border-color: #dc3545;
}

.lembrete-item.teste {
  background: #f3f0ff;
  border-color: #9b59b6;
}

.lembrete-info {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.lembrete-tipo {
  font-weight: bold;
  color: #333;
}

.lembrete-data {
  color: #666;
  font-size: 0.9rem;
}

.lembrete-status {
  display: flex;
  align-items: center;
  gap: 8px;
}

.lembrete-erro {
  margin-top: 10px;
  padding: 8px;
  background: #f8d7da;
  border-radius: 4px;
  color: #721c24;
  font-size: 0.9rem;
}

.empty-historico {
  text-align: center;
  padding: 40px 20px;
  color: #666;
}

/* Responsividade */
@media (max-width: 768px) {
  .notifications-header {
    flex-direction: column;
    gap: 10px;
    align-items: stretch;
  }
  
  .filters {
    flex-direction: column;
    gap: 15px;
  }
  
  .product-header {
    flex-direction: column;
    gap: 10px;
  }
  
  .product-actions {
    flex-direction: column;
  }
  
  .detail-row {
    flex-direction: column;
    gap: 5px;
  }
  
  .modal-content {
    width: 95%;
  }
}
</style>