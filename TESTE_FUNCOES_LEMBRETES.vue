<template>
  <div class="teste-lembretes">
    <h1>🧪 Teste Sistema de Lembretes</h1>
    
    <div class="buttons">
      <button @click="carregarEstatisticasLembretes" class="btn-test">
        📊 Carregar Estatísticas
      </button>
      
      <button @click="carregarRdmsPendentes" class="btn-test">
        📋 Carregar RDMs Pendentes
      </button>
      
      <button @click="ativarSistemaLembretes" class="btn-test">
        🚀 Ativar Sistema
      </button>
      
      <button @click="processarLembretesManual" class="btn-test">
        📧 Processar Lembretes
      </button>
    </div>
    
    <div class="results">
      <h3>📊 Estatísticas:</h3>
      <pre>{{ JSON.stringify(estatisticasLembretes, null, 2) }}</pre>
      
      <h3>📋 RDMs Pendentes:</h3>
      <pre>{{ rdmsPendentes.length }} encontradas</pre>
      
      <h3>📝 Log:</h3>
      <div v-for="log in logLembretes" :key="log.id">
        {{ log.timestamp }} - {{ log.level }} - {{ log.message }}
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'TesteFuncoesLembretes',
  data() {
    return {
      estatisticasLembretes: {
        total_enviados: 0,
        lembretes_15_dias: 0,
        lembretes_25_dias: 0,
        lembretes_30_dias_urgente: 0,
        com_erro: 0
      },
      rdmsPendentes: [],
      logLembretes: []
    }
  },
  methods: {
    async carregarEstatisticasLembretes() {
      try {
        console.log('📊 Carregando estatísticas de lembretes...')
        this.adicionarLogLembrete('info', '📊 Carregando estatísticas...')
        
        const { data, error } = await supabase
          .from('v_estatisticas_lembretes')
          .select('*')
          .order('data', { ascending: false })
          .limit(1)
          .single()
        
        if (error && error.code !== 'PGRST116') {
          console.error('❌ Erro ao carregar estatísticas:', error)
          this.adicionarLogLembrete('error', `Erro: ${error.message}`)
          return
        }
        
        if (data) {
          this.estatisticasLembretes = {
            total_enviados: data.total_lembretes_enviados || 0,
            lembretes_15_dias: data.lembretes_15_dias || 0,
            lembretes_25_dias: data.lembretes_25_dias || 0,
            lembretes_30_dias_urgente: data.lembretes_30_dias_urgente || 0,
            com_erro: data.lembretes_com_erro || 0
          }
        }
        
        console.log('✅ Estatísticas carregadas:', this.estatisticasLembretes)
        this.adicionarLogLembrete('success', '✅ Estatísticas carregadas com sucesso!')
        
      } catch (error) {
        console.error('❌ Erro ao carregar estatísticas:', error)
        this.adicionarLogLembrete('error', `Erro: ${error.message}`)
      }
    },

    async carregarRdmsPendentes() {
      try {
        console.log('📋 Carregando RDMs pendentes de feedback...')
        this.adicionarLogLembrete('info', '📋 Carregando RDMs pendentes...')
        
        const { data, error } = await supabase
          .from('v_rdms_pendentes_feedback')
          .select('*')
          .order('dias_desde_aprovacao', { ascending: false })
        
        if (error) {
          console.error('❌ Erro ao carregar RDMs pendentes:', error)
          this.adicionarLogLembrete('error', `Erro: ${error.message}`)
          return
        }
        
        this.rdmsPendentes = data || []
        console.log(`✅ ${this.rdmsPendentes.length} RDMs pendentes carregadas`)
        this.adicionarLogLembrete('success', `✅ ${this.rdmsPendentes.length} RDMs pendentes carregadas`)
        
      } catch (error) {
        console.error('❌ Erro ao carregar RDMs pendentes:', error)
        this.adicionarLogLembrete('error', `Erro: ${error.message}`)
      }
    },

    async ativarSistemaLembretes() {
      try {
        this.adicionarLogLembrete('info', '🤖 Ativando sistema automático de lembretes...')
        
        // Importar e iniciar o sistema de lembretes
        const { iniciarSistemaLembretes } = await import('../../services/emailService')
        iniciarSistemaLembretes()
        
        this.adicionarLogLembrete('success', '✅ Sistema de lembretes ativado! Verificação automática a cada 4 horas.')
        
      } catch (error) {
        console.error('❌ Erro ao ativar sistema:', error)
        this.adicionarLogLembrete('error', `❌ Erro ao ativar sistema: ${error.message}`)
      }
    },

    async processarLembretesManual() {
      try {
        this.adicionarLogLembrete('info', '📧 Iniciando processamento manual de lembretes...')
        
        // Importar e executar processamento
        const { processarLembretesPendentes } = await import('../../services/emailService')
        const resultado = await processarLembretesPendentes()
        
        if (resultado.success) {
          this.adicionarLogLembrete('success', `✅ ${resultado.message}`)
          
          // Atualizar estatísticas e dados
          await this.carregarEstatisticasLembretes()
          await this.carregarRdmsPendentes()
          
        } else {
          this.adicionarLogLembrete('error', `❌ Erro: ${resultado.message}`)
        }
        
      } catch (error) {
        console.error('❌ Erro no processamento manual:', error)
        this.adicionarLogLembrete('error', `❌ Erro no processamento: ${error.message}`)
      }
    },

    adicionarLogLembrete(level, message) {
      const novoLog = {
        id: Date.now(),
        timestamp: new Date().toLocaleTimeString(),
        level: level,
        message: message
      }
      
      this.logLembretes.unshift(novoLog)
      
      // Manter apenas os últimos 10 logs
      if (this.logLembretes.length > 10) {
        this.logLembretes = this.logLembretes.slice(0, 10)
      }
    }
  }
}
</script>

<style scoped>
.teste-lembretes {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
}

.buttons {
  display: flex;
  gap: 10px;
  margin: 20px 0;
  flex-wrap: wrap;
}

.btn-test {
  padding: 10px 15px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

.btn-test:hover {
  background: #0056b3;
}

.results {
  margin-top: 20px;
}

.results h3 {
  color: #333;
  margin-top: 20px;
}

.results pre {
  background: #f8f9fa;
  padding: 10px;
  border-radius: 5px;
  overflow-x: auto;
}
</style> 