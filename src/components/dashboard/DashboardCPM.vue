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
      <div 
        class="tab" 
        :class="{ active: activeTab === 'usuarios' }" 
        @click="activeTab = 'usuarios'"
      >
        Cadastro de Usuários
      </div>
      <div 
        class="tab" 
        :class="{ active: activeTab === 'reclamacoes' }" 
        @click="activeTab = 'reclamacoes'"
      >
        Registros de Reclamações
        <span v-if="reclamacoesNaoRespondidas > 0" class="notification-badge">
          {{ reclamacoesNaoRespondidas }}
        </span>
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
              <th>Edital</th>
              <th>Status</th>
              <th>Data</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="produto in produtosPaginados" :key="produto.id">
              <td>{{ produto.nome }}</td>
              <td>{{ produto.marca }}</td>
              <td>{{ formatarEdital(produto) }}</td>
              <td>
                <span v-if="produto.status === 'aprovado' || produto.status === 'julgado_aprovado' || produto.status === 'homologado'" style="background-color: #2ecc71; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
                  {{ formatarStatus(produto.status) }}
                </span>
                <span v-else-if="produto.status === 'reprovado' || produto.status === 'julgado_reprovado'" style="background-color: #e74c3c; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
                  {{ formatarStatus(produto.status) }}
                </span>
                <span v-else-if="produto.status === 'pendente'" style="background-color: #f39c12; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
                  {{ formatarStatus(produto.status) }}
                </span>
                <span v-else-if="produto.status === 'em_analise'" style="background-color: #3498db; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
                  {{ formatarStatus(produto.status) }}
                </span>
                <span v-else-if="produto.status === 'diligencia'" style="background-color: #9b59b6; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
                  {{ formatarStatus(produto.status) }}
                </span>
                <span v-else style="background-color: #6c757d; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
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
              <th>Edital</th>
              <th>Status</th>
              <th>Data</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="produto in diligenciasPaginadas" :key="produto.id">
              <td>{{ produto.nome }}</td>
              <td>{{ produto.marca }}</td>
              <td>{{ formatarEdital(produto) }}</td>
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
    </div>
    
    <!-- Aba Pesquisa de Mercado -->
    <div v-if="activeTab === 'pesquisa'" class="pesquisa-mercado">
      <div class="pesquisa-mercado-container">


        <!-- Abas das Funcionalidades -->
        <div class="sub-tabs">
          <div 
            class="sub-tab" 
            :class="{ active: activeSubTab === 'pesquisa-tecnica' }" 
            @click="activeSubTab = 'pesquisa-tecnica'"
          >
            🤖 PesquisaBot
          </div>
          <div 
            class="sub-tab" 
            :class="{ active: activeSubTab === 'cotacoes' }" 
            @click="activeSubTab = 'cotacoes'"
          >
            💰 Cotações
          </div>
          <div 
            class="sub-tab" 
            :class="{ active: activeSubTab === 'comparativo' }" 
            @click="activeSubTab = 'comparativo'"
          >
            📊 Comparativo
          </div>
          <div 
            class="sub-tab" 
            :class="{ active: activeSubTab === 'analise-precos' }" 
            @click="activeSubTab = 'analise-precos'"
          >
            📈 Análise de Preços
          </div>
          <div 
            class="sub-tab" 
            :class="{ active: activeSubTab === 'relatorios' }" 
            @click="activeSubTab = 'relatorios'"
          >
            📋 Relatórios
          </div>
          <div 
            class="sub-tab" 
            :class="{ active: activeSubTab === 'bancos-precos' }" 
            @click="activeSubTab = 'bancos-precos'"
          >
            🏦 Bancos de Preços
          </div>
        </div>

        <!-- Conteúdo das Sub-abas -->
        
        <!-- PesquisaBot -->
        <div v-if="activeSubTab === 'pesquisa-tecnica'" class="sub-content">
          <div class="pesquisa-bot-section">
            <div class="section-intro">
              <h4>🤖 PesquisaBot - Assistente de Pesquisa Técnica</h4>
              <p>Ferramenta especializada para buscar informações técnicas sobre produtos e marcas, incluindo manuais, laudos, normas, certificações e informações regulatórias.</p>
            </div>
            <PesquisaBot />
          </div>
        </div>

        <!-- Cotações -->
        <div v-if="activeSubTab === 'cotacoes'" class="sub-content">
          <GerenciadorCotacoes />
        </div>

        <!-- Comparativo Técnico -->
        <div v-if="activeSubTab === 'comparativo'" class="sub-content">
          <GerenciadorComparativo />
        </div>

        <!-- Análise de Preços -->
        <div v-if="activeSubTab === 'analise-precos'" class="sub-content">
          <GerenciadorAnalisePrecos />
        </div>

        <!-- Relatórios -->
        <div v-if="activeSubTab === 'relatorios'" class="sub-content">
          <GerenciadorRelatorios />
        </div>

        <!-- Bancos de Preços -->
        <div v-if="activeSubTab === 'bancos-precos'" class="sub-content">
          <div class="bancos-precos-section">
            <div class="section-intro">
              <h4>🏦 Integração com Bancos de Preços Públicos</h4>
              <p>Consulte e integre dados de bancos de preços públicos para referência de mercado.</p>
            </div>
            
            <div class="bancos-grid">
              <div class="banco-card">
                <div class="banco-icon">🏛️</div>
                <h5>Banco de Preços do Governo Federal</h5>
                <p>Consulta ao Painel de Preços</p>
                <a href="https://paineldeprecos.planejamento.gov.br/" target="_blank" rel="noopener noreferrer" class="btn-primary" style="text-decoration: none; display: inline-block; text-align: center;">Consultar</a>
              </div>
              
              <div class="banco-card">
                <div class="banco-icon">🏥</div>
                <h5>Banco de Preços em Saúde</h5>
                <p>Preços de medicamentos e materiais médicos</p>
                <button @click="$swal({ title: '🏥 Banco de Saúde', text: 'Funcionalidade em desenvolvimento - Preços de medicamentos e materiais', icon: 'info' })" class="btn-primary">Consultar</button>
              </div>
              
              <div class="banco-card">
                <div class="banco-icon">🏢</div>
                <h5>Banco de Preços do TCE/MG</h5>
                <p>Tribunal de Contas do Estado de Minas Gerais</p>
                <a href="https://bancodepreco.tce.mg.gov.br/#/login/ex" target="_blank" rel="noopener noreferrer" class="btn-primary" style="text-decoration: none; display: inline-block; text-align: center;">Consultar</a>
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
    
    <!-- Aba Editais -->
    <div v-if="activeTab === 'editais'" class="editais">
      <div class="editais-container">
        <!-- Cabeçalho com Stats -->
        <div class="editais-stats">
          <div class="stat-card editais-ativos">
                            <h4>📋 Publicados</h4>
            <div class="stat-value">{{ editaisAtivos.length }}</div>
            <small>Recebendo documentação</small>
          </div>
          <div class="stat-card editais-rascunho">
            <h4>✏️ Em Elaboração</h4>
            <div class="stat-value">{{ editaisRascunho.length }}</div>
            <small>Aguardando publicação</small>
          </div>
          <div class="stat-card editais-finalizados">
            <h4>✅ Finalizados</h4>
            <div class="stat-value">{{ editaisFinalizados.length }}</div>
            <small>Processos concluídos</small>
          </div>

        </div>

        <!-- Barra de Ações -->
        <div class="editais-actions">
          <div class="actions-left">
            <button @click="abrirModalNovoEdital" class="btn-primary">
              ➕ Novo Edital
            </button>
            <button @click="carregarEditais" class="btn-secondary" :disabled="loadingEditais">
              🔄 Atualizar
            </button>
          </div>
          <div class="actions-right">
            <div class="filtro-group">
              <input 
                v-model="filtroEditais.busca" 
                type="text" 
                placeholder="🔍 Buscar edital..."
                @input="debouncedFiltrarEditais"
                @keyup.enter="aplicarFiltrosEditais"
              >
              <button 
                v-if="filtroEditais.busca || filtroEditais.status" 
                @click="limparFiltrosEditais" 
                class="btn-clear-filter"
                title="Limpar filtros"
              >
                ✕
              </button>
            </div>
            <div class="filtro-group">
              <select v-model="filtroEditais.status" @change="aplicarFiltrosEditais">
                <option value="">Todos os Status</option>
                <option value="RASCUNHO">📝 Em Elaboração</option>
                <option value="PUBLICADO">📋 Publicado</option>
                <option value="CANCELADO">❌ Cancelado</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Lista de Editais -->
        <div v-if="loadingEditais" class="loading-state">
          <div class="loading-spinner"></div>
          <p>Carregando editais...</p>
        </div>

        <div v-else-if="editaisFiltrados.length > 0" class="editais-grid">
          <div 
            v-for="edital in editaisFiltrados" 
            :key="edital.id" 
            class="edital-card"
            :class="{ 
              'status-ativo': edital.status === 'PUBLICADO',
              'status-rascunho': edital.status === 'RASCUNHO',
              'status-cancelado': edital.status === 'CANCELADO'
            }"
          >
            <div class="edital-header">
              <div class="edital-numero">{{ edital.numero }}</div>
              <div class="edital-status">
                <span v-if="edital.status === 'PUBLICADO'" class="badge status-publicado">📋 Publicado</span>
                <span v-else-if="edital.status === 'RASCUNHO'" class="badge status-rascunho">✏️ Em Elaboração</span>
                <span v-else-if="edital.status === 'CANCELADO'" class="badge status-cancelado">❌ Cancelado</span>
              </div>
            </div>
            
                          <div class="edital-content">
              <h4>{{ edital.descricao }}</h4>
              <div class="edital-info">
                <template v-if="edital.status === 'PUBLICADO'">
                  <p><strong>📅 Publicação:</strong> {{ formatDate(edital.data_publicacao) }}</p>
                  <p v-if="edital.data_limite_impugnacao">
                    <strong>⏰ Prazo Impugnação:</strong> {{ formatDate(edital.data_limite_impugnacao) }}
                  </p>
                </template>
              </div>
            </div>

            <div class="edital-actions">
              <button @click="visualizarEdital(edital)" class="btn-secondary btn-small">
                👁️ Visualizar
              </button>
              <button 
                v-if="edital.status === 'RASCUNHO'" 
                @click="editarEdital(edital)" 
                class="btn-primary btn-small"
              >
                ✏️ Editar
              </button>
              

              <div class="dropdown">
                <button class="btn-secondary btn-small dropdown-toggle">⋮</button>
                <div class="dropdown-menu">
                  <a v-if="edital.url_documento" @click="baixarDocumento(edital)">📥 Baixar PDF</a>
                  <a @click="duplicarEdital(edital)">📋 Duplicar</a>
                  <a v-if="edital.status === 'RASCUNHO'" @click="cancelarEdital(edital)" class="text-danger">❌ Cancelar</a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="empty-state">
          <div class="empty-icon">📋</div>
          <h3>Nenhum edital encontrado</h3>
          <p v-if="filtroEditais.busca || filtroEditais.status">
            Nenhum edital corresponde aos filtros aplicados.
          </p>
          <p v-else>
            Ainda não há editais cadastrados. Clique em "Novo Edital" para começar.
          </p>
          <button @click="abrirModalNovoEdital" class="btn-primary">
            ➕ Criar Primeiro Edital
          </button>
        </div>
      </div>

      <!-- Modal Novo Edital - Seleção de Minuta -->
      <div v-if="modalNovoEdital" class="modal-overlay" @click="fecharModalNovoEdital">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>📋 Selecionar Minuta-Padrão</h3>
            <button @click="fecharModalNovoEdital" class="btn-close">&times;</button>
          </div>
          
          <div class="modal-body">
            <div class="minuta-selecao">
              <div class="section-intro">
                <h4>Escolha uma minuta-padrão para criar o edital:</h4>
                <p>Selecione uma das minutas-padrão disponíveis. Após a seleção, o novo edital ficará com o status "Em Elaboração".</p>
              </div>

              <!-- Botão para adicionar nova minuta -->
              <div class="minutas-actions">
                <button @click="abrirModalAddMinuta" class="btn-secondary">
                  ➕ Adicionar Nova Minuta-Padrão
                </button>
              </div>

              <!-- Lista de Minutas Disponíveis -->
              <div class="minutas-grid">
                <div 
                  v-for="minuta in minutasDisponiveis" 
                  :key="minuta.id"
                  class="minuta-card"
                  :class="{ 'selected': minutaSelecionada === minuta.id }"
                  @click="selecionarMinuta(minuta)"
                >
                  <div class="minuta-header">
                    <div class="minuta-icon">
                      <span v-if="minuta.eh_padrao_sistema">🏛️</span>
                      <span v-else>📄</span>
                    </div>
                    <div class="minuta-info">
                      <h5>{{ minuta.nome }}</h5>
                      <p class="minuta-categoria">{{ minuta.categoria || 'Geral' }}</p>
                    </div>
                  </div>
                  
                  <div class="minuta-description">
                    <p>{{ minuta.descricao || 'Sem descrição' }}</p>
                  </div>
                  
                  <div class="minuta-meta">
                    <small>
                      <span v-if="minuta.eh_padrao_sistema" class="badge badge-system">Sistema</span>
                      <span v-else class="badge badge-custom">Personalizada</span>
                    </small>
                  </div>
                </div>
              </div>

              <!-- Estado vazio -->
              <div v-if="minutasDisponiveis.length === 0" class="empty-state">
                <div class="empty-icon">📋</div>
                <h3>Nenhuma minuta-padrão disponível</h3>
                <p>Adicione uma minuta-padrão para começar a criar editais.</p>
                <button @click="abrirModalAddMinuta" class="btn-primary">
                  ➕ Adicionar Primeira Minuta
                </button>
              </div>
            </div>

            <div class="form-actions">
              <button type="button" @click="fecharModalNovoEdital" class="btn-secondary">
                Cancelar
              </button>
              <button 
                @click="processarCriacaoEdital" 
                class="btn-primary" 
                :disabled="!minutaSelecionada || criandoEdital"
              >
                {{ criandoEdital ? 'Criando...' : 'Criar Edital com Minuta Selecionada' }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Modal Adicionar Nova Minuta Padrão -->
      <div v-if="modalAddMinuta" class="modal-overlay" @click="fecharModalAddMinuta">
        <div class="modal-content medium" @click.stop>
          <div class="modal-header">
            <h3>➕ Adicionar Nova Minuta-Padrão</h3>
            <button @click="fecharModalAddMinuta" class="btn-close">&times;</button>
          </div>
          
          <div class="modal-body">
            <form @submit.prevent="salvarNovaMinuta">
              <div class="form-group">
                <label for="minuta-nome">Nome da Minuta*</label>
                <input 
                  id="minuta-nome" 
                  v-model="novaMinuta.nome" 
                  type="text" 
                  placeholder="Ex: Minuta para Material de Escritório"
                  required
                >
              </div>

              <div class="form-group">
                <label for="minuta-categoria">Categoria</label>
                <select id="minuta-categoria" v-model="novaMinuta.categoria">
                  <option value="geral">Geral</option>
                  <option value="medicamentos">Medicamentos</option>
                  <option value="material_escritorio">Material de Escritório</option>
                  <option value="material_odontologico">Material Odontológico</option>
                  <option value="material_medico_hospitalar">Material Médico-Hospitalar</option>
                  <option value="equipamentos">Equipamentos</option>
                  <option value="outros_materiais">Outros Materiais</option>
                </select>
              </div>

              <div class="form-group">
                <label for="minuta-descricao">Descrição</label>
                <textarea 
                  id="minuta-descricao" 
                  v-model="novaMinuta.descricao" 
                  rows="3"
                  placeholder="Descrição opcional da minuta..."
                ></textarea>
              </div>

              <div class="form-group">
                <label for="minuta-arquivo">Arquivo da Minuta (Word)*</label>
                <input 
                  id="minuta-arquivo" 
                  type="file" 
                  accept=".docx,.doc"
                  @change="handleMinutaUpload"
                  required
                >
                <small>Arquivo Word (.docx ou .doc) com a minuta-padrão (máximo 10MB)</small>
              </div>

              <div class="form-actions">
                <button type="button" @click="fecharModalAddMinuta" class="btn-secondary">
                  Cancelar
                </button>
                <button type="submit" class="btn-primary" :disabled="salvandoMinuta">
                  {{ salvandoMinuta ? 'Salvando...' : 'Salvar Minuta' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <!-- Modal Visualizar Edital -->
      <div v-if="modalVisualizarEdital" class="modal-overlay" @click="fecharModalVisualizarEdital">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>👁️ {{ editalSelecionado.numero }} - {{ editalSelecionado.descricao }}</h3>
            <button @click="fecharModalVisualizarEdital" class="btn-close">&times;</button>
          </div>
          
          <div class="modal-body">
            <div class="edital-detalhes">
              <div class="info-section">
                <h4>📋 Informações Gerais</h4>
                <div class="info-grid">
                  <div><strong>Número:</strong> {{ editalSelecionado.numero }}</div>
                  <div><strong>Status:</strong> 
                    <span :class="'badge status-' + editalSelecionado.status.toLowerCase()">
                      {{ editalSelecionado.status }}
                    </span>
                  </div>
                  <template v-if="editalSelecionado.status === 'PUBLICADO'">
                    <div><strong>Data Publicação:</strong> {{ formatDate(editalSelecionado.data_publicacao) }}</div>
                    <div v-if="editalSelecionado.data_limite_impugnacao">
                      <strong>Prazo Impugnação:</strong> {{ formatDate(editalSelecionado.data_limite_impugnacao) }}
                    </div>
                  </template>
                </div>
              </div>

              <!-- Seção de Minuta (apenas para editais em elaboração) -->
              <div v-if="editalSelecionado.status === 'RASCUNHO'" class="info-section">
                <h4>📄 Minuta-Padrão</h4>
                <div class="minuta-workflow">
                  <div class="workflow-step" :class="{ active: true }">
                    <div class="step-number">1</div>
                    <div class="step-content">
                      <h5>Baixar Minuta</h5>
                      <p>Baixe a minuta-padrão selecionada</p>
                      <button @click="baixarMinutaPadrao(editalSelecionado)" class="btn-primary btn-small">
                        📥 Baixar Minuta-Padrão
                      </button>
                    </div>
                  </div>
                  
                  <div class="workflow-step" :class="{ active: editalSelecionado.minuta_preenchida_url }">
                    <div class="step-number">2</div>
                    <div class="step-content">
                      <h5>Enviar Minuta Preenchida</h5>
                      <p>Após preencher, envie a minuta</p>
                      <div v-if="!editalSelecionado.minuta_preenchida_url">
                        <input 
                          type="file" 
                          accept=".docx,.doc" 
                          @change="handleMinutaPreenchidaUpload"
                          ref="minutaPreenchidaInput"
                          style="display: none"
                        >
                        <button @click="$refs.minutaPreenchidaInput.click()" class="btn-primary btn-small">
                          📤 Enviar Minuta Preenchida
                        </button>
                      </div>
                      <div v-else>
                        <p class="success-text">✅ Minuta preenchida enviada</p>
                        <button @click="visualizarMinutaPreenchida(editalSelecionado)" class="btn-secondary btn-small">
                          👁️ Visualizar
                        </button>
                      </div>
                    </div>
                  </div>
                  
                  <div class="workflow-step" :class="{ active: editalSelecionado.pdf_convertido_url }">
                    <div class="step-number">3</div>
                    <div class="step-content">
                      <h5>Converter para PDF</h5>
                      <p>Finalizar e publicar edital</p>
                      <div v-if="editalSelecionado.minuta_preenchida_url && !editalSelecionado.pdf_convertido_url">
                        <!-- CORREÇÃO: Usar processarConversaoPDF para evitar problema de z-index -->
                        <button @click="processarConversaoPDF(editalSelecionado)" class="btn-primary btn-small">
                          📋 Converter para PDF e Publicar
                        </button>
                      </div>
                      <div v-else-if="editalSelecionado.pdf_convertido_url">
                        <p class="success-text">✅ PDF gerado e publicado</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div v-if="editalSelecionado.conteudo" class="info-section">
                <h4>📄 Conteúdo</h4>
                <div class="conteudo-texto">{{ editalSelecionado.conteudo }}</div>
              </div>

              <div class="info-section">
                <h4>📊 Estatísticas</h4>
                <div class="stats-grid">
                  <div class="mini-stat">
                    
                  </div>
                  <div class="mini-stat">
                    <span class="mini-stat-value">{{ editalSelecionado.produtos_submetidos || 0 }}</span>
                    <span class="mini-stat-label">Produtos Submetidos</span>
                  </div>
                  <div class="mini-stat">
                    <span class="mini-stat-value">{{ editalSelecionado.impugnacoes_count || 0 }}</span>
                    <span class="mini-stat-label">Impugnações</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="modal-actions">
              <button 
                v-if="editalSelecionado.url_documento || editalSelecionado.pdf_convertido_url" 
                @click="abrirDocumento(editalSelecionado.url_documento || editalSelecionado.pdf_convertido_url)"
                class="btn-primary"
              >
                📄 Abrir PDF
              </button>
              <button 
                v-if="editalSelecionado.url_documento || editalSelecionado.pdf_convertido_url" 
                @click="baixarDocumento(editalSelecionado)"
                class="btn-secondary"
              >
                📥 Baixar PDF
              </button>
              <button @click="fecharModalVisualizarEdital" class="btn-secondary">
                Fechar
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Seção de Impugnações -->
      <div class="impugnacoes-section">
        <div class="section-header">
          <h3>Impugnações ao Edital</h3>
          <button @click="abrirModalNovaImpugnacao" class="btn-primary">
            ➕ Nova Impugnação
          </button>
        </div>
        <table v-if="impugnacoes.length > 0">
          <thead>
            <tr>
              <th>Impugnante</th>
              <th>Produto</th>
              <th>Data da Impugnação</th>
              <th>Prazo Final</th>
              <th>Status</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="impugnacao in impugnacoes" :key="impugnacao.id">
              <td>{{ impugnacao.impugnante }}</td>
              <td>{{ impugnacao.produto_nome }}</td>
              <td>{{ formatDate(impugnacao.data_impugnacao) }}</td>
              <td>{{ formatDate(impugnacao.prazo_final) }}</td>
              <td>
                <span v-if="impugnacao.status === 'DEFERIDA'" class="status-badge status-aprovado">
                  DEFERIDA
                </span>
                <span v-else-if="impugnacao.status === 'INDEFERIDA'" class="status-badge status-reprovado">
                  INDEFERIDA
                </span>
                <span v-else class="status-badge status-pendente">
                  {{ impugnacao.status }}
                </span>
              </td>
              <td>
                <button 
                  v-if="impugnacao.status === 'EM_ANALISE' || !impugnacao.data_decisao"
                  @click="analisarImpugnacao(impugnacao.id)" 
                  class="btn-small"
                >
                  Visualizar
                </button>
                <button 
                  v-if="impugnacao.status !== 'EM_ANALISE' && impugnacao.data_decisao"
                  @click="verDecisaoImpugnacao(impugnacao.id)" 
                  class="btn-small btn-info"
                >
                  Ver Decisão
                </button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else>Não há impugnações apresentadas.</p>
      </div>

      <!-- Modal Nova Impugnação -->
      <div v-if="modalNovaImpugnacao" class="modal-overlay" @click="fecharModalNovaImpugnacao">
        <div class="modal-content medium" @click.stop>
          <div class="modal-header">
            <h3>➕ Nova Impugnação ao Edital</h3>
            <button @click="fecharModalNovaImpugnacao" class="btn-close">&times;</button>
          </div>
          
          <div class="modal-body">
            <form @submit.prevent="salvarNovaImpugnacao">
              <div class="form-group">
                <label for="editalImpugnacao">Edital *</label>
                <select id="editalImpugnacao" v-model="novaImpugnacao.edital_id" required :disabled="carregandoEditais">
                  <option value="">{{ carregandoEditais ? 'Carregando editais...' : 'Selecione um edital...' }}</option>
                  <option 
                    v-for="edital in editaisParaImpugnacao" 
                    :key="edital.id" 
                    :value="edital.id"
                    :disabled="!editalDentroDoPrazo(edital)"
                  >
                    {{ edital.numero }} - {{ edital.descricao }}
                    <span v-if="!editalDentroDoPrazo(edital)"> (Prazo vencido)</span>
                  </option>
                </select>
                <small v-if="editalSelecionadoInfo" class="help-text">
                  Prazo para impugnação: {{ formatDate(editalSelecionadoInfo.data_limite_impugnacao) }}
                </small>
              </div>

              <div class="form-group">
                <label for="impugnante">Nome do Impugnante *</label>
                <input 
                  id="impugnante" 
                  v-model="novaImpugnacao.impugnante" 
                  type="text" 
                  placeholder="Ex: João Silva"
                  required
                >
              </div>

              <div class="form-group">
                <label for="emailImpugnante">Email *</label>
                <input 
                  id="emailImpugnante" 
                  v-model="novaImpugnacao.email" 
                  type="email" 
                  placeholder="Ex: joao@empresa.com"
                  required
                >
              </div>

              <div class="form-group">
                <label for="empresaImpugnante">Empresa</label>
                <input 
                  id="empresaImpugnante" 
                  v-model="novaImpugnacao.empresa" 
                  type="text" 
                  placeholder="Ex: Empresa XYZ Ltda"
                >
              </div>

              <div class="form-group">
                <label for="motivoImpugnacao">Motivo da Impugnação *</label>
                <textarea 
                  id="motivoImpugnacao" 
                  v-model="novaImpugnacao.motivo" 
                  rows="4"
                  placeholder="Descreva o motivo da impugnação..."
                  required
                ></textarea>
              </div>

              <div class="form-group">
                <label for="documentosImpugnacao">Documentos de Apoio</label>
                <input 
                  id="documentosImpugnacao" 
                  type="file" 
                  @change="handleDocumentosUpload"
                  multiple
                  accept=".pdf,.doc,.docx,.jpg,.png"
                >
                <small>Arquivos suportados: PDF, DOC, DOCX, JPG, PNG (máximo 5MB cada)</small>
              </div>

              <div class="form-actions">
                <button type="button" @click="fecharModalNovaImpugnacao" class="btn-secondary">
                  Cancelar
                </button>
                <button type="submit" class="btn-primary" :disabled="salvandoImpugnacao">
                  <span v-if="salvandoImpugnacao">Salvando...</span>
                  <span v-else>Registrar Impugnação</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Aba Marcas Despadronizadas -->
    <div v-if="activeTab === 'despadronizadas'" class="marcas-despadronizadas">
      <GerenciadorMarcasDespadronizadas ref="gerenciadorMarcas" />
    </div>
    
    <!-- Aba Emissão de Certificados (DCB) -->
    <div v-if="activeTab === 'certificados'" class="certificados-dcb">
      <div class="dcb-container">
        <!-- Cabeçalho com Stats -->
        <div class="dcb-stats">
          <div class="stat-card dcb-pendentes">
            <h4>🟡 Prontos para DCB</h4>
            <div class="stat-value">{{ produtosProntosDCB.length }}</div>
            <small>Produtos aprovados sem DCB</small>
        </div>
          <div class="stat-card dcb-emitidos">
                            <h4>✅ DCBs Emitidas</h4>
            <div class="stat-value">{{ dcbsEmitidos.length }}</div>
            <small>Certificados válidos</small>
      </div>
          <div class="stat-card dcb-vencendo">
                            <h4>⚠️ DCBs Vencendo</h4>
            <div class="stat-value">{{ dcbsVencendo.length }}</div>
            <small>Próximos 30 dias</small>
          </div>
          <div class="stat-card dcb-vencidos">
                            <h4>🔴 DCBs Vencidas</h4>
            <div class="stat-value">{{ dcbsVencidos.length }}</div>
            <small>Precisam renovação</small>
          </div>
        </div>

        <!-- Abas do DCB -->
        <div class="dcb-tabs">
          <div 
            class="dcb-tab" 
            :class="{ active: activeTabDCB === 'emitir' }" 
            @click="activeTabDCB = 'emitir'"
          >
            📝 Emitir DCB
          </div>
          <div 
            class="dcb-tab" 
            :class="{ active: activeTabDCB === 'historico' }" 
            @click="activeTabDCB = 'historico'"
          >
            📋 Histórico DCBs
          </div>
          <div 
            class="dcb-tab" 
            :class="{ active: activeTabDCB === 'vencimentos' }" 
            @click="activeTabDCB = 'vencimentos'"
          >
            ⏰ Controle Vencimentos
          </div>
        </div>

        <!-- Sub-aba: Emitir DCB -->
        <div v-if="activeTabDCB === 'emitir'" class="dcb-content">
          <div class="section-header">
            <h3>📝 Produtos Prontos para Certificação DCB</h3>
            <p>Produtos aprovados pela CPM que ainda não possuem DCB emitida.</p>
          </div>

          <!-- Filtros para Emissão -->
          <div class="filtros-dcb">
            <div class="filtro-group">
              <label>🔍 Buscar:</label>
              <input 
                v-model="filtrosDCB.busca" 
                type="text" 
                placeholder="Nome, marca ou fabricante..."
                @input="aplicarFiltrosDCB"
              >
            </div>
            <div class="filtro-group">
              <label>📂 Categoria:</label>
              <select v-model="filtrosDCB.categoria" @change="aplicarFiltrosDCB">
                <option value="">Todas</option>
                <option value="medicamentos">Medicamentos</option>
                <option value="materiais_medicos">Materiais Médicos</option>
                <option value="equipamentos">Equipamentos</option>
                <option value="administrativo">Administrativo</option>
              </select>
            </div>
            <div class="filtro-group">
              <label>📅 Data Aprovação:</label>
              <input 
                v-model="filtrosDCB.dataAprovacao" 
                type="date" 
                @change="aplicarFiltrosDCB"
              >
            </div>
            <button @click="limparFiltrosDCB" class="btn-limpar">🗑️ Limpar</button>
          </div>

          <!-- Lista de Produtos para DCB -->
          <div v-if="produtosProntosDCBFiltrados.length > 0" class="produtos-dcb-lista">
            <div 
              v-for="produto in produtosProntosDCBFiltrados" 
              :key="produto.id" 
              class="produto-dcb-card"
            >
              <div class="produto-info">
                <div class="produto-header">
                  <h4>{{ produto.nome }}</h4>
                  <span class="status-badge status-aprovado">✅ Aprovado</span>
                </div>
                <div class="produto-details">
                  <p><strong>Marca:</strong> {{ produto.marca }}</p>
                  <p><strong>Modelo:</strong> {{ produto.modelo || 'N/A' }}</p>
                  <p><strong>Fabricante:</strong> {{ produto.fabricante }}</p>
                                     <p><strong>Data Aprovação:</strong> {{ formatDate(produto.data_aprovacao || produto.aprovado_em || produto.criado_em) }}</p>
                </div>
              </div>
              <div class="produto-actions">
                <button 
                  @click="visualizarProdutoDetalhes(produto)" 
                  class="btn-secondary"
                >
                  👁️ Detalhes
                </button>
                <button 
                  @click="emitirDCB(produto)" 
                  class="btn-primary"
                  :disabled="emitindoDCB === produto.id"
                >
                  <span v-if="emitindoDCB === produto.id">⏳ Emitindo...</span>
                  <span v-else>📜 Emitir DCB</span>
                </button>
              </div>
            </div>
          </div>
          
          <div v-else-if="produtosProntosDCB.length === 0" class="empty-state">
            <div class="empty-icon">📝</div>
            <h3>Nenhum produto pronto para DCB</h3>
            <p>Todos os produtos aprovados já possuem DCB emitido ou não há produtos aprovados.</p>
          </div>

          <div v-else class="empty-state">
            <div class="empty-icon">🔍</div>
            <h3>Nenhum produto encontrado</h3>
            <p>Nenhum produto corresponde aos filtros aplicados.</p>
          </div>
        </div>

        <!-- Sub-aba: Histórico DCBs -->
        <div v-if="activeTabDCB === 'historico'" class="dcb-content">
          <div class="section-header">
            <h3>📋 Histórico de DCBs Emitidas</h3>
            <p>Todos os certificados DCB emitidos pelo sistema.</p>
          </div>

          <!-- Filtros para Histórico -->
          <div class="filtros-dcb">
            <div class="filtro-group">
              <label>🔢 Número DCB:</label>
              <input 
                v-model="filtrosHistorico.numeroDCB" 
                type="text" 
                placeholder="Ex: 001/2024"
                @input="aplicarFiltrosHistorico"
              >
            </div>
            <div class="filtro-group">
              <label>📊 Status:</label>
              <select v-model="filtrosHistorico.status" @change="aplicarFiltrosHistorico">
                <option value="">Todos</option>
                <option value="ativo">Ativo</option>
                <option value="vencido">Vencido</option>
                <option value="revogado">Revogado</option>
              </select>
            </div>
            <div class="filtro-group">
              <label>📅 Período:</label>
              <input 
                v-model="filtrosHistorico.dataInicio" 
                type="date" 
                @change="aplicarFiltrosHistorico"
              >
              <span>até</span>
              <input 
                v-model="filtrosHistorico.dataFim" 
                type="date" 
                @change="aplicarFiltrosHistorico"
              >
            </div>
          </div>

          <!-- Tabela de Histórico -->
          <div v-if="dcbsHistoricoFiltrados.length > 0" class="dcb-historico-tabela">
            <table>
              <thead>
                <tr>
                  <th>Número DCB</th>
                  <th>Produto</th>
                  <th>Marca</th>
                  <th>Data Emissão</th>
                  <th>Validade</th>
                  <th>Status</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="dcb in dcbsHistoricoFiltrados" :key="dcb.id">
                  <td class="dcb-numero">{{ dcb.numero_dcb }}</td>
                  <td>{{ dcb.produto_nome }}</td>
                  <td>{{ dcb.produto_marca }}</td>
                  <td>{{ formatDate(dcb.data_emissao) }}</td>
                  <td>{{ formatDate(dcb.data_validade) }}</td>
                  <td>
                    <span class="status-badge" :class="getStatusDCBClass(dcb.status)">
                      {{ formatStatusDCB(dcb.status) }}
                    </span>
                  </td>
                  <td>
                    <div class="acoes-dcb">
                      <button @click="visualizarDCB(dcb)" class="btn-small">
                        👁️ Ver
                      </button>
                      <button @click="downloadDCB(dcb)" class="btn-small">
                        📥 PDF
                      </button>
                      <button 
                        v-if="dcb.status === 'ativo'" 
                        @click="revogarDCB(dcb)" 
                        class="btn-small btn-danger"
                      >
                        🚫 Revogar
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div v-else class="empty-state">
            <div class="empty-icon">📋</div>
            <h3>Nenhum DCB encontrado</h3>
            <p>Nenhum certificado corresponde aos filtros aplicados.</p>
          </div>
        </div>

        <!-- Sub-aba: Controle de Vencimentos -->
        <div v-if="activeTabDCB === 'vencimentos'" class="dcb-content">
          <div class="section-header">
            <h3>⏰ Controle de Vencimentos DCB</h3>
            <p>Monitoramento de DCBs prestes a vencer ou já vencidas.</p>
          </div>

          <!-- Alertas de Vencimento -->
          <div class="alertas-vencimento">
            <div v-if="dcbsVencendo.length > 0" class="alerta-warning">
              <div class="alerta-icon">⚠️</div>
              <div class="alerta-content">
                <h4>{{ dcbsVencendo.length }} DCB(s) vencendo nos próximos 30 dias</h4>
                <p>É recomendado iniciar o processo de renovação.</p>
              </div>
            </div>

            <div v-if="dcbsVencidos.length > 0" class="alerta-danger">
              <div class="alerta-icon">🔴</div>
              <div class="alerta-content">
                <h4>{{ dcbsVencidos.length }} DCB(s) vencido(s)</h4>
                <p>Produtos não podem ser utilizados em licitações até renovação.</p>
              </div>
            </div>
          </div>

          <!-- DCBs Vencendo -->
          <div v-if="dcbsVencendo.length > 0" class="dcb-vencimento-section">
            <h4>⚠️ DCBs Vencendo (Próximos 30 dias)</h4>
            <div class="dcb-vencimento-lista">
              <div 
                v-for="dcb in dcbsVencendo" 
                :key="dcb.id" 
                class="dcb-vencimento-card warning"
              >
                <div class="dcb-info">
                  <h5>{{ dcb.numero_dcb }} - {{ dcb.produto_nome }}</h5>
                  <p><strong>Marca:</strong> {{ dcb.produto_marca }}</p>
                  <p><strong>Vence em:</strong> {{ formatDate(dcb.data_validade) }}</p>
                  <p><strong>Dias restantes:</strong> {{ calcularDiasRestantes(dcb.data_validade) }}</p>
                </div>
                <div class="dcb-actions">
                  <button @click="iniciarRenovacao(dcb)" class="btn-warning">
                    🔄 Renovar
                  </button>
                  <button @click="visualizarDCB(dcb)" class="btn-secondary">
                    👁️ Ver DCB
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- DCBs Vencidos -->
          <div v-if="dcbsVencidos.length > 0" class="dcb-vencimento-section">
            <h4>🔴 DCBs Vencidos</h4>
            <div class="dcb-vencimento-lista">
              <div 
                v-for="dcb in dcbsVencidos" 
                :key="dcb.id" 
                class="dcb-vencimento-card danger"
              >
                <div class="dcb-info">
                  <h5>{{ dcb.numero_dcb }} - {{ dcb.produto_nome }}</h5>
                  <p><strong>Marca:</strong> {{ dcb.produto_marca }}</p>
                  <p><strong>Venceu em:</strong> {{ formatDate(dcb.data_validade) }}</p>
                  <p><strong>Vencido há:</strong> {{ calcularDiasVencidos(dcb.data_validade) }} dias</p>
                </div>
                <div class="dcb-actions">
                  <button @click="renovarDCBVencido(dcb)" class="btn-danger">
                    🔄 Renovar Urgente
                  </button>
                  <button @click="visualizarDCB(dcb)" class="btn-secondary">
                    👁️ Ver DCB
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div v-if="dcbsVencendo.length === 0 && dcbsVencidos.length === 0" class="empty-state">
            <div class="empty-icon">✅</div>
            <h3>Todos os DCBs estão em dia!</h3>
            <p>Não há certificados vencidos ou próximos ao vencimento.</p>
          </div>
        </div>
      </div>

      <!-- Modal de Detalhes do Produto -->
      <div v-if="modalProdutoDetalhes" class="modal-overlay" @click="fecharModalDetalhes">
        <div class="modal-content produto-detalhes-modal" @click.stop>
          <div class="modal-header">
            <h3>📋 Detalhes do Produto</h3>
            <button @click="fecharModalDetalhes" class="btn-close">✕</button>
          </div>
          <div class="modal-body" v-if="produtoSelecionado">
            <div class="produto-detalhes-grid">
              <div class="detalhes-section">
                <h4>📦 Informações Básicas</h4>
                <p><strong>Nome:</strong> {{ produtoSelecionado.nome }}</p>
                <p><strong>Marca:</strong> {{ produtoSelecionado.marca }}</p>
                <p><strong>Modelo:</strong> {{ produtoSelecionado.modelo || 'N/A' }}</p>
                <p><strong>Fabricante:</strong> {{ produtoSelecionado.fabricante }}</p>
                <p><strong>CNPJ:</strong> {{ produtoSelecionado.cnpj_fabricante || produtoSelecionado.cnpj || 'Não informado' }}</p>
              </div>
              <div class="detalhes-section">
                <h4>✅ Status da Aprovação</h4>
                <p><strong>Status:</strong> 
                  <span class="status-badge status-aprovado">{{ formatarStatus(produtoSelecionado.status) }}</span>
                </p>
                <p><strong>Data Aprovação:</strong> {{ formatDate(produtoSelecionado.data_aprovacao || produtoSelecionado.aprovado_em || produtoSelecionado.criado_em) }}</p>
                <p><strong>Aprovado por:</strong> {{ produtoSelecionado.aprovado_por_nome || 'Sistema' }}</p>
              </div>
            </div>
            <div v-if="produtoSelecionado.especificacoes_tecnicas" class="detalhes-section">
              <h4>🔧 Especificações Técnicas</h4>
              <pre>{{ formatarEspecificacoes(produtoSelecionado.especificacoes_tecnicas) }}</pre>
            </div>
            <div v-if="produtoSelecionado.observacoes_internas" class="detalhes-section">
              <h4>📝 Observações</h4>
              <p>{{ produtoSelecionado.observacoes_internas }}</p>
            </div>
          </div>
          <div class="modal-footer">
            <button @click="fecharModalDetalhes" class="btn-secondary">Fechar</button>
            <button @click="emitirDCB(produtoSelecionado)" class="btn-primary">
              📜 Emitir DCB
            </button>
          </div>
        </div>
      </div>

      <!-- Modal de Visualização DCB -->
      <div v-if="modalVisualizarDCB" class="modal-overlay" @click="fecharModalDCB">
        <div class="modal-content dcb-visualizar-modal" @click.stop>
          <div class="modal-header">
            <h3>📜 Visualizar DCB</h3>
            <button @click="fecharModalDCB" class="btn-close">✕</button>
          </div>
          <div class="modal-body" v-if="dcbSelecionado">
            <div class="dcb-preview">
              <div class="dcb-header">
                <h2>DECLARAÇÃO DE CONFORMIDADE DE BEM</h2>
                <h3>DCB Nº {{ dcbSelecionado.numero_dcb }}</h3>
              </div>
              <div class="dcb-content-preview">
                <div class="dcb-section">
                  <h4>PRODUTO CERTIFICADO</h4>
                  <p><strong>Nome:</strong> {{ dcbSelecionado.produto_nome }}</p>
                  <p><strong>Marca:</strong> {{ dcbSelecionado.produto_marca }}</p>
                  <p><strong>Modelo:</strong> {{ dcbSelecionado.produto_modelo || 'N/A' }}</p>
                  <p><strong>Fabricante:</strong> {{ dcbSelecionado.produto_fabricante }}</p>
                </div>
                <div class="dcb-section">
                  <h4>DADOS DO CERTIFICADO</h4>   
                  <p><strong>Data de Emissão:</strong> {{ formatDate(dcbSelecionado.data_emissao) }}</p>
                  <p><strong>Validade:</strong> {{ formatDate(dcbSelecionado.data_validade) }}</p>
                  <p><strong>Status:</strong> 
                    <span class="status-badge" :class="getStatusDCBClass(dcbSelecionado.status)">
                      {{ formatStatusDCB(dcbSelecionado.status) }}
                    </span>
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button @click="fecharModalDCB" class="btn-secondary">Fechar</button>
            <button @click="downloadDCB(dcbSelecionado)" class="btn-primary">
              📥 Download PDF
            </button>
          </div>
        </div>
      </div>

      <!-- Modal Gerenciar Participantes -->
      <div v-show="modalParticipantes" class="modal-participantes-overlay">
        <div class="modal-participantes-content">
          <div class="modal-participantes-header">
            <h3>👥 Participantes - {{ editalSelecionado.numero }}</h3>
            <button @click="fecharModalParticipantes" class="btn-close-participantes">&times;</button>
          </div>
          
          <div class="modal-participantes-body">
            <!-- Cabeçalho com filtros e botão adicionar -->
            <div class="participantes-header">
              <div class="filtros-participantes">
                <div class="filtro-group">
                  <label>🔍 Buscar:</label>
                  <input 
                    v-model="filtroParticipantes.busca" 
                    type="text" 
                    placeholder="Nome, CNPJ, representante..."
                    @input="aplicarFiltrosParticipantes"
                  >
                </div>
                <div class="filtro-group">
                  <label>📊 Status:</label>
                  <select v-model="filtroParticipantes.status" @change="aplicarFiltrosParticipantes">
                    <option value="">Todos</option>
                    <option value="INTERESSADO">Interessado</option>
                    <option value="DOCUMENTACAO_ENVIADA">Documentação Enviada</option>
                    <option value="EM_AVALIACAO">Em Avaliação</option>
                    <option value="APROVADO">Aprovado</option>
                    <option value="REPROVADO">Reprovado</option>
                    <option value="DESISTENTE">Desistente</option>
                  </select>
                </div>
              </div>
              <button @click="abrirModalNovoParticipante" class="btn-primary">
                ➕ Adicionar Participante
              </button>
            </div>

            <!-- Lista de Participantes -->
            <div v-if="loadingParticipantes" class="loading-state">
              <div class="spinner"></div>
              <p>Carregando participantes...</p>
            </div>

            <div v-else-if="participantesFiltrados.length > 0" class="participantes-lista">
              <div 
                v-for="participante in participantesFiltrados" 
                :key="participante.id" 
                class="participante-card"
              >
                <div class="participante-info">
                  <div class="participante-header">
                    <h4>{{ participante.razao_social }}</h4>
                    <span class="status-badge" :class="getStatusClass(participante.status)">
                      {{ formatarStatus(participante.status) }}
                    </span>
                  </div>
                  <div class="participante-details">
                    <p><strong>CNPJ:</strong> {{ formatarCNPJ(participante.cnpj) }}</p>
                    <p><strong>Representante:</strong> {{ participante.representante_legal }}</p>
                    <p><strong>Email:</strong> {{ participante.email }}</p>
                    <p v-if="participante.telefone"><strong>Telefone:</strong> {{ participante.telefone }}</p>
                    <p><strong>Data Participação:</strong> {{ formatDate(participante.data_participacao) }}</p>
                    <p v-if="participante.data_envio_documentacao">
                      <strong>Documentação Enviada:</strong> {{ formatDate(participante.data_envio_documentacao) }}
                    </p>
                    <p v-if="participante.observacoes">
                      <strong>Observações:</strong> {{ participante.observacoes }}
                    </p>
                  </div>
                </div>
                <div class="participante-actions">
                  <button @click="editarParticipante(participante)" class="btn-secondary btn-small">
                    ✏️ Editar
                  </button>
                  <button @click="removerParticipante(participante)" class="btn-danger btn-small">
                    🗑️ Remover
                  </button>
                </div>
              </div>
            </div>

            <div v-else class="empty-state">
              <div class="empty-icon">👥</div>
              <h3>Nenhum participante encontrado</h3>
              <p v-if="filtroParticipantes.busca || filtroParticipantes.status">
                Nenhum participante corresponde aos filtros aplicados.
              </p>
              <p v-else>
                Ainda não há participantes neste edital. Clique em "Adicionar Participante" para começar.
              </p>
            </div>
          </div>
          
          <div class="modal-participantes-footer">
            <button @click="fecharModalParticipantes" class="btn-secondary">Fechar</button>
          </div>
        </div>
      </div>

      <!-- Modal Novo/Editar Participante -->
      <div v-if="modalNovoParticipante" class="modal-overlay" @click="fecharModalNovoParticipante">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>{{ participanteAtual.id ? '✏️ Editar Participante' : '➕ Novo Participante' }}</h3>
            <button @click="fecharModalNovoParticipante" class="btn-close">&times;</button>
          </div>
          
          <div class="modal-body">
            <form @submit.prevent="salvarParticipante">
              <div class="form-row">
                <div class="form-group">
                  <label for="razao_social">Razão Social*</label>
                  <input 
                    id="razao_social" 
                    v-model="participanteAtual.razao_social" 
                    type="text" 
                    placeholder="Nome da empresa"
                    required
                  >
                </div>
                <div class="form-group">
                  <label for="cnpj">CNPJ*</label>
                  <input 
                    id="cnpj" 
                    v-model="participanteAtual.cnpj" 
                    type="text" 
                    placeholder="00.000.000/0000-00"
                    required
                  >
                </div>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label for="representante_legal">Representante Legal*</label>
                  <input 
                    id="representante_legal" 
                    v-model="participanteAtual.representante_legal" 
                    type="text" 
                    placeholder="Nome do representante"
                    required
                  >
                </div>
                <div class="form-group">
                  <label for="email">Email*</label>
                  <input 
                    id="email" 
                    v-model="participanteAtual.email" 
                    type="email" 
                    placeholder="contato@empresa.com"
                    required
                  >
                </div>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label for="telefone">Telefone</label>
                  <input 
                    id="telefone" 
                    v-model="participanteAtual.telefone" 
                    type="text" 
                    placeholder="(11) 99999-9999"
                  >
                </div>
                <div class="form-group">
                  <label for="status">Status</label>
                  <select id="status" v-model="participanteAtual.status">
                    <option value="INTERESSADO">Interessado</option>
                    <option value="DOCUMENTACAO_ENVIADA">Documentação Enviada</option>
                    <option value="EM_AVALIACAO">Em Avaliação</option>
                    <option value="APROVADO">Aprovado</option>
                    <option value="REPROVADO">Reprovado</option>
                    <option value="DESISTENTE">Desistente</option>
                  </select>
                </div>
              </div>

              <div class="form-group">
                <label for="endereco">Endereço</label>
                <input 
                  id="endereco" 
                  v-model="participanteAtual.endereco" 
                  type="text" 
                  placeholder="Endereço completo da empresa"
                >
              </div>

              <div class="form-group">
                <label for="observacoes">Observações</label>
                <textarea 
                  id="observacoes" 
                  v-model="participanteAtual.observacoes" 
                  rows="3"
                  placeholder="Observações sobre a participação..."
                ></textarea>
              </div>

              <div class="form-actions">
                <button type="button" @click="fecharModalNovoParticipante" class="btn-secondary">
                  Cancelar
                </button>
                <button type="submit" class="btn-primary">
                  {{ participanteAtual.id ? 'Atualizar' : 'Adicionar' }} Participante
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>

    <!-- Aba Cadastro de Usuários -->
    <div v-if="activeTab === 'usuarios'" class="usuarios-section">
      <div class="section-header">
        <h2>👥 Cadastro de Usuários</h2>
        <p>Gestão de usuários autorizados a emitir RDMs no sistema</p>
      </div>
      
      <div class="section-actions">
        <button @click="abrirModalNovoUsuario" class="btn-primary">
          ➕ Cadastrar Novo Usuário
        </button>
      </div>

      <!-- Lista de Usuários -->
      <div class="usuarios-container">
        <div class="filtros-usuarios">
          <div class="filtro-group">
            <label>🔍 Buscar:</label>
            <input 
              v-model="filtroUsuarios.busca" 
              type="text" 
              placeholder="Nome, unidade, coordenador..."
              @input="aplicarFiltrosUsuarios"
            >
          </div>
          <div class="filtro-group">
            <label>🏢 Unidade:</label>
            <select v-model="filtroUsuarios.unidade" @change="aplicarFiltrosUsuarios">
              <option value="">Todas</option>
              <option v-for="unidade in unidadesUnicas" :key="unidade" :value="unidade">
                {{ unidade }}
              </option>
            </select>
          </div>
        </div>

        <div v-if="usuariosFiltrados.length > 0" class="usuarios-grid">
          <div 
            v-for="usuario in usuariosFiltrados" 
            :key="usuario.id" 
            class="usuario-card"
          >
            <div class="usuario-header">
              <h4>{{ usuario.nome_usuario }}</h4>
              <div class="status-badges">
                <span class="status-badge status-ativo">Ativo</span>
                <span 
                  v-if="usuario.user_id"
                  :class="[
                    'status-convite',
                    usuario.convite_aceito ? 'aceito' : 
                    usuario.convite_enviado ? 'enviado' : 'pendente'
                  ]"
                >
                  {{ usuario.convite_aceito ? '🟢 Conectado' : 
                     usuario.convite_enviado ? '📧 Convite Enviado' : '⏳ Convite Pendente' }}
                </span>
              </div>
            </div>
            <div class="usuario-details">
              <p><strong>Unidade/Setor:</strong> {{ usuario.unidade_setor }}</p>
              <p><strong>Coordenador:</strong> {{ usuario.nome_coordenador }}</p>
              <p><strong>Telefone:</strong> {{ usuario.telefone }}</p>
              <p><strong>Email:</strong> {{ usuario.email }}</p>
              <p><strong>Materiais:</strong> {{ usuario.materiais?.length || 0 }} cadastrados</p>
              <p><strong>Próximo RDM:</strong> 
                <span class="data-rdm">{{ calcularProximoRDM(usuario) }}</span>
              </p>
            </div>
            <div class="usuario-actions">
              <button @click="editarUsuario(usuario)" class="btn-secondary btn-small">
                ✏️ Editar
              </button>
              <button @click="verMateriaisUsuario(usuario)" class="btn-info btn-small">
                📦 Materiais
              </button>
              <button 
                v-if="usuario.user_id && !usuario.convite_aceito"
                @click="reenviarConvite(usuario)" 
                class="btn-reenviar btn-small"
              >
                📧 Reenviar Convite
              </button>
              <button @click="removerUsuario(usuario)" class="btn-danger btn-small">
                🗑️ Remover
              </button>
            </div>
          </div>
        </div>

        <div v-else class="empty-state">
          <div class="empty-icon">👥</div>
          <h3>Nenhum usuário cadastrado</h3>
          <p>Clique em "Cadastrar Novo Usuário" para começar.</p>
        </div>
      </div>

      <!-- Modal Novo/Editar Usuário -->
      <div v-if="modalNovoUsuario" class="modal-overlay" @click="fecharModalNovoUsuario">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>{{ usuarioAtual.id ? '✏️ Editar Usuário' : '👥 Novo Usuário' }}</h3>
            <button @click="fecharModalNovoUsuario" class="btn-close">&times;</button>
          </div>
          
          <div class="modal-body">
            <form @submit.prevent="salvarUsuario">
              <div class="form-row">
                <div class="form-group">
                  <label for="unidade_setor">Unidade/Setor*</label>
                  <input 
                    id="unidade_setor" 
                    v-model="usuarioAtual.unidade_setor" 
                    type="text" 
                    placeholder="Ex: Secretaria da Saúde"
                    required
                  >
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label for="nome_coordenador">Nome do Coordenador*</label>
                  <input 
                    id="nome_coordenador" 
                    v-model="usuarioAtual.nome_coordenador" 
                    type="text" 
                    placeholder="Nome completo do responsável"
                    required
                  >
                </div>
                <div class="form-group">
                  <label for="telefone_usuario">Telefone*</label>
                  <input 
                    id="telefone_usuario" 
                    v-model="usuarioAtual.telefone" 
                    type="tel" 
                    placeholder="(00) 00000-0000"
                    required
                  >
                </div>
              </div>
              
              <div class="form-group">
                <label for="email_usuario">Email*</label>
                <input 
                  id="email_usuario" 
                  v-model="usuarioAtual.email" 
                  type="email" 
                  placeholder="email@exemplo.com"
                  required
                >
              </div>

              <!-- Sistema de Login -->
              <div class="login-system-section">
                <h4>🔐 Sistema de Login</h4>
                <div class="form-group checkbox-group">
                  <label class="checkbox-label">
                    <input 
                      type="checkbox" 
                      v-model="usuarioAtual.criar_login"
                      @change="toggleLoginSystem"
                    >
                    <span class="checkmark">✓</span>
                    Permitir login no sistema (Dashboard RDM On-line)
                  </label>
                  <p class="help-text">
                    Ao marcar esta opção, o usuário receberá um e-mail da CPM, com senha de acesso, para preencher o formulário RDM.
                  </p>
                </div>
                
                <div v-if="usuarioAtual.criar_login" class="convite-info">
                  <div class="info-card">
                    <h5>📧 Convite Automático</h5>
                    <p>Será enviado automaticamente um email para <strong>{{ usuarioAtual.email }}</strong> com:</p>
                    <ul>
                      <li>Senha de acesso definitiva</li>
                      <li>Link direto para o sistema</li>
                      <li>Instruções de uso do Dashboard RDM</li>
                    </ul>
                  </div>
                </div>
              </div>

              <!-- Materiais do Usuário -->
              <div class="materiais-section">
                <h4>📦 Materiais sob Responsabilidade da Unidade</h4>
                <div class="materiais-lista">
                  <div 
                    v-for="(material, index) in usuarioAtual.materiais" 
                    :key="index" 
                    class="material-item"
                  >
                    <div class="material-fields-novo">
                      <div class="material-select">
                        <label>📦 Material/Produto:</label>
                        <select 
                          v-model="material.produto_id" 
                          @change="selecionarProduto(index, $event)"
                          :disabled="loadingProdutos"
                          required
                        >
                          <option value="" v-if="loadingProdutos">⏳ Carregando produtos...</option>
                          <option value="" v-else-if="produtosDisponiveis.length === 0">Nenhum produto encontrado</option>
                          <option value="" v-else>Selecione um produto...</option>
                          <option 
                            v-for="produto in produtosDisponiveis" 
                            :key="produto.id" 
                            :value="produto.id"
                          >
                            {{ produto.nome }} - {{ produto.marca || 'S/Marca' }} ({{ produto.codigo_material || produto.modelo || 'S/Código' }})
                          </option>
                          <option value="NOVO">➕ Cadastrar Novo Material</option>
                        </select>
                      </div>
                      
                      <!-- Campos para novo material (se selecionou "NOVO") -->
                      <div v-if="material.produto_id === 'NOVO'" class="novo-material">
                        <input 
                          v-model="material.nome" 
                          type="text" 
                          placeholder="Nome do novo material"
                          required
                        >
                        <input 
                          v-model="material.codigo" 
                          type="text" 
                          placeholder="Código do material"
                          required
                        >
                      </div>
                      
                      <div class="material-periodo">
                        <label>📅 Periodicidade RDM:</label>
                        <select v-model="material.periodicidade_rdm" required>
                          <option value="">Selecionar...</option>
                          <option value="mensal">Mensal</option>
                          <option value="bimestral">Bimestral</option>
                          <option value="trimestral">Trimestral</option>
                          <option value="semestral">Semestral</option>
                          <option value="anual">Anual</option>
                        </select>
                      </div>
                      
                      <button 
                        type="button" 
                        @click="removerMaterial(index)" 
                        class="btn-danger btn-small"
                        title="Remover material"
                      >
                        🗑️
                      </button>
                    </div>
                  </div>
                  
                                      <div class="material-actions">
                    <button 
                      type="button" 
                      @click="adicionarMaterial" 
                      class="btn-secondary"
                      :disabled="loadingProdutos"
                    >
                      <span v-if="loadingProdutos">⏳</span>
                      <span v-else>➕</span>
                      Adicionar Material
                    </button>
                    <button 
                      type="button" 
                      @click="carregarProdutos" 
                      class="btn-info btn-small"
                      :disabled="loadingProdutos"
                    >
                      <span v-if="loadingProdutos">⏳</span>
                      <span v-else>🔄</span>
                      Atualizar Lista
                    </button>
                  </div>
                  
                  <!-- Debug Info - só aparecer em desenvolvimento -->
                  <div v-if="!loadingProdutos" class="debug-info">
                    <small>
                      📊 Debug: {{ produtosDisponiveis.length }} produtos disponíveis
                      <span v-if="currentTenantId">(Tenant: {{ currentTenantId.substring(0, 8) }}...)</span>
                      <br>
                      📋 Materiais do usuário: {{ usuarioAtual.materiais?.length || 0 }}
                      <span v-if="usuarioAtual.materiais?.length > 0">
                        ({{ usuarioAtual.materiais.map(m => m.nome || 'Sem nome').join(', ') }})
                      </span>
                    </small>
                  </div>
                </div>
              </div>
              
              <div class="modal-actions">
                <button type="button" @click="fecharModalNovoUsuario" class="btn-secondary">
                  Cancelar
                </button>
                <button type="submit" class="btn-primary">
                  {{ usuarioAtual.id ? 'Atualizar' : 'Cadastrar' }} Usuário
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>

    <!-- Aba Registros de Reclamações -->
    <div v-if="activeTab === 'reclamacoes'" class="reclamacoes-section">
      <div class="section-header">
        <h2>📢 Registros de Reclamações</h2>
        <p>Gerenciamento de reclamações públicas dos usuários</p>
      </div>
      
      <div class="section-actions">
        <div class="stats-reclamacoes">
          <span class="stat-item">📊 Total: {{ reclamacoes.length }}</span>
          <span class="stat-item">🔍 Filtradas: {{ reclamacoesFiltradas.length }}</span>
          <span class="stat-item pendentes">⏳ Pendentes: {{ reclamacoesPendentes }}</span>
          <span class="stat-item respondidas">✅ Respondidas: {{ reclamacoesRespondidas }}</span>
        </div>
      </div>

      <!-- Filtros para Reclamações -->
      <div class="filtros-reclamacoes">
        <div class="filtro-group">
          <label>🔍 Buscar:</label>
          <input 
            v-model="filtroReclamacoes.busca" 
            type="text" 
            placeholder="Título, nome, descrição..."
            @input="aplicarFiltrosReclamacoes"
          >
        </div>
        <div class="filtro-group">
          <label>📊 Status:</label>
          <select v-model="filtroReclamacoes.status" @change="aplicarFiltrosReclamacoes">
            <option value="">Todos</option>
            <option value="pendente">⏳ Pendente</option>
            <option value="em_analise">🔍 Em Análise</option>
            <option value="respondida">✅ Respondida</option>
            <option value="resolvida">🎯 Resolvida</option>
          </select>
        </div>
        <div class="filtro-group">
          <label>⚡ Prioridade:</label>
          <select v-model="filtroReclamacoes.prioridade" @change="aplicarFiltrosReclamacoes">
            <option value="">Todas</option>
            <option value="baixa">🟢 Baixa</option>
            <option value="normal">🔵 Normal</option>
            <option value="alta">🟡 Alta</option>
            <option value="critica">🔴 Crítica</option>
          </select>
        </div>
      </div>

      <!-- Lista de Reclamações -->
      <div v-if="reclamacoesFiltradas.length > 0" class="reclamacoes-lista">
        <div 
          v-for="reclamacao in reclamacoesFiltradas" 
          :key="reclamacao.id" 
          class="reclamacao-card"
        >
          <div class="reclamacao-header">
            <div class="reclamacao-info">
              <div class="reclamacao-meta">
                <span class="reclamante">👤 {{ reclamacao.nome_reclamante }}</span>
                <span v-if="reclamacao.setor_reclamante" class="setor">🏢 {{ reclamacao.setor_reclamante }}</span>
                <span class="data">📅 {{ formatDate(reclamacao.criado_em) }}</span>
              </div>
            </div>
            <div class="reclamacao-badges">
              <span class="status-badge" :class="getStatusClass(reclamacao.status)">
                {{ getStatusText(reclamacao.status) }}
              </span>
              <span class="prioridade-badge" :class="getPrioridadeClass(reclamacao.prioridade)">
                {{ getPrioridadeText(reclamacao.prioridade) }}
              </span>
            </div>
          </div>
          
          <div class="reclamacao-content">
            <div class="reclamacao-detalhes">
              <div class="descricao-reclamacao">
                <h5>📝 Descrição da Reclamação:</h5>
                <p>{{ reclamacao.descricao_reclamacao }}</p>
              </div>
              
              <!-- Ações da CPM -->
              <div class="cpm-acoes">
                <!-- Alterar Status -->
                <div class="acao-group">
                  <label>📊 Alterar Status:</label>
                  <select 
                    v-model="reclamacao.novo_status" 
                    @change="alterarStatusReclamacao(reclamacao)"
                    :disabled="salvandoStatus"
                  >
                    <option :value="reclamacao.status">{{ getStatusText(reclamacao.status) }} (atual)</option>
                    <option value="pendente">⏳ Pendente</option>
                    <option value="em_analise">🔍 Em Análise</option>
                    <option value="respondida">✅ Respondida</option>
                    <option value="resolvida">🎯 Resolvida</option>
                  </select>
                </div>
                
                <!-- Alterar Prioridade -->
                <div class="acao-group">
                  <label>⚡ Alterar Prioridade:</label>
                  <select 
                    v-model="reclamacao.nova_prioridade" 
                    @change="alterarPrioridadeReclamacao(reclamacao)"
                    :disabled="salvandoPrioridade"
                  >
                    <option :value="reclamacao.prioridade">{{ getPrioridadeText(reclamacao.prioridade) }} (atual)</option>
                    <option value="baixa">🟢 Baixa</option>
                    <option value="normal">🔵 Normal</option>
                    <option value="alta">🟡 Alta</option>
                    <option value="critica">🔴 Crítica</option>
                  </select>
                </div>
              </div>
              
              <!-- Resposta da CPM -->
              <div class="cpm-resposta">
                <h5>💬 Resposta da CPM:</h5>
                <div v-if="reclamacao.resposta_cpm" class="resposta-existente">
                  <p>{{ reclamacao.resposta_cpm }}</p>
                  <small class="data-resposta">✅ Respondido em: {{ formatDate(reclamacao.respondido_em) }}</small>
                  <button 
                    @click="editarResposta(reclamacao)" 
                    class="btn-secondary btn-small"
                  >
                    ✏️ Editar Resposta
                  </button>
                </div>
                <div v-else class="sem-resposta">
                  <textarea 
                    v-model="reclamacao.nova_resposta" 
                    class="textarea-resposta"
                    rows="4"
                    placeholder="Digite a resposta da CPM para esta reclamação. Seja detalhado e explicativo sobre as ações tomadas ou que serão tomadas..."
                  ></textarea>
                  <div class="resposta-acoes">
                    <button 
                      @click="salvarRespostaReclamacao(reclamacao)" 
                      class="btn-primary btn-small"
                      :disabled="!reclamacao.nova_resposta || salvandoResposta"
                    >
                      <span v-if="salvandoResposta" class="spinner-small"></span>
                      {{ salvandoResposta ? 'Salvando...' : '💾 Salvar Resposta' }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Estado vazio para Reclamações -->
      <div v-if="reclamacoesFiltradas.length === 0" class="empty-state">
        <div class="empty-icon">📢</div>
        <h3>Nenhuma reclamação encontrada</h3>
        <p>Quando houver reclamações dos usuários, elas aparecerão aqui para gerenciamento.</p>
      </div>

    </div>

    <!-- Modal Editar Edital -->
    <div v-if="modalEditarEdital" class="modal-overlay" @click="fecharModalEditarEdital">
      <div class="modal-content medium" @click.stop>
        <div class="modal-header">
          <h3>✏️ Editar Edital</h3>
          <button @click="fecharModalEditarEdital" class="btn-close">&times;</button>
        </div>
        
        <div class="modal-body">
          <form @submit.prevent="salvarEdicaoEdital">
            <div class="form-group">
              <label for="numeroEdital">Número do Edital *</label>
              <input 
                id="numeroEdital"
                v-model="editalEditando.numero" 
                type="text" 
                required
                placeholder="Ex: 001/2024"
                :disabled="editalEditando.status !== 'RASCUNHO'"
              >
              <small v-if="editalEditando.status !== 'RASCUNHO'" class="help-text">
                O número não pode ser alterado após a publicação
              </small>
            </div>

            <div class="form-group">
              <label for="descricaoEdital">Descrição/Nome do Edital *</label>
              <input 
                id="descricaoEdital"
                v-model="editalEditando.descricao" 
                type="text" 
                required
                placeholder="Ex: Pré-qualificação de Equipamentos Médicos"
              >
            </div>

            <div class="form-group">
              <label for="conteudoEdital">Conteúdo Adicional</label>
              <textarea 
                id="conteudoEdital"
                v-model="editalEditando.conteudo" 
                rows="4"
                placeholder="Informações adicionais sobre o edital..."
              ></textarea>
            </div>

            <div v-if="editalEditando.status === 'PUBLICADO'" class="form-row">
              <div class="form-group">
                <label for="dataPublicacao">Data de Publicação</label>
                <input 
                  id="dataPublicacao"
                  v-model="editalEditando.data_publicacao" 
                  type="datetime-local"
                  :disabled="true"
                >
              </div>

              <div class="form-group">
                <label for="dataLimiteImpugnacao">Prazo para Impugnações</label>
                <input 
                  id="dataLimiteImpugnacao"
                  v-model="editalEditando.data_limite_impugnacao" 
                  type="datetime-local"
                  :disabled="true"
                >
              </div>
            </div>

            <div class="form-group">
              <label>Status Atual</label>
              <div class="status-display">
                <span :class="'badge status-' + editalEditando.status.toLowerCase()">
                  {{ getStatusText(editalEditando.status) }}
                </span>
              </div>
            </div>
          </form>
        </div>

        <div class="modal-footer">
          <button type="button" @click="fecharModalEditarEdital" class="btn-secondary">
            Cancelar
          </button>
          <button type="button" @click="salvarEdicaoEdital" class="btn-primary" :disabled="salvandoEdicaoEdital">
            <span v-if="salvandoEdicaoEdital" class="spinner"></span>
            {{ salvandoEdicaoEdital ? 'Salvando...' : 'Salvar Alterações' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import emailjs from '@emailjs/browser'
import EditaisService from '@/services/editaisService'
import PesquisaBot from '@/components/common/PesquisaBot.vue'
import GerenciadorCotacoes from '@/components/cotacoes/GerenciadorCotacoes.vue'
import GerenciadorComparativo from '@/components/comparativos/GerenciadorComparativo.vue'
import GerenciadorAnalisePrecos from '@/components/analise-precos/GerenciadorAnalisePrecos.vue'
import GerenciadorRelatorios from '@/components/relatorios/GerenciadorRelatorios.vue'
import GerenciadorMarcasDespadronizadas from '@/components/marcas-despadronizadas/GerenciadorMarcasDespadronizadas.vue'

export default {
  name: 'DashboardCPM',
  components: {
    PesquisaBot,
    GerenciadorCotacoes,
    GerenciadorComparativo,
    GerenciadorAnalisePrecos,
    GerenciadorRelatorios,
    GerenciadorMarcasDespadronizadas
  },
  data() {
    return {
      activeTab: 'dashboard',
      activeSubTab: 'pesquisa-tecnica',
      cotacoes: [],
      produtos: [],
      produtosComDiligencia: [],
      pendentes: 0,
      aprovados: 0,
      reprovados: 0,
      currentTenantId: null,
      loading: false,
      editais: [],
      editaisFiltrados: [],
      loadingEditais: false,
      modalNovoEdital: false,
      modalVisualizarEdital: false,
      modalEditarEdital: false,
      modalParticipantes: false,
      modalNovoParticipante: false,
      modoEdicaoEdital: false,
      salvandoEdital: false,
      salvandoEdicaoEdital: false,
      editalEditando: {
        id: null,
        numero: '',
        descricao: '',
        conteudo: '',
        status: 'RASCUNHO',
        data_publicacao: '',
        data_limite_impugnacao: ''
      },
      // Sistema de Minutas Padrão
      modalAddMinuta: false,
      minutasDisponiveis: [],
      minutaSelecionada: null,
      criandoEdital: false,
      novaMinuta: {
        nome: '',
        categoria: 'geral',
        descricao: '',
        arquivo: null
      },
      salvandoMinuta: false,
      editalAtual: {
        id: null,
        numero: '',
        descricao: '',
        conteudo: '',
        status: 'RASCUNHO',
        data_publicacao: '',
        data_limite_impugnacao: '',
        url_documento: '',
        nome_arquivo: ''
      },
      editalSelecionado: {},
      filtroEditais: {
        busca: '',
        status: ''
      },
      debounceTimer: null,
      participantes: [],
      participantesFiltrados: [],
      loadingParticipantes: false,
      participanteAtual: {
        id: null,
        razao_social: '',
        cnpj: '',
        representante_legal: '',
        email: '',
        telefone: '',
        endereco: '',
        status: 'INTERESSADO',
        observacoes: '',
        produtos_submetidos: []
      },
      filtroParticipantes: {
        busca: '',
        status: ''
      },
      impugnacoes: [],
      // Sistema de Impugnações
      modalNovaImpugnacao: false,
      salvandoImpugnacao: false,
      editaisParaImpugnacao: [],
      carregandoEditais: false,
      novaImpugnacao: {
        edital_id: '',
        impugnante: '',
        email: '',
        empresa: '',
        motivo: '',
        documentos: []
      },
      certificados: [],
      // DCB Data
      activeTabDCB: 'emitir',
      produtosProntosDCB: [],
      produtosProntosDCBFiltrados: [],
      dcbsEmitidos: [],
      dcbsHistoricoFiltrados: [],
      dcbsVencendo: [],
      dcbsVencidos: [],
      emitindoDCB: null,
      modalProdutoDetalhes: false,
      modalVisualizarDCB: false,
      produtoSelecionado: null,
      dcbSelecionado: null,
      filtrosDCB: {
        busca: '',
        categoria: '',
        dataAprovacao: ''
      },
      filtrosHistorico: {
        numeroDCB: '',
        status: '',
        dataInicio: '',
        dataFim: ''
      },
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
       diligenciasPaginadas: [],
       
       // Dados para Usuários
       usuarios: [],
       usuariosFiltrados: [],
       modalNovoUsuario: false,
       usuarioAtual: {
         id: null,
         nome_usuario: '',
         unidade_setor: '',
         nome_coordenador: '',
         telefone: '',
         email: '',
         materiais: [],
         criar_login: false,
         user_id: null,
         senha_temporaria: null,
         convite_enviado: false,
         convite_aceito: false
       },
       filtroUsuarios: {
         busca: '',
         unidade: ''
       },
       statusConvites: {},
       notificacoes: [],
       produtosDisponiveis: [],
       loadingProdutos: false,
       

       
       // Dados para Registros de Reclamações
       reclamacoes: [],
       reclamacoesFiltradas: [],
       salvandoResposta: false,
       salvandoStatus: false,
       salvandoPrioridade: false,
       filtroReclamacoes: {
         busca: '',
         status: '',
         prioridade: ''
       },
       
       // Controle de abas internas na seção de reclamações
 
       
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
    // Carregar produtos para seleção nos materiais
    await this.carregarProdutos()
    
    // Se a aba for diretamente 'lembretes', carregar dados
    if (this.activeTab === 'lembretes') {
      await this.carregarEstatisticasLembretes()
      await this.carregarRdmsPendentes()
    }
  },

  beforeUnmount() {
    // Limpar timer de debounce se existir
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
  },
  
  watch: {
    // Observar mudanças na aba ativa
    activeTab(novaAba) {
      if (novaAba === 'lembretes') {
        // Carregar dados quando acessar a aba de lembretes
        this.$nextTick(() => {
          if (this.carregarEstatisticasLembretes) {
            this.carregarEstatisticasLembretes()
          }
          if (this.carregarRdmsPendentes) {
            this.carregarRdmsPendentes()
          }
        })
      } else if (novaAba === 'despadronizadas') {
        // Recarregar dados quando acessar a aba de marcas despadronizadas
        this.$nextTick(() => {
          if (this.$refs.gerenciadorMarcas && this.$refs.gerenciadorMarcas.carregarProdutos) {
            console.log('🔄 Recarregando produtos no gerenciador de marcas...')
            this.$refs.gerenciadorMarcas.carregarProdutos()
          }
        })
      } else if (novaAba === 'reclamacoes') {
        // Carregar dados quando acessar a aba de reclamações
        this.$nextTick(() => {
          this.carregarReclamacoes()
        })
      }
    }
  },
      computed: {
      // Marcas únicas para o filtro de diligências
      marcasUnicas() {
        const marcas = [...new Set(this.produtosComDiligencia.map(p => p.marca))]
        return marcas.filter(marca => marca).sort()
      },

      // Edital selecionado para impugnação
      editalSelecionadoInfo() {
        if (!this.novaImpugnacao.edital_id) return null
        return this.editaisParaImpugnacao.find(e => e.id === this.novaImpugnacao.edital_id)
      },
      
      // Verificar se há filtros aplicados nos requerimentos
      temFiltrosAplicados() {
        return this.filtros.nome || this.filtros.marca || this.filtros.status || this.filtros.data
      },
      
      // Verificar se há filtros aplicados nas diligências
      temFiltrosDiligenciaAplicados() {
        return this.filtrosDiligencia.busca || this.filtrosDiligencia.marca || this.filtrosDiligencia.data
      },

      // Computed properties para editais
      editaisAtivos() {
        return this.editais.filter(edital => edital.status === 'PUBLICADO')
      },
      
      editaisRascunho() {
        return this.editais.filter(edital => edital.status === 'RASCUNHO')
      },
      
      // Propriedades computadas para reclamações
      reclamacoesPendentes() {
        return this.reclamacoes.filter(r => r.status === 'pendente' || r.status === 'em_analise').length
      },
      
      reclamacoesRespondidas() {
        return this.reclamacoes.filter(r => r.status === 'respondida' || r.status === 'resolvida').length
      },
      
      reclamacoesNaoRespondidas() {
        return this.reclamacoes.filter(r => r.status === 'pendente' || r.status === 'em_analise').length
      },
      
      editaisFinalizados() {
        return this.editais.filter(edital => edital.status === 'CANCELADO')
      },
      
      totalParticipantes() {
        return this.editais.reduce((total, edital) => {
          return total + (edital.participantes_count || 0)
        }, 0)
      },
      
      // Computed properties para usuários
      unidadesUnicas() {
        const unidades = [...new Set(this.usuarios.map(u => u.unidade_setor))]
        return unidades.filter(unidade => unidade).sort()
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
        
        // 📋 REQUERIMENTOS RECENTES: pendente, aprovado, reprovado, em_analise, julgado_aprovado, julgado_reprovado
        // (Incluindo produtos julgados pela CCL para manter visibilidade)
        this.produtos = produtos.filter(produto => 
          ['pendente', 'aprovado', 'reprovado', 'em_analise', 'julgado_aprovado', 'julgado_reprovado'].includes(produto.status)
        )
        console.log(`${this.produtos.length} requerimentos recentes carregados (sem diligências)`)

        // 🔍 REQUERIMENTOS COM DILIGÊNCIAS: apenas status 'diligencia'
        this.produtosComDiligencia = produtos.filter(produto => produto.status === 'diligencia')
        console.log(`${this.produtosComDiligencia.length} produtos com diligência carregados`)
        
        // Carregar impugnações reais do banco
        await this.carregarImpugnacoes()
        
        // Carregar dados DCB
        await this.carregarDadosDCB()
        
        // Carregar editais
        await this.carregarEditais()
        
        // Carregar minutas padrão
        await this.carregarMinutasDisponiveis()
        
        // Carregar usuários e reclamações
        await this.carregarUsuarios()
        await this.carregarReclamacoes()
        
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
      
      let query = supabase
        .from('produtos')
        .select('id', { count: 'exact' })
        .eq('tenant_id', this.currentTenantId) // Filtrar por tenant_id
      
      // Para 'aprovado', incluir também 'julgado_aprovado' e 'homologado'
      if (status === 'aprovado') {
        query = query.in('status', ['aprovado', 'julgado_aprovado', 'homologado'])
      } 
      // Para 'reprovado', incluir também 'julgado_reprovado'  
      else if (status === 'reprovado') {
        query = query.in('status', ['reprovado', 'julgado_reprovado'])
      }
      // Para outros status, manter filtro exato
      else {
        query = query.eq('status', status)
      }
      
      const { count, error } = await query
      
      if (error) {
        console.error(`Erro ao contar produtos ${status}:`, error)
        return 0
      }
      
      return count || 0
    },
    verProduto(id) {
      this.$router.push(`/analise/${id}`)
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

    async verDecisaoImpugnacao(id) {
      try {
        // Buscar detalhes da impugnação com a decisão
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

        const impugnacao = data
        const statusText = impugnacao.status === 'DEFERIDA' ? 'Deferida' : 
                          impugnacao.status === 'INDEFERIDA' ? 'Indeferida' : 
                          'Pendente de análise'

        this.$swal({
          title: 'Decisão da Impugnação',
          html: `
            <div style="text-align: left;">
              <h4>Impugnação de: ${impugnacao.impugnante}</h4>
              <p><strong>Edital:</strong> ${impugnacao.editais?.numero} - ${impugnacao.editais?.descricao}</p>
              <p><strong>Data da Impugnação:</strong> ${this.formatDate(impugnacao.data_impugnacao)}</p>
              <p><strong>Motivo:</strong> ${impugnacao.motivo}</p>
              <hr>
              <h4>Decisão:</h4>
              <p><strong>Status:</strong> <span style="color: ${impugnacao.status === 'DEFERIDA' ? '#27ae60' : impugnacao.status === 'INDEFERIDA' ? '#e74c3c' : '#f39c12'}">${statusText}</span></p>
              ${impugnacao.justificativa_decisao ? `<p><strong>Justificativa:</strong> ${impugnacao.justificativa_decisao}</p>` : ''}
              ${impugnacao.data_decisao ? `<p><strong>Data da Decisão:</strong> ${this.formatDate(impugnacao.data_decisao)}</p>` : ''}
              ${impugnacao.analisado_por ? `<p><strong>Analisado por:</strong> ${impugnacao.analisado_por}</p>` : ''}
              ${!impugnacao.data_decisao ? '<p><em>Esta impugnação ainda não foi analisada.</em></p>' : ''}
            </div>
          `,
          width: '600px',
          confirmButtonText: 'Fechar'
        })

      } catch (error) {
        console.error('Erro ao carregar decisão:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao carregar decisão da impugnação',
          icon: 'error'
        })
      }
    },

    // ===========================
    // MÉTODOS SISTEMA DE IMPUGNAÇÕES
    // ===========================

    async abrirModalNovaImpugnacao() {
      this.modalNovaImpugnacao = true
      this.limparFormularioImpugnacao()
      await this.carregarEditaisParaImpugnacao()
    },

    fecharModalNovaImpugnacao() {
      this.modalNovaImpugnacao = false
      this.limparFormularioImpugnacao()
    },

    async carregarEditaisParaImpugnacao() {
      try {
        this.carregandoEditais = true
        
        const { data, error } = await supabase
          .from('editais')
          .select('id, numero, descricao, status, data_publicacao, data_limite_impugnacao')
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'PUBLICADO')
          .order('data_publicacao', { ascending: false })

        if (error) throw error

        this.editaisParaImpugnacao = data || []
        
        if (this.editaisParaImpugnacao.length === 0) {
          this.$swal({
            title: 'Nenhum Edital Disponível',
            text: 'Não há editais publicados disponíveis para impugnação no momento.',
            icon: 'info'
          })
        }

      } catch (error) {
        console.error('Erro ao carregar editais:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao carregar editais disponíveis.',
          icon: 'error'
        })
      } finally {
        this.carregandoEditais = false
      }
    },

    limparFormularioImpugnacao() {
      this.novaImpugnacao = {
        edital_id: '',
        impugnante: '',
        email: '',
        empresa: '',
        motivo: '',
        documentos: []
      }
    },

    editalDentroDoPrazo(edital) {
      if (!edital.data_limite_impugnacao) return false
      const agora = new Date()
      const prazoLimite = new Date(edital.data_limite_impugnacao)
      return agora <= prazoLimite
    },

    handleDocumentosUpload(event) {
      const files = event.target.files
      this.novaImpugnacao.documentos = Array.from(files)
    },

    async salvarNovaImpugnacao() {
      if (this.salvandoImpugnacao) return

      try {
        this.salvandoImpugnacao = true

        // Validar se o edital ainda está dentro do prazo
        const editalSelecionado = this.editaisParaImpugnacao.find(e => e.id === this.novaImpugnacao.edital_id)
        if (!this.editalDentroDoPrazo(editalSelecionado)) {
          this.$swal({
            title: 'Prazo Vencido',
            text: 'O prazo para impugnação deste edital já expirou.',
            icon: 'error'
          })
          return
        }

        // Calcular prazo final (geralmente 5 dias úteis a partir da data da impugnação)
        const dataImpugnacao = new Date()
        const prazoFinal = new Date(dataImpugnacao)
        prazoFinal.setDate(prazoFinal.getDate() + 7) // 7 dias para análise

        // Preparar dados da impugnação
        const dadosImpugnacao = {
          edital_id: this.novaImpugnacao.edital_id,
          impugnante: this.novaImpugnacao.impugnante,
          email_impugnante: this.novaImpugnacao.email,
          documento_impugnante: this.novaImpugnacao.documento || '00000000000', // CPF/CNPJ padrão se não fornecido
          motivo: this.novaImpugnacao.motivo,
          data_impugnacao: dataImpugnacao.toISOString(),
          prazo_final: prazoFinal.toISOString(),
          status: 'EM_ANALISE',
          tenant_id: this.currentTenantId,
          criado_em: new Date().toISOString()
        }

        // Salvar no banco de dados
        const { data, error } = await supabase
          .from('impugnacoes')
          .insert(dadosImpugnacao)
          .select()
          .single()

        if (error) throw error

        // TODO: Upload de documentos se houver
        if (this.novaImpugnacao.documentos.length > 0) {
          // Implementar upload de documentos para o Supabase Storage
          console.log('Documentos a serem enviados:', this.novaImpugnacao.documentos)
        }

        // Sucesso
        this.$swal({
          title: 'Sucesso!',
          text: 'Impugnação registrada com sucesso. Você receberá atualizações por email.',
          icon: 'success',
          timer: 4000
        })

        // Recarregar impugnações e fechar modal
        await this.carregarImpugnacoes()
        this.fecharModalNovaImpugnacao()

      } catch (error) {
        console.error('Erro ao salvar impugnação:', error)
        this.$swal({
          title: 'Erro',
          text: error.message || 'Erro ao registrar impugnação. Tente novamente.',
          icon: 'error'
        })
      } finally {
        this.salvandoImpugnacao = false
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
       this.editaisFiltrados = [...this.editais]
       this.aplicarFiltros()
       this.aplicarFiltrosDiligencia()
       this.aplicarFiltrosEditais()
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
          'julgado_aprovado': 'Julgado Aprovado', // Status após julgamento CCL favorável
          'julgado_reprovado': 'Julgado Reprovado', // Status após julgamento CCL desfavorável
          'homologado': 'Homologado', // Status homologado
          'reprovado': 'Reprovado',
          'diligencia': 'Diligência',
          'em_analise': 'Em Análise',
          'INTERESSADO': 'Interessado',
          'DOCUMENTACAO_ENVIADA': 'Documentação Enviada',
          'EM_AVALIACAO': 'Em Avaliação',
          'APROVADO': 'Aprovado',
          'REPROVADO': 'Reprovado',
          'DESISTENTE': 'Desistente'
        }
        return statusMap[status] || status
      },
      
      getStatusClass(status) {
        const classMap = {
          'aprovado': 'status-aprovado',
          'julgado_aprovado': 'status-aprovado', // Produtos julgados pela CCL como aprovados
          'julgado_reprovado': 'status-reprovado', // Produtos julgados pela CCL como reprovados
          'homologado': 'status-aprovado', // Produtos homologados também ficam verdes
          'pendente': 'status-pendente',
          'reprovado': 'status-reprovado',
          'diligencia': 'status-diligencia',
          'em_analise': 'status-em_analise',
          'INTERESSADO': 'status-interessado',
          'DOCUMENTACAO_ENVIADA': 'status-documentacao',
          'EM_AVALIACAO': 'status-avaliacao',
          'APROVADO': 'status-aprovado',
          'REPROVADO': 'status-reprovado',
          'DESISTENTE': 'status-desistente'
        }
        return classMap[status] || `status-${status}`
      },
      
      formatDate(dateString) {
        if (!dateString) return 'Não informado'
        try {
        const date = new Date(dateString)
          if (isNaN(date.getTime())) return 'Data inválida'
        return date.toLocaleDateString('pt-BR')
        } catch (error) {
          return 'Data inválida'
        }
      },

      formatarEdital(produto) {
        // Primeiro verificar se há edital vinculado pelo Catálogo de Marcas
        if (produto.edital_prequalificacao) {
          // Extrair apenas o número do edital (ex: "nº 001/2025")
          const match = produto.edital_prequalificacao.match(/nº\s*(\d{3}\/\d{4})/i)
          return match ? `nº ${match[1]}` : produto.edital_prequalificacao
        }
        
        // Senão, verificar os campos do sistema de editais antigo
        if (produto.numero_edital && produto.ano_edital) {
          return `nº ${produto.numero_edital}`
        }
        
        return 'Sem edital vinculado'
      },

      // ===========================
      // MÉTODOS DCB
      // ===========================
      async carregarDadosDCB() {
        try {
          if (!this.currentTenantId) return

          console.log('Carregando dados DCB para tenant:', this.currentTenantId)

          // 1. Buscar produtos aprovados sem DCB
          const { data: produtosAprovados, error: errorProdutos } = await supabase
            .from('produtos')
            .select(`
              *,
              categorias(nome)
            `)
            .eq('tenant_id', this.currentTenantId)
            .eq('status', 'aprovado')
            .is('numero_dcb', null)
            .order('data_aprovacao', { ascending: false })

          if (errorProdutos) throw errorProdutos

          this.produtosProntosDCB = produtosAprovados || []
          this.produtosProntosDCBFiltrados = [...this.produtosProntosDCB]

          // 2. Buscar DCBs emitidos
          const { data: dcbsData, error: errorDCBs } = await supabase
            .from('dcb_certificados')
            .select(`
              *,
              produtos(nome, marca, modelo, fabricante)
            `)
            .eq('tenant_id', this.currentTenantId)
            .order('data_emissao', { ascending: false })

          if (errorDCBs) throw errorDCBs

          const dcbs = dcbsData || []
          
          // Processar DCBs para facilitar exibição
          this.dcbsEmitidos = dcbs.map(dcb => ({
            ...dcb,
            produto_nome: dcb.produtos?.nome || 'N/A',
            produto_marca: dcb.produtos?.marca || 'N/A',
            produto_modelo: dcb.produtos?.modelo || 'N/A',
            produto_fabricante: dcb.produtos?.fabricante || 'N/A'
          }))

          this.dcbsHistoricoFiltrados = [...this.dcbsEmitidos]

          // 3. Calcular DCBs vencendo e vencidos
          this.calcularVencimentos()

          console.log(`DCB dados carregados: ${this.produtosProntosDCB.length} prontos, ${this.dcbsEmitidos.length} emitidos`)

        } catch (error) {
          console.error('Erro ao carregar dados DCB:', error)
          this.$swal.fire('Erro', 'Erro ao carregar dados DCB', 'error')
        }
      },

      calcularVencimentos() {
        const hoje = new Date()
        const em30Dias = new Date()
        em30Dias.setDate(hoje.getDate() + 30)

        this.dcbsVencendo = this.dcbsEmitidos.filter(dcb => {
          if (dcb.status !== 'ativo') return false
          const dataValidade = new Date(dcb.data_validade)
          return dataValidade > hoje && dataValidade <= em30Dias
        })

        this.dcbsVencidos = this.dcbsEmitidos.filter(dcb => {
          if (dcb.status !== 'ativo') return false
          const dataValidade = new Date(dcb.data_validade)
          return dataValidade <= hoje
        })
      },

      // Filtros DCB
      aplicarFiltrosDCB() {
        let produtosFiltrados = [...this.produtosProntosDCB]

        if (this.filtrosDCB.busca) {
          const busca = this.filtrosDCB.busca.toLowerCase()
          produtosFiltrados = produtosFiltrados.filter(produto =>
            produto.nome.toLowerCase().includes(busca) ||
            produto.marca.toLowerCase().includes(busca) ||
            produto.fabricante.toLowerCase().includes(busca)
          )
        }

        if (this.filtrosDCB.categoria) {
          produtosFiltrados = produtosFiltrados.filter(produto =>
            produto.categorias?.nome?.toLowerCase() === this.filtrosDCB.categoria
          )
        }

        if (this.filtrosDCB.dataAprovacao) {
          const dataFiltro = new Date(this.filtrosDCB.dataAprovacao)
          produtosFiltrados = produtosFiltrados.filter(produto => {
            if (!produto.data_aprovacao) return false
            const dataAprovacao = new Date(produto.data_aprovacao)
            return dataAprovacao.toDateString() === dataFiltro.toDateString()
          })
        }

        this.produtosProntosDCBFiltrados = produtosFiltrados
      },

      limparFiltrosDCB() {
        this.filtrosDCB = {
          busca: '',
          categoria: '',
          dataAprovacao: ''
        }
        this.aplicarFiltrosDCB()
      },

      aplicarFiltrosHistorico() {
        let dcbsFiltrados = [...this.dcbsEmitidos]

        if (this.filtrosHistorico.numeroDCB) {
          const numero = this.filtrosHistorico.numeroDCB.toLowerCase()
          dcbsFiltrados = dcbsFiltrados.filter(dcb =>
            dcb.numero_dcb.toLowerCase().includes(numero)
          )
        }

        if (this.filtrosHistorico.status) {
          dcbsFiltrados = dcbsFiltrados.filter(dcb =>
            dcb.status === this.filtrosHistorico.status
          )
        }

        if (this.filtrosHistorico.dataInicio) {
          const dataInicio = new Date(this.filtrosHistorico.dataInicio)
          dcbsFiltrados = dcbsFiltrados.filter(dcb => {
            const dataEmissao = new Date(dcb.data_emissao)
            return dataEmissao >= dataInicio
          })
        }

        if (this.filtrosHistorico.dataFim) {
          const dataFim = new Date(this.filtrosHistorico.dataFim)
          dcbsFiltrados = dcbsFiltrados.filter(dcb => {
            const dataEmissao = new Date(dcb.data_emissao)
            return dataEmissao <= dataFim
          })
        }

        this.dcbsHistoricoFiltrados = dcbsFiltrados
      },

      // Ações DCB
      async emitirDCB(produto) {
        try {
          this.emitindoDCB = produto.id

          console.log('Emitindo DCB para produto:', produto.nome)

          // 1. Gerar número DCB sequencial
          const numeroDCB = await this.gerarNumeroDCB()

          // 2. Calcular data de validade (1 ano)
          const dataEmissao = new Date()
          const dataValidade = new Date()
          dataValidade.setFullYear(dataValidade.getFullYear() + 1)
          
          // Converter para formato de data (YYYY-MM-DD) para compatibilidade com campo date
          const dataValidadeFormatada = dataValidade.toISOString().split('T')[0]

          // 3. Criar DCB no banco
          const { data: dcbData, error: dcbError } = await supabase
            .from('dcb_certificados')
            .insert({
              tenant_id: this.currentTenantId,
              produto_id: produto.id,
              numero_dcb: numeroDCB,
              data_emissao: dataEmissao.toISOString(),
              data_validade: dataValidadeFormatada,
              status: 'ativo'
            })
            .select()
            .single()

          if (dcbError) throw dcbError

          // 4. Atualizar produto com número DCB
          const { error: produtoError } = await supabase
            .from('produtos')
            .update({
              numero_dcb: numeroDCB,
              validade_dcb: dataValidadeFormatada
            })
            .eq('id', produto.id)

          if (produtoError) throw produtoError

          // 5. Registrar no histórico
          await this.registrarHistoricoDCB(produto.id, 'dcb_emitido', `DCB ${numeroDCB} emitido`)

          // 6. Recarregar dados
          await this.carregarDadosDCB()

          // 7. Gerar PDF automaticamente
          await this.gerarPDFDCBAutomatico(dcbData, produto)

          this.$swal.fire({
            icon: 'success',
            title: '🎉 DCB Emitido com Sucesso!',
            html: `
              <div style="text-align: left; padding: 10px;">
                <p><strong>📜 DCB:</strong> ${numeroDCB}</p>
                <p><strong>📦 Produto:</strong> ${produto.nome}</p>
                <p><strong>🏭 Marca:</strong> ${produto.marca}</p>
                <p><strong>📅 Validade:</strong> ${this.formatDate(dataValidadeFormatada)}</p>
                <hr style="margin: 15px 0;">
                <p style="color: #28a745; font-weight: bold;">
                  ✅ PDF oficial gerado automaticamente<br>
                  📥 Use o botão "PDF" para baixar
                </p>
              </div>
            `,
            showConfirmButton: true,
            confirmButtonText: '📥 Baixar PDF Agora',
            showCancelButton: true,
            cancelButtonText: 'Fechar',
            confirmButtonColor: '#dc3545'
          }).then((result) => {
            if (result.isConfirmed) {
              // Baixar PDF imediatamente
              this.downloadDCB(dcbData)
            }
          })

          console.log('DCB emitido com sucesso:', numeroDCB)

        } catch (error) {
          console.error('Erro ao emitir DCB:', error)
          this.$swal.fire('Erro', 'Erro ao emitir DCB: ' + error.message, 'error')
        } finally {
          this.emitindoDCB = null
        }
      },

      async gerarNumeroDCB() {
        try {
          // Buscar o último número DCB do tenant
          const { data, error } = await supabase
            .from('dcb_certificados')
            .select('numero_dcb')
            .eq('tenant_id', this.currentTenantId)
            .order('criado_em', { ascending: false })
            .limit(1)

          if (error) throw error

          const anoAtual = new Date().getFullYear()
          
          if (!data || data.length === 0) {
            return `001/${anoAtual}`
          }

          const ultimoNumero = data[0].numero_dcb
          const [numeroStr, ano] = ultimoNumero.split('/')
          
          if (parseInt(ano) === anoAtual) {
            // Mesmo ano, incrementar número
            const proximoNumero = parseInt(numeroStr) + 1
            return `${proximoNumero.toString().padStart(3, '0')}/${anoAtual}`
          } else {
            // Ano diferente, começar do 001
            return `001/${anoAtual}`
          }

        } catch (error) {
          console.error('Erro ao gerar número DCB:', error)
          throw error
        }
      },

      async registrarHistoricoDCB(produtoId, acao, observacoes) {
        try {
          const { data } = await supabase.auth.getSession()
          const user = data?.session?.user

          await supabase
            .from('workflow_historico')
            .insert({
              tenant_id: this.currentTenantId,
              produto_id: produtoId,
              usuario_id: user?.id,
              acao: acao,
              observacoes: observacoes
            })

        } catch (error) {
          console.error('Erro ao registrar histórico:', error)
        }
      },

      // Modais
      visualizarProdutoDetalhes(produto) {
        this.produtoSelecionado = produto
        this.modalProdutoDetalhes = true
      },

      fecharModalDetalhes() {
        this.modalProdutoDetalhes = false
        this.produtoSelecionado = null
      },

      visualizarDCB(dcb) {
        this.dcbSelecionado = dcb
        this.modalVisualizarDCB = true
      },

      fecharModalDCB() {
        this.modalVisualizarDCB = false
        this.dcbSelecionado = null
      },

      async downloadDCB(dcb) {
        try {
          console.log('Iniciando download DCB:', dcb.numero_dcb)
          
          // Mostrar loading
          this.$swal.fire({
            title: 'Gerando PDF...',
            text: 'Aguarde enquanto geramos seu DCB',
            allowOutsideClick: false,
            didOpen: () => {
              this.$swal.showLoading()
            }
          })

          // Gerar PDF do DCB
          await this.gerarPDFDCB(dcb)
          
          this.$swal.close()
          
        } catch (error) {
          console.error('Erro ao fazer download:', error)
          this.$swal.fire('Erro', 'Erro ao gerar PDF do DCB: ' + error.message, 'error')
        }
      },

      async gerarPDFDCB(dcb) {
        try {
          // Importar dinamicamente as bibliotecas
          const jsPDF = (await import('jspdf')).default
          const QRCode = (await import('qrcode')).default

          // Buscar dados completos do produto
          const { data: produto, error } = await supabase
            .from('produtos')
            .select('*')
            .eq('id', dcb.produto_id)
            .single()

          if (error) throw error

          // Criar novo PDF
          const doc = new jsPDF('portrait', 'mm', 'a4')
          
          // Configurações
          const pageWidth = doc.internal.pageSize.getWidth()
          const pageHeight = doc.internal.pageSize.getHeight()
          const margin = 20
          let currentY = margin

          // ========================================
          // CABEÇALHO OFICIAL
          // ========================================
          
          // Logo/Brasão (simulado com texto)
          doc.setFontSize(16)
          doc.setFont('helvetica', 'bold')
          doc.text('REPÚBLICA FEDERATIVA DO BRASIL', pageWidth/2, currentY, { align: 'center' })
          currentY += 8
          
          doc.setFontSize(14)
          doc.text('MINISTÉRIO DA SAÚDE', pageWidth/2, currentY, { align: 'center' })
          currentY += 6
          
          doc.setFontSize(12)
          doc.setFont('helvetica', 'normal')
          doc.text('Comissão de Padronização de Materiais - CPM', pageWidth/2, currentY, { align: 'center' })
          currentY += 15

          // Linha separadora
          doc.setDrawColor(0, 0, 0)
          doc.setLineWidth(0.5)
          doc.line(margin, currentY, pageWidth - margin, currentY)
          currentY += 15

          // ========================================
          // TÍTULO PRINCIPAL
          // ========================================
          
          doc.setFontSize(18)
          doc.setFont('helvetica', 'bold')
          doc.text('DECLARAÇÃO DE CONFORMIDADE DE BEM', pageWidth/2, currentY, { align: 'center' })
          currentY += 8
          
          doc.setFontSize(16)
          doc.setTextColor(0, 100, 200)
          doc.text(`DCB Nº ${dcb.numero_dcb}`, pageWidth/2, currentY, { align: 'center' })
          doc.setTextColor(0, 0, 0)
          currentY += 20

          // ========================================
          // DADOS DO PRODUTO
          // ========================================
          
          doc.setFontSize(14)
          doc.setFont('helvetica', 'bold')
          doc.text('PRODUTO CERTIFICADO', margin, currentY)
          currentY += 10
          
          doc.setFontSize(11)
          doc.setFont('helvetica', 'normal')
          
          // Box com dados do produto
          const boxHeight = 50
          doc.setDrawColor(200, 200, 200)
          doc.setFillColor(250, 250, 250)
          doc.rect(margin, currentY, pageWidth - 2*margin, boxHeight, 'FD')
          
          currentY += 10
          doc.setFont('helvetica', 'bold')
          doc.text('Nome do Produto:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.text(produto.nome || 'N/A', margin + 45, currentY)
          currentY += 7
          
          doc.setFont('helvetica', 'bold')
          doc.text('Marca:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.text(produto.marca || 'N/A', margin + 20, currentY)
          currentY += 7
          
          doc.setFont('helvetica', 'bold')
          doc.text('Modelo:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.text(produto.modelo || 'N/A', margin + 22, currentY)
          currentY += 7
          
          doc.setFont('helvetica', 'bold')
          doc.text('Fabricante:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.text(produto.fabricante || 'N/A', margin + 30, currentY)
          currentY += 7
          
          doc.setFont('helvetica', 'bold')
          doc.text('CNPJ:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.text(produto.cnpj_fabricante || produto.cnpj || 'N/A', margin + 20, currentY)
          
          currentY += 25

          // ========================================
          // DADOS DO CERTIFICADO
          // ========================================
          
          doc.setFontSize(14)
          doc.setFont('helvetica', 'bold')
          doc.text('DADOS DO CERTIFICADO', margin, currentY)
          currentY += 10
          
          doc.setFontSize(11)
          doc.setFont('helvetica', 'normal')
          
          // Box com dados do certificado
          doc.setDrawColor(200, 200, 200)
          doc.setFillColor(250, 250, 250)
          doc.rect(margin, currentY, pageWidth - 2*margin, 40, 'FD')
          
          currentY += 10
          doc.setFont('helvetica', 'bold')
          doc.text('Data de Emissão:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.text(this.formatDate(dcb.data_emissao), margin + 40, currentY)
          currentY += 8
          
          doc.setFont('helvetica', 'bold')
          doc.text('Data de Validade:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.text(this.formatDate(dcb.data_validade), margin + 40, currentY)
          currentY += 8
          
          doc.setFont('helvetica', 'bold')
          doc.text('Status:', margin + 5, currentY)
          doc.setFont('helvetica', 'normal')
          doc.setTextColor(0, 150, 0)
          doc.text(this.formatStatusDCB(dcb.status), margin + 20, currentY)
          doc.setTextColor(0, 0, 0)
          
          currentY += 25

          // ========================================
          // DECLARAÇÃO LEGAL
          // ========================================
          
          doc.setFontSize(12)
          doc.setFont('helvetica', 'bold')
          doc.text('DECLARAÇÃO', margin, currentY)
          currentY += 10
          
          doc.setFontSize(10)
          doc.setFont('helvetica', 'normal')
          
          const declaracao = `Declaramos que o produto acima identificado foi submetido a análise técnica pela Comissão de Padronização de Materiais (CPM) deste órgão, tendo sido APROVADO para utilização em processos licitatórios, conforme previsto na Lei Federal nº 14.133/2021 (Lei de Licitações e Contratos).

O presente Documento de Comprovação de Bem (DCB) atesta que o produto atende aos requisitos técnicos mínimos exigidos e está apto para fornecimento no âmbito da Administração Pública.

Esta declaração possui validade até ${this.formatDate(dcb.data_validade)}, podendo ser renovada mediante nova análise técnica.`

          const splitDeclaracao = doc.splitTextToSize(declaracao, pageWidth - 2*margin)
          
          // Verificar se há espaço suficiente para a declaração
          const espacoNecessario = splitDeclaracao.length * 4 + 80 // 80 para QR Code + assinatura
          if (currentY + espacoNecessario > pageHeight - 30) {
            // Adicionar nova página se necessário
            doc.addPage()
            currentY = margin
          }
          
          doc.text(splitDeclaracao, margin, currentY)
          currentY += splitDeclaracao.length * 4 + 25

          // ========================================
          // QR CODE PARA VALIDAÇÃO
          // ========================================
          
          try {
            // Criar URL de validação compatível com GitHub Pages
            const baseUrl = window.location.origin
            const isGitHubPages = baseUrl.includes('github.io')
            const urlValidacao = isGitHubPages 
              ? `${baseUrl}/ComprarBem/#/validar-dcb/${dcb.numero_dcb}`
              : `${baseUrl}/validar-dcb/${dcb.numero_dcb}`
            
            // Gerar QR Code
            const qrCodeDataURL = await QRCode.toDataURL(urlValidacao, {
              width: 80,
              margin: 1,
              color: {
                dark: '#000000',
                light: '#FFFFFF'
              }
            })
            
            // Verificar se temos espaço suficiente, senão pular para posição fixa
            const qrPosition = Math.max(currentY, pageHeight - 120)
            
            // Adicionar QR Code ao PDF
            doc.addImage(qrCodeDataURL, 'PNG', pageWidth - margin - 30, qrPosition, 25, 25)
            
            doc.setFontSize(8)
            doc.text('Validar DCB:', pageWidth - margin - 30, qrPosition + 30)
            doc.text(dcb.numero_dcb, pageWidth - margin - 30, qrPosition + 33)
            
          } catch (qrError) {
            console.warn('Erro ao gerar QR Code:', qrError)
          }

          // ========================================
          // ASSINATURA (POSIÇÃO FIXA NO FINAL DA PÁGINA)
          // ========================================
          
          currentY = pageHeight - 90
          
          doc.setFontSize(10)
          doc.setFont('helvetica', 'normal')
          
          // Data e local
          const hoje = new Date()
          doc.text(`Brasília, ${hoje.getDate().toString().padStart(2, '0')} de ${hoje.toLocaleDateString('pt-BR', { month: 'long' })} de ${hoje.getFullYear()}`, margin, currentY)
          currentY += 20
          
          // Garantir espaço mínimo para assinatura
          currentY = Math.max(currentY, pageHeight - 85)
          
          // Linha para assinatura
          doc.setDrawColor(0, 0, 0)
          doc.setLineWidth(0.5)
          doc.line(margin, currentY, pageWidth/2 - 10, currentY)
          currentY += 8
          
          doc.setFontSize(9)
          doc.setTextColor(0, 0, 0)
          doc.text('Presidente da Comissão de Padronização de Materiais', margin, currentY)
          currentY += 4
          doc.text('CPM - Ministério da Saúde', margin, currentY)

          // ========================================
          // RODAPÉ (POSIÇÃO FIXA)
          // ========================================
          
          doc.setFontSize(8)
          doc.setTextColor(100, 100, 100)
          const rodapeTexto = `Este documento foi gerado eletronicamente pelo Sistema ComprarBem em ${hoje.toLocaleString('pt-BR')}`
          doc.text(rodapeTexto, pageWidth/2, pageHeight - 10, { align: 'center' })

          // ========================================
          // SALVAR PDF
          // ========================================
          
          const nomeArquivo = `DCB_${dcb.numero_dcb.replace('/', '_')}_${produto.nome.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`
          doc.save(nomeArquivo)
          
          console.log('PDF gerado com sucesso:', nomeArquivo)
          
          // Opcional: Salvar URL do PDF no banco
          await this.salvarURLPDFNoBanco(dcb.id, nomeArquivo)
          
        } catch (error) {
          console.error('Erro ao gerar PDF:', error)
          throw error
        }
      },

      async salvarURLPDFNoBanco(dcbId, nomeArquivo) {
        try {
          // Atualizar registro com nome do arquivo (opcional)
          const { error } = await supabase
            .from('dcb_certificados')
            .update({
              arquivo_pdf_url: nomeArquivo
            })
            .eq('id', dcbId)

          if (error) {
            console.warn('Erro ao salvar URL do PDF:', error)
          }
        } catch (error) {
          console.warn('Erro ao atualizar banco com PDF:', error)
        }
      },

      async gerarPDFDCBAutomatico(dcbData, produto) {
        try {
          console.log('Gerando PDF automaticamente para DCB:', dcbData.numero_dcb)
          
          // Criar objeto DCB completo para a função de PDF
          const dcbCompleto = {
            ...dcbData,
            produto_id: produto.id
          }
          
          await this.gerarPDFDCB(dcbCompleto)
          
        } catch (error) {
          console.warn('Erro ao gerar PDF automaticamente:', error)
          // Não bloquear o fluxo principal se o PDF falhar
        }
      },

      async revogarDCB(dcb) {
        try {
          const result = await this.$swal.fire({
            title: 'Revogar DCB?',
            text: `Tem certeza que deseja revogar o DCB ${dcb.numero_dcb}?`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sim, revogar',
            cancelButtonText: 'Cancelar',
            input: 'textarea',
            inputPlaceholder: 'Digite o motivo da revogação...',
            inputValidator: (value) => {
              if (!value) {
                return 'Você precisa inserir um motivo!'
              }
            }
          })

          if (result.isConfirmed) {
            const motivo = result.value

            const { error } = await supabase
              .from('dcb_certificados')
              .update({
                status: 'revogado',
                revogado_em: new Date().toISOString(),
                motivo_revogacao: motivo
              })
              .eq('id', dcb.id)

            if (error) throw error

            await this.carregarDadosDCB()

            this.$swal.fire('Sucesso!', 'DCB revogado com sucesso.', 'success')
          }

        } catch (error) {
          console.error('Erro ao revogar DCB:', error)
          this.$swal.fire('Erro', 'Erro ao revogar DCB', 'error')
        }
      },

      // Renovações
      async iniciarRenovacao(dcb) {
        this.$swal.fire({
          icon: 'info',
          title: 'Renovação de DCB',
          text: `Processo de renovação do DCB ${dcb.numero_dcb} será implementado em breve.`,
          timer: 2000
        })
      },

      async renovarDCBVencido(dcb) {
        this.$swal.fire({
          icon: 'info',
          title: 'Renovação Urgente',
          text: `Renovação urgente do DCB ${dcb.numero_dcb} será implementada em breve.`,
          timer: 2000
        })
      },

      // Utilitários DCB
      getStatusDCBClass(status) {
        switch (status) {
          case 'ativo': return 'status-ativo'
          case 'vencido': return 'status-vencido'
          case 'revogado': return 'status-revogado'
          default: return 'status-indefinido'
        }
      },

      formatStatusDCB(status) {
        switch (status) {
          case 'ativo': return 'Ativo'
          case 'vencido': return 'Vencido'
          case 'revogado': return 'Revogado'
          default: return status
        }
      },

      calcularDiasRestantes(dataValidade) {
        const hoje = new Date()
        const validade = new Date(dataValidade)
        const diffTime = validade - hoje
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
        return Math.max(0, diffDays)
      },

      calcularDiasVencidos(dataValidade) {
        const hoje = new Date()
        const validade = new Date(dataValidade)
        const diffTime = hoje - validade
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
        return Math.max(0, diffDays)
      },

      formatarEspecificacoes(especificacoes) {
        if (typeof especificacoes === 'string') {
          return especificacoes
        }
        if (typeof especificacoes === 'object') {
          return JSON.stringify(especificacoes, null, 2)
        }
        return 'N/A'
      },

      // ==========================================
      // MÉTODOS DOS EDITAIS DE PRÉ-QUALIFICAÇÃO
      // ==========================================

      async carregarEditais() {
        try {
          this.loadingEditais = true
          
          if (!this.currentTenantId) {
            console.error('Tenant ID não disponível para carregar editais')
            return
          }

          const { data, error } = await supabase
            .from('editais')
            .select(`
              *,
              participantes_count:participantes_editais(count)
            `)
            .eq('tenant_id', this.currentTenantId)
            .order('criado_em', { ascending: false })

          if (error) throw error

          // Processar dados dos editais com contagem de participantes
          this.editais = (data || []).map(edital => ({
            ...edital,
            participantes_count: edital.participantes_count?.[0]?.count || 0
          }))
          
          this.aplicarFiltrosEditais()
          
          console.log(`${this.editais.length} editais carregados`)
          console.log('Editais com participantes:', this.editais.map(e => ({
            numero: e.numero,
            participantes: e.participantes_count
          })))

        } catch (error) {
          console.error('Erro ao carregar editais:', error)
          this.$swal.fire('Erro', 'Erro ao carregar editais', 'error')
        } finally {
          this.loadingEditais = false
        }
      },

      aplicarFiltrosEditais() {
        try {
          let editaisFiltrados = [...this.editais]

          // Aplicar filtro de busca
          if (this.filtroEditais.busca && this.filtroEditais.busca.trim()) {
            const busca = this.filtroEditais.busca.toLowerCase().trim()
            editaisFiltrados = editaisFiltrados.filter(edital => {
              try {
                // Verificar se as propriedades existem e não são null/undefined
                const numero = edital.numero ? edital.numero.toString().toLowerCase() : ''
                const descricao = edital.descricao ? edital.descricao.toString().toLowerCase() : ''
                
                // Buscar em número e descrição
                return numero.includes(busca) || descricao.includes(busca)
              } catch (error) {
                console.warn('Erro ao filtrar edital:', edital, error)
                return false
              }
            })
          }

          // Aplicar filtro de status
          if (this.filtroEditais.status && this.filtroEditais.status.trim()) {
            editaisFiltrados = editaisFiltrados.filter(edital =>
              edital.status === this.filtroEditais.status
            )
          }

          this.editaisFiltrados = editaisFiltrados
          
        } catch (error) {
          console.error('Erro ao aplicar filtros aos editais:', error)
          // Em caso de erro, mostrar todos os editais sem filtro
          this.editaisFiltrados = [...this.editais]
          
          // Exibir mensagem de erro amigável ao usuário
          this.$swal.fire({
            icon: 'warning',
            title: 'Aviso',
            text: 'Houve um problema ao aplicar os filtros. Mostrando todos os editais.',
            timer: 3000,
            showConfirmButton: false
          })
        }
      },

      // Método com debounce para melhorar performance da busca
      debouncedFiltrarEditais() {
        // Limpar timeout anterior se existir
        if (this.debounceTimer) {
          clearTimeout(this.debounceTimer)
        }
        
        // Configurar novo timeout de 300ms
        this.debounceTimer = setTimeout(() => {
          this.aplicarFiltrosEditais()
        }, 300)
      },

      // Método para limpar todos os filtros
      limparFiltrosEditais() {
        this.filtroEditais.busca = ''
        this.filtroEditais.status = ''
        this.aplicarFiltrosEditais()
      },

      async abrirModalNovoEdital() {
        // Carregar minutas disponíveis
        await this.carregarMinutasDisponiveis()
        
        // Resetar seleção
        this.minutaSelecionada = null
        this.modalNovoEdital = true
      },

      fecharModalNovoEdital() {
        this.modalNovoEdital = false
        this.minutaSelecionada = null
      },

      // Método para limpar estado sem fechar o modal
      limparEstadoModal() {
        this.minutaSelecionada = null
        this.criandoEdital = false
      },

      // Métodos para Sistema de Minutas Padrão
      async processarCriacaoEdital() {
        // CORREÇÃO: Armazenar temporariamente para uso após fechar o modal
        // Isso evita problema de z-index entre modal e SweetAlert
        const minutaTemp = this.minutaSelecionada
        
        if (!minutaTemp) {
          this.$swal.fire('Atenção', 'Selecione uma minuta padrão para continuar', 'warning')
          return
        }

        // Chamar método principal com a minuta armazenada
        await this.criarEditalComMinuta(minutaTemp)
      },

      async carregarMinutasDisponiveis() {
        try {
          // Verificar e configurar minuta padrão do sistema
          await this.verificarMinutaPadraoSistema()

          const { data, error } = await supabase
            .from('minutas_padrao')
            .select('*')
            .eq('ativa', true)
            .order('eh_padrao_sistema', { ascending: false })
            .order('nome', { ascending: true })

          if (error) throw error

          this.minutasDisponiveis = data || []
        } catch (error) {
          console.error('Erro ao carregar minutas:', error)
          this.$swal.fire('Erro', 'Erro ao carregar minutas padrão: ' + error.message, 'error')
        }
      },

      async verificarMinutaPadraoSistema() {
        try {
          // Verificar se já existe minuta padrão do sistema
          const { data: minutaExistente } = await supabase
            .from('minutas_padrao')
            .select('id, arquivo_url')
            .eq('eh_padrao_sistema', true)
            .single()

          if (minutaExistente) {
            // Verificar se o arquivo existe no storage
            const { data: storageData } = await supabase.storage
              .from('minutas-padrao')
              .list('sistema/')

            const arquivoExiste = storageData?.some(file => 
              file.name === 'MINUTA_PADRAO.docx'
            )

            if (!arquivoExiste) {
              // Arquivo não existe, tentar fazer upload
              await this.criarMinutaPadraoSistema()
            }
          } else {
            // Minuta padrão não existe, criar
            await this.criarMinutaPadraoSistema()
          }
        } catch (error) {
          console.warn('Aviso: Não foi possível verificar minuta padrão do sistema:', error)
        }
      },

      async criarMinutaPadraoSistema() {
        try {
          // Verificar se existe o arquivo MINUTA PADRAO.docx no projeto
          const response = await fetch('/MINUTA_PADRAO.docx')
          
          if (!response.ok) {
            console.warn('Arquivo MINUTA_PADRAO.docx não encontrado localmente')
            return
          }

          const blob = await response.blob()
          const fileName = 'MINUTA_PADRAO.docx'
          const filePath = `sistema/${fileName}`

          // Fazer upload para o storage
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('minutas-padrao')
            .upload(filePath, blob, {
              cacheControl: '3600',
              upsert: true
            })

          if (uploadError) throw uploadError

          // Obter URL pública
          const { data: publicData } = supabase.storage
            .from('minutas-padrao')
            .getPublicUrl(filePath)

          // Inserir ou atualizar no banco
          const { error: upsertError } = await supabase
            .from('minutas_padrao')
            .upsert({
              nome: 'Minuta-Padrão do Sistema',
              descricao: 'Minuta-padrão oficial instituída com o auxílio dos órgãos de assessoramento jurídico e de controle interno',
              arquivo_nome: fileName,
              arquivo_url: publicData.publicUrl,
              categoria: 'SISTEMA',
              eh_padrao_sistema: true,
              ativa: true,
              criado_em: new Date().toISOString(),
              atualizado_em: new Date().toISOString()
            })

          if (upsertError) throw upsertError

          console.log('Minuta padrão do sistema configurada com sucesso')
        } catch (error) {
          console.error('Erro ao criar minuta padrão do sistema:', error)
        }
      },

      selecionarMinuta(minuta) {
        this.minutaSelecionada = minuta.id
      },

      async criarEditalComMinuta(minutaId = null) {
        try {
          this.criandoEdital = true

          const minutaParaUsar = minutaId || this.minutaSelecionada
          
          if (!minutaParaUsar) {
            this.$swal.fire('Atenção', 'Selecione uma minuta padrão para continuar', 'warning')
            return
          }

          if (!this.currentTenantId) {
            throw new Error('Tenant ID não disponível')
          }

          // CORREÇÃO: Fechar o modal de seleção de minuta antes de abrir o SweetAlert
          // Isso evita problema de sobreposição de z-index
          this.fecharModalNovoEdital()

          // Aguardar um pouco para que o modal seja fechado completamente
          await new Promise(resolve => setTimeout(resolve, 100))

          // Solicitar número do edital
          const { value: numeroEdital } = await this.$swal.fire({
            title: 'Número do Edital',
            html: `
              <label for="numero-edital"><strong>Número do Edital:</strong></label>
              <input 
                id="numero-edital" 
                class="swal2-input" 
                placeholder="Ex: 001/2024"
                value="${await this.gerarProximoNumeroEdital()}"
              >
              <small style="color: #666; font-size: 12px;">
                Formato sugerido: 001/2024, 002/2024...
              </small>
            `,
            focusConfirm: false,
            showCancelButton: true,
            confirmButtonText: 'Criar Edital',
            cancelButtonText: 'Cancelar',
            customClass: {
              popup: 'swal2-popup-edital'
            },
            preConfirm: () => {
              const numero = document.getElementById('numero-edital').value
              if (!numero || numero.trim() === '') {
                this.$swal.showValidationMessage('Número do edital é obrigatório')
                return false
              }
              return numero.trim()
            }
          })

          if (!numeroEdital) {
            // Se cancelou, reabrir o modal de seleção de minuta
            this.modalNovoEdital = true
            return
          }

          // Verificar se o número já existe
          const { data: editalExistente } = await supabase
            .from('editais')
            .select('id')
            .eq('tenant_id', this.currentTenantId)
            .eq('numero', numeroEdital)
            .single()

          if (editalExistente) {
            this.$swal.fire('Erro', `Já existe um edital com o número "${numeroEdital}". Por favor, escolha outro número.`, 'error')
            // Reabrir o modal de seleção de minuta
            this.modalNovoEdital = true
            return
          }

          // Criar edital com status RASCUNHO
          const editalData = {
            tenant_id: this.currentTenantId,
            numero: numeroEdital,
            descricao: 'Edital em elaboração',
            status: 'RASCUNHO',
            minuta_usada_id: minutaParaUsar,
            criado_em: new Date().toISOString()
          }

          const { data, error } = await supabase
            .from('editais')
            .insert(editalData)
            .select()
            .single()

          if (error) throw error

          // Registrar uso da minuta
          await supabase
            .from('minuta_uso_historico')
            .insert({
              minuta_id: minutaParaUsar,
              edital_id: data.id,
              usuario_id: this.currentTenantId,
              observacoes: 'Edital criado com minuta padrão'
            })

          await this.carregarEditais()

          this.$swal.fire({
            icon: 'success',
            title: 'Edital Criado!',
            text: `Edital ${numeroEdital} criado com sucesso em elaboração.`,
            timer: 2000
          })

        } catch (error) {
          console.error('Erro ao criar edital:', error)
          this.$swal.fire('Erro', 'Erro ao criar edital: ' + error.message, 'error')
        } finally {
          this.criandoEdital = false
        }
      },

      async gerarProximoNumeroEdital() {
        try {
          const anoAtual = new Date().getFullYear()
          
          // Buscar último número do ano atual
          const { data, error } = await supabase
            .from('editais')
            .select('numero')
            .eq('tenant_id', this.currentTenantId)
            .like('numero', `%/${anoAtual}`)
            .order('numero', { ascending: false })
            .limit(1)

          if (error) throw error

          let proximoNumero = 1
          if (data && data.length > 0) {
            const ultimoNumero = data[0].numero
            const numero = parseInt(ultimoNumero.split('/')[0])
            proximoNumero = numero + 1
          }

          return String(proximoNumero).padStart(3, '0') + '/' + anoAtual
        } catch (error) {
          console.error('Erro ao gerar número:', error)
          return '001/' + new Date().getFullYear()
        }
      },

      // Modal para adicionar nova minuta
      abrirModalAddMinuta() {
        this.novaMinuta = {
          nome: '',
          categoria: 'geral',
          descricao: '',
          arquivo: null
        }
        this.modalAddMinuta = true
      },

      fecharModalAddMinuta() {
        this.modalAddMinuta = false
        this.novaMinuta = {
          nome: '',
          categoria: 'geral',
          descricao: '',
          arquivo: null
        }
      },

      handleMinutaUpload(event) {
        const file = event.target.files[0]
        if (file) {
          // Validar tipo de arquivo
          const allowedTypes = ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
          if (!allowedTypes.includes(file.type)) {
            this.$swal.fire('Erro', 'Por favor, selecione um arquivo Word (.docx ou .doc)', 'error')
            event.target.value = ''
            return
          }

          // Validar tamanho (10MB)
          if (file.size > 10 * 1024 * 1024) {
            this.$swal.fire('Erro', 'O arquivo deve ter no máximo 10MB', 'error')
            event.target.value = ''
            return
          }

          this.novaMinuta.arquivo = file
        }
      },

      async salvarNovaMinuta() {
        try {
          this.salvandoMinuta = true

          if (!this.novaMinuta.arquivo) {
            this.$swal.fire('Atenção', 'Selecione um arquivo Word para a minuta', 'warning')
            return
          }

          // Upload do arquivo
          const fileName = `minutas/${Date.now()}-${this.novaMinuta.arquivo.name}`
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('documentos')
            .upload(fileName, this.novaMinuta.arquivo)

          if (uploadError) throw uploadError

          // Obter URL pública
          const { data: urlData } = supabase.storage
            .from('documentos')
            .getPublicUrl(fileName)

          // Salvar na base de dados
          const { data, error } = await supabase
            .from('minutas_padrao')
            .insert({
              nome: this.novaMinuta.nome,
              categoria: this.novaMinuta.categoria,
              descricao: this.novaMinuta.descricao,
              arquivo_nome: this.novaMinuta.arquivo.name,
              arquivo_url: urlData.publicUrl,
              tipo_arquivo: this.novaMinuta.arquivo.name.split('.').pop(),
              criado_por: this.currentTenantId,
              eh_padrao_sistema: false
            })

          if (error) throw error

          await this.carregarMinutasDisponiveis()
          this.fecharModalAddMinuta()

          this.$swal.fire({
            icon: 'success',
            title: 'Minuta Adicionada!',
            text: `Minuta "${this.novaMinuta.nome}" adicionada com sucesso.`,
            timer: 2000
          })

        } catch (error) {
          console.error('Erro ao salvar minuta:', error)
          this.$swal.fire('Erro', 'Erro ao salvar minuta: ' + error.message, 'error')
        } finally {
          this.salvandoMinuta = false
        }
      },

      // Métodos para workflow de minutas
      async baixarMinutaPadrao(edital) {
        try {
          // Buscar a minuta padrão usada
          const { data: minuta, error } = await supabase
            .from('minutas_padrao')
            .select('*')
            .eq('id', edital.minuta_usada_id)
            .single()

          if (error) throw error

          if (minuta.arquivo_url) {
            // Baixar arquivo da URL
            const response = await fetch(minuta.arquivo_url)
            const blob = await response.blob()
            
            // Criar link de download
            const url = window.URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = minuta.arquivo_nome || 'minuta_padrao.docx'
            document.body.appendChild(a)
            a.click()
            window.URL.revokeObjectURL(url)
            document.body.removeChild(a)
          } else {
            // Fallback para arquivo local
            const link = document.createElement('a')
            link.href = '/DOCUMENTOS ESCRITOS/MINUTA PADRAO.docx'
            link.download = 'MINUTA PADRAO.docx'
            document.body.appendChild(link)
            link.click()
            document.body.removeChild(link)
          }

        } catch (error) {
          console.error('Erro ao baixar minuta:', error)
          this.$swal.fire('Erro', 'Erro ao baixar minuta padrão', 'error')
        }
      },

      async handleMinutaPreenchidaUpload(event) {
        try {
          const file = event.target.files[0]
          if (!file) return

          // Validar tipo de arquivo
          const allowedTypes = ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
          if (!allowedTypes.includes(file.type)) {
            this.$swal.fire('Erro', 'Por favor, selecione um arquivo Word (.docx ou .doc)', 'error')
            return
          }

          // Validar tamanho (15MB)
          if (file.size > 15 * 1024 * 1024) {
            this.$swal.fire('Erro', 'O arquivo deve ter no máximo 15MB', 'error')
            return
          }

          // Upload do arquivo
          const fileName = `editais/preenchidas/${Date.now()}-${file.name}`
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('documentos')
            .upload(fileName, file)

          if (uploadError) throw uploadError

          // Obter URL pública
          const { data: urlData } = supabase.storage
            .from('documentos')
            .getPublicUrl(fileName)

          // Atualizar edital
          const { error: updateError } = await supabase
            .from('editais')
            .update({
              minuta_preenchida_url: urlData.publicUrl,
              minuta_preenchida_nome: file.name
            })
            .eq('id', this.editalSelecionado.id)

          if (updateError) throw updateError

          // Atualizar dados locais
          this.editalSelecionado.minuta_preenchida_url = urlData.publicUrl
          this.editalSelecionado.minuta_preenchida_nome = file.name

          await this.carregarEditais()

          this.$swal.fire({
            icon: 'success',
            title: 'Minuta Enviada!',
            text: 'Minuta preenchida enviada com sucesso.',
            timer: 2000
          })

        } catch (error) {
          console.error('Erro ao enviar minuta:', error)
          this.$swal.fire('Erro', 'Erro ao enviar minuta preenchida: ' + error.message, 'error')
        }
      },

      visualizarMinutaPreenchida(edital) {
        if (edital.minuta_preenchida_url) {
          window.open(edital.minuta_preenchida_url, '_blank')
        }
      },

      // Método para processar conversão para PDF (evita problema de z-index)
      async processarConversaoPDF(edital) {
        // CORREÇÃO: Armazenar dados do edital para uso após fechar o modal
        // Isso evita problema de z-index entre modal e SweetAlert
        const editalTemp = { ...edital }
        
        // Chamar método principal com dados armazenados
        await this.converterParaPDF(editalTemp)
      },

      // 🆕 NOVA FUNCIONALIDADE: Gerar PDF real do edital (substitui cópia do Word)
      // 
      // FUNÇÃO: Converte edital de Word para PDF oficial usando jsPDF
      // ENTRADA: edital (objeto com dados do edital)
      // SAÍDA: { url, nome, caminho } do PDF gerado
      // 
      // PROCESSO:
      // 1. Busca dados da minuta padrão usada
      // 2. Cria PDF com layout oficial usando jsPDF  
      // 3. Faz upload do PDF para Supabase Storage
      // 4. Retorna URL pública do PDF convertido
      //
      async gerarPDFEdital(edital) {
        try {
          console.log('📄 Gerando PDF do edital:', edital.numero)
          
          // Importar jsPDF dinamicamente
          const jsPDF = (await import('jspdf')).jsPDF || (await import('jspdf')).default
          
          // Buscar dados da minuta padrão usada
          const { data: minuta } = await supabase
            .from('minutas_padrao')
            .select('*')
            .eq('id', edital.minuta_usada_id)
            .single()

          // Criar novo PDF
          const doc = new jsPDF('portrait', 'mm', 'a4')
          
          // Configurações
          const pageWidth = doc.internal.pageSize.getWidth()
          const pageHeight = doc.internal.pageSize.getHeight()
          const margin = 20
          let currentY = margin

          // ========================================
          // CABEÇALHO OFICIAL
          // ========================================
          
          // Logo/Brasão (simulado)
          doc.setFontSize(16)
          doc.setFont('helvetica', 'bold')
          doc.text('REPÚBLICA FEDERATIVA DO BRASIL', pageWidth/2, currentY, { align: 'center' })
          currentY += 8
          
          doc.setFontSize(14)
          doc.text('MINISTÉRIO DA SAÚDE', pageWidth/2, currentY, { align: 'center' })
          currentY += 6
          
          doc.setFontSize(12)
          doc.setFont('helvetica', 'normal')
          doc.text('Comissão de Padronização de Materiais - CPM', pageWidth/2, currentY, { align: 'center' })
          currentY += 15

          // Linha separadora
          doc.setDrawColor(0, 0, 0)
          doc.setLineWidth(0.5)
          doc.line(margin, currentY, pageWidth - margin, currentY)
          currentY += 15

          // ========================================
          // TÍTULO DO EDITAL
          // ========================================
          
          doc.setFontSize(18)
          doc.setFont('helvetica', 'bold')
          const titulo = `EDITAL DE PREGÃO ELETRÔNICO Nº ${edital.numero}`
          doc.text(titulo, pageWidth/2, currentY, { align: 'center' })
          currentY += 15
          
          doc.setFontSize(14)
          doc.setFont('helvetica', 'normal')
          doc.text(edital.descricao || 'Edital de Pré-qualificação de Materiais', pageWidth/2, currentY, { align: 'center' })
          currentY += 25

          // ========================================
          // INFORMAÇÕES DO EDITAL
          // ========================================
          
          doc.setFontSize(12)
          doc.setFont('helvetica', 'bold')
          doc.text('DADOS DO PROCEDIMENTO', margin, currentY)
          currentY += 10
          
          // Box com dados do edital
          doc.setDrawColor(200, 200, 200)
          doc.setFillColor(250, 250, 250)
          doc.rect(margin, currentY, pageWidth - 2*margin, 35, 'FD')
          
          currentY += 10
          doc.setFontSize(11)
          doc.setFont('helvetica', 'normal')
          
          doc.text(`Número do Edital: ${edital.numero}`, margin + 5, currentY)
          currentY += 6
          doc.text(`Status: ${edital.status}`, margin + 5, currentY)
          currentY += 6
          doc.text(`Data de Publicação: ${this.formatDate(edital.data_publicacao || new Date())}`, margin + 5, currentY)
          currentY += 6
          doc.text(`Prazo para Impugnações: ${this.formatDate(edital.data_limite_impugnacao || new Date())}`, margin + 5, currentY)
          
          currentY += 25

          // ========================================
          // OBJETO DO EDITAL
          // ========================================
          
          doc.setFontSize(12)
          doc.setFont('helvetica', 'bold')
          doc.text('OBJETO', margin, currentY)
          currentY += 10
          
          doc.setFontSize(11)
          doc.setFont('helvetica', 'normal')
          const objeto = `Processo de pré-qualificação de materiais para aquisição futura, conforme especificações técnicas definidas pela Comissão de Padronização de Materiais - CPM.`
          const splitObjeto = doc.splitTextToSize(objeto, pageWidth - 2*margin)
          doc.text(splitObjeto, margin, currentY)
          currentY += splitObjeto.length * 6 + 15

          // ========================================
          // MINUTA PADRÃO UTILIZADA
          // ========================================
          
          if (minuta) {
            doc.setFontSize(12)
            doc.setFont('helvetica', 'bold')
            doc.text('MINUTA PADRÃO UTILIZADA', margin, currentY)
            currentY += 10
            
            doc.setFontSize(11)
            doc.setFont('helvetica', 'normal')
            doc.text(`Nome: ${minuta.nome}`, margin, currentY)
            currentY += 6
            doc.text(`Categoria: ${minuta.categoria || 'Geral'}`, margin, currentY)
            currentY += 6
            if (minuta.descricao) {
              const splitDesc = doc.splitTextToSize(`Descrição: ${minuta.descricao}`, pageWidth - 2*margin)
              doc.text(splitDesc, margin, currentY)
              currentY += splitDesc.length * 6
            }
            currentY += 15
          }
          
          // ========================================
          // CONDIÇÕES GERAIS
          // ========================================
          
          doc.setFontSize(12)
          doc.setFont('helvetica', 'bold')
          doc.text('CONDIÇÕES GERAIS', margin, currentY)
          currentY += 10
          
          doc.setFontSize(11)
          doc.setFont('helvetica', 'normal')
          
          const condicoes = [
            '1. Este edital visa a pré-qualificação de materiais conforme normas vigentes.',
            '2. Os fornecedores interessados deverão apresentar documentação completa.',
            '3. A avaliação será realizada pela Comissão de Padronização de Materiais.',
            '4. Os materiais aprovados receberão Declaração de Conformidade de Bem (DCB).',
            '5. O processo poderá ser impugnado no prazo estabelecido.',
            '6. Maiores informações no Sistema ComprarBem.'
          ]
          
          condicoes.forEach(condicao => {
            const splitCondicao = doc.splitTextToSize(condicao, pageWidth - 2*margin - 5)
            doc.text(splitCondicao, margin, currentY)
            currentY += splitCondicao.length * 6 + 3
          })

          // ========================================
          // RODAPÉ E ASSINATURA
          // ========================================
          
          // Garantir espaço para assinatura
          currentY = Math.max(currentY + 30, pageHeight - 120)
          
          // Data e local
          const hoje = new Date()
          doc.text(`Brasília, ${hoje.getDate().toString().padStart(2, '0')} de ${hoje.toLocaleDateString('pt-BR', { month: 'long' })} de ${hoje.getFullYear()}`, margin, currentY)
          currentY += 20
          
          // Linha para assinatura
          doc.setDrawColor(0, 0, 0)
          doc.setLineWidth(0.5)
          doc.line(margin, currentY, pageWidth/2 - 10, currentY)
          currentY += 8
          
          doc.setFontSize(10)
          doc.text('Presidente da Comissão de Padronização de Materiais', margin, currentY)
          currentY += 4
          doc.text('CPM - Ministério da Saúde', margin, currentY)

          // Rodapé
          doc.setFontSize(8)
          doc.setTextColor(100, 100, 100)
          const rodapeTexto = `Este documento foi gerado eletronicamente pelo Sistema ComprarBem em ${hoje.toLocaleString('pt-BR')}`
          doc.text(rodapeTexto, pageWidth/2, pageHeight - 10, { align: 'center' })

          // ========================================
          // SALVAR PDF E FAZER UPLOAD
          // ========================================
          
          const nomeArquivo = `Edital_${edital.numero.replace('/', '_')}_${hoje.getFullYear()}.pdf`
          const pdfBlob = doc.output('blob')
          
          console.log('📤 Fazendo upload do PDF para Supabase...')
          
          // Upload para Supabase Storage
          const caminhoArquivo = `editais-pdf/${this.currentTenantId}/${nomeArquivo}`
          
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('documentos')
            .upload(caminhoArquivo, pdfBlob, {
              cacheControl: '3600',
              upsert: true,
              contentType: 'application/pdf'
            })

          if (uploadError) throw uploadError

          // Obter URL pública
          const { data: urlData } = supabase.storage
            .from('documentos')
            .getPublicUrl(caminhoArquivo)

          console.log('✅ PDF gerado e enviado com sucesso:', urlData.publicUrl)

          return {
            url: urlData.publicUrl,
            nome: nomeArquivo,
            caminho: caminhoArquivo
          }
          
        } catch (error) {
          console.error('❌ Erro ao gerar PDF do edital:', error)
          
          // Fechar loading se estiver aberto
          if (this.$swal && this.$swal.close) {
            this.$swal.close()
          }
          
          // Tratar diferentes tipos de erro
          let mensagemErro = 'Não foi possível gerar o PDF do edital.'
          
          if (error.message.includes('storage')) {
            mensagemErro = 'Erro no armazenamento do arquivo. Verifique as permissões.'
          } else if (error.message.includes('network') || error.message.includes('fetch')) {
            mensagemErro = 'Erro de conexão. Verifique sua internet e tente novamente.'
          } else if (error.message.includes('jsPDF')) {
            mensagemErro = 'Erro na geração do PDF. Tente novamente.'
          }
          
          throw new Error(mensagemErro + ' Detalhes: ' + error.message)
        }
      },

      // 🆕 NOVA FUNCIONALIDADE: Converter arquivo Word da minuta preenchida para PDF
      // 
      // FUNÇÃO: Converte arquivo Word carregado pelo usuário para PDF com formatação preservada
      // ENTRADA: edital (objeto com dados do edital incluindo minuta_preenchida_url)
      // SAÍDA: { url, nome, caminho } do PDF convertido
      // 
      // PROCESSO AVANÇADO:
      // 1. Baixa o arquivo Word do Storage
      // 2. Extrai HTML e texto usando mammoth.js
      // 3. Processa estrutura (títulos, campos, tabelas)
      // 4. Identifica elementos (títulos, formulários, parágrafos)
      // 5. Aplica formatação específica para cada tipo
      // 6. Cria PDF preservando a estrutura original
      // 7. Faz upload do PDF para Supabase Storage
      // 8. Retorna URL pública do PDF convertido
      //





      async converterWordParaPDF(edital) {
        try {
          console.log('📄 Convertendo minuta Word para PDF (MODO VISUAL):', edital.minuta_preenchida_url)
          
          // 🎯 USAR NOVO SERVIÇO DEDICADO DE CONVERSÃO
          const { convertWordToPdf } = await import('@/services/wordToPdfService')
          
          const fileName = edital.minuta_preenchida_nome?.replace(/\.(docx?|doc)$/i, '') || 'Minuta'
          
          console.log('🔄 Iniciando conversão visual...')
          const result = await convertWordToPdf(edital.minuta_preenchida_url, fileName)
          
                    console.log('✅ Conversão concluída:', result.fileName)
          
          // ========================================
          // UPLOAD DO PDF CONVERTIDO PARA SUPABASE
          // ========================================
          
          console.log('📤 Fazendo upload do PDF convertido para Supabase...')
          
          const caminhoArquivo = `editais-pdf/${this.currentTenantId}/${result.fileName}`
          
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('documentos')
            .upload(caminhoArquivo, result.blob, {
              cacheControl: '3600',
              upsert: true,
              contentType: 'application/pdf'
            })

          if (uploadError) throw uploadError

          // Obter URL pública
          const { data: urlData } = supabase.storage
            .from('documentos')
            .getPublicUrl(caminhoArquivo)

          console.log('🎉 PDF CONVERTIDO COM SUCESSO (MODO VISUAL)!')
          console.log('📄 URL:', urlData.publicUrl)

          return {
            url: urlData.publicUrl,
            nome: result.fileName,
            caminho: caminhoArquivo
          }
          
        } catch (error) {
          console.error('❌ Erro ao converter Word para PDF:', error)
          throw error
        }
      },

      async converterParaPDF(edital) {
        try {
          // CORREÇÃO: Fechar modal de visualização antes de abrir SweetAlert
          // Isso evita problema de sobreposição de z-index (mesmo problema que tivemos com seleção de minuta)
          this.fecharModalVisualizarEdital()

          // Aguardar um pouco para que o modal seja fechado completamente
          await new Promise(resolve => setTimeout(resolve, 100))

          // Verificar se existe minuta preenchida para personalizar mensagem
          const temMinutaPreenchida = edital.minuta_preenchida_url && edital.minuta_preenchida_url.trim() !== ''
          
          // Confirmação antes de converter
          const result = await this.$swal.fire({
            title: 'Confirmar Conversão',
            html: `
              <div style="text-align: left;">
                <p><strong>Atenção:</strong> Esta ação irá:</p>
                <ul>
                  ${temMinutaPreenchida 
                    ? `<li>Converter sua minuta Word preenchida para PDF</li>
                       <li>Arquivo: ${edital.minuta_preenchida_nome || 'Minuta preenchida'}</li>`
                    : `<li>Gerar PDF oficial com base nos dados do edital</li>`
                  }
                  <li>Marcar o edital como PUBLICADO</li>
                  <li>Tornar o edital disponível para consulta</li>
                </ul>
                <p><strong>${temMinutaPreenchida 
                  ? 'Tem certeza que a minuta preenchida está pronta para publicação?'
                  : 'Tem certeza que o edital está pronto para publicação?'
                }</strong></p>
              </div>
            `,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sim, Converter e Publicar',
            cancelButtonText: 'Cancelar',
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            customClass: {
              popup: 'swal2-popup-converter-pdf'
            }
          })

          if (!result.isConfirmed) {
            // Se cancelou, reabrir o modal de visualização do edital
            this.modalVisualizarEdital = true
            return
          }

          // CONVERSÃO REAL: Determinar tipo de conversão baseado na minuta
          console.log('🔄 Iniciando conversão real para PDF...')
          
          // Mostrar loading da conversão
          this.$swal.fire({
            title: 'Convertendo para PDF...',
            text: temMinutaPreenchida 
              ? 'Aguarde enquanto convertemos sua minuta Word para PDF'
              : 'Aguarde enquanto geramos o PDF do edital',
            allowOutsideClick: false,
            didOpen: () => {
              this.$swal.showLoading()
            }
          })

          // Escolher método de conversão baseado na existência de minuta preenchida
          let pdfData
          if (temMinutaPreenchida) {
            console.log('📄 Convertendo minuta Word carregada pelo usuário...')
            pdfData = await this.converterWordParaPDF(edital)
          } else {
            console.log('📄 Gerando PDF com dados do edital...')
            pdfData = await this.gerarPDFEdital(edital)
          }
          
          const agora = new Date()
          const dataPublicacao = agora.toISOString()
          const dataLimiteImpugnacao = new Date(agora.getTime() + (30 * 24 * 60 * 60 * 1000)).toISOString() // 30 dias

          // Atualizar edital com URL real do PDF
          const { error } = await supabase
            .from('editais')
            .update({
              status: 'PUBLICADO',
              data_publicacao: dataPublicacao,
              data_limite_impugnacao: dataLimiteImpugnacao,
              pdf_convertido_url: pdfData.url, // URL real do PDF convertido
              pdf_convertido_nome: pdfData.nome // Nome real do PDF
            })
            .eq('id', edital.id)

          if (error) throw error

          this.$swal.close()

          // Atualizar dados locais
          this.editalSelecionado.status = 'PUBLICADO'
          this.editalSelecionado.data_publicacao = dataPublicacao
          this.editalSelecionado.data_limite_impugnacao = dataLimiteImpugnacao
          this.editalSelecionado.pdf_convertido_url = pdfData.url
          this.editalSelecionado.pdf_convertido_nome = pdfData.nome

          await this.carregarEditais()

          this.$swal.fire({
            icon: 'success',
            title: 'Edital Publicado!',
            html: `
              <div style="text-align: left; padding: 10px;">
                <p><strong>📋 Edital:</strong> ${edital.numero}</p>
                <p><strong>📄 PDF:</strong> ${pdfData.nome}</p>
                <p><strong>📅 Publicado em:</strong> ${this.formatDate(dataPublicacao)}</p>
                <hr style="margin: 15px 0;">
                <p style="color: #28a745; font-weight: bold;">
                  ${temMinutaPreenchida 
                    ? '✅ Minuta Word convertida para PDF oficial<br>📝 Conteúdo baseado na minuta preenchida enviada'
                    : '✅ PDF oficial gerado automaticamente<br>📄 Conteúdo baseado nos dados do edital'
                  }<br>
                  📥 Use o botão "Abrir PDF" para visualizar
                </p>
              </div>
            `,
            showConfirmButton: true,
            confirmButtonText: '📥 Abrir PDF Agora',
            showCancelButton: true,
            cancelButtonText: 'Fechar',
            confirmButtonColor: '#28a745'
          }).then((result) => {
            if (result.isConfirmed) {
              // Abrir PDF imediatamente
              window.open(pdfData.url, '_blank')
            }
          })

        } catch (error) {
          console.error('❌ Erro ao converter para PDF:', error)
          
          // Fechar qualquer loading ativo
          if (this.$swal && this.$swal.close) {
            this.$swal.close()
          }
          
          // Mostrar erro específico e informativo
          this.$swal.fire({
            icon: 'error',
            title: 'Erro na Conversão para PDF',
            html: `
              <div style="text-align: left;">
                <p><strong>Não foi possível converter o edital para PDF.</strong></p>
                <p><strong>Erro:</strong> ${error.message}</p>
                <hr>
                <p><strong>O que fazer:</strong></p>
                <ul>
                  <li>Verifique sua conexão com a internet</li>
                  <li>Tente novamente em alguns minutos</li>
                  <li>Se o problema persistir, contate o suporte</li>
                </ul>
                <p style="color: #666; font-size: 12px; margin-top: 15px;">
                  💡 <strong>Dica:</strong> O edital continuará como "RASCUNHO" até a conversão ser bem-sucedida.
                </p>
              </div>
            `,
            confirmButtonText: 'Entendi',
            confirmButtonColor: '#dc3545'
          })
          
          // Reabrir modal de visualização do edital se necessário
          setTimeout(() => {
            this.modalVisualizarEdital = true
          }, 500)
        }
      },

      validarDatas() {
        // Verificar se as datas estão preenchidas
        if (!this.editalAtual.data_publicacao) {
          this.$swal.fire('Erro', 'Data de publicação é obrigatória', 'error')
          return false
        }

        if (!this.editalAtual.data_limite_impugnacao) {
          this.$swal.fire('Erro', 'Prazo para impugnações é obrigatório', 'error')
          return false
        }

        // Converter datas para comparação
        const dataPublicacao = new Date(this.editalAtual.data_publicacao)
        const dataLimiteImpugnacao = new Date(this.editalAtual.data_limite_impugnacao)

        // Verificar se o prazo de impugnação é posterior à data de publicação
        if (dataLimiteImpugnacao <= dataPublicacao) {
          this.$swal.fire({
            icon: 'error',
            title: 'Erro de Data',
            html: `
              <p><strong>O prazo para impugnações deve ser posterior à data de publicação!</strong></p>
              <br>
              <p><strong>Data de Publicação:</strong> ${this.formatDate(dataPublicacao)}</p>
              <p><strong>Prazo para Impugnações:</strong> ${this.formatDate(dataLimiteImpugnacao)}</p>
              <br>
              <p>Por favor, ajuste as datas e tente novamente.</p>
            `,
            confirmButtonText: 'Entendi'
          })
          return false
        }

        // Verificar se o prazo não é muito distante (mais de 1 ano)
        const umAnoDepois = new Date(dataPublicacao)
        umAnoDepois.setFullYear(umAnoDepois.getFullYear() + 1)
        
        if (dataLimiteImpugnacao > umAnoDepois) {
          const result = this.$swal.fire({
            icon: 'warning',
            title: 'Prazo muito distante',
            text: 'O prazo para impugnações está mais de 1 ano após a publicação. Tem certeza?',
            showCancelButton: true,
            confirmButtonText: 'Sim, continuar',
            cancelButtonText: 'Cancelar'
          })
          
          if (!result.isConfirmed) {
            return false
          }
        }

        return true
      },

      validarDataLimite() {
        if (!this.editalAtual.data_publicacao || !this.editalAtual.data_limite_impugnacao) {
          return
        }

        const dataPublicacao = new Date(this.editalAtual.data_publicacao)
        const dataLimiteImpugnacao = new Date(this.editalAtual.data_limite_impugnacao)

        if (dataLimiteImpugnacao <= dataPublicacao) {
          this.$swal.fire({
            icon: 'warning',
            title: 'Atenção!',
            text: 'O prazo para impugnações deve ser posterior à data de publicação.',
            timer: 3000,
            toast: true,
            position: 'top-end',
            showConfirmButton: false
          })
          
          // Limpar o campo
          this.editalAtual.data_limite_impugnacao = ''
        }
      },

      async salvarEdital() {
        try {
          this.salvandoEdital = true

          if (!this.currentTenantId) {
            throw new Error('Tenant ID não disponível')
          }

          // Validar datas
          if (!this.validarDatas()) {
            return
          }

          // Preparar dados do edital
          const editalData = {
            tenant_id: this.currentTenantId,
            numero: this.editalAtual.numero,
            descricao: this.editalAtual.descricao,
            conteudo: this.editalAtual.conteudo,
            status: this.editalAtual.status,
            data_publicacao: this.editalAtual.data_publicacao || new Date().toISOString(),
            data_limite_impugnacao: this.editalAtual.data_limite_impugnacao,
            url_documento: this.editalAtual.url_documento,
            nome_arquivo: this.editalAtual.nome_arquivo
          }

          let result
          if (this.modoEdicaoEdital) {
            // Atualizar edital existente
            const { data, error } = await supabase
              .from('editais')
              .update(editalData)
              .eq('id', this.editalAtual.id)
              .select()
              .single()

            result = { data, error }
          } else {
            // Criar novo edital
            const { data, error } = await supabase
              .from('editais')
              .insert(editalData)
              .select()
              .single()

            result = { data, error }
          }

          if (result.error) throw result.error

          await this.carregarEditais()
          this.fecharModalNovoEdital()

          this.$swal.fire({
            icon: 'success',
            title: this.modoEdicaoEdital ? 'Edital Atualizado!' : 'Edital Criado!',
            text: `Edital ${this.editalAtual.numero} ${this.modoEdicaoEdital ? 'atualizado' : 'criado'} com sucesso.`,
            timer: 2000
          })

        } catch (error) {
          console.error('Erro ao salvar edital:', error)
          this.$swal.fire('Erro', 'Erro ao salvar edital: ' + error.message, 'error')
        } finally {
          this.salvandoEdital = false
        }
      },

      visualizarEdital(edital) {
        this.editalSelecionado = { ...edital }
        this.modalVisualizarEdital = true
      },

      fecharModalVisualizarEdital() {
        this.modalVisualizarEdital = false
        this.editalSelecionado = {}
      },

      editarEdital(edital) {
        this.editalEditando = {
          id: edital.id,
          numero: edital.numero,
          descricao: edital.descricao,
          conteudo: edital.conteudo || '',
          status: edital.status,
          data_publicacao: edital.data_publicacao ? new Date(edital.data_publicacao).toISOString().slice(0, 16) : '',
          data_limite_impugnacao: edital.data_limite_impugnacao ? new Date(edital.data_limite_impugnacao).toISOString().slice(0, 16) : ''
        }
        
        this.modalEditarEdital = true
      },

      editarEditalSelecionado() {
        this.fecharModalVisualizarEdital()
        this.editarEdital(this.editalSelecionado)
      },

      fecharModalEditarEdital() {
        this.modalEditarEdital = false
        this.editalEditando = {
          id: null,
          numero: '',
          descricao: '',
          conteudo: '',
          status: 'RASCUNHO',
          data_publicacao: '',
          data_limite_impugnacao: ''
        }
      },

      async salvarEdicaoEdital() {
        // Validação de campos obrigatórios
        if (!this.editalEditando.numero || !this.editalEditando.numero.trim()) {
          this.$swal.fire('Erro', 'Número do edital é obrigatório', 'error')
          return
        }

        if (!this.editalEditando.descricao || !this.editalEditando.descricao.trim()) {
          this.$swal.fire('Erro', 'Descrição do edital é obrigatória', 'error')
          return
        }

        // Validação de formato do número
        if (this.editalEditando.numero.trim().length < 3) {
          this.$swal.fire('Erro', 'Número do edital deve ter pelo menos 3 caracteres', 'error')
          return
        }

        console.log('🔍 Iniciando edição do edital:', {
          id: this.editalEditando.id,
          numero: this.editalEditando.numero,
          descricao: this.editalEditando.descricao,
          tenant_id: this.currentTenantId
        })

        this.salvandoEdicaoEdital = true

        try {
          // Verificar se o número já existe em outro edital (apenas se mudou o número)
          const { data: editaisExistentes, error: checkError } = await supabase
            .from('editais')
            .select('id')
            .eq('numero', this.editalEditando.numero)
            .eq('tenant_id', this.currentTenantId)
            .neq('id', this.editalEditando.id)

          if (checkError) {
            console.error('Erro ao verificar duplicata:', checkError)
            this.$swal.fire('Erro', 'Erro ao verificar duplicata de edital. Tente novamente.', 'error')
            return
          }

          if (editaisExistentes && editaisExistentes.length > 0) {
            this.$swal.fire('Erro', `Já existe outro edital com o número "${this.editalEditando.numero}". Por favor, escolha outro número.`, 'error')
            return
          }

          // Preparar dados para atualização - limpar campos vazios
          const dadosAtualizacao = {
            numero: this.editalEditando.numero.trim(),
            descricao: this.editalEditando.descricao.trim(),
            atualizado_em: new Date().toISOString()
          }

          // Adicionar campos opcionais apenas se preenchidos
          if (this.editalEditando.conteudo && this.editalEditando.conteudo.trim()) {
            dadosAtualizacao.conteudo = this.editalEditando.conteudo.trim()
          }

          if (this.editalEditando.data_publicacao && this.editalEditando.data_publicacao.trim()) {
            dadosAtualizacao.data_publicacao = this.editalEditando.data_publicacao
          }

          if (this.editalEditando.data_limite_impugnacao && this.editalEditando.data_limite_impugnacao.trim()) {
            dadosAtualizacao.data_limite_impugnacao = this.editalEditando.data_limite_impugnacao
          }

          console.log('🔄 Atualizando edital:', {
            id: this.editalEditando.id,
            tenant_id: this.currentTenantId,
            dados: dadosAtualizacao
          })

          // Atualizar edital
          const { data: editalAtualizado, error } = await supabase
            .from('editais')
            .update(dadosAtualizacao)
            .eq('id', this.editalEditando.id)
            .eq('tenant_id', this.currentTenantId)
            .select()

          if (error) {
            console.error('❌ Erro detalhado na atualização do edital:', error)
            throw error
          }

          console.log('✅ Edital atualizado com sucesso:', editalAtualizado)

          this.$swal.fire({
            icon: 'success',
            title: 'Edital Atualizado!',
            text: `Edital "${this.editalEditando.numero}" atualizado com sucesso.`,
            timer: 2000,
            showConfirmButton: false
          })

          // Recarregar lista de editais
          await this.carregarEditais()
          
          // Fechar modal
          this.fecharModalEditarEdital()

        } catch (error) {
          console.error('❌ Erro ao salvar edital:', error)
          
          // Tratamento específico para diferentes tipos de erro
          let mensagemErro = 'Não foi possível salvar as alterações. Tente novamente.'
          
          if (error.code === '23505') {
            mensagemErro = 'Já existe um edital com este número. Por favor, escolha outro número.'
          } else if (error.code === '23514') {
            mensagemErro = 'Dados inválidos fornecidos. Verifique se todos os campos estão corretos.'
          } else if (error.code === 'PGRST116') {
            mensagemErro = 'Nenhum edital foi encontrado para atualizar. O edital pode ter sido removido.'
          } else if (error.code === 'PGRST204') {
            mensagemErro = 'Erro no esquema do banco de dados. Contacte o administrador do sistema.'
            console.error('❌ Erro PGRST204 - Coluna não encontrada:', error)
          } else if (error.message) {
            if (error.message.includes('duplicate key')) {
              mensagemErro = 'Já existe um edital com este número.'
            } else if (error.message.includes('violates check constraint')) {
              mensagemErro = 'Os dados fornecidos não atendem aos requisitos do sistema.'
            } else if (error.message.includes('permission denied')) {
              mensagemErro = 'Você não tem permissão para editar este edital.'
            }
          }
          
          this.$swal.fire('Erro', mensagemErro, 'error')
        } finally {
          this.salvandoEdicaoEdital = false
        }
      },

      getStatusText(status) {
        const statusTexts = {
          'RASCUNHO': 'Em Elaboração',
          'PUBLICADO': 'Publicado',
          'CANCELADO': 'Cancelado',
          'INTERESSADO': 'Interessado',
          'DOCUMENTACAO_ENVIADA': 'Documentação Enviada',
          'EM_AVALIACAO': 'Em Avaliação',
          'APROVADO': 'Aprovado',
          'REPROVADO': 'Reprovado',
          'DESISTENTE': 'Desistente'
        }
        return statusTexts[status] || status
      },

      async duplicarEdital(edital) {
        try {
          const result = await this.$swal.fire({
            title: 'Duplicar Edital',
            text: 'Digite o número do novo edital:',
            input: 'text',
            inputValue: '',
            inputPlaceholder: 'Ex: 002/2024',
            showCancelButton: true,
            confirmButtonText: 'Duplicar',
            cancelButtonText: 'Cancelar',
            inputValidator: (value) => {
              if (!value) {
                return 'Você precisa inserir um número!'
              }
            }
          })

          if (result.isConfirmed) {
            const novoNumero = result.value

            const novoEdital = {
              tenant_id: this.currentTenantId,
              numero: novoNumero,
              descricao: edital.descricao + ' (Cópia)',
              conteudo: edital.conteudo,
              status: 'RASCUNHO',
              data_publicacao: new Date().toISOString(),
              data_limite_impugnacao: edital.data_limite_impugnacao
            }

            const { error } = await supabase
              .from('editais')
              .insert(novoEdital)

            if (error) throw error

            await this.carregarEditais()

            this.$swal.fire('Sucesso!', `Edital ${novoNumero} criado com sucesso.`, 'success')
          }

        } catch (error) {
          console.error('Erro ao duplicar edital:', error)
          this.$swal.fire('Erro', 'Erro ao duplicar edital', 'error')
        }
      },

      async cancelarEdital(edital) {
        try {
          const result = await this.$swal.fire({
            title: 'Cancelar Edital',
            text: `Tem certeza que deseja cancelar o edital ${edital.numero}?`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sim, cancelar',
            cancelButtonText: 'Não',
            confirmButtonColor: '#d33'
          })

          if (result.isConfirmed) {
            const { error } = await supabase
              .from('editais')
              .update({ status: 'CANCELADO' })
              .eq('id', edital.id)

            if (error) throw error

            await this.carregarEditais()

            this.$swal.fire('Cancelado!', `Edital ${edital.numero} foi cancelado.`, 'success')
          }

        } catch (error) {
          console.error('Erro ao cancelar edital:', error)
          this.$swal.fire('Erro', 'Erro ao cancelar edital', 'error')
        }
      },

      gerenciarParticipantes(edital) {
        console.log('Abrindo modal de participantes para:', edital.numero)
        
        // Criar modal diretamente no DOM
        this.criarModalParticipantes(edital)
      },

      async criarModalParticipantes(edital) {
        // Carregar participantes primeiro
        const { data: participantes, error } = await supabase
          .from('participantes_editais')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .eq('edital_id', edital.id)
          .order('data_participacao', { ascending: false })

        if (error) {
          console.error('Erro ao carregar participantes:', error)
          this.$swal.fire('Erro', 'Erro ao carregar participantes', 'error')
          return
        }

        console.log('Participantes carregados:', participantes)

        // Criar HTML do modal
        const modalHTML = `
          <div id="modal-participantes-custom" style="
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(0,0,0,0.8);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 999999;
          ">
            <div style="
              background: white;
              border-radius: 12px;
              width: 90%;
              max-width: 1000px;
              max-height: 80vh;
              overflow-y: auto;
              box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            ">
              <div style="
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 20px 25px;
                border-bottom: 1px solid #eee;
                background: #f8f9fa;
                border-radius: 12px 12px 0 0;
              ">
                <h3 style="margin: 0; color: #2c3e50;">👥 Participantes - ${edital.numero}</h3>
                <button onclick="document.getElementById('modal-participantes-custom').remove()" style="
                  background: none;
                  border: none;
                  font-size: 24px;
                  cursor: pointer;
                  color: #6c757d;
                  width: 30px;
                  height: 30px;
                  border-radius: 50%;
                ">&times;</button>
              </div>
              
              <div style="padding: 25px;">
                <div style="margin-bottom: 20px;">
                  <h4>📊 Total de Participantes: ${participantes.length}</h4>
                </div>
                
                ${participantes.length > 0 ? `
                  <div style="display: grid; gap: 15px;">
                    ${participantes.map(p => `
                      <div style="
                        border: 1px solid #ddd;
                        border-radius: 8px;
                        padding: 20px;
                        background: #f9f9f9;
                      ">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 15px;">
                          <h4 style="margin: 0; color: #2c3e50;">${p.razao_social}</h4>
                          <span style="
                            padding: 4px 12px;
                            border-radius: 20px;
                            font-size: 12px;
                            font-weight: 600;
                            background: ${this.getStatusColor(p.status)};
                            color: white;
                          ">${this.getStatusText(p.status)}</span>
                        </div>
                        
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 10px; margin-bottom: 15px;">
                          <p style="margin: 5px 0;"><strong>CNPJ:</strong> ${this.formatarCNPJSimples(p.cnpj)}</p>
                          <p style="margin: 5px 0;"><strong>Representante:</strong> ${p.representante_legal}</p>
                          <p style="margin: 5px 0;"><strong>Email:</strong> ${p.email}</p>
                          <p style="margin: 5px 0;"><strong>Telefone:</strong> ${p.telefone || 'N/A'}</p>
                          <p style="margin: 5px 0;"><strong>Data Inscrição:</strong> ${this.formatDateSimples(p.data_participacao)}</p>
                          ${p.data_envio_documentacao ? `<p style="margin: 5px 0;"><strong>Data Documentação:</strong> ${this.formatDateSimples(p.data_envio_documentacao)}</p>` : ''}
                        </div>
                        
                        ${p.endereco ? `
                          <div style="margin-bottom: 15px;">
                            <p style="margin: 5px 0;"><strong>📍 Endereço:</strong> ${p.endereco}</p>
                          </div>
                        ` : ''}
                        
                        ${p.observacoes ? `
                          <div style="
                            margin-bottom: 15px;
                            padding: 12px;
                            background: #fff3cd;
                            border: 1px solid #ffeaa7;
                            border-radius: 6px;
                          ">
                            <p style="margin: 0; font-weight: 600; color: #856404;">💬 Observações da Empresa:</p>
                            <p style="margin: 8px 0 0 0; color: #856404;">${p.observacoes}</p>
                          </div>
                        ` : ''}
                        
                        ${p.produtos_submetidos && p.produtos_submetidos.length > 0 ? `
                          <div style="
                            margin-bottom: 15px;
                            padding: 12px;
                            background: #d1ecf1;
                            border: 1px solid #bee5eb;
                            border-radius: 6px;
                          ">
                            <p style="margin: 0; font-weight: 600; color: #0c5460;">📦 Produtos Submetidos:</p>
                            <ul style="margin: 8px 0 0 20px; color: #0c5460;">
                              ${p.produtos_submetidos.map(produto => `<li>${produto.nome || produto}</li>`).join('')}
                            </ul>
                          </div>
                        ` : ''}
                        
                        <div style="margin-top: 15px;">
                          <div style="display: flex; gap: 10px; margin-bottom: 10px;">
                            <button onclick="window.alterarStatusParticipante('${p.id}', 'APROVADO')" style="
                              padding: 8px 16px;
                              background: #28a745;
                              color: white;
                              border: none;
                              border-radius: 6px;
                              cursor: pointer;
                              font-size: 14px;
                            ">✅ Aprovar</button>
                            
                            <button onclick="window.alterarStatusParticipante('${p.id}', 'REPROVADO')" style="
                              padding: 8px 16px;
                              background: #dc3545;
                              color: white;
                              border: none;
                              border-radius: 6px;
                              cursor: pointer;
                              font-size: 14px;
                            ">❌ Reprovar</button>
                            
                            <button onclick="window.alterarStatusParticipante('${p.id}', 'EM_AVALIACAO')" style="
                              padding: 8px 16px;
                              background: #ffc107;
                              color: #212529;
                              border: none;
                              border-radius: 6px;
                              cursor: pointer;
                              font-size: 14px;
                            ">🔄 Em Avaliação</button>
                            
                            <button onclick="window.adicionarObservacaoInterna('${p.id}')" style="
                              padding: 8px 16px;
                              background: #6f42c1;
                              color: white;
                              border: none;
                              border-radius: 6px;
                              cursor: pointer;
                              font-size: 14px;
                            ">📝 Adicionar Observação</button>
                          </div>
                          
                          ${p.observacoes_internas ? `
                            <div style="
                              padding: 12px;
                              background: #e9ecef;
                              border: 1px solid #ced4da;
                              border-radius: 6px;
                              margin-top: 10px;
                            ">
                              <p style="margin: 0; font-weight: 600; color: #495057;">🔒 Observações Internas da CPM:</p>
                              <p style="margin: 8px 0 0 0; color: #495057; font-style: italic;">${p.observacoes_internas}</p>
                            </div>
                          ` : ''}
                        </div>
                      </div>
                    `).join('')}
                  </div>
                ` : `
                  <div style="text-align: center; padding: 40px; color: #6c757d;">
                    <div style="font-size: 48px; margin-bottom: 20px;">👥</div>
                    <h3>Nenhum participante encontrado</h3>
                    <p>Ainda não há empresas inscritas neste edital.</p>
                  </div>
                `}
              </div>
              
              <div style="
                padding: 20px 25px;
                border-top: 1px solid #eee;
                display: flex;
                justify-content: flex-end;
              ">
                <button onclick="document.getElementById('modal-participantes-custom').remove()" style="
                  padding: 10px 20px;
                  background: #6c757d;
                  color: white;
                  border: none;
                  border-radius: 6px;
                  cursor: pointer;
                ">Fechar</button>
              </div>
            </div>
          </div>
        `

        // Adicionar modal ao DOM
        document.body.insertAdjacentHTML('beforeend', modalHTML)

        // Adicionar função global para alterar status
        window.alterarStatusParticipante = async (participanteId, novoStatus) => {
          try {
            // Buscar dados do participante antes da atualização
            const { data: participanteData, error: participanteError } = await supabase
              .from('participantes_editais')
              .select('*')
              .eq('id', participanteId)
              .single()

            if (participanteError) throw participanteError

            // Atualizar status no banco
            const { error } = await supabase
              .from('participantes_editais')
              .update({ status: novoStatus })
              .eq('id', participanteId)

            if (error) throw error

            // Declarar variável para controle de email
            let motivoRejeicao = null

            // 📧 ENVIAR EMAIL PARA APROVAÇÃO OU REPROVAÇÃO
            if (novoStatus === 'APROVADO' || novoStatus === 'REPROVADO') {
              try {
                // Importar função de envio de email
                const { enviarEmailParticipanteStatus } = await import('@/services/emailService')
                
                // Se foi reprovado, FECHAR MODAL primeiro e depois pedir motivo
                if (novoStatus === 'REPROVADO') {
                  // Fechar modal de participantes
                  document.getElementById('modal-participantes-custom').remove()
                  
                  // Aguardar um pouco para garantir que fechou
                  await new Promise(resolve => setTimeout(resolve, 100))
                  
                  const result = await this.$swal.fire({
                    title: '❌ Motivo da Reprovação',
                    text: 'Informe o motivo da reprovação (será enviado por email):',
                    input: 'textarea',
                    inputPlaceholder: 'Ex: Documentação incompleta, dados inconsistentes, etc.',
                    showCancelButton: true,
                    confirmButtonText: 'Enviar Email',
                    cancelButtonText: 'Pular Email',
                    inputValidator: (value) => {
                      if (!value) {
                        return 'Por favor, informe o motivo da reprovação!'
                      }
                    },
                    // Configurações para aparecer na frente
                    heightAuto: false,
                    backdrop: true,
                    allowOutsideClick: false
                  })
                  
                  if (result.isConfirmed) {
                    motivoRejeicao = result.value
                  } else {
                    // Se cancelou, pular envio de email mas continuar o fluxo
                    console.log('📧 Usuário cancelou envio de email de reprovação')
                    motivoRejeicao = null
                  }
                }
                
                // Só enviar email se for aprovação OU se for reprovação com motivo
                if (novoStatus === 'APROVADO' || (novoStatus === 'REPROVADO' && motivoRejeicao)) {
                  const statusEmail = novoStatus === 'APROVADO' ? 'aprovado' : 'rejeitado'
                  console.log(`📧 Enviando email de ${statusEmail} para:`, participanteData.email)
                  
                  // Enviar email
                  await enviarEmailParticipanteStatus(participanteData, edital, statusEmail, motivoRejeicao)
                  
                  console.log(`✅ Email de ${statusEmail} enviado com sucesso!`)
                } else if (novoStatus === 'REPROVADO' && !motivoRejeicao) {
                  console.log('📧 Email de reprovação não enviado (usuário cancelou)')
                }
                
              } catch (emailError) {
                console.warn(`⚠️ Erro ao enviar email de ${novoStatus.toLowerCase()}:`, emailError)
                // Não bloquear o fluxo principal se o email falhar
              }
            }

            // Fechar modal se ainda não foi fechado (só para aprovação)
            const modalExistente = document.getElementById('modal-participantes-custom')
            if (modalExistente) {
              modalExistente.remove()
            }
            
            // Mostrar mensagem de sucesso personalizada
            let mensagemSucesso = `Status alterado para ${this.getStatusText(novoStatus)}`
            if (novoStatus === 'APROVADO') {
              mensagemSucesso += '\n📧 Email de aprovação enviado automaticamente!'
            } else if (novoStatus === 'REPROVADO') {
              // Verificar se foi enviado email (só se tiver motivo)
              const emailEnviado = motivoRejeicao !== null
              if (emailEnviado) {
                mensagemSucesso += '\n📧 Email de reprovação enviado automaticamente!'
              } else {
                mensagemSucesso += '\n📧 Email de reprovação não foi enviado'
              }
            }
            
            this.$swal.fire({
              icon: 'success',
              title: 'Sucesso!',
              text: mensagemSucesso,
              timer: (novoStatus === 'APROVADO' || novoStatus === 'REPROVADO') ? 4000 : 2000
            })
            
            // Recarregar editais para atualizar contadores
            await this.carregarEditais()
            
            // Reabrir modal atualizado
            setTimeout(() => {
              this.criarModalParticipantes(edital)
            }, 500)

          } catch (error) {
            console.error('Erro ao alterar status:', error)
            // Fechar modal se existir
            const modalExistente = document.getElementById('modal-participantes-custom')
            if (modalExistente) {
              modalExistente.remove()
            }
            
            this.$swal.fire({
              icon: 'error',
              title: 'Erro',
              text: 'Erro ao alterar status do participante'
            })
            
            // Reabrir modal após erro
            setTimeout(() => {
              this.criarModalParticipantes(edital)
            }, 2000)
          }
        }

        // Adicionar função global para observações internas
        window.adicionarObservacaoInterna = async (participanteId) => {
          try {
            // Fechar modal de participantes primeiro
            document.getElementById('modal-participantes-custom').remove()
            
            // Aguardar um pouco
            await new Promise(resolve => setTimeout(resolve, 100))
            
            const result = await this.$swal.fire({
              title: 'Observação Interna da CPM',
              text: 'Esta observação será visível apenas para a equipe da CPM',
              input: 'textarea',
              inputPlaceholder: 'Digite suas observações sobre a análise deste participante...',
              showCancelButton: true,
              confirmButtonText: 'Salvar',
              cancelButtonText: 'Cancelar',
              inputValidator: (value) => {
                if (!value) {
                  return 'Você precisa inserir uma observação!'
                }
              }
            })

            if (result.isConfirmed) {
              const observacao = result.value

              const { error } = await supabase
                .from('participantes_editais')
                .update({ observacoes_internas: observacao })
                .eq('id', participanteId)

              if (error) throw error

              this.$swal.fire({
                icon: 'success',
                title: 'Sucesso!',
                text: 'Observação interna adicionada com sucesso'
              })
              
              // Reabrir modal atualizado
              setTimeout(() => {
                this.criarModalParticipantes(edital)
              }, 500)
            }

          } catch (error) {
            console.error('Erro ao adicionar observação:', error)
            this.$swal.fire({
              icon: 'error',
              title: 'Erro',
              text: 'Erro ao adicionar observação interna'
            })
            
            // Reabrir modal após erro
            setTimeout(() => {
              this.criarModalParticipantes(edital)
            }, 2000)
          }
        }
      },

      getStatusColor(status) {
        const colors = {
          'INTERESSADO': '#17a2b8',
          'DOCUMENTACAO_ENVIADA': '#ffc107',
          'EM_AVALIACAO': '#fd7e14',
          'APROVADO': '#28a745',
          'REPROVADO': '#dc3545',
          'DESISTENTE': '#6c757d'
        }
        return colors[status] || '#6c757d'
      },


      formatarCNPJSimples(cnpj) {
        if (!cnpj) return ''
        if (cnpj.includes('.')) return cnpj
        return cnpj.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5')
      },

      formatDateSimples(date) {
        if (!date) return 'N/A'
        return new Date(date).toLocaleDateString('pt-BR', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric'
        })
      },

      abrirDocumento(url) {
        console.log('📄 Abrindo documento:', url)
        
        if (url && url !== 'uploads/documento-exemplo.pdf') {
          // CORREÇÃO: Verificar se é um PDF real (não Word mascarado)
          if (url.includes('editais-pdf/') || url.includes('.pdf')) {
            // É um PDF real convertido
            window.open(url, '_blank')
          } else {
            // Ainda é arquivo Word - mostrar aviso
            this.$swal.fire({
              icon: 'warning',
              title: 'Documento ainda não convertido',
              html: `
                <p>Este edital ainda contém a minuta Word original.</p>
                <p><strong>Para obter o PDF oficial:</strong></p>
                <ol style="text-align: left; margin: 15px 0;">
                  <li>Clique em "Converter para PDF e Publicar"</li>
                  <li>Confirme a conversão</li>
                  <li>O sistema gerará o PDF oficial automaticamente</li>
                </ol>
                <p style="color: #28a745;">Após a conversão, o botão "Abrir PDF" mostrará o documento oficial.</p>
              `,
              confirmButtonText: 'Entendi',
              confirmButtonColor: '#3085d6'
            })
          }
        } else {
          this.$swal.fire('Aviso', 'Documento não disponível', 'warning')
        }
      },

      async baixarDocumento(edital) {
        if (!edital.url_documento || edital.url_documento === 'uploads/documento-exemplo.pdf') {
          this.$swal.fire('Aviso', 'Documento não disponível para download', 'warning')
          return
        }

        try {
          // Mostrar loading
          this.$swal.fire({
            title: 'Preparando download...',
            text: 'Aguarde um momento',
            allowOutsideClick: false,
            didOpen: () => {
              this.$swal.showLoading()
            }
          })

          // Criar link temporário para download
          const link = document.createElement('a')
          link.href = edital.url_documento
          link.download = edital.nome_arquivo || `edital_${edital.numero}.pdf`
          link.target = '_blank'
          
          document.body.appendChild(link)
          link.click()
          document.body.removeChild(link)

          this.$swal.close()

        } catch (error) {
          console.error('Erro no download:', error)
          this.$swal.fire({
            icon: 'error',
            title: 'Erro no download',
            text: 'Não foi possível baixar o arquivo. Tente novamente.'
          })
        }
      },

      async handleFileUpload(event) {
        const file = event.target.files[0]
        if (!file) return

        // Validações
        if (file.type !== 'application/pdf') {
          this.$swal.fire('Erro', 'Apenas arquivos PDF são permitidos', 'error')
          event.target.value = ''
          return
        }

        if (file.size > 10 * 1024 * 1024) { // 10MB
          this.$swal.fire('Erro', 'Arquivo muito grande. Máximo 10MB', 'error')
          event.target.value = ''
          return
        }

        try {
          // Mostrar loading
          this.$swal.fire({
            title: 'Fazendo upload...',
            text: 'Aguarde enquanto o arquivo é enviado',
            allowOutsideClick: false,
            didOpen: () => {
              this.$swal.showLoading()
            }
          })

          // Gerar nome único para o arquivo
          const timestamp = Date.now()
          const tenantId = localStorage.getItem('tenant_id') || 'default'
          const fileName = `edital_${timestamp}_${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`
          const filePath = `${tenantId}/editais/${fileName}`

          // Upload para o Supabase Storage
          const { data, error } = await supabase.storage
            .from('editais')
            .upload(filePath, file, {
              cacheControl: '3600',
              upsert: false
            })

          if (error) {
            console.error('Erro no upload:', error)
            throw error
          }

          // Obter URL pública do arquivo
          const { data: publicData } = supabase.storage
            .from('editais')
            .getPublicUrl(filePath)

          if (publicData?.publicUrl) {
            this.editalAtual.url_documento = publicData.publicUrl
            this.editalAtual.nome_arquivo = file.name
            
            this.$swal.fire({
              icon: 'success',
              title: 'Upload realizado!',
              text: 'Arquivo PDF enviado com sucesso',
              timer: 2000
            })
          } else {
            throw new Error('Não foi possível obter URL do arquivo')
          }

        } catch (error) {
          console.error('Erro no upload:', error)
          
          // Verificar se o bucket existe, se não, tentar criar
          if (error.message?.includes('Bucket not found') || error.statusCode === 404) {
            try {
              await this.criarBucketEditais()
              // Tentar upload novamente
              await this.handleFileUpload(event)
              return
            } catch (bucketError) {
              console.error('Erro ao criar bucket:', bucketError)
            }
          }

          this.$swal.fire({
            icon: 'error',
            title: 'Erro no upload',
            text: 'Não foi possível enviar o arquivo. Tente novamente.',
            footer: error.message || 'Erro desconhecido'
          })
          
          event.target.value = ''
        }
      },

      async criarBucketEditais() {
        try {
          // Criar bucket se não existir
          const { data, error } = await supabase.storage.createBucket('editais', {
            public: true,
            fileSizeLimit: 10485760, // 10MB
            allowedMimeTypes: ['application/pdf']
          })

          if (error && !error.message.includes('already exists')) {
            throw error
          }

          console.log('Bucket editais criado/verificado com sucesso')
        } catch (error) {
          console.error('Erro ao criar bucket editais:', error)
          throw error
        }
      },

      // === MÉTODOS PARA PARTICIPANTES ===
      async carregarParticipantes(editalId) {
        try {
          console.log('Carregando participantes para edital ID:', editalId)
          console.log('Tenant ID:', this.currentTenantId)
          this.loadingParticipantes = true
          
          const { data, error } = await supabase
            .from('participantes_editais')
            .select('*')
            .eq('tenant_id', this.currentTenantId)
            .eq('edital_id', editalId)
            .order('data_participacao', { ascending: false })

          if (error) throw error

          console.log('Participantes carregados:', data)
          this.participantes = data || []
          this.aplicarFiltrosParticipantes()

        } catch (error) {
          console.error('Erro ao carregar participantes:', error)
          this.$swal.fire('Erro', 'Erro ao carregar participantes: ' + error.message, 'error')
        } finally {
          this.loadingParticipantes = false
        }
      },

      aplicarFiltrosParticipantes() {
        let filtrados = [...this.participantes]

        if (this.filtroParticipantes.busca) {
          const busca = this.filtroParticipantes.busca.toLowerCase()
          filtrados = filtrados.filter(p => 
            p.razao_social.toLowerCase().includes(busca) ||
            p.cnpj.includes(busca) ||
            p.representante_legal.toLowerCase().includes(busca) ||
            p.email.toLowerCase().includes(busca)
          )
        }

        if (this.filtroParticipantes.status) {
          filtrados = filtrados.filter(p => p.status === this.filtroParticipantes.status)
        }

        this.participantesFiltrados = filtrados
      },

      formatarCNPJ(cnpj) {
        if (!cnpj) return ''
        // Se já tem formatação, retorna como está
        if (cnpj.includes('.')) return cnpj
        // Se são só números, aplica a máscara
        return cnpj.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5')
      },


      abrirModalNovoParticipante() {
        this.participanteAtual = {
          id: null,
          razao_social: '',
          cnpj: '',
          representante_legal: '',
          email: '',
          telefone: '',
          endereco: '',
          status: 'INTERESSADO',
          observacoes: '',
          produtos_submetidos: []
        }
        this.modalNovoParticipante = true
      },

      fecharModalParticipantes() {
        this.modalParticipantes = false
        this.editalSelecionado = {}
        this.participantes = []
        this.participantesFiltrados = []
        this.filtroParticipantes = { busca: '', status: '' }
      },

      fecharModalNovoParticipante() {
        this.modalNovoParticipante = false
        this.participanteAtual = {
          id: null,
          razao_social: '',
          cnpj: '',
          representante_legal: '',
          email: '',
          telefone: '',
          endereco: '',
          status: 'INTERESSADO',
          observacoes: '',
          produtos_submetidos: []
        }
      },

      async salvarParticipante() {
        try {
          if (!this.participanteAtual.razao_social || !this.participanteAtual.cnpj || 
              !this.participanteAtual.representante_legal || !this.participanteAtual.email) {
            this.$swal.fire('Erro', 'Preencha todos os campos obrigatórios', 'error')
            return
          }

          const participanteData = {
            tenant_id: this.currentTenantId,
            edital_id: this.editalSelecionado.id,
            razao_social: this.participanteAtual.razao_social,
            cnpj: this.participanteAtual.cnpj,
            representante_legal: this.participanteAtual.representante_legal,
            email: this.participanteAtual.email,
            telefone: this.participanteAtual.telefone,
            endereco: this.participanteAtual.endereco,
            status: this.participanteAtual.status,
            observacoes: this.participanteAtual.observacoes,
            produtos_submetidos: this.participanteAtual.produtos_submetidos
          }

          let result
          if (this.participanteAtual.id) {
            // Atualizar
            const { data, error } = await supabase
              .from('participantes_editais')
              .update(participanteData)
              .eq('id', this.participanteAtual.id)
              .select()
              .single()
            result = { data, error }
          } else {
            // Criar novo
            const { data, error } = await supabase
              .from('participantes_editais')
              .insert(participanteData)
              .select()
              .single()
            result = { data, error }
          }

          if (result.error) throw result.error

          await this.carregarParticipantes(this.editalSelecionado.id)
          this.fecharModalNovoParticipante()

          this.$swal.fire({
            icon: 'success',
            title: 'Participante salvo!',
            text: `${this.participanteAtual.razao_social} foi ${this.participanteAtual.id ? 'atualizado' : 'adicionado'} com sucesso.`,
            timer: 2000
          })

        } catch (error) {
          console.error('Erro ao salvar participante:', error)
          this.$swal.fire('Erro', 'Erro ao salvar participante: ' + error.message, 'error')
        }
      },

      editarParticipante(participante) {
        this.participanteAtual = { ...participante }
        this.modalNovoParticipante = true
      },

      async removerParticipante(participante) {
        try {
          const result = await this.$swal.fire({
            title: 'Remover Participante',
            text: `Tem certeza que deseja remover ${participante.razao_social}?`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sim, remover',
            cancelButtonText: 'Cancelar',
            confirmButtonColor: '#d33'
          })

          if (result.isConfirmed) {
            const { error } = await supabase
              .from('participantes_editais')
              .delete()
              .eq('id', participante.id)

            if (error) throw error

            // Recarregar participantes
            await this.carregarParticipantes(this.editalSelecionado.id)
            
            // Recarregar editais para atualizar contador
            await this.carregarEditais()

            this.$swal.fire('Removido!', 'Participante removido com sucesso.', 'success')
          }

        } catch (error) {
          console.error('Erro ao remover participante:', error)
          this.$swal.fire('Erro', 'Erro ao remover participante: ' + error.message, 'error')
        }
      },
    
    // === MÉTODOS PARA USUÁRIOS ===
    async carregarUsuarios() {
      try {
        const { data, error } = await supabase
          .from('usuarios_rdm')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .order('nome_usuario', { ascending: true })
        
        if (error) throw error
        
        this.usuarios = data || []
        this.aplicarFiltrosUsuarios()
      } catch (error) {
        console.error('Erro ao carregar usuários:', error)
      }
    },
    
    aplicarFiltrosUsuarios() {
      let filtrados = [...this.usuarios]
      
      if (this.filtroUsuarios.busca) {
        const busca = this.filtroUsuarios.busca.toLowerCase()
        filtrados = filtrados.filter(usuario => 
          usuario.nome_usuario?.toLowerCase().includes(busca) ||
          usuario.unidade_setor?.toLowerCase().includes(busca) ||
          usuario.nome_coordenador?.toLowerCase().includes(busca) ||
          usuario.email?.toLowerCase().includes(busca)
        )
      }
      
      if (this.filtroUsuarios.unidade) {
        filtrados = filtrados.filter(usuario => 
          usuario.unidade_setor === this.filtroUsuarios.unidade
        )
      }
      
      this.usuariosFiltrados = filtrados
    },
    
    async abrirModalNovoUsuario() {
      console.log('➕ Abrindo modal de novo usuário...')
      
      // Primeiro carregar produtos disponíveis
      await this.carregarProdutos()
      
      this.usuarioAtual = {
        nome_usuario: '',
        unidade_setor: '',
        nome_coordenador: '',
        telefone: '',
        email: '',
        materiais: [{
          produto_id: '',
          nome: '',
          codigo: '',
          periodicidade_rdm: ''
        }],
        criar_login: false
      }
      
      console.log('✅ Modal novo usuário preparado')
      console.log('📦 Produtos disponíveis:', this.produtosDisponiveis.length)
      
      this.modalNovoUsuario = true
    },
    
    fecharModalNovoUsuario() {
      this.modalNovoUsuario = false
      this.usuarioAtual = {
        nome_usuario: '',
        unidade_setor: '',
        nome_coordenador: '',
        telefone: '',
        email: '',
        materiais: [],
        criar_login: false
      }
    },
    
    adicionarMaterial() {
      this.usuarioAtual.materiais.push({
        produto_id: '',
        nome: '',
        codigo: '',
        periodicidade_rdm: ''
      })
    },
    
    removerMaterial(index) {
      this.usuarioAtual.materiais.splice(index, 1)
    },
    
    async salvarUsuario() {
      console.log('🚀 INICIANDO salvarUsuario...')
      console.log('📊 Estado inicial:', {
        usuarioAtual: this.usuarioAtual,
        temCriarLogin: this.usuarioAtual?.criar_login,
        temId: !!this.usuarioAtual?.id
      })
      
      try {
        let senhaTemporaria = null
        let usuarioSupabaseId = null
        
        console.log('✅ Variáveis inicializadas com sucesso')
        
        // 1. Criar login no Supabase se solicitado
        console.log('🔍 Verificando necessidade de criar login...')
        if (this.usuarioAtual.criar_login && !this.usuarioAtual.id) {
          console.log('🔐 Criando login automático para:', this.usuarioAtual.email)
          
          // Gerar senha temporária
          console.log('🎯 Gerando senha temporária...')
          senhaTemporaria = this.gerarSenhaTemporaria()
          console.log('✅ Senha temporária gerada:', senhaTemporaria ? 'SIM' : 'NÃO')
          
          try {
            // SIMULAÇÃO: Criar usuário (auth.admin só funciona no servidor)
            // Em produção, isso seria feito via API/webhook
            console.log('🔐 SIMULAÇÃO - Criando usuário:', {
              email: this.usuarioAtual.email,
              senha: senhaTemporaria,
              tipo: 'rdm'
            })
            
            // Para desenvolvimento, simular criação de usuário com UUID válido
            const usuarioSimuladoId = crypto.randomUUID ? crypto.randomUUID() : 
              'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                const r = Math.random() * 16 | 0;
                const v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
              });
            const authData = { user: { id: usuarioSimuladoId } }
            const authError = null
            
            if (authError) {
              console.error('Erro ao criar usuário no Supabase Auth:', authError)
              throw new Error('Não foi possível criar o login. Verifique se o email já está cadastrado.')
            }
            
            usuarioSupabaseId = authData.user.id
            console.log('✅ Usuário criado no Supabase Auth:', usuarioSupabaseId)
            
          } catch (authError) {
            console.error('Erro na criação do login:', authError)
            alert('Erro ao criar login do usuário. Usuário será cadastrado sem acesso ao sistema.')
            // Continua sem criar login
          }
        }
        
        // 2. Preparar dados do usuário
        console.log('📝 Preparando dados do usuário...')
        console.log('🔑 Dados de entrada:', {
          currentTenantId: this.currentTenantId,
          usuarioSupabaseId: usuarioSupabaseId,
          senhaTemporaria: senhaTemporaria ? 'EXISTE' : 'NULL'
        })
        
        const userData = {
          ...this.usuarioAtual,
          tenant_id: this.currentTenantId,
          user_id: usuarioSupabaseId,
          senha_temporaria: senhaTemporaria,
          convite_enviado: false,
          convite_aceito: false,
          ativo: true,
          criado_em: new Date().toISOString(),
          atualizado_em: new Date().toISOString()
        }
        
        console.log('✅ Dados do usuário preparados com sucesso')
        
        // Remove campos auxiliares e problemáticos
        delete userData.criar_login
        
        // CORREÇÃO: Remove o campo 'id' para novos usuários para permitir geração automática de UUID
        if (!this.usuarioAtual.id) {
          delete userData.id
          console.log('🆔 Campo ID removido para permitir geração automática de UUID')
        }
        
        console.log('📝 Dados preparados para inserção:', {
          temId: !!userData.id,
          tenant_id: userData.tenant_id,
          nome_usuario: userData.nome_usuario,
          email: userData.email,
          materiais: userData.materiais?.length || 0
        })
        
        console.log('🔍 DIAGNÓSTICO TENANT_ID:', {
          currentTenantId: this.currentTenantId,
          userDataTenantId: userData.tenant_id,
          tenantIdType: typeof userData.tenant_id,
          tenantIdLength: userData.tenant_id?.length,
          isValidUUID: /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(userData.tenant_id)
        })
        
        // 3. Salvar no banco
        if (this.usuarioAtual.id) {
          // Atualizar - CORREÇÃO: Não sobrescrever dados de login existentes
          const updateData = { ...userData }
          
          // Se não está criando novo login, remover campos de senha para não sobrescrever
          if (!this.usuarioAtual.criar_login) {
            delete updateData.user_id
            delete updateData.senha_temporaria
            delete updateData.convite_enviado  
            delete updateData.convite_aceito
            console.log('🔐 Campos de login preservados (não serão sobrescritos)')
          }
          
          const { error } = await supabase
            .from('usuarios_rdm')
            .update(updateData)
            .eq('id', this.usuarioAtual.id)
            .eq('tenant_id', this.currentTenantId)
          
          if (error) throw error
          console.log('✅ Usuário atualizado com sucesso')
        } else {
          // Criar
          const { data: insertData, error } = await supabase
            .from('usuarios_rdm')
            .insert([userData])
            .select()
          
          if (error) throw error
          
          userData.id = insertData[0].id
          console.log('✅ Usuário criado com sucesso:', userData.id)
        }
        
        // 4. Enviar email de convite se login foi criado
        console.log('📧 Verificando envio de email...')
        let emailResult = null
        if (usuarioSupabaseId && senhaTemporaria) {
          console.log('📧 Condições atendidas, enviando email...')
          console.log('📧 Dados para envio:', {
            usuarioSupabaseId: usuarioSupabaseId ? 'EXISTE' : 'NULL',
            senhaTemporaria: senhaTemporaria ? 'EXISTE' : 'NULL',
            email: userData.email
          })
          
          try {
            emailResult = await this.enviarEmailConvite(userData, senhaTemporaria)
            console.log('📧 Resultado do email:', emailResult)
          } catch (emailError) {
            console.error('❌ ERRO ESPECÍFICO NO EMAIL:', emailError)
            emailResult = { success: false, message: emailError.message }
          }
        } else {
          console.log('⏩ Pulando envio de email (condições não atendidas)')
        }
        
        this.fecharModalNovoUsuario()
        await this.carregarUsuarios()
        
        // Mostrar mensagem de sucesso baseada no resultado do email
        if (usuarioSupabaseId) {
          if (emailResult && emailResult.success) {
            alert(`🎉 USUÁRIO CADASTRADO COM SUCESSO!

✅ Usuário: ${this.usuarioAtual.nome_usuario}
✅ Login criado no sistema
✅ Email enviado para: ${this.usuarioAtual.email}

📧 O usuário receberá:
• Link de acesso: ${window.location.origin.includes('localhost') ? window.location.origin + '/rdm' : window.location.origin + '/#/rdm'}
• Senha temporária para primeiro acesso
• Instruções completas de uso

O usuário já pode fazer login no sistema!`)
          } else {
            alert(`⚠️ USUÁRIO CADASTRADO (Email com problema)

✅ Usuário: ${this.usuarioAtual.nome_usuario}
✅ Login criado no sistema
⚠️ Email NÃO foi enviado automaticamente

🔧 AÇÃO NECESSÁRIA:
Envie manualmente os dados de acesso:
📧 Email: ${this.usuarioAtual.email}
🔑 Senha: ${senhaTemporaria}
🔗 Link: ${window.location.origin.includes('localhost') ? window.location.origin + '/rdm' : window.location.origin + '/#/rdm'}

O sistema funciona normalmente, apenas o email automático falhou.`)
          }
        } else {
          alert('✅ Usuário cadastrado com sucesso!')
        }
        
        // Programar alertas RDM
        this.programarAlertasRDM(userData)
        
      } catch (error) {
        console.error('❌ ERRO PRINCIPAL em salvarUsuario:', error)
        console.error('📊 INFORMAÇÕES DO ERRO PRINCIPAL:', {
          tipo: typeof error,
          nome: error?.name,
          mensagem: error?.message,
          stack: error?.stack
        })
        
        let mensagemAmigavel = 'Erro desconhecido. Tente novamente.'
        
        try {
          if (error && error.message) {
            mensagemAmigavel = error.message
          } else if (error && typeof error.toString === 'function') {
            mensagemAmigavel = error.toString()
          }
        } catch (msgError) {
          console.error('Erro ao extrair mensagem:', msgError)
        }
        
        alert(`❌ Erro ao salvar usuário: ${mensagemAmigavel}`)
      }
    },
    
    async editarUsuario(usuario) {
      console.log('🔧 Editando usuário:', usuario.nome_usuario)
      console.log('📋 Materiais do usuário:', usuario.materiais)
      
      // Primeiro carregar produtos disponíveis
      await this.carregarProdutos()
      
      // Copiar dados do usuário
      this.usuarioAtual = { ...usuario }
      
      // Garantir que materiais existe como array
      if (!this.usuarioAtual.materiais || !Array.isArray(this.usuarioAtual.materiais)) {
        console.log('⚠️ Materiais não encontrados, inicializando array vazio')
        this.usuarioAtual.materiais = []
      }
      
      // Processar cada material existente
      this.usuarioAtual.materiais = this.usuarioAtual.materiais.map((material, index) => {
        console.log(`📦 Processando material ${index + 1}:`, material)
        
        const materialProcessado = {
          produto_id: material.produto_id || '',
          nome: material.nome || '',
          codigo: material.codigo || '',
          periodicidade_rdm: material.periodicidade_rdm || 'mensal',
          marca: material.marca || '',
          categoria: material.categoria || '',
          ...material
        }
        
        console.log(`✅ Material ${index + 1} processado:`, materialProcessado)
        return materialProcessado
      })
      
      console.log('✅ Usuário preparado para edição:', this.usuarioAtual)
      console.log('📦 Produtos disponíveis:', this.produtosDisponiveis.length)
      
      // Abrir modal
      this.modalNovoUsuario = true
    },
    
    async removerUsuario(usuario) {
      if (!confirm(`Tem certeza que deseja remover o usuário "${usuario.nome_usuario}"?`)) {
        return
      }
      
      try {
        const { error } = await supabase
          .from('usuarios_rdm')
          .delete()
          .eq('id', usuario.id)
          .eq('tenant_id', this.currentTenantId)
        
        if (error) throw error
        
        await this.carregarUsuarios()
      } catch (error) {
        console.error('Erro ao remover usuário:', error)
        alert('Erro ao remover usuário. Tente novamente.')
      }
    },
    
    verMateriaisUsuario(usuario) {
      alert(`Materiais de ${usuario.nome_usuario}:\n\n${usuario.materiais?.map(m => `• ${m.nome} (${m.codigo}) - RDM ${m.periodicidade_rdm}`).join('\n') || 'Nenhum material cadastrado'}`)
    },
    
    calcularProximoRDM(usuario) {
      if (!usuario.materiais || usuario.materiais.length === 0) {
        return 'N/A'
      }
      
      // Lógica simplificada - pode ser expandida
      const hoje = new Date()
      const proximoMes = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 1)
      return proximoMes.toLocaleDateString('pt-BR')
    },
    
    programarAlertasRDM(usuario) {
      // Implementar lógica de alertas automáticos no futuro
      console.log('Alertas RDM programados para:', usuario.nome_usuario)
    },

    // === TESTE DE EMAIL ===
    async testarEmailJS() {
      if (!confirm('🧪 Testar configuração do EmailJS?\n\nIsso enviará um email de teste para comprarbemteste@gmail.com')) {
        return
      }
      
      try {
        console.log('🧪 Iniciando teste do EmailJS...')
        
        // Verificação básica e robusta
        if (typeof emailjs === 'undefined' || !emailjs) {
          throw new Error('❌ EmailJS não está carregado')
        }
        
        if (typeof emailjs.init !== 'function' || typeof emailjs.send !== 'function') {
          throw new Error('❌ Métodos EmailJS não estão disponíveis')
        }
        
        const EMAILJS_CONFIG = {
          serviceId: 'service_7sv1naw',
          templateId: 'template_nyiw2ua',
          publicKey: 'DqGKMNJ87ch3qVxGv'
        }
        
        console.log('🧪 Configuração:', EMAILJS_CONFIG)
        
        // Inicializar EmailJS (OBRIGATÓRIO)
        try {
          console.log('🧪 Inicializando EmailJS para teste...')
          emailjs.init(EMAILJS_CONFIG.publicKey)
          console.log('✅ EmailJS inicializado com sucesso para teste')
        } catch (initError) {
          console.error('❌ Erro crítico na inicialização:', initError)
          throw new Error('Falha na inicialização do EmailJS para teste: ' + initError.message)
        }
        
        // Parâmetros de teste (FORMATO EXATO DOS EDITAIS QUE FUNCIONA)
        const emailParams = {
          numero_edital: 'TESTE-EMAILJS',
          email_empresa: 'comprarbemteste@gmail.com',
          message: `
🧪 TESTE DE CONFIGURAÇÃO EMAILJS

Este é um email de teste para verificar se o EmailJS está funcionando corretamente.

=== INFORMAÇÕES DO TESTE ===
Data do teste: ${new Date().toLocaleString('pt-BR')}
Sistema: ${window.location.origin}
Template: template_nyiw2ua
Service: service_7sv1naw

=== RESULTADO ===
Se você recebeu este email, a configuração está funcionando perfeitamente!

=== PRÓXIMO PASSO ===
Agora você pode cadastrar usuários RDM com confiança que os emails serão enviados.

---
Sistema Comprar Bem - Compras Públicas Inteligentes
Teste automático de configuração EmailJS
          `,
          name: 'Teste do Sistema',
          email: 'comprarbemteste@gmail.com',
          subject: '🧪 Teste de Configuração EmailJS - Sistema Comprar Bem',
          status_participante: 'aprovado',
          motivo_rejeicao: ''
        }
        
        console.log('🧪 Enviando email de teste...')
        console.log('🧪 Parâmetros:', emailParams)
        
        // Enviar email de teste
        const result = await emailjs.send(
          EMAILJS_CONFIG.serviceId,
          EMAILJS_CONFIG.templateId,
          emailParams,
          EMAILJS_CONFIG.publicKey
        )
        
        console.log('✅ Teste bem-sucedido:', result)
        
        if (result && result.status === 200) {
          alert('✅ TESTE REALIZADO COM SUCESSO!\n\n📧 Email de teste enviado para comprarbemteste@gmail.com\n\n✅ EmailJS está configurado corretamente')
        } else {
          throw new Error(`Status de resposta inesperado: ${result?.status}`)
        }
        
      } catch (error) {
        console.error('❌ Falha no teste:', error)
        alert(`❌ FALHA NO TESTE DO EMAILJS

Erro: ${error.message}

Possíveis causas:
• Configuração incorreta do EmailJS
• Problemas de conectividade
• Service ID ou Template ID inválidos
• Public Key incorreta

Verifique:
1. Configuração no EmailJS Dashboard
2. Conexão com a internet
3. Console do navegador para mais detalhes`)
      }
    },
    

    
    // === MÉTODOS PARA RECLAMAÇÕES ===
    async carregarReclamacoes() {
      try {
        console.log('🔍 [RECLAMAÇÕES CPM] Carregando reclamações para tenant:', this.currentTenantId)
        
        const { data: reclamacoes, error } = await supabase
          .from('reclame_aqui')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .order('criado_em', { ascending: false })
        
        if (error) {
          console.error('❌ [RECLAMAÇÕES CPM] Erro ao carregar reclamações:', error)
          this.reclamacoes = []
        } else {
          console.log('✅ [RECLAMAÇÕES CPM] Reclamações carregadas:', reclamacoes?.length || 0)
          this.reclamacoes = reclamacoes || []
          
          // Inicializar campos auxiliares para cada reclamação
          this.reclamacoes.forEach(reclamacao => {
            if (!reclamacao.nova_resposta) {
              this.$set(reclamacao, 'nova_resposta', '')
            }
            if (!reclamacao.novo_status) {
              this.$set(reclamacao, 'novo_status', reclamacao.status)
            }
            if (!reclamacao.nova_prioridade) {
              this.$set(reclamacao, 'nova_prioridade', reclamacao.prioridade)
            }
          })
        }
        
        this.aplicarFiltrosReclamacoes()
        
      } catch (error) {
        console.error('❌ [RECLAMAÇÕES CPM] Erro geral ao carregar reclamações:', error)
        this.reclamacoes = []
        this.aplicarFiltrosReclamacoes()
      }
    },
    
    // Filtrar reclamações
    aplicarFiltrosReclamacoes() {
      this.reclamacoesFiltradas = this.reclamacoes.filter(reclamacao => {
        const matchBusca = !this.filtroReclamacoes.busca ||
          reclamacao.nome_reclamante.toLowerCase().includes(this.filtroReclamacoes.busca.toLowerCase()) ||
          reclamacao.descricao_reclamacao.toLowerCase().includes(this.filtroReclamacoes.busca.toLowerCase())
        
        const matchStatus = !this.filtroReclamacoes.status || reclamacao.status === this.filtroReclamacoes.status
        const matchPrioridade = !this.filtroReclamacoes.prioridade || reclamacao.prioridade === this.filtroReclamacoes.prioridade
        
        return matchBusca && matchStatus && matchPrioridade
      })
    },
    
    // Salvar resposta da CPM para uma reclamação
    async salvarRespostaReclamacao(reclamacao) {
      if (!reclamacao.nova_resposta?.trim()) {
        alert('Por favor, digite uma resposta antes de salvar.')
        return
      }
      
      this.salvandoResposta = true
      
      try {
        const { error } = await supabase
          .from('reclame_aqui')
          .update({
            resposta_cpm: reclamacao.nova_resposta,
            respondido_por: this.currentUserId,
            respondido_em: new Date().toISOString(),
            status: 'respondida'
          })
          .eq('id', reclamacao.id)
        
        if (error) {
          throw error
        }
        
        // Atualizar localmente
        reclamacao.resposta_cpm = reclamacao.nova_resposta
        reclamacao.respondido_em = new Date().toISOString()
        reclamacao.status = 'respondida'
        reclamacao.nova_resposta = ''
        
        alert('✅ Resposta salva com sucesso!')
        this.aplicarFiltrosReclamacoes()
        
      } catch (error) {
        console.error('❌ Erro ao salvar resposta:', error)
        alert('❌ Erro ao salvar resposta. Tente novamente.')
      } finally {
        this.salvandoResposta = false
      }
    },
    
    // Alterar status de uma reclamação
    async alterarStatusReclamacao(reclamacao) {
      if (!reclamacao.novo_status || reclamacao.novo_status === reclamacao.status) {
        return
      }
      
      this.salvandoStatus = true
      
      try {
        const { error } = await supabase
          .from('reclame_aqui')
          .update({
            status: reclamacao.novo_status
          })
          .eq('id', reclamacao.id)
        
        if (error) {
          throw error
        }
        
        // Atualizar localmente
        reclamacao.status = reclamacao.novo_status
        
        this.aplicarFiltrosReclamacoes()
        
      } catch (error) {
        console.error('❌ Erro ao alterar status:', error)
        alert('❌ Erro ao alterar status. Tente novamente.')
        // Reverter o valor
        reclamacao.novo_status = reclamacao.status
      } finally {
        this.salvandoStatus = false
      }
    },
    
    // Alterar prioridade de uma reclamação
    async alterarPrioridadeReclamacao(reclamacao) {
      if (!reclamacao.nova_prioridade || reclamacao.nova_prioridade === reclamacao.prioridade) {
        return
      }
      
      this.salvandoPrioridade = true
      
      try {
        const { error } = await supabase
          .from('reclame_aqui')
          .update({
            prioridade: reclamacao.nova_prioridade
          })
          .eq('id', reclamacao.id)
        
        if (error) {
          throw error
        }
        
        // Atualizar localmente
        reclamacao.prioridade = reclamacao.nova_prioridade
        
        this.aplicarFiltrosReclamacoes()
        
      } catch (error) {
        console.error('❌ Erro ao alterar prioridade:', error)
        alert('❌ Erro ao alterar prioridade. Tente novamente.')
        // Reverter o valor
        reclamacao.nova_prioridade = reclamacao.prioridade
      } finally {
        this.salvandoPrioridade = false
      }
    },
    
    // Editar resposta existente
    editarResposta(reclamacao) {
      reclamacao.nova_resposta = reclamacao.resposta_cpm
      reclamacao.resposta_cpm = null // Temporariamente limpar para mostrar o textarea
    },
    
    
    getPrioridadeClass(prioridade) {
      const classes = {
        'baixa': 'prioridade-baixa',
        'normal': 'prioridade-normal',
        'alta': 'prioridade-alta',
        'critica': 'prioridade-critica'
      }
      return classes[prioridade] || 'prioridade-normal'
    },
    
    getPrioridadeText(prioridade) {
      const texts = {
        'baixa': 'Baixa',
        'normal': 'Normal', 
        'alta': 'Alta',
        'critica': 'Crítica'
      }
      return texts[prioridade] || prioridade
    },
    
    // Método antigo - manter para compatibilidade
    async enriquecerAvaliacoesComUsuarios(avaliacoes) {
      try {
        const avaliacoesEnriquecidas = []
        
        for (const avaliacao of avaliacoes) {
          if (avaliacao.usuario_rdm_id) {
            const { data: usuario, error } = await supabase
              .from('usuarios_rdm')
              .select('nome_usuario, unidade_setor, email, telefone')
              .eq('id', avaliacao.usuario_rdm_id)
              .eq('tenant_id', this.currentTenantId)
              .single()
            
            avaliacoesEnriquecidas.push({
              ...avaliacao,
              usuario_rdm: usuario || null
            })
          } else {
            avaliacoesEnriquecidas.push({
              ...avaliacao,
              usuario_rdm: null
            })
          }
        }
        
        return avaliacoesEnriquecidas
      } catch (error) {
        console.error('❌ [AVALIAÇÕES CPM] Erro ao enriquecer com usuários:', error)
        return avaliacoes.map(avaliacao => ({
          ...avaliacao,
          usuario_rdm: null
        }))
      }
    },
    
    aplicarFiltrosAvaliacoes() {
      let filtradas = [...this.avaliacoes]
      
      if (this.filtroAvaliacoes.busca) {
        const busca = this.filtroAvaliacoes.busca.toLowerCase()
        filtradas = filtradas.filter(avaliacao => 
          avaliacao.material_nome?.toLowerCase().includes(busca) ||
          avaliacao.material_codigo?.toLowerCase().includes(busca) ||
          avaliacao.usuario_rdm?.nome_usuario?.toLowerCase().includes(busca) ||
          avaliacao.usuario_rdm?.unidade_setor?.toLowerCase().includes(busca) ||
          avaliacao.comentario?.toLowerCase().includes(busca)
        )
      }
      
      if (this.filtroAvaliacoes.rating) {
        filtradas = filtradas.filter(avaliacao => 
          avaliacao.rating == this.filtroAvaliacoes.rating
        )
      }
      
      if (this.filtroAvaliacoes.usuario) {
        filtradas = filtradas.filter(avaliacao => 
          avaliacao.usuario_rdm?.nome_usuario?.toLowerCase().includes(this.filtroAvaliacoes.usuario.toLowerCase())
        )
      }
      
      this.avaliacoesFiltradas = filtradas
    },
    
    // Salvar resposta da CPM para uma avaliação
    async salvarRespostaCPM(avaliacao) {
      if (!avaliacao.nova_resposta || !avaliacao.nova_resposta.trim()) {
        this.$swal({
          title: 'Atenção',
          text: 'Por favor, digite um comentário ou decisão.',
          icon: 'warning'
        })
        return
      }
      
      this.salvandoResposta = true
      
      try {
        const { error } = await supabase
          .from('material_feedbacks')
          .update({
            resposta_cpm: avaliacao.nova_resposta.trim(),
            data_resposta_cpm: new Date().toISOString()
          })
          .eq('id', avaliacao.id)
        
        if (error) throw error
        
        // Atualizar localmente
        avaliacao.resposta_cpm = avaliacao.nova_resposta.trim()
        avaliacao.data_resposta_cpm = new Date().toISOString()
        avaliacao.nova_resposta = ''
        
        this.$swal({
          title: 'Sucesso!',
          text: 'Comentário/Decisão da CPM salvo com sucesso',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        })
        
      } catch (error) {
        console.error('Erro ao salvar resposta da CPM:', error)
        this.$swal({
          title: 'Erro',
          text: 'Erro ao salvar resposta: ' + error.message,
          icon: 'error'
        })
      } finally {
        this.salvandoResposta = false
      }
    },

    
    // ============================================
    // SISTEMA DE CONVITES AUTOMÁTICOS
    // ============================================
    
    toggleLoginSystem() {
      if (!this.usuarioAtual.criar_login) {
        this.usuarioAtual.senha_temporaria = null
        this.usuarioAtual.user_id = null
      }
    },
    
    gerarSenhaTemporaria() {
      // Gera senha simples e definitiva: CB + ano + 4 dígitos
      const ano = new Date().getFullYear()
      const numero = Math.floor(Math.random() * 10000).toString().padStart(4, '0')
      return `CB${ano}${numero}`
    },
    
    async enviarEmailConvite(usuario, senhaTemporaria) {
      try {
        console.log('📧 Enviando email REAL de convite para:', usuario.email)
        
        // VERIFICAÇÃO 1: EmailJS disponível?
        if (typeof emailjs === 'undefined' || !emailjs) {
          throw new Error('EmailJS não está carregado. Verifique a importação.')
        }
        
        // VERIFICAÇÃO 1.1: Métodos EmailJS disponíveis?
        if (typeof emailjs.init !== 'function' || typeof emailjs.send !== 'function') {
          throw new Error('Métodos EmailJS não estão disponíveis. Verifique a versão.')
        }
        
        // VERIFICAÇÃO 2: Configuração EmailJS
        const EMAILJS_CONFIG = {
          serviceId: 'service_7sv1naw', 
          templateId: 'template_nyiw2ua', // Template existente
          publicKey: 'DqGKMNJ87ch3qVxGv'
        }
        
        console.log('📧 EmailJS disponível:', typeof emailjs)
        console.log('📧 Configuração:', EMAILJS_CONFIG)
        
        // Preparar dados para EmailJS (FORMATO EXATO DOS EDITAIS QUE FUNCIONA)
        const emailParams = {
          // EXATOS parâmetros que funcionam no enviarEmailParticipanteStatus
          numero_edital: 'RDM-CONVITE',
          email_empresa: usuario.email,
          message: `
🔐 BEM-VINDO AO SISTEMA COMPRAR BEM

Olá ${usuario.nome_usuario}!

Você foi cadastrado(a) para acessar o Sistema Comprar Bem - Dashboard RDM Online.

=== SEUS DADOS DE ACESSO ===
Email: ${usuario.email}
Senha de Acesso: ${senhaTemporaria}
Unidade/Setor: ${usuario.unidade_setor}
Coordenador: ${usuario.nome_coordenador}

=== COMO ACESSAR ===
1. Acesse: ${window.location.origin.includes('localhost') ? window.location.origin + '/rdm' : window.location.origin + '/#/rdm'}
2. Faça login com seu email e senha
3. Comece a emitir suas RDMs online!

=== FUNCIONALIDADES DISPONÍVEIS ===
✅ Emissão de RDMs online
✅ Histórico de solicitações
✅ Acompanhamento de status
✅ Notificações automáticas

=== IMPORTANTE ===
🔑 Use sempre a mesma senha para acessar o sistema
📝 Guarde seus dados de acesso em local seguro
📞 Em caso de dúvidas, entre em contato conosco

=== SUPORTE ===
Email: comprarbemteste@gmail.com
Sistema: ${window.location.origin}

Data do cadastro: ${new Date().toLocaleDateString('pt-BR')}

---
Sistema Comprar Bem - Compras Públicas Inteligentes
Este é um email automático. Não responda diretamente.
          `,
          name: usuario.nome_usuario,
          email: 'comprarbemteste@gmail.com',
          subject: '🔐 Bem-vindo ao Sistema Comprar Bem - Acesso RDM Online',
          status_participante: 'aprovado',
          motivo_rejeicao: ''
        }
        
        console.log('📧 Enviando email REAL via EmailJS...')
        console.log('📧 Para:', usuario.email)
        console.log('📧 Config EmailJS:', EMAILJS_CONFIG)
        console.log('📧 Parâmetros do email:', emailParams)
        
        // VERIFICAÇÃO 3: Inicializar EmailJS (SEMPRE INICIALIZAR)
        try {
          console.log('📧 Inicializando EmailJS com public key...')
          emailjs.init(EMAILJS_CONFIG.publicKey)
          console.log('✅ EmailJS inicializado com sucesso')
        } catch (initError) {
          console.error('❌ Erro na inicialização do EmailJS:', initError)
          throw new Error('Falha na inicialização do EmailJS: ' + initError.message)
        }
        
        // ENVIAR EMAIL REAL via EmailJS
        console.log('📧 Chamando emailjs.send...')
        const result = await emailjs.send(
          EMAILJS_CONFIG.serviceId,
          EMAILJS_CONFIG.templateId,
          emailParams,
          EMAILJS_CONFIG.publicKey
        )
        
        console.log('🎉 EMAIL REAL ENVIADO COM SUCESSO!', result)
        
        // VERIFICAÇÃO 4: Resultado válido?
        if (!result || result.status !== 200) {
          throw new Error(`Falha no envio do email. Status: ${result?.status || 'desconhecido'}`)
        }
        
        // Marcar convite como enviado
        await supabase
          .from('usuarios_rdm')
          .update({ 
            convite_enviado: true,
            data_convite: new Date().toISOString()
          })
          .eq('id', usuario.id)
          .eq('tenant_id', this.currentTenantId)
        
        console.log('✅ Status do convite atualizado no banco')
        
        // Criar notificação para CPM
        await this.criarNotificacao(
          this.currentTenantId,
          this.currentTenantId,
          'SISTEMA',
          'Convite RDM Enviado',
          `✅ Email de convite enviado com SUCESSO!
          
📧 Destinatário: ${usuario.nome_usuario} (${usuario.email})
🔑 Senha de acesso: ${senhaTemporaria}
🔗 Link de acesso: ${window.location.origin.includes('localhost') ? window.location.origin + '/rdm' : window.location.origin + '/#/rdm'}
📅 Data: ${new Date().toLocaleString('pt-BR')}

O usuário pode fazer login imediatamente no sistema RDM.`,
          null
        )
        
        console.log('🎉 PROCESSO COMPLETO - Email enviado e notificação criada!')
        
        return { success: true, message: 'Email enviado com sucesso!' }
        
      } catch (error) {
        console.error('❌ ERRO DETALHADO ao enviar email de convite:', error)
        console.error('📊 INFORMAÇÕES DO ERRO:', {
          tipo: typeof error,
          nome: error?.name || 'SemNome',
          mensagem: error?.message || 'SemMensagem',
          stack: error?.stack || 'SemStack',
          usuario: usuario?.email || 'SemEmail',
          emailjsDisponivel: typeof emailjs,
          errorString: error?.toString() || 'NãoConvertível'
        })
        
        // ANÁLISE DETALHADA DO ERRO (SUPER SEGURA)
        let mensagemErro = 'Erro desconhecido'
        
        try {
          // Obter mensagem de erro de forma segura
          let errorMessage = 'Erro sem descrição'
          
          if (error && typeof error === 'object') {
            if (typeof error.message === 'string') {
              errorMessage = error.message
            } else if (typeof error.toString === 'function') {
              errorMessage = error.toString()
            }
          } else if (typeof error === 'string') {
            errorMessage = error
          }
          
          console.log('🔍 Mensagem de erro extraída:', errorMessage)
          
          // Análise segura da mensagem
          if (typeof errorMessage === 'string' && errorMessage.length > 0) {
            if (errorMessage.indexOf('emailjs') !== -1) {
              mensagemErro = 'EmailJS não está carregado ou configurado corretamente'
            } else if (errorMessage.indexOf('network') !== -1 || errorMessage.indexOf('fetch') !== -1) {
              mensagemErro = 'Erro de conectividade. Verifique sua conexão com a internet'
            } else if (errorMessage.indexOf('service') !== -1 || errorMessage.indexOf('template') !== -1) {
              mensagemErro = 'Configuração inválida do EmailJS (service/template ID)'
            } else if (errorMessage.indexOf('422') !== -1) {
              mensagemErro = 'Parâmetros incorretos do template EmailJS (erro 422)'
            } else if (errorMessage.indexOf('includes') !== -1) {
              mensagemErro = 'Erro interno do JavaScript (propriedade undefined)'
            } else {
              mensagemErro = errorMessage
            }
          } else {
            mensagemErro = 'Erro sem mensagem válida'
          }
                  } catch (analysisError) {
            console.error('❌ Erro na análise do erro:', analysisError)
            mensagemErro = 'Erro complexo não analisável'
          }
          
                    return { success: false, message: mensagemErro }
      }
    },
    
    async criarNotificacao(tenantId, usuarioDestino, tipo, titulo, mensagem, linkAcao = null) {
      try {
        const { error } = await supabase
          .from('notificacoes')
          .insert([{
            tenant_id: tenantId,
            usuario_destino: usuarioDestino,
            tipo: tipo,
            titulo: titulo,
            mensagem: mensagem,
            link_acao: linkAcao,
            criado_em: new Date().toISOString()
          }])
        
        if (error) throw error
        
      } catch (error) {
        console.error('Erro ao criar notificação:', error)
      }
    },
    
    async verificarStatusConvites() {
      try {
        const { data, error } = await supabase
          .from('usuarios_rdm')
          .select('id, nome_usuario, email, convite_enviado, convite_aceito, data_convite')
          .eq('tenant_id', this.currentTenantId)
          .eq('ativo', true)
          .not('user_id', 'is', null)
        
        if (error) throw error
        
        // Atualizar status visual dos convites
        this.statusConvites = data.reduce((acc, usuario) => {
          acc[usuario.id] = {
            enviado: usuario.convite_enviado,
            aceito: usuario.convite_aceito,
            dataConvite: usuario.data_convite
          }
          return acc
        }, {})
        
      } catch (error) {
        console.error('Erro ao verificar status dos convites:', error)
      }
    },
    
    async reenviarConvite(usuario) {
      if (!confirm(`Reenviar convite de acesso para ${usuario.nome_usuario}?`)) {
        return
      }
      
      try {
        // Gerar nova senha temporária
        const novaSenha = this.gerarSenhaTemporaria()
        
        // Atualizar senha no banco
        await supabase
          .from('usuarios_rdm')
          .update({ 
            senha_temporaria: novaSenha,
            convite_enviado: false
          })
          .eq('id', usuario.id)
          .eq('tenant_id', this.currentTenantId)
        
        // SIMULAÇÃO: Atualizar senha (auth.admin só funciona no servidor)
        if (usuario.user_id) {
          console.log('🔐 SIMULAÇÃO - Atualizando senha para:', usuario.email, novaSenha)
        }
        
        // Reenviar email
        await this.enviarEmailConvite({ ...usuario, senha_temporaria: novaSenha }, novaSenha)
        
        alert('✅ Convite reenviado com sucesso!')
        await this.carregarUsuarios()
        
             } catch (error) {
         console.error('Erro ao reenviar convite:', error)
         alert('❌ Erro ao reenviar convite. Tente novamente.')
       }
     },
     
     // ============================================
     // SISTEMA DE PRODUTOS/MATERIAIS
     // ============================================
     
     async carregarProdutos() {
       try {
         this.loadingProdutos = true
         console.log('📦 Carregando produtos disponíveis...')
         console.log('🔑 Tenant ID atual:', this.currentTenantId)
         
         // Primeiro, vamos ver todos os produtos sem filtros
         const { data: todosProdutos, error: erroTodos } = await supabase
           .from('produtos')
           .select('id, nome, marca, modelo, codigo_material, categoria_id, status, tenant_id')
           .order('nome')
         
         console.log('📊 Todos os produtos encontrados:', todosProdutos?.length || 0)
         console.log('📋 Primeiros 3 produtos:', todosProdutos?.slice(0, 3))
         if (todosProdutos?.length > 0) {
           console.log('🔍 Estrutura do primeiro produto:', {
             id: todosProdutos[0].id,
             nome: todosProdutos[0].nome,
             marca: todosProdutos[0].marca,
             modelo: todosProdutos[0].modelo,
             codigo_material: todosProdutos[0].codigo_material,
             categoria_id: todosProdutos[0].categoria_id,
             status: todosProdutos[0].status,
             tenant_id: todosProdutos[0].tenant_id
           })
         }
         
         // Agora com filtros
         const { data, error } = await supabase
           .from('produtos')
           .select('id, nome, marca, modelo, codigo_material, categoria_id, status, tenant_id')
           .eq('tenant_id', this.currentTenantId)
           .order('nome')
         
         console.log('🎯 Produtos do tenant atual:', data?.length || 0)
         console.log('📋 Status dos produtos:', data?.map(p => p.status))
         
         if (error) {
           console.error('❌ Erro na query:', error)
           throw error
         }
         
         // Se não houver produtos com status 'aprovado', pegar todos os produtos do tenant
         let produtosFiltrados = data?.filter(p => p.status === 'aprovado') || []
         
         if (produtosFiltrados.length === 0) {
           console.log('⚠️ Nenhum produto "aprovado" encontrado, carregando todos os produtos do tenant...')
           produtosFiltrados = data || []
         }
         
         this.produtosDisponiveis = produtosFiltrados
         console.log(`✅ ${this.produtosDisponiveis.length} produtos carregados para seleção`)
         console.log('📦 Produtos disponíveis:', this.produtosDisponiveis.map(p => `${p.nome} (${p.status})`))
         
       } catch (error) {
         console.error('❌ Erro ao carregar produtos:', error)
         this.produtosDisponiveis = []
         
         // Mostrar erro para debug
         alert(`❌ Erro ao carregar produtos:\n${error.message}\n\nVerifique o console para mais detalhes.`)
       } finally {
         this.loadingProdutos = false
       }
     },
     
     selecionarProduto(index, event) {
       const produtoId = event.target.value
       const material = this.usuarioAtual.materiais[index]
       
       console.log('🔍 Selecionando produto:', produtoId, 'para material index:', index)
       
       if (produtoId === 'NOVO') {
         // Limpar dados para permitir entrada manual
         material.produto_id = 'NOVO'
         material.nome = ''
         material.codigo = ''
         console.log('📝 Modo novo material ativado')
       } else if (produtoId) {
         // Buscar dados do produto selecionado
         const produto = this.produtosDisponiveis.find(p => p.id === produtoId)
         console.log('🔍 Produto encontrado:', produto)
         
         if (produto) {
           material.produto_id = produtoId
           material.nome = produto.nome
           material.codigo = produto.codigo_material || produto.modelo || ''
           material.marca = produto.marca || ''
           material.categoria = produto.categoria_id || ''
           
           console.log('✅ Dados do produto aplicados:', {
             nome: material.nome,
             codigo: material.codigo,
             marca: material.marca,
             categoria_id: material.categoria
           })
         }
       } else {
         // Limpar seleção
         material.produto_id = ''
         material.nome = ''
         material.codigo = ''
         console.log('🗑️ Seleção limpa')
       }
       
       console.log('📋 Material atualizado:', material)
     }
   },


   formatarData(data) {
     if (!data) return ''
     
     const date = new Date(data)
     return date.toLocaleString('pt-BR', {
       day: '2-digit',
       month: '2-digit',
       year: 'numeric',
       hour: '2-digit',
       minute: '2-digit'
     })
   },

   // Método para formatação de moeda
   formatCurrency(value) {
     return new Intl.NumberFormat('pt-BR', {
       style: 'currency',
       currency: 'BRL'
     }).format(value)
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
  padding: 6px 12px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
  font-size: 0.85em;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.btn-small:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

/* Estilo especial para botão PDF */
.btn-small:contains('📥') {
  background: linear-gradient(135deg, #dc3545, #c82333);
  border: 1px solid #bd2130;
}

.btn-small:contains('📥'):hover {
  background: linear-gradient(135deg, #c82333, #a71e2a);
  box-shadow: 0 6px 12px rgba(220, 53, 69, 0.4);
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

/* ===========================
   ESTILOS SISTEMA DE MINUTAS
   =========================== */

.minuta-selecao {
  margin-top: 20px;
}

.section-intro {
  margin-bottom: 25px;
  text-align: center;
}

.section-intro h4 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 18px;
}

.section-intro p {
  margin: 0;
  color: #666;
  font-size: 14px;
}

.minutas-actions {
  display: flex;
  justify-content: center;
  margin-bottom: 30px;
}

.minutas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.minuta-card {
  background: white;
  border: 2px solid #e9ecef;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
}

.minuta-card:hover {
  border-color: #3498db;
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.15);
  transform: translateY(-2px);
}

.minuta-card.selected {
  border-color: #3498db;
  background: #f8f9fa;
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.2);
}

.minuta-card.selected::after {
  content: '✓';
  position: absolute;
  top: 10px;
  right: 15px;
  color: #3498db;
  font-size: 20px;
  font-weight: bold;
}

.minuta-header {
  display: flex;
  align-items: center;
  margin-bottom: 15px;
}

.minuta-icon {
  font-size: 24px;
  margin-right: 15px;
}

.minuta-info h5 {
  margin: 0 0 5px 0;
  color: #2c3e50;
  font-size: 16px;
}

.minuta-categoria {
  margin: 0;
  color: #6c757d;
  font-size: 12px;
  text-transform: uppercase;
  font-weight: 600;
}

.minuta-description {
  margin-bottom: 15px;
}

.minuta-description p {
  margin: 0;
  color: #666;
  font-size: 14px;
  line-height: 1.4;
}

.minuta-meta {
  display: flex;
  justify-content: flex-end;
}

.badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
}

.badge-system {
  background: #e7f3ff;
  color: #0066cc;
}

.badge-custom {
  background: #fff3cd;
  color: #856404;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #6c757d;
}

.empty-state .empty-icon {
  font-size: 48px;
  margin-bottom: 20px;
}

.empty-state h3 {
  margin: 0 0 10px 0;
  color: #495057;
}

.empty-state p {
  margin: 0 0 20px 0;
  color: #6c757d;
}

/* Estilos para Workflow de Minutas */
.minuta-workflow {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.workflow-step {
  display: flex;
  align-items: flex-start;
  gap: 15px;
  padding: 20px;
  border-radius: 8px;
  border: 2px solid #e9ecef;
  background: #f8f9fa;
  transition: all 0.3s ease;
}

.workflow-step.active {
  border-color: #3498db;
  background: #fff;
  box-shadow: 0 2px 8px rgba(52, 152, 219, 0.1);
}

.step-number {
  background: #6c757d;
  color: white;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 14px;
  flex-shrink: 0;
}

.workflow-step.active .step-number {
  background: #3498db;
}

.step-content {
  flex: 1;
}

.step-content h5 {
  margin: 0 0 5px 0;
  color: #2c3e50;
  font-size: 16px;
}

.step-content p {
  margin: 0 0 15px 0;
  color: #6c757d;
  font-size: 14px;
}

.success-text {
  color: #28a745;
  font-weight: 600;
  margin-bottom: 10px;
}

.btn-small {
  padding: 6px 12px;
  font-size: 12px;
  border-radius: 4px;
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

/* ===========================
   ESTILOS DCB
   =========================== */

.certificados-dcb {
  margin-top: 20px;
}

.dcb-container {
  background: white;
  border-radius: 8px;
  padding: 25px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

/* Stats DCB */
.dcb-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.dcb-stats .stat-card {
  padding: 20px;
  border-radius: 8px;
  text-align: center;
  background: white;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border-left: 4px solid #3498db;
}

.dcb-pendentes {
  border-left-color: #f39c12 !important;
}

.dcb-emitidos {
  border-left-color: #2ecc71 !important;
}

.dcb-vencendo {
  border-left-color: #e67e22 !important;
}

.dcb-vencidos {
  border-left-color: #e74c3c !important;
}

.dcb-stats h4 {
  margin: 0 0 10px 0;
  font-size: 14px;
  color: #666;
}

.dcb-stats .stat-value {
  font-size: 28px;
    font-weight: bold;
  color: #2c3e50;
  margin: 10px 0;
}

.dcb-stats small {
  color: #888;
  font-size: 12px;
}

/* Abas DCB */
.dcb-tabs {
    display: flex;
  margin-bottom: 25px;
  border-bottom: 1px solid #ddd;
}

.dcb-tab {
  padding: 12px 24px;
  cursor: pointer;
  font-weight: 500;
  border-bottom: 3px solid transparent;
  transition: all 0.3s ease;
  color: #666;
}

.dcb-tab:hover {
  background-color: #f8f9fa;
  color: #3498db;
}

.dcb-tab.active {
  border-bottom-color: #3498db;
  color: #3498db;
  background-color: #f8f9fa;
}

/* Conteúdo DCB */
.dcb-content {
  min-height: 400px;
}

.section-header {
    margin-bottom: 20px;
  }

.section-header h3 {
  margin: 0 0 8px 0;
  color: #2c3e50;
}

.section-header p {
  margin: 0;
  color: #666;
  font-size: 14px;
}

/* Filtros DCB */
.filtros-dcb {
  display: flex;
  gap: 15px;
  align-items: end;
  margin-bottom: 25px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  flex-wrap: wrap;
}

.filtro-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filtro-group label {
  font-size: 12px;
  font-weight: 600;
  color: #555;
}

.filtro-group input,
.filtro-group select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  min-width: 150px;
}

.btn-limpar {
  padding: 8px 16px;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  height: fit-content;
}

.btn-limpar:hover {
  background: #5a6268;
}

/* Lista de Produtos DCB */
.produtos-dcb-lista {
  display: grid;
  gap: 20px;
}

.produto-dcb-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  background: white;
  transition: all 0.3s ease;
}

.produto-dcb-card:hover {
  border-color: #3498db;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.1);
}

.produto-info {
    flex: 1;
}

.produto-header {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 10px;
}

.produto-header h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 16px;
}

.produto-details p {
  margin: 5px 0;
  color: #666;
  font-size: 14px;
}

.produto-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.btn-primary {
    padding: 10px 20px;
  background: #3498db;
  color: white;
    border: none;
  border-radius: 4px;
    cursor: pointer;
  font-weight: 500;
  transition: background 0.3s ease;
}

.btn-primary:hover:not(:disabled) {
  background: #2980b9;
}

.btn-primary:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.btn-test-email {
  padding: 10px 20px;
  background: linear-gradient(135deg, #ff6b6b, #ffa726);
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
  margin-left: 10px;
}

.btn-test-email:hover {
  background: linear-gradient(135deg, #ff5252, #ff9800);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 107, 107, 0.3);
}

.btn-secondary {
  padding: 8px 16px;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-secondary:hover {
  background: #5a6268;
}

/* Tabela Histórico DCB */
.dcb-historico-tabela {
  overflow-x: auto;
}

.dcb-historico-tabela table {
    width: 100%;
    border-collapse: collapse;
  margin-top: 15px;
}

.dcb-historico-tabela th,
.dcb-historico-tabela td {
  padding: 12px 15px;
    text-align: left;
  border-bottom: 1px solid #e9ecef;
}

.dcb-historico-tabela th {
  background-color: #f8f9fa;
  font-weight: 600;
  color: #495057;
}

.dcb-numero {
  font-family: 'Courier New', monospace;
    font-weight: bold;
  color: #2c3e50;
}

.acoes-dcb {
  display: flex;
  gap: 8px;
}

.acoes-dcb .btn-small {
  padding: 4px 8px;
  font-size: 12px;
  border-radius: 3px;
}

.btn-danger {
  background: #e74c3c;
}

.btn-danger:hover {
  background: #c0392b;
}

/* Status DCB */
.status-ativo {
  background-color: #2ecc71;
  color: white;
}

.status-vencido {
  background-color: #e74c3c;
  color: white;
}

.status-revogado {
  background-color: #95a5a6;
  color: white;
}

/* Controle de Vencimentos */
.alertas-vencimento {
  margin-bottom: 30px;
}

.alerta-warning {
    display: flex;
    align-items: center;
  padding: 15px;
  background: #fff3cd;
  border-left: 4px solid #ffc107;
  border-radius: 4px;
  margin-bottom: 15px;
}

.alerta-danger {
  display: flex;
  align-items: center;
  padding: 15px;
  background: #f8d7da;
  border-left: 4px solid #dc3545;
  border-radius: 4px;
  margin-bottom: 15px;
}

.alerta-icon {
  font-size: 24px;
  margin-right: 15px;
}

.alerta-content h4 {
  margin: 0 0 5px 0;
  color: #495057;
}

.alerta-content p {
  margin: 0;
  color: #6c757d;
  font-size: 14px;
}

/* DCB Vencimento */
.dcb-vencimento-section {
  margin-bottom: 30px;
}

.dcb-vencimento-section h4 {
  margin-bottom: 15px;
  color: #495057;
}

.dcb-vencimento-lista {
  display: grid;
  gap: 15px;
}

.dcb-vencimento-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  border-radius: 8px;
  border-left: 4px solid;
}

.dcb-vencimento-card.warning {
  background: #fff3cd;
  border-left-color: #ffc107;
}

.dcb-vencimento-card.danger {
  background: #f8d7da;
  border-left-color: #dc3545;
}

.dcb-info h5 {
  margin: 0 0 10px 0;
  color: #495057;
}

.dcb-info p {
  margin: 3px 0;
  color: #6c757d;
  font-size: 14px;
}

.dcb-actions {
  display: flex;
  gap: 10px;
}

.btn-warning {
  padding: 8px 16px;
  background: #ffc107;
  color: #212529;
    border: none;
  border-radius: 4px;
    cursor: pointer;
  font-size: 14px;
  font-weight: 500;
}

.btn-warning:hover {
  background: #e0a800;
}

/* Estados Vazios */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #6c757d;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 20px;
}

.empty-state h3 {
  margin: 0 0 10px 0;
  color: #495057;
}

.empty-state p {
  margin: 0;
  font-size: 14px;
}



/* Modais */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
  z-index: 999999;
}

/* Modal de seleção de minuta padrão - z-index menor que SweetAlert */
.modal-overlay .modal-content {
  z-index: 999999;
}

.modal-content {
  background: white;
  border-radius: 8px;
  max-width: 800px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #e9ecef;
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
  color: #6c757d;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  color: #495057;
  background: #f8f9fa;
  border-radius: 50%;
}

.modal-body {
  padding: 20px;
}

.modal-footer {
  padding: 20px;
  border-top: 1px solid #e9ecef;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

/* Detalhes do Produto Modal */
.produto-detalhes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  margin-bottom: 20px;
}

.detalhes-section {
  padding: 15px;
  background: #f8f9fa;
  border-radius: 6px;
}

.detalhes-section h4 {
  margin: 0 0 15px 0;
  color: #495057;
  font-size: 16px;
}

.detalhes-section p {
  margin: 8px 0;
  color: #6c757d;
}

.detalhes-section pre {
  background: white;
  padding: 10px;
  border-radius: 4px;
  border: 1px solid #dee2e6;
  font-size: 12px;
  max-height: 200px;
  overflow-y: auto;
}

/* DCB Preview */
.dcb-preview {
  border: 2px solid #dee2e6;
  border-radius: 8px;
  padding: 30px;
  background: white;
  font-family: 'Times New Roman', serif;
}

.dcb-header {
  text-align: center;
  margin-bottom: 30px;
  border-bottom: 2px solid #dee2e6;
  padding-bottom: 20px;
}

.dcb-header h2 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 18px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.dcb-header h3 {
  margin: 0;
  color: #3498db;
  font-size: 16px;
}

.dcb-content-preview {
  display: grid;
  gap: 20px;
}

.dcb-section h4 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 14px;
  text-transform: uppercase;
  border-bottom: 1px solid #dee2e6;
  padding-bottom: 5px;
}

.dcb-section p {
  margin: 5px 0;
  color: #495057;
  font-size: 13px;
}

/* Responsividade */
@media (max-width: 768px) {
  .dcb-stats {
    grid-template-columns: 1fr;
  }
  
  .produto-dcb-card {
    flex-direction: column;
    align-items: flex-start;
    gap: 15px;
  }
  
  .produto-actions {
    align-self: stretch;
    justify-content: center;
  }
  
  .filtros-dcb {
    flex-direction: column;
    align-items: stretch;
  }
  
  .filtro-group {
    width: 100%;
  }
  
  .filtro-group input,
  .filtro-group select {
    min-width: auto;
    width: 100%;
  }
  
  .dcb-tabs {
    flex-wrap: wrap;
  }
  
  .dcb-tab {
    flex: 1;
    min-width: 120px;
    text-align: center;
  }
  
  .dcb-vencimento-card {
    flex-direction: column;
    align-items: flex-start;
    gap: 15px;
  }
  
  .dcb-actions {
    align-self: stretch;
    justify-content: center;
  }
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
 
 /* 🏷️ STATUS BADGES - FORÇAR ESTILOS */
 .status-badge {
   display: inline-block !important;
   padding: 5px 10px !important;
   border-radius: 20px !important;
   font-size: 12px !important;
   text-transform: uppercase !important;
   font-weight: bold !important;
   text-align: center !important;
   min-width: 80px !important;
 }
 
 .status-badge.status-aprovado {
   background-color: #2ecc71 !important;
   color: white !important;
 }
 
 .status-badge.status-pendente {
   background-color: #f39c12 !important;
   color: white !important;
 }
 
 .status-badge.status-reprovado {
   background-color: #e74c3c !important;
   color: white !important;
 }
 
 .status-badge.status-diligencia {
   background-color: #9b59b6 !important;
   color: white !important;
 }

 .status-badge.status-em_analise {
   background-color: #3498db !important;
   color: white !important;
 }
 
 .status-em_analise {
   background-color: #3498db;
   color: white;
}

/* ==========================================
   ESTILOS DOS EDITAIS DE PRÉ-QUALIFICAÇÃO
   ========================================== */

.editais-container {
  background: white;
  border-radius: 8px;
  padding: 25px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

/* Stats dos Editais */
.editais-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.editais-stats .stat-card {
  padding: 20px;
  border-radius: 8px;
  text-align: center;
  background: white;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border-left: 4px solid #3498db;
  transition: transform 0.3s ease;
}

.editais-stats .stat-card:hover {
  transform: translateY(-2px);
}

.editais-ativos {
  border-left-color: #2ecc71 !important;
}

.editais-rascunho {
  border-left-color: #f39c12 !important;
}

.editais-finalizados {
  border-left-color: #95a5a6 !important;
}

.participantes-total {
  border-left-color: #3498db !important;
}

/* Barra de Ações */
.editais-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  flex-wrap: wrap;
  gap: 15px;
}

.actions-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.actions-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.filtro-group {
  display: flex;
  flex-direction: column;
  min-width: 150px;
}

.filtro-group input,
.filtro-group select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

/* Grid de Editais */
.editais-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
}

.edital-card {
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
  position: relative;
}

.edital-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.edital-card.status-ativo {
  border-left: 4px solid #2ecc71;
}

.edital-card.status-rascunho {
  border-left: 4px solid #f39c12;
}

.edital-card.status-cancelado {
  border-left: 4px solid #95a5a6;
  opacity: 0.7;
}

.edital-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.edital-numero {
  font-size: 18px;
  font-weight: bold;
  color: #2c3e50;
}

.edital-status .badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.status-publicado {
  background-color: #2ecc71;
  color: white;
}

.status-rascunho {
  background-color: #f39c12;
  color: white;
}

.status-cancelado {
  background-color: #95a5a6;
  color: white;
}

.edital-content h4 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 16px;
  line-height: 1.4;
}

.edital-info p {
  margin: 5px 0;
  font-size: 13px;
  color: #6c757d;
}

.edital-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #e9ecef;
  gap: 8px;
}

.btn-info {
  background-color: #17a2b8;
  color: white;
}

.btn-info:hover {
  background-color: #138496;
}

/* Dropdown */
.dropdown {
  position: relative;
  display: inline-block;
}

.dropdown-toggle {
  background: #6c757d !important;
  color: white;
  border: none;
  padding: 6px 10px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
}

.dropdown-menu {
  display: none;
  position: absolute;
  right: 0;
  top: 100%;
  background: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  z-index: 1000;
  min-width: 150px;
}

.dropdown:hover .dropdown-menu {
  display: block;
}

.dropdown-menu a {
  display: block;
  padding: 8px 12px;
  color: #333;
  text-decoration: none;
  font-size: 13px;
  border-bottom: 1px solid #f8f9fa;
  cursor: pointer;
}

.dropdown-menu a:hover {
  background-color: #f8f9fa;
}

.dropdown-menu a.text-danger {
  color: #dc3545;
}

.dropdown-menu a.text-danger:hover {
  background-color: #f8d7da;
}

/* Loading State */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: #6c757d;
  }

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 15px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #6c757d;
}

.empty-icon {
  font-size: 64px;
  margin-bottom: 20px;
  opacity: 0.5;
}

.empty-state h3 {
  margin: 0 0 10px 0;
  color: #495057;
}

.empty-state p {
  margin: 10px 0 20px 0;
  color: #6c757d;
}

/* Modal Específico dos Editais */
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
  z-index: 9999;
}

.modal-content.large {
  width: 90%;
    max-width: 800px;
  max-height: 90vh;
    overflow-y: auto;
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
}

.modal-content.medium {
  width: 80%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
}

.modal-content.extra-large {
  width: 95%;
  max-width: 1200px;
  max-height: 90vh;
  overflow-y: auto;
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
}

.modal-header {
    display: flex;
  justify-content: space-between;
    align-items: center;
  padding: 20px 25px;
  border-bottom: 1px solid #e9ecef;
  background: #f8f9fa;
  border-radius: 8px 8px 0 0;
}

.modal-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 18px;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
    cursor: pointer;
  color: #6c757d;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s ease;
}

.btn-close:hover {
  background: #e9ecef;
  color: #495057;
}

.modal-body {
  padding: 25px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
    margin-bottom: 20px;
  }

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 600;
  color: #495057;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.3s, box-shadow 0.3s;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3498db;
  box-shadow: 0 0 5px rgba(52, 152, 219, 0.3);
}

.form-group small {
  display: block;
  margin-top: 5px;
  color: #6c757d;
  font-size: 12px;
}

.form-actions {
    display: flex;
    justify-content: flex-end;
  gap: 10px;
  padding-top: 20px;
  border-top: 1px solid #e9ecef;
}

/* Detalhes do Edital */
.edital-detalhes {
  max-height: 60vh;
  overflow-y: auto;
}

.info-section {
  margin-bottom: 25px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e9ecef;
}

.info-section:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

.info-section h4 {
  margin: 0 0 15px 0;
  color: #495057;
  font-size: 16px;
  font-weight: 600;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 15px;
}

.info-grid > div {
  padding: 10px;
  background: #f8f9fa;
  border-radius: 4px;
  border-left: 3px solid #3498db;
}

.conteudo-texto {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 4px;
  border-left: 3px solid #17a2b8;
  white-space: pre-wrap;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.4;
  max-height: 200px;
  overflow-y: auto;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
}

.mini-stat {
  text-align: center;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 6px;
  border-top: 3px solid #3498db;
}

.mini-stat-value {
  display: block;
  font-size: 24px;
  font-weight: bold;
  color: #2c3e50;
  margin-bottom: 5px;
}

.mini-stat-label {
  display: block;
  font-size: 12px;
  color: #6c757d;
  text-transform: uppercase;
  font-weight: 500;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding-top: 20px;
  border-top: 1px solid #e9ecef;
}

/* === ESTILOS PARA PARTICIPANTES === */
.participantes-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
  padding-bottom: 15px;
  border-bottom: 1px solid #e9ecef;
}

.filtros-participantes {
  display: flex;
  gap: 20px;
  align-items: center;
}

.filtro-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filtro-group label {
  font-size: 12px;
  font-weight: 600;
  color: #6c757d;
  text-transform: uppercase;
}

.filtro-group input,
.filtro-group select {
  padding: 8px 12px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 14px;
  min-width: 200px;
}

.participantes-lista {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.participante-card {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 20px;
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  transition: all 0.3s ease;
}

.participante-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transform: translateY(-2px);
}

.participante-info {
  flex: 1;
}

.participante-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.participante-header h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 16px;
  font-weight: 600;
}

.participante-details {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 10px;
}

.participante-details p {
  margin: 0;
  font-size: 14px;
  color: #495057;
}

.participante-details strong {
  color: #2c3e50;
}

.participante-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-left: 20px;
}

/* Status badges específicos para participantes */
.status-interessado {
  background: #17a2b8;
  color: white;
}

.status-documentacao {
  background: #ffc107;
  color: #212529;
}

.status-avaliacao {
  background: #fd7e14;
  color: white;
}



.status-desistente {
  background: #6c757d;
  color: white;
}

.btn-danger {
  background: linear-gradient(135deg, #dc3545, #c82333);
  color: white;
  border: 1px solid #bd2130;
}

.btn-danger:hover {
  background: linear-gradient(135deg, #c82333, #a71e2a);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(220, 53, 69, 0.3);
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px;
  color: #6c757d;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 15px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Responsividade */
@media (max-width: 768px) {
  .participantes-header {
    flex-direction: column;
    align-items: stretch;
    gap: 15px;
  }

  .filtros-participantes {
    flex-direction: column;
    gap: 15px;
  }

  .participante-card {
    flex-direction: column;
    gap: 15px;
  }

  .participante-actions {
    flex-direction: row;
    margin-left: 0;
  }

  .participante-details {
    grid-template-columns: 1fr;
  }

  .filtro-group input,
  .filtro-group select {
    min-width: auto;
  }

  .editais-grid {
    grid-template-columns: 1fr;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .editais-actions {
    flex-direction: column;
    align-items: stretch;
  }
  
  .actions-left,
  .actions-right {
    justify-content: center;
  }
  
  .modal-content.large {
    width: 95%;
    margin: 20px;
  }
  
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
}

/* Estilos de validação de formulário */
.form-text.text-warning {
  font-size: 12px;
  color: #856404;
  background: #fff3cd;
  padding: 5px 8px;
  border-radius: 4px;
  border-left: 3px solid #ffc107;
  margin-top: 5px;
  display: block;
}

.form-group input.error {
  border-color: #dc3545;
  box-shadow: 0 0 5px rgba(220, 53, 69, 0.3);
}

.form-group input:invalid {
  border-color: #dc3545;
}

.form-group input:valid {
  border-color: #28a745;
}

/* Estilos específicos do modal de edição */
.status-display {
  padding: 8px 0;
}

.status-display .badge {
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: bold;
  text-transform: uppercase;
}

.status-display .status-rascunho {
  background-color: #fff3cd;
  color: #856404;
}

.status-display .status-publicado {
  background-color: #d4edda;
  color: #155724;
}

.status-display .status-cancelado {
  background-color: #f8d7da;
  color: #721c24;
}

.help-text {
  color: #6c757d;
  font-size: 12px;
  margin-top: 4px;
}

.form-group input:disabled {
  background-color: #f8f9fa;
  color: #6c757d;
  cursor: not-allowed;
}

.spinner {
  width: 14px;
  height: 14px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Modal de participantes - CSS específico */
.modal-participantes-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999999;
}

.modal-participantes-content {
  background: white;
  border-radius: 12px;
  width: 95%;
  max-width: 1200px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 30px rgba(0,0,0,0.5);
}

.modal-participantes-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 25px;
  border-bottom: 1px solid #eee;
  background: #f8f9fa;
  border-radius: 12px 12px 0 0;
}

.modal-participantes-header h3 {
  margin: 0;
  color: #2c3e50;
}

.btn-close-participantes {
  background: none;
    border: none;
  font-size: 24px;
    cursor: pointer;
  color: #6c757d;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s;
}

.btn-close-participantes:hover {
  background: #e9ecef;
}

.modal-participantes-body {
  padding: 25px;
}

.modal-participantes-footer {
  padding: 20px 25px;
  border-top: 1px solid #eee;
    display: flex;
  justify-content: flex-end;
}

/* Modal de participantes com z-index adequado */
.modal-participantes-overlay {
  z-index: 999999 !important;
}

/* CORREÇÃO: SweetAlert customizado para número do edital */
/* Garantir que o SweetAlert apareça sempre por cima do modal de seleção de minuta */
.swal2-popup-edital {
  z-index: 99999 !important;
}

/* CORREÇÃO: SweetAlert customizado para conversão de PDF */
/* Garantir que o SweetAlert apareça sempre por cima do modal de visualização do edital */
.swal2-popup-converter-pdf {
  z-index: 99999 !important;
}

/* Garantir que o container do SweetAlert tenha z-index alto */
.swal2-container {
  z-index: 99999 !important;
}

/* CSS global para SweetAlert2 sempre aparecer por cima de qualquer modal */
::v-deep .swal2-container {
  z-index: 99999 !important;
}

::v-deep .swal2-popup {
  z-index: 100000 !important;
}

/* === ESTILOS PARA USUÁRIOS === */
.usuarios-section {
  padding: 20px;
}

.usuarios-container {
  margin-top: 20px;
}

.filtros-usuarios {
  display: flex;
  gap: 15px;
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.filtro-group {
  display: flex;
  flex-direction: column;
  min-width: 200px;
}

.filtro-group label {
  font-size: 12px;
    font-weight: bold;
  color: #495057;
  margin-bottom: 4px;
}

.filtro-group input,
.filtro-group select {
  padding: 8px 12px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 14px;
}

.usuarios-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
}

.usuario-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border: 1px solid #e9ecef;
  transition: transform 0.2s;
}

.usuario-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.usuario-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #e9ecef;
}

.status-badges {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 5px;
}

.usuario-header h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 16px;
}

.status-ativo {
  background: #28a745;
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: bold;
}

.usuario-details p {
  margin: 8px 0;
  font-size: 14px;
  color: #495057;
}

.data-rdm {
  font-weight: bold;
  color: #007bff;
}

.usuario-actions {
  display: flex;
  gap: 8px;
  margin-top: 15px;
  justify-content: flex-end;
}

.btn-info {
  background: linear-gradient(135deg, #17a2b8, #138496);
  color: white;
  border: 1px solid #117a8b;
}

.btn-info:hover {
  background: linear-gradient(135deg, #138496, #0f6674);
}

/* Materiais Section */
.materiais-section {
  margin: 20px 0;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.materiais-section h4 {
  margin-bottom: 15px;
  color: #2c3e50;
}

.materiais-lista {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.material-item {
  background: white;
  padding: 15px;
  border-radius: 6px;
  border: 1px solid #dee2e6;
}

.material-fields {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr auto;
  gap: 10px;
  align-items: center;
}

.material-fields input,
.material-fields select {
  padding: 8px 12px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 14px;
}

/* Novos estilos para sistema de materiais melhorado */
.material-fields-novo {
  display: flex;
  flex-direction: column;
  gap: 15px;
  position: relative;
}

.material-select {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.material-select label {
  font-weight: 600;
  color: #2c3e50;
  font-size: 14px;
}

.material-select select {
  padding: 10px 12px;
  border: 2px solid #e9ecef;
  border-radius: 6px;
  font-size: 14px;
  background: white;
  transition: border-color 0.3s;
}

.material-select select:focus {
  border-color: #007bff;
  outline: none;
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.novo-material {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 10px;
    padding: 10px;
  background: #fff3cd;
  border-radius: 6px;
  border: 1px solid #ffeaa7;
}

.novo-material input {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.material-periodo {
    display: flex;
  flex-direction: column;
  gap: 5px;
}

.material-periodo label {
  font-weight: 600;
  color: #2c3e50;
  font-size: 14px;
}

.material-periodo select {
  padding: 8px 12px;
  border: 2px solid #e9ecef;
  border-radius: 6px;
  font-size: 14px;
  background: white;
}

.material-actions {
  display: flex;
  gap: 10px;
  justify-content: space-between;
    align-items: center;
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #e9ecef;
}

.material-fields-novo .btn-danger {
  position: absolute;
  top: 0;
  right: 0;
  padding: 6px 10px;
  font-size: 12px;
}

.debug-info {
  margin-top: 10px;
  padding: 8px;
  background: #e9ecef;
  border-radius: 4px;
  text-align: center;
}

.debug-info small {
  color: #6c757d;
  font-size: 12px;
}

/* === ESTILOS PARA SISTEMA DE LOGIN === */
.login-system-section {
  margin: 20px 0;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.login-system-section h4 {
  margin-bottom: 15px;
  color: #2c3e50;
    display: flex;
    align-items: center;
  gap: 8px;
}

.checkbox-group {
  margin-bottom: 15px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-weight: 500;
  color: #2c3e50;
}

.checkbox-label input[type="checkbox"] {
  width: 18px;
  height: 18px;
  margin: 0;
}

.help-text {
  margin: 8px 0 0 28px;
  font-size: 14px;
  color: #6c757d;
  line-height: 1.4;
}

.convite-info {
  margin-top: 15px;
  padding: 15px;
  background: white;
  border-radius: 6px;
  border: 1px solid #28a745;
  border-left: 4px solid #28a745;
}

.info-card h5 {
  margin: 0 0 10px 0;
  color: #28a745;
  font-size: 16px;
}

.info-card p {
  margin: 8px 0;
  color: #495057;
  font-size: 14px;
}

.info-card ul {
  margin: 10px 0;
  padding-left: 20px;
}

.info-card li {
  margin: 5px 0;
  color: #495057;
  font-size: 14px;
}

.status-convite {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.status-convite.enviado {
  background: #d1ecf1;
  color: #0c5460;
}

.status-convite.aceito {
  background: #d4edda;
  color: #155724;
}

.status-convite.pendente {
  background: #fff3cd;
  color: #856404;
}

.btn-reenviar {
  background: linear-gradient(135deg, #ffc107, #e0a800);
  color: #212529;
  border: 1px solid #ffc107;
  font-size: 12px;
  padding: 4px 8px;
  margin-left: 8px;
}

.btn-reenviar:hover {
  background: linear-gradient(135deg, #e0a800, #d39e00);
}



/* === ESTILOS PARA AVALIAÇÕES === */
.filtros-avaliacoes {
  display: flex;
  gap: 15px;
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
  flex-wrap: wrap;
}

.avaliacoes-lista {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.avaliacao-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border: 1px solid #e9ecef;
  transition: transform 0.2s;
  border-left: 4px solid #ffd700;
}

.avaliacao-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.avaliacao-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #e9ecef;
}

.avaliacao-header h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 16px;
}

.rating-display {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rating-display .star {
  font-size: 18px;
  color: #ddd;
  transition: color 0.2s;
}

.rating-display .star.active {
  color: #ffd700;
  text-shadow: 0 0 2px rgba(255, 215, 0, 0.5);
}

.rating-text {
  font-weight: 600;
  color: #2c3e50;
  font-size: 14px;
  margin-left: 5px;
}

.avaliacao-content {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 20px;
  margin-bottom: 15px;
}

.avaliacao-info p {
  margin: 8px 0;
  font-size: 14px;
  color: #495057;
}

.avaliacao-detalhes {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.comentario-texto {
  padding: 12px;
  background: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #28a745;
}

.comentario-texto h5 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 14px;
}

.comentario-texto p {
  margin: 0;
  font-size: 13px;
  line-height: 1.5;
  color: #495057;
}

.sem-comentario {
  padding: 12px;
  background: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #6c757d;
  font-style: italic;
  color: #6c757d;
}

.sem-comentario p {
  margin: 0;
  font-size: 13px;
}

/* === ESTILOS PARA RESPOSTA DA CPM === */
.cpm-resposta {
  padding: 15px;
  background: #e8f4fd;
  border-radius: 6px;
  border-left: 4px solid #007bff;
  margin-top: 15px;
}

.cpm-resposta h5 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 14px;
  font-weight: 600;
}

.resposta-existente {
  background: #d4edda;
  padding: 12px;
  border-radius: 4px;
  border-left: 3px solid #28a745;
}

.resposta-existente p {
  margin: 0 0 8px 0;
  font-size: 13px;
  line-height: 1.5;
  color: #155724;
}

.data-resposta {
  font-size: 11px;
  color: #6c757d;
  font-style: italic;
}

.sem-resposta {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.textarea-resposta {
  width: 100%;
  padding: 10px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 13px;
  line-height: 1.5;
  resize: vertical;
  min-height: 80px;
}

.textarea-resposta:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.btn-small {
  padding: 6px 12px;
  font-size: 12px;
  border-radius: 4px;
  align-self: flex-start;
}

/* === RESPONSIVIDADE === */
@media (max-width: 768px) {
  .avaliacao-content {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .filtros-avaliacoes {
    flex-direction: column;
    gap: 10px;
  }
}

/* === ESTILOS PARA SISTEMA DE LEMBRETES === */
.lembretes-section {
  padding: 20px;
}

.section-controls {
  display: flex;
  gap: 15px;
  margin: 20px 0;
  align-items: center;
  flex-wrap: wrap;
}

.btn-success {
  background: linear-gradient(135deg, #28a745, #20c997);
  color: white;
  border: 1px solid #28a745;
    padding: 10px 20px;
  border-radius: 6px;
    cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
  }

.btn-success:disabled {
  background: #6c757d;
  border-color: #6c757d;
    cursor: not-allowed;
  opacity: 0.7;
}

.btn-warning {
  background: linear-gradient(135deg, #ffc107, #e0a800);
  color: #212529;
  border: 1px solid #ffc107;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
}

.btn-warning:disabled {
  background: #6c757d;
  border-color: #6c757d;
  color: white;
  cursor: not-allowed;
  opacity: 0.7;
}

.btn-info {
  background: linear-gradient(135deg, #17a2b8, #138496);
  color: white;
  border: 1px solid #17a2b8;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
}

.btn-success:hover:not(:disabled),
.btn-warning:hover:not(:disabled),
.btn-info:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.stats-detailed {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.stat-row {
    display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #e9ecef;
}

.stat-row:last-child {
  border-bottom: none;
}

.stat-row span {
  color: #495057;
  font-size: 14px;
}

.stat-row strong {
  color: #2c3e50;
  font-size: 16px;
  font-weight: 600;
}

.badge-normal {
  background: #28a745;
  color: white;
}

.badge-alta {
  background: #ffc107;
  color: #212529;
}

.badge-urgente {
  background: #dc3545;
  color: white;
}

.badge-recente {
  background: #17a2b8;
  color: white;
}

.badge {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.no-data-message {
  text-align: center;
  padding: 60px 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  margin: 20px 0;
}

.no-data-icon {
  font-size: 48px;
  margin-bottom: 20px;
}

.no-data-message h3 {
  color: #28a745;
    margin-bottom: 10px;
  font-size: 24px;
}

.no-data-message p {
  color: #6c757d;
  font-size: 16px;
}

.log-container {
  background: #f8f9fa;
  border-radius: 8px;
  max-height: 300px;
  overflow-y: auto;
  padding: 15px;
  font-family: 'Courier New', monospace;
  font-size: 13px;
}

.log-entry {
  display: flex;
  gap: 10px;
  margin-bottom: 8px;
  padding: 5px 0;
  border-bottom: 1px solid #e9ecef;
}

.log-entry:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.log-time {
  color: #6c757d;
  min-width: 130px;
  font-size: 12px;
}

.log-level {
  min-width: 60px;
  padding: 2px 6px;
  border-radius: 4px;
    font-weight: bold;
  font-size: 11px;
  text-align: center;
}

.log-info {
  background: #d1ecf1;
  color: #0c5460;
}

.log-success {
  background: #d4edda;
  color: #155724;
}

.log-error {
  background: #f8d7da;
  color: #721c24;
}

.log-message {
  flex: 1;
  color: #495057;
}

.table-container {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  margin: 20px 0;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th {
  background: #f8f9fa;
  color: #495057;
  font-weight: 600;
  padding: 15px;
  text-align: left;
  border-bottom: 2px solid #dee2e6;
  font-size: 14px;
}

.data-table td {
  padding: 12px 15px;
  border-bottom: 1px solid #e9ecef;
  color: #495057;
}

.data-table tbody tr:hover {
  background: #f8f9fa;
}

.data-table tbody tr:last-child td {
  border-bottom: none;
}

.stat-icon {
  font-size: 24px;
  margin-bottom: 10px;
}

.stat-content {
  text-align: center;
}

.stat-label {
  font-size: 14px;
  color: #6c757d;
  margin-top: 5px;
}

.section-content {
  margin: 30px 0;
}

.section-content h3 {
  color: #2c3e50;
  margin-bottom: 20px;
  font-size: 20px;
  font-weight: 600;
}

/* Responsividade */
@media (max-width: 768px) {
  .usuarios-grid {
    grid-template-columns: 1fr;
  }
  
  .filtros-usuarios {
    flex-direction: column;
  }
  
  .material-fields {
    grid-template-columns: 1fr;
    gap: 8px;
  }
  
  .usuario-actions {
    flex-direction: column;
    align-items: stretch;
  }
  
  .section-controls {
    flex-direction: column;
    align-items: stretch;
  }
  
  .section-controls button {
    width: 100%;
    margin-bottom: 10px;
  }
  
  .stats-container {
    flex-direction: column;
    gap: 15px;
  }
  
  .stat-card {
    margin: 0;
  }
  
  .data-table {
    font-size: 12px;
  }
  
  .data-table th,
  .data-table td {
    padding: 8px;
  }
}

/* === ESTILOS PARA PESQUISA DE MERCADO === */
.pesquisa-mercado-container {
  background: white;
  border-radius: 10px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.section-header {
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 2px solid #e9ecef;
}

.section-header h3 {
  color: #2c3e50;
  margin-bottom: 15px;
  font-size: 24px;
  font-weight: 600;
}

.section-header p {
  color: #6c757d;
  font-size: 16px;
  line-height: 1.6;
}

.sub-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 30px;
  border-bottom: 1px solid #e9ecef;
}

.sub-tab {
  padding: 12px 20px;
  cursor: pointer;
  font-weight: 500;
  border-bottom: 3px solid transparent;
  transition: all 0.3s ease;
  border-radius: 8px 8px 0 0;
  color: #6c757d;
}

.sub-tab:hover {
  background-color: #f8f9fa;
  color: #495057;
}

.sub-tab.active {
  border-bottom: 3px solid #667eea;
  color: #667eea;
  background-color: #f8f9ff;
}

.sub-content {
  min-height: 400px;
  padding: 20px 0;
}

.section-intro {
  margin-bottom: 30px;
  padding: 20px;
  background: linear-gradient(135deg, #f8f9ff 0%, #e9ecff 100%);
  border-radius: 10px;
  border-left: 4px solid #667eea;
}

.section-intro h4 {
  color: #2c3e50;
  margin-bottom: 10px;
  font-size: 20px;
}

.section-intro p {
  color: #6c757d;
  margin: 0;
  line-height: 1.6;
}

.pesquisa-bot-section {
  background: #f8f9fa;
  border-radius: 10px;
  padding: 20px;
  margin-top: 20px;
}

/* Cotações */
.cotacoes-actions {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
}

.cotacoes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.cotacao-card {
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 10px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.3s;
}

.cotacao-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.15);
}

.cotacao-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #e9ecef;
}

.cotacao-header h5 {
  color: #2c3e50;
  margin: 0;
  font-size: 16px;
  font-weight: 600;
}

.cotacao-data {
  color: #6c757d;
  font-size: 12px;
}

.cotacao-content p {
  margin: 8px 0;
  color: #495057;
}

.cotacao-actions {
  display: flex;
  gap: 10px;
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #e9ecef;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
  border: 1px solid #dc3545;
}

.btn-danger:hover {
  background-color: #c82333;
  border-color: #bd2130;
}

/* Comparativo */
.comparativo-actions {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
}

/* Análise de Preços */
.analise-actions {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
}

/* Relatórios */
.relatorios-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
}

.relatorio-card {
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 10px;
  padding: 25px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.3s;
}

.relatorio-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.15);
}

.relatorio-icon {
  font-size: 48px;
  margin-bottom: 15px;
}

.relatorio-card h5 {
  color: #2c3e50;
  margin-bottom: 10px;
  font-size: 18px;
  font-weight: 600;
}

.relatorio-card p {
  color: #6c757d;
  margin-bottom: 20px;
  line-height: 1.5;
}

/* Bancos de Preços */
.bancos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.banco-card {
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 10px;
  padding: 25px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.3s;
}

.banco-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.15);
}

.banco-icon {
  font-size: 48px;
  margin-bottom: 15px;
}

.banco-card h5 {
  color: #2c3e50;
  margin-bottom: 10px;
  font-size: 18px;
  font-weight: 600;
}

.banco-card p {
  color: #6c757d;
  margin-bottom: 20px;
  line-height: 1.5;
}

/* Estado vazio */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  background: #f8f9fa;
  border-radius: 10px;
  border: 2px dashed #dee2e6;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 20px;
  opacity: 0.5;
}

.empty-state h3 {
  color: #6c757d;
  margin-bottom: 10px;
  font-size: 20px;
}

.empty-state p {
  color: #6c757d;
  margin-bottom: 20px;
}

/* Em desenvolvimento */
.em-desenvolvimento {
  text-align: center;
  padding: 40px 20px;
  background: linear-gradient(135deg, #ffeaa7 0%, #fab1a0 100%);
  border-radius: 10px;
  margin-top: 20px;
}

.em-desenvolvimento span {
  display: block;
  font-size: 18px;
  font-weight: bold;
  color: #2d3436;
  margin-bottom: 10px;
}

.em-desenvolvimento p {
  color: #2d3436;
  margin: 0;
  opacity: 0.8;
}

/* Responsividade para Pesquisa de Mercado */
@media (max-width: 768px) {
  .sub-tabs {
    flex-direction: column;
    gap: 5px;
  }
  
  .sub-tab {
    text-align: center;
    border-radius: 8px;
    border-bottom: none;
    border-left: 3px solid transparent;
  }
  
  .sub-tab.active {
    border-bottom: none;
    border-left: 3px solid #667eea;
  }
  
  .cotacoes-actions,
  .comparativo-actions,
  .analise-actions {
    flex-direction: column;
  }
  
  .cotacoes-grid,
  .relatorios-grid,
  .bancos-grid {
    grid-template-columns: 1fr;
  }
  
  .cotacao-actions {
    flex-direction: column;
  }
  
  .section-intro {
    padding: 15px;
  }
  
  .section-intro h4 {
    font-size: 18px;
  }
}

/* === ESTILOS PARA RECLAMAÇÕES === */
.reclamacoes-section {
  padding: 20px;
}

.stats-reclamacoes {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  margin-bottom: 20px;
}

.stat-item {
  padding: 8px 16px;
  background: #f8f9fa;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  border: 1px solid #e9ecef;
}

.stat-item.pendentes {
  background: #fff3cd;
  color: #856404;
  border-color: #ffeaa7;
}

.stat-item.respondidas {
  background: #d4edda;
  color: #155724;
  border-color: #c3e6cb;
}

.filtros-reclamacoes {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  margin-bottom: 30px;
  padding: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.filtro-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filtro-group label {
  font-weight: 600;
  color: #495057;
  font-size: 14px;
}

.filtro-group input,
.filtro-group select {
  padding: 8px 12px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 14px;
}

.reclamacoes-lista {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.reclamacao-card {
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.reclamacao-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
  padding-bottom: 15px;
  border-bottom: 1px solid #e9ecef;
}

.reclamacao-info h4 {
  margin: 0 0 10px 0;
  color: #495057;
  font-size: 18px;
  font-weight: 600;
}

.reclamacao-meta {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
  font-size: 13px;
  color: #6c757d;
}

.reclamacao-badges {
  display: flex;
  flex-direction: column;
  gap: 5px;
  align-items: flex-end;
}

.status-badge,
.categoria-badge,
.prioridade-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: bold;
  text-transform: uppercase;
}

.status-pendente {
  background: #fff3cd;
  color: #856404;
}

.status-em-analise {
  background: #cce5ff;
  color: #004085;
}

.status-respondida {
  background: #d4edda;
  color: #155724;
}

.status-resolvida {
  background: #d1ecf1;
  color: #0c5460;
}

.categoria-badge {
  background: #e9ecef;
  color: #495057;
}

.prioridade-baixa {
  background: #d4edda;
  color: #155724;
}

.prioridade-normal {
  background: #e9ecef;
  color: #495057;
}

.prioridade-alta {
  background: #fff3cd;
  color: #856404;
}

.prioridade-critica {
  background: #f8d7da;
  color: #721c24;
}

.reclamacao-detalhes {
  margin-top: 15px;
}

.descricao-reclamacao h5 {
  color: #495057;
  margin: 0 0 10px 0;
  font-size: 14px;
  font-weight: 600;
}

.descricao-reclamacao p {
  color: #6c757d;
  line-height: 1.5;
  margin: 0 0 20px 0;
}

.cpm-acoes {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #007bff;
}

.acao-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.acao-group label {
  font-weight: 600;
  color: #495057;
  font-size: 13px;
}

.acao-group select {
  padding: 6px 10px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  font-size: 13px;
}

.cpm-resposta {
  margin-top: 20px;
}

.cmp-resposta h5 {
  color: #495057;
  margin: 0 0 15px 0;
  font-size: 14px;
  font-weight: 600;
}

.resposta-existente {
  background: #f8fff9;
  padding: 15px;
  border-radius: 6px;
  border-left: 4px solid #28a745;
  margin-bottom: 10px;
}

.resposta-existente p {
  margin: 0 0 10px 0;
  color: #495057;
  line-height: 1.5;
}

.data-resposta {
  font-size: 12px;
  color: #6c757d;
  font-style: italic;
}

.sem-resposta {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.textarea-resposta {
  width: 100%;
  padding: 12px;
  border: 1px solid #ced4da;
  border-radius: 6px;
  font-size: 14px;
  line-height: 1.5;
  resize: vertical;
  min-height: 100px;
}

.textarea-resposta:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.1);
}

.resposta-acoes {
  display: flex;
  gap: 10px;
}

.btn-small {
  padding: 8px 16px;
  font-size: 13px;
  border-radius: 4px;
  border: none;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

.btn-primary.btn-small {
  background: #007bff;
  color: white;
}

.btn-primary.btn-small:hover:not(:disabled) {
  background: #0056b3;
}

.btn-secondary.btn-small {
  background: #6c757d;
  color: white;
}

.btn-secondary.btn-small:hover {
  background: #5a6268;
}

.btn-small:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner-small {
  width: 14px;
  height: 14px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Responsividade para reclamações */
@media (max-width: 768px) {
  .filtros-reclamacoes {
    flex-direction: column;
    gap: 15px;
  }
  
  .stats-reclamacoes {
    flex-direction: column;
    gap: 10px;
  }
  
  .reclamacao-header {
    flex-direction: column;
    gap: 15px;
  }
  
  .reclamacao-badges {
    align-items: flex-start;
  }
  
  .cpm-acoes {
    flex-direction: column;
    gap: 15px;
  }
  
  .resposta-acoes {
    flex-direction: column;
  }
}

/* === BALÃOZINHO DE NOTIFICAÇÃO === */
.tab {
  position: relative;
}

.notification-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  background: #dc3545;
  color: white;
  border-radius: 50%;
  padding: 2px 6px;
  font-size: 11px;
  font-weight: bold;
  min-width: 18px;
  height: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 4px rgba(220, 53, 69, 0.3);
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.1);
  }
  100% {
    transform: scale(1);
  }
}

/* === CORREÇÕES DE OVERFLOW EM ANÁLISE/DOCUMENTOS === */
.produto-detalhes-modal {
  max-width: 900px !important;
  width: 90% !important;
  max-height: 90vh !important;
  overflow-y: auto !important;
}

.produto-detalhes-grid {
  max-width: 100%;
  overflow-x: auto;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.detalhes-section {
  max-width: 100%;
  word-wrap: break-word;
  overflow-wrap: break-word;
  overflow-x: auto;
}

.detalhes-section pre {
  max-width: 100%;
  overflow-x: auto;
  white-space: pre-wrap;
  word-wrap: break-word;
  background: #f8f9fa;
  padding: 10px;
  border-radius: 4px;
  border: 1px solid #e9ecef;
}

.detalhes-section p {
  word-wrap: break-word;
  overflow-wrap: break-word;
  max-width: 100%;
}

/* Documentos em lista (se houver) */
.documentos-lista {
  max-height: 300px;
  overflow-y: auto;
  padding: 10px;
  border: 1px solid #e9ecef;
  border-radius: 4px;
  margin-top: 10px;
  background: #f8f9fa;
}

.documento-item {
  padding: 8px 12px;
  border-bottom: 1px solid #e9ecef;
  word-wrap: break-word;
  overflow-wrap: break-word;
  background: white;
  margin-bottom: 5px;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.documento-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.documento-nome {
  font-weight: 600;
  color: #495057;
  margin-bottom: 4px;
}

.documento-info {
  font-size: 12px;
  color: #6c757d;
}

/* Modal body para melhor scroll */
.modal-body {
  max-height: calc(90vh - 140px);
  overflow-y: auto;
  padding: 20px;
}

/* Responsividade para documentos */
@media (max-width: 768px) {
  .produto-detalhes-grid {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .produto-detalhes-modal {
    width: 95% !important;
    margin: 10px;
  }
  
  .detalhes-section pre {
    font-size: 12px;
    padding: 8px;
  }
  
  .documentos-lista {
    max-height: 200px;
    padding: 8px;
  }
  
  .documento-item {
    padding: 6px 8px;
  }
}

/* Scroll customizado para documentos */
.documentos-lista::-webkit-scrollbar {
  width: 6px;
}

.documentos-lista::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.documentos-lista::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.documentos-lista::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style> 