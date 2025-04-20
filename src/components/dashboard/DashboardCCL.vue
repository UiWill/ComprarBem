<template>
  <div class="dashboard">
    <h2>Painel de Comissão de Contratação ou Licitação</h2>
    
    <div class="tabs">
      <div 
        class="tab" 
        :class="{ active: activeTab === 'dashboard' }" 
        @click="activeTab = 'dashboard'"
      >
        Dashboard
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'atas' }" 
        @click="activeTab = 'atas'"
      >
        Atas de Julgamento
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'homologacoes' }" 
        @click="activeTab = 'homologacoes'"
      >
        Homologações
      </div>
    </div>
    
    <!-- Aba Dashboard -->
    <div v-if="activeTab === 'dashboard'">
      <div class="stats-container">
        <div class="stat-card status-pendente-card">
          <h3>Processos Aguardando Julgamento</h3>
          <div class="stat-value">{{ pendentes }}</div>
        </div>
        
        <div class="stat-card status-aprovado-card">
          <h3>Homologações</h3>
          <div class="stat-value">{{ aprovados }}</div>
        </div>
        
        <div class="stat-card status-diligencia-card">
          <h3>Processos com Diligências</h3>
          <div class="stat-value">{{ diligencias }}</div>
        </div>
      </div>
      
      <div class="dashboard-section">
        <h3>Processos Pendentes de Julgamento</h3>
        <table v-if="produtosPendentes.length > 0">
          <thead>
            <tr>
              <th>Nome</th>
              <th>Marca</th>
              <th>Categoria</th>
              <th>Status</th>
              <th>Data</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="produto in produtosPendentes" :key="produto.id">
              <td>{{ produto.nome }}</td>
              <td>{{ produto.marca }}</td>
              <td>{{ getCategoriaName(produto.categoria_id) }}</td>
              <td>
                <span class="status-badge" :class="getStatusClass(produto.status)">
                  {{ formatarStatus(produto.status) }}
                </span>
              </td>
              <td>{{ formatDate(produto.criado_em) }}</td>
              <td>
                <button @click="publicarDecisao(produto.id)" class="btn-small">Julgamento</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Não há processos pendentes de julgamento.</p>
      </div>
      
      <div class="dashboard-section">
        <h3>Atas de Julgamento Recentes</h3>
        <table v-if="atasRecentes.length > 0">
          <thead>
            <tr>
              <th>Número da Ata</th>
              <th>Produto</th>
              <th>Decisão</th>
              <th>Data de Publicação</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ata in atasRecentes" :key="ata.id">
              <td>{{ ata.numero }}</td>
              <td>{{ ata.produto_nome }}</td>
              <td>
                <span class="status-badge" :class="getStatusClass(ata.decisao)">
                  {{ formatarStatus(ata.decisao) }}
                </span>
              </td>
              <td>{{ formatDate(ata.data_publicacao) }}</td>
              <td>
                <button @click="visualizarAta(ata.id)" class="btn-small">Visualizar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Não há atas de julgamento recentes.</p>
      </div>
      
      <div class="dashboard-section">
        <h3>Recursos Apresentados</h3>
        <table v-if="recursos.length > 0">
          <thead>
            <tr>
              <th>Recorrente</th>
              <th>Produto</th>
              <th>Data do Recurso</th>
              <th>Status</th>
              <th>Prazo Final</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="recurso in recursos" :key="recurso.id">
              <td>{{ recurso.recorrente }}</td>
              <td>{{ recurso.produto_nome }}</td>
              <td>{{ formatDate(recurso.data_recurso) }}</td>
              <td>
                <span class="status-badge" :class="getRecursoStatusClass(recurso.status)">
                  {{ recurso.status }}
                </span>
              </td>
              <td>{{ formatDate(recurso.prazo_final) }}</td>
              <td>
                <button @click="julgarRecurso(recurso.id)" class="btn-small">Julgar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Não há recursos apresentados.</p>
      </div>
    </div>
    
    <!-- Aba Atas de Julgamento -->
    <div v-if="activeTab === 'atas'" class="atas-julgamento">
      <div class="info-card">
        <h3>Atas de Julgamento</h3>
        <p>Este módulo permitirá o gerenciamento completo das atas de julgamento emitidas pela Comissão de Contratação ou Licitação.</p>
        <p>Funcionalidades que serão implementadas:</p>
        <ul>
          <li>Cadastro e edição de atas de julgamento</li>
          <li>Publicação automática no Diário Oficial</li>
          <li>Comunicação com fornecedores interessados</li>
          <li>Histórico de alterações e versões</li>
          <li>Geração de relatórios consolidados</li>
          <li>Integração com sistema de processo eletrônico</li>
        </ul>
        <div class="em-desenvolvimento">
          <span>Em desenvolvimento</span>
        </div>
      </div>
    </div>
    
    <!-- Aba Homologações -->
    <div v-if="activeTab === 'homologacoes'" class="homologacoes">
      <div class="info-card">
        <h3>Homologações</h3>
        <p>Este módulo permitirá o acesso a todos os arquivos em PDF de atos de homologação assinados digitalmente pela autoridade competente do órgão ou entidade.</p>
        <p>Funcionalidades que serão implementadas:</p>
        <ul>
          <li>Acesso aos documentos de homologação de padronizações de marcas e modelos</li>
          <li>Acesso aos documentos de despadronizações</li>
          <li>Registro de decisões da autoridade competente</li>
          <li>Emissão de certificados de homologação</li>
          <li>Controle de prazos de validade</li>
          <li>Notificação automática de homologações e indeferimentos</li>
        </ul>
        <div class="em-desenvolvimento">
          <span>Em desenvolvimento</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'DashboardCCL',
  data() {
    return {
      activeTab: 'dashboard',
      produtosPendentes: [],
      atasRecentes: [],
      pendentes: 0,
      aprovados: 0,
      diligencias: 0,
      categorias: [],
      currentTenantId: null,
      loading: false,
      recursos: []
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarDados()
      this.carregarCategorias()
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
        } else {
          console.error('Tenant ID não encontrado para o usuário')
        }
      } catch (error) {
        console.error('Erro ao obter tenant_id:', error)
      }
    },
    async carregarCategorias() {
      try {
        const { data, error } = await supabase
          .from('categorias')
          .select('*')
        
        if (error) throw error
        
        this.categorias = data || []
      } catch (error) {
        console.error('Erro ao carregar categorias:', error)
      }
    },
    getCategoriaName(categoriaId) {
      const categoria = this.categorias.find(cat => cat.id === categoriaId)
      return categoria ? categoria.nome : 'Categoria não encontrada'
    },
    async carregarDados() {
      try {
        this.loading = true
        
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível')
          return
        }
        
        // Carregar produtos pendentes
        const { data: pendentesData, error: pendentesError } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['aprovado', 'reprovado']) // produtos já analisados pela CPM, pendentes de julgamento pela CCL
          .order('criado_em', { ascending: false })
          .limit(10)
        
        if (pendentesError) throw pendentesError
        
        this.produtosPendentes = pendentesData || []
        
        // Dados simulados para atas de julgamento (em uma implementação real, estaria em uma tabela específica)
        this.atasRecentes = [
          {
            id: '1',
            numero: 'ATA-001/2023',
            produto_nome: 'Monitor de Sinais Vitais',
            decisao: 'aprovado',
            data_publicacao: '2023-05-15'
          },
          {
            id: '2',
            numero: 'ATA-002/2023',
            produto_nome: 'Desfibrilador',
            decisao: 'diligencia',
            data_publicacao: '2023-05-20'
          },
          {
            id: '3',
            numero: 'ATA-003/2023',
            produto_nome: 'Autoclave Hospitalar',
            decisao: 'aprovado',
            data_publicacao: '2023-06-01'
          }
        ]
        
        // Dados simulados para recursos (em uma implementação real, estaria em uma tabela específica)
        this.recursos = [
          {
            id: '1',
            recorrente: 'Hospital Médico LTDA',
            produto_nome: 'Desfibrilador',
            data_recurso: '2023-05-22',
            status: 'EM ANÁLISE',
            prazo_final: '2023-06-06'
          },
          {
            id: '2',
            recorrente: 'Equipamentos Hospitalares S.A.',
            produto_nome: 'Bomba de Infusão',
            data_recurso: '2023-06-05',
            status: 'DEFERIDO',
            prazo_final: '2023-06-20'
          },
          {
            id: '3',
            recorrente: 'Medical Suprimentos Médicos',
            produto_nome: 'Ventilador Pulmonar',
            data_recurso: '2023-06-10',
            status: 'INDEFERIDO',
            prazo_final: '2023-06-25'
          }
        ]
        
        // Contar por status
        const statsCounts = await Promise.all([
          this.contarPorStatus('pendente'),
          this.contarPorStatus('aprovado'),
          this.contarPorStatus('diligencia')
        ])
        
        this.pendentes = statsCounts[0]
        this.aprovados = statsCounts[1]
        this.diligencias = statsCounts[2]
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
      } finally {
        this.loading = false
      }
    },
    async contarPorStatus(status) {
      if (!this.currentTenantId) return 0
      
      const { count, error } = await supabase
        .from('produtos')
        .select('id', { count: 'exact' })
        .eq('status', status)
        .eq('tenant_id', this.currentTenantId)
      
      if (error) {
        console.error(`Erro ao contar produtos ${status}:`, error)
        return 0
      }
      
      return count || 0
    },
    formatDate(dateString) {
      if (!dateString) return ''
      
      // Se for uma data no formato ISO
      if (dateString.includes('T')) {
        const date = new Date(dateString)
        return date.toLocaleDateString('pt-BR')
      }
      
      // Se for uma data no formato YYYY-MM-DD
      const parts = dateString.split('-')
      if (parts.length === 3) {
        return `${parts[2]}/${parts[1]}/${parts[0]}`
      }
      
      return dateString
    },
    formatarStatus(status) {
      switch (status) {
        case 'pendente': return 'Em avaliação'
        case 'aprovado': return 'Homologado'
        case 'diligencia': return 'Em diligência'
        default: return status
      }
    },
    getStatusClass(status) {
      switch (status) {
        case 'aprovado': return 'status-aprovado'
        case 'pendente': return 'status-pendente'
        case 'reprovado': return 'status-reprovado'
        case 'diligencia': return 'status-diligencia'
        default: return ''
      }
    },
    publicarDecisao(id) {
      this.$swal({
        title: 'Ação Simulada',
        text: 'Em uma implementação completa, abriria um formulário para registrar a decisão da comissão e publicar no Diário Oficial.',
        icon: 'info'
      })
    },
    visualizarAta(id) {
      this.$swal({
        title: 'Ação Simulada',
        text: 'Em uma implementação completa, exibiria o documento da ata de julgamento e permitiria fazer download.',
        icon: 'info'
      })
    },
    getRecursoStatusClass(status) {
      switch (status) {
        case 'EM ANÁLISE': return 'status-pendente'
        case 'DEFERIDO': return 'status-aprovado'
        case 'INDEFERIDO': return 'status-reprovado'
        default: return ''
      }
    },
    julgarRecurso(id) {
      this.$swal({
        title: 'Ação Simulada',
        text: 'Em uma implementação completa, abriria um formulário para julgar o recurso.',
        icon: 'info'
      })
    }
  }
}
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.tabs {
  display: flex;
  margin-bottom: 20px;
  border-bottom: 1px solid #ddd;
}

.tab {
  padding: 10px 20px;
  cursor: pointer;
  font-weight: 500;
  border-bottom: 3px solid transparent;
  transition: all 0.3s ease;
}

.tab:hover {
  background-color: #f5f5f5;
}

.tab.active {
  border-bottom: 3px solid #3498db;
  color: #3498db;
}

.atas-julgamento,
.homologacoes {
  margin-top: 20px;
}

.info-card {
  background: white;
  border-radius: 8px;
  padding: 25px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  position: relative;
  overflow: hidden;
}

.info-card h3 {
  color: #2c3e50;
  margin-bottom: 15px;
}

.info-card p {
  margin-bottom: 15px;
  color: #555;
}

.info-card ul {
  margin-left: 20px;
  margin-bottom: 20px;
}

.info-card li {
  margin-bottom: 8px;
  color: #555;
}

.em-desenvolvimento {
  position: relative;
  margin-top: 20px;
  padding: 8px 15px;
  background-color: #f39c12;
  color: white;
  border-radius: 4px;
  display: inline-block;
  font-weight: bold;
  text-transform: uppercase;
  font-size: 12px;
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

.dashboard-section {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

h3 {
  margin-top: 0;
  margin-bottom: 15px;
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

.status-diligencia-card {
  border-top: 5px solid #9b59b6;
}

.status-diligencia {
  background-color: #9b59b6;
  color: white;
}
</style> 