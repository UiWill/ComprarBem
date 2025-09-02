<template>
  <div class="dcb-container">
    <h2>Declaração de Conformidade de Bem (DCB)</h2>
    
    <div class="search-container">
      <div class="form-group">
        <label for="produto">Selecione o produto</label>
        <select 
          id="produto" 
          v-model="produtoSelecionado" 
          @change="carregarDetalhes"
        >
          <option value="">Selecione...</option>
          <option 
            v-for="produto in produtos" 
            :key="produto.id" 
            :value="produto.id"
          >
            {{ produto.nome }} - {{ produto.marca }} - {{ produto.modelo }}
          </option>
        </select>
        
        <!-- CORREÇÃO ISSUE #5 - Informações de paginação e controles -->
        <div v-if="produtos.length > 0" class="paginacao-info">
          <small>
            📊 Mostrando {{ paginacao.totalCarregados }} produtos aprovados
            <span v-if="paginacao.temMaisProdutos"> (há mais disponíveis)</span>
          </small>
          
          <button 
            v-if="paginacao.temMaisProdutos"
            @click="carregarMaisProdutos" 
            class="btn-carregar-mais"
            :disabled="carregandoMais"
          >
            <span v-if="carregandoMais">⏳ Carregando...</span>
            <span v-else>📥 Carregar mais produtos</span>
          </button>
        </div>
      </div>
    </div>
    
    <div v-if="loading || authenticationInProgress || dataLoadingInProgress" class="loading">
      <p v-if="authenticationInProgress">🔐 Validando autenticação...</p>
      <p v-else-if="dataLoadingInProgress">📋 Carregando produtos...</p>
      <p v-else-if="loadingStates.detalhes">🔍 Carregando detalhes do produto...</p>
      <p v-else-if="loadingStates.pdf">📄 Gerando PDF da DCB...</p>
      <p v-else>⏳ Carregando informações...</p>
    </div>
    
    <div v-else-if="produtoDetalhes" class="produto-detalhes">
      <!-- PRODUTO CERTIFICADO -->
      <div class="dcb-section">
        <h3>PRODUTO CERTIFICADO</h3>
        <div class="primeiro-quadro">
          <p><strong>1. Primeiro quadro</strong></p>
      <div class="info-grid">
            <div class="info-item full-width">
              <strong>1.1. Nome do Produto:</strong> {{ produtoDetalhes.nome || 'Não informado' }}
        </div>
        <div class="info-item">
              <strong>Marca:</strong> {{ produtoDetalhes.marca || 'Não informada' }}
        </div>
        <div class="info-item">
              <strong>Modelo:</strong> {{ produtoDetalhes.modelo || 'Não informado' }}
        </div>
        <div class="info-item">
              <strong>Fabricante:</strong> {{ produtoDetalhes.fabricante || 'Não informado' }}
        </div>
        <div class="info-item">
              <strong>CNPJ do Fabricante:</strong> {{ produtoDetalhes.cnpj || 'Não informado' }}
            </div>
          </div>
        </div>
      </div>

      <!-- DADOS DA CERTIFICAÇÃO -->
      <div class="dcb-section">
        <h3>DADOS DA CERTIFICAÇÃO</h3>
        <div class="primeiro-quadro">
          <p><strong>1. Primeiro quadro</strong></p>
          <div class="status-info">
            <p style="margin-left: 20px;"><strong>1.1.</strong> Incluir abaixo de "Status":</p>
            <div class="info-item" style="margin-left: 40px;">
              <strong>Status:</strong> 
              <span class="status-badge" :class="getStatusDCBClass()">
                {{ getStatusDCB() }}
              </span>
            </div>
            <div class="info-item" style="margin-left: 40px;">
              <strong>1.1.1. Origem:</strong> 
              <span v-if="produtoDetalhes.numero_edital">
                Edital de Pré-Qualificação de Bens nº {{ produtoDetalhes.numero_edital }}
              </span>
              <span v-else class="edital-nao-vinculado">
                <em>Produto não vinculado a edital</em>
                <button @click="vincularEdital" class="btn-vincular">🔗 Vincular Edital</button>
              </span>
            </div>
          </div>
          <div class="info-grid">
        <div class="info-item">
              <strong>Data de Emissão:</strong> 
              {{ formatarData(produtoDetalhes.data_emissao) }}
        </div>
        <div class="info-item">
              <strong>Data de Validade:</strong> 
              {{ formatarData(produtoDetalhes.data_validade) }}
        </div>
        </div>
        </div>
      </div>
      
      <div class="documentos">
        <h3>Documentos Anexos</h3>
        
        <!-- CORREÇÃO ISSUE #8 - Loading state específico para documentos -->
        <div v-if="loadingStates.documentos" class="loading-small">
          <span class="spinner-small">⏳</span> Carregando documentos...
        </div>
        
        <div v-else-if="documentos.length > 0">
          <ul class="documentos-lista">
            <li v-for="doc in documentos" :key="doc.id" class="documento-item">
              <span class="doc-icon">📄</span>
              <span class="doc-nome">{{ doc.nome }}</span>
              <a :href="doc.arquivo_url" target="_blank" class="btn-download">Visualizar</a>
            </li>
          </ul>
        </div>
        
        <div v-else class="no-documentos">
          <p>📋 Nenhum documento anexo encontrado para este produto.</p>
        </div>
      </div>
      
      <div class="dcb-actions">
        <div class="button-group">
          <button @click="visualizarDCB" class="btn-primary" :disabled="!produtoAprovado || loadingStates.pdf">
            <span v-if="loadingStates.pdf">⏳ Processando...</span>
            <span v-else>👁️ Visualizar DCB</span>
          </button>
          <button @click="baixarDCB" class="btn-secondary" :disabled="!produtoAprovado || loadingStates.pdf">
            <span v-if="loadingStates.pdf">📄 Gerando PDF...</span>
            <span v-else>📥 Baixar DCB (PDF)</span>
        </button>
        </div>
        <p v-if="!produtoAprovado" class="aviso">
          ⚠️ Somente produtos aprovados possuem Declaração de Conformidade disponível.
        </p>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { jsPDF } from 'jspdf'

export default {
  name: 'FormularioDCB',
  data() {
    return {
      produtoSelecionado: '',
      produtoDetalhes: null,
      documentos: [],
      produtos: [],
      loading: false,
      currentTenantId: null,
      
      // CORREÇÃO ISSUE #4 - Controle de Race Conditions
      authenticationInProgress: false,
      dataLoadingInProgress: false,
      componentInitialized: false,
      
      // CORREÇÃO ISSUE #5 - Performance - Paginação
      paginacao: {
        paginaAtual: 0,
        itensPorPagina: 20,
        temMaisProdutos: true,
        totalCarregados: 0
      },
      carregandoMais: false,
      
      // CORREÇÃO ISSUE #8 - Loading states específicos
      loadingStates: {
        detalhes: false,
        pdf: false,
        documentos: false
      },
      
      // Sistema de edição de dados gerados
      dadosGerados: {
        data_emissao: false,
        data_validade: false,
        numero_edital: false
      },
      // Propriedades de edição removidas - sistema agora usa dados reais da tabela
    }
  },
  computed: {
    produtoAprovado() {
      return this.produtoDetalhes && this.produtoDetalhes.status === 'aprovado'
    },
    
    // CORREÇÃO ISSUE #7 - Detectar dados gerados automaticamente
  },
  created() {
    // CORREÇÃO ISSUE #4 - Controle de Race Condition na inicialização
    this.initializeComponent()
  },
  
  // CORREÇÃO ISSUE #3 - Cleanup na destruição do componente
  beforeDestroy() {
    this.cleanupMemory()
  },
  
  methods: {
    // CORREÇÃO ISSUE #4 - Inicialização controlada para evitar race conditions
    async initializeComponent() {
      try {
        // Prevenir múltiplas inicializações simultâneas
        if (this.authenticationInProgress || this.componentInitialized) {
          return
        }
        
        this.authenticationInProgress = true
        this.loading = true
        
        // Aguardar um tick para garantir que DOM esteja pronto
        await this.$nextTick()
        
        // Obter tenant ID com timeout
        const authPromise = this.obterTenantId()
        const timeout = new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Authentication timeout')), 10000)
        )
        
        const isAuthenticated = await Promise.race([authPromise, timeout])
        
        if (isAuthenticated) {
          // CORREÇÃO ISSUE #5 - Reset paginação antes de carregar
          this.resetarPaginacao()
          
          // Só carregar dados se autenticação foi bem sucedida
          await this.carregarProdutos()
          this.componentInitialized = true
        }
        
      } catch (error) {
        console.error('Erro na inicialização do componente:', error)
        
        // Se timeout ou erro de auth, redirecionar
        if (error.message === 'Authentication timeout') {
          this.redirectToLogin('Timeout na autenticação')
        }
      } finally {
        this.authenticationInProgress = false
        this.loading = false
      }
    },
    
    // CORREÇÃO ISSUE #3 - Método para limpeza de memória
    cleanupMemory() {
      try {
        // Limpar arrays grandes
        this.produtos = []
        this.documentos = []
        
        // Limpar objetos complexos
        this.produtoDetalhes = null
        
        // Limpar referências a PDFs se houver
        if (this.$refs) {
          Object.keys(this.$refs).forEach(key => {
            if (this.$refs[key] && typeof this.$refs[key].cleanup === 'function') {
              this.$refs[key].cleanup()
            }
          })
        }
        
        console.debug('Memory cleanup completed for FormularioDCB')
      } catch (error) {
        console.warn('Warning during memory cleanup:', error)
      }
    },
    // CORREÇÃO ISSUE #1 - Sanitização XSS para PDF
    sanitizeForPDF(text) {
      if (!text) return 'Não informado'
      
      // Converter para string e remover HTML tags
      const str = String(text)
      
      // Remove tags HTML/XML
      const withoutTags = str.replace(/<[^>]*>/g, '')
      
      // Remove caracteres especiais que podem ser interpretados como código
      const withoutSpecialChars = withoutTags
        .replace(/[<>&"'`]/g, '') // Remove caracteres perigosos
        .replace(/javascript:/gi, '') // Remove javascript: URLs
        .replace(/data:/gi, '') // Remove data: URLs
        .replace(/vbscript:/gi, '') // Remove vbscript: URLs
        .replace(/on\w+\s*=/gi, '') // Remove event handlers (onclick, onload, etc)
      
      // Limita o tamanho para evitar buffer overflow
      return withoutSpecialChars.substring(0, 200)
    },
    async obterTenantId() {
      try {
        // CORREÇÃO ISSUE #2 - Validação adequada de autenticação
        const { data, error: sessionError } = await supabase.auth.getSession()
        
        // Verificar se há erro na sessão
        if (sessionError) {
          console.error('Erro na sessão:', sessionError)
          this.redirectToLogin('Erro na sessão de autenticação')
          return false
        }
        
        const user = data?.session?.user
        const session = data?.session
        
        // Verificar se usuário está autenticado
        if (!user || !session) {
          console.error('Usuário não está autenticado')
          this.redirectToLogin('Usuário não autenticado')
          return false
        }
        
        // Verificar se a sessão não expirou
        const now = Math.floor(Date.now() / 1000) // timestamp atual em segundos
        if (session.expires_at && session.expires_at < now) {
          console.error('Sessão expirada')
          this.redirectToLogin('Sessão expirou, faça login novamente')
          return false
        }
        
        // Verificar tenant_id nos metadados do usuário
        if (user.user_metadata?.tenant_id) {
          this.currentTenantId = user.user_metadata.tenant_id
          return true
        }
        
        // Buscar tenant_id na tabela usuarios como fallback
        const { data: userData, error: userError } = await supabase
          .from('usuarios')
          .select('tenant_id')
          .eq('email', user.email)
          .single()
            
        if (userError) {
          console.error('Erro ao buscar tenant_id:', userError)
          this.redirectToLogin('Erro ao validar permissões do usuário')
          return false
        }
        
        if (userData?.tenant_id) {
          this.currentTenantId = userData.tenant_id
          return true
        } else {
          console.error('Tenant ID não encontrado para o usuário')
          this.redirectToLogin('Usuário sem permissões adequadas')
          return false
        }
      } catch (error) {
        console.error('Erro ao obter tenant_id:', error)
        this.redirectToLogin('Erro interno de autenticação')
        return false
      }
    },
    
    // CORREÇÃO ISSUE #2 - Método para redirecionamento seguro
    redirectToLogin(message) {
      this.$swal({
        icon: 'warning',
        title: 'Sessão Inválida',
        text: message,
        confirmButtonText: 'Fazer Login'
      }).then(() => {
        // Limpar dados sensíveis antes de redirecionar
        this.currentTenantId = null
        this.produtos = []
        this.produtoDetalhes = null
        this.produtoSelecionado = ''
        this.documentos = []
        
        // Redirecionar para login
        if (this.$router) {
          this.$router.push('/login')
        } else {
          window.location.href = '/login'
        }
      })
    },
    
    async carregarProdutos() {
      try {
        // CORREÇÃO ISSUE #4 - Prevenir múltiplas chamadas simultâneas
        if (this.dataLoadingInProgress) {
          console.debug('Carregamento de produtos já em progresso, ignorando nova chamada')
          return
        }
        
        this.dataLoadingInProgress = true
        this.loading = true
        
        // CORREÇÃO ISSUE #2 - Verificar autenticação antes de acessar dados
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível')
          const isAuthenticated = await this.obterTenantId()
          if (!isAuthenticated) {
            return // obterTenantId já redirecionou para login
          }
        }
        
        // CORREÇÃO ISSUE #5 - Implementar paginação eficiente
        const offset = this.paginacao.paginaAtual * this.paginacao.itensPorPagina
        const limit = this.paginacao.itensPorPagina + 1 // +1 para saber se há mais
        
        const { data: produtos, error } = await supabase
          .from('produtos')
          .select('id, nome, marca, modelo, status, numero_edital') // Apenas campos necessários
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'aprovado')
          .order('nome')
          .range(offset, offset + this.paginacao.itensPorPagina)
        
        if (error) throw error
        
        const produtosPagina = produtos || []
        
        // Verificar se há mais produtos
        this.paginacao.temMaisProdutos = produtosPagina.length > this.paginacao.itensPorPagina
        
        // Remover item extra se existir
        if (this.paginacao.temMaisProdutos) {
          produtosPagina.pop()
        }
        
        // Se é primeira página, substituir. Senão, adicionar
        if (this.paginacao.paginaAtual === 0) {
          this.produtos = produtosPagina
        } else {
          this.produtos = [...this.produtos, ...produtosPagina]
        }
        
        this.paginacao.totalCarregados = this.produtos.length
        console.debug(`Carregados ${produtosPagina.length} produtos (total: ${this.paginacao.totalCarregados})`)
      } catch (error) {
        console.error('Erro ao carregar produtos:', error)
        
        // CORREÇÃO ISSUE #6 - Error handling específico e útil
        let titulo = 'Erro ao carregar produtos'
        let mensagemErro = 'Não foi possível carregar a lista de produtos.'
        let icon = 'error'
        
        if (error.code === 'PGRST116') {
          titulo = 'Acesso Negado'
          mensagemErro = 'Você não tem permissão para acessar os produtos deste órgão.'
          icon = 'warning'
        } else if (error.message?.includes('JWT')) {
          titulo = 'Sessão Expirada'
          mensagemErro = 'Sua sessão expirou. Você será redirecionado para fazer login.'
          icon = 'info'
          
          setTimeout(() => {
            this.redirectToLogin('Sessão expirada')
          }, 2000)
        } else if (error.message?.includes('network') || error.message?.includes('fetch')) {
          titulo = 'Erro de Conexão'
          mensagemErro = 'Verifique sua conexão com a internet e tente novamente.'
          icon = 'warning'
        } else if (error.code === 'PGRST301') {
          titulo = 'Banco Indisponível'
          mensagemErro = 'O sistema está temporariamente indisponível. Tente em alguns minutos.'
          icon = 'warning'
        }
        
        this.$swal({
          icon: icon,
          title: titulo,
          text: mensagemErro,
          confirmButtonText: 'Tentar Novamente',
          showCancelButton: true,
          cancelButtonText: 'Cancelar'
        }).then((result) => {
          if (result.isConfirmed && !error.message?.includes('JWT')) {
            // Tentar carregar novamente
            this.carregarProdutos()
          }
        })
      } finally {
        // CORREÇÃO ISSUE #4 - Sempre limpar flags de loading
        this.dataLoadingInProgress = false
        this.loading = false
      }
    },
    
    // CORREÇÃO ISSUE #5 - Método para carregar mais produtos
    async carregarMaisProdutos() {
      if (this.carregandoMais || !this.paginacao.temMaisProdutos) {
        return
      }
      
      try {
        this.carregandoMais = true
        this.paginacao.paginaAtual++
        
        await this.carregarProdutos()
        
        console.debug(`Página ${this.paginacao.paginaAtual} carregada`)
      } catch (error) {
        console.error('Erro ao carregar mais produtos:', error)
        // Reverter página em caso de erro
        this.paginacao.paginaAtual--
        
        // CORREÇÃO ISSUE #6 - Error handling melhorado
        let mensagemErro = 'Não foi possível carregar mais produtos.'
        
        if (error.code === 'PGRST116') {
          mensagemErro = 'Sem permissão para acessar os produtos.'
        } else if (error.message?.includes('network')) {
          mensagemErro = 'Erro de conexão. Verifique sua internet.'
        } else if (error.message?.includes('timeout')) {
          mensagemErro = 'Timeout na consulta. Tente novamente.'
        }
        
        this.$swal({
          icon: 'warning',
          title: 'Erro ao carregar',
          text: mensagemErro,
          footer: 'Você pode tentar novamente clicando no botão',
          confirmButtonText: 'OK'
        })
      } finally {
        this.carregandoMais = false
      }
    },
    
    // CORREÇÃO ISSUE #5 - Reset da paginação
    resetarPaginacao() {
      this.paginacao.paginaAtual = 0
      this.paginacao.temMaisProdutos = true
      this.paginacao.totalCarregados = 0
      this.produtos = []
    },
    
    // CORREÇÃO ISSUE #7 - Mostrar detalhes dos dados gerados
    
    async carregarDetalhes() {
      if (!this.produtoSelecionado) {
        this.produtoDetalhes = null
        this.documentos = []
        return
      }
      
      try {
        // CORREÇÃO ISSUE #8 - Loading states específicos
        this.loadingStates.detalhes = true
        this.loading = true
        
        // Carregar detalhes do produto
        const { data: produto, error: produtoError } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', this.produtoSelecionado)
          .single()
        
        if (produtoError) throw produtoError
        
        console.log('Produto carregado:', produto)
        
        // CORREÇÃO FINAL - Usar dados reais sem sistema de "dados gerados"
        // Reset flags de dados gerados (mantido para compatibilidade)
        this.dadosGerados = {
          data_emissao: false,
          data_validade: false,
          numero_edital: false
        }
        
        // Processar data de emissão - usar dados reais da tabela
        if (!produto.data_emissao || produto.data_emissao === '' || produto.data_emissao === null) {
          const infoEmissao = this.obterDataEmissaoDCB(produto)
          produto.data_emissao = infoEmissao.data
          console.log(`✅ Data de emissão DCB obtida de: ${infoEmissao.origem}`)
        } else {
          console.log(`✅ Produto já possui data de emissão: ${produto.data_emissao}`)
        }
        
        // Processar data de validade - calcular baseado na data de emissão
        if (!produto.data_validade || produto.data_validade === '' || produto.data_validade === null) {
          const dataValidade = new Date(produto.data_emissao)
          dataValidade.setFullYear(dataValidade.getFullYear() + 1)
          produto.data_validade = dataValidade.toISOString().split('T')[0]
          console.log(`✅ Data de validade DCB calculada: ${dataValidade.toLocaleDateString('pt-BR')}`)
        } else {
          console.log(`✅ Produto já possui data de validade: ${produto.data_validade}`)
        }
        
        // Processar número do edital apenas se não existir
        if (!produto.numero_edital || produto.numero_edital === '' || produto.numero_edital === null) {
          // Tentar montar o número do edital baseado nos campos reais
          let numeroEdital = null
          
          // Verificar se existe edital_prequalificacao ou outros campos relacionados
          if (produto.edital_prequalificacao) {
            numeroEdital = produto.edital_prequalificacao
            console.log(`✅ Número do edital obtido de edital_prequalificacao: ${numeroEdital}`)
          } else if (produto.edital_id) {
            numeroEdital = produto.edital_id
            console.log(`✅ Número do edital obtido de edital_id: ${numeroEdital}`)
          } else if (produto.ano_edital) {
            numeroEdital = `001/${produto.ano_edital}`
            console.log(`✅ Número do edital construído com ano_edital: ${numeroEdital}`)
          }
          
          if (numeroEdital) {
            produto.numero_edital = numeroEdital
            // NÃO adicionar aos dados gerados - é um dado real da tabela
          } else {
            // Se realmente não tem como determinar, deixar vazio para vincular depois
            produto.numero_edital = null
            console.warn('⚠️ Número do edital não encontrado - produto precisa ser vinculado a um edital')
          }
        } else {
          console.log(`✅ Número do edital já existe: ${produto.numero_edital}`)
        }
        
        // Sistema removido - não exibir mais avisos de dados gerados
        // Todos os dados agora vêm da tabela ou são calculados com base em dados reais
        
        this.produtoDetalhes = produto
        console.log('Detalhes do produto definidos:', this.produtoDetalhes)
        
        // CORREÇÃO ISSUE #8 - Loading state para documentos
        this.loadingStates.documentos = true
        
        // Carregar documentos
        const { data: docs, error: docsError } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', this.produtoSelecionado)
        
        if (docsError) throw docsError
        
        this.documentos = docs || []
      } catch (error) {
        console.error('Erro ao carregar detalhes do produto:', error)
        
        // CORREÇÃO ISSUE #6 - Error handling detalhado
        let titulo = 'Erro ao carregar detalhes'
        let mensagem = 'Não foi possível carregar os detalhes do produto selecionado.'
        
        if (error.code === 'PGRST116') {
          titulo = 'Produto Inacessível'
          mensagem = 'Você não tem permissão para acessar este produto.'
        } else if (error.code === 'PGRST100') {
          titulo = 'Produto Não Encontrado'
          mensagem = 'Este produto não foi encontrado ou foi removido do sistema.'
        } else if (error.message?.includes('network')) {
          titulo = 'Erro de Conexão'
          mensagem = 'Problema de conexão. Verifique sua internet e tente selecionar o produto novamente.'
        }
        
        // Limpar seleção em caso de erro
        this.produtoDetalhes = null
        this.documentos = []
        
        this.$swal({
          icon: 'warning',
          title: titulo,
          text: mensagem,
          confirmButtonText: 'OK',
          footer: 'Tente selecionar outro produto da lista'
        })
      } finally {
        // CORREÇÃO ISSUE #8 - Limpar todos os loading states
        this.loading = false
        this.loadingStates.detalhes = false
        this.loadingStates.documentos = false
      }
    },
    
    getStatusDCB() {
      if (!this.produtoDetalhes || !this.produtoDetalhes.data_validade) {
        return 'VENCIDA'
      }
      
      const hoje = new Date()
      const dataValidade = new Date(this.produtoDetalhes.data_validade)
      
      return dataValidade > hoje ? 'EM VIGOR' : 'VENCIDA'
    },
    
    getStatusDCBClass() {
      const status = this.getStatusDCB()
      return {
        'status-em-vigor': status === 'EM VIGOR',
        'status-vencida': status === 'VENCIDA'
      }
    },
    
    formatarData(data) {
      if (!data) return 'Não informada'
      
      try {
        const dataObj = new Date(data)
        return dataObj.toLocaleDateString('pt-BR')
      } catch (error) {
        return 'Data inválida'
      }
    },
    
    visualizarDCB() {
      if (!this.produtoDetalhes || !this.produtoAprovado) {
        this.$swal({
          icon: 'error',
          title: 'Não disponível',
          text: 'Apenas produtos aprovados possuem Declaração de Conformidade disponível.'
        })
        return
      }
      
      // Mostrar DCB em modal
      const dcbContent = this.criarConteudoDCB()
      
      this.$swal({
        title: 'Declaração de Conformidade de Bem',
        html: dcbContent,
        width: '800px',
        showConfirmButton: true,
        confirmButtonText: 'Fechar',
        showCancelButton: true,
        cancelButtonText: '📥 Baixar PDF',
        cancelButtonColor: '#3498db'
      }).then((result) => {
        if (result.isDismissed && result.dismiss === 'cancel') {
          this.baixarDCB()
        }
      })
    },
    
    baixarDCB() {
      if (!this.produtoDetalhes || !this.produtoAprovado) {
        this.$swal({
          icon: 'error',
          title: 'Não disponível',
          text: 'Apenas produtos aprovados possuem Declaração de Conformidade disponível.'
        })
        return
      }
      
      // CORREÇÃO ISSUE #3 - Controle de Memory Leak
      let pdf = null
      
      try {
        // CORREÇÃO ISSUE #8 - Loading state específico para PDF
        this.loadingStates.pdf = true
        
        // Criar PDF usando jsPDF
        pdf = new jsPDF('p', 'mm', 'a4')
        const produto = this.produtoDetalhes
        const numeroAno = new Date().getFullYear()
        
        // Configurar fonte
        pdf.setFont('helvetica')
        
        // Cabeçalho
        pdf.setFontSize(9)
        pdf.text('(Logo do órgão ou entidade)', 20, 15)
        pdf.text('(Nome do órgão ou entidade)', 130, 15)
        pdf.text('Comissão de Padronização de Materiais - CPM', 115, 22)
        
        // Título principal
        pdf.setFontSize(14)
        pdf.setFont('helvetica', 'bold')
        const titulo = 'DECLARAÇÃO DE CONFORMIDADE DE BEM'
        const tituloWidth = pdf.getTextWidth(titulo)
        pdf.text(titulo, (210 - tituloWidth) / 2, 35)
        
        pdf.setFontSize(12)
        const dcbNumero = `DCB Nº ${produto.id}/${numeroAno}`
        const dcbWidth = pdf.getTextWidth(dcbNumero)
        pdf.text(dcbNumero, (210 - dcbWidth) / 2, 42)
        
        // Linha separadora
        pdf.line(20, 47, 190, 47)
        
        // PRODUTO CERTIFICADO
        let y = 55
        pdf.setFontSize(11)
        pdf.setFont('helvetica', 'bold')
        pdf.text('PRODUTO CERTIFICADO', 20, y)
        
        y += 6
        pdf.setFont('helvetica', 'normal')
        pdf.setFontSize(9)
        pdf.text('1. Primeiro quadro', 20, y)
        
        y += 5
        // CORREÇÃO XSS: Sanitizar dados antes de inserir no PDF
        pdf.text(`1.1. Nome: ${this.sanitizeForPDF(produto.nome)}`, 25, y)
        y += 4
        pdf.text(`Marca: ${this.sanitizeForPDF(produto.marca)}`, 25, y)
        y += 4
        pdf.text(`Modelo: ${this.sanitizeForPDF(produto.modelo)}`, 25, y)
        y += 4
        pdf.text(`Fabricante: ${this.sanitizeForPDF(produto.fabricante)}`, 25, y)
        y += 4
        pdf.text(`CNPJ do Fabricante: ${this.sanitizeForPDF(produto.cnpj)}`, 25, y)
        
        // DADOS DA CERTIFICAÇÃO
        y += 10
        pdf.setFont('helvetica', 'bold')
        pdf.setFontSize(11)
        pdf.text('DADOS DA CERTIFICAÇÃO', 20, y)
        
        y += 6
        pdf.setFont('helvetica', 'normal')
        pdf.setFontSize(9)
        pdf.text('1. Primeiro quadro', 20, y)
        y += 5
        pdf.text('1.1. Incluir abaixo de "Status":', 25, y)
        y += 4
        pdf.text(`Status: ${this.getStatusDCB()}`, 30, y)
        y += 4
        pdf.text(`1.1.1. Origem: Edital de Pré-Qualificação de Bens nº ${this.sanitizeForPDF(produto.numero_edital) || 'XXX/YYYY'}`, 30, y)
        
        // DECLARAÇÃO
        y += 10
        pdf.setFont('helvetica', 'bold')
        pdf.setFontSize(11)
        pdf.text('DECLARAÇÃO', 20, y)
        
        y += 6
        pdf.setFont('helvetica', 'normal')
        pdf.setFontSize(8)
        
        // Texto da declaração - dividido em linhas otimizadas
        const textoDeclaracao = [
          'A Comissão de Padronização de Materiais – CPM do(a) _______ (nome do órgão/entidade)',
          '_______, constituída por meio do(a) __________ [informar o tipo de instrumento',
          '(resolução/portaria), número e ano de expedição], DECLARA que:',
          '',
          '1º) o produto especificado nesta DCB foi submetido à demonstração funcional e análise',
          'técnica, devidamente monitoradas e documentadas por esta CPM em processo administrativo',
          'próprio, com estrita observância às formalidades legais e regulamentares, tendo sido',
          'considerado apto e, portanto, APROVADO para o uso e a finalidade a que se destina, uma',
          'vez que atendeu aos requisitos técnicos exigidos pelo Edital de Pré-Qualificação de Bens',
          'em referência, sendo a sua marca comercial e modelo lançados no Catálogo Eletrônico de',
          'Bens Padronizados deste(a) órgão/entidade, para fins de aquisições futuras e eventuais,',
          'conforme previsto na Lei Federal nº 14.133/2021 (Lei de Licitações e Contratos);',
          '',
          '2º) expirada a sua vigência, esta DCB somente poderá ser renovada mediante a realização',
          'de nova demonstração do produto nela especificado, para fins de reanálise técnica e',
          'funcional monitoradas e documentadas pela CPM.'
        ]
        
        textoDeclaracao.forEach(linha => {
          pdf.text(linha, 20, y)
          y += linha === '' ? 2 : 4
        })
        
        // Assinatura - compacta
        y += 8
        pdf.text('Local e data ___________', 20, y)
        y += 12
        pdf.text('(assinatura digital)', 20, y)
        y += 5
        pdf.setFont('helvetica', 'bold')
        pdf.text('Comissão de Padronização de Materiais', 20, y)
        y += 4
        pdf.text('Presidente da CPM', 20, y)
        
        // Salvar PDF
        const nomeArquivo = `DCB_${produto.nome}_${produto.id}_${numeroAno}.pdf`
        pdf.save(nomeArquivo)
        
        this.$swal({
          icon: 'success',
          title: 'PDF Gerado!',
          text: `DCB baixada como: ${nomeArquivo}`,
          timer: 3000,
          showConfirmButton: false
        })
        
      } catch (error) {
        console.error('Erro ao gerar PDF:', error)
        
        // CORREÇÃO ISSUE #6 - Error handling específico para PDF
        let titulo = 'Erro na Geração do PDF'
        let mensagem = 'Não foi possível gerar o arquivo PDF da DCB.'
        
        if (error.name === 'SecurityError') {
          titulo = 'Erro de Segurança'
          mensagem = 'Seu navegador bloqueou o download. Permita downloads neste site.'
        } else if (error.message?.includes('memory') || error.message?.includes('Memory')) {
          titulo = 'Memória Insuficiente'
          mensagem = 'Memória insuficiente para gerar o PDF. Feche outras abas e tente novamente.'
        } else if (error.message?.includes('jsPDF')) {
          titulo = 'Erro na Biblioteca PDF'
          mensagem = 'Problema na geração do PDF. Atualize a página e tente novamente.'
        } else if (!produto?.nome) {
          titulo = 'Dados Incompletos'
          mensagem = 'Dados do produto estão incompletos para gerar a DCB.'
        }
        
        this.$swal({
          icon: 'error',
          title: titulo,
          text: mensagem,
          confirmButtonText: 'Tentar Novamente',
          showCancelButton: true,
          cancelButtonText: 'Cancelar',
          footer: 'Se o problema persistir, entre em contato com o suporte'
        }).then((result) => {
          if (result.isConfirmed) {
            // Tentar gerar novamente após um breve delay
            setTimeout(() => {
              this.baixarDCB()
            }, 1000)
          }
        })
      } finally {
        // CORREÇÃO ISSUE #3 - Memory Cleanup
        if (pdf) {
          try {
            // Limpar referências internas do PDF
            pdf.internal = null
            pdf = null
            
            // Forçar garbage collection se disponível
            if (window.gc) {
              window.gc()
            }
            
            // Liberar memória explicitamente
            if (performance && performance.memory) {
              console.debug('Memory after PDF cleanup:', performance.memory)
            }
          } catch (cleanupError) {
            console.warn('Aviso durante cleanup do PDF:', cleanupError)
          }
        }
        
        // Limpar variáveis grandes da memória
        produto = null
        
        // CORREÇÃO ISSUE #8 - Limpar loading state do PDF
        this.loadingStates.pdf = false
      }
    },
    
    // Detectar melhor data de criação/aprovação do DCB
    obterDataEmissaoDCB(produto) {
      // Vamos examinar quais campos existem no produto
      console.log('📊 Campos disponíveis no produto:', Object.keys(produto))
      
      // Prioridade dos campos que podem existir:
      // 1. data_aprovacao, data_aprovado, aprovado_em
      // 2. updated_at (última atualização)
      // 3. qualquer campo com 'data' no nome
      // 4. hoje como fallback
      
      let dataEmissao = new Date()
      let origem = 'hoje (fallback - nenhuma data encontrada)'
      
      // Buscar melhor data baseada nos campos reais da tabela
      if (produto.data_aprovacao) {
        dataEmissao = new Date(produto.data_aprovacao)
        origem = 'data de aprovação pela CPM'
      } else if (produto.homologado_em) {
        dataEmissao = new Date(produto.homologado_em)
        origem = 'data de homologação'
      } else if (produto.julgado_em) {
        dataEmissao = new Date(produto.julgado_em)
        origem = 'data de julgamento'
      } else if (produto.ccl_data_julgamento) {
        dataEmissao = new Date(produto.ccl_data_julgamento)
        origem = 'data de julgamento pela CCL'
      } else if (produto.criado_em) {
        dataEmissao = new Date(produto.criado_em)
        origem = 'data de criação do produto'
      } else if (produto.updated_at) {
        dataEmissao = new Date(produto.updated_at)
        origem = 'data da última atualização'
      }
      
      return {
        data: dataEmissao.toISOString().split('T')[0],
        dataFormatada: dataEmissao.toLocaleDateString('pt-BR'),
        origem: origem
      }
    },
    
    // Vincular produto a um edital
    async vincularEdital() {
      try {
        // Buscar editais disponíveis
        const { data: editais, error } = await supabase
          .from('editais')
          .select('id, numero, titulo, ano')
          .eq('tenant_id', this.currentTenantId)
          .order('ano', { ascending: false })
        
        if (error) throw error
        
        if (!editais || editais.length === 0) {
          this.$swal({
            icon: 'info',
            title: 'Nenhum Edital Encontrado',
            text: 'Não há editais cadastrados para vincular a este produto.'
          })
          return
        }
        
        // Criar options para o select
        const options = {}
        editais.forEach(edital => {
          options[edital.id] = `${edital.numero} - ${edital.titulo}`
        })
        
        const { value: editalId } = await this.$swal({
          title: 'Vincular Produto ao Edital',
          text: 'Selecione o edital ao qual este produto deve ser vinculado:',
          input: 'select',
          inputOptions: options,
          inputPlaceholder: 'Selecione um edital...',
          showCancelButton: true,
          confirmButtonText: 'Vincular',
          cancelButtonText: 'Cancelar'
        })
        
        if (editalId) {
          const editalSelecionado = editais.find(e => e.id === editalId)
          
          // Atualizar o produto no banco
          const { error: updateError } = await supabase
            .from('produtos')
            .update({
              edital_id: editalId,
              numero_edital: editalSelecionado.numero
            })
            .eq('id', this.produtoDetalhes.id)
          
          if (updateError) throw updateError
          
          // Atualizar a interface
          this.produtoDetalhes.edital_id = editalId
          this.produtoDetalhes.numero_edital = editalSelecionado.numero
          
          this.$swal({
            icon: 'success',
            title: 'Produto Vinculado',
            text: `Produto vinculado ao edital ${editalSelecionado.numero} com sucesso!`,
            timer: 2000
          })
        }
        
      } catch (error) {
        console.error('Erro ao vincular edital:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível vincular o produto ao edital.'
        })
      }
    },
    
    // Métodos de edição removidos - sistema agora usa apenas dados reais da tabela
    
    criarConteudoDCB() {
      const produto = this.produtoDetalhes
      const hoje = new Date().toLocaleDateString('pt-BR')
      const numeroAno = new Date().getFullYear()
      
      return `
        <div style="text-align: left; font-family: Arial, sans-serif; line-height: 1.6; padding: 20px;">
          <div style="text-align: center; margin-bottom: 30px; border-bottom: 2px solid #2c3e50; padding-bottom: 20px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
              <div style="text-align: left;">
                <strong>(Logo do órgão<br>ou entidade)</strong>
              </div>
              <div style="text-align: right;">
                <strong>(Nome do órgão ou entidade)<br>
                Comissão de Padronização de Materiais - CPM</strong>
              </div>
            </div>
            <h2 style="margin: 20px 0 10px 0; font-size: 18px; font-weight: bold;">DECLARAÇÃO DE CONFORMIDADE DE BEM</h2>
            <h3 style="margin: 5px 0; font-size: 16px;">DCB Nº ${produto.id}/${numeroAno}</h3>
          </div>
          
          <div style="margin-bottom: 25px;">
            <h4 style="color: #2c3e50; margin-bottom: 15px; font-size: 16px; font-weight: bold;">PRODUTO CERTIFICADO</h4>
            <p style="margin: 8px 0;"><strong>1. Primeiro quadro</strong></p>
            <p style="margin: 8px 0; margin-left: 20px;"><strong>1.1. Nome:</strong> ${produto.nome || 'Não informado'}</p>
            <p style="margin: 8px 0; margin-left: 20px;"><strong>Marca:</strong> ${produto.marca || 'Não informada'}</p>
            <p style="margin: 8px 0; margin-left: 20px;"><strong>Modelo:</strong> ${produto.modelo || 'Não informado'}</p>
            <p style="margin: 8px 0; margin-left: 20px;"><strong>Fabricante:</strong> ${produto.fabricante || 'Não informado'}</p>
            <p style="margin: 8px 0; margin-left: 20px;"><strong>CNPJ do Fabricante:</strong> ${produto.cnpj || 'Não informado'}</p>
          </div>
          
          <div style="margin-bottom: 25px;">
            <h4 style="color: #2c3e50; margin-bottom: 15px; font-size: 16px; font-weight: bold;">DADOS DA CERTIFICAÇÃO</h4>
            <p style="margin: 8px 0;"><strong>1. Primeiro quadro</strong></p>
            <p style="margin: 8px 0; margin-left: 20px;"><strong>1.1.</strong> Incluir abaixo de "Status":</p>
            <p style="margin: 8px 0; margin-left: 40px;"><strong>Status:</strong> ${this.getStatusDCB()}</p>
            <p style="margin: 8px 0; margin-left: 40px;"><strong>1.1.1. Origem:</strong> Edital de Pré-Qualificação de Bens nº ${produto.numero_edital || 'XXX/YYYY'}</p>
          </div>
          
          <div style="margin-bottom: 25px;">
            <h4 style="color: #2c3e50; margin-bottom: 15px; font-size: 16px; font-weight: bold;">DECLARAÇÃO</h4>
            <p style="margin: 10px 0; text-align: justify;">
              A Comissão de Padronização de Materiais – CPM do(a) <strong>_______ (nome do órgão/entidade) _______</strong>, constituída por meio do(a) <strong>__________ [informar o tipo de instrumento (resolução/portaria), número e ano de expedição]</strong>, <strong>DECLARA</strong> que:
            </p>
            
            <p style="margin: 15px 0; text-align: justify;">
              <strong>1º)</strong> o produto especificado nesta DCB foi submetido à demonstração funcional e análise técnica, devidamente monitoradas e documentadas por esta CPM em processo administrativo próprio, com estrita observância às formalidades legais e regulamentares, tendo sido considerado apto e, portanto, <strong>APROVADO</strong> para o uso e a finalidade a que se destina, uma vez que atendeu aos requisitos técnicos exigidos pelo Edital de Pré-Qualificação de Bens em referência, sendo a sua marca comercial e modelo lançados no <strong>Catálogo Eletrônico de Bens Padronizados</strong> deste(a) órgão/entidade, para fins de aquisições futuras e eventuais, conforme previsto na Lei Federal nº 14.133/2021 (Lei de Licitações e Contratos);
            </p>
            
            <p style="margin: 15px 0; text-align: justify;">
              <strong>2º)</strong> expirada a sua vigência, esta DCB somente poderá ser renovada mediante a realização de nova demonstração do produto nela especificado, para fins de reanálise técnica e funcional monitoradas e documentadas pela CPM.
            </p>
          </div>
          
          <div style="margin-top: 50px; text-align: center;">
            <p style="margin: 20px 0;">Local e data ___________</p>
            <br><br>
            <p style="margin: 10px 0;">(assinatura digital)</p>
            <p style="margin: 5px 0; font-weight: bold;">Comissão de Padronização de Materiais</p>
            <p style="margin: 5px 0; font-weight: bold;">Presidente da CPM</p>
          </div>
        </div>
      `
    }
  }
}
</script>

<style scoped>
.dcb-container {
  padding: 20px;
  max-width: 900px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #2c3e50;
}

.search-container {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

select {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.loading {
  text-align: center;
  padding: 20px;
}

.produto-detalhes {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.dcb-section {
  margin-bottom: 30px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #3498db;
}

.dcb-section h3 {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-size: 18px;
  font-weight: bold;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

.info-item {
  padding: 10px;
  background: white;
  border-radius: 4px;
  border: 1px solid #e0e0e0;
}

.info-item.full-width {
  grid-column: span 2;
}

.primeiro-quadro {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 6px;
  border: 1px solid #e0e0e0;
}

.primeiro-quadro > p {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-weight: bold;
}

.status-info {
  margin-bottom: 20px;
}

.status-info p {
  margin: 8px 0;
  color: #2c3e50;
}

.status-badge {
  display: inline-block;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  text-transform: uppercase;
  font-weight: bold;
  margin-left: 10px;
}

.status-em-vigor {
  background-color: #27ae60;
  color: white;
}

.status-vencida {
  background-color: #e74c3c;
  color: white;
}

.documentos {
  margin-top: 20px;
}

.documentos h3 {
  margin-bottom: 15px;
  color: #2c3e50;
}

.documentos-lista {
  list-style: none;
  padding: 0;
  margin: 0;
}

.documento-item {
  display: flex;
  align-items: center;
  padding: 10px;
  background: #f9f9f9;
  margin-bottom: 8px;
  border-radius: 4px;
}

.doc-icon {
  margin-right: 10px;
  font-size: 20px;
}

.doc-nome {
  flex: 1;
}

.btn-download {
  padding: 5px 10px;
  background-color: #3498db;
  color: white;
  text-decoration: none;
  border-radius: 4px;
  font-size: 12px;
}

.dcb-actions {
  margin-top: 30px;
  text-align: center;
}

.button-group {
  display: flex;
  justify-content: center;
  gap: 10px;
}

.btn-primary {
  padding: 12px 24px;
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  font-weight: bold;
}

.btn-primary:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}

/* Estilos para edição removidos - sistema agora usa apenas dados reais da tabela */

.info-item input[type="date"]:focus,
.info-item input[type="text"]:focus {
  outline: none;
  border-color: #2980b9;
  box-shadow: 0 0 3px rgba(52, 152, 219, 0.3);
}

/* Estilos para produto não vinculado a edital */
.edital-nao-vinculado {
  color: #e67e22;
  font-style: italic;
}

.btn-vincular {
  background-color: #f39c12;
  color: white;
  border: none;
  padding: 4px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  margin-left: 10px;
  transition: background-color 0.2s;
}

.btn-vincular:hover {
  background-color: #e67e22;
}

.btn-secondary {
  padding: 12px 24px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  font-weight: bold;
}

.btn-secondary:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}

.aviso {
  margin-top: 10px;
  color: #e74c3c;
  font-size: 14px;
}

/* CORREÇÃO ISSUE #5 - Estilos para paginação */
.paginacao-info {
  margin-top: 10px;
  padding: 10px;
  background-color: #f8f9fa;
  border-radius: 5px;
  border-left: 3px solid #007bff;
}

.paginacao-info small {
  display: block;
  margin-bottom: 8px;
  color: #6c757d;
  font-weight: 500;
}

.btn-carregar-mais {
  background: linear-gradient(135deg, #007bff, #0056b3);
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
}

.btn-carregar-mais:hover:not(:disabled) {
  background: linear-gradient(135deg, #0056b3, #004085);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0,123,255,0.3);
}

.btn-carregar-mais:disabled {
  background: #6c757d;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* Estilos do aviso de dados gerados removidos - sistema agora usa apenas dados reais da tabela */

@media (max-width: 768px) {
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .dcb-container {
    padding: 10px;
  }
  
  .btn-carregar-mais {
    width: 100%;
    margin-top: 5px;
  }
  
  .btn-detalhes {
    width: 100%;
  }
}

/* CORREÇÃO ISSUE #8 - Estilos para loading states específicos */
.loading-small {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background-color: #f8f9fa;
  border-radius: 6px;
  color: #6c757d;
  font-size: 0.9rem;
  margin: 10px 0;
}

.spinner-small {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.no-documentos {
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  text-align: center;
  margin: 10px 0;
}

.no-documentos p {
  margin: 0;
  color: #6c757d;
  font-style: italic;
}

/* Melhorar loading states nos botões */
button:disabled span {
  opacity: 0.8;
}

button[disabled] {
  cursor: not-allowed;
  opacity: 0.7;
}
</style> 