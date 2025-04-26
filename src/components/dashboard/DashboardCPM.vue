<template>
  <div class="dashboard">
    <h2>Painel CPM</h2>
    
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
        :class="{ active: activeTab === 'editais' }" 
        @click="activeTab = 'editais'"
      >
        Editais de Pré-Qualificação
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'pesquisa' }" 
        @click="activeTab = 'pesquisa'"
      >
        Pesquisa de Mercado
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'despadronizadas' }" 
        @click="activeTab = 'despadronizadas'"
      >
        Marcas Despadronizadas
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'certificados' }" 
        @click="activeTab = 'certificados'"
      >
        Emissão de Certificados (DCB)
      </div>
    </div>
    
    <!-- Aba Dashboard -->
    <div v-if="activeTab === 'dashboard'">
      <div class="stats-container">
        <div class="stat-card status-pendente-card">
          <h3>Produtos em Avaliação</h3>
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
        <h3>Requerimentos Recentes</h3>
        <table v-if="produtos.length > 0">
          <thead>
            <tr>
              <th>Nome</th>
              <th>Marca</th>
              <th>Status</th>
              <th>Data</th>
              <th>Documentação</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="produto in produtos" :key="produto.id">
              <td>{{ produto.nome }}</td>
              <td>{{ produto.marca }}</td>
              <td>
                <span class="status-badge" :class="getStatusClass(produto.status)">
                  {{ formatarStatus(produto.status) }}
                </span>
              </td>
              <td>{{ formatDate(produto.criado_em) }}</td>
              <td>
                <button @click="verProduto(produto.id)" class="btn-small">Visualizar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Nenhum requerimento cadastrado.</p>
      </div>
      
      <div class="diligencia-section">
        <h3>Requerimentos com Diligências</h3>
        <table v-if="produtosComDiligencia.length > 0">
          <thead>
            <tr>
              <th>Nome</th>
              <th>Marca</th>
              <th>Status</th>
              <th>Data</th>
              <th>Documentação</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="produto in produtosComDiligencia" :key="produto.id">
              <td>{{ produto.nome }}</td>
              <td>{{ produto.marca }}</td>
              <td>
                <span class="status-badge status-diligencia">
                  Diligência
                </span>
              </td>
              <td>{{ formatDate(produto.criado_em) }}</td>
              <td>
                <button @click="verProduto(produto.id)" class="btn-small">Visualizar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Nenhum requerimento com diligência encontrado.</p>
      </div>
      
      <div class="impugnacoes-section">
        <h3>Impugnações ao Edital</h3>
        <table v-if="impugnacoes.length > 0">
          <thead>
            <tr>
              <th>Impugnante</th>
              <th>Produto</th>
              <th>Data da Impugnação</th>
              <th>Prazo Final</th>
              <th>Status</th>
              <th>Documentação</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="impugnacao in impugnacoes" :key="impugnacao.id">
              <td>{{ impugnacao.impugnante }}</td>
              <td>{{ impugnacao.produto_nome }}</td>
              <td>{{ formatDate(impugnacao.data_impugnacao) }}</td>
              <td>{{ formatDate(impugnacao.prazo_final) }}</td>
              <td>
                <span class="status-badge" :class="getImpugnacaoStatusClass(impugnacao.status)">
                  {{ impugnacao.status }}
                </span>
              </td>
              <td>
                <button @click="analisarImpugnacao(impugnacao.id)" class="btn-small">Visualizar</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Não há impugnações apresentadas.</p>
      </div>
    </div>
    
    <!-- Aba Pesquisa de Mercado -->
    <div v-if="activeTab === 'pesquisa'" class="pesquisa-mercado">
      <div class="info-card">
        <h3>Pesquisa de Mercado</h3>
        <p>Este módulo permitirá registrar as pesquisas realizadas para conhecer e/ou avaliar as especificações técnicas e funcionalidades de produtos novos ou já existentes no mercado fornecedor, bem como os seus preços estimados, para fins de instrução dos processos destinados à padronização de marcas e modelos.</p>
        <p>Funcionalidades que serão implementadas:</p>
        <ul>
          <li>Registro de especificações técnicas de produtos e cotações de fornecedores</li>
          <li>Comparativo técnico de produtos, seus preços e condições gerais</li>
          <li>Análise de variação de preços</li>
          <li>Geração de relatórios para instrução de processos de compras</li>
          <li>Integração com bancos de preços públicos</li>
        </ul>
        <div class="em-desenvolvimento">
          <span>Em desenvolvimento</span>
        </div>
      </div>
    </div>
    
    <!-- Aba Editais -->
    <div v-if="activeTab === 'editais'" class="editais">
      <div class="info-card">
        <h3>Editais de Pré-Qualificação</h3>
        <p>Este módulo permite acessar os arquivos em PDF dos editais publicados pela Comissão de Padronização de Materiais.</p>
        <p>Funcionalidades que serão implementadas:</p>
        <ul>
          <li>Upload de arquivos PDF dos editais</li>
          <li>Organização dos editais por data e categoria</li>
          <li>Pesquisa avançada nos editais</li>
          <li>Controle de versões dos documentos</li>
          <li>Histórico de publicações por período</li>
        </ul>
        
        <div class="editais-list">
          <h4>Editais Disponíveis</h4>
          <table v-if="editais && editais.length > 0">
            <thead>
              <tr>
                <th>Número</th>
                <th>Descrição</th>
                <th>Data de Publicação</th>
                <th>Documentação</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="edital in editais" :key="edital.id">
                <td>{{ edital.numero }}</td>
                <td>{{ edital.descricao }}</td>
                <td>{{ formatDate(edital.data_publicacao) }}</td>
                <td>
                  <button @click="visualizarEdital(edital.id)" class="btn-small">Visualizar</button>
                </td>
              </tr>
            </tbody>
          </table>
          <div v-else class="em-desenvolvimento">
            <span>Em desenvolvimento</span>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Aba Marcas Despadronizadas -->
    <div v-if="activeTab === 'despadronizadas'" class="marcas-despadronizadas">
      <div class="info-card">
        <h3>Marcas Despadronizadas</h3>
        <p>Este módulo permitirá gerenciar marcas e modelos que foram despadronizados ou que não atendem mais aos requisitos de padronização.</p>
        <p>Funcionalidades que serão implementadas:</p>
        <ul>
          <li>Registro de marcas e modelos despadronizados</li>
          <li>Motivos e justificativas para despadronização</li>
          <li>Histórico de despadronizações</li>
          <li>Restrições de uso para modelos despadronizados</li>
          <li>Notificação aos setores sobre despadronizações</li>
          <li>Relatórios de impacto por despadronização</li>
          <li>Registro de comunicações aos órgãos de controle</li>
        </ul>
        <div class="em-desenvolvimento">
          <span>Em desenvolvimento</span>
        </div>
      </div>
    </div>
    
    <!-- Aba Emissão de Certificados (DCB) -->
    <div v-if="activeTab === 'certificados'" class="certificados">
      <div class="info-card">
        <h3>Emissão de Certificados (DCB)</h3>
        <p>Este módulo permitirá o acesso e emissão de certificados DCB (Documento de Comprovação de Bem) para produtos aprovados.</p>
        <p>Funcionalidades que serão implementadas:</p>
        <ul>
          <li>Emissão de certificados de homologação</li>
          <li>Controle e gerenciamento de certificados emitidos</li>
          <li>Validação e verificação de autenticidade</li>
          <li>Histórico de certificações por produto</li>
          <li>Relatórios de produtos certificados</li>
          <li>Notificação automática de certificações realizadas</li>
          <li>Controle de prazos de validade de DCB</li>
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
  name: 'DashboardCPM',
  data() {
    return {
      activeTab: 'dashboard',
      produtos: [],
      produtosComDiligencia: [],
      pendentes: 0,
      aprovados: 0,
      reprovados: 0,
      currentTenantId: null,
      loading: false,
      editais: [],
      impugnacoes: [],
      certificados: []
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

        // Carregar produtos com diligência (status = 'diligencia')
        const { data: diligenciaData, error: diligenciaError } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'diligencia') // Filtrar produtos com status de diligência
          .order('criado_em', { ascending: false })
          .limit(10)
        
        if (diligenciaError) throw diligenciaError
        
        this.produtosComDiligencia = diligenciaData || []
        console.log(`${this.produtosComDiligencia.length} produtos com diligência carregados`)
        
        // Dados simulados para impugnações (em uma implementação real, viriam do banco de dados)
        this.impugnacoes = [
          {
            id: '1',
            impugnante: 'MedTech Equipamentos LTDA',
            produto_nome: 'Monitor de Sinais Vitais',
            data_impugnacao: '2023-06-10',
            status: 'EM ANÁLISE',
            prazo_final: '2023-06-25',
            url_documento: 'https://comprabem.gov.br/docs/impugnacoes/imp_2023_001.pdf'
          },
          {
            id: '2',
            impugnante: 'Hospital Santa Casa',
            produto_nome: 'Desfibrilador Cardíaco',
            data_impugnacao: '2023-06-15',
            status: 'DEFERIDA',
            prazo_final: '2023-06-30',
            url_documento: 'https://comprabem.gov.br/docs/impugnacoes/imp_2023_002.pdf'
          },
          {
            id: '3',
            impugnante: 'Laboratórios Reunidos S.A.',
            produto_nome: 'Autoclave Hospitalar',
            data_impugnacao: '2023-06-20',
            status: 'INDEFERIDA',
            prazo_final: '2023-07-05',
            url_documento: null
          }
        ]
        
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
    formatarStatus(status) {
      if (status === 'pendente') return 'em avaliação'
      return status
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
    },
    async visualizarEdital(id) {
      // Implemente a lógica para visualizar o edital com base no ID
      console.log(`Visualizando edital com ID: ${id}`)
    },
    getImpugnacaoStatusClass(status) {
      switch (status) {
        case 'EM ANÁLISE': return 'status-pendente'
        case 'DEFERIDA': return 'status-aprovado'
        case 'INDEFERIDA': return 'status-reprovado'
        default: return ''
      }
    },
    async analisarImpugnacao(id) {
      // Implemente a lógica para analisar uma impugnação com base no ID
      console.log(`Analisando impugnação com ID: ${id}`)
      this.$swal({
        title: 'Ação Simulada',
        text: 'Em uma implementação completa, abriria um formulário para analisar a impugnação ao edital e permitiria acesso ao documento PDF assinado digitalmente.',
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

.pesquisa-mercado {
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

.diligencia-section {
  margin-top: 30px;
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.status-diligencia {
  background-color: #9b59b6;
  color: white;
}

.marcas-despadronizadas {
  margin-top: 20px;
}

.editais {
  margin-top: 20px;
}

.editais-list {
  margin-top: 20px;
}

.impugnacoes-section {
  margin-top: 30px;
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.link-documento {
  display: flex;
  align-items: center;
  color: #3498db;
  text-decoration: none;
  font-size: 0.9rem;
}

.link-documento:hover {
  text-decoration: underline;
}

.link-documento i {
  margin-right: 5px;
  font-size: 1.1rem;
  color: #e74c3c;
}

.sem-documento {
  color: #999;
  font-size: 0.9rem;
  font-style: italic;
}

.certificados {
  margin-top: 20px;
}
</style> 