<template>
  <div class="catalogo-container">
    <div class="catalogo-header">
      <h2>Catálogo Eletrônico de Bens Padronizados</h2>
      <div class="export-buttons">
        <button @click="exportarCatalogoPDF" class="btn-exportar btn-resumido" :disabled="exportandoPDF">
          <span v-if="exportandoPDF && tipoExportacao === 'resumido'" class="spinner-small"></span>
          {{ (exportandoPDF && tipoExportacao === 'resumido') ? 'Gerando...' : '📄 Catálogo Legal' }}
        </button>
        <button @click="exportarCatalogoDetalhado" class="btn-exportar btn-detalhado" :disabled="exportandoPDF">
          <span v-if="exportandoPDF && tipoExportacao === 'detalhado'" class="spinner-small"></span>
          {{ (exportandoPDF && tipoExportacao === 'detalhado') ? 'Gerando...' : '📋 Catálogo Completo' }}
        </button>
      </div>
    </div>
    
    <div class="search-filters">
      <div class="search-box">
        <input 
          type="text" 
          v-model="searchTerm" 
          placeholder="Buscar produto..." 
          @input="filtrarProdutos"
        >
      </div>
      
      
      <div class="filters">
        <div class="categoria-filter">
          <label><strong>Grupo:</strong></label>
          <div class="dropdown">
            <button class="dropdown-toggle" 
                    type="button" 
                    @click="toggleCategoriaDropdown">
              {{ categoriaAtual }}
            </button>
            <div class="dropdown-menu" :class="{'show': showCategoriaDropdown}">
              <div v-if="carregandoCategorias" class="dropdown-item loading">
                <div class="spinner-border spinner-border-sm" role="status"></div>
                <span>Carregando...</span>
              </div>
              <template v-else>
                <a class="dropdown-item" @click="selecionarCategoria(null)">Todos os grupos</a>
                <div v-if="categorias.length === 0" class="dropdown-item empty">
                  Nenhum grupo disponível
                </div>
                <template v-else>
                  <a 
                    v-for="categoria in categorias" 
                    :key="categoria.id" 
                    class="dropdown-item" 
                    :class="{'active': categoria.id === filtroCategoria}"
                    @click="selecionarCategoria(categoria)">
                    {{ categoria.nome }}
                  </a>
                </template>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="produtos-grid" v-if="produtosFiltradosOrdenados.length > 0">
      <div 
        class="produto-card" 
        v-for="produto in produtosFiltradosOrdenados" 
        :key="produto.id"
        @click="verDetalhesProduto(produto.id)"
      >
        <div class="produto-info">
          <h3>{{ produto.nome }}</h3>
          <p><strong>Marca:</strong> {{ produto.marca }}</p>
          <div class="status-marca">
            <span class="status-badge" :class="getStatusMarcaClass(produto)">{{ getStatusMarca(produto) }}</span>
          </div>
          <p><strong>Modelo:</strong> {{ produto.modelo }}</p>
          <p><strong>Fabricante:</strong> {{ produto.fabricante }}</p>
        </div>
      </div>
    </div>
    
    <div class="empty-state" v-else>
      <p>Nenhum produto encontrado.</p>
    </div>
    
    
    <div class="produto-modal" v-if="produtoSelecionado" @click.self="fecharModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ produtoSelecionado.nome }}</h3>
          <button class="btn-close" @click="fecharModal">×</button>
        </div>
        <div class="modal-body">
          <div class="produto-detalhes">
            <p><strong>Marca:</strong> {{ produtoSelecionado.marca }}</p>
            <p><strong>Modelo:</strong> {{ produtoSelecionado.modelo }}</p>
            <p><strong>Fabricante:</strong> {{ produtoSelecionado.fabricante }}</p>
            <p><strong>CNPJ:</strong> {{ produtoSelecionado.cnpj }}</p>
            <p><strong>Código Material:</strong> {{ produtoSelecionado.codigo_material }}</p>
            <p v-if="produtoSelecionado.descricao"><strong>Descrição:</strong> {{ produtoSelecionado.descricao }}</p>
            
            <!-- Seção de Avaliações RDM -->
            <div class="avaliacoes-section">
              <div class="avaliacoes-header" @click="toggleAvaliacoes" :class="{ 'active': showAvaliacoes }">
                <h4>Avaliações de Desempenho (RDM)</h4>
                <div class="avaliacao-summary">
                  <div class="stars-container" v-if="avaliacaoMedia > 0">
                    <div class="stars">
                      <span v-for="n in 5" :key="n" class="star" :class="{ filled: avaliacaoMedia >= n, half: avaliacaoMedia >= n-0.5 && avaliacaoMedia < n }">★</span>
                    </div>
                    <span class="rating-number">{{ avaliacaoMedia }}</span>
                    <span class="rating-count">({{ avaliacoes.length }} avaliações)</span>
                  </div>
                  <div v-else class="no-ratings">
                    Sem avaliações ainda
                  </div>
                  <span class="toggle-icon">{{ showAvaliacoes ? '▲' : '▼' }}</span>
                </div>
              </div>
              
              <div class="avaliacoes-content" v-if="showAvaliacoes">
                <div v-if="avaliacoes.length === 0" class="no-avaliacoes">
                  Este produto ainda não possui avaliações de desempenho.
                </div>
                <div v-else class="avaliacoes-list">
                  <div v-for="(avaliacao, index) in avaliacoes" :key="index" class="avaliacao-item">
                    <div class="avaliacao-header">
                      <span class="avaliacao-tipo" :class="avaliacao.tipo.toLowerCase()">
                        {{ avaliacao.tipo }}
                      </span>
                      <div class="avaliacao-stars">
                        <span v-for="n in 5" :key="n" class="star" :class="{ filled: avaliacao.avaliacao >= n }">★</span>
                      </div>
                    </div>
                    <div class="avaliacao-comentario" v-if="avaliacao.comentario">
                      {{ avaliacao.comentario }}
                    </div>
                    <div class="avaliacao-footer">
                      <span class="avaliador">{{ avaliacao.avaliador }}</span>
                      <span class="avaliacao-data">{{ formatarData(avaliacao.data) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Abas para Avaliações e Reclamações -->
            <div class="tabs-container mt-4">
              <div class="tabs-header">
                <button 
                  class="tab-button" 
                  :class="{ active: activeTab === 'avaliacoes' }"
                  @click="setActiveTab('avaliacoes')">
                  <span>Avaliações de Usuários</span>
                  <div class="tab-info">
                    <span v-if="avaliacoes.length > 0" class="tab-badge">{{ avaliacoes.length }}</span>
                    <span class="toggle-icon">{{ (activeTab === 'avaliacoes' && showAvaliacoesContent) ? '▲' : '▼' }}</span>
                  </div>
                </button>
                <button 
                  class="tab-button" 
                  :class="{ active: activeTab === 'reclamacoes' }"
                  @click="setActiveTab('reclamacoes')">
                  <span>Reclamações de Usuários</span>
                  <div class="tab-info">
                    <span v-if="reclamacoes.length > 0" class="tab-badge">{{ reclamacoes.length }}</span>
                    <span class="toggle-icon">{{ (activeTab === 'reclamacoes' && showReclamacoesContent) ? '▲' : '▼' }}</span>
                  </div>
                </button>
              </div>
              
              <div class="tabs-content">
                <!-- Aba de Avaliações -->
                <div v-if="activeTab === 'avaliacoes'" class="tab-panel">
                  <div class="tab-header-toggle" @click="toggleAvaliacoesContent">
                    <h5>Lista de Avaliações</h5>
                    <span class="toggle-icon">{{ showAvaliacoesContent ? '▲' : '▼' }}</span>
                  </div>
                  
                  <div v-if="showAvaliacoesContent" class="tab-content-collapsible">
                    <div v-if="avaliacoes.length === 0" class="no-avaliacoes">
                      Este produto ainda não possui avaliações de desempenho.
                    </div>
                    <div v-else class="avaliacoes-list">
                      <div v-for="(avaliacao, index) in avaliacoes" :key="index" class="avaliacao-item">
                        <div class="avaliacao-header">
                          <span class="avaliacao-tipo" :class="avaliacao.tipo.toLowerCase()">
                            {{ avaliacao.tipo }}
                          </span>
                          <div class="avaliacao-stars">
                            <span v-for="n in 5" :key="n" class="star" :class="{ filled: avaliacao.avaliacao >= n }">★</span>
                          </div>
                        </div>
                        <div class="avaliacao-comentario" v-if="avaliacao.comentario">
                          {{ avaliacao.comentario }}
                        </div>
                        <div class="avaliacao-footer">
                          <span class="avaliador">{{ avaliacao.avaliador }}</span>
                          <span class="avaliacao-data">{{ formatarData(avaliacao.data) }}</span>
                        </div>
                        <!-- Campo para manifestação da CPM -->
                        <div v-if="avaliacao.ciencia_cpm || avaliacao.manifestacao_cpm" class="cpm-response">
                          <div class="cpm-header">
                            <h6>Manifestação da CPM</h6>
                          </div>
                          <div v-if="avaliacao.ciencia_cpm" class="cpm-ciencia">
                            <strong>Ciência:</strong> {{ formatarData(avaliacao.ciencia_cpm) }}
                          </div>
                          <div v-if="avaliacao.manifestacao_cpm" class="cpm-manifestacao">
                            <strong>Manifestação:</strong> {{ avaliacao.manifestacao_cpm }}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Aba de Reclamações -->
                <div v-if="activeTab === 'reclamacoes'" class="tab-panel">
                  <div class="tab-header-toggle" @click="toggleReclamacoesContent">
                    <h5>Lista de Reclamações</h5>
                    <span class="toggle-icon">{{ showReclamacoesContent ? '▲' : '▼' }}</span>
                  </div>
                  
                  <div v-if="showReclamacoesContent" class="tab-content-collapsible">
                    <div v-if="reclamacoes.length === 0" class="text-center text-muted py-3">
                      Nenhuma reclamação registrada
                    </div>
                    <div v-else class="reclamacoes-list">
                      <div v-for="reclamacao in reclamacoesSorted" :key="reclamacao.id" class="reclamacao-item">
                        <div class="reclamacao-header">
                          <div class="d-flex align-items-center">
                            <span class="badge" :class="getStatusBadgeClass(reclamacao.status)">{{ reclamacao.status }}</span>
                            <span class="reclamante-nome">{{ reclamacao.nome_reclamante }}</span>
                            <span class="reclamante-setor">{{ reclamacao.unidade_setor }}</span>
                          </div>
                          <span class="reclamacao-data">{{ formatDate(reclamacao.data_reclamacao) }}</span>
                        </div>
                        
                        <div class="reclamacao-content">
                          <div class="problema-box">
                            <h6 class="box-title">Problema Reportado:</h6>
                            <p class="box-text">{{ reclamacao.registro_reclamacao }}</p>
                          </div>
                          
                          <div v-if="reclamacao.sugestoes" class="sugestao-box">
                            <h6 class="box-title">Sugestões de Melhoria:</h6>
                            <p class="box-text">{{ reclamacao.sugestoes }}</p>
                          </div>

                          <div v-if="reclamacao.providencias_cpm" class="providencias-box">
                            <h6 class="box-title">Providências Tomadas:</h6>
                            <p class="box-text">{{ reclamacao.providencias_cpm }}</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Seção de Documentos e Padronização -->
            <div class="documentos-section">
              <h4>Documentos e Padronização</h4>
              
              <!-- Informações de Padronização/Despadronização -->
              <div class="padronizacao-info">
                <div class="info-row">
                  <div class="info-item">
                    <span class="info-label">Padronização:</span>
                    <span class="info-value">
                      {{ produtoSelecionado.edital_prequalificacao || 'Edital de Pré-Qualificação de Bens nº ______/____' }}
                    </span>
                    <button 
                      v-if="!produtoSelecionado.edital_prequalificacao" 
                      @click="abrirModalVincularEdital"
                      class="btn-action btn-vincular">
                      🔗 Vincular Edital
                    </button>
                  </div>
                </div>
                
                <div v-if="produtoSelecionado.processo_cancelamento" class="info-row">
                  <div class="info-item">
                    <span class="info-label">Despadronização:</span>
                    <span class="info-value">
                      {{ produtoSelecionado.processo_cancelamento || 'Processo de cancelamento da DCB nº _______/____' }}
                    </span>
                  </div>
                </div>
                
                <div class="info-row">
                  <div class="info-item">
                    <span class="info-label">Status Atual:</span>
                    <span class="status-badge" :class="getStatusMarcaClass(produtoSelecionado)">
                      {{ getStatusMarca(produtoSelecionado) }}
                    </span>
                    <button 
                      v-if="getStatusMarca(produtoSelecionado) === 'Em Vigor' && !produtoSelecionado.processo_cancelamento" 
                      @click="abrirModalDespadronizar"
                      class="btn-action btn-despadronizar">
                      ❌ Despadronizar
                    </button>
                  </div>
                </div>
                
                <div v-if="produtoSelecionado.validade_dcb" class="info-row">
                  <div class="info-item">
                    <span class="info-label">Validade DCB:</span>
                    <span class="info-value">
                      {{ formatarData(produtoSelecionado.validade_dcb) }}
                    </span>
                  </div>
                </div>
              </div>
              
              <!-- Lista de Documentos Anexos -->
              <div v-if="documentos.length > 0" class="documentos-anexos">
                <h5>Documentos Anexos</h5>
                <ul>
                  <li v-for="doc in documentos" :key="doc.id">
                    <a :href="doc.arquivo_url" target="_blank">{{ doc.nome }}</a>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Modal Vincular Edital -->
    <div class="modal-overlay" v-if="modalVincularEdital" @click="fecharModalVincularEdital">
      <div class="modal-content vincular-edital-modal" @click.stop>
        <div class="modal-header">
          <h3>Vincular Edital de Pré-Qualificação</h3>
          <button class="btn-close" @click="fecharModalVincularEdital">×</button>
        </div>
        <div class="modal-body">
          <div class="produto-info-display">
            <h4>Produto:</h4>
            <p><strong>{{ produtoSelecionado?.nome }}</strong> - {{ produtoSelecionado?.marca }} {{ produtoSelecionado?.modelo }}</p>
          </div>
          
          <form @submit.prevent="vincularEdital">
            <div class="form-group">
              <label for="editalSelect">Selecionar Edital Existente *</label>
              <select id="editalSelect" v-model="editalSelecionado" required>
                <option value="">Selecione um edital...</option>
                <option v-for="edital in editaisDisponiveis" :key="edital.id" :value="edital">
                  {{ edital.numero }} - {{ edital.descricao }}
                </option>
              </select>
            </div>
            
            <div v-if="editalSelecionado" class="edital-preview">
              <h5>Detalhes do Edital Selecionado:</h5>
              <p><strong>Número:</strong> {{ editalSelecionado.numero }}</p>
              <p><strong>Descrição:</strong> {{ editalSelecionado.descricao }}</p>
              <p v-if="editalSelecionado.data_publicacao"><strong>Data de Publicação:</strong> {{ formatarData(editalSelecionado.data_publicacao) }}</p>
              <p><strong>Status:</strong> {{ editalSelecionado.status }}</p>
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button type="button" @click="fecharModalVincularEdital" class="btn btn-secondary">
            Cancelar
          </button>
          <button type="button" @click="vincularEdital" class="btn btn-primary" :disabled="!editalSelecionado || salvandoVinculacao">
            <span v-if="salvandoVinculacao" class="spinner"></span>
            {{ salvandoVinculacao ? 'Vinculando...' : 'Vincular Edital' }}
          </button>
        </div>
      </div>
    </div>
    
    <!-- Modal Despadronizar Produto -->
    <div class="modal-overlay" v-if="modalDespadronizar" @click="fecharModalDespadronizar">
      <div class="modal-content despadronizar-modal" @click.stop>
        <div class="modal-header">
          <h3>Despadronizar Produto</h3>
          <button class="btn-close" @click="fecharModalDespadronizar">×</button>
        </div>
        <div class="modal-body">
          <div class="produto-info-display">
            <h4>Produto:</h4>
            <p><strong>{{ produtoSelecionado?.nome }}</strong> - {{ produtoSelecionado?.marca }} {{ produtoSelecionado?.modelo }}</p>
          </div>
          
          <div class="warning-message">
            <p><strong>⚠️ Atenção:</strong> Esta ação irá remover este produto da lista de itens padronizados.</p>
          </div>
          
          <form @submit.prevent="despadronizarProduto">
            <div class="form-group">
              <label for="numeroProcesso">Número do Processo de Cancelamento *</label>
              <input 
                id="numeroProcesso" 
                v-model="despadronizacao.numero_processo" 
                type="text" 
                required 
                placeholder="Ex: 2024/001"
              >
            </div>
            
            <div class="form-group">
              <label for="motivoDespadronizacao">Motivo da Despadronização *</label>
              <textarea 
                id="motivoDespadronizacao" 
                v-model="despadronizacao.motivo" 
                rows="4"
                required
                placeholder="Descreva detalhadamente o motivo da despadronização..."
              ></textarea>
            </div>
            
            <div class="form-group">
              <label for="documentoDespadronizacao">Documento Comprobatório *</label>
              <input 
                type="file" 
                id="documentoDespadronizacao"
                @change="handleFileUpload"
                accept=".pdf,.doc,.docx"
                required
              >
              <small class="file-info">Formatos aceitos: PDF, DOC, DOCX (máx. 10MB)</small>
            </div>
            
            <div class="form-group">
              <label for="dataDespadronizacao">Data de Vigência da Despadronização *</label>
              <input 
                id="dataDespadronizacao" 
                v-model="despadronizacao.data_vigencia" 
                type="date"
                required
              >
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button type="button" @click="fecharModalDespadronizar" class="btn btn-secondary">
            Cancelar
          </button>
          <button type="button" @click="despadronizarProduto" class="btn btn-danger" :disabled="!formularioDespadronizacaoValido || salvandoDespadronizacao">
            <span v-if="salvandoDespadronizacao" class="spinner"></span>
            {{ salvandoDespadronizacao ? 'Processando...' : 'Confirmar Despadronização' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { ref, onMounted, computed } from 'vue'

export default {
  name: 'CatalogoEletronico',
  data() {
    return {
      produtos: [],
      produtosFiltrados: [],
      categorias: [],
      searchTerm: '',
      filtroCategoria: '',
      categoriaAtual: 'Todos os grupos',
      showCategoriaDropdown: false,
      showAvaliacoes: false,
      showReclamacoes: false,
      activeTab: 'avaliacoes',
      showAvaliacoesContent: false,
      showReclamacoesContent: false,
      produtoSelecionado: null,
      documentos: [],
      avaliacoes: [],
      avaliacaoMedia: 0,
      carregandoCategorias: true,
      categoriaSelecionada: null,
      currentTenantId: null,
      loading: false,
      reclamacoes: ref([]),
      // Lista de produtos despadronizados
      produtosDespadronizados: [],
      // Modais para vincular edital e despadronizar
      modalVincularEdital: false,
      modalDespadronizar: false,
      editaisDisponiveis: [],
      editalSelecionado: null,
      salvandoVinculacao: false,
      salvandoDespadronizacao: false,
      despadronizacao: {
        numero_processo: '',
        motivo: '',
        data_vigencia: '',
        arquivo: null
      },
      // Exportação de PDF
      exportandoPDF: false,
      tipoExportacao: null
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarDados()
    })
    document.addEventListener('click', this.closeDropdownOnClickOutside)
  },
  mounted() {
    // Carregar categorias diretamente e garantir que o dropdown está fechado
    this.carregarCategoriasDireto()
    this.showCategoriaDropdown = false
  },
  beforeUnmount() {
    document.removeEventListener('click', this.closeDropdownOnClickOutside)
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
      console.log("Iniciando carregamento de dados")
      this.carregandoCategorias = true
      this.loading = true
      
      try {
        // Garantir que temos o tenant_id antes de continuar
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível. Tentando recarregar...')
          await this.obterTenantId()
          
          if (!this.currentTenantId) {
            console.error('Não foi possível obter o tenant_id, impossível carregar dados')
            this.$swal({
              icon: 'error',
              title: 'Erro ao carregar dados',
              text: 'Não foi possível identificar sua conta. Por favor, faça login novamente.'
            })
            return
          }
        }
        
        // Carregar categorias
        console.log("Buscando categorias do Supabase...")
        const { data: categorias, error: errorCategorias } = await supabase
          .from('categorias')
          .select('*')
          
        if (errorCategorias) {
          console.error('Erro ao carregar categorias:', errorCategorias)
        } else {
          this.categorias = categorias || []
          console.log(`${this.categorias.length} categorias carregadas`)
        }
        
        // Carregar produtos - apenas produtos pré-qualificados e padronizados
        console.log("Buscando produtos padronizados do Supabase...")
        let query = supabase
          .from('produtos')
          .select(`
            *,
            dcb_certificados!produto_id (
              numero_dcb,
              data_validade,
              status
            )
          `)
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['homologado', 'aprovado']) // Produtos homologados via tramitação ou aprovados
        
        const { data: produtos, error: errorProdutos } = await query
        
        if (errorProdutos) {
          console.error('Erro ao carregar produtos:', errorProdutos)
          this.produtos = []
        } else {
          // Processar produtos e mesclar informações de DCB
          let produtosProcessados = (produtos || []).map(produto => {
            // Prioridade 1: Usar DCB salvo diretamente no produto
            if (produto.numero_dcb && produto.validade_dcb) {
              console.log(`📋 DCB encontrado no produto: ${produto.nome} - ${produto.numero_dcb}`)
              return {
                ...produto,
                dcb_status: 'ativo' // Assumir ativo se está salvo no produto
              }
            }
            
            // Prioridade 2: Usar DCB da tabela dcb_certificados
            if (produto.dcb_certificados && produto.dcb_certificados.length > 0) {
              const dcb = produto.dcb_certificados[0] // Pegar o primeiro DCB ativo
              console.log(`📋 DCB encontrado na tabela: ${produto.nome} - ${dcb.numero_dcb}`)
              return {
                ...produto,
                numero_dcb: dcb.numero_dcb,
                validade_dcb: dcb.data_validade,
                dcb_status: dcb.status
              }
            }
            
            // Nenhum DCB encontrado
            console.log(`⏳ Aguardando DCB para: ${produto.nome}`)
            return produto
          })
          
          // Remover duplicatas priorizando homologados > aprovados com DCB > aprovados sem DCB
          const produtosUnicos = new Map()
          
          produtosProcessados.forEach(produto => {
            const chave = `${produto.nome}|${produto.marca || ''}|${produto.modelo || ''}|${produto.fabricante || ''}`
            const produtoExistente = produtosUnicos.get(chave)
            
            if (!produtoExistente) {
              // Primeiro produto com essa chave
              produtosUnicos.set(chave, produto)
            } else {
              // Decidir qual produto manter baseado na prioridade
              let manterExistente = true
              
              // Prioridade 1: Quem tem DCB sempre ganha (independente do status)
              const produtoTemDCB = !!(produto.numero_dcb && produto.validade_dcb)
              const existenteTemDCB = !!(produtoExistente.numero_dcb && produtoExistente.validade_dcb)
              
              if (produtoTemDCB && !existenteTemDCB) {
                manterExistente = false
                console.log(`🔄 Priorizando produto COM DCB: ${produto.nome} (${produto.status} com DCB ${produto.numero_dcb})`)
              }
              // Prioridade 2: Se ambos têm DCB ou ambos não têm, priorizar homologado
              else if (produtoTemDCB === existenteTemDCB) {
                if (produto.status === 'homologado' && produtoExistente.status === 'aprovado') {
                  manterExistente = false
                  console.log(`🔄 Priorizando produto homologado: ${produto.nome} (${produtoExistente.status} → ${produto.status})`)
                }
              }
              // Prioridade 3: Se existente tem DCB e novo não tem, manter existente
              else if (!produtoTemDCB && existenteTemDCB) {
                console.log(`✅ Mantendo produto COM DCB: ${produtoExistente.nome} (${produtoExistente.status} com DCB ${produtoExistente.numero_dcb})`)
              }
              
              if (!manterExistente) {
                produtosUnicos.set(chave, produto)
              }
            }
          })
          
          this.produtos = Array.from(produtosUnicos.values())
          
          console.log(`${this.produtos.length} produtos únicos carregados (${produtosProcessados.length - this.produtos.length} duplicatas removidas)`)
          console.log('Produtos homologados:', this.produtos.filter(p => p.status === 'homologado').length)
          console.log('Produtos aprovados:', this.produtos.filter(p => p.status === 'aprovado').length)
          console.log('Produtos com DCB:', this.produtos.filter(p => p.numero_dcb).length)
          console.log('Produtos aguardando DCB:', this.produtos.filter(p => p.status === 'aprovado' && !p.numero_dcb).length)
        }
        
        // Carregar produtos despadronizados
        await this.carregarProdutosDespadronizados()
        
        this.filtrarProdutos()
        
      } catch (error) {
        console.error('Erro no carregamento de dados:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro ao carregar dados',
          text: 'Ocorreu um erro ao carregar os dados. Tente novamente.'
        })
      } finally {
        this.carregandoCategorias = false
        this.loading = false
      }
    },
    
    async carregarProdutosDespadronizados() {
      try {
        console.log("Carregando produtos despadronizados...")
        const { data: marcasDespadronizadas, error } = await supabase
          .from('marcas_despadronizadas')
          .select('produto_id')
          .eq('tenant_id', this.currentTenantId)
          .eq('status_atual', 'ativa') // Apenas despadronizações ativas
        
        if (error) {
          console.error('Erro ao carregar produtos despadronizados:', error)
          this.produtosDespadronizados = []
        } else {
          this.produtosDespadronizados = (marcasDespadronizadas || [])
            .filter(item => item.produto_id) // Apenas aqueles com produto_id
            .map(item => item.produto_id)
          console.log(`${this.produtosDespadronizados.length} produtos despadronizados encontrados`)
        }
      } catch (error) {
        console.error('Erro ao carregar produtos despadronizados:', error)
        this.produtosDespadronizados = []
      }
    },
    
    async carregarCategoriasDireto() {
      try {
        console.log('Tentando carregar categorias diretamente...')
        const { data, error } = await supabase
          .from('categorias')
          .select('*')
        
        if (error) {
          console.error('Erro ao carregar categorias direto:', error)
          return
        }
        
        console.log('Resposta direta de categorias:', data)
        
        if (data && data.length > 0 && this.categorias.length === 0) {
          console.log('Atualizando categorias com dados diretos')
          this.categorias = data
        }
      } catch (e) {
        console.error('Exceção ao carregar categorias direto:', e)
      }
    },
    filtrarProdutos() {
      console.log('Filtrando produtos por:', this.filtroCategoria, 'e texto:', this.searchTerm)
      
      this.produtosFiltrados = this.produtos.filter(produto => {
        const matchCategoria = !this.filtroCategoria || produto.categoria_id === this.filtroCategoria
        const matchText = !this.searchTerm || 
                        produto.nome.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
                        (produto.descricao && produto.descricao.toLowerCase().includes(this.searchTerm.toLowerCase()))
        
        return matchCategoria && matchText
      })
      
      console.log('Produtos filtrados:', this.produtosFiltrados.length)
    },
    async verDetalhesProduto(id) {
      try {
        // Garantir que só podemos ver produtos do nosso tenant
        if (!this.currentTenantId) {
          console.error('Não foi possível identificar o tenant_id')
          return
        }
        
        // Buscar detalhes do produto (com filtro de tenant_id)
        const { data, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', id)
          .eq('tenant_id', this.currentTenantId) // Garantir que só vemos produtos do nosso tenant
          .single()
        
        if (error) {
          console.error('Erro ao carregar produto:', error)
          throw error
        }
        
        if (!data) {
          console.error('Produto não encontrado ou não pertence ao tenant atual')
          this.$swal({
            icon: 'error',
            title: 'Produto não encontrado',
            text: 'O produto solicitado não existe ou você não tem permissão para visualizá-lo.'
          })
          return
        }
        
        this.produtoSelecionado = data
        
        // Buscar documentos do produto
        const { data: docs, error: docsError } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', id)
          .eq('tenant_id', this.currentTenantId) // Filtrar documentos por tenant_id
        
        if (docsError) throw docsError
        
        this.documentos = docs || []

        // Buscar avaliações RDM do produto (tabelas existentes)
        // Buscar feedbacks dos usuários
        const feedbacksResponse = await supabase
          .from('material_feedbacks')
          .select('*')
          .eq('produto_id', id)

        // Tentar buscar feedbacks RDM com tratamento de erro
        let rdmFeedbacksResponse = { data: [], error: null }
        try {
          // Primeiro tentar com produto_id
          rdmFeedbacksResponse = await supabase
            .from('rdm_feedbacks')
            .select('*')
            .eq('produto_id', id)
        } catch (error) {
          // Se falhar, tentar estrutura alternativa
          console.warn('Erro na primeira tentativa de RDM feedbacks, tentando estrutura alternativa:', error.message)
          try {
            rdmFeedbacksResponse = await supabase
              .from('rdm_feedbacks') 
              .select('*')
              .eq('id', id)
          } catch (secondError) {
            console.warn('Tabela rdm_feedbacks não disponível ou sem estrutura compatível:', secondError.message)
            rdmFeedbacksResponse = { data: [], error: null }
          }
        }

        // Tratar erros se houver
        if (feedbacksResponse.error) {
          console.error('Erro ao carregar feedbacks:', feedbacksResponse.error);
        }
        if (rdmFeedbacksResponse.error && !rdmFeedbacksResponse.error.code?.includes('42')) {
          console.error('Erro ao carregar feedbacks RDM:', rdmFeedbacksResponse.error);
        }

        // Combinar as avaliações das duas tabelas existentes
        const feedbacksUsuarios = feedbacksResponse.data || [];
        const rdmFeedbacks = rdmFeedbacksResponse.data || [];

        // Formatar as avaliações para um formato uniforme
        this.avaliacoes = [
          ...feedbacksUsuarios.map(fb => ({
            id: fb.id,
            avaliacao: fb.rating || 0,
            comentario: fb.comentario,
            data: fb.data_feedback || fb.criado_em,
            tipo: 'Feedback',
            avaliador: 'Feedback de Usuário'
          })),
          ...rdmFeedbacks.map(rf => ({
            id: rf.id,
            avaliacao: rf.rating || 0,
            comentario: rf.comentario,
            data: rf.data_feedback || rf.criado_em,
            tipo: 'RDM',
            avaliador: 'Avaliação RDM'
          }))
        ];

        // Ordenar por data mais recente
        this.avaliacoes.sort((a, b) => new Date(b.data) - new Date(a.data));

        // Calcular média considerando todas as avaliações
        if (this.avaliacoes.length > 0) {
          const somaAvaliacoes = this.avaliacoes.reduce((soma, item) => soma + item.avaliacao, 0);
          this.avaliacaoMedia = parseFloat((somaAvaliacoes / this.avaliacoes.length).toFixed(1));
        } else {
          this.avaliacaoMedia = 0;
        }

        // Carregar reclamações
        await this.carregarReclamacoes()

      } catch (error) {
        console.error('Erro ao carregar detalhes do produto:', error);
        this.$swal({
          icon: 'error',
          title: 'Erro ao carregar detalhes',
          text: 'Não foi possível carregar os detalhes do produto. Tente novamente.'
        });
      }
    },
    fecharModal() {
      this.produtoSelecionado = null;
      this.documentos = [];
      this.avaliacoes = [];
      this.avaliacaoMedia = 0;
      this.showAvaliacoes = false; // Reset ao fechar modal
    },
    closeDropdownOnClickOutside(event) {
      // Método melhorado para fechar dropdown quando clica fora
      const dropdownEl = this.$el.querySelector('.dropdown')
      if (dropdownEl && !dropdownEl.contains(event.target)) {
        this.showCategoriaDropdown = false
      }
    },
    selecionarCategoria(categoria) {
      console.log('Categoria selecionada:', categoria)
      this.categoriaSelecionada = categoria
      this.categoriaAtual = categoria ? categoria.nome : 'Todos os grupos'
      this.filtroCategoria = categoria ? categoria.id : ''
      this.showCategoriaDropdown = false
      this.filtrarProdutos()
    },
    toggleCategoriaDropdown() {
      this.showCategoriaDropdown = !this.showCategoriaDropdown
    },
    toggleAvaliacoes() {
      this.showAvaliacoes = !this.showAvaliacoes;
    },
    toggleReclamacoes() {
      this.showReclamacoes = !this.showReclamacoes;
    },
    setActiveTab(tab) {
      this.activeTab = tab;
      // Abrir automaticamente o conteúdo quando seleciona a aba
      if (tab === 'avaliacoes') {
        this.showAvaliacoesContent = true;
        this.showReclamacoesContent = false;
      } else if (tab === 'reclamacoes') {
        this.showReclamacoesContent = true;
        this.showAvaliacoesContent = false;
      }
    },
    toggleAvaliacoesContent() {
      this.showAvaliacoesContent = !this.showAvaliacoesContent;
    },
    toggleReclamacoesContent() {
      this.showReclamacoesContent = !this.showReclamacoesContent;
    },
    formatarData(dataString) {
      if (!dataString) {
        // Se não houver data, verificar se há outro campo de data disponível
        return 'Data não disponível';
      }
      try {
        const data = new Date(dataString);
        return data.toLocaleDateString('pt-BR', { 
          day: '2-digit', 
          month: '2-digit', 
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        });
      } catch (e) {
        console.error('Erro ao formatar data:', e);
        return 'Data inválida';
      }
    },
    async carregarReclamacoes() {
      try {
        if (!this.produtoSelecionado?.codigo_material) {
          console.log('Código do material não encontrado no produto');
          return;
        }

        console.log('Buscando reclamações para o código de material:', this.produtoSelecionado.codigo_material);

        const { data, error } = await supabase
          .from('reclamacoes_usuarios')
          .select('*')
          .eq('codigo_material', this.produtoSelecionado.codigo_material)
          .order('data_reclamacao', { ascending: false });

        if (error) {
          console.error('Erro ao carregar reclamações:', error);
          throw error;
        }

        console.log(`Reclamações encontradas: ${data?.length || 0}`, data);
        
        this.reclamacoes = data || [];
      } catch (error) {
        console.error('Erro ao carregar reclamações:', error);
        this.reclamacoes = [];
      }
    },
    formatDate(date) {
      if (!date) return ''
      return new Date(date).toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    getStatusBadgeClass(status) {
      const classes = {
        'ABERTA': 'badge-warning',
        'EM_ANALISE': 'badge-info',
        'RESOLVIDA': 'badge-success',
        'REJEITADA': 'badge-danger'
      }
      return classes[status] || 'badge-secondary'
    },
    getTipoAvaliacao(avaliacao) {
      if (avaliacao.tipo === 'RDM') return 'RDM'
      if (avaliacao.tipo === 'FEEDBACK') return 'Feedback'
      return 'Avaliação'
    },
    getDocumentName(url) {
      if (!url) return ''
      const parts = url.split('/')
      return parts[parts.length - 1]
    },
    
    getStatusMarca(produto) {
      // Verificar se produto está despadronizado
      if (this.produtosDespadronizados.includes(produto.id)) {
        return 'Despadronizado'
      }
      
      // Se não tem DCB emitido ainda, está aguardando DCB
      if (!produto.validade_dcb) {
        return 'Aguardando DCB'
      }
      
      const hoje = new Date()
      const validade = new Date(produto.validade_dcb)
      
      if (validade < hoje) {
        return 'Vencido'
      } else {
        return 'Em Vigor'
      }
    },
    
    getStatusMarcaClass(produto) {
      const status = this.getStatusMarca(produto)
      switch(status) {
        case 'Em Vigor':
          return 'status-em-vigor'
        case 'Vencido':
          return 'status-vencido'
        case 'Despadronizado':
          return 'status-despadronizado'
        case 'Aguardando DCB':
          return 'status-aguardando-dcb'
        default:
          return 'status-despadronizado'
      }
    },
    
    
    // Métodos para vincular edital
    async abrirModalVincularEdital() {
      this.modalVincularEdital = true
      await this.carregarEditaisDisponiveis()
    },
    
    fecharModalVincularEdital() {
      this.modalVincularEdital = false
      this.editalSelecionado = null
      this.editaisDisponiveis = []
    },
    
    async carregarEditaisDisponiveis() {
      try {
        console.log('Carregando editais para tenant:', this.currentTenantId)
        
        const { data, error } = await supabase
          .from('editais')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'PUBLICADO')
          .order('data_publicacao', { ascending: false })
        
        if (error) {
          console.error('Erro detalhado ao carregar editais:', error)
          throw error
        }
        
        console.log('Editais encontrados:', data)
        this.editaisDisponiveis = data || []
        
        if (this.editaisDisponiveis.length === 0) {
          this.$swal({
            icon: 'info',
            title: 'Nenhum edital encontrado',
            text: 'Não há editais publicados disponíveis para vinculação. Verifique se existem editais com status "PUBLICADO" para este órgão.'
          })
        }
      } catch (error) {
        console.error('Erro ao carregar editais:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: `Não foi possível carregar os editais disponíveis: ${error.message}`
        })
      }
    },
    
    async vincularEdital() {
      if (!this.editalSelecionado) return
      
      this.salvandoVinculacao = true
      
      try {
        const editalInfo = `Edital de Pré-Qualificação de Bens nº ${this.editalSelecionado.numero}`
        
        const { error } = await supabase
          .from('produtos')
          .update({
            edital_prequalificacao: editalInfo,
            edital_id: this.editalSelecionado.id,
            updated_at: new Date().toISOString()
          })
          .eq('id', this.produtoSelecionado.id)
          .eq('tenant_id', this.currentTenantId)
        
        if (error) throw error
        
        // Atualizar o produto selecionado
        this.produtoSelecionado.edital_prequalificacao = editalInfo
        this.produtoSelecionado.edital_id = this.editalSelecionado.id
        
        this.$swal({
          icon: 'success',
          title: 'Sucesso!',
          text: 'Edital vinculado com sucesso!',
          timer: 2000,
          showConfirmButton: false
        })
        
        this.fecharModalVincularEdital()
        
      } catch (error) {
        console.error('Erro ao vincular edital:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível vincular o edital. Tente novamente.'
        })
      } finally {
        this.salvandoVinculacao = false
      }
    },
    
    // Métodos para despadronizar
    abrirModalDespadronizar() {
      this.modalDespadronizar = true
      this.despadronizacao = {
        numero_processo: '',
        motivo: '',
        data_vigencia: '',
        arquivo: null
      }
    },
    
    fecharModalDespadronizar() {
      this.modalDespadronizar = false
      this.despadronizacao = {
        numero_processo: '',
        motivo: '',
        data_vigencia: '',
        arquivo: null
      }
    },
    
    handleFileUpload(event) {
      const file = event.target.files[0]
      if (file) {
        // Validar tamanho do arquivo (10MB)
        if (file.size > 10 * 1024 * 1024) {
          this.$swal({
            icon: 'error',
            title: 'Arquivo muito grande',
            text: 'O arquivo deve ter no máximo 10MB.'
          })
          event.target.value = ''
          return
        }
        
        this.despadronizacao.arquivo = file
      }
    },
    
    async despadronizarProduto() {
      if (!this.formularioDespadronizacaoValido) return
      
      this.salvandoDespadronizacao = true
      
      try {
        // 1. Upload do documento se houver
        let documentoUrl = null
        if (this.despadronizacao.arquivo) {
          const fileName = `despadronizacao_${this.produtoSelecionado.id}_${Date.now()}_${this.despadronizacao.arquivo.name}`
          
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('documentos')
            .upload(fileName, this.despadronizacao.arquivo)
          
          if (uploadError) throw uploadError
          
          // Obter URL público do arquivo
          const { data: { publicUrl } } = supabase.storage
            .from('documentos')
            .getPublicUrl(fileName)
          
          documentoUrl = publicUrl
        }
        
        // 2. Atualizar o produto
        const processoInfo = `Processo de cancelamento da DCB nº ${this.despadronizacao.numero_processo}`
        
        const { error } = await supabase
          .from('produtos')
          .update({
            processo_cancelamento: processoInfo,
            motivo_despadronizacao: this.despadronizacao.motivo,
            data_despadronizacao: this.despadronizacao.data_vigencia,
            documento_despadronizacao: documentoUrl,
            status: 'despadronizado',
            updated_at: new Date().toISOString()
          })
          .eq('id', this.produtoSelecionado.id)
          .eq('tenant_id', this.currentTenantId)
        
        if (error) throw error
        
        // 3. Atualizar o produto selecionado
        this.produtoSelecionado.processo_cancelamento = processoInfo
        this.produtoSelecionado.motivo_despadronizacao = this.despadronizacao.motivo
        this.produtoSelecionado.data_despadronizacao = this.despadronizacao.data_vigencia
        this.produtoSelecionado.documento_despadronizacao = documentoUrl
        this.produtoSelecionado.status = 'despadronizado'
        
        this.$swal({
          icon: 'success',
          title: 'Produto Despadronizado',
          text: 'O produto foi despadronizado com sucesso!',
          timer: 3000,
          showConfirmButton: false
        })
        
        this.fecharModalDespadronizar()
        
      } catch (error) {
        console.error('Erro ao despadronizar produto:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível despadronizar o produto. Tente novamente.'
        })
      } finally {
        this.salvandoDespadronizacao = false
      }
    },
    
    // Exportar Catálogo em PDF conforme Lei 14.133/2021
    async exportarCatalogoPDF() {
      this.exportandoPDF = true
      this.tipoExportacao = 'resumido'
      
      try {
        // Obter dados do tenant/órgão
        const { data: tenantData } = await supabase
          .from('tenants')
          .select('nome')
          .eq('id', this.currentTenantId)
          .single()
        
        const nomeOrgao = tenantData?.nome || 'Órgão Público'
        
        // Buscar todos os produtos padronizados e despadronizados
        const { data: produtosPadronizados } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['aprovado', 'julgado_aprovado', 'homologado'])
          .order('nome')
        
        // Buscar produtos despadronizados
        const { data: produtosDespadronizados } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'despadronizado')
          .order('nome')
        
        // Criar estrutura do PDF
        const dadosCatalogo = {
          orgao: nomeOrgao,
          dataGeracao: new Date().toLocaleDateString('pt-BR'),
          produtosPadronizados: produtosPadronizados || [],
          produtosDespadronizados: produtosDespadronizados || []
        }
        
        this.gerarPDFCatalogo(dadosCatalogo)
        
      } catch (error) {
        console.error('Erro ao exportar catálogo:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro na Exportação',
          text: 'Não foi possível gerar o catálogo em PDF. Tente novamente.'
        })
      } finally {
        this.exportandoPDF = false
        this.tipoExportacao = null
      }
    },
    
    gerarPDFCatalogo(dados) {
      // Criar documento HTML para impressão
      const htmlContent = this.criarHTMLCatalogo(dados)
      
      // Criar janela de impressão
      const printWindow = window.open('', '_blank')
      printWindow.document.write(htmlContent)
      printWindow.document.close()
      
      // Aguardar carregamento e imprimir
      printWindow.onload = () => {
        printWindow.print()
        printWindow.close()
      }
    },
    
    criarHTMLCatalogo(dados) {
      const totalItens = dados.produtosPadronizados.length + dados.produtosDespadronizados.length
      
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Catálogo de Bens - ${dados.orgao}</title>
          <style>
            @page { 
              margin: 20mm; 
              size: A4;
            }
            body {
              font-family: Arial, sans-serif;
              font-size: 12px;
              line-height: 1.4;
              color: #333;
              margin: 0;
              padding: 0;
            }
            .cabecalho {
              text-align: center;
              margin-bottom: 30px;
              padding-bottom: 20px;
              border-bottom: 2px solid #2c3e50;
            }
            .cabecalho h1 {
              color: #2c3e50;
              font-size: 20px;
              margin: 0 0 10px 0;
              font-weight: bold;
            }
            .cabecalho h2 {
              color: #666;
              font-size: 16px;
              margin: 0 0 15px 0;
              font-weight: normal;
            }
            .info-legal {
              background-color: #f8f9fa;
              padding: 15px;
              border-left: 4px solid #007bff;
              margin: 20px 0;
              font-size: 11px;
            }
            .secao {
              margin-bottom: 30px;
            }
            .secao h3 {
              background-color: #2c3e50;
              color: white;
              padding: 10px;
              margin: 0 0 15px 0;
              font-size: 14px;
              font-weight: bold;
            }
            table {
              width: 100%;
              border-collapse: collapse;
              margin-bottom: 20px;
            }
            th, td {
              border: 1px solid #ddd;
              padding: 8px;
              text-align: left;
              vertical-align: top;
            }
            th {
              background-color: #f8f9fa;
              font-weight: bold;
              font-size: 11px;
            }
            td {
              font-size: 10px;
            }
            .status-padronizado {
              color: #28a745;
              font-weight: bold;
            }
            .status-despadronizado {
              color: #dc3545;
              font-weight: bold;
            }
            .rodape {
              margin-top: 40px;
              padding-top: 20px;
              border-top: 1px solid #ddd;
              text-align: center;
              font-size: 10px;
              color: #666;
            }
            .estatisticas {
              display: flex;
              justify-content: space-around;
              margin: 20px 0;
              background-color: #f8f9fa;
              padding: 15px;
              border-radius: 5px;
            }
            .estatistica {
              text-align: center;
            }
            .estatistica .numero {
              font-size: 18px;
              font-weight: bold;
              color: #2c3e50;
            }
            .estatistica .label {
              font-size: 11px;
              color: #666;
            }
          </style>
        </head>
        <body>
          <div class="cabecalho">
            <h1>CATÁLOGO DE BENS PADRONIZADOS E DESPADRONIZADOS</h1>
            <h2>${dados.orgao}</h2>
            <p><strong>Data de Geração:</strong> ${dados.dataGeracao}</p>
          </div>
          
          <div class="info-legal">
            <strong>Base Legal:</strong> Catálogo elaborado em conformidade com o art. 15 da Lei nº 14.133/2021 
            (Nova Lei de Licitações e Contratos Administrativos), que estabelece a obrigatoriedade de 
            manutenção de catálogo de bens padronizados pelos órgãos públicos.
          </div>
          
          <div class="estatisticas">
            <div class="estatistica">
              <div class="numero">${dados.produtosPadronizados.length}</div>
              <div class="label">Bens Padronizados</div>
            </div>
            <div class="estatistica">
              <div class="numero">${dados.produtosDespadronizados.length}</div>
              <div class="label">Bens Despadronizados</div>
            </div>
            <div class="estatistica">
              <div class="numero">${totalItens}</div>
              <div class="label">Total de Itens</div>
            </div>
          </div>
          
          ${dados.produtosPadronizados.length > 0 ? `
          <div class="secao">
            <h3>📋 BENS PADRONIZADOS</h3>
            <table>
              <thead>
                <tr>
                  <th style="width: 15%">Código</th>
                  <th style="width: 40%">Especificação</th>
                  <th style="width: 20%">Marca</th>
                  <th style="width: 15%">Modelo</th>
                  <th style="width: 10%">Status</th>
                </tr>
              </thead>
              <tbody>
                ${dados.produtosPadronizados.map(produto => `
                  <tr>
                    <td><strong>${produto.codigo_material || produto.codigo || 'N/A'}</strong></td>
                    <td>${produto.nome || 'N/A'}<br><small>${produto.descricao || ''}</small></td>
                    <td>${produto.marca || 'N/A'}</td>
                    <td>${produto.modelo || 'N/A'}</td>
                    <td><span class="status-padronizado">PADRONIZADO</span></td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          ` : ''}
          
          ${dados.produtosDespadronizados.length > 0 ? `
          <div class="secao">
            <h3>❌ BENS DESPADRONIZADOS</h3>
            <table>
              <thead>
                <tr>
                  <th style="width: 12%">Código</th>
                  <th style="width: 30%">Especificação</th>
                  <th style="width: 15%">Marca</th>
                  <th style="width: 12%">Modelo</th>
                  <th style="width: 10%">Status</th>
                  <th style="width: 21%">Motivo da Despadronização</th>
                </tr>
              </thead>
              <tbody>
                ${dados.produtosDespadronizados.map(produto => `
                  <tr>
                    <td><strong>${produto.codigo_material || produto.codigo || 'N/A'}</strong></td>
                    <td>${produto.nome || 'N/A'}<br><small>${produto.descricao || ''}</small></td>
                    <td>${produto.marca || 'N/A'}</td>
                    <td>${produto.modelo || 'N/A'}</td>
                    <td><span class="status-despadronizado">DESPADRONIZADO</span></td>
                    <td><small>${produto.motivo_despadronizacao || 'Não informado'}</small></td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          ` : ''}
          
          <div class="rodape">
            <p><strong>Catálogo gerado automaticamente pelo Sistema Comprar Bem</strong></p>
            <p>Este documento possui validade legal conforme Lei nº 14.133/2021</p>
            <p>Data e hora de geração: ${new Date().toLocaleString('pt-BR')}</p>
          </div>
        </body>
        </html>
      `
    },
    
    // Exportar Catálogo Detalhado com todas as informações
    async exportarCatalogoDetalhado() {
      this.exportandoPDF = true
      this.tipoExportacao = 'detalhado'
      
      try {
        // Obter dados do tenant/órgão
        const { data: tenantData } = await supabase
          .from('tenants')
          .select('nome')
          .eq('id', this.currentTenantId)
          .single()
        
        const nomeOrgao = tenantData?.nome || 'Órgão Público'
        
        // Buscar todos os produtos com mais detalhes
        const { data: produtosPadronizados } = await supabase
          .from('produtos')
          .select(`
            *,
            categorias:categoria_id(nome)
          `)
          .eq('tenant_id', this.currentTenantId)
          .in('status', ['aprovado', 'julgado_aprovado', 'homologado'])
          .order('nome')
        
        // Buscar produtos despadronizados com detalhes
        const { data: produtosDespadronizados } = await supabase
          .from('produtos')
          .select(`
            *,
            categorias:categoria_id(nome)
          `)
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'despadronizado')
          .order('nome')
        
        // Buscar marcas despadronizadas para detalhes adicionais
        const { data: marcasDespadronizadas } = await supabase
          .from('marcas_despadronizadas')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .eq('status_atual', 'ativa')
        
        // Criar estrutura do PDF detalhado
        const dadosCatalogo = {
          orgao: nomeOrgao,
          dataGeracao: new Date().toLocaleDateString('pt-BR'),
          produtosPadronizados: produtosPadronizados || [],
          produtosDespadronizados: produtosDespadronizados || [],
          marcasDespadronizadas: marcasDespadronizadas || []
        }
        
        this.gerarPDFCatalogoDetalhado(dadosCatalogo)
        
      } catch (error) {
        console.error('Erro ao exportar catálogo detalhado:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro na Exportação',
          text: 'Não foi possível gerar o catálogo detalhado em PDF. Tente novamente.'
        })
      } finally {
        this.exportandoPDF = false
        this.tipoExportacao = null
      }
    },
    
    gerarPDFCatalogoDetalhado(dados) {
      // Criar documento HTML para impressão
      const htmlContent = this.criarHTMLCatalogoDetalhado(dados)
      
      // Criar janela de impressão
      const printWindow = window.open('', '_blank')
      printWindow.document.write(htmlContent)
      printWindow.document.close()
      
      // Aguardar carregamento e imprimir
      printWindow.onload = () => {
        printWindow.print()
        printWindow.close()
      }
    },
    
    criarHTMLCatalogoDetalhado(dados) {
      const totalItens = dados.produtosPadronizados.length + dados.produtosDespadronizados.length
      
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Catálogo Completo de Bens - ${dados.orgao}</title>
          <style>
            @page { 
              margin: 15mm; 
              size: A4;
            }
            body {
              font-family: Arial, sans-serif;
              font-size: 11px;
              line-height: 1.3;
              color: #333;
              margin: 0;
              padding: 0;
            }
            .cabecalho {
              text-align: center;
              margin-bottom: 25px;
              padding-bottom: 15px;
              border-bottom: 2px solid #2c3e50;
            }
            .cabecalho h1 {
              color: #2c3e50;
              font-size: 18px;
              margin: 0 0 8px 0;
              font-weight: bold;
            }
            .cabecalho h2 {
              color: #666;
              font-size: 14px;
              margin: 0 0 10px 0;
              font-weight: normal;
            }
            .info-legal {
              background-color: #f8f9fa;
              padding: 12px;
              border-left: 4px solid #007bff;
              margin: 15px 0;
              font-size: 10px;
            }
            .secao {
              margin-bottom: 25px;
              page-break-inside: avoid;
            }
            .secao h3 {
              background-color: #2c3e50;
              color: white;
              padding: 8px;
              margin: 0 0 12px 0;
              font-size: 13px;
              font-weight: bold;
            }
            table {
              width: 100%;
              border-collapse: collapse;
              margin-bottom: 15px;
              font-size: 9px;
            }
            th, td {
              border: 1px solid #ddd;
              padding: 6px;
              text-align: left;
              vertical-align: top;
            }
            th {
              background-color: #f8f9fa;
              font-weight: bold;
              font-size: 9px;
            }
            .status-padronizado {
              color: #28a745;
              font-weight: bold;
            }
            .status-despadronizado {
              color: #dc3545;
              font-weight: bold;
            }
            .rodape {
              margin-top: 30px;
              padding-top: 15px;
              border-top: 1px solid #ddd;
              text-align: center;
              font-size: 9px;
              color: #666;
            }
            .estatisticas {
              display: flex;
              justify-content: space-around;
              margin: 15px 0;
              background-color: #f8f9fa;
              padding: 12px;
              border-radius: 5px;
            }
            .estatistica {
              text-align: center;
            }
            .estatistica .numero {
              font-size: 16px;
              font-weight: bold;
              color: #2c3e50;
            }
            .estatistica .label {
              font-size: 10px;
              color: #666;
            }
            .detalhes-adicionais {
              font-size: 8px;
              color: #666;
              background-color: #f9f9f9;
              padding: 4px;
            }
          </style>
        </head>
        <body>
          <div class="cabecalho">
            <h1>CATÁLOGO COMPLETO DE BENS PADRONIZADOS E DESPADRONIZADOS</h1>
            <h2>${dados.orgao}</h2>
            <p><strong>Data de Geração:</strong> ${dados.dataGeracao} | <strong>Tipo:</strong> Relatório Detalhado</p>
          </div>
          
          <div class="info-legal">
            <strong>Base Legal:</strong> Catálogo elaborado em conformidade com o art. 15 da Lei nº 14.133/2021. 
            Este relatório contém informações detalhadas para gestão interna e controle administrativo.
          </div>
          
          <div class="estatisticas">
            <div class="estatistica">
              <div class="numero">${dados.produtosPadronizados.length}</div>
              <div class="label">Bens Padronizados</div>
            </div>
            <div class="estatistica">
              <div class="numero">${dados.produtosDespadronizados.length}</div>
              <div class="label">Bens Despadronizados</div>
            </div>
            <div class="estatistica">
              <div class="numero">${totalItens}</div>
              <div class="label">Total de Itens</div>
            </div>
          </div>
          
          ${dados.produtosPadronizados.length > 0 ? `
          <div class="secao">
            <h3>📋 BENS PADRONIZADOS - INFORMAÇÕES COMPLETAS</h3>
            <table>
              <thead>
                <tr>
                  <th style="width: 10%">Código</th>
                  <th style="width: 25%">Especificação</th>
                  <th style="width: 12%">Marca</th>
                  <th style="width: 10%">Modelo</th>
                  <th style="width: 12%">Fabricante</th>
                  <th style="width: 8%">Categoria</th>
                  <th style="width: 8%">Status</th>
                  <th style="width: 15%">Detalhes Técnicos</th>
                </tr>
              </thead>
              <tbody>
                ${dados.produtosPadronizados.map(produto => `
                  <tr>
                    <td><strong>${produto.codigo_material || produto.codigo || 'N/A'}</strong></td>
                    <td>
                      <strong>${produto.nome || 'N/A'}</strong>
                      ${produto.descricao ? `<br><small>${produto.descricao}</small>` : ''}
                    </td>
                    <td>${produto.marca || 'N/A'}</td>
                    <td>${produto.modelo || 'N/A'}</td>
                    <td>${produto.fabricante || 'N/A'}</td>
                    <td>${produto.categorias?.nome || 'N/A'}</td>
                    <td><span class="status-padronizado">PADRONIZADO</span></td>
                    <td class="detalhes-adicionais">
                      ${produto.cnpj ? `<strong>CNPJ:</strong> ${produto.cnpj}<br>` : ''}
                      ${produto.data_aprovacao ? `<strong>Aprovado:</strong> ${new Date(produto.data_aprovacao).toLocaleDateString('pt-BR')}<br>` : ''}
                      ${produto.validade_dcb ? `<strong>DCB válido até:</strong> ${new Date(produto.validade_dcb).toLocaleDateString('pt-BR')}<br>` : ''}
                      ${produto.edital_prequalificacao ? `<strong>Edital:</strong> ${produto.edital_prequalificacao}` : ''}
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          ` : ''}
          
          ${dados.produtosDespadronizados.length > 0 ? `
          <div class="secao">
            <h3>❌ BENS DESPADRONIZADOS - INFORMAÇÕES COMPLETAS</h3>
            <table>
              <thead>
                <tr>
                  <th style="width: 10%">Código</th>
                  <th style="width: 20%">Especificação</th>
                  <th style="width: 12%">Marca</th>
                  <th style="width: 10%">Modelo</th>
                  <th style="width: 12%">Fabricante</th>
                  <th style="width: 8%">Status</th>
                  <th style="width: 15%">Motivo Despadronização</th>
                  <th style="width: 13%">Detalhes Processo</th>
                </tr>
              </thead>
              <tbody>
                ${dados.produtosDespadronizados.map(produto => `
                  <tr>
                    <td><strong>${produto.codigo_material || produto.codigo || 'N/A'}</strong></td>
                    <td>
                      <strong>${produto.nome || 'N/A'}</strong>
                      ${produto.descricao ? `<br><small>${produto.descricao}</small>` : ''}
                    </td>
                    <td>${produto.marca || 'N/A'}</td>
                    <td>${produto.modelo || 'N/A'}</td>
                    <td>${produto.fabricante || 'N/A'}</td>
                    <td><span class="status-despadronizado">DESPADRONIZADO</span></td>
                    <td><small>${produto.motivo_despadronizacao || 'Não informado'}</small></td>
                    <td class="detalhes-adicionais">
                      ${produto.processo_cancelamento ? `<strong>Processo:</strong> ${produto.processo_cancelamento}<br>` : ''}
                      ${produto.data_despadronizacao ? `<strong>Data:</strong> ${new Date(produto.data_despadronizacao).toLocaleDateString('pt-BR')}<br>` : ''}
                      ${produto.cnpj ? `<strong>CNPJ:</strong> ${produto.cnpj}` : ''}
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          ` : ''}
          
          <div class="rodape">
            <p><strong>Catálogo Detalhado gerado automaticamente pelo Sistema Comprar Bem</strong></p>
            <p>Este documento contém informações completas para gestão interna e controle administrativo</p>
            <p>Data e hora de geração: ${new Date().toLocaleString('pt-BR')}</p>
          </div>
        </body>
        </html>
      `
    }
  },
  computed: {
    avaliacoesSorted() {
      return [...this.avaliacoes].sort((a, b) => {
        const dateA = new Date(a.data)
        const dateB = new Date(b.data)
        return dateB - dateA
      })
    },
    reclamacoesSorted() {
      return [...this.reclamacoes].sort((a, b) => {
        return new Date(b.data_reclamacao) - new Date(a.data_reclamacao)
      })
    },
    averageRating() {
      if (!this.avaliacoes.length) return 0
      const sum = this.avaliacoes.reduce((acc, curr) => acc + (curr.avaliacao || 0), 0)
      return (sum / this.avaliacoes.length).toFixed(1)
    },
    produtosFiltradosOrdenados() {
      return [...this.produtosFiltrados].sort((a, b) => {
        return a.nome.localeCompare(b.nome, 'pt-BR', { sensitivity: 'base' })
      })
    },
    formularioDespadronizacaoValido() {
      return this.despadronizacao.numero_processo && 
             this.despadronizacao.motivo && 
             this.despadronizacao.data_vigencia && 
             this.despadronizacao.arquivo
    }
  }
}
</script>

<style scoped>
.catalogo-container {
  padding: 20px;
}

.catalogo-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.catalogo-header h2 {
  margin: 0;
  color: #2c3e50;
}

.export-buttons {
  display: flex;
  gap: 10px;
}

.btn-exportar {
  border: none;
  padding: 10px 18px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  white-space: nowrap;
}

.btn-resumido {
  background-color: #007bff;
  color: white;
}

.btn-resumido:hover:not(:disabled) {
  background-color: #0056b3;
  transform: translateY(-1px);
}

.btn-detalhado {
  background-color: #28a745;
  color: white;
}

.btn-detalhado:hover:not(:disabled) {
  background-color: #218838;
  transform: translateY(-1px);
}

.btn-exportar:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
  transform: none;
}

.spinner-small {
  width: 14px;
  height: 14px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.search-filters {
  display: flex;
  margin-bottom: 20px;
  gap: 15px;
}

.search-box {
  flex: 2;
}

.filters {
  flex: 1;
  position: relative;
}

.categoria-filter {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.dropdown {
  position: relative;
  display: inline-block;
  width: 100%;
}

.dropdown-toggle {
  width: 100%;
  padding: 10px 12px;
  background-color: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  text-align: left;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  position: relative;
}

.dropdown-toggle::after {
  content: '';
  display: inline-block;
  margin-left: 0.255em;
  vertical-align: 0.255em;
  border-top: 0.3em solid;
  border-right: 0.3em solid transparent;
  border-bottom: 0;
  border-left: 0.3em solid transparent;
}

.dropdown-toggle:hover {
  border-color: #2c3e50;
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  z-index: 1000;
  display: none;
  width: 100%;
  padding: 0.5rem 0;
  margin: 0.125rem 0 0;
  font-size: 14px;
  color: #212529;
  text-align: left;
  list-style: none;
  background-color: #fff;
  background-clip: padding-box;
  border: 1px solid rgba(0, 0, 0, 0.15);
  border-radius: 0.25rem;
  box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.175);
}

.dropdown-menu.show {
  display: block;
}

.dropdown-item {
  display: block;
  width: 100%;
  padding: 0.5rem 1rem;
  clear: both;
  font-weight: 400;
  color: #212529;
  text-align: inherit;
  white-space: nowrap;
  background-color: transparent;
  border: 0;
  cursor: pointer;
}

.dropdown-item:hover, .dropdown-item:focus {
  color: #16181b;
  text-decoration: none;
  background-color: #f8f9fa;
}

.dropdown-item.active, .dropdown-item:active {
  color: #fff;
  text-decoration: none;
  background-color: #2c3e50;
}

.dropdown-item.loading {
  display: flex;
  align-items: center;
  gap: 8px;
}

.dropdown-item.empty {
  color: #6c757d;
  cursor: default;
}

.spinner-border {
  display: inline-block;
  width: 1rem;
  height: 1rem;
  vertical-align: text-bottom;
  border: 0.15em solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: spinner-border 0.75s linear infinite;
}

@keyframes spinner-border {
  to { transform: rotate(360deg); }
}

.search-box input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.search-box input:focus {
  outline: none;
  border-color: #2c3e50;
}

.produtos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.produto-card {
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.produto-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  border-color: #2c3e50;
}

.produto-info h3 {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-size: 18px;
  font-weight: 600;
}

.produto-info p {
  margin: 8px 0;
  color: #666;
  font-size: 14px;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #666;
}

.produto-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
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
  border-bottom: 1px solid #eee;
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
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  color: #2c3e50;
}

.modal-body {
  padding: 20px;
}

.produto-detalhes p {
  margin: 12px 0;
  color: #666;
}

.avaliacoes-section {
  margin-top: 20px;
  border-top: 1px solid #eee;
  padding-top: 20px;
}

.avaliacoes-header {
  cursor: pointer;
  padding: 10px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.avaliacoes-header:hover {
  background-color: #f8f9fa;
}

.avaliacoes-header h4 {
  margin: 0;
  color: #2c3e50;
}

.avaliacao-summary {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 5px;
}

.stars-container {
  display: flex;
  align-items: center;
  gap: 5px;
}

.stars {
  display: flex;
}

.star {
  color: #ddd;
  font-size: 18px;
}

.star.filled {
  color: #ffc107;
}

.star.half {
  color: #ffc107;
}

.rating-number {
  font-weight: bold;
  color: #2c3e50;
}

.rating-count {
  color: #666;
  font-size: 12px;
}

.no-ratings {
  color: #666;
  font-style: italic;
}

.toggle-icon {
  color: #666;
  font-size: 12px;
  margin-left: auto;
}

.avaliacoes-content {
  padding: 15px 0;
}

.no-avaliacoes {
  color: #666;
  font-style: italic;
  text-align: center;
  padding: 20px;
}

.avaliacoes-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.avaliacao-item {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 4px;
  border-left: 3px solid #2c3e50;
}

.avaliacao-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.avaliacao-tipo {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: bold;
}

.avaliacao-tipo.rdm {
  background-color: #e3f2fd;
  color: #1976d2;
}

.avaliacao-tipo.feedback {
  background-color: #f3e5f5;
  color: #7b1fa2;
}

.avaliacao-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 10px;
  font-size: 12px;
  color: #666;
}

.avaliador {
  font-weight: 500;
}

/* Seção de Documentos e Padronização */
.documentos-section {
  margin-top: 20px;
  border-top: 1px solid #eee;
  padding-top: 20px;
}

.documentos-section h4 {
  margin-bottom: 15px;
  color: #2c3e50;
  font-weight: 600;
}

.padronizacao-info {
  background-color: #f8f9fa;
  border-radius: 6px;
  padding: 15px;
  margin-bottom: 20px;
  border-left: 4px solid #2c3e50;
}

.info-row {
  margin-bottom: 12px;
}

.info-row:last-child {
  margin-bottom: 0;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.info-label {
  font-weight: 600;
  color: #495057;
  min-width: 120px;
}

.info-value {
  color: #2c3e50;
  flex: 1;
}

.documentos-anexos {
  margin-top: 15px;
}

.documentos-anexos h5 {
  margin-bottom: 10px;
  color: #2c3e50;
  font-weight: 600;
  font-size: 16px;
}

.documentos-anexos ul {
  list-style: none;
  padding: 0;
}

.documentos-anexos li {
  margin-bottom: 8px;
}

.documentos-anexos a {
  color: #3498db;
  text-decoration: none;
  padding: 5px 10px;
  border: 1px solid #3498db;
  border-radius: 4px;
  display: inline-block;
  transition: all 0.3s;
}

.documentos-anexos a:hover {
  background-color: #3498db;
  color: white;
}

.reclamacoes-section {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.section-header {
  cursor: pointer;
  padding: 15px 20px;
  background-color: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  transition: all 0.2s ease;
}

.section-header:hover {
  background-color: #e9ecef;
}

.section-header h5 {
  color: #2c3e50;
  font-weight: 600;
}

.toggle-icon {
  font-size: 12px;
  color: #6c757d;
  transition: transform 0.2s;
}

.reclamacoes-content {
  padding: 20px;
  border: 1px solid #e9ecef;
  border-top: none;
  border-bottom-left-radius: 8px;
  border-bottom-right-radius: 8px;
}

.reclamacao-item {
  background-color: white;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 15px;
  transition: transform 0.2s;
}

.reclamacao-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.reclamacao-item:last-child {
  margin-bottom: 0;
}

.reclamacao-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.reclamante-nome {
  font-weight: 600;
  color: #2c3e50;
  margin: 0 10px;
}

.reclamante-setor {
  color: #6c757d;
  font-size: 0.9em;
}

.reclamacao-data {
  color: #6c757d;
  font-size: 0.9em;
}

.reclamacao-content {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.problema-box,
.sugestao-box,
.providencias-box {
  background-color: #f8f9fa;
  border-radius: 6px;
  padding: 12px 15px;
}

.box-title {
  color: #495057;
  font-size: 0.9em;
  font-weight: 600;
  margin-bottom: 8px;
}

.box-text {
  color: #2c3e50;
  margin: 0;
  line-height: 1.5;
}

.providencias-box {
  border-left: 3px solid #28a745;
  background-color: #f8fff9;
}

.badge {
  padding: 5px 10px;
  font-weight: 500;
  border-radius: 4px;
}

.badge-warning { 
  background-color: #fff3cd; 
  color: #856404; 
}

.badge-info { 
  background-color: #cce5ff; 
  color: #004085; 
}

.badge-success { 
  background-color: #d4edda; 
  color: #155724; 
}

.badge-danger { 
  background-color: #f8d7da; 
  color: #721c24; 
}

/* Estilos para Status das Marcas */
.status-marca {
  margin: 8px 0;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: bold;
  text-transform: uppercase;
}

.status-em-vigor {
  background-color: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.status-vencido {
  background-color: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.status-despadronizado {
  background-color: #fff3cd;
  color: #856404;
  border: 1px solid #ffeaa7;
}

.status-aguardando-dcb {
  background-color: #e2e3e5;
  color: #495057;
  border: 1px solid #ced4da;
}

/* Estilos para Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 600;
  color: #2c3e50;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.3s ease;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #2c3e50;
  box-shadow: 0 0 0 2px rgba(44, 62, 80, 0.1);
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

.btn-secondary {
  background-color: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background-color: #5a6268;
}

.btn-primary {
  background-color: #007bff;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #0056b3;
}

.btn:disabled {
  opacity: 0.6;
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

/* Botões de Ação */
.btn-action {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 500;
  transition: all 0.3s ease;
  margin-left: 10px;
}

.btn-vincular {
  background-color: #17a2b8;
  color: white;
}

.btn-vincular:hover {
  background-color: #138496;
  transform: translateY(-1px);
}

.btn-despadronizar {
  background-color: #dc3545;
  color: white;
}

.btn-despadronizar:hover {
  background-color: #c82333;
  transform: translateY(-1px);
}

/* Modais específicos */
.vincular-edital-modal,
.despadronizar-modal {
  max-width: 600px;
  width: 95%;
}

.edital-preview {
  background-color: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 4px;
  padding: 15px;
  margin-top: 15px;
}

.edital-preview h5 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 14px;
}

.edital-preview p {
  margin: 5px 0;
  color: #495057;
  font-size: 13px;
}

.warning-message {
  background-color: #fff3cd;
  border: 1px solid #ffeaa7;
  border-radius: 4px;
  padding: 12px;
  margin-bottom: 20px;
}

.warning-message p {
  margin: 0;
  color: #856404;
}

.file-info {
  display: block;
  margin-top: 5px;
  color: #6c757d;
  font-size: 12px;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background-color: #c82333;
}

/* Produto info display nos modais */
.produto-info-display {
  background-color: #e3f2fd;
  border: 1px solid #bbdefb;
  border-radius: 4px;
  padding: 12px;
  margin-bottom: 20px;
}

.produto-info-display h4 {
  margin: 0 0 5px 0;
  color: #1976d2;
  font-size: 14px;
}

.produto-info-display p {
  margin: 0;
  color: #1565c0;
  font-weight: 500;
}

/* Estilos para Abas */
.tabs-container {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  overflow: hidden;
}

.tabs-header {
  display: flex;
  background-color: #f8f9fa;
  border-bottom: 1px solid #e9ecef;
}

.tab-button {
  flex: 1;
  padding: 15px 20px;
  border: none;
  background: transparent;
  cursor: pointer;
  font-weight: 500;
  color: #6c757d;
  transition: all 0.3s ease;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.tab-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.tab-button:hover {
  background-color: #e9ecef;
  color: #495057;
}

.tab-button.active {
  background-color: white;
  color: #2c3e50;
  border-bottom: 3px solid #2c3e50;
}

.tab-badge {
  background-color: #007bff;
  color: white;
  padding: 2px 6px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: bold;
}

.tab-panel {
  padding: 0;
}

.tab-header-toggle {
  cursor: pointer;
  padding: 15px 20px;
  background-color: #f8f9fa;
  border-bottom: 1px solid #e9ecef;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: background-color 0.3s ease;
}

.tab-header-toggle:hover {
  background-color: #e9ecef;
}

.tab-header-toggle h5 {
  margin: 0;
  color: #2c3e50;
  font-weight: 600;
}

.tab-content-collapsible {
  padding: 20px;
  background-color: white;
}

/* Estilos para Manifestação da CPM */
.cpm-response {
  margin-top: 15px;
  padding: 12px;
  background-color: #f0f8ff;
  border-left: 4px solid #007bff;
  border-radius: 4px;
}

.cmp-header h6 {
  margin: 0 0 8px 0;
  color: #007bff;
  font-weight: 600;
}

.cpm-ciencia, .cpm-manifestacao {
  margin-bottom: 8px;
  font-size: 14px;
  color: #495057;
}

.cpm-ciencia:last-child, .cpm-manifestacao:last-child {
  margin-bottom: 0;
}

/* Estilos para Modal de Reclamação */
.form-reclamacao-modal {
  max-width: 700px;
  width: 95%;
  max-height: 90vh;
}

.form-row {
  display: flex;
  gap: 15px;
  margin-bottom: 15px;
}

.form-row .form-group {
  flex: 1;
  margin-bottom: 0;
}

.readonly-field {
  background-color: #f8f9fa !important;
  cursor: not-allowed;
  color: #6c757d;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

/* Responsividade */
@media (max-width: 768px) {
  .form-row {
    flex-direction: column;
    gap: 0;
  }
  
  .form-row .form-group {
    margin-bottom: 15px;
  }
  
  .tabs-header {
    flex-direction: column;
  }
  
  .tab-button {
    border-bottom: 1px solid #e9ecef;
  }
  
  .tab-button.active {
    border-bottom: 1px solid #e9ecef;
    border-left: 3px solid #2c3e50;
  }
}
</style> 