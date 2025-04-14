<template>
  <div class="dashboard">
    <h2>Dashboard CPM</h2>
    
    <div class="stats-container">
      <div class="stat-card status-pendente-card">
        <h3>Produtos Pendentes</h3>
        <div class="stat-value">{{ pendentes }}</div>
      </div>
      
      <div class="stat-card status-aprovado-card">
        <h3>Produtos Aprovados</h3>
        <div class="stat-value">{{ aprovados }}</div>
      </div>
      
      <div class="stat-card status-reprovado-card">
        <h3>Produtos Reprovados</h3>
        <div class="stat-value">{{ reprovados }}</div>
      </div>
    </div>
    
    <div class="recent-products">
      <h3>Produtos Recentes</h3>
      <table v-if="produtos.length > 0">
        <thead>
          <tr>
            <th>Nome</th>
            <th>Marca</th>
            <th>Status</th>
            <th>Data</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="produto in produtos" :key="produto.id">
            <td>{{ produto.nome }}</td>
            <td>{{ produto.marca }}</td>
            <td>
              <span class="status-badge" :class="getStatusClass(produto.status)">
                {{ produto.status }}
              </span>
            </td>
            <td>{{ formatDate(produto.criado_em) }}</td>
            <td>
              <button @click="verProduto(produto.id)" class="btn-small">Ver</button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else>Nenhum produto cadastrado.</p>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'DashboardCPM',
  data() {
    return {
      produtos: [],
      pendentes: 0,
      aprovados: 0,
      reprovados: 0,
      currentTenantId: null,
      loading: false
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarDados()
    })
  },
  methods: {
    async obterTenantId() {
      try {
        // Tenta obter o tenant_id do usuário logado
        const { data } = await supabase.auth.getSession()
        const user = data?.session?.user
        
        if (!user) {
          console.error('Usuário não está autenticado')
          return
        }
        
        // Primeiro tenta obter dos metadados
        if (user.user_metadata?.tenant_id) {
          this.currentTenantId = user.user_metadata.tenant_id
          console.log('Tenant ID obtido dos metadados:', this.currentTenantId)
          return
        }
        
        // Se não estiver nos metadados, tenta buscar na tabela usuarios
        const { data: userData, error: userError } = await supabase
          .from('usuarios')
          .select('tenant_id')
          .eq('email', user.email)
          .single()
        
        if (userError) {
          console.error('Erro ao buscar tenant_id:', userError)
          return
        }
        
        if (userData?.tenant_id) {
          this.currentTenantId = userData.tenant_id
          console.log('Tenant ID obtido da tabela usuarios:', this.currentTenantId)
        } else {
          console.error('Tenant ID não encontrado para o usuário')
        }
      } catch (error) {
        console.error('Erro ao obter tenant_id:', error)
      }
    },
    async carregarDados() {
      try {
        this.loading = true
        
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível. Tentando recarregar...')
          await this.obterTenantId()
          
          if (!this.currentTenantId) {
            console.error('Não foi possível obter o tenant_id, impossível carregar dados')
            return
          }
        }
        
        console.log('Carregando produtos para tenant_id:', this.currentTenantId)
        
        // Carregar produtos APENAS do tenant atual
        const { data, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId) // Filtrar por tenant_id
          .order('criado_em', { ascending: false })
          .limit(10)
        
        if (error) throw error
        
        this.produtos = data || []
        console.log(`${this.produtos.length} produtos carregados para o tenant atual`)
        
        // Contar por status - também filtrando por tenant_id
        const statsCounts = await Promise.all([
          this.contarPorStatus('pendente'),
          this.contarPorStatus('aprovado'),
          this.contarPorStatus('reprovado')
        ])
        
        this.pendentes = statsCounts[0]
        this.aprovados = statsCounts[1]
        this.reprovados = statsCounts[2]
        
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
      } finally {
        this.loading = false
      }
    },
    async contarPorStatus(status) {
      // Garantir que tenant_id está disponível
      if (!this.currentTenantId) return 0
      
      const { count, error } = await supabase
        .from('produtos')
        .select('id', { count: 'exact' })
        .eq('status', status)
        .eq('tenant_id', this.currentTenantId) // Filtrar por tenant_id
      
      if (error) {
        console.error(`Erro ao contar produtos ${status}:`, error)
        return 0
      }
      
      return count || 0
    },
    formatDate(dateString) {
      if (!dateString) return ''
      const date = new Date(dateString)
      return date.toLocaleDateString('pt-BR')
    },
    getStatusClass(status) {
      switch (status) {
        case 'aprovado': return 'status-aprovado'
        case 'pendente': return 'status-pendente'
        case 'reprovado': return 'status-reprovado'
        default: return ''
      }
    },
    verProduto(id) {
      this.$router.push(`/analise/${id}`)
    }
  }
}
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.stats-container {
  display: flex;
  justify-content: space-between;
  margin-bottom: 30px;
}

.stat-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  flex: 1;
  margin: 0 10px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.stat-card:first-child {
  margin-left: 0;
}

.stat-card:last-child {
  margin-right: 0;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  text-align: center;
  margin-top: 10px;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 15px;
}

th, td {
  padding: 12px 15px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

th {
  background-color: #f5f5f5;
}

.btn-small {
  padding: 5px 10px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.status-badge {
  display: inline-block;
  padding: 5px 10px;
  border-radius: 20px;
  font-size: 12px;
  text-transform: uppercase;
  font-weight: bold;
}

.status-aprovado {
  background-color: #2ecc71;
  color: white;
}

.status-pendente {
  background-color: #f39c12;
  color: white;
}

.status-reprovado {
  background-color: #e74c3c;
  color: white;
}

.status-aprovado-card {
  border-top: 5px solid #2ecc71;
}

.status-pendente-card {
  border-top: 5px solid #f39c12;
}

.status-reprovado-card {
  border-top: 5px solid #e74c3c;
}
</style> 