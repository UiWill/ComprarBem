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
                <span v-if="produto.status === 'aprovado'" style="background-color: #2ecc71; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
                  {{ formatarStatus(produto.status) }}
                </span>
                <span v-else-if="produto.status === 'pendente'" style="background-color: #f39c12; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
                  {{ formatarStatus(produto.status) }}
                </span>
                <span v-else-if="produto.status === 'reprovado'" style="background-color: #e74c3c; color: white; display: inline-block; padding: 5px 10px; border-radius: 20px; font-size: 12px; text-transform: uppercase; font-weight: bold; min-width: 80px; text-align: center;">
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
      <div class="editais-container">
        <!-- Cabeçalho com Stats -->
        <div class="editais-stats">
          <div class="stat-card editais-ativos">
            <h4>📋 Editais Ativos</h4>
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
          <div class="stat-card participantes-total">
            <h4>👥 Participantes</h4>
            <div class="stat-value">{{ totalParticipantes }}</div>
            <small>Empresas interessadas</small>
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
                @input="aplicarFiltrosEditais"
              >
            </div>
            <div class="filtro-group">
              <select v-model="filtroEditais.status" @change="aplicarFiltrosEditais">
                <option value="">Todos os Status</option>
                <option value="RASCUNHO">📝 Rascunho</option>
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
                <span v-else-if="edital.status === 'RASCUNHO'" class="badge status-rascunho">✏️ Rascunho</span>
                <span v-else-if="edital.status === 'CANCELADO'" class="badge status-cancelado">❌ Cancelado</span>
              </div>
            </div>
            
            <div class="edital-content">
              <h4>{{ edital.descricao }}</h4>
              <div class="edital-info">
                <p><strong>📅 Publicação:</strong> {{ formatDate(edital.data_publicacao) }}</p>
                <p v-if="edital.data_limite_impugnacao">
                  <strong>⏰ Prazo Impugnação:</strong> {{ formatDate(edital.data_limite_impugnacao) }}
                </p>
                <p v-if="edital.participantes_count">
                  <strong>👥 Participantes:</strong> {{ edital.participantes_count }} empresas
                </p>
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
              <button 
                v-if="edital.status === 'PUBLICADO'" 
                @click="gerenciarParticipantes(edital)" 
                class="btn-info btn-small"
              >
                👥 Participantes
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

      <!-- Modal Novo Edital -->
      <div v-if="modalNovoEdital" class="modal-overlay" @click="fecharModalNovoEdital">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>{{ modoEdicaoEdital ? '✏️ Editar Edital' : '➕ Novo Edital de Pré-Qualificação' }}</h3>
            <button @click="fecharModalNovoEdital" class="btn-close">&times;</button>
          </div>
          
          <div class="modal-body">
            <form @submit.prevent="salvarEdital">
              <div class="form-row">
                <div class="form-group">
                  <label for="numero">Número do Edital*</label>
                  <input 
                    id="numero" 
                    v-model="editalAtual.numero" 
                    type="text" 
                    placeholder="Ex: 001/2024"
                    required
                  >
                  <small>Formato sugerido: 001/2024, 002/2024...</small>
                </div>
                <div class="form-group">
                  <label for="status">Status*</label>
                  <select id="status" v-model="editalAtual.status" required>
                    <option value="RASCUNHO">✏️ Rascunho</option>
                    <option value="PUBLICADO">📋 Publicado</option>
                  </select>
                </div>
              </div>

              <div class="form-group">
                <label for="descricao">Descrição/Objeto*</label>
                <textarea 
                  id="descricao" 
                  v-model="editalAtual.descricao" 
                  rows="3"
                  placeholder="Ex: Pré-qualificação técnica de medicamentos básicos para unidades de saúde"
                  required
                ></textarea>
              </div>

              <div class="form-group">
                <label for="conteudo">Conteúdo Detalhado</label>
                <textarea 
                  id="conteudo" 
                  v-model="editalAtual.conteudo" 
                  rows="6"
                  placeholder="Detalhes técnicos, especificações, critérios de avaliação..."
                ></textarea>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label for="data_publicacao">Data de Publicação</label>
                  <input 
                    id="data_publicacao" 
                    v-model="editalAtual.data_publicacao" 
                    type="datetime-local"
                  >
                </div>
                <div class="form-group">
                  <label for="data_limite_impugnacao">Prazo para Impugnações</label>
                  <input 
                    id="data_limite_impugnacao" 
                    v-model="editalAtual.data_limite_impugnacao" 
                    type="datetime-local"
                    :min="editalAtual.data_publicacao"
                    @change="validarDataLimite"
                  >
                  <small v-if="editalAtual.data_publicacao" class="form-text text-muted">
                    ⚠️ Deve ser posterior à data de publicação ({{ formatDate(editalAtual.data_publicacao) }})
                  </small>
                </div>
              </div>

              <div class="form-group">
                <label for="arquivo">Upload do Edital (PDF)</label>
                <input 
                  id="arquivo" 
                  type="file" 
                  accept=".pdf"
                  @change="handleFileUpload"
                >
                <small>Arquivo PDF com o edital completo (máximo 10MB)</small>
              </div>

              <div class="form-actions">
                <button type="button" @click="fecharModalNovoEdital" class="btn-secondary">
                  Cancelar
                </button>
                <button type="submit" class="btn-primary" :disabled="salvandoEdital">
                  {{ salvandoEdital ? 'Salvando...' : (modoEdicaoEdital ? 'Atualizar' : 'Criar Edital') }}
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
                  <div><strong>Data Publicação:</strong> {{ formatDate(editalSelecionado.data_publicacao) }}</div>
                  <div v-if="editalSelecionado.data_limite_impugnacao">
                    <strong>Prazo Impugnação:</strong> {{ formatDate(editalSelecionado.data_limite_impugnacao) }}
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
                    <span class="mini-stat-value">{{ editalSelecionado.participantes_count || 0 }}</span>
                    <span class="mini-stat-label">Participantes</span>
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
                v-if="editalSelecionado.url_documento" 
                @click="abrirDocumento(editalSelecionado.url_documento)"
                class="btn-primary"
              >
                📄 Abrir PDF
              </button>
              <button 
                v-if="editalSelecionado.url_documento" 
                @click="baixarDocumento(editalSelecionado)"
                class="btn-secondary"
              >
                📥 Baixar PDF
              </button>
              <button 
                v-if="editalSelecionado.status === 'RASCUNHO'" 
                @click="editarEditalSelecionado"
                class="btn-secondary"
              >
                ✏️ Editar
              </button>
              <button @click="fecharModalVisualizarEdital" class="btn-secondary">
                Fechar
              </button>
            </div>
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
            <h4>✅ DCBs Emitidos</h4>
            <div class="stat-value">{{ dcbsEmitidos.length }}</div>
            <small>Certificados válidos</small>
      </div>
          <div class="stat-card dcb-vencendo">
            <h4>⚠️ Vencendo</h4>
            <div class="stat-value">{{ dcbsVencendo.length }}</div>
            <small>Próximos 30 dias</small>
          </div>
          <div class="stat-card dcb-vencidos">
            <h4>🔴 Vencidos</h4>
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
            <p>Produtos aprovados pela CPM que ainda não possuem DCB emitido.</p>
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
            <h3>📋 Histórico de DCBs Emitidos</h3>
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
            <p>Monitoramento de DCBs próximos ao vencimento ou já vencidos.</p>
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
      editaisFiltrados: [],
      loadingEditais: false,
      modalNovoEdital: false,
      modalVisualizarEdital: false,
      modalParticipantes: false,
      modalNovoParticipante: false,
      modoEdicaoEdital: false,
      salvandoEdital: false,
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
      },

      // Computed properties para editais
      editaisAtivos() {
        return this.editais.filter(edital => edital.status === 'PUBLICADO')
      },
      
      editaisRascunho() {
        return this.editais.filter(edital => edital.status === 'RASCUNHO')
      },
      
      editaisFinalizados() {
        return this.editais.filter(edital => edital.status === 'CANCELADO')
      },
      
      totalParticipantes() {
        return this.editais.reduce((total, edital) => {
          return total + (edital.participantes_count || 0)
        }, 0)
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
        
        // Carregar dados DCB
        await this.carregarDadosDCB()
        
        // Carregar editais
        await this.carregarEditais()
        
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
      if (!dateString) return '-'
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
        switch(status) {
          case 'aprovado': return 'status-aprovado'
          case 'pendente': return 'status-pendente' 
          case 'reprovado': return 'status-reprovado'
          case 'diligencia': return 'status-diligencia'
          case 'em_analise': return 'status-em_analise'
          default: return `status-${status}`
        }
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
            // Criar URL de validação
            const urlValidacao = `${window.location.origin}/validar-dcb/${dcb.numero_dcb}`
            
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
        let editaisFiltrados = [...this.editais]

        if (this.filtroEditais.busca) {
          const busca = this.filtroEditais.busca.toLowerCase()
          editaisFiltrados = editaisFiltrados.filter(edital =>
            edital.numero.toLowerCase().includes(busca) ||
            edital.descricao.toLowerCase().includes(busca)
          )
        }

        if (this.filtroEditais.status) {
          editaisFiltrados = editaisFiltrados.filter(edital =>
            edital.status === this.filtroEditais.status
          )
        }

        this.editaisFiltrados = editaisFiltrados
      },

      abrirModalNovoEdital() {
        this.modoEdicaoEdital = false
        this.editalAtual = {
          id: null,
          numero: '',
          descricao: '',
          conteudo: '',
          status: 'RASCUNHO',
          data_publicacao: '',
          data_limite_impugnacao: '',
          url_documento: ''
        }
        this.modalNovoEdital = true
      },

      fecharModalNovoEdital() {
        this.modalNovoEdital = false
        this.modoEdicaoEdital = false
        this.editalAtual = {
          id: null,
          numero: '',
          descricao: '',
          conteudo: '',
          status: 'RASCUNHO',
          data_publicacao: '',
          data_limite_impugnacao: '',
          url_documento: '',
          nome_arquivo: ''
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
        this.modoEdicaoEdital = true
        this.editalAtual = {
          id: edital.id,
          numero: edital.numero,
          descricao: edital.descricao,
          conteudo: edital.conteudo || '',
          status: edital.status,
          data_publicacao: edital.data_publicacao ? new Date(edital.data_publicacao).toISOString().slice(0, 16) : '',
          data_limite_impugnacao: edital.data_limite_impugnacao ? new Date(edital.data_limite_impugnacao).toISOString().slice(0, 16) : '',
          url_documento: edital.url_documento || '',
          nome_arquivo: edital.nome_arquivo || ''
        }
        this.modalNovoEdital = true
      },

      editarEditalSelecionado() {
        this.fecharModalVisualizarEdital()
        this.editarEdital(this.editalSelecionado)
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
            const { error } = await supabase
              .from('participantes_editais')
              .update({ status: novoStatus })
              .eq('id', participanteId)

            if (error) throw error

            // Fechar modal e reabrir atualizado
            document.getElementById('modal-participantes-custom').remove()
            this.$swal.fire('Sucesso!', `Status alterado para ${this.getStatusText(novoStatus)}`, 'success')
            
            // Recarregar editais para atualizar contadores
            await this.carregarEditais()
            
            // Reabrir modal atualizado
            setTimeout(() => {
              this.criarModalParticipantes(edital)
            }, 500)

          } catch (error) {
            console.error('Erro ao alterar status:', error)
            this.$swal.fire('Erro', 'Erro ao alterar status do participante', 'error')
          }
        }

        // Adicionar função global para observações internas
        window.adicionarObservacaoInterna = async (participanteId) => {
          try {
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

              // Fechar modal e reabrir atualizado
              document.getElementById('modal-participantes-custom').remove()
              this.$swal.fire('Sucesso!', 'Observação interna adicionada com sucesso', 'success')
              
              // Reabrir modal atualizado
              setTimeout(() => {
                this.criarModalParticipantes(edital)
              }, 500)
            }

          } catch (error) {
            console.error('Erro ao adicionar observação:', error)
            this.$swal.fire('Erro', 'Erro ao adicionar observação interna', 'error')
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

      getStatusText(status) {
        const texts = {
          'INTERESSADO': 'Interessado',
          'DOCUMENTACAO_ENVIADA': 'Documentação Enviada',
          'EM_AVALIACAO': 'Em Avaliação',
          'APROVADO': 'Aprovado',
          'REPROVADO': 'Reprovado',
          'DESISTENTE': 'Desistente'
        }
        return texts[status] || status
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
        if (url && url !== 'uploads/documento-exemplo.pdf') {
          // Abrir documento real
          window.open(url, '_blank')
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

      formatarStatus(status) {
        const statusMap = {
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
          'INTERESSADO': 'status-interessado',
          'DOCUMENTACAO_ENVIADA': 'status-documentacao',
          'EM_AVALIACAO': 'status-avaliacao',
          'APROVADO': 'status-aprovado',
          'REPROVADO': 'status-reprovado',
          'DESISTENTE': 'status-desistente'
        }
        return classMap[status] || 'status-default'
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
  z-index: 1000;
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
</style> 