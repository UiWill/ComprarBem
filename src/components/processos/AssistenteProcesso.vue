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
      <!-- Etapa 0: Folha de Rosto -->
      <div v-if="etapaAtual === 0" class="etapa-conteudo">
        <div class="etapa-header-numeracao">
          <span class="numero-pagina">Página 1</span>
          <h3>📋 Folha de Rosto do Processo</h3>
        </div>
        <div class="tipo-processo-container">
          <div class="tipo-processo-escolha">
            <h4>Escolha o tipo de processo:</h4>
            <div class="tipos-opcoes">
              <!-- Mostrar apenas Padronização se nenhum tipo foi escolhido, ou se Padronização foi escolhido -->
              <div 
                v-if="!dadosProcesso.tipo_processo || dadosProcesso.tipo_processo === 'padronizacao'"
                class="tipo-opcao" 
                :class="{ selected: dadosProcesso.tipo_processo === 'padronizacao' }"
                @click="selecionarTipo('padronizacao')"
              >
                <div class="tipo-icon">✅</div>
                <div class="tipo-info">
                  <h5>Padronização</h5>
                  <p>Incluir marcas de produtos no Catálogo Eletrônico</p>
                  <div class="tipo-fluxo tipo-fluxo-verde">
                    <span class="fluxo-item">DFD</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Edital</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Relatório CPM</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Ata CCL</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Homologação</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">DCB</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Catálogo</span>
                  </div>
                </div>
              </div>
              
              <!-- Mostrar apenas Despadronização se nenhum tipo foi escolhido, ou se Despadronização foi escolhido -->
              <div 
                v-if="!dadosProcesso.tipo_processo || dadosProcesso.tipo_processo === 'despadronizacao'"
                class="tipo-opcao" 
                :class="{ selected: dadosProcesso.tipo_processo === 'despadronizacao' }"
                @click="selecionarTipo('despadronizacao')"
              >
                <div class="tipo-icon">❌</div>
                <div class="tipo-info">
                  <h5>Despadronização</h5>
                  <p>Excluir marcas de produtos do Catálogo Eletrônico</p>
                  <div class="tipo-fluxo tipo-fluxo-vermelho">
                    <span class="fluxo-item">DFD</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Relatório CPM</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Ata CCL</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Homologação</span>
                    <span class="fluxo-arrow">→</span>
                    <span class="fluxo-item">Catálogo</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Campos da Folha de Rosto -->
          <div v-if="dadosProcesso.tipo_processo" class="folha-rosto-campos">
            <h4>📋 Dados da Folha de Rosto:</h4>
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
              <label>Data de Autuação *</label>
              <input 
                type="date" 
                v-model="dadosProcesso.data_autuacao" 
                required
              >
            </div>
            
            <!-- Preview da Folha de Rosto -->
            <div class="folha-rosto-preview-mini">
              <h4>🔍 Preview da Folha de Rosto:</h4>
              <div class="preview-container">
                <FolhaRosto 
                  :numeroProcesso="dadosProcesso.numero_processo"
                  :tipoProcesso="dadosProcesso.tipo_processo"
                  :dataInicio="formatarDataBrasileira(dadosProcesso.data_autuacao)"
                  :dadosOrgao="{
                    nome: dadosProcesso.nome_orgao,
                    unidade_interessada: dadosProcesso.unidade_interessada
                  }"
                  :observacoes="dadosProcesso.observacoes"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Etapa 1: Informações Básicas -->
      <div v-if="etapaAtual === 1" class="etapa-conteudo">
        <div class="etapa-header-numeracao">
          <span class="numero-pagina">Página 2</span>
          <h3>📋 Informações Básicas do Processo</h3>
        </div>
        
        <div class="resumo-processo">
          <h4>📄 Resumo dos Dados Informados:</h4>
          <div class="info-grid">
            <div class="info-item">
              <strong>Número do Processo:</strong>
              <span>{{ dadosProcesso.numero_processo }}</span>
            </div>
            <div class="info-item">
              <strong>Tipo de Processo:</strong>
              <span>{{ dadosProcesso.tipo_processo === 'padronizacao' ? 'Padronização' : 'Despadronização' }}</span>
            </div>
            <div class="info-item">
              <strong>Nome do Órgão:</strong>
              <span>{{ dadosProcesso.nome_orgao }}</span>
            </div>
            <div class="info-item">
              <strong>Unidade Interessada:</strong>
              <span>{{ dadosProcesso.unidade_interessada }}</span>
            </div>
            <div class="info-item">
              <strong>Data de Autuação:</strong>
              <span>{{ formatarDataBrasileira(dadosProcesso.data_autuacao) }}</span>
            </div>
          </div>
        </div>
        
        <div class="observacoes-adicionais">
          <h4>💬 Observações Adicionais (opcional):</h4>
          <div class="form-group">
            <label>Observações sobre o processo</label>
            <textarea 
              v-model="dadosProcesso.observacoes" 
              rows="4"
              placeholder="Adicione observações especiais sobre este processo, instruções para a equipe, detalhes importantes, etc..."
            ></textarea>
          </div>
          
          <div class="dica-observacoes">
            <div class="dica-icon">💡</div>
            <div class="dica-texto">
              <strong>Dica:</strong> Use este campo para adicionar informações que serão úteis durante o processo, como:
              <ul>
                <li>Prioridades especiais</li>
                <li>Prazos específicos</li>
                <li>Contatos responsáveis</li>
                <li>Observações técnicas</li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- Etapa 2: DFD -->
      <div v-if="etapaAtual === 2" class="etapa-conteudo">
        <div class="etapa-header-numeracao">
          <span class="numero-pagina">Página 3</span>
          <h3>📄 Documento de Formalização de Demanda</h3>
        </div>
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
      <div v-if="etapaAtual === 3 && dadosProcesso.tipo_processo === 'padronizacao'" class="etapa-conteudo">
        <div class="etapa-header-numeracao">
          <span class="numero-pagina">Página 4</span>
          <h3>📦 Selecionar Produtos para Pré-qualificação</h3>
        </div>
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
                      <div class="especificacoes-content">
                        <p>{{ produto.especificacoes_tecnicas }}</p>
                        <button 
                          v-if="produto.especificacoes_tecnicas === 'Especificações não disponíveis'"
                          @click="verCadastroCompleto(produto)" 
                          class="btn-ver-cadastro"
                        >
                          📋 Ver Cadastro Completo
                        </button>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Campos específicos do processo -->
                  <!-- Documentos do Produto -->
                  <div v-if="produto.documentos && produto.documentos.length > 0" class="produto-documentos">
                    <h6>📄 Documentos do Produto:</h6>
                    <div class="documentos-produto-grid">
                      <div 
                        v-for="doc in produto.documentos" 
                        :key="doc.id"
                        class="documento-produto-item"
                      >
                        <div class="doc-icon">📄</div>
                        <div class="doc-info">
                          <strong>{{ doc.nome }}</strong>
                          <small>{{ doc.tipo }}</small>
                        </div>
                        <div class="doc-actions">
                          <a :href="doc.arquivo_url" target="_blank" class="btn-visualizar-doc">
                            👁️ Ver
                          </a>
                          <button 
                            @click="adicionarDocumentoProcesso(doc, index)" 
                            class="btn-adicionar-doc"
                            :class="{ 'adicionado': produto.documentos_adicionados && produto.documentos_adicionados.includes(doc.id) }"
                          >
                            {{ produto.documentos_adicionados && produto.documentos_adicionados.includes(doc.id) ? '✅ Adicionado' : '➕ Adicionar' }}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                  
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

      <!-- Etapa final: Documentação -->
      <div v-if="etapaAtual === (dadosProcesso.tipo_processo === 'padronizacao' ? 4 : 3)" class="etapa-conteudo">
        <div class="etapa-header-numeracao">
          <span class="numero-pagina">Página {{ dadosProcesso.tipo_processo === 'padronizacao' ? '5+' : '4+' }}</span>
          <h3>📁 Documentação do Processo</h3>
        </div>
        <div class="documentacao-container">
          <div class="documentacao-info">
            <p>Upload dos documentos necessários para completar o processo administrativo.</p>
            <p>Faça o upload de todos os documentos que compõem este processo. Eles serão organizados em formato de caderno eletrônico.</p>
          </div>
          
          <!-- Seção de Vinculação de Edital -->
          <div v-if="dadosProcesso.tipo_processo === 'padronizacao'" class="edital-section">
            <div class="edital-header">
              <h4>📎 Edital de Pré-Qualificação</h4>
              <p>Selecione um edital existente do órgão para vincular ao processo</p>
            </div>
            
            <div v-if="!editalVinculado" class="edital-form">
              <div class="form-group">
                <label>Editais Disponíveis do Órgão</label>
                <button 
                  @click="carregarEditaisDisponiveis" 
                  class="btn-carregar-editais"
                  :disabled="carregandoEditais"
                >
                  {{ carregandoEditais ? '🔄 Carregando...' : '🔍 Buscar Editais' }}
                </button>
              </div>
              
              <div v-if="editaisDisponiveis.length > 0" class="editais-lista">
                <h5>📋 Editais Encontrados:</h5>
                <div class="editais-grid">
                  <div 
                    v-for="edital in editaisDisponiveis" 
                    :key="edital.id"
                    class="edital-item"
                    :class="{ 'selecionado': editalSelecionado && editalSelecionado.id === edital.id }"
                    @click="selecionarEdital(edital)"
                  >
                    <div class="edital-info">
                      <h6>{{ edital.numero_edital }}</h6>
                      <p class="edital-data">{{ formatarData(edital.data_publicacao) }}</p>
                      <p class="edital-tipo">{{ edital.tipo_edital || 'Pré-Qualificação' }}</p>
                      <div v-if="edital.produtos_count" class="edital-produtos">
                        📦 {{ edital.produtos_count }} produtos
                      </div>
                    </div>
                    <div class="edital-status">
                      <span v-if="edital.status === 'ativo'" class="status-ativo">✅ Ativo</span>
                      <span v-else class="status-inativo">⏸️ {{ edital.status }}</span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div v-else-if="editaisCarregados && editaisDisponiveis.length === 0" class="editais-vazio">
                <div class="vazio-icon">📄</div>
                <p>Nenhum edital encontrado para este órgão</p>
                <small>Verifique se há editais cadastrados no sistema</small>
              </div>
              
              <div v-if="editalSelecionado" class="edital-selecionado">
                <h5>📎 Edital Selecionado:</h5>
                <div class="edital-preview">
                  <div class="preview-info">
                    <strong>{{ editalSelecionado.numero_edital }}</strong>
                    <p>Data: {{ formatarData(editalSelecionado.data_publicacao) }}</p>
                    <p v-if="editalSelecionado.descricao">{{ editalSelecionado.descricao }}</p>
                  </div>
                  <div class="preview-acoes">
                    <a v-if="editalSelecionado.arquivo_url" :href="editalSelecionado.arquivo_url" target="_blank" class="btn-ver-edital">
                      👁️ Ver PDF
                    </a>
                    <div v-else class="aviso-pdf">
                      📄 PDF não disponível para visualização
                    </div>
                    <button @click="editalSelecionado = null" class="btn-remover-selecao">
                      🗑️ Remover
                    </button>
                  </div>
                </div>
              </div>
              
              <div class="edital-acao">
                <button 
                  @click="vincularEditalSelecionado" 
                  class="btn-vincular-edital"
                  :disabled="!editalSelecionado || processando"
                >
                  {{ processando ? '🔄 Vinculando...' : '📎 Vincular Edital Selecionado' }}
                </button>
              </div>
            </div>
            
            <div v-else class="edital-vinculado">
              <div class="vinculado-success">
                <div class="success-icon">✅</div>
                <div class="success-info">
                  <h5>Edital Vinculado com Sucesso</h5>
                  <p><strong>Número:</strong> {{ dadosProcesso.numero_edital }}</p>
                  <p v-if="dadosProcesso.data_vinculacao_edital">
                    <strong>Data:</strong> {{ formatarData(dadosProcesso.data_vinculacao_edital) }}
                  </p>
                </div>
                <button @click="editarEdital" class="btn-editar-edital">✏️ Editar</button>
              </div>
            </div>
          </div>
          
          <div class="documentos-section">
            <div class="documentos-header">
              <h4>📄 Documentos do Processo</h4>
              <button @click="adicionarDocumento" class="btn-adicionar">
                ➕ Adicionar Documento
              </button>
            </div>
            
            <div v-if="documentos.length === 0" class="documentos-vazio">
              <div class="vazio-icon">📄</div>
              <p>Nenhum documento adicionado ainda</p>
              <p><small>Clique em "Adicionar Documento" para fazer upload dos arquivos</small></p>
            </div>
            
            <div v-else class="documentos-lista">
              <div 
                v-for="(documento, index) in documentos" 
                :key="index"
                class="documento-item"
              >
                <div class="documento-info">
                  <div class="documento-icon">📄</div>
                  <div class="documento-detalhes">
                    <h5>{{ documento.nome }}</h5>
                    <p class="documento-tipo">{{ documento.tipo }}</p>
                    <p class="documento-data">Adicionado em: {{ formatarData(documento.data_upload) }}</p>
                  </div>
                </div>
                <div class="documento-acoes">
                  <button @click="visualizarDocumento(documento)" class="btn-visualizar">👁️ Ver</button>
                  <button @click="removerDocumento(index)" class="btn-remover">🗑️ Remover</button>
                </div>
              </div>
            </div>
            
            <!-- Numeração automática -->
            <div class="numeracao-info">
              <h4>📊 Numeração Automática - Caderno Eletrônico</h4>
              <p>O sistema numera automaticamente todas as páginas do processo:</p>
              <div class="exemplo-numeracao">
                <div class="paginas-fixas">
                  <strong>Páginas Fixas:</strong>
                  <ul>
                    <li>Página 1: Folha de Rosto</li>
                    <li>Página 2: Informações Básicas</li>
                    <li>Página 3: DFD</li>
                    <li v-if="dadosProcesso.tipo_processo === 'padronizacao'">Página 4: Produtos</li>
                  </ul>
                </div>
                <div class="paginas-documentos">
                  <strong>Documentos Adicionais:</strong>
                  <span v-if="documentos.length === 0">
                    Página {{ dadosProcesso.tipo_processo === 'padronizacao' ? '5' : '4' }}+ (conforme documentos adicionados)
                  </span>
                  <ul v-else>
                    <li v-for="(documento, index) in documentos" :key="index">
                      Página {{ (dadosProcesso.tipo_processo === 'padronizacao' ? 5 : 4) + index }}: {{ documento.nome }}
                    </li>
                  </ul>
                </div>
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
  props: {
    // Processo a ser editado (se existir)
    processoEdicao: {
      type: Object,
      default: null
    },
    // Modo de edição ou criação
    modoEdicao: {
      type: Boolean,
      default: false
    },
    // Tipo de processo pré-selecionado (padronizacao ou despadronizacao)
    tipoProcessoInicial: {
      type: String,
      default: null
    }
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
        data_autuacao: new Date().toISOString().split('T')[0], // Data atual no formato YYYY-MM-DD
        observacoes: ''
      },
      
      produtos: [],
      
      // Novos campos para seleção de produtos aprovados
      produtosAprovados: [],
      produtosSelecionados: [],
      mostrarSeletorProdutos: false,
      carregandoProdutos: false,
      
      // Campos para documentação
      documentos: [],
      
      // Campos para edital
      dadosEdital: {
        numero_edital: '',
        data_publicacao: '',
        arquivo: null,
        observacoes: ''
      },
      erroEdital: '',
      dragoverEdital: false,
      
      // Seleção de editais existentes
      editaisDisponiveis: [],
      editalSelecionado: null,
      carregandoEditais: false,
      editaisCarregados: false
    }
  },
  
  computed: {
    etapas() {
      const etapasBase = [
        {
          titulo: 'Folha de Rosto',
          descricao: 'Escolha do tipo e dados iniciais'
        },
        {
          titulo: 'Informações Básicas',
          descricao: 'Dados do órgão e unidade'
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
        titulo: 'Documentação',
        descricao: 'Upload de documentos do processo'
      })
      
      return etapasBase
    },
    
    podeAvancar() {
      switch (this.etapaAtual) {
        case 0:
          // Etapa Folha de Rosto - precisa preencher todos os campos da folha de rosto
          return this.dadosProcesso.tipo_processo && 
                 this.dadosProcesso.numero_processo &&
                 this.dadosProcesso.nome_orgao && 
                 this.dadosProcesso.unidade_interessada &&
                 this.dadosProcesso.data_autuacao
        case 1:
          // Etapa Informações Básicas - sempre pode avançar (apenas observações opcionais)
          return true
        case 2:
          // Etapa DFD
          return this.dfdCriada
        case 3:
          // Etapa Produtos (apenas para padronização)
          if (this.dadosProcesso.tipo_processo === 'padronizacao') {
            return this.produtos.length > 0 && this.produtos.every(p => p.nome_produto)
          }
          return true
        case 4:
          // Etapa Documentação - sempre pode finalizar
          return true
        default:
          return true
      }
    },
    
    editalVinculado() {
      return this.dadosProcesso.edital_vinculado || false
    }
  },
  
  async mounted() {
    // Se estamos criando um NOVO processo (não está em modo edição), começar limpo
    if (!this.modoEdicao) {
      console.log('🆕 CRIANDO NOVO PROCESSO - Iniciando assistente limpo')
      this.etapaAtual = 0
      this.limparDados()
      return
    }
    
    // Se estamos EDITANDO um processo existente, tentar carregar progresso salvo
    console.log('✏️ EDITANDO PROCESSO EXISTENTE - Carregando dados salvos')
    const processoCarregado = await this.carregarProcessoSalvo()
    
    // Se não conseguiu carregar progresso salvo E estamos em modo de edição, carregar dados do processo
    if (!processoCarregado && this.modoEdicao && this.processoEdicao) {
      await this.carregarDadosProcesso()
    }
    
    // Se carregou processo salvo e tem processo temporário, carregar produtos do banco
    if (processoCarregado && (this.processoTemporario?.id || this.processoEdicao?.id)) {
      await this.carregarProdutosProcesso()
      // Redeterminar etapa após carregar produtos
      this.determinarEtapaAtual()
    }
  },
  
  methods: {
    async carregarDadosProcesso() {
      try {
        console.log('Carregando dados do processo:', this.processoEdicao)
        
        // Definir processo temporário para continuar o workflow
        this.processoTemporario = this.processoEdicao
        
        // Carregar dados básicos
        this.dadosProcesso = {
          tipo_processo: this.processoEdicao.tipo_processo || '',
          numero_processo: this.processoEdicao.numero_processo || '',
          nome_orgao: this.processoEdicao.nome_orgao || '',
          unidade_interessada: this.processoEdicao.unidade_interessada || '',
          data_autuacao: this.processoEdicao.data_autuacao ? 
            new Date(this.processoEdicao.data_autuacao).toISOString().split('T')[0] : 
            new Date().toISOString().split('T')[0],
          observacoes: this.processoEdicao.observacoes || '',
          
          // Dados do edital (se existirem)
          numero_edital: this.processoEdicao.numero_edital || '',
          edital_vinculado: this.processoEdicao.edital_vinculado || false,
          data_vinculacao_edital: this.processoEdicao.data_vinculacao_edital || null
        }
        
        // Carregar produtos se for processo de padronização
        if (this.processoEdicao.tipo_processo === 'padronizacao') {
          await this.carregarProdutosProcesso()
        }
        
        // Carregar documentos
        await this.carregarDocumentosProcesso()
        
        // Verificar DFD - se existe DFD, marcar como criado
        this.dfdCriada = { id: 'existing', processo_id: this.processoEdicao.id }
        
        // Determinar etapa atual baseada no status do processo
        this.determinarEtapaAtual()
        
        console.log('Dados carregados com sucesso:', {
          dadosProcesso: this.dadosProcesso,
          produtos: this.produtos,
          documentos: this.documentos,
          etapaAtual: this.etapaAtual
        })
        
      } catch (error) {
        console.error('Erro ao carregar dados do processo:', error)
        alert('Erro ao carregar dados do processo: ' + error.message)
      }
    },
    
    async carregarProdutosProcesso() {
      try {
        // Usar ID correto dependendo do contexto
        const processoId = this.processoEdicao?.id || this.processoTemporario?.id
        if (!processoId) {
          console.warn('Nenhum processo ID disponível para carregar produtos')
          return
        }
        
        const { data, error } = await supabase
          .from('produtos_prequalificacao')
          .select('*')
          .eq('processo_id', processoId)
        
        if (error) throw error
        
        // Carregar produtos e marcar como selecionados
        this.produtos = data?.map(item => ({
          id: item.id,
          nome_produto: item.nome_produto,
          marca: item.marca,
          modelo: item.modelo,
          fabricante: item.fabricante,
          categoria_produto: item.categoria_produto,
          especificacoes_tecnicas: item.especificacoes_tecnicas,
          quantidade_amostras: item.quantidade_amostras || 0,
          valor_estimado: item.valor_estimado || null,
          status_produto: item.status_produto,
          parecer_cppm: item.parecer_cppm,
          observacoes_tecnicas: item.observacoes_tecnicas
        })) || []
        
        // IMPORTANTE: Marcar produtos como selecionados
        this.produtosSelecionados = this.produtos.map(produto => produto.id) || []
        
        console.log(`📦 ${this.produtos.length} produtos carregados e ${this.produtosSelecionados.length} marcados como selecionados`)
        
      } catch (error) {
        console.error('Erro ao carregar produtos do processo:', error)
        this.produtos = []
        this.produtosSelecionados = []
      }
    },
    
    async carregarDocumentosProcesso() {
      try {
        // Usar ID correto dependendo se é edição ou criação
        const processoId = this.processoEdicao?.id || this.processoTemporario?.id
        if (!processoId) {
          console.warn('Nenhum ID de processo disponível para carregar documentos')
          this.documentos = []
          return
        }
        
        console.log('🔍 Carregando documentos para processo ID:', processoId)
        
        const { data, error } = await supabase
          .from('documentos_processo')
          .select('*')
          .eq('processo_id', processoId)
          .order('numero_sequencial', { ascending: true })
        
        if (error) {
          console.warn('Erro ao carregar documentos (normal se tabela não existe):', error)
          this.documentos = []
          return
        }
        
        // Filtrar documentos para excluir DFD e folha de rosto no assistente
        const documentosFiltrados = data?.filter(doc => {
          const tipoDoc = doc.tipo_documento || ''
          // ❌ EXCLUIR DFD e folha de rosto do assistente
          if (tipoDoc === 'DFD' || tipoDoc === 'FOLHA_ROSTO') {
            return false
          }
          return true
        }) || []

        const documentosProcesso = documentosFiltrados.map(doc => ({
          nome: doc.nome_documento || doc.titulo || 'Documento',
          tipo: doc.tipo_documento || 'Documento',
          data_upload: new Date(doc.data_criacao || doc.criado_em || new Date()),
          pagina: doc.numero_sequencial || 0,
          url_arquivo: doc.arquivo_url || doc.url_arquivo,
          id: doc.id,
          origem: 'processo'
        }))

        // ✅ CARREGAR também documentos dos produtos
        try {
          const { data: docsProdutos, error: errorProdutos } = await supabase
            .from('documentos_produtos_processo')
            .select('*')
            .eq('processo_id', processoId)
            .order('created_at', { ascending: true })

          if (!errorProdutos && docsProdutos) {
            const documentosProdutos = docsProdutos.map(doc => ({
              nome: `${doc.nome_arquivo} (${doc.nome_produto})`,
              tipo: 'DOCUMENTO_PRODUTO',
              data_upload: new Date(doc.created_at),
              pagina: 0,
              url_arquivo: doc.url_arquivo,
              id: doc.id,
              origem: 'produto',
              produto: doc.nome_produto,
              marca: doc.marca,
              fabricante: doc.fabricante
            }))

            this.documentos = [...documentosProcesso, ...documentosProdutos]
            console.log(`📄 Carregados ${documentosProcesso.length} docs do processo + ${documentosProdutos.length} docs de produtos`)
          } else {
            this.documentos = documentosProcesso
            console.log(`📄 Carregados apenas ${documentosProcesso.length} docs do processo (sem docs de produtos)`)
          }
        } catch (errorProdutos) {
          console.warn('Erro ao carregar documentos dos produtos:', errorProdutos)
          this.documentos = documentosProcesso
        }
        
      } catch (error) {
        console.warn('Erro ao carregar documentos (pode ser normal):', error)
        this.documentos = []
      }
    },
    
    determinarEtapaAtual() {
      // Lógica inteligente para determinar etapa atual baseada no progresso real
      
      // Verificar se tem dados básicos
      if (!this.dadosProcesso.tipo_processo || !this.dadosProcesso.numero_processo) {
        this.etapaAtual = 0 // Folha de Rosto
        return
      }
      
      // Verificar se tem dados básicos completos (órgão, unidade)
      if (!this.dadosProcesso.nome_orgao || !this.dadosProcesso.unidade_interessada) {
        this.etapaAtual = 1 // Informações Básicas
        return
      }
      
      // Verificar se tem DFD
      if (!this.dfdCriada) {
        this.etapaAtual = 2 // DFD
        return
      }
      
      // Para processos de padronização, verificar produtos
      if (this.dadosProcesso.tipo_processo === 'padronizacao') {
        if (this.produtos.length === 0 || this.produtosSelecionados.length === 0) {
          this.etapaAtual = 3 // Produtos
          return
        } else {
          this.etapaAtual = 4 // Documentação
          return
        }
      }
      
      // Para despadronização, ir direto para documentação após DFD
      this.etapaAtual = 3 // Documentação (despadronização)
    },
    
    selecionarTipo(tipo) {
      this.dadosProcesso.tipo_processo = tipo
    },
    
    async proximaEtapa() {
      // Auto-save antes de avançar para próxima etapa
      await this.salvarProgressoEtapaAtual()
      
      if (this.etapaAtual === 1) {
        // Criar processo temporário após informações básicas
        await this.criarProcessoTemporario()
      }
      
      if (this.etapaAtual === 3 && this.dadosProcesso.tipo_processo === 'padronizacao') {
        // Salvar produtos
        await this.salvarProdutos()
      }
      
      if (this.etapaAtual === 4) {
        // Salvar documentos (edital, DFD, etc.)
        await this.salvarDocumentosProcesso()
      }
      
      this.etapaAtual++
    },
    
    async voltarEtapa() {
      // Auto-save antes de voltar para etapa anterior
      await this.salvarProgressoEtapaAtual()
      
      if (this.etapaAtual > 0) {
        this.etapaAtual--
        // Carregar dados salvos da etapa anterior
        await this.carregarProgressoEtapa(this.etapaAtual)
      }
    },
    
    async salvarProgressoEtapaAtual() {
      try {
        let chaveStorage = null
        
        if (this.modoEdicao && this.processoEdicao?.id) {
          chaveStorage = `processo_edicao_${this.processoEdicao.id}`
        } else {
          // Para processos novos, usar ou criar uma chave consistente
          chaveStorage = localStorage.getItem('processo_atual_novo')
          if (!chaveStorage) {
            chaveStorage = `processo_novo_${Date.now()}`
            localStorage.setItem('processo_atual_novo', chaveStorage)
          }
        }
        
        const progressoSalvo = {
          etapaAtual: this.etapaAtual,
          dadosProcesso: { ...this.dadosProcesso },
          dadosBasicos: { ...this.dadosBasicos },
          dadosDFD: { ...this.dadosDFD },
          produtosSelecionados: Array.isArray(this.produtosSelecionados) ? [...this.produtosSelecionados] : [],
          documentosUpload: [...(this.documentosUpload || [])],
          timestamp: new Date().toISOString(),
          processoId: this.processoTemporario?.id || this.processoEdicao?.id,
          modoEdicao: this.modoEdicao
        }
        
        localStorage.setItem(chaveStorage, JSON.stringify(progressoSalvo))
        console.log(`📄 Auto-save realizado - Etapa ${this.etapaAtual}`)
        console.log(`📄 DEBUG: Produtos selecionados salvos:`, progressoSalvo.produtosSelecionados)
        
      } catch (error) {
        console.error('Erro ao salvar progresso da etapa:', error)
      }
    },
    
    async carregarProgressoEtapa(etapa) {
      try {
        const chaveStorage = this.modoEdicao ? 
          `processo_edicao_${this.processoEdicao?.id}` : 
          localStorage.getItem('processo_atual_novo')
        
        if (!chaveStorage) return
        
        const progressoSalvo = localStorage.getItem(chaveStorage)
        if (progressoSalvo) {
          const dados = JSON.parse(progressoSalvo)
          
          // Carregar apenas os dados relevantes para a etapa
          this.dadosProcesso = { ...dados.dadosProcesso }
          this.dadosBasicos = { ...dados.dadosBasicos }
          this.dadosDFD = { ...dados.dadosDFD }
          this.produtosSelecionados = [...(dados.produtosSelecionados || [])]
          console.log('📄 DEBUG: Produtos selecionados carregados do auto-save:', this.produtosSelecionados)
          this.documentosUpload = [...(dados.documentosUpload || [])]
          
          console.log(`📄 Dados carregados - Etapa ${etapa}`)
        }
      } catch (error) {
        console.error('Erro ao carregar progresso da etapa:', error)
      }
    },
    
    async carregarProcessoSalvo() {
      // Função para carregar processo ao iniciar o assistente
      try {
        let chaveStorage = null
        
        if (this.modoEdicao && this.processoEdicao?.id) {
          chaveStorage = `processo_edicao_${this.processoEdicao.id}`
        } else {
          chaveStorage = localStorage.getItem('processo_atual_novo')
        }
        
        if (!chaveStorage) return false
        
        const progressoSalvo = localStorage.getItem(chaveStorage)
        if (progressoSalvo) {
          const dados = JSON.parse(progressoSalvo)
          
          // Restaurar todos os dados
          this.etapaAtual = dados.etapaAtual || 0
          this.dadosProcesso = { ...dados.dadosProcesso }
          this.dadosBasicos = { ...dados.dadosBasicos }
          this.dadosDFD = { ...dados.dadosDFD }
          this.produtosSelecionados = [...(dados.produtosSelecionados || [])]
          console.log('📄 DEBUG: Produtos selecionados carregados do auto-save:', this.produtosSelecionados)
          this.documentosUpload = [...(dados.documentosUpload || [])]
          
          if (dados.processoId) {
            this.processoTemporario = { id: dados.processoId }
          }
          
          console.log(`📄 Processo carregado - Retornando para Etapa ${this.etapaAtual}`)
          return true
        }
      } catch (error) {
        console.error('Erro ao carregar processo salvo:', error)
      }
      return false
    },
    
    async criarProcessoTemporario() {
      try {
        this.processando = true
        
        // Se já existe processo temporário ou está em modo edição, não criar novo
        if (this.processoTemporario || this.modoEdicao) {
          console.log('🔄 DEBUG: Processo já existe ou está em modo edição, pulando criação')
          console.log('🔄 Processo existente:', this.processoTemporario || this.processoEdicao)
          return this.processoTemporario || this.processoEdicao
        }
        
        console.log('🚀 DEBUG: Criando novo processo com dados:', this.dadosProcesso)
        this.processoTemporario = await ProcessosAdministrativosService.criarProcesso(this.dadosProcesso)
        console.log('✅ DEBUG: Processo criado com sucesso:', this.processoTemporario)
        
        // Criar automaticamente a Folha de Rosto (Fl. 001)
        await this.criarFolhaDeRosto()
        
      } catch (error) {
        console.error('Erro ao criar processo:', error)
        alert('Erro ao criar processo: ' + error.message)
        throw error
      } finally {
        this.processando = false
      }
    },
    
    async criarFolhaDeRosto() {
      try {
        const folhaDeRosto = {
          processo_id: this.processoTemporario.id,
          tenant_id: this.processoTemporario.tenant_id,
          numero_folha: 1, // Folha de Rosto é sempre Fl. 001
          tipo_documento: 'FOLHA_ROSTO',
          nome_documento: 'Folha de Rosto do Processo Administrativo',
          titulo: 'Folha de Rosto',
          descricao: 'Folha de rosto do processo administrativo',
          data_autuacao: new Date().toISOString(),
          assinado: false,
          conteudo_html: null // Será gerado dinamicamente
        }
        
        const { error } = await supabase
          .from('documentos_processo')
          .insert([folhaDeRosto])
        
        if (error) {
          console.error('Erro ao criar folha de rosto:', error)
          throw error
        }
        
        console.log('Folha de rosto criada com sucesso')
      } catch (error) {
        console.error('Erro ao criar folha de rosto:', error)
        throw error
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
      console.log('🔄 DEBUG: Toggling produto:', produto.nome_produto || produto.nome, 'ID:', produto.id)
      console.log('🔄 DEBUG: produtosSelecionados ANTES:', this.produtosSelecionados)
      
      const index = this.produtosSelecionados.indexOf(produto.id)
      if (index > -1) {
        this.produtosSelecionados.splice(index, 1)
        console.log('❌ DEBUG: Produto removido da seleção')
      } else {
        this.produtosSelecionados.push(produto.id)
        console.log('✅ DEBUG: Produto adicionado à seleção')
      }
      
      console.log('🔄 DEBUG: produtosSelecionados DEPOIS:', this.produtosSelecionados)
    },
    
    async confirmarSelecaoProdutos() {
      try {
        this.processando = true
        
        // Converter produtos selecionados para formato do processo
        const produtosSelecionadosData = this.produtosAprovados
          .filter(produto => this.produtosSelecionados.includes(produto.id))
        
        // Carregar documentos para cada produto selecionado
        const produtosComDocumentos = []
        for (const produto of produtosSelecionadosData) {
          // Carregar documentos do produto
          const { data: documentos, error } = await supabase
            .from('documentos')
            .select('*')
            .eq('produto_id', produto.id)
          
          if (error) {
            console.warn('Erro ao carregar documentos do produto:', produto.nome, error)
          }
          
          console.log('Produto original:', produto)
          console.log('Documentos carregados:', documentos)
          
          produtosComDocumentos.push({
            ...produto,
            nome_produto: produto.nome || produto.nome_produto,
            categoria_produto: produto.categoria || produto.categoria_produto || 'Categoria não informada',
            especificacoes_tecnicas: produto.especificacoes || produto.especificacoes_tecnicas || produto.descricao || 'Especificações não disponíveis',
            fabricante: produto.fabricante || 'Fabricante não informado',
            quantidade_amostras: 0,
            valor_estimado: null,
            observacoes_processo: '',
            documentos: documentos || [],
            documentos_adicionados: [] // Para rastrear quais documentos foram adicionados ao processo
          })
        }
        
        this.produtos = produtosComDocumentos
        this.mostrarSeletorProdutos = false
        this.produtosSelecionados = []
        
      } catch (error) {
        console.error('Erro ao carregar documentos dos produtos:', error)
        alert('Erro ao carregar documentos dos produtos: ' + error.message)
      } finally {
        this.processando = false
      }
    },
    
    cancelarSelecaoProdutos() {
      this.mostrarSeletorProdutos = false
      this.produtosSelecionados = []
    },
    
    removerProdutoSelecionado(index) {
      this.produtos.splice(index, 1)
    },
    
    adicionarDocumentoProcesso(documento, produtoIndex) {
      const produto = this.produtos[produtoIndex]
      
      // Verificar se já foi adicionado
      if (!produto.documentos_adicionados) {
        produto.documentos_adicionados = []
      }
      
      if (produto.documentos_adicionados.includes(documento.id)) {
        // Remover se já estava adicionado
        produto.documentos_adicionados = produto.documentos_adicionados.filter(id => id !== documento.id)
        
        // Remover da lista de documentos do processo
        this.documentos = this.documentos.filter(doc => doc.documento_produto_id !== documento.id)
      } else {
        // Adicionar à lista de documentos adicionados
        produto.documentos_adicionados.push(documento.id)
        
        // Adicionar à lista de documentos do processo
        const paginaBase = this.dadosProcesso.tipo_processo === 'padronizacao' ? 5 : 4
        this.documentos.push({
          nome: `${produto.nome_produto} - ${documento.nome}`,
          tipo: documento.tipo || 'Documento do Produto',
          data_upload: new Date(),
          pagina: paginaBase + this.documentos.length,
          url_arquivo: documento.arquivo_url,
          documento_produto_id: documento.id,
          produto_id: produto.id,
          documento_original: documento
        })
      }
      
      // Reorganizar numeração
      const paginaBase = this.dadosProcesso.tipo_processo === 'padronizacao' ? 5 : 4
      this.documentos.forEach((doc, i) => {
        doc.pagina = paginaBase + i
      })
    },
    
    verCadastroCompleto(produto) {
      // Abrir modal ou navegar para visualização completa do produto
      const url = `/analise/${produto.id}`
      window.open(url, '_blank')
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
        
        // Pegar apenas produtos selecionados que ainda não foram salvos
        console.log('🔍 DEBUG: Produtos disponíveis:', this.produtos.length)
        console.log('🔍 DEBUG: Produtos selecionados IDs:', this.produtosSelecionados)
        console.log('🔍 DEBUG: Tipo de produtosSelecionados:', typeof this.produtosSelecionados, Array.isArray(this.produtosSelecionados))
        console.log('🔍 DEBUG: Conteúdo real de produtosSelecionados:', JSON.stringify(this.produtosSelecionados))
        
        // Forçar reconstrução do array se estiver corrompido
        let produtosSelecionadosLimpo = []
        if (Array.isArray(this.produtosSelecionados)) {
          produtosSelecionadosLimpo = this.produtosSelecionados.filter(id => typeof id === 'string' && id.length > 0)
        }
        
        console.log(`🔧 DEBUG: Array limpo de produtos selecionados:`, produtosSelecionadosLimpo)
        
        // Se ainda estiver vazio, verificar produtos marcados visualmente na interface
        if (produtosSelecionadosLimpo.length === 0) {
          console.log('⚠️ DEBUG: Array vazio! Tentando recuperar produtos da interface...')
          // Como fallback, salvar todos os produtos carregados (usuário já confirmou seleção)
          produtosSelecionadosLimpo = this.produtos.map(p => p.id)
          console.log('🔄 DEBUG: Usando todos os produtos como selecionados:', produtosSelecionadosLimpo)
        }
        
        const produtosParaSalvar = this.produtos.filter(produto => 
          produtosSelecionadosLimpo.includes(produto.id) && 
          !produto.processo_id  // Produto ainda não foi salvo
        )
        
        console.log(`💾 DEBUG: Produtos para salvar (${produtosParaSalvar.length}):`, produtosParaSalvar)
        console.log(`📋 DEBUG: ID do processo onde salvar:`, this.processoTemporario.id)
        
        for (const produto of produtosParaSalvar) {
          try {
            console.log(`🔄 DEBUG: Salvando produto:`, produto.nome_produto || produto.nome)
            console.log(`🔄 DEBUG: Estrutura completa do produto antes de salvar:`, produto)
            console.log(`🔄 DEBUG: Documentos do produto (se existirem):`, produto.documentos_produto || 'NENHUM')
            
            const resultado = await ProcessosAdministrativosService.adicionarProduto(
              this.processoTemporario.id, 
              produto
            )
            console.log(`✅ DEBUG: Produto salvo com sucesso:`, resultado)
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
    
    // Métodos para documentação
    adicionarDocumento() {
      // Criar um input file temporário
      const input = document.createElement('input')
      input.type = 'file'
      input.multiple = true
      input.accept = '.pdf,.doc,.docx,.jpg,.jpeg,.png'
      
      input.addEventListener('change', (event) => {
        const files = Array.from(event.target.files)
        const paginaBase = this.dadosProcesso.tipo_processo === 'padronizacao' ? 5 : 4
        
        files.forEach((file, index) => {
          this.documentos.push({
            nome: file.name,
            tipo: this.obterTipoDocumento(file.name),
            arquivo: file,
            data_upload: new Date(),
            pagina: paginaBase + this.documentos.length + index
          })
        })
      })
      
      input.click()
    },
    
    obterTipoDocumento(nomeArquivo) {
      const extensao = nomeArquivo.split('.').pop().toLowerCase()
      const tipos = {
        'pdf': 'Documento PDF',
        'doc': 'Documento Word',
        'docx': 'Documento Word',
        'jpg': 'Imagem JPEG',
        'jpeg': 'Imagem JPEG', 
        'png': 'Imagem PNG'
      }
      return tipos[extensao] || 'Documento'
    },
    
    formatarData(data) {
      return new Date(data).toLocaleString('pt-BR')
    },
    
    formatarDataBrasileira(data) {
      if (!data) return ''
      // Para evitar problema de fuso horário com input type="date"
      const [ano, mes, dia] = data.split('-')
      const dataFormatada = new Date(ano, mes - 1, dia)
      return dataFormatada.toLocaleDateString('pt-BR')
    },
    
    visualizarDocumento(documento) {
      console.log('Visualizar documento:', documento)
      
      // Verificar se tem URL do arquivo (tentar diferentes campos possíveis)
      const urlArquivo = documento.url_arquivo || documento.arquivo_url || documento.arquivo
      if (urlArquivo && typeof urlArquivo === 'string') {
        console.log('Abrindo URL:', urlArquivo)
        window.open(urlArquivo, '_blank')
        return
      }
      
      // Se tem arquivo blob (upload local)
      if (documento.arquivo) {
        const url = URL.createObjectURL(documento.arquivo)
        window.open(url, '_blank')
        return
      }
      
      // Se é documento gerado pelo sistema (Folha de Rosto, DFD)
      if (documento.tipo === 'FOLHA_ROSTO') {
        this.gerarPDFFolhaRosto()
        return
      }
      
      if (documento.tipo === 'DFD') {
        this.gerarPDFDFD()
        return
      }
      
      // Fallback - mostrar mensagem
      alert('⚠️ Documento não disponível para visualização.\n\nTipo: ' + documento.tipo)
    },
    
    async gerarPDFFolhaRosto() {
      try {
        // Criar conteúdo HTML da folha de rosto
        const conteudoHTML = this.gerarConteudoFolhaRosto()
        
        // Abrir em nova janela para impressão/salvamento
        const novaJanela = window.open('', '_blank')
        novaJanela.document.write(conteudoHTML)
        novaJanela.document.close()
        
        // Aguardar carregar e imprimir
        setTimeout(() => {
          novaJanela.focus()
          novaJanela.print()
        }, 500)
        
      } catch (error) {
        console.error('Erro ao gerar PDF da folha de rosto:', error)
        alert('Erro ao gerar PDF da folha de rosto: ' + error.message)
      }
    },
    
    async gerarPDFDFD() {
      try {
        // Buscar dados do DFD do processo (usar ID correto dependendo do modo)
        const processoId = this.processoTemporario?.id || this.processoEdicao?.id
        console.log('🔍 Debug - Buscando DFD para processo ID:', processoId)
        
        const { data: dfd, error } = await supabase
          .from('dfd_processo')
          .select('*')
          .eq('processo_id', processoId)
          .single()
        
        if (error) {
          console.error('Erro ao buscar DFD:', error)
          alert('Erro ao carregar dados do DFD: ' + error.message)
          return
        }
        
        if (!dfd) {
          console.warn('⚠️ DFD não encontrado para o processo ID:', processoId)
          alert('DFD não encontrado para este processo. Certifique-se de que o DFD foi criado corretamente.')
          return
        }
        
        console.log('✅ DFD encontrado:', dfd)
        
        // Criar conteúdo HTML do DFD
        const conteudoHTML = this.gerarConteudoDFD(dfd)
        
        // Abrir em nova janela para impressão/salvamento
        const novaJanela = window.open('', '_blank')
        novaJanela.document.write(conteudoHTML)
        novaJanela.document.close()
        
        // Aguardar carregar e imprimir
        setTimeout(() => {
          novaJanela.focus()
          novaJanela.print()
        }, 500)
        
      } catch (error) {
        console.error('Erro ao gerar PDF do DFD:', error)
        alert('Erro ao gerar PDF do DFD: ' + error.message)
      }
    },
    
    gerarConteudoFolhaRosto() {
      const dataAtual = new Date().toLocaleDateString('pt-BR')
      const objetoTexto = this.dadosProcesso.tipo_processo === 'padronizacao' ? 
        `CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS` :
        `DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE E ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS`
      
      // Usar formato exato do componente FolhaRosto.vue
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <title>Folha de Rosto - ${this.dadosProcesso.numero_processo}</title>
          <meta charset="utf-8">
          <style>
            .folha-rosto {
              width: 21cm;
              min-height: 29.7cm;
              margin: 0 auto;
              padding: 2cm;
              background: white;
              font-family: 'Times New Roman', serif;
              font-size: 12pt;
              line-height: 1.6;
              box-shadow: 0 0 10px rgba(0,0,0,0.1);
            }
            
            .folha-rosto-simples {
              display: flex;
              flex-direction: column;
              justify-content: center;
              align-items: center;
              min-height: 25cm;
            }
            
            .caixa-bordered {
              border: 2px solid #000;
              padding: 1.5cm;
              max-width: 16cm;
              width: 100%;
            }
            
            .numero-processo {
              font-weight: bold;
              font-size: 14pt;
              margin-bottom: 1cm;
              text-align: center;
            }
            
            .campo {
              margin-bottom: 1cm;
              text-align: left;
            }
            
            .campo.objeto {
              text-align: justify;
              line-height: 1.4;
            }
            
            .campo.observacoes {
              margin-top: 1.5cm;
              border-top: 1px solid #ccc;
              padding-top: 1cm;
            }
            
            .observacoes-conteudo {
              margin-top: 0.5cm;
              text-align: justify;
              line-height: 1.5;
              font-style: italic;
            }
            
            .campo strong {
              font-weight: bold;
            }
            
            .folha-numero {
              margin-top: 4cm;
              text-align: center;
              font-size: 10pt;
              color: #666;
            }
            
            .folha-numero p {
              margin: 0;
            }
            
            @media print {
              .folha-rosto {
                box-shadow: none;
                margin: 0;
                padding: 1.5cm;
              }
            }
          </style>
        </head>
        <body>
          <div class="folha-rosto">
            <div class="folha-rosto-simples">
              <div class="caixa-bordered">
                
                <div class="numero-processo">
                  <strong>PROCESSO ADMINISTRATIVO Nº ${this.dadosProcesso.numero_processo || '[não definido]'}</strong>
                </div>
                
                <div class="campo">
                  <strong>NOME DO ÓRGÃO:</strong> ${this.dadosProcesso.nome_orgao}
                </div>
                
                <div class="campo">
                  <strong>INTERESSADO(A):</strong> ${this.dadosProcesso.unidade_interessada}
                </div>
                
                <div class="campo">
                  <strong>DATA DE AUTUAÇÃO:</strong> ${this.formatarDataBrasileira(this.dadosProcesso.data_autuacao)}
                </div>
                
                <div class="campo objeto">
                  <strong>OBJETO:</strong> ${objetoTexto}
                </div>

                ${this.dadosProcesso.observacoes ? `
                <div class="campo observacoes">
                  <strong>OBSERVAÇÕES:</strong>
                  <div class="observacoes-conteudo">${this.dadosProcesso.observacoes.replace(/\n/g, '<br>')}</div>
                </div>
                ` : ''}
                
              </div>
              
              <!-- Número da folha -->
              <div class="folha-numero">
                <p>Fl. 001</p>
              </div>
            </div>
          </div>
        </body>
        </html>
      `
    },
    
    gerarConteudoDFD(dfd) {
      const dataAtual = new Date().toLocaleDateString('pt-BR')
      const modeloTipo = this.dadosProcesso.tipo_processo === 'padronizacao' ? 'MODELO 1' : 'MODELO 2'
      const finalidade = this.dadosProcesso.tipo_processo === 'padronizacao' ? 
        'padronização de marcas e modelos de produtos' : 
        'despadronização de marcas e modelos de produtos'
      
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <title>DFD - ${this.dadosProcesso.numero_processo}</title>
          <meta charset="utf-8">
          <style>
            @page {
              margin: 2cm;
              @bottom-right {
                content: "Fl. 002";
              }
            }
            body {
              font-family: 'Times New Roman', serif;
              font-size: 12pt;
              line-height: 1.6;
              color: #000;
            }
            .header {
              text-align: center;
              margin-bottom: 30px;
            }
            .header h1 {
              font-size: 14pt;
              font-weight: bold;
              margin: 10px 0;
            }
            .campo {
              margin-bottom: 15px;
            }
            .label {
              font-weight: bold;
              margin-right: 10px;
            }
            .tabela {
              width: 100%;
              border-collapse: collapse;
              margin: 20px 0;
            }
            .tabela th, .tabela td {
              border: 1px solid #000;
              padding: 8px;
              text-align: left;
            }
            .tabela th {
              background-color: #f0f0f0;
              font-weight: bold;
            }
            .assinatura {
              margin-top: 50px;
              text-align: center;
            }
            .linha-assinatura {
              border-top: 1px solid #000;
              margin-top: 50px;
              padding-top: 10px;
              width: 300px;
              margin-left: auto;
              margin-right: auto;
            }
            @media print {
              body { margin: 0; }
            }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>(${modeloTipo} – ${finalidade.toUpperCase()})</h1>
            <h1>DOCUMENTO DE FORMALIZAÇÃO DA DEMANDA – DFD</h1>
          </div>
          
          <div class="campo">
            <span class="label">Demandante:</span> Comissão Permanente de Padronização de Materiais - CPPM
          </div>
          
          <div class="campo">
            <span class="label">Presidente:</span> ${dfd.nome_presidente || '_________________________________'}
            <span class="label">Matrícula:</span> ${dfd.matricula_presidente || '_________________'}
          </div>
          
          <div class="campo">
            <span class="label">E-mail:</span> ${dfd.email_presidente || '________________________'}
            <span class="label">Telefone:</span> ${dfd.telefone_presidente || '_________________'}
          </div>
          
          <h2>1. OBJETO DESTE DFD:</h2>
          <p>${finalidade.charAt(0).toUpperCase() + finalidade.slice(1)} que ${this.dadosProcesso.tipo_processo === 'padronizacao' ? 'possuam os padrões mínimos de qualidade' : 'não mais atendem aos padrões mínimos de qualidade'}, estética, rendimento, durabilidade e adequação ao uso.</p>
          
          ${this.produtos && this.produtos.length > 0 ? `
          <h3>1.1. Relação de ${this.dadosProcesso.tipo_processo === 'padronizacao' ? 'Bens' : 'Bens Passíveis de Despadronização'}:</h3>
          <table class="tabela">
            <thead>
              <tr>
                <th>ITEM</th>
                <th>CÓDIGO</th>
                <th>DESCRIÇÃO</th>
                <th>UNIDADE</th>
                <th>${this.dadosProcesso.tipo_processo === 'padronizacao' ? 'REQUISITOS MÍNIMOS' : 'MOTIVAÇÃO'}</th>
                ${this.dadosProcesso.tipo_processo === 'padronizacao' ? '<th>PREÇO ESTIMADO</th>' : ''}
              </tr>
            </thead>
            <tbody>
              ${this.produtos.map((produto, index) => `
                <tr>
                  <td>${index + 1}</td>
                  <td>${produto.codigo || 'N/A'}</td>
                  <td>${produto.nome_produto}</td>
                  <td>UN</td>
                  <td>${produto.especificacoes_tecnicas || 'A definir'}</td>
                  ${this.dadosProcesso.tipo_processo === 'padronizacao' ? `<td>R$ ${produto.valor_estimado || '0,00'}</td>` : ''}
                </tr>
              `).join('')}
            </tbody>
          </table>
          ` : ''}
          
          <p style="margin-top: 50px;">
            Nestes termos, encaminha-se o presente DFD à autoridade competente, para ciência da presente demanda e autorização para a abertura e instrução do pertinente processo administrativo.
          </p>
          
          <p>Em ${dataAtual}.</p>
          
          <div class="assinatura">
            <div class="linha-assinatura">
              (Assinatura Eletrônica)<br>
              Presidente da CPPM
            </div>
          </div>
          
          <div style="margin-top: 50px;">
            <p><strong>DESPACHO:</strong></p>
            <p>De acordo. Autorizo, nos termos da solicitação supra.</p>
            
            <div class="assinatura">
              <div class="linha-assinatura">
                (Assinatura Eletrônica)<br>
                Cargo da Autoridade Competente
              </div>
            </div>
          </div>
        </body>
        </html>
      `
    },
    
    removerDocumento(index) {
      this.documentos.splice(index, 1)
      // Reorganizar numeração
      const paginaBase = this.dadosProcesso.tipo_processo === 'padronizacao' ? 5 : 4
      this.documentos.forEach((doc, i) => {
        doc.pagina = paginaBase + i
      })
    },
    
    // Métodos para edital
    validarNumeroEdital() {
      const regex = /^\d{1,3}\/\d{4}$/
      if (!this.dadosEdital.numero_edital) {
        this.erroEdital = ''
        return
      }
      
      if (!regex.test(this.dadosEdital.numero_edital)) {
        this.erroEdital = 'Formato inválido. Use XXX/YYYY (ex: 001/2024)'
      } else {
        this.erroEdital = ''
      }
    },
    
    onEditalSelect(event) {
      const file = event.target.files[0]
      if (!file) return
      
      if (file.type !== 'application/pdf') {
        alert('Apenas arquivos PDF são aceitos para o edital.')
        return
      }
      
      if (file.size > 50 * 1024 * 1024) { // 50MB limit
        alert('Arquivo muito grande. O limite é de 50MB.')
        return
      }
      
      this.dadosEdital.arquivo = file
    },
    
    onEditalDrop(event) {
      this.dragoverEdital = false
      const file = event.dataTransfer.files[0]
      
      if (!file) return
      
      if (file.type !== 'application/pdf') {
        alert('Apenas arquivos PDF são aceitos para o edital.')
        return
      }
      
      if (file.size > 50 * 1024 * 1024) { // 50MB limit
        alert('Arquivo muito grande. O limite é de 50MB.')
        return
      }
      
      this.dadosEdital.arquivo = file
    },
    
    removerEdital() {
      this.dadosEdital.arquivo = null
      if (this.$refs.editalFileInput) {
        this.$refs.editalFileInput.value = ''
      }
    },
    
    editarEdital() {
      this.dadosProcesso.edital_vinculado = false
    },
    
    formatarTamanhoArquivo(bytes) {
      if (bytes === 0) return '0 Bytes'
      const k = 1024
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    },
    
    async carregarEditaisDisponiveis() {
      // Prevenir múltiplas chamadas simultâneas
      if (this.carregandoEditais) {
        console.log('⚠️ Já está carregando editais, ignorando nova chamada')
        return
      }
      
      try {
        this.carregandoEditais = true
        // Limpar lista anterior para evitar duplicação
        this.editaisDisponiveis = []
        console.log('🔄 Limpando lista de editais e carregando novamente...')
        
        const tenantId = await this.getTenantId()
        console.log('🔍 Debug - Tenant ID obtido:', tenantId)
        console.log('🔍 Debug - Nome do órgão:', this.dadosProcesso.nome_orgao)
        
        // Primeiro, vamos buscar TODOS os editais para debug
        const { data: todosEditais, error: errorTodos } = await supabase
          .from('editais')
          .select(`
            id,
            numero,
            data_publicacao,
            descricao,
            status,
            pdf_convertido_url,
            pdf_convertido_nome,
            url_documento,
            tenant_id
          `)
          .order('data_publicacao', { ascending: false })
        
        console.log('🔍 Debug - TODOS os editais no sistema:', todosEditais)
        
        if (errorTodos) {
          console.error('Erro ao carregar TODOS os editais:', errorTodos)
        }
        
        // Agora buscar com filtro por tenant_id
        let editaisFiltrados = []
        
        if (tenantId) {
          const { data: editais, error } = await supabase
            .from('editais')
            .select(`
              id,
              numero,
              data_publicacao,
              descricao,
              status,
              pdf_convertido_url,
              pdf_convertido_nome,
              url_documento,
              tenant_id
            `)
            .eq('tenant_id', tenantId)
            .eq('status', 'PUBLICADO')
            .order('data_publicacao', { ascending: false })
          
          console.log('🔍 Debug - Editais filtrados por tenant_id:', editais)
          editaisFiltrados = editais || []
          
          if (error) {
            console.error('Erro ao carregar editais filtrados:', error)
          }
        }
        
        // Se não encontrou com tenant_id, vamos tentar buscar apenas os publicados
        if (editaisFiltrados.length === 0) {
          const { data: editaisPublicados, error: errorPublicados } = await supabase
            .from('editais')
            .select(`
              id,
              numero,
              data_publicacao,
              descricao,
              status,
              pdf_convertido_url,
              pdf_convertido_nome,
              url_documento,
              tenant_id
            `)
            .eq('status', 'PUBLICADO')
            .order('data_publicacao', { ascending: false })
          
          console.log('🔍 Debug - Editais apenas por status PUBLICADO:', editaisPublicados)
          editaisFiltrados = editaisPublicados || []
          
          if (errorPublicados) {
            console.error('Erro ao carregar editais publicados:', errorPublicados)
          }
        }
        
        // Mapear para o formato esperado
        this.editaisDisponiveis = editaisFiltrados.map(edital => ({
          id: edital.id,
          numero_edital: edital.numero,
          data_publicacao: edital.data_publicacao,
          tipo_edital: 'Pré-Qualificação',
          descricao: edital.descricao || 'Edital de Pré-Qualificação',
          arquivo_url: edital.pdf_convertido_url || edital.url_documento, // Fallback para url_documento
          status: edital.status ? edital.status.toLowerCase() : 'ativo',
          produtos_count: 0 // Placeholder - podemos calcular depois se necessário
        }))
        
        console.log('🎯 Editais finais disponíveis:', this.editaisDisponiveis)
        console.log('🔗 URLs dos PDFs encontrados:', this.editaisDisponiveis.map(e => ({ 
          numero: e.numero_edital, 
          url: e.arquivo_url,
          status: e.status 
        })))
        this.editaisCarregados = true
        
      } catch (error) {
        console.error('Erro ao buscar editais:', error)
        alert('Erro ao buscar editais: ' + error.message)
        this.editaisDisponiveis = []
      } finally {
        this.carregandoEditais = false
      }
    },
    
    selecionarEdital(edital) {
      console.log('📎 Edital selecionado:', edital)
      console.log('🔗 URL do PDF do edital selecionado:', edital.arquivo_url)
      this.editalSelecionado = edital
    },
    
    async vincularEditalSelecionado() {
      if (!this.editalSelecionado) {
        alert('Selecione um edital primeiro.')
        return
      }
      
      try {
        this.processando = true
        
        // Vincular edital selecionado ao processo
        const dadosVinculacao = {
          numero_edital: this.editalSelecionado.numero_edital,
          data_publicacao: this.editalSelecionado.data_publicacao,
          edital_id: this.editalSelecionado.id,
          arquivo_url: this.editalSelecionado.arquivo_url,
          descricao: this.editalSelecionado.descricao
        }
        
        await ProcessosAdministrativosService.vincularEditalProcesso(
          this.processoTemporario.id,
          dadosVinculacao
        )
        
        // Atualizar dados do processo
        this.dadosProcesso.edital_vinculado = true
        this.dadosProcesso.numero_edital = this.editalSelecionado.numero_edital
        this.dadosProcesso.data_vinculacao_edital = new Date()
        
        // Limpar seleção de edital
        const numeroEdital = this.editalSelecionado.numero_edital
        this.editalSelecionado = null
        
        // Recarregar documentos para mostrar o edital vinculado
        await this.carregarDocumentosProcesso()
        
        alert(`✅ Edital ${numeroEdital} vinculado com sucesso!`)
        
      } catch (error) {
        console.error('Erro ao vincular edital:', error)
        alert('Erro ao vincular edital: ' + error.message)
      } finally {
        this.processando = false
      }
    },
    
    async vincularEdital() {
      if (!this.dadosEdital.numero_edital || !this.dadosEdital.arquivo || this.erroEdital) {
        alert('Por favor, preencha o número do edital e selecione um arquivo PDF válido.')
        return
      }
      
      try {
        this.processando = true
        
        await ProcessosAdministrativosService.vincularEditalProcesso(
          this.processoTemporario.id,
          this.dadosEdital
        )
        
        // Atualizar dados do processo
        this.dadosProcesso.edital_vinculado = true
        this.dadosProcesso.numero_edital = this.dadosEdital.numero_edital
        this.dadosProcesso.data_vinculacao_edital = new Date()
        
        alert('✅ Edital vinculado com sucesso!')
        
      } catch (error) {
        console.error('Erro ao vincular edital:', error)
        alert('Erro ao vincular edital: ' + error.message)
      } finally {
        this.processando = false
      }
    },

    async salvarDocumentosProcesso() {
      try {
        console.log('Salvando documentos do processo...')
        
        // Salvar DFD se existir
        if (this.dfdCriada) {
          await this.salvarDocumentoDFD()
        }
        
        // Salvar edital se selecionado (apenas para padronização)
        if (this.editalSelecionado && this.dadosProcesso.tipo_processo === 'padronizacao') {
          await this.salvarDocumentoEdital()
        }
        
        console.log('Documentos do processo salvos com sucesso')
        
      } catch (error) {
        console.error('Erro ao salvar documentos do processo:', error)
        throw error
      }
    },

    async salvarDocumentoDFD() {
      try {
        const documentoDFD = {
          processo_id: this.processoTemporario.id,
          tenant_id: this.processoTemporario.tenant_id,
          numero_folha: 2, // DFD é sempre Fl. 002
          tipo_documento: 'DFD',
          nome_documento: `Documento de Formalização de Demanda - ${this.dadosProcesso.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'}`,
          titulo: 'DFD - Documento de Formalização de Demanda',
          descricao: `Documento de Formalização de Demanda do processo de ${this.dadosProcesso.tipo_processo}`,
          data_autuacao: new Date().toISOString(),
          assinado: false,
          conteudo_html: null // Será gerado dinamicamente
        }
        
        const { error } = await supabase
          .from('documentos_processo')
          .insert([documentoDFD])
        
        if (error) {
          console.error('Erro ao salvar DFD:', error)
          throw error
        }
        
        console.log('DFD salvo com sucesso')
      } catch (error) {
        console.error('Erro ao salvar documento DFD:', error)
        throw error
      }
    },

    async salvarDocumentoEdital() {
      try {
        const documentoEdital = {
          processo_id: this.processoTemporario.id,
          tenant_id: this.processoTemporario.tenant_id,
          numero_folha: 3, // Edital é sempre Fl. 003 para padronização
          tipo_documento: 'EDITAL',
          nome_documento: `Edital de Chamamento Público - ${this.editalSelecionado.titulo}`,
          titulo: 'Edital de Chamamento Público',
          descricao: 'Edital de Chamamento Público para Pré-qualificação de Bens',
          data_autuacao: new Date().toISOString(),
          arquivo_url: this.editalSelecionado.arquivo_url,
          assinado: false,
          conteudo_html: null // Será gerado dinamicamente
        }
        
        const { error } = await supabase
          .from('documentos_processo')
          .insert([documentoEdital])
        
        if (error) {
          console.error('Erro ao salvar edital:', error)
          throw error
        }
        
        console.log('Edital salvo como documento do processo')
      } catch (error) {
        console.error('Erro ao salvar documento edital:', error)
        throw error
      }
    },
    
    limparProgressoSalvo() {
      try {
        const chaveStorage = this.modoEdicao ? 
          `processo_edicao_${this.processoEdicao?.id}` : 
          localStorage.getItem('processo_atual_novo')
        
        if (chaveStorage) {
          localStorage.removeItem(chaveStorage)
          if (!this.modoEdicao) {
            localStorage.removeItem('processo_atual_novo')
          }
          console.log('📄 Progresso salvo limpo com sucesso')
        }
      } catch (error) {
        console.error('Erro ao limpar progresso salvo:', error)
      }
    },

    async finalizarProcesso() {
      try {
        this.processando = true
        
        console.log('🏁 DEBUG: Iniciando finalização do processo:', this.processoTemporario.id)
        
        // Verificar se produtos foram salvos antes de finalizar
        const produtosSalvos = await ProcessosAdministrativosService.listarProdutosProcesso(this.processoTemporario.id)
        console.log(`📋 DEBUG: Produtos encontrados no processo antes da finalização (${produtosSalvos.length}):`, produtosSalvos)
        
        // 🆕 SALVAR DOCUMENTOS DE UPLOAD (apenas para despadronização)
        if (this.dadosProcesso.tipo_processo === 'despadronizacao' && this.documentos.length > 0) {
          console.log('📄 DEBUG: Salvando documentos de upload para despadronização...')
          await this.salvarDocumentosUpload()
        }
        
        // Atualizar status do processo baseado no tipo
        const novoStatus = this.dadosProcesso.tipo_processo === 'despadronizacao' ? 'criado_cpm_desp' : 'criado_cpm'
        console.log(`🔄 DEBUG: Atualizando status para ${novoStatus}`)
        await ProcessosAdministrativosService.atualizarProcesso(
          this.processoTemporario.id,
          { status: novoStatus }
        )
        
        // Limpar dados salvos após finalização com sucesso
        this.limparProgressoSalvo()
        
        this.$emit('processo-criado', this.processoTemporario)
        
      } catch (error) {
        console.error('Erro ao finalizar processo:', error)
        alert('Erro ao finalizar processo: ' + error.message)
      } finally {
        this.processando = false
      }
    },
    
    limparDados() {
      // Limpar todos os dados para começar um processo novo
      this.dadosProcesso = {
        tipo_processo: this.tipoProcessoInicial || '', // Usar tipo pré-selecionado se fornecido
        numero_processo: '',
        nome_orgao: '',
        unidade_interessada: '',
        data_autuacao: new Date().toISOString().split('T')[0],
        observacoes: '',
        numero_edital: '',
        edital_vinculado: false,
        data_vinculacao_edital: null
      }
      
      this.dadosBasicos = {
        nome_contato: '',
        email_contato: '',
        telefone_contato: '',
        departamento_contato: ''
      }
      
      this.dadosDFD = {
        justificativa: '',
        descricao_necessidade: '',
        criterios_aceitacao: '',
        observacoes_especiais: ''
      }
      
      this.produtosSelecionados = []
      this.documentosUpload = []
      this.processoTemporario = null
      
      console.log('🧹 Dados limpos para novo processo. Tipo pré-selecionado:', this.tipoProcessoInicial)
    },

    async salvarDocumentosUpload() {
      try {
        console.log('📄 DEBUG: Salvando documentos de upload no banco...')
        
        const documentosParaSalvar = this.documentos.filter(doc => 
          // Salvar apenas documentos que foram feitos upload pelo usuário
          doc.arquivo && !doc.origem // documentos com arquivo blob e sem origem (não são do banco)
        )
        
        console.log(`📄 DEBUG: ${documentosParaSalvar.length} documentos de upload para salvar`)
        
        for (const doc of documentosParaSalvar) {
          console.log(`📤 Fazendo upload do arquivo: ${doc.nome}`)
          
          // 1. FAZER UPLOAD DO ARQUIVO FÍSICO no Supabase Storage
          const nomeArquivo = `doc_${this.processoTemporario.id}_${Date.now()}_${doc.nome}`
          
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('documentosprocessos')
            .upload(nomeArquivo, doc.arquivo, {
              cacheControl: '3600',
              upsert: false
            })
          
          if (uploadError) {
            console.error('❌ Erro no upload do arquivo:', uploadError)
            throw uploadError
          }
          
          // 2. OBTER URL PÚBLICA DO ARQUIVO
          const { data: { publicUrl } } = supabase.storage
            .from('documentosprocessos')
            .getPublicUrl(nomeArquivo)
          
          console.log(`✅ Arquivo enviado com sucesso: ${uploadData.path}`)
          console.log(`🔗 URL gerada: ${publicUrl}`)
          
          // 3. OBTER PRÓXIMA NUMERAÇÃO (igual ao ProcessosAdministrativosComponent)
          const NumeracaoDocumentosService = (await import('../../services/numeracaoDocumentosService')).default
          const { numero, folha } = await NumeracaoDocumentosService.obterProximoNumero(this.processoTemporario.id)
          console.log(`📋 Numeração gerada: ${folha} (número ${numero})`)
          
          // 4. SALVAR DIRETAMENTE NA TABELA documentos_processo (igual ao ProcessosAdministrativosComponent)
          const ProcessosAdministrativosService = (await import('../../services/processosAdministrativosService')).default
          const documentoData = {
            processo_id: this.processoTemporario.id,
            tenant_id: await ProcessosAdministrativosService.getTenantId(),
            numero_sequencial: numero,
            folha_numero: folha,
            tipo_documento: 'DOCUMENTO_ADICIONAL',
            nome_documento: doc.nome,
            titulo: doc.nome,
            descricao: `Documento adicional: ${doc.tipo}`,
            arquivo_url: publicUrl,
            data_autuacao: new Date().toISOString(),
            assinado: false,
            status: 'ativo'
          }
          
          const { error: dbError } = await supabase
            .from('documentos_processo')
            .insert([documentoData])
          
          if (dbError) {
            console.error('❌ Erro ao salvar documento no banco:', dbError)
            throw dbError
          } else {
            console.log(`✅ Documento de upload salvo: ${folha}`)
          }
        }
        
        console.log('✅ Todos os documentos de upload foram salvos com sucesso')
        
      } catch (error) {
        console.error('❌ Erro ao salvar documentos de upload:', error)
        throw error
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

/* Estilos para numeração das etapas */
.etapa-header-numeracao {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #e2e8f0;
}

.numero-pagina {
  background: #2c3e50;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 600;
  font-size: 0.9rem;
  min-width: 80px;
  text-align: center;
}

.etapa-header-numeracao h3 {
  margin: 0;
  color: #2d3748;
  flex: 1;
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

/* Fluxo Verde - Padronização */
.tipo-fluxo-verde .fluxo-item {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #a7f3d0;
}

.tipo-fluxo-verde .fluxo-arrow {
  color: #059669;
}

/* Fluxo Vermelho - Despadronização */
.tipo-fluxo-vermelho .fluxo-item {
  background: #fee2e2;
  color: #7f1d1d;
  border: 1px solid #fca5a5;
}

.tipo-fluxo-vermelho .fluxo-arrow {
  color: #dc2626;
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

/* Estilos para Folha de Rosto */
.folha-rosto-campos {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 2px solid #2c3e50;
}

.folha-rosto-campos h4 {
  color: #2d3748;
  margin-bottom: 1.5rem;
}

.folha-rosto-preview-mini {
  margin-top: 2rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.folha-rosto-preview-mini h4 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.preview-container {
  max-height: 400px;
  overflow-y: auto;
  border: 1px solid #cbd5e0;
  border-radius: 8px;
  background: white;
}

/* Estilos para Informações Básicas */
.resumo-processo {
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.resumo-processo h4 {
  color: #0c4a6e;
  margin-bottom: 1rem;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
}

.info-item {
  background: white;
  padding: 1rem;
  border-radius: 8px;
  border: 1px solid #e0f2fe;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.info-item strong {
  color: #0c4a6e;
  font-size: 0.9rem;
}

.info-item span {
  color: #1e40af;
  font-weight: 500;
}

.observacoes-adicionais {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
}

.observacoes-adicionais h4 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.dica-observacoes {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
  padding: 1rem;
  background: #fefce8;
  border: 1px solid #fde047;
  border-radius: 8px;
}

.dica-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.dica-texto {
  color: #713f12;
  font-size: 0.9rem;
}

.dica-texto strong {
  color: #92400e;
  display: block;
  margin-bottom: 0.5rem;
}

.dica-texto ul {
  margin: 0.5rem 0 0 1rem;
  padding: 0;
}

.dica-texto li {
  margin: 0.25rem 0;
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

/* Estilos para documentos dos produtos */
.produto-documentos {
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 1rem;
  margin: 1rem 0;
}

.produto-documentos h6 {
  color: #0c4a6e;
  margin: 0 0 1rem 0;
  font-size: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.documentos-produto-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  max-height: 300px;
  overflow-y: auto;
}

.documento-produto-item {
  background: white;
  border: 1px solid #e0f2fe;
  border-radius: 6px;
  padding: 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  transition: all 0.3s ease;
}

.documento-produto-item:hover {
  border-color: #0284c7;
  box-shadow: 0 2px 8px rgba(2, 132, 199, 0.1);
}

.documento-produto-item .doc-icon {
  font-size: 1.5rem;
  opacity: 0.7;
  flex-shrink: 0;
}

.documento-produto-item .doc-info {
  flex: 1;
}

.documento-produto-item .doc-info strong {
  display: block;
  color: #1e40af;
  font-size: 0.9rem;
  margin-bottom: 0.25rem;
}

.documento-produto-item .doc-info small {
  color: #64748b;
  font-size: 0.8rem;
}

.documento-produto-item .doc-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.btn-visualizar-doc {
  background: #3182ce;
  color: white;
  padding: 0.5rem 0.75rem;
  border-radius: 4px;
  text-decoration: none;
  font-size: 0.8rem;
  transition: all 0.3s ease;
  border: none;
  cursor: pointer;
}

.btn-visualizar-doc:hover {
  background: #2c5aa0;
}

.btn-adicionar-doc {
  background: #48bb78;
  color: white;
  padding: 0.5rem 0.75rem;
  border-radius: 4px;
  font-size: 0.8rem;
  transition: all 0.3s ease;
  border: none;
  cursor: pointer;
  min-width: 90px;
}

.btn-adicionar-doc:hover:not(.adicionado) {
  background: #38a169;
}

.btn-adicionar-doc.adicionado {
  background: #68d391;
  cursor: default;
}

.btn-adicionar-doc.adicionado:hover {
  background: #68d391;
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

/* Estilos para a seção de documentação */
.documentacao-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.documentacao-info {
  background: #f8f9fa;
  padding: 1.5rem;
  border-radius: 12px;
  border-left: 4px solid #2c3e50;
}

.documentacao-info p {
  margin: 0.5rem 0;
  color: #4a5568;
}

.documentos-section {
  background: #f8f9fa;
  border-radius: 12px;
  padding: 1.5rem;
}

.documentos-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.documentos-header h4 {
  color: #2d3748;
  margin: 0;
}

.documentos-vazio {
  text-align: center;
  padding: 3rem;
  color: #718096;
}

.documentos-lista {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 2rem;
}

.documento-item {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.documento-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex: 1;
}

.documento-icon {
  font-size: 2rem;
  opacity: 0.7;
}

.documento-detalhes h5 {
  color: #2d3748;
  margin: 0 0 0.25rem 0;
}

.documento-tipo {
  color: #4a5568;
  margin: 0.25rem 0;
  font-size: 0.9rem;
}

.documento-data {
  color: #718096;
  margin: 0;
  font-size: 0.8rem;
}

.documento-acoes {
  display: flex;
  gap: 0.5rem;
}

.btn-visualizar {
  background: #3182ce;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.8rem;
  transition: all 0.3s ease;
}

.btn-visualizar:hover {
  background: #2c5aa0;
}

.numeracao-info {
  background: #e6fffa;
  border: 1px solid #b2f5ea;
  border-radius: 8px;
  padding: 1rem;
  margin-top: 1rem;
}

.numeracao-info h4 {
  color: #2d3748;
  margin: 0 0 0.5rem 0;
}

.numeracao-info p {
  color: #4a5568;
  margin: 0.5rem 0;
}

.exemplo-numeracao {
  background: white;
  padding: 1rem;
  border-radius: 6px;
  border: 1px solid #b2f5ea;
  margin-top: 0.5rem;
}

.exemplo-numeracao strong {
  color: #2d3748;
  display: block;
  margin-bottom: 0.25rem;
}

.exemplo-numeracao small {
  color: #718096;
}

.paginas-fixas,
.paginas-documentos {
  margin: 1rem 0;
}

.paginas-fixas ul,
.paginas-documentos ul {
  margin: 0.5rem 0;
  padding-left: 1.5rem;
}

.paginas-fixas li,
.paginas-documentos li {
  margin: 0.25rem 0;
  color: #4a5568;
}

.paginas-documentos span {
  color: #718096;
  font-style: italic;
}

/* Estilos específicos para edital */
.edital-section {
  background: #f8f9fa;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  border: 1px solid #e2e8f0;
}

.edital-header h4 {
  color: #2d3748;
  margin: 0 0 0.5rem 0;
  font-size: 1.2rem;
}

.edital-header p {
  color: #4a5568;
  margin: 0 0 1.5rem 0;
  font-size: 0.95rem;
}

.edital-form {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  border: 1px solid #e2e8f0;
}

.edital-upload {
  border: 2px dashed #cbd5e0;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  transition: all 0.3s ease;
  cursor: pointer;
}

.edital-upload:hover {
  border-color: #2c3e50;
  background: #f8f9fa;
}

.edital-upload.dragover {
  border-color: #2c3e50;
  background: #e6fffa;
  border-style: solid;
}

.edital-upload.has-file {
  border-color: #48bb78;
  background: #f0fff4;
}

.upload-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.upload-icon {
  font-size: 3rem;
  opacity: 0.5;
}

.upload-area p {
  margin: 0;
  color: #4a5568;
}

.btn-link {
  background: none;
  border: none;
  color: #2c3e50;
  text-decoration: underline;
  cursor: pointer;
  font-weight: 600;
}

.btn-link:hover {
  color: #1a202c;
}

.upload-area small {
  color: #718096;
  font-size: 0.8rem;
  margin-top: 0.5rem;
}

.arquivo-selecionado {
  display: flex;
  align-items: center;
  justify-content: center;
}

.arquivo-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: white;
  padding: 1rem;
  border-radius: 8px;
  border: 1px solid #48bb78;
  box-shadow: 0 2px 4px rgba(72, 187, 120, 0.1);
}

.arquivo-icon {
  font-size: 2rem;
  color: #48bb78;
}

.arquivo-dados {
  flex: 1;
}

.arquivo-dados strong {
  display: block;
  color: #2d3748;
  margin-bottom: 0.25rem;
}

.arquivo-dados small {
  color: #718096;
}

.btn-remover-arquivo {
  background: #fed7d7;
  color: #e53e3e;
  border: none;
  padding: 0.5rem;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-remover-arquivo:hover {
  background: #feb2b2;
}

.edital-checklist {
  background: #e6fffa;
  border: 1px solid #b2f5ea;
  border-radius: 8px;
  padding: 1rem;
  margin-top: 1rem;
}

.edital-checklist h5 {
  color: #2d3748;
  margin: 0 0 0.5rem 0;
}

.edital-checklist p {
  color: #4a5568;
  margin: 0.5rem 0;
}

.checklist-items {
  list-style: none;
  padding: 0;
  margin: 0.5rem 0 0 0;
}

.checklist-items li {
  margin: 0.5rem 0;
  color: #2d3748;
  font-size: 0.9rem;
}

.edital-acao {
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
  text-align: center;
}

.btn-vincular-edital {
  background: #2c3e50;
  color: white;
  border: none;
  padding: 0.75rem 2rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 1rem;
}

.btn-vincular-edital:hover:not(:disabled) {
  background: #1a202c;
  transform: translateY(-1px);
}

.btn-vincular-edital:disabled {
  background: #a0aec0;
  cursor: not-allowed;
  transform: none;
}

.edital-vinculado {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  border: 1px solid #48bb78;
}

.vinculado-success {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: #f0fff4;
  border-radius: 8px;
  border: 1px solid #9ae6b4;
}

.success-icon {
  font-size: 2rem;
  color: #48bb78;
  flex-shrink: 0;
}

.success-info {
  flex: 1;
}

.success-info h5 {
  color: #2d3748;
  margin: 0 0 0.5rem 0;
}

.success-info p {
  color: #4a5568;
  margin: 0.25rem 0;
  font-size: 0.9rem;
}

.btn-editar-edital {
  background: #e2e8f0;
  color: #2d3748;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.3s ease;
}

.btn-editar-edital:hover {
  background: #cbd5e0;
}

.form-group input.error {
  border-color: #e53e3e;
  box-shadow: 0 0 0 3px rgba(229, 62, 62, 0.1);
}

.error-msg {
  color: #e53e3e;
  font-size: 0.8rem;
  margin-top: 0.25rem;
}

.help-text {
  color: #718096;
  font-size: 0.8rem;
  margin-top: 0.25rem;
}

/* Estilos para seleção de editais */
.btn-carregar-editais {
  background: #3182ce;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 0.5rem;
}

.btn-carregar-editais:hover:not(:disabled) {
  background: #2c5aa0;
  transform: translateY(-1px);
}

.btn-carregar-editais:disabled {
  background: #a0aec0;
  cursor: not-allowed;
}

.editais-lista {
  margin: 1.5rem 0;
}

.editais-lista h5 {
  color: #2d3748;
  margin: 0 0 1rem 0;
}

.editais-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  max-height: 400px;
  overflow-y: auto;
}

.edital-item {
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

.edital-item:hover {
  border-color: #3182ce;
  box-shadow: 0 4px 12px rgba(49, 130, 206, 0.1);
  transform: translateY(-2px);
}

.edital-item.selecionado {
  border-color: #48bb78;
  background: #f0fff4;
  box-shadow: 0 4px 12px rgba(72, 187, 120, 0.2);
}

.edital-info {
  flex: 1;
}

.edital-info h6 {
  color: #2d3748;
  margin: 0 0 0.5rem 0;
  font-size: 1.1rem;
  font-weight: 600;
}

.edital-data {
  color: #4a5568;
  margin: 0.25rem 0;
  font-size: 0.9rem;
}

.edital-tipo {
  color: #718096;
  margin: 0.25rem 0;
  font-size: 0.85rem;
  font-style: italic;
}

.edital-produtos {
  color: #3182ce;
  font-size: 0.8rem;
  margin-top: 0.5rem;
  font-weight: 500;
}

.edital-status {
  flex-shrink: 0;
  margin-left: 1rem;
}

.status-ativo {
  background: #c6f6d5;
  color: #22543d;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 600;
}

.status-inativo {
  background: #fed7d7;
  color: #c53030;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 600;
}

.editais-vazio {
  text-align: center;
  padding: 3rem;
  color: #718096;
}

.editais-vazio .vazio-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.editais-vazio p {
  margin: 0.5rem 0;
  font-weight: 500;
}

.editais-vazio small {
  color: #a0aec0;
}

.edital-selecionado {
  margin: 1.5rem 0;
  background: #f0fff4;
  border: 1px solid #9ae6b4;
  border-radius: 8px;
  padding: 1rem;
}

.edital-selecionado h5 {
  color: #22543d;
  margin: 0 0 1rem 0;
}

.edital-preview {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  background: white;
  padding: 1rem;
  border-radius: 6px;
  border: 1px solid #c6f6d5;
}

.preview-info {
  flex: 1;
}

.preview-info strong {
  display: block;
  color: #2d3748;
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
}

.preview-info p {
  margin: 0.25rem 0;
  color: #4a5568;
  font-size: 0.9rem;
}

.preview-acoes {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
  margin-left: 1rem;
}

.btn-ver-edital {
  background: #3182ce;
  color: white;
  padding: 0.5rem 0.75rem;
  border-radius: 4px;
  text-decoration: none;
  font-size: 0.8rem;
  transition: all 0.3s ease;
}

.btn-ver-edital:hover {
  background: #2c5aa0;
}

.aviso-pdf {
  color: #718096;
  font-style: italic;
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  background: #f7fafc;
}

.btn-remover-selecao {
  background: #fed7d7;
  color: #c53030;
  border: none;
  padding: 0.5rem 0.75rem;
  border-radius: 4px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-remover-selecao:hover {
  background: #feb2b2;
}

/* Estilo para o botão ver cadastro completo */
.btn-ver-cadastro {
  background: #3182ce;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 0.5rem;
}

.btn-ver-cadastro:hover {
  background: #2c5aa0;
}

.especificacoes-content {
  display: flex;
  flex-direction: column;
}

.especificacoes-content p {
  margin: 0 0 0.5rem 0;
  color: #4a5568;
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