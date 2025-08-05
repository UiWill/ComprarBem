<template>
  <div class="assistente-container">
    <div class="assistente-header">
      <h2>🎯 Assistente de Processo Administrativo</h2>
      <div class="progresso">
        <div class="etapas">
          <div 
            v-for="(etapa, index) in etapas" 
            :key="index"
            class="etapa"
            :class="{ 
              active: etapaAtual === index, 
              completed: etapaAtual > index,
              disabled: etapaAtual < index 
            }"
          >
            <div class="etapa-numero">{{ index + 1 }}</div>
            <div class="etapa-info">
              <div class="etapa-titulo">{{ etapa.titulo }}</div>
              <div class="etapa-desc">{{ etapa.descricao }}</div>
            </div>
          </div>
        </div>
        <div class="barra-progresso">
          <div 
            class="progresso-fill" 
            :style="{ width: `${(etapaAtual / (etapas.length - 1)) * 100}%` }"
          ></div>
        </div>
      </div>
    </div>

    <div class="assistente-conteudo">
      <!-- Etapa 1: Informações Básicas -->
      <div v-if="etapaAtual === 0" class="etapa-conteudo">
        <h3>📋 Informações Básicas do Processo</h3>
        <div class="tipo-processo-container">
          <div class="tipo-processo-escolha">
            <h4>Escolha o tipo de processo:</h4>
            <div class="tipos-opcoes">
              <div 
                class="tipo-opcao" 
                :class="{ selected: dadosProcesso.tipo_processo === 'padronizacao' }"
                @click="selecionarTipo('padronizacao')"
              >
                <div class="tipo-icon">✅</div>
                <div class="tipo-info">
                  <h5>Padronização</h5>
                  <p>Incluir novos produtos no Catálogo Eletrônico</p>
                  <div class="tipo-fluxo">
                    <span class="fluxo-item">DFD</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Edital</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Análise CPPM</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">CCL</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">DCB</span>
                  </div>
                </div>
              </div>
              
              <div 
                class="tipo-opcao" 
                :class="{ selected: dadosProcesso.tipo_processo === 'despadronizacao' }"
                @click="selecionarTipo('despadronizacao')"
              >
                <div class="tipo-icon">❌</div>
                <div class="tipo-info">
                  <h5>Despadronização</h5>
                  <p>Remover produtos inadequados do Catálogo</p>
                  <div class="tipo-fluxo">
                    <span class="fluxo-item">DFD</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Relatório</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">CCL</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Remoção</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="dadosProcesso.tipo_processo" class="dados-basicos">
            <h4>Dados do Órgão:</h4>
            <div class="form-group">
              <label>Número do Processo *</label>
              <input 
                type="text" 
                v-model="dadosProcesso.numero_processo" 
                placeholder="Ex: 001/2025"
                required
              >
              <small class="field-hint">Formato: [número]/[ano] - Ex: 001/2025, 123/2024</small>
            </div>
            
            <div class="form-group">
              <label>Nome do Órgão *</label>
              <input 
                type="text" 
                v-model="dadosProcesso.nome_orgao" 
                placeholder="Ex: Prefeitura Municipal de Nova Lima"
                required
              >
            </div>
            
            <div class="form-group">
              <label>Unidade Interessada *</label>
              <input 
                type="text" 
                v-model="dadosProcesso.unidade_interessada" 
                placeholder="Ex: Secretaria de Administração"
                required
              >
            </div>
            
            <div class="form-group">
              <label>Observações Iniciais</label>
              <textarea 
                v-model="dadosProcesso.observacoes" 
                rows="3"
                placeholder="Observações especiais sobre este processo..."
              ></textarea>
            </div>
          </div>
        </div>
      </div>

      <!-- Etapa 2: DFD -->
      <div v-if="etapaAtual === 1" class="etapa-conteudo">
        <FormularioDFD
          v-if="processoTemporario"
          :processo-id="processoTemporario.id"
          :numero-processo="dadosProcesso.numero_processo"
          :tipo-processo="dadosProcesso.tipo_processo"
          @dfd-criado="dfdCriado"
          @cancelar="voltarEtapa"
        />
      </div>

      <!-- Etapa 3: Seleção de Produtos Aprovados (apenas para padronização) -->
      <div v-if="etapaAtual === 2 && dadosProcesso.tipo_processo === 'padronizacao'" class="etapa-conteudo">
        <h3>📦 Selecionar Produtos para Pré-qualificação</h3>
        <div class="produtos-configuracao">
          <div class="produtos-header">
            <h4>Selecione os produtos já aprovados pela CPM:</h4>
            <button @click="abrirSeletorProdutos" class="btn-adicionar" :disabled="carregandoProdutos">
              {{ carregandoProdutos ? '🔄 Carregando...' : '➕ Selecionar Produtos' }}
            </button>
          </div>

          <!-- Lista de Produtos Aprovados Disponíveis -->
          <div v-if="mostrarSeletorProdutos" class="produtos-disponiveis">
            <h4>🔍 Produtos Aprovados Disponíveis:</h4>
            <div v-if="produtosAprovados.length === 0" class="produtos-vazio">
              <div class="vazio-icon">⚠️</div>
              <p>Nenhum produto aprovado encontrado</p>
              <small>Produtos devem ser cadastrados e aprovados pela CPM primeiro</small>
            </div>
            <div v-else class="produtos-grid">
              <div 
                v-for="produto in produtosAprovados" 
                :key="produto.id"
                class="produto-disponivel"
                :class="{ selecionado: produtosSelecionados.includes(produto.id) }"
                @click="toggleProdutoSelecionado(produto)"
              >
                <div class="produto-info">
                  <h5>{{ produto.nome }}</h5>
                  <p class="produto-fabricante">{{ produto.fabricante }}</p>
                  <p class="produto-categoria">{{ produto.categoria }}</p>
                  <p class="produto-status">✅ Aprovado pela CPM</p>
                </div>
                <div class="produto-checkbox">
                  <input 
                    type="checkbox" 
                    :checked="produtosSelecionados.includes(produto.id)"
                    @change="toggleProdutoSelecionado(produto)"
                  >
                </div>
              </div>
            </div>
            <div class="seletor-acoes">
              <button @click="confirmarSelecaoProdutos" class="btn-primary" :disabled="produtosSelecionados.length === 0">
                ✅ Confirmar Seleção ({{ produtosSelecionados.length }} produtos)
              </button>
              <button @click="cancelarSelecaoProdutos" class="btn-secondary">
                ❌ Cancelar
              </button>
            </div>
          </div>

          <!-- Lista de Produtos Selecionados -->
          <div v-if="produtos.length === 0 && !mostrarSeletorProdutos" class="produtos-vazio">
            <div class="vazio-icon">📦</div>
            <p>Nenhum produto selecionado ainda</p>
            <button @click="abrirSeletorProdutos" class="btn-primary">
              Selecionar Produtos Aprovados
            </button>
          </div>

          <div v-else-if="!mostrarSeletorProdutos" class="produtos-selecionados">
            <h4>📋 Produtos Selecionados para Pré-qualificação:</h4>
            <div class="produtos-lista">
              <div 
                v-for="(produto, index) in produtos" 
                :key="produto.id || index"
                class="produto-item selecionado"
              >
                <div class="produto-header">
                  <div class="produto-info-header">
                    <h5>{{ produto.nome_produto || produto.nome }}</h5>
                    <span class="produto-badge">✅ Aprovado</span>
                  </div>
                  <button @click="removerProdutoSelecionado(index)" class="btn-remover" title="Remover da seleção">🗑️</button>
                </div>
                
                <div class="produto-detalhes">
                  <div class="produto-info-grid">
                    <div class="info-item">
                      <strong>Fabricante:</strong> {{ produto.fabricante || 'N/A' }}
                    </div>
                    <div class="info-item">
                      <strong>Categoria:</strong> {{ produto.categoria || produto.categoria_produto || 'N/A' }}
                    </div>
                    <div class="info-item">
                      <strong>Especificações:</strong> 
                      <p>{{ produto.especificacoes || produto.especificacoes_tecnicas || 'Ver cadastro completo' }}</p>
                    </div>
                  </div>
                  
                  <!-- Campos específicos do processo -->
                  <div class="produto-processo-info">
                    <h6>📋 Informações Específicas do Processo:</h6>
                    <div class="form-row">
                      <div class="form-group">
                        <label>Quantidade de Amostras Necessárias</label>
                        <input 
                          type="number" 
                          v-model.number="produto.quantidade_amostras" 
                          placeholder="Ex: 3"
                          min="0"
                        >
                      </div>
                      
                      <div class="form-group">
                        <label>Valor Estimado para Amostras (R$)</label>
                        <input 
                          type="number" 
                          step="0.01"
                          v-model.number="produto.valor_estimado" 
                          placeholder="0.00"
                          min="0"
                        >
                      </div>
                    </div>
                    
                    <div class="form-group">
                      <label>Observações Específicas (opcional)</label>
                      <textarea 
                        v-model="produto.observacoes_processo" 
                        rows="2"
                        placeholder="Observações específicas para este processo..."
                      ></textarea>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Etapa 4: Folha de Rosto -->
      <div v-if="etapaAtual === (dadosProcesso.tipo_processo === 'padronizacao' ? 3 : 2)" class="etapa-conteudo">
        <h3>📋 Folha de Rosto do Processo</h3>
        <div class="folha-rosto-container">
          <div class="folha-rosto-info">
            <p>A folha de rosto será gerada automaticamente com base nos dados informados.</p>
            <p><strong>Número do Processo:</strong> {{ numeroProcesso }}</p>
            <p><strong>Tipo:</strong> {{ dadosProcesso.tipo_processo === 'padronizacao' ? 'Padronização' : 'Despadronização' }}</p>
          </div>
          
          <div class="folha-rosto-preview">
            <FolhaRosto 
              :numeroProcesso="dadosProcesso.numero_processo"
              :tipoProcesso="dadosProcesso.tipo_processo"
              :dadosOrgao="{
                nome: dadosProcesso.nome_orgao,
                departamento: 'DEPARTAMENTO DE COMPRAS E LICITAÇÕES',
                unidade_interessada: dadosProcesso.unidade_interessada
              }"
            />
          </div>
        </div>
      </div>

      <!-- Etapa 5: Revisão e Finalização -->
      <div v-if="etapaAtual === (dadosProcesso.tipo_processo === 'padronizacao' ? 4 : 3)" class="etapa-conteudo">
        <h3>✅ Revisão e Finalização</h3>
        <div class="revisao-container">
          <div class="revisao-secao">
            <h4>📋 Dados do Processo</h4>
            <div class="revisao-item">
              <strong>Número do Processo:</strong> {{ dadosProcesso.numero_processo }}
            </div>
            <div class="revisao-item">
              <strong>Tipo:</strong> 
              {{ dadosProcesso.tipo_processo === 'padronizacao' ? 'Padronização' : 'Despadronização' }}
            </div>
            <div class="revisao-item">
              <strong>Órgão:</strong> {{ dadosProcesso.nome_orgao }}
            </div>
            <div class="revisao-item">
              <strong>Unidade Interessada:</strong> {{ dadosProcesso.unidade_interessada }}
            </div>
            <div v-if="dadosProcesso.observacoes" class="revisao-item">
              <strong>Observações:</strong> {{ dadosProcesso.observacoes }}
            </div>
          </div>

          <div class="revisao-secao">
            <h4>📄 DFD Criado</h4>
            <div class="revisao-item">
              <strong>Status:</strong> 
              <span class="status-badge green">✅ DFD Criado com Sucesso</span>
            </div>
            <div class="revisao-item">
              <strong>Modelo:</strong> {{ dfdCriada?.dfd?.modelo_usado?.toUpperCase() }}
            </div>
          </div>

          <div v-if="dadosProcesso.tipo_processo === 'padronizacao' && produtos.length > 0" class="revisao-secao">
            <h4>📦 Produtos Configurados</h4>
            <div class="revisao-item">
              <strong>Total de Produtos:</strong> {{ produtos.length }}
            </div>
            <div class="produtos-resumo">
              <div 
                v-for="(produto, index) in produtos" 
                :key="index"
                class="produto-resumo"
              >
                <strong>{{ produto.nome_produto }}</strong>
                <span v-if="produto.marca">- {{ produto.marca }}</span>
                <span v-if="produto.modelo">{{ produto.modelo }}</span>
              </div>
            </div>
          </div>

          <div class="proximos-passos">
            <h4>🎯 Próximos Passos</h4>
            <div v-if="dadosProcesso.tipo_processo === 'padronizacao'" class="passos-lista">
              <div class="passo-item">
                <div class="passo-numero">1</div>
                <div class="passo-texto">Criação do Edital de Chamamento Público</div>
              </div>
              <div class="passo-item">
                <div class="passo-numero">2</div>
                <div class="passo-texto">Publicação do Aviso no Diário Oficial</div>
              </div>
              <div class="passo-item">
                <div class="passo-numero">3</div>
                <div class="passo-texto">Recebimento e Análise de Propostas</div>
              </div>
              <div class="passo-item">
                <div class="passo-numero">4</div>
                <div class="passo-texto">Análise Técnica pela CPPM</div>
              </div>
              <div class="passo-item">
                <div class="passo-numero">5</div>
                <div class="passo-texto">Julgamento pela CCL</div>
              </div>
              <div class="passo-item">
                <div class="passo-numero">6</div>
                <div class="passo-texto">Emissão das DCBs e Inclusão no Catálogo</div>
              </div>
            </div>
            <div v-else class="passos-lista">
              <div class="passo-item">
                <div class="passo-numero">1</div>
                <div class="passo-texto">Elaboração do Relatório de Problemas</div>
              </div>
              <div class="passo-item">
                <div class="passo-numero">2</div>
                <div class="passo-texto">Análise pela CCL</div>
              </div>
              <div class="passo-item">
                <div class="passo-numero">3</div>
                <div class="passo-texto">Remoção dos Produtos do Catálogo</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="assistente-acoes">
      <button 
        v-if="etapaAtual > 0" 
        @click="voltarEtapa" 
        class="btn-secondary"
        :disabled="processando"
      >
        ← Voltar
      </button>
      
      <div class="acoes-direita">
        <button 
          v-if="etapaAtual < etapas.length - 1" 
          @click="proximaEtapa" 
          class="btn-primary"
          :disabled="!podeAvancar || processando"
        >
          {{ processando ? 'Processando...' : 'Próximo →' }}
        </button>
        
        <button 
          v-if="etapaAtual === etapas.length - 1" 
          @click="finalizarProcesso" 
          class="btn-primary"
          :disabled="processando"
        >
          {{ processando ? 'Finalizando...' : '🎉 Finalizar Processo' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import ProcessosAdministrativosService from '../../services/processosAdministrativosService'
import FormularioDFD from './FormularioDFD.vue'
import FolhaRosto from './FolhaRosto.vue'
import { supabase } from '../../services/supabase'

export default {
  name: 'AssistenteProcesso',
  components: {
    FormularioDFD,
    FolhaRosto
  },
  data() {
    return {
      etapaAtual: 0,
      processando: false,
      processoTemporario: null,
      dfdCriada: null,
      
      dadosProcesso: {
        tipo_processo: '',
        numero_processo: '',
        nome_orgao: '',
        unidade_interessada: '',
        observacoes: ''
      },
      
      produtos: [],
      
      // Novos campos para seleção de produtos aprovados
      produtosAprovados: [],
      produtosSelecionados: [],
      mostrarSeletorProdutos: false,
      carregandoProdutos: false
    }
  },
  
  computed: {
    etapas() {
      const etapasBase = [
        {
          titulo: 'Informações Básicas',
          descricao: 'Tipo de processo e dados do órgão'
        },
        {
          titulo: 'DFD',
          descricao: 'Documento de Formalização de Demanda'
        }
      ]
      
      if (this.dadosProcesso.tipo_processo === 'padronizacao') {
        etapasBase.push({
          titulo: 'Produtos',
          descricao: 'Configuração dos produtos'
        })
      }
      
      etapasBase.push({
        titulo: 'Folha de Rosto',
        descricao: 'Capa do processo administrativo'
      })
      
      etapasBase.push({
        titulo: 'Finalização',
        descricao: 'Revisão e conclusão'
      })
      
      return etapasBase
    },
    
    podeAvancar() {
      switch (this.etapaAtual) {
        case 0:
          return this.dadosProcesso.tipo_processo && 
                 this.dadosProcesso.numero_processo &&
                 this.dadosProcesso.nome_orgao && 
                 this.dadosProcesso.unidade_interessada
        case 1:
          return this.dfdCriada
        case 2:
          if (this.dadosProcesso.tipo_processo === 'padronizacao') {
            return this.produtos.length > 0 && this.produtos.every(p => p.nome_produto)
          }
          return true
        case 3:
          // Etapa da folha de rosto - sempre pode avançar pois número já foi definido na etapa 0
          return true
        default:
          return true
      }
    }
  },
  
  methods: {
    selecionarTipo(tipo) {
      this.dadosProcesso.tipo_processo = tipo
    },
    
    async proximaEtapa() {
      if (this.etapaAtual === 0) {
        // Criar processo temporário
        await this.criarProcessoTemporario()
      }
      
      if (this.etapaAtual === 2 && this.dadosProcesso.tipo_processo === 'padronizacao') {
        // Salvar produtos
        await this.salvarProdutos()
      }
      
      this.etapaAtual++
    },
    
    voltarEtapa() {
      if (this.etapaAtual > 0) {
        this.etapaAtual--
      }
    },
    
    async criarProcessoTemporario() {
      try {
        this.processando = true
        this.processoTemporario = await ProcessosAdministrativosService.criarProcesso(this.dadosProcesso)
      } catch (error) {
        console.error('Erro ao criar processo:', error)
        alert('Erro ao criar processo: ' + error.message)
        throw error
      } finally {
        this.processando = false
      }
    },
    
    dfdCriado(resultado) {
      this.dfdCriada = resultado
      this.proximaEtapa()
    },
    
    // NOVOS MÉTODOS para seleção de produtos aprovados
    async abrirSeletorProdutos() {
      this.mostrarSeletorProdutos = true
      await this.carregarProdutosAprovados()
    },
    
    async carregarProdutosAprovados() {
      try {
        this.carregandoProdutos = true
        
        // Buscar produtos aprovados pela CPM
        const { data, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', await this.getTenantId())
          .eq('status', 'aprovado')
          .order('nome', { ascending: true })
        
        if (error) {
          console.error('Erro ao carregar produtos aprovados:', error)
          throw error
        }
        
        this.produtosAprovados = data || []
        
      } catch (error) {
        console.error('Erro ao carregar produtos aprovados:', error)
        alert('Erro ao carregar produtos aprovados: ' + error.message)
      } finally {
        this.carregandoProdutos = false
      }
    },
    
    toggleProdutoSelecionado(produto) {
      const index = this.produtosSelecionados.indexOf(produto.id)
      if (index > -1) {
        this.produtosSelecionados.splice(index, 1)
      } else {
        this.produtosSelecionados.push(produto.id)
      }
    },
    
    confirmarSelecaoProdutos() {
      // Converter produtos selecionados para formato do processo
      this.produtos = this.produtosAprovados
        .filter(produto => this.produtosSelecionados.includes(produto.id))
        .map(produto => ({
          ...produto,
          nome_produto: produto.nome,
          categoria_produto: produto.categoria,
          especificacoes_tecnicas: produto.especificacoes,
          quantidade_amostras: 0,
          valor_estimado: null,
          observacoes_processo: ''
        }))
      
      this.mostrarSeletorProdutos = false
      this.produtosSelecionados = []
    },
    
    cancelarSelecaoProdutos() {
      this.mostrarSeletorProdutos = false
      this.produtosSelecionados = []
    },
    
    removerProdutoSelecionado(index) {
      this.produtos.splice(index, 1)
    },
    
    async getTenantId() {
      // Método helper para obter tenant_id
      const { data: sessionData } = await supabase.auth.getSession()
      const user = sessionData?.session?.user
      return user?.user_metadata?.tenant_id
    },
    
    async salvarProdutos() {
      try {
        this.processando = true
        
        for (const produto of this.produtos) {
          try {
            await ProcessosAdministrativosService.adicionarProduto(
              this.processoTemporario.id, 
              produto
            )
          } catch (error) {
            if (error.code === 'PRODUTO_JA_USADO') {
              // Produto já foi usado, perguntar se quer forçar
              const confirmar = confirm(
                `⚠️ PRODUTO JÁ UTILIZADO\n\n` +
                `O produto "${produto.nome_produto || produto.nome}" já foi usado em outro processo de pré-qualificação.\n\n` +
                `Deseja reutilizá-lo mesmo assim neste processo?\n\n` +
                `Clique OK para REUTILIZAR ou Cancelar para PARAR`
              )
              
              if (confirmar) {
                // Forçar inserção removendo o ID para criar um novo registro
                const produtoNovo = { ...produto }
                delete produtoNovo.id // Remove o ID para criar novo registro
                
                await ProcessosAdministrativosService.adicionarProduto(
                  this.processoTemporario.id, 
                  produtoNovo,
                  true // forçar inserção
                )
              } else {
                throw new Error(`Operação cancelada pelo usuário para o produto: ${produto.nome_produto || produto.nome}`)
              }
            } else {
              throw error
            }
          }
        }
      } catch (error) {
        console.error('Erro ao salvar produtos:', error)
        alert('Erro ao salvar produtos: ' + error.message)
        throw error
      } finally {
        this.processando = false
      }
    },
    
    async finalizarProcesso() {
      try {
        this.processando = true
        
        // Atualizar status do processo para "aguardando_aprovacao"
        await ProcessosAdministrativosService.atualizarProcesso(
          this.processoTemporario.id,
          { status: 'aguardando_aprovacao' }
        )
        
        this.$emit('processo-criado', this.processoTemporario)
        
      } catch (error) {
        console.error('Erro ao finalizar processo:', error)
        alert('Erro ao finalizar processo: ' + error.message)
      } finally {
        this.processando = false
      }
    }
  }
}
</script>

<style scoped>
.assistente-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  background: white;
  min-height: 100vh;
}

.assistente-header {
  margin-bottom: 3rem;
}

.assistente-header h2 {
  text-align: center;
  color: #2d3748;
  margin-bottom: 2rem;
}

.progresso {
  position: relative;
}

.etapas {
  display: flex;
  justify-content: space-between;
  position: relative;
  z-index: 2;
}

.etapa {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
  opacity: 0.5;
  transition: all 0.3s ease;
}

.etapa.active,
.etapa.completed {
  opacity: 1;
}

.etapa-numero {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: #e2e8f0;
  color: #718096;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 1.2rem;
  margin-bottom: 1rem;
  transition: all 0.3s ease;
}

.etapa.active .etapa-numero {
  background: #2c3e50;
  color: white;
}

.etapa.completed .etapa-numero {
  background: #48bb78;
  color: white;
}

.etapa-info {
  text-align: center;
}

.etapa-titulo {
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 0.25rem;
}

.etapa-desc {
  font-size: 0.85rem;
  color: #718096;
}

.barra-progresso {
  position: absolute;
  top: 25px;
  left: 25px;
  right: 25px;
  height: 3px;
  background: #e2e8f0;
  z-index: 1;
  border-radius: 2px;
}

.progresso-fill {
  height: 100%;
  background: #2c3e50;
  border-radius: 2px;
  transition: width 0.5s ease;
}

.etapa-conteudo {
  background: white;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  padding: 2rem;
  margin-bottom: 2rem;
  min-height: 400px;
  max-height: 70vh;
  overflow-y: auto;
}

.etapa-conteudo h3 {
  color: #2d3748;
  margin-bottom: 2rem;
}

.tipos-opcoes {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  margin-bottom: 2rem;
}

.tipo-opcao {
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: center;
}

.tipo-opcao:hover {
  border-color: #cbd5e0;
  transform: translateY(-2px);
}

.tipo-opcao.selected {
  border-color: #2c3e50;
  background: #f0f9ff;
  box-shadow: 0 4px 12px rgba(44, 62, 80, 0.1);
}

.tipo-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.tipo-info h5 {
  color: #2d3748;
  margin-bottom: 0.5rem;
  font-size: 1.2rem;
}

.tipo-info p {
  color: #718096;
  margin-bottom: 1rem;
}

.tipo-fluxo {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.fluxo-item {
  background: #e2e8f0;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
  color: #4a5568;
}

.fluxo-arrow {
  color: #a0aec0;
}

.dados-basicos {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid #e2e8f0;
}

.dados-basicos h4 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #374151;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: border-color 0.3s ease;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #2c3e50;
  box-shadow: 0 0 0 3px rgba(44, 62, 80, 0.1);
}

.field-hint {
  display: block;
  margin-top: 0.25rem;
  font-size: 0.8rem;
  color: #6b7280;
  font-style: italic;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.produtos-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.produtos-header h4 {
  color: #2d3748;
  margin: 0;
}

.btn-adicionar {
  background: #48bb78;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
}

.btn-adicionar:hover {
  background: #38a169;
  transform: translateY(-1px);
}

.produtos-vazio {
  text-align: center;
  padding: 3rem;
  color: #718096;
}

.vazio-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.produtos-lista {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.produto-item {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  background: #f8fafc;
}

.produto-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.produto-header h5 {
  color: #2d3748;
  margin: 0;
}

.btn-remover {
  background: #fed7d7;
  color: #e53e3e;
  border: none;
  padding: 0.5rem;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-remover:hover {
  background: #feb2b2;
}

.revisao-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.revisao-secao {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
}

.revisao-secao h4 {
  color: #2d3748;
  margin: 0 0 1rem 0;
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 0.5rem;
}

.revisao-item {
  margin-bottom: 0.75rem;
  display: flex;
  gap: 0.5rem;
}

.revisao-item strong {
  color: #4a5568;
  min-width: 150px;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 600;
}

.status-badge.green {
  background: #c6f6d5;
  color: #22543d;
}

.produtos-resumo {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 1rem;
}

.produto-resumo {
  padding: 0.5rem;
  background: white;
  border-radius: 4px;
  border: 1px solid #e2e8f0;
}

.passos-lista {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.passo-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.passo-numero {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: #2c3e50;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  flex-shrink: 0;
}

.passo-texto {
  color: #4a5568;
  font-weight: 500;
}

.assistente-acoes {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 2rem;
  border-top: 1px solid #e2e8f0;
  background: #f8fafc;
  border-radius: 0 0 12px 12px;
  margin-top: 2rem;
}

.acoes-direita {
  display: flex;
  gap: 1rem;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 2rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  border: none;
}

.btn-primary {
  background: #2c3e50;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #34495e;
  transform: translateY(-1px);
}

.btn-primary:disabled {
  background: #a0aec0;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover:not(:disabled) {
  background: #cbd5e0;
}

/* Melhorias para formulários longos */
.produtos-configuracao {
  max-height: 50vh;
  overflow-y: auto;
  padding-right: 0.5rem;
}

.produtos-lista {
  padding-bottom: 1rem;
}

/* Scrollbar customizada */
.etapa-conteudo::-webkit-scrollbar,
.produtos-configuracao::-webkit-scrollbar {
  width: 8px;
}

.etapa-conteudo::-webkit-scrollbar-track,
.produtos-configuracao::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.etapa-conteudo::-webkit-scrollbar-thumb,
.produtos-configuracao::-webkit-scrollbar-thumb {
  background: #cbd5e0;
  border-radius: 4px;
}

.etapa-conteudo::-webkit-scrollbar-thumb:hover,
.produtos-configuracao::-webkit-scrollbar-thumb:hover {
  background: #a0aec0;
}

/* NOVOS ESTILOS para seleção de produtos aprovados */
.produtos-disponiveis {
  background: #f8f9fa;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  margin: 1rem 0;
}

.produtos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin: 1rem 0;
}

.produto-disponivel {
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.produto-disponivel:hover {
  border-color: #cbd5e0;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.produto-disponivel.selecionado {
  border-color: #2c3e50;
  background: #f0f9ff;
  box-shadow: 0 4px 12px rgba(44, 62, 80, 0.15);
}

.produto-info h5 {
  color: #2d3748;
  margin: 0 0 0.5rem 0;
  font-size: 1.1rem;
}

.produto-fabricante {
  color: #4a5568;
  font-weight: 600;
  margin: 0.25rem 0;
}

.produto-categoria {
  color: #718096;
  font-size: 0.9rem;
  margin: 0.25rem 0;
}

.produto-status {
  color: #48bb78;
  font-size: 0.85rem;
  font-weight: 600;
  margin: 0.5rem 0 0 0;
}

.produto-checkbox input {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.seletor-acoes {
  display: flex;
  gap: 1rem;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}

.produtos-selecionados {
  background: #f8f9fa;
  border-radius: 12px;
  padding: 1.5rem;
  margin-top: 1rem;
}

.produto-item.selecionado {
  background: white;
  border: 2px solid #48bb78;
  box-shadow: 0 4px 12px rgba(72, 187, 120, 0.1);
}

.produto-info-header {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.produto-badge {
  background: #48bb78;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 600;
}

.produto-info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.info-item strong {
  color: #2d3748;
  font-size: 0.9rem;
}

.info-item p {
  color: #4a5568;
  font-size: 0.85rem;
  margin: 0;
}

.produto-processo-info {
  background: #e6fffa;
  border: 1px solid #b2f5ea;
  border-radius: 8px;
  padding: 1rem;
  margin-top: 1rem;
}

.produto-processo-info h6 {
  color: #2d3748;
  margin: 0 0 1rem 0;
  font-size: 1rem;
}

.folha-rosto-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.folha-rosto-info {
  background: #f8f9fa;
  padding: 1.5rem;
  border-radius: 12px;
  border-left: 4px solid #2c3e50;
}

.folha-rosto-info p {
  margin: 0.5rem 0;
  color: #4a5568;
}

.folha-rosto-preview {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  max-height: 80vh;
  overflow-y: auto;
}

@media (max-width: 768px) {
  .assistente-container {
    padding: 1rem;
  }
  
  .etapa-conteudo {
    max-height: 80vh;
  }

  .produtos-configuracao {
    max-height: 60vh;
  }

  .tipos-opcoes {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .etapas {
    flex-direction: column;
    gap: 1rem;
  }

  .barra-progresso {
    display: none;
  }

  .produtos-header {
    flex-direction: column;
    align-items: stretch;
    gap: 1rem;
  }

  .assistente-acoes {
    flex-direction: column;
    gap: 1rem;
  }

  .acoes-direita {
    width: 100%;
    justify-content: stretch;
  }

  .acoes-direita button {
    flex: 1;
  }
}
</style>