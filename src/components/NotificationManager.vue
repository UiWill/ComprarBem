<template>
  <div class="notification-manager">
    <!-- Painel de Controle -->
    <div class="control-panel">
      <h3>🔔 Sistema de Notificações</h3>
      
      <!-- Botões de Ação -->
      <div class="action-buttons">
        <button 
          @click="processarNovosprodutos" 
          :disabled="processando"
          class="btn btn-primary"
        >
          📦 Processar Novos Produtos
        </button>
        
        <button 
          @click="processarLembretes" 
          :disabled="processando"
          class="btn btn-warning"
        >
          ⏰ Processar Lembretes
        </button>
        
        <button 
          @click="obterEstatisticas" 
          :disabled="processando"
          class="btn btn-info"
        >
          📊 Atualizar Estatísticas
        </button>
      </div>
      
      <!-- Status do Sistema -->
      <div class="system-status">
        <div class="status-item">
          <span class="status-label">Sistema:</span>
          <span class="status-badge active">
            🚀 Automático via GitHub Actions
          </span>
        </div>
        
        <div class="status-item">
          <span class="status-label">Frequência:</span>
          <span class="status-value">A cada 30 minutos</span>
        </div>
        
        <div class="status-item">
          <span class="status-label">Última Execução:</span>
          <span class="status-value">{{ ultimaExecucao || 'Verificando...' }}</span>
        </div>
      </div>
    </div>

    <!-- Estatísticas -->
    <div class="statistics-panel" v-if="estatisticas">
      <h4>📊 Estatísticas do Sistema</h4>
      
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-number">{{ estatisticas.produtosVinculados }}</div>
          <div class="stat-label">Produtos Vinculados</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-number">{{ estatisticas.produtosAvaliados }}</div>
          <div class="stat-label">Produtos Avaliados</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-number">{{ estatisticas.produtosPendentes }}</div>
          <div class="stat-label">Pendentes Avaliação</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-number">{{ estatisticas.lembretesEnviados }}</div>
          <div class="stat-label">Lembretes Enviados</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-number">{{ estatisticas.taxaAvaliacao }}%</div>
          <div class="stat-label">Taxa de Avaliação</div>
        </div>
      </div>
      
      <!-- Detalhes por Tipo de Lembrete -->
      <div class="reminder-breakdown">
        <h5>📈 Lembretes por Tipo</h5>
        <div class="reminder-stats">
          <div class="reminder-stat">
            <span class="reminder-type">5 Minutos (Teste):</span>
            <span class="reminder-count test">{{ estatisticas.lembretes5Minutos || 0 }}</span>
          </div>
          <div class="reminder-stat">
            <span class="reminder-type">10 Dias:</span>
            <span class="reminder-count">{{ estatisticas.lembretes10Dias }}</span>
          </div>
          <div class="reminder-stat">
            <span class="reminder-type">20 Dias:</span>
            <span class="reminder-count">{{ estatisticas.lembretes20Dias }}</span>
          </div>
          <div class="reminder-stat">
            <span class="reminder-type">30 Dias:</span>
            <span class="reminder-count">{{ estatisticas.lembretes30Dias }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Log de Atividades -->
    <div class="activity-log">
      <h4>📝 Log de Atividades</h4>
      <div class="log-entries">
        <div 
          v-for="(entry, index) in logEntries" 
          :key="index"
          :class="['log-entry', entry.type]"
        >
          <span class="log-time">{{ formatTime(entry.timestamp) }}</span>
          <span class="log-message">{{ entry.message }}</span>
        </div>
      </div>
    </div>

    <!-- Modal de Processamento -->
    <div v-if="processando" class="processing-modal">
      <div class="modal-content">
        <div class="loader"></div>
        <p>{{ mensagemProcessamento }}</p>
      </div>
    </div>
  </div>
</template>

<script>
import { 
  processarNovosProdutosPendentes,
  processarLembretesAvaliacao,
  obterEstatisticasNotificacoes,
  iniciarSistemaNotificacoes
} from '@/services/emailService'

export default {
  name: 'NotificationManager',
  
  data() {
    return {
      processando: false,
      mensagemProcessamento: '',
      sistemaAtivo: false,
      ultimaExecucao: null,
      estatisticas: null,
      logEntries: [],
      intervaloEstatisticas: null
    }
  },
  
  mounted() {
    this.inicializarSistema()
    this.obterEstatisticas()
    
    // Atualizar estatísticas a cada 5 minutos
    this.intervaloEstatisticas = setInterval(() => {
      this.obterEstatisticas()
    }, 5 * 60 * 1000)
  },
  
  beforeUnmount() {
    if (this.intervaloEstatisticas) {
      clearInterval(this.intervaloEstatisticas)
    }
  },
  
  methods: {
    async inicializarSistema() {
      try {
        this.adicionarLog('Sistema de notificações iniciado', 'info')
        
        // Iniciar o sistema automático
        iniciarSistemaNotificacoes()
        this.sistemaAtivo = true
        
        this.adicionarLog('Sistema automático ativado (verifica a cada 2 horas)', 'success')
      } catch (error) {
        this.adicionarLog(`Erro ao iniciar sistema: ${error.message}`, 'error')
      }
    },
    
    async processarNovosprodutos() {
      this.processando = true
      this.mensagemProcessamento = 'Processando novos produtos...'
      
      try {
        this.adicionarLog('Iniciando processamento de novos produtos...', 'info')
        
        const resultado = await processarNovosProdutosPendentes()
        
        if (resultado.success) {
          this.adicionarLog(
            `Processamento concluído: ${resultado.sucessos} enviados, ${resultado.erros} erros`, 
            'success'
          )
          this.ultimaExecucao = new Date().toLocaleString('pt-BR')
        } else {
          this.adicionarLog(`Erro no processamento: ${resultado.message}`, 'error')
        }
        
        // Atualizar estatísticas
        await this.obterEstatisticas()
        
      } catch (error) {
        this.adicionarLog(`Erro no processamento: ${error.message}`, 'error')
      } finally {
        this.processando = false
      }
    },
    
    async processarLembretes() {
      this.processando = true
      this.mensagemProcessamento = 'Processando lembretes de avaliação...'
      
      try {
        this.adicionarLog('Iniciando processamento de lembretes...', 'info')
        
        const resultado = await processarLembretesAvaliacao()
        
        if (resultado.success) {
          this.adicionarLog(
            `Lembretes processados: ${resultado.sucessos} enviados, ${resultado.erros} erros`, 
            'success'
          )
          this.ultimaExecucao = new Date().toLocaleString('pt-BR')
        } else {
          this.adicionarLog(`Erro no processamento: ${resultado.message}`, 'error')
        }
        
        // Atualizar estatísticas
        await this.obterEstatisticas()
        
      } catch (error) {
        this.adicionarLog(`Erro no processamento: ${error.message}`, 'error')
      } finally {
        this.processando = false
      }
    },
    
    async obterEstatisticas() {
      try {
        const resultado = await obterEstatisticasNotificacoes()
        
        if (resultado.success) {
          this.estatisticas = resultado.estatisticas
        } else {
          this.adicionarLog(`Erro ao obter estatísticas: ${resultado.message}`, 'error')
        }
        
      } catch (error) {
        this.adicionarLog(`Erro ao obter estatísticas: ${error.message}`, 'error')
      }
    },
    
    adicionarLog(message, type = 'info') {
      const entry = {
        timestamp: new Date(),
        message,
        type
      }
      
      this.logEntries.unshift(entry)
      
      // Manter apenas os últimos 50 logs
      if (this.logEntries.length > 50) {
        this.logEntries = this.logEntries.slice(0, 50)
      }
      
      console.log(`[${type.toUpperCase()}] ${message}`)
    },
    
    formatTime(timestamp) {
      return timestamp.toLocaleTimeString('pt-BR', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })
    }
  }
}
</script>

<style scoped>
.notification-manager {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.control-panel {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.control-panel h3 {
  margin: 0 0 20px 0;
  color: #333;
}

.action-buttons {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-weight: bold;
  transition: background-color 0.3s;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #0056b3;
}

.btn-warning {
  background: #ffc107;
  color: #212529;
}

.btn-warning:hover:not(:disabled) {
  background: #e0a800;
}

.btn-info {
  background: #17a2b8;
  color: white;
}

.btn-info:hover:not(:disabled) {
  background: #138496;
}

.system-status {
  display: flex;
  gap: 30px;
  align-items: center;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.status-label {
  font-weight: bold;
  color: #666;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: bold;
}

.status-badge.active {
  background: #d4edda;
  color: #155724;
}

.status-badge.inactive {
  background: #f8d7da;
  color: #721c24;
}

.statistics-panel {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.statistics-panel h4 {
  margin: 0 0 20px 0;
  color: #333;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 15px;
  margin-bottom: 20px;
}

.stat-card {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  border-left: 4px solid #007bff;
}

.stat-number {
  font-size: 2rem;
  font-weight: bold;
  color: #007bff;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 0.9rem;
  color: #666;
}

.reminder-breakdown {
  border-top: 1px solid #eee;
  padding-top: 20px;
}

.reminder-breakdown h5 {
  margin: 0 0 15px 0;
  color: #333;
}

.reminder-stats {
  display: flex;
  gap: 30px;
}

.reminder-stat {
  display: flex;
  align-items: center;
  gap: 10px;
}

.reminder-type {
  font-weight: bold;
  color: #666;
}

.reminder-count {
  background: #007bff;
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8rem;
}

.reminder-count.test {
  background: #9b59b6;
  color: white;
}

.activity-log {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.activity-log h4 {
  margin: 0 0 20px 0;
  color: #333;
}

.log-entries {
  max-height: 400px;
  overflow-y: auto;
}

.log-entry {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
  border-bottom: 1px solid #eee;
}

.log-entry:last-child {
  border-bottom: none;
}

.log-time {
  font-size: 0.8rem;
  color: #999;
  font-family: monospace;
  width: 80px;
  flex-shrink: 0;
}

.log-message {
  flex: 1;
  font-size: 0.9rem;
}

.log-entry.success .log-message {
  color: #28a745;
}

.log-entry.error .log-message {
  color: #dc3545;
}

.log-entry.warning .log-message {
  color: #ffc107;
}

.log-entry.info .log-message {
  color: #17a2b8;
}

.processing-modal {
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
  padding: 40px;
  border-radius: 8px;
  text-align: center;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
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

/* Responsividade */
@media (max-width: 768px) {
  .action-buttons {
    flex-direction: column;
  }
  
  .system-status {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .reminder-stats {
    flex-direction: column;
    gap: 10px;
  }
}
</style>