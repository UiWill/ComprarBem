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
        <div class="section-header">
          <h3>📋 Requerimentos Recentes</h3>
          <div class="pagination-controls">
            <label>Itens por página:</label>
            <select v-model="itensPorPagina" @change="aplicarPaginacao">
              <option value="5">5</option>
              <option value="10">10</option>
              <option value="20">20</option>
              <option value="50">50</option>
            </select>
          </div>
        </div>
        
        <!-- Filtros Inline -->
        <div class="filtros-inline">
          <div class="filtro-inline">
            <label>🔤 Nome:</label>
            <input 
              v-model="filtros.nome" 
              type="text" 
              placeholder="Filtrar por nome..."
              @input="aplicarFiltros"
            >
          </div>
          
          <div class="filtro-inline">
            <label>🏷️ Marca:</label>
            <input 
              v-model="filtros.marca" 
              type="text" 
              placeholder="Filtrar por marca..."
              @input="aplicarFiltros"
            >
          </div>
          
                       <div class="filtro-inline">
               <label>📊 Status:</label>
               <select v-model="filtros.status" @change="aplicarFiltros">
                 <option value="">Todos</option>
                 <option value="pendente">Em Avaliação</option>
                 <option value="aprovado">Aprovado</option>
                 <option value="reprovado">Reprovado</option>
                 <option value="em_analise">Em Análise</option>
               </select>
             </div>
          
          <div class="filtro-inline">
            <label>📅 Data:</label>
            <input 
              v-model="filtros.data" 
              type="date" 
              @change="aplicarFiltros"
            >
          </div>
          
          <button @click="limparFiltros" class="btn-limpar-filtros">
            🗑️ Limpar
          </button>
        </div>
        

        
        <table v-if="produtosPaginados.length > 0">
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
            <tr v-for="produto in produtosPaginados" :key="produto.id">
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
        
        <!-- Paginação -->
        <div v-if="totalPaginas > 1" class="paginacao">
          <div class="paginacao-info">
            Página {{ paginaAtual }} de {{ totalPaginas }}
          </div>
          <div class="paginacao-botoes">
            <button 
              @click="irParaPagina(paginaAtual - 1)" 
              :disabled="paginaAtual === 1"
              class="btn-paginacao"
            >
              ◀️ Anterior
            </button>
            
            <span class="numeros-pagina">
              <button 
                v-for="pagina in paginasVisiveis" 
                :key="pagina"
                @click="irParaPagina(pagina)"
                :class="['btn-numero', { active: pagina === paginaAtual }]"
              >
                {{ pagina }}
              </button>
            </span>
            
            <button 
              @click="irParaPagina(paginaAtual + 1)" 
              :disabled="paginaAtual === totalPaginas"
              class="btn-paginacao"
            >
              ▶️ Próxima
            </button>
          </div>
        </div>
        
        <p v-else-if="produtos.length === 0">Nenhum requerimento cadastrado.</p>
        <p v-else-if="temFiltrosAplicados">Nenhum produto encontrado com os filtros aplicados.</p>
      </div>
      
      <div class="diligencia-section">
        <div class="section-header">
          <h3>🔍 Requerimentos com Diligências</h3>
          <div class="pagination-controls">
            <label>Itens por página:</label>
            <select v-model="itensPorPaginaDiligencia" @change="aplicarPaginacaoDiligencia">
              <option value="5">5</option>
              <option value="10">10</option>
              <option value="20">20</option>
            </select>
          </div>
        </div>
        
        <!-- Filtros Inline para Diligências -->
        <div class="filtros-inline">
          <div class="filtro-inline">
            <label>🔍 Buscar:</label>
            <input 
              v-model="filtrosDiligencia.busca" 
              type="text" 
              placeholder="Nome, marca ou fabricante..."
              @input="aplicarFiltrosDiligencia"
            >
          </div>
          
          <div class="filtro-inline">
            <label>🏷️ Marca:</label>
            <select v-model="filtrosDiligencia.marca" @change="aplicarFiltrosDiligencia">
              <option value="">Todas</option>
              <option v-for="marca in marcasUnicas" :key="marca" :value="marca">
                {{ marca }}
              </option>
            </select>
          </div>
          
          <div class="filtro-inline">
            <label>📅 Data:</label>
            <input 
              v-model="filtrosDiligencia.data" 
              type="date" 
              @change="aplicarFiltrosDiligencia"
            >
          </div>
          
          <button @click="limparFiltrosDiligencia" class="btn-limpar-filtros">
            🗑️ Limpar
          </button>
        </div>
        

        
        <table v-if="diligenciasPaginadas.length > 0">
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
            <tr v-for="produto in diligenciasPaginadas" :key="produto.id">
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
                <button @click="visualizarDiligencias(produto.id)" class="btn-small btn-diligencia">Ver Diligências</button>
              </td>
            </tr>
          </tbody>
        </table>
        
        <!-- Paginação Diligências -->
        <div v-if="totalPaginasDiligencia > 1" class="paginacao">
          <div class="paginacao-info">
            Página {{ paginaAtualDiligencia }} de {{ totalPaginasDiligencia }}
          </div>
          <div class="paginacao-botoes">
            <button 
              @click="irParaPaginaDiligencia(paginaAtualDiligencia - 1)" 
              :disabled="paginaAtualDiligencia === 1"
              class="btn-paginacao"
            >
              ◀️ Anterior
            </button>
            
            <span class="numeros-pagina">
              <button 
                v-for="pagina in paginasVisiveisDiligencia" 
                :key="pagina"
                @click="irParaPaginaDiligencia(pagina)"
                :class="['btn-numero', { active: pagina === paginaAtualDiligencia }]"
              >
                {{ pagina }}
              </button>
            </span>
            
            <button 
              @click="irParaPaginaDiligencia(paginaAtualDiligencia + 1)" 
              :disabled="paginaAtualDiligencia === totalPaginasDiligencia"
              class="btn-paginacao"
            >
              ▶️ Próxima
            </button>
          </div>
        </div>
        
        <p v-else-if="produtosComDiligencia.length === 0">Nenhum requerimento com diligência encontrado.</p>
        <p v-else-if="temFiltrosDiligenciaAplicados">Nenhuma diligência encontrada com os filtros aplicados.</p>
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
          <li>Emissão de Certificados (DCB)</li>
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
      certificados: [],
      itensPorPagina: 5,
      paginaAtual: 1,
      totalPaginas: 1,
      paginasVisiveis: [],
      filtros: {
        nome: '',
        marca: '',
        status: '',
        data: ''
      },
      produtosPaginados: [],
      produtosFiltrados: [],
      itensPorPaginaDiligencia: 5,
      paginaAtualDiligencia: 1,
      totalPaginasDiligencia: 1,
      paginasVisiveisDiligencia: [],
             filtrosDiligencia: {
         busca: '',
         marca: '',
         data: ''
       },
       diligenciasFiltradas: [],
       diligenciasPaginadas: []
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarDados()
    })
  },
  async mounted() {
    await this.carregarDados()
    this.inicializarFiltros()
  },
      computed: {
      // Marcas únicas para o filtro de diligências
      marcasUnicas() {
        const marcas = [...new Set(this.produtosComDiligencia.map(p => p.marca))]
        return marcas.filter(marca => marca).sort()
      },
      
      // Verificar se há filtros aplicados nos requerimentos
      temFiltrosAplicados() {
        return this.filtros.nome || this.filtros.marca || this.filtros.status || this.filtros.data
      },
      
      // Verificar se há filtros aplicados nas diligências
      temFiltrosDiligenciaAplicados() {
        return this.filtrosDiligencia.busca || this.filtrosDiligencia.marca || this.filtrosDiligencia.data
      }
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
        
        // Carregar TODOS os produtos do tenant atual
        const { data: todosProdutos, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId) // Filtrar por tenant_id
          .order('criado_em', { ascending: false })
        
        if (error) throw error
        
        const produtos = todosProdutos || []
        
        // 📋 REQUERIMENTOS RECENTES: pendente, aprovado, reprovado, em_analise
        // (Excluindo produtos com status 'diligencia')
        this.produtos = produtos.filter(produto => 
          ['pendente', 'aprovado', 'reprovado', 'em_analise'].includes(produto.status)
        )
        console.log(`${this.produtos.length} requerimentos recentes carregados (sem diligências)`)

        // 🔍 REQUERIMENTOS COM DILIGÊNCIAS: apenas status 'diligencia'
        this.produtosComDiligencia = produtos.filter(produto => produto.status === 'diligencia')
        console.log(`${this.produtosComDiligencia.length} produtos com diligência carregados`)
        
        // Carregar impugnações reais do banco
        await this.carregarImpugnacoes()
        
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
          // Inicializar filtros após carregar os dados
          this.$nextTick(() => {
            this.inicializarFiltros()
          })
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
      try {
        // Buscar detalhes da impugnação
        const { data, error } = await supabase
          .from('impugnacoes')
          .select(`
            *,
            editais (
              numero,
              descricao
            )
          `)
          .eq('id', id)
          .single()
        
        if (error) throw error
        
        // Abrir modal para análise
        const { value: resposta } = await this.$swal({
          title: 'Análise de Impugnação',
          html: `
            <div style="text-align: left;">
              <h4>Impugnação de: ${data.impugnante}</h4>
              <p><strong>Edital:</strong> ${data.editais?.numero} - ${data.editais?.descricao}</p>
              <p><strong>Data:</strong> ${this.formatDate(data.data_impugnacao)}</p>
              <p><strong>Prazo Final:</strong> ${this.formatDate(data.prazo_final)}</p>
              <p><strong>Motivo:</strong> ${data.motivo}</p>
              <p><strong>Status Atual:</strong> ${data.status}</p>
            </div>
            <hr>
            <label for="decisao"><strong>Decisão:</strong></label>
            <select id="decisao" class="swal2-input">
              <option value="">Selecione uma decisão</option>
              <option value="DEFERIDA">DEFERIDA (Procedente)</option>
              <option value="INDEFERIDA">INDEFERIDA (Improcedente)</option>
              <option value="PARCIALMENTE_DEFERIDA">PARCIALMENTE DEFERIDA</option>
            </select>
            <label for="justificativa"><strong>Justificativa da Decisão:</strong></label>
            <textarea id="justificativa" class="swal2-textarea" placeholder="Fundamente a decisão tomada..."></textarea>
          `,
          focusConfirm: false,
          preConfirm: () => {
            const decisao = document.getElementById('decisao').value
            const justificativa = document.getElementById('justificativa').value
            
            if (!decisao) {
              this.$swal.showValidationMessage('Selecione uma decisão')
              return false
            }
            
            if (!justificativa || justificativa.trim().length < 10) {
              this.$swal.showValidationMessage('A justificativa deve ter pelo menos 10 caracteres')
              return false
            }
            
            return { decisao, justificativa }
          }
        })
        
        if (resposta) {
          await this.salvarDecisaoImpugnacao(id, resposta.decisao, resposta.justificativa)
        }
        
      } catch (error) {
        console.error('Erro ao analisar impugnação:', error)
      this.$swal({
          title: 'Erro',
          text: 'Erro ao carregar dados da impugnação',
          icon: 'error'
        })
      }
    },
    
    async carregarImpugnacoes() {
      try {
        const { data, error } = await supabase
          .from('impugnacoes')
          .select(`
            *,
            editais (
              numero,
              descricao
            )
          `)
          .eq('tenant_id', this.currentTenantId)
          .order('data_impugnacao', { ascending: false })
          .limit(10)
        
        if (error) throw error
        
        this.impugnacoes = data?.map(impugnacao => ({
          ...impugnacao,
          produto_nome: `Edital ${impugnacao.editais?.numero || 'N/A'}`
        })) || []
        
        console.log(`${this.impugnacoes.length} impugnações carregadas`)
      } catch (error) {
        console.error('Erro ao carregar impugnações:', error)
        this.impugnacoes = []
      }
    },
    
    async salvarDecisaoImpugnacao(id, decisao, justificativa) {
      try {
        const { error } = await supabase
          .from('impugnacoes')
          .update({
            status: decisao,
            justificativa_decisao: justificativa,
            data_decisao: new Date().toISOString(),
            analisado_por: 'CPM'
          })
          .eq('id', id)
        
        if (error) throw error
        
        this.$swal({
          title: 'Sucesso!',
          text: 'Decisão da impugnação salva com sucesso',
          icon: 'success'
        })
        
        await this.carregarImpugnacoes()
        
             } catch (error) {
         console.error('Erro ao salvar decisão:', error)
         this.$swal({
           title: 'Erro',
           text: 'Erro ao salvar decisão da impugnação',
           icon: 'error'
         })
       }
     },
     
     async solicitarDiligencia(produtoId) {
       try {
         const { value: diligenciaData } = await this.$swal({
           title: 'Solicitar Diligência',
           html: `
             <label for="tipo_diligencia"><strong>Tipo de Diligência:</strong></label>
             <select id="tipo_diligencia" class="swal2-input">
               <option value="">Selecione o tipo</option>
               <option value="DOCUMENTACAO_FALTANTE">Documentação Faltante</option>
               <option value="AMOSTRA_INADEQUADA">Amostra Inadequada</option>
               <option value="ESPECIFICACAO_INCOMPLETA">Especificação Incompleta</option>
               <option value="CERTIFICACAO_PENDENTE">Certificação Pendente</option>
               <option value="ESCLARECIMENTO_TECNICO">Esclarecimento Técnico</option>
             </select>
             <label for="descricao_diligencia"><strong>Descrição da Diligência:</strong></label>
             <textarea id="descricao_diligencia" class="swal2-textarea" placeholder="Descreva detalhadamente o que precisa ser providenciado..."></textarea>
             <label for="prazo_dias"><strong>Prazo (dias úteis):</strong></label>
             <input type="number" id="prazo_dias" class="swal2-input" value="5" min="1" max="30">
           `,
           focusConfirm: false,
           preConfirm: () => {
             const tipo = document.getElementById('tipo_diligencia').value
             const descricao = document.getElementById('descricao_diligencia').value
             const prazo = parseInt(document.getElementById('prazo_dias').value)
             
             if (!tipo) {
               this.$swal.showValidationMessage('Selecione o tipo de diligência')
               return false
             }
             
             if (!descricao || descricao.trim().length < 10) {
               this.$swal.showValidationMessage('A descrição deve ter pelo menos 10 caracteres')
               return false
             }
             
             if (!prazo || prazo < 1 || prazo > 30) {
               this.$swal.showValidationMessage('O prazo deve ser entre 1 e 30 dias')
               return false
             }
             
             return { tipo, descricao, prazo }
           }
         })
         
         if (diligenciaData) {
           await this.salvarDiligencia(produtoId, diligenciaData)
         }
         
       } catch (error) {
         console.error('Erro ao solicitar diligência:', error)
       }
     },
     
     async salvarDiligencia(produtoId, diligenciaData) {
       try {
         // Calcular data limite (dias úteis)
         const dataLimite = this.calcularDataUtil(new Date(), diligenciaData.prazo)
         
         // Inserir diligência
         const { error: diligenciaError } = await supabase
           .from('diligencias')
           .insert({
             produto_id: produtoId,
             tenant_id: this.currentTenantId,
             tipo: diligenciaData.tipo,
             descricao: diligenciaData.descricao,
             prazo_dias: diligenciaData.prazo,
             data_limite: dataLimite.toISOString(),
             status: 'PENDENTE',
             solicitado_por: 'CPM'
           })
         
         if (diligenciaError) throw diligenciaError
         
         // Atualizar status do produto para 'diligencia'
         const { error: produtoError } = await supabase
           .from('produtos')
           .update({ status: 'diligencia' })
           .eq('id', produtoId)
         
         if (produtoError) throw produtoError
         
         this.$swal({
           title: 'Sucesso!',
           text: 'Diligência solicitada com sucesso',
           icon: 'success'
         })
         
         // Recarregar dados
         await this.carregarDados()
         
       } catch (error) {
         console.error('Erro ao salvar diligência:', error)
         this.$swal({
           title: 'Erro',
           text: 'Erro ao solicitar diligência',
           icon: 'error'
         })
       }
     },
     
     async visualizarDiligencias(produtoId) {
       try {
         // Buscar diligências do produto
         const { data, error } = await supabase
           .from('diligencias')
           .select('*')
           .eq('produto_id', produtoId)
           .order('criado_em', { ascending: false })
         
         if (error) throw error
         
         let html = '<div style="text-align: left;">'
         
         if (data && data.length > 0) {
           html += '<h4>Diligências do Produto:</h4>'
           data.forEach((diligencia, index) => {
             const statusClass = diligencia.status === 'PENDENTE' ? 'color: #f39c12' : 'color: #27ae60'
             html += `
               <div style="border: 1px solid #ddd; padding: 10px; margin: 10px 0; border-radius: 5px;">
                 <strong>Diligência ${index + 1}</strong><br>
                 <strong>Tipo:</strong> ${diligencia.tipo.replace(/_/g, ' ')}<br>
                 <strong>Status:</strong> <span style="${statusClass}">${diligencia.status}</span><br>
                 <strong>Descrição:</strong> ${diligencia.descricao}<br>
                 <strong>Prazo:</strong> ${this.formatDate(diligencia.data_limite)}<br>
                 <strong>Solicitado em:</strong> ${this.formatDate(diligencia.criado_em)}
               </div>
             `
           })
         } else {
           html += '<p>Nenhuma diligência encontrada para este produto.</p>'
         }
         
         html += '</div>'
         
         this.$swal({
           title: 'Diligências',
           html: html,
           width: '600px'
         })
         
       } catch (error) {
         console.error('Erro ao carregar diligências:', error)
      this.$swal({
           title: 'Erro',
           text: 'Erro ao carregar diligências do produto',
           icon: 'error'
         })
       }
     },
     
     calcularDataUtil(dataInicio, diasUteis) {
       const data = new Date(dataInicio)
       let diasAdicionados = 0
       
       while (diasAdicionados < diasUteis) {
         data.setDate(data.getDate() + 1)
         
         // Se não for sábado (6) nem domingo (0)
         if (data.getDay() !== 0 && data.getDay() !== 6) {
           diasAdicionados++
         }
       }
       
       return data
    },
         // 🔍 MÉTODOS DE FILTROS E PAGINAÇÃO - REQUERIMENTOS
     inicializarFiltros() {
       this.produtosFiltrados = [...this.produtos]
       this.diligenciasFiltradas = [...this.produtosComDiligencia]
       this.aplicarFiltros()
       this.aplicarFiltrosDiligencia()
     },
     
     aplicarFiltros() {
       // Filtrar produtos
       this.produtosFiltrados = this.produtos.filter(produto => {
         const nomeMatch = produto.nome.toLowerCase().includes(this.filtros.nome.toLowerCase())
         const marcaMatch = produto.marca.toLowerCase().includes(this.filtros.marca.toLowerCase())
         const statusMatch = this.filtros.status === '' || produto.status === this.filtros.status
         
         let dataMatch = true
         if (this.filtros.data) {
           const produtoData = new Date(produto.criado_em).toDateString()
           const filtroData = new Date(this.filtros.data).toDateString()
           dataMatch = produtoData === filtroData
         }
         
         return nomeMatch && marcaMatch && statusMatch && dataMatch
       })
       
       this.calcularPaginacao()
     },
     
     calcularPaginacao() {
       this.totalPaginas = Math.ceil(this.produtosFiltrados.length / this.itensPorPagina)
       
       // Ajustar página atual se necessário
       if (this.paginaAtual > this.totalPaginas) {
         this.paginaAtual = Math.max(1, this.totalPaginas)
       }
       
       // Calcular páginas visíveis (máximo 5)
       this.paginasVisiveis = []
       const maxPaginas = 5
       
       if (this.totalPaginas <= maxPaginas) {
         for (let i = 1; i <= this.totalPaginas; i++) {
           this.paginasVisiveis.push(i)
         }
       } else {
         const inicio = Math.max(1, this.paginaAtual - 2)
         const fim = Math.min(this.totalPaginas, inicio + maxPaginas - 1)
         
         for (let i = inicio; i <= fim; i++) {
           this.paginasVisiveis.push(i)
         }
       }
       
       // Calcular produtos da página atual
       const inicio = (this.paginaAtual - 1) * this.itensPorPagina
       const fim = inicio + this.itensPorPagina
       this.produtosPaginados = this.produtosFiltrados.slice(inicio, fim)
     },
     
     aplicarPaginacao() {
       this.paginaAtual = 1
       this.calcularPaginacao()
     },
     
     irParaPagina(pagina) {
       this.paginaAtual = pagina
       this.calcularPaginacao()
     },
     
     limparFiltros() {
       this.filtros = {
         nome: '',
         marca: '',
         status: '',
         data: ''
       }
       this.paginaAtual = 1
       this.aplicarFiltros()
     },
     
     // 🔍 MÉTODOS DE FILTROS E PAGINAÇÃO - DILIGÊNCIAS
     aplicarFiltrosDiligencia() {
       this.diligenciasFiltradas = this.produtosComDiligencia.filter(produto => {
         const buscaMatch = !this.filtrosDiligencia.busca || 
           produto.nome.toLowerCase().includes(this.filtrosDiligencia.busca.toLowerCase()) ||
           produto.marca.toLowerCase().includes(this.filtrosDiligencia.busca.toLowerCase()) ||
           (produto.fabricante && produto.fabricante.toLowerCase().includes(this.filtrosDiligencia.busca.toLowerCase()))
         
         const marcaMatch = !this.filtrosDiligencia.marca || produto.marca === this.filtrosDiligencia.marca
         
         let dataMatch = true
         if (this.filtrosDiligencia.data) {
           const produtoData = new Date(produto.criado_em).toDateString()
           const filtroData = new Date(this.filtrosDiligencia.data).toDateString()
           dataMatch = produtoData === filtroData
         }
         
         return buscaMatch && marcaMatch && dataMatch
       })
       
       this.calcularPaginacaoDiligencia()
     },
     
     calcularPaginacaoDiligencia() {
       this.totalPaginasDiligencia = Math.ceil(this.diligenciasFiltradas.length / this.itensPorPaginaDiligencia)
       
       if (this.paginaAtualDiligencia > this.totalPaginasDiligencia) {
         this.paginaAtualDiligencia = Math.max(1, this.totalPaginasDiligencia)
       }
       
       // Calcular páginas visíveis
       this.paginasVisiveisDiligencia = []
       const maxPaginas = 5
       
       if (this.totalPaginasDiligencia <= maxPaginas) {
         for (let i = 1; i <= this.totalPaginasDiligencia; i++) {
           this.paginasVisiveisDiligencia.push(i)
         }
       } else {
         const inicio = Math.max(1, this.paginaAtualDiligencia - 2)
         const fim = Math.min(this.totalPaginasDiligencia, inicio + maxPaginas - 1)
         
         for (let i = inicio; i <= fim; i++) {
           this.paginasVisiveisDiligencia.push(i)
         }
       }
       
       // Calcular diligências da página atual
       const inicio = (this.paginaAtualDiligencia - 1) * this.itensPorPaginaDiligencia
       const fim = inicio + this.itensPorPaginaDiligencia
       this.diligenciasPaginadas = this.diligenciasFiltradas.slice(inicio, fim)
     },
     
     aplicarPaginacaoDiligencia() {
       this.paginaAtualDiligencia = 1
       this.calcularPaginacaoDiligencia()
     },
     
     irParaPaginaDiligencia(pagina) {
       this.paginaAtualDiligencia = pagina
       this.calcularPaginacaoDiligencia()
     },
     
     limparFiltrosDiligencia() {
       this.filtrosDiligencia = {
         busca: '',
         marca: '',
         data: ''
               }
        this.paginaAtualDiligencia = 1
        this.aplicarFiltrosDiligencia()
      },
      
      // 🎨 MÉTODOS AUXILIARES
      formatarStatus(status) {
        const statusMap = {
          'pendente': 'Em Avaliação',
          'aprovado': 'Aprovado',
          'reprovado': 'Reprovado',
          'diligencia': 'Diligência',
          'em_analise': 'Em Análise'
        }
        return statusMap[status] || status
      },
      
      getStatusClass(status) {
        return `status-${status}`
      },
      
      formatDate(dateString) {
        if (!dateString) return '-'
        const date = new Date(dateString)
        return date.toLocaleDateString('pt-BR')
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

 /* 🎨 ESTILOS PARA FILTROS E PAGINAÇÃO */
 .section-header {
   display: flex;
   justify-content: space-between;
   align-items: center;
   margin-bottom: 15px;
   padding-bottom: 10px;
   border-bottom: 2px solid #ecf0f1;
 }
 
 .section-header h3 {
   margin: 0;
   color: #2c3e50;
   font-size: 18px;
 }
 
 .pagination-controls {
   display: flex;
   align-items: center;
   gap: 8px;
 }
 
 .pagination-controls label {
   font-size: 14px;
   color: #7f8c8d;
   font-weight: 500;
 }
 
 .pagination-controls select {
   padding: 5px 8px;
   border: 1px solid #ddd;
   border-radius: 4px;
   font-size: 14px;
 }
 
 /* 🔍 FILTROS INLINE */
 .filtros-inline {
   display: flex;
   align-items: center;
   gap: 15px;
   margin-bottom: 15px;
   padding: 15px;
   background: #f8f9fa;
   border-radius: 8px;
   border: 1px solid #e9ecef;
   flex-wrap: wrap;
 }
 
 .filtro-inline {
   display: flex;
   flex-direction: column;
   min-width: 150px;
 }
 
 .filtro-inline label {
   font-size: 12px;
   font-weight: bold;
   color: #495057;
   margin-bottom: 4px;
 }
 
 .filtro-inline input,
 .filtro-inline select {
   padding: 6px 10px;
   border: 1px solid #ced4da;
   border-radius: 4px;
   font-size: 14px;
   transition: border-color 0.3s, box-shadow 0.3s;
 }
 
 .filtro-inline input:focus,
 .filtro-inline select:focus {
   outline: none;
   border-color: #3498db;
   box-shadow: 0 0 5px rgba(52, 152, 219, 0.3);
 }
 
 .btn-limpar-filtros {
   padding: 8px 12px;
   background-color: #e74c3c;
   color: white;
   border: none;
   border-radius: 4px;
   cursor: pointer;
   font-size: 12px;
   font-weight: bold;
   transition: background-color 0.3s;
   align-self: flex-end;
 }
 
 .btn-limpar-filtros:hover {
   background-color: #c0392b;
 }
 
 /* 📊 INFORMAÇÕES DE RESULTADOS */
 .resultados-info {
   margin-bottom: 15px;
   padding: 8px 12px;
   background: #e8f4fd;
   border-left: 4px solid #3498db;
   border-radius: 4px;
   font-size: 14px;
   color: #2c3e50;
   font-weight: 500;
 }
 
 /* 📄 PAGINAÇÃO */
 .paginacao {
   display: flex;
   justify-content: space-between;
   align-items: center;
   margin-top: 20px;
   padding: 15px;
   background: #f8f9fa;
   border-radius: 8px;
   border: 1px solid #e9ecef;
 }
 
 .paginacao-info {
   font-size: 14px;
   color: #6c757d;
   font-weight: 500;
 }
 
 .paginacao-botoes {
   display: flex;
   align-items: center;
   gap: 5px;
 }
 
 .btn-paginacao {
   padding: 8px 12px;
   background-color: #6c757d;
   color: white;
   border: none;
   border-radius: 4px;
   cursor: pointer;
   font-size: 12px;
   font-weight: bold;
   transition: background-color 0.3s;
 }
 
 .btn-paginacao:hover:not(:disabled) {
   background-color: #5a6268;
 }
 
 .btn-paginacao:disabled {
   background-color: #dee2e6;
   color: #6c757d;
   cursor: not-allowed;
 }
 
 .numeros-pagina {
   display: flex;
   align-items: center;
   gap: 2px;
   margin: 0 10px;
 }
 
 .btn-numero {
   padding: 6px 10px;
   background-color: #f8f9fa;
   color: #495057;
   border: 1px solid #dee2e6;
   border-radius: 4px;
   cursor: pointer;
   font-size: 12px;
   font-weight: bold;
   transition: all 0.3s;
 }
 
 .btn-numero:hover {
   background-color: #e9ecef;
 }
 
 .btn-numero.active {
   background-color: #3498db;
   color: white;
   border-color: #3498db;
 }
 
 /* 🎯 BOTÕES ESPECIAIS */
 .btn-diligencia {
   background-color: #17a2b8 !important;
   color: white !important;
   margin-left: 5px;
 }
 
 .btn-diligencia:hover {
   background-color: #138496 !important;
 }
 
 /* 🏷️ STATUS BADGES - ESTILO IGUAL CCL */
 .status-badge {
   display: inline-block;
   padding: 5px 10px;
   border-radius: 20px;
   font-size: 12px;
   text-transform: uppercase;
   font-weight: bold;
 }
 
 .status-pendente {
   background-color: #f39c12;
   color: white;
 }
 
 .status-aprovado {
   background-color: #2ecc71;
   color: white;
 }
 
 .status-reprovado {
   background-color: #e74c3c;
   color: white;
 }
 
 .status-diligencia {
   background-color: #9b59b6;
   color: white;
 }
 
 .status-em_analise {
   background-color: #3498db;
   color: white;
}
</style> 