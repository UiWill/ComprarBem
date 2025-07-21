<template>
  <div class="gerenciador-notificacoes">
    <!-- Cabeçalho -->
    <div class="header-section">
      <h2>📧 Gerenciador de Notificações</h2>
      <p>Controle completo do sistema de emails e lembretes automáticos</p>
    </div>

    <!-- Estatísticas -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon">📊</div>
        <div class="stat-content">
          <h3>{{ estatisticas.usuariosAtivos }}</h3>
          <p>Usuários Ativos</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon">📦</div>
        <div class="stat-content">
          <h3>{{ estatisticas.produtosPendentes }}</h3>
          <p>Produtos Pendentes</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon">⏰</div>
        <div class="stat-content">
          <h3>{{ estatisticas.lembretesPendentes }}</h3>
          <p>Lembretes Pendentes</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon">✅</div>
        <div class="stat-content">
          <h3>{{ estatisticas.avaliacoesPendentes }}</h3>
          <p>Avaliações Pendentes</p>
        </div>
      </div>
    </div>

    <!-- Controles Principais -->
    <div class="controls-section">
      <div class="control-group">
        <h3>🚀 Executar Manualmente</h3>
        <div class="button-group">
          <button 
            @click="executarNotificacaoNovos" 
            :disabled="executando.novos"
            class="btn btn-primary"
          >
            <i class="fas fa-bell"></i>
            {{ executando.novos ? 'Enviando...' : 'Notificar Novos Produtos' }}
          </button>
          
          <button 
            @click="executarLembretes" 
            :disabled="executando.lembretes"
            class="btn btn-warning"
          >
            <i class="fas fa-clock"></i>
            {{ executando.lembretes ? 'Enviando...' : 'Enviar Lembretes' }}
          </button>
          
          <button 
            @click="executarTodas" 
            :disabled="executando.todas"
            class="btn btn-success"
          >
            <i class="fas fa-sync"></i>
            {{ executando.todas ? 'Processando...' : 'Executar Todas' }}
          </button>
        </div>
      </div>

      <div class="control-group">
        <h3>⚙️ Configurações</h3>
        <div class="config-grid">
          <div class="config-item">
            <label>
              <input 
                type="checkbox" 
                v-model="configuracoes.notificacoesAtivas"
                @change="salvarConfiguracoes"
              >
              Sistema de notificações ativo
            </label>
          </div>
          <div class="config-item">
            <label>
              Intervalo de verificação (horas):
              <input 
                type="number" 
                v-model="configuracoes.intervaloHoras"
                @change="salvarConfiguracoes"
                min="1" 
                max="24"
              >
            </label>
          </div>
          <div class="config-item">
            <label>
              Prazo para avaliação (dias):
              <input 
                type="number" 
                v-model="configuracoes.prazoAvaliacaoDias"
                @change="salvarConfiguracoes"
                min="10" 
                max="60"
              >
            </label>
          </div>
        </div>
      </div>
    </div>

    <!-- Histórico de Execuções -->
    <div class="history-section">
      <h3>📋 Histórico de Execuções</h3>
      <div class="history-table">
        <table>
          <thead>
            <tr>
              <th>Data/Hora</th>
              <th>Tipo</th>
              <th>Status</th>
              <th>Enviados</th>
              <th>Erros</th>
              <th>Detalhes</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="execucao in historicoExecucoes" :key="execucao.id">
              <td>{{ formatarDataHora(execucao.dataHora) }}</td>
              <td>
                <span :class="['badge', 'badge-' + execucao.tipo]">
                  {{ execucao.tipoLabel }}
                </span>
              </td>
              <td>
                <span :class="['status', execucao.sucesso ? 'success' : 'error']">
                  {{ execucao.sucesso ? '✅ Sucesso' : '❌ Erro' }}
                </span>
              </td>
              <td>{{ execucao.enviados }}</td>
              <td>{{ execucao.erros }}</td>
              <td>
                <button 
                  @click="verDetalhes(execucao)" 
                  class="btn btn-sm btn-info"
                >
                  Ver
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Usuários Pendentes -->
    <div class="users-section">
      <h3>👥 Usuários com Avaliações Pendentes</h3>
      <div class="users-table">
        <table>
          <thead>
            <tr>
              <th>Nome</th>
              <th>Email</th>
              <th>Unidade/Setor</th>
              <th>Produtos Pendentes</th>
              <th>Dias Atraso</th>
              <th>Último Lembrete</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="usuario in usuariosPendentes" :key="usuario.id">
              <td>{{ usuario.nome }}</td>
              <td>{{ usuario.email }}</td>
              <td>{{ usuario.unidadeSetor }}</td>
              <td>
                <span class="badge badge-warning">
                  {{ usuario.produtosPendentes }}
                </span>
              </td>
              <td>
                <span :class="['days-badge', getDaysClass(usuario.diasAtraso)]">
                  {{ usuario.diasAtraso }} dias
                </span>
              </td>
              <td>{{ usuario.ultimoLembrete || 'Nunca' }}</td>
              <td>
                <button 
                  @click="enviarLembreteManual(usuario)" 
                  class="btn btn-sm btn-warning"
                  :disabled="enviandoLembrete"
                >
                  📧 Lembrete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal de Detalhes -->
    <div v-if="modalDetalhes" class="modal-overlay" @click="fecharModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Detalhes da Execução</h3>
          <button @click="fecharModal" class="btn-close">×</button>
        </div>
        <div class="modal-body">
          <div class="detail-item">
            <strong>Tipo:</strong> {{ modalDetalhes.tipoLabel }}
          </div>
          <div class="detail-item">
            <strong>Data/Hora:</strong> {{ formatarDataHora(modalDetalhes.dataHora) }}
          </div>
          <div class="detail-item">
            <strong>Status:</strong> {{ modalDetalhes.sucesso ? 'Sucesso' : 'Erro' }}
          </div>
          <div class="detail-item">
            <strong>Emails Enviados:</strong> {{ modalDetalhes.enviados }}
          </div>
          <div class="detail-item">
            <strong>Erros:</strong> {{ modalDetalhes.erros }}
          </div>
          <div class="detail-item">
            <strong>Mensagem:</strong> {{ modalDetalhes.mensagem }}
          </div>
          <div v-if="modalDetalhes.detalhesCompletos" class="detail-item">
            <strong>Detalhes Completos:</strong>
            <pre>{{ modalDetalhes.detalhesCompletos }}</pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { 
  processarNovosProdutosPendentes, 
  processarLembretesAvaliacao, 
  iniciarSistemaNotificacoes,
  enviarLembreteAvaliacao
} from '@/services/emailService'
import { supabase } from '@/services/supabase'

export default {
  name: 'GerenciadorNotificacoes',
  data() {
    return {
      estatisticas: {
        usuariosAtivos: 0,
        produtosPendentes: 0,
        lembretesPendentes: 0,
        avaliacoesPendentes: 0
      },
      configuracoes: {
        notificacoesAtivas: true,
        intervaloHoras: 2,
        prazoAvaliacaoDias: 30
      },
      executando: {
        novos: false,
        lembretes: false,
        todas: false
      },
      historicoExecucoes: [],
      usuariosPendentes: [],
      modalDetalhes: null,
      enviandoLembrete: false,
      intervaloAtualizacao: null
    }
  },
  async mounted() {
    await this.carregarDados()
    this.iniciarSistemaAutomatico()
    this.iniciarAtualizacaoAutomatica()
  },
  beforeUnmount() {
    if (this.intervaloAtualizacao) {
      clearInterval(this.intervaloAtualizacao)
    }
  },
  methods: {
    async carregarDados() {
      try {
        await Promise.all([
          this.carregarEstatisticas(),
          this.carregarConfiguracoes(),
          this.carregarHistoricoExecucoes(),
          this.carregarUsuariosPendentes()
        ])
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
        this.$swal.fire('Erro', 'Erro ao carregar dados do sistema', 'error')
      }
    },

    async carregarEstatisticas() {
      try {
        // Carregar estatísticas do banco
        const { data: usuarios } = await supabase
          .from('usuarios_rdm')
          .select('count(*)')
          .eq('ativo', true)

        const { data: produtosPendentes } = await supabase
          .from('usuarios_rdm_produtos')
          .select('count(*)')
          .eq('notificado_email', false)

        const { data: avaliacoesPendentes } = await supabase
          .from('usuarios_rdm_produtos')
          .select('count(*)')
          .eq('avaliado', false)

        this.estatisticas.usuariosAtivos = usuarios?.[0]?.count || 0
        this.estatisticas.produtosPendentes = produtosPendentes?.[0]?.count || 0
        this.estatisticas.avaliacoesPendentes = avaliacoesPendentes?.[0]?.count || 0

        // Lembretes pendentes - calcular baseado em dias
        const { data: lembretes } = await supabase
          .rpc('verificar_rdms_lembretes_avaliacao')

        this.estatisticas.lembretesPendentes = lembretes?.length || 0

      } catch (error) {
        console.error('Erro ao carregar estatísticas:', error)
      }
    },

    async carregarConfiguracoes() {
      try {
        const configs = localStorage.getItem('configuracoes_notificacoes')
        if (configs) {
          this.configuracoes = { ...this.configuracoes, ...JSON.parse(configs) }
        }
      } catch (error) {
        console.error('Erro ao carregar configurações:', error)
      }
    },

    async salvarConfiguracoes() {
      try {
        localStorage.setItem('configuracoes_notificacoes', JSON.stringify(this.configuracoes))
        this.$swal.fire('Sucesso', 'Configurações salvas com sucesso!', 'success')
      } catch (error) {
        console.error('Erro ao salvar configurações:', error)
        this.$swal.fire('Erro', 'Erro ao salvar configurações', 'error')
      }
    },

    async carregarHistoricoExecucoes() {
      try {
        const historico = localStorage.getItem('historico_execucoes_notificacoes')
        if (historico) {
          this.historicoExecucoes = JSON.parse(historico).slice(0, 10) // Últimas 10
        }
      } catch (error) {
        console.error('Erro ao carregar histórico:', error)
      }
    },

    async carregarUsuariosPendentes() {
      try {
        const { data: usuarios } = await supabase
          .from('vw_avaliacoes_pendentes')
          .select('*')
          .eq('avaliado', false)
          .gte('dias_desde_recebimento', 10)
          .order('dias_desde_recebimento', { ascending: false })

        this.usuariosPendentes = usuarios?.map(u => ({
          id: u.id,
          nome: u.nome_usuario,
          email: u.email,
          unidadeSetor: u.unidade_setor,
          produtosPendentes: 1, // Simplificado
          diasAtraso: u.dias_desde_recebimento,
          ultimoLembrete: null // Implementar busca de último lembrete
        })) || []

      } catch (error) {
        console.error('Erro ao carregar usuários pendentes:', error)
      }
    },

    async executarNotificacaoNovos() {
      this.executando.novos = true
      try {
        const resultado = await processarNovosProdutosPendentes()
        
        this.adicionarAoHistorico({
          tipo: 'novos',
          tipoLabel: 'Novos Produtos',
          sucesso: resultado.success,
          enviados: resultado.sucessos || 0,
          erros: resultado.erros || 0,
          mensagem: resultado.message,
          detalhesCompletos: JSON.stringify(resultado, null, 2)
        })

        if (resultado.success) {
          this.$swal.fire('Sucesso', resultado.message, 'success')
        } else {
          this.$swal.fire('Erro', resultado.message, 'error')
        }

        await this.carregarEstatisticas()
      } catch (error) {
        console.error('Erro ao executar notificação de novos:', error)
        this.$swal.fire('Erro', 'Erro ao executar notificação de novos produtos', 'error')
      } finally {
        this.executando.novos = false
      }
    },

    async executarLembretes() {
      this.executando.lembretes = true
      try {
        const resultado = await processarLembretesAvaliacao()
        
        this.adicionarAoHistorico({
          tipo: 'lembretes',
          tipoLabel: 'Lembretes',
          sucesso: resultado.success,
          enviados: resultado.sucessos || 0,
          erros: resultado.erros || 0,
          mensagem: resultado.message,
          detalhesCompletos: JSON.stringify(resultado, null, 2)
        })

        if (resultado.success) {
          this.$swal.fire('Sucesso', resultado.message, 'success')
        } else {
          this.$swal.fire('Erro', resultado.message, 'error')
        }

        await this.carregarEstatisticas()
        await this.carregarUsuariosPendentes()
      } catch (error) {
        console.error('Erro ao executar lembretes:', error)
        this.$swal.fire('Erro', 'Erro ao executar lembretes', 'error')
      } finally {
        this.executando.lembretes = false
      }
    },

    async executarTodas() {
      this.executando.todas = true
      try {
        await this.executarNotificacaoNovos()
        await this.executarLembretes()
        
        this.$swal.fire('Sucesso', 'Todas as notificações foram processadas!', 'success')
      } catch (error) {
        console.error('Erro ao executar todas:', error)
        this.$swal.fire('Erro', 'Erro ao executar todas as notificações', 'error')
      } finally {
        this.executando.todas = false
      }
    },

    async enviarLembreteManual(usuario) {
      this.enviandoLembrete = true
      try {
        const dadosLembrete = {
          tipo_lembrete: usuario.diasAtraso >= 30 ? '30_DIAS' : usuario.diasAtraso >= 20 ? '20_DIAS' : '10_DIAS',
          material_nome: 'Produto para Avaliação',
          material_codigo: 'MANUAL-' + usuario.id,
          dias_desde_aprovacao: usuario.diasAtraso,
          usuario_nome: usuario.nome,
          usuario_email: usuario.email,
          unidade_setor: usuario.unidadeSetor
        }

        const resultado = await enviarLembreteAvaliacao(dadosLembrete)
        
        if (resultado.success) {
          this.$swal.fire('Sucesso', 'Lembrete enviado com sucesso!', 'success')
        } else {
          this.$swal.fire('Erro', resultado.message, 'error')
        }
      } catch (error) {
        console.error('Erro ao enviar lembrete manual:', error)
        this.$swal.fire('Erro', 'Erro ao enviar lembrete', 'error')
      } finally {
        this.enviandoLembrete = false
      }
    },

    adicionarAoHistorico(execucao) {
      const novaExecucao = {
        id: Date.now(),
        dataHora: new Date(),
        ...execucao
      }
      
      this.historicoExecucoes.unshift(novaExecucao)
      this.historicoExecucoes = this.historicoExecucoes.slice(0, 10)
      
      // Salvar no localStorage
      try {
        localStorage.setItem('historico_execucoes_notificacoes', JSON.stringify(this.historicoExecucoes))
      } catch (error) {
        console.error('Erro ao salvar histórico:', error)
      }
    },

    iniciarSistemaAutomatico() {
      if (this.configuracoes.notificacoesAtivas) {
        iniciarSistemaNotificacoes()
      }
    },

    iniciarAtualizacaoAutomatica() {
      // Atualizar dados a cada 5 minutos
      this.intervaloAtualizacao = setInterval(() => {
        this.carregarEstatisticas()
        this.carregarUsuariosPendentes()
      }, 5 * 60 * 1000)
    },

    verDetalhes(execucao) {
      this.modalDetalhes = execucao
    },

    fecharModal() {
      this.modalDetalhes = null
    },

    formatarDataHora(dataHora) {
      return new Date(dataHora).toLocaleString('pt-BR')
    },

    getDaysClass(dias) {
      if (dias >= 30) return 'danger'
      if (dias >= 20) return 'warning'
      return 'info'
    }
  }
}
</script>

<style scoped>
.gerenciador-notificacoes {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.header-section {
  text-align: center;
  margin-bottom: 30px;
}

.header-section h2 {
  color: #2c3e50;
  margin-bottom: 10px;
}

.header-section p {
  color: #7f8c8d;
  font-size: 16px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  display: flex;
  align-items: center;
  gap: 15px;
}

.stat-icon {
  font-size: 2em;
  background: #f8f9fa;
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
}

.stat-content h3 {
  margin: 0;
  font-size: 2em;
  color: #2c3e50;
}

.stat-content p {
  margin: 0;
  color: #7f8c8d;
}

.controls-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  margin-bottom: 30px;
}

.control-group {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.control-group h3 {
  margin-top: 0;
  color: #2c3e50;
}

.button-group {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2980b9;
}

.btn-warning {
  background: #f39c12;
  color: white;
}

.btn-warning:hover:not(:disabled) {
  background: #e67e22;
}

.btn-success {
  background: #27ae60;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #229954;
}

.btn-info {
  background: #17a2b8;
  color: white;
}

.btn-sm {
  padding: 5px 10px;
  font-size: 0.8em;
}

.config-grid {
  display: grid;
  gap: 15px;
}

.config-item label {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: normal;
}

.config-item input[type="number"] {
  width: 80px;
  padding: 5px;
  border: 1px solid #ddd;
  border-radius: 3px;
}

.history-section,
.users-section {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.history-section h3,
.users-section h3 {
  margin-top: 0;
  color: #2c3e50;
}

.history-table,
.users-table {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
}

th, td {
  padding: 12px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

th {
  background: #f8f9fa;
  font-weight: bold;
  color: #2c3e50;
}

.badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;
}

.badge-novos {
  background: #d4edda;
  color: #155724;
}

.badge-lembretes {
  background: #fff3cd;
  color: #856404;
}

.badge-warning {
  background: #fff3cd;
  color: #856404;
}

.status.success {
  color: #28a745;
}

.status.error {
  color: #dc3545;
}

.days-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;
}

.days-badge.info {
  background: #d1ecf1;
  color: #0c5460;
}

.days-badge.warning {
  background: #fff3cd;
  color: #856404;
}

.days-badge.danger {
  background: #f8d7da;
  color: #721c24;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  padding: 0;
  border-radius: 10px;
  max-width: 600px;
  width: 90%;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #ddd;
}

.modal-header h3 {
  margin: 0;
  color: #2c3e50;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-body {
  padding: 20px;
}

.detail-item {
  margin-bottom: 15px;
}

.detail-item strong {
  color: #2c3e50;
}

.detail-item pre {
  background: #f8f9fa;
  padding: 10px;
  border-radius: 5px;
  overflow-x: auto;
  font-size: 12px;
}

@media (max-width: 768px) {
  .controls-section {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .button-group {
    flex-direction: column;
  }
}
</style>