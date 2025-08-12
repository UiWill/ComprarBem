<template>
  <div class="processos-container">
    <div class="content-wrapper">
      <aside class="sidebar">
        <div class="iniciar-processo-section">
          <h3>🏛️ Processos Administrativos</h3>
          <div class="sistema-titulo">
            <p class="sistema-nome">Sistema Comprar Bem</p>
            <p class="sistema-slogan">Compras Públicas Inteligentes</p>
          </div>
          
          <div class="botoes-principais">
            <button @click="abrirAssistente('padronizacao')" class="btn-processo padronizacao">
              <span class="icone">✅</span>
              <div class="texto">
                <strong>Padronização</strong>
                <small>Inclusão de marcas de produtos no Catálogo</small>
              </div>
            </button>
            
            <button @click="abrirAssistente('despadronizacao')" class="btn-processo despadronizacao">
              <span class="icone">❌</span>
              <div class="texto">
                <strong>Despadronização</strong>
                <small>Exclusão de marcas de produtos do Catálogo</small>
              </div>
            </button>
          </div>
        </div>

        <div class="filter-section">
          <h3>🔍 Filtros</h3>
          
          <div class="filter-group">
            <label>📁 Tipo de Processo</label>
            <select v-model="filtroTipo" @change="filtrarProcessos">
              <option value="">Todos os tipos</option>
              <option value="padronizacao">✅ Padronização</option>
              <option value="despadronizacao">❌ Despadronização</option>
            </select>
          </div>

          <div class="filter-group">
            <label>📊 Status</label>
            <select v-model="filtroStatus" @change="filtrarProcessos">
              <option value="">Todos os status</option>
              
              <!-- STATUS PADRONIZAÇÃO (VERDE) - Sequência lógica do cliente -->
              <optgroup label="🟢 PADRONIZAÇÃO">
                <option value="rascunho">📝 Em Criação</option>
                <option value="criado_cpm">🎯 Criado pela CPM</option>
                <option value="aprovado_cpm">📋 Aprovado pela CPM</option>
                <option value="assinado_admin">✅ Assinado pelo Órgão</option>
                <option value="julgamento_ccl">⚖️ Julgamento CCL</option>
                <option value="aprovado_ccl">💜 Aprovado pela CCL</option>
                <option value="aprovado_juridico">⚖️ Aprovado Juridicamente</option>
                <option value="edital_publicado">📃 Com Edital Publicado</option>
                <option value="homologado">✅ Com Homologação</option>
                <option value="finalizado">🏆 Finalizado</option>
                
                <!-- Status de Rejeição -->
                <option value="rejeitado_cpm">❌ Rejeitado pela CPM</option>
                <option value="rejeitado_admin">❌ Rejeitado pelo Órgão</option>
                <option value="rejeitado_ccl">❌ Rejeitado pela CCL</option>
                <option value="rejeitado_juridico">❌ Rejeitado Juridicamente</option>
                <option value="rejeitado_final">❌ Rejeitado Final</option>
                
                <!-- Status Antigos (Compatibilidade) -->
                <option value="aguardando_aprovacao">🔄 Aguardando Aprovação (Legado)</option>
                <option value="iniciado">🆕 Iniciado (Legado)</option>
                <option value="analise_cppm">🔍 Análise CPPM (Legado)</option>
              </optgroup>
              
              <!-- STATUS DESPADRONIZAÇÃO (VERMELHO) - Sequência lógica do cliente -->
              <optgroup label="🔴 DESPADRONIZAÇÃO">
                <option value="em_criacao_desp">📝 Em Criação</option>
                <option value="criado_cpm_desp">🎯 Criado pela CPM</option>
                <option value="submetido_autoridade_desp">📋 Submetido à Autoridade Competente</option>
                <option value="abertura_autorizada_desp">✅ Abertura Autorizada</option>
                <option value="aviso_publicado">📢 Com Aviso Publicado</option>
                <option value="com_recurso_desp">📝 Com Recurso Administrativo</option>
                <option value="homologado_desp">✅ Com Homologação</option>
                <option value="excluindo_marcas">❌ Excluindo Marcas do Catálogo</option>
              </optgroup>
              
              <!-- STATUS ANTIGOS (COMPATIBILIDADE) -->
              <optgroup label="📁 LEGADOS">
                <option value="rascunho">📝 Rascunho</option>
                <option value="iniciado">🆕 Iniciado</option>
                <option value="analise_cppm">🔍 Análise CPPM</option>
                <option value="julgamento_ccl">⚖️ Julgamento CCL</option>
                <option value="finalizado">✅ Finalizado</option>
              </optgroup>
            </select>
          </div>

          <div class="filter-group">
            <label>🔎 Buscar Processos</label>
            <input 
              type="text" 
              v-model="termoBusca" 
              @input="filtrarProcessos"
              placeholder="Número do processo ou objeto..."
              class="search-input"
            >
          </div>

          <div class="filter-group">
            <label>📊 Ordenar por</label>
            <select v-model="ordenacao" @change="filtrarProcessos">
              <option value="data_desc">Mais recentes</option>
              <option value="data_asc">Mais antigos</option>
              <option value="numero_asc">Número (crescente)</option>
              <option value="numero_desc">Número (decrescente)</option>
              <option value="status">Por status</option>
            </select>
          </div>

          <div class="stats-section">
            <h4>📈 Estatísticas</h4>
            <div class="stats-item">
              <span class="stats-label">Total:</span>
              <span class="stats-value">{{ processos.length }}</span>
            </div>
            <div class="stats-item">
              <span class="stats-label">Filtrados:</span>
              <span class="stats-value">{{ processosFiltrados.length }}</span>
            </div>
            <div class="stats-item" v-if="estatisticas">
              <span class="stats-label">Em andamento:</span>
              <span class="stats-value">{{ estatisticas.por_status?.analise_cppm || 0 }}</span>
            </div>
          </div>
        </div>

      </aside>

      <section class="processos-section">
        <div class="processos-header">
          <h3>Processos Administrativos ({{ processosFiltrados.length }})</h3>
          <div class="view-options">
            <button @click="visualizacao = 'grid'" :class="{ active: visualizacao === 'grid' }">
              ⊞ Grade
            </button>
            <button @click="visualizacao = 'list'" :class="{ active: visualizacao === 'list' }">
              ☰ Lista
            </button>
          </div>
        </div>

        <div v-if="carregando" class="loading">
          <div class="spinner"></div>
          <p>Carregando processos...</p>
        </div>

        <div v-else-if="processosFiltrados.length === 0" class="empty-state">
          <div class="empty-icon">🏛️</div>
          <h4>Nenhum processo encontrado</h4>
          <p>Inicie um novo processo ou ajuste os filtros de busca</p>
          <button @click="abrirAssistente()" class="btn-primary">
            🆕 Iniciar Primeiro Processo
          </button>
        </div>

        <div v-else class="processos-container" :class="visualizacao">
          <div 
            v-for="processo in processosFiltrados" 
            :key="processo.id"
            @click="visualizarProcesso(processo)"
            class="processo-card"
          >
            <div class="processo-header">
              <div class="processo-numero">
                <span class="numero">{{ processo.numero_processo }}</span>
                <span class="tipo" :class="processo.tipo_processo">
                  {{ obterTipoProcesso(processo.tipo_processo).icone }}
                  {{ obterTipoProcesso(processo.tipo_processo).label }}
                </span>
              </div>
              <div class="processo-status">
                <span class="status-badge" :class="obterStatusProcesso(processo.status).cor">
                  {{ obterStatusProcesso(processo.status).label }}
                </span>
              </div>
            </div>
            
            <div class="processo-info">
              <h4>{{ processo.nome_orgao }}</h4>
              <p class="interessado">Interessado: {{ processo.unidade_interessada }}</p>
              <p class="objeto">{{ processo.objeto.substring(0, 150) }}...</p>
            </div>
            
            <div class="processo-meta">
              <div class="meta-item">
                <span class="meta-label">📄 Documentos:</span>
                <span class="meta-value">{{ processo.total_documentos || 0 }}</span>
              </div>
              <div class="meta-item">
                <span class="meta-label">📅 Autuação:</span>
                <span class="meta-value">{{ formatarData(processo.data_autuacao) }}</span>
              </div>
              <div class="meta-item" v-if="processo.total_produtos">
                <span class="meta-label">📦 Produtos:</span>
                <span class="meta-value">{{ processo.total_produtos }}</span>
              </div>
            </div>
            
            <div class="processo-actions">
              <button @click.stop="abrirProcesso(processo)" class="btn-action primary">
                👁️ Ver
              </button>
              <button 
                v-if="podeEditarProcesso(processo)" 
                @click.stop="editarProcesso(processo)" 
                class="btn-action">
                ✏️ Editar
              </button>
              <button @click.stop="gerarRelatorio(processo)" class="btn-action">
                📄 PDF
              </button>
            </div>
            
          </div>
        </div>
      </section>
    </div>

    <!-- Assistente de Processo -->
    <div v-if="mostrarAssistente" class="modal-overlay assistente-overlay" @click="fecharAssistente">
      <div class="modal assistente-modal" @click.stop>
        <div class="assistente-header-modal">
          <h3>🎯 Assistente de Processo Administrativo</h3>
          <button @click="fecharAssistente" class="btn-close">&times;</button>
        </div>
        <div class="assistente-content">
          <AssistenteProcesso 
            :processo-edicao="processoParaEditar"
            :modo-edicao="modoEdicao"
            :tipo-processo-inicial="tipoProcessoInicial"
            @processo-criado="processoCriado"
            @cancelar="fecharAssistente"
          />
        </div>
      </div>
    </div>

    <!-- Modal de Visualização de Processo -->
    <div v-if="processoSelecionado" class="modal-overlay" @click="fecharVisualizacaoProcesso">
      <div class="modal modal-large" @click.stop>
        <div class="modal-header">
          <div class="processo-title-section">
            <div class="processo-icon-large">
              {{ obterTipoProcesso(processoSelecionado.tipo_processo).icone }}
            </div>
            <div>
              <h3>Processo {{ processoSelecionado.numero_processo }}</h3>
              <span class="processo-tipo-badge" :class="processoSelecionado.tipo_processo">
                {{ obterTipoProcesso(processoSelecionado.tipo_processo).label }}
              </span>
              <span class="processo-status-badge" :class="obterStatusProcesso(processoSelecionado.status).cor">
                {{ obterStatusProcesso(processoSelecionado.status).label }}
              </span>
            </div>
          </div>
          <button @click="fecharVisualizacaoProcesso" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <div class="processo-viewer-container">
            <div class="processo-details-panel">
              <h4>📋 Informações do Processo</h4>
              
              <div class="detail-item">
                <strong>🏛️ Órgão:</strong>
                <p>{{ processoSelecionado.nome_orgao }}</p>
              </div>
              
              <div class="detail-item">
                <strong>👥 Interessado:</strong>
                <p>{{ processoSelecionado.unidade_interessada }}</p>
              </div>
              
              <div class="detail-item">
                <strong>📅 Data de Autuação:</strong>
                <span>{{ formatarData(processoSelecionado.data_autuacao) }}</span>
              </div>
              
              <div class="detail-item" v-if="processoSelecionado.data_finalizacao">
                <strong>🏁 Data de Finalização:</strong>
                <span>{{ formatarData(processoSelecionado.data_finalizacao) }}</span>
              </div>
              
              <div class="detail-item">
                <strong>📄 Documentos:</strong>
                <span>{{ processoSelecionado.total_documentos || 0 }}</span>
              </div>
              
              <div class="detail-item" v-if="processoSelecionado.total_produtos">
                <strong>📦 Produtos:</strong>
                <span>{{ processoSelecionado.total_produtos }}</span>
              </div>
              
              <div class="detail-item" v-if="processoSelecionado.observacoes">
                <strong>💭 Observações:</strong>
                <p>{{ processoSelecionado.observacoes }}</p>
              </div>
              
              <div class="processo-actions-panel">
                <div class="actions-grid">
                  <button @click="gerarRelatorio(processoSelecionado)" class="action-btn action-btn-primary">
                    <span class="btn-icon">📄</span>
                    <span class="btn-text">Gerar Relatório PDF</span>
                  </button>
                  
                  <!-- Botão para enviar para análise administrativa (CPM apenas) -->
                  <button 
                    v-if="podeEnviarParaAnalise(processoSelecionado)" 
                    @click="enviarParaAnaliseAdministrativa(processoSelecionado)" 
                    class="action-btn action-btn-success"
                  >
                    <span class="btn-icon">🚀</span>
                    <span class="btn-text">Enviar para Análise</span>
                  </button>
                  
                  <!-- Botões específicos para Órgão Administrativo em processos aguardando assinatura -->
                  <button 
                    v-if="podeOrgaoAssinarDocumento(processoSelecionado)" 
                    @click="assinarEEnviarProcesso(processoSelecionado)" 
                    class="action-btn action-btn-success"
                  >
                    <span class="btn-icon">✍️</span>
                    <span class="btn-text">Assinar e Enviar para CCL</span>
                  </button>
                  
                  <button 
                    v-if="podeDevolverParaCPM(processoSelecionado)" 
                    @click="abrirModalDevolucao(processoSelecionado)" 
                    class="action-btn action-btn-warning"
                  >
                    <span class="btn-icon">↩️</span>
                    <span class="btn-text">Devolver para CPM</span>
                  </button>
                  
                  <!-- Botão para tramitar processo assinado para CCL -->
                  <button 
                    v-if="podeTramitarParaCCL(processoSelecionado)" 
                    @click="tramitarProcessoParaCCL(processoSelecionado)" 
                    class="action-btn action-btn-success"
                  >
                    <span class="btn-icon">⚖️</span>
                    <span class="btn-text">{{ obterTextoBotaoTramitacao(processoSelecionado) }}</span>
                  </button>
                  
                  <button @click="verTramitacao(processoSelecionado)" class="action-btn action-btn-info">
                    <span class="btn-icon">📋</span>
                    <span class="btn-text">Ver Tramitação</span>
                  </button>
                  
                  <!-- Botão para reenviar processo devolvido (CPM apenas) -->
                  <button 
                    v-if="podeReenviarProcesso(processoSelecionado)" 
                    @click="reenviarProcessoDevolvido(processoSelecionado)" 
                    class="action-btn action-btn-success"
                  >
                    <span class="btn-icon">🔄</span>
                    <span class="btn-text">Reenviar Processo</span>
                  </button>
                  
                  <button @click="adicionarDocumento(processoSelecionado)" class="action-btn action-btn-secondary">
                    <span class="btn-icon">📎</span>
                    <span class="btn-text">{{ obterTextoAdicionarDocumento() }}</span>
                  </button>
                  
                  <button 
                    v-if="podeEditarProcesso(processoSelecionado)" 
                    @click="editarProcesso(processoSelecionado)" 
                    class="action-btn action-btn-warning">
                    <span class="btn-icon">✏️</span>
                    <span class="btn-text">Editar Processo</span>
                  </button>
                </div>
              </div>
            </div>
            
            <div class="processo-content-panel">
              <h4>🎯 Objeto do Processo</h4>
              <div class="objeto-container">
                <p class="objeto-texto">{{ processoSelecionado.objeto }}</p>
              </div>
              
              <!-- Seção de Motivo da Devolução (se houver) -->
              <div v-if="processoFoiDevolvido(processoSelecionado)" class="devolucao-info">
                <h4>⚠️ Motivo da Devolução</h4>
                <div class="devolucao-container">
                  <div class="devolucao-header">
                    <span class="devolucao-status">🔴 {{ obterNomeStatus(processoSelecionado.status) }}</span>
                    <span class="devolucao-data">{{ new Date(processoSelecionado.data_devolucao).toLocaleDateString('pt-BR') }}</span>
                  </div>
                  
                  <div class="motivo-devolucao">
                    <h5>📝 Motivo:</h5>
                    <p class="motivo-texto">{{ processoSelecionado.motivo_devolucao || 'Motivo não informado' }}</p>
                  </div>
                  
                  <div v-if="processoSelecionado.observacoes_devolucao" class="observacoes-devolucao">
                    <h5>📝 Observações:</h5>
                    <p class="observacoes-texto">{{ processoSelecionado.observacoes_devolucao }}</p>
                  </div>
                  
                  <div class="acao-requerida">
                    <p><strong>📝 Ação Requerida:</strong> Corrija os pontos mencionados e reenvie o processo.</p>
                  </div>
                </div>
              </div>
              
              <h4>📄 Documentos do Processo</h4>
              <div class="documentos-container">
                <div v-if="documentosProcessoFiltrados.length === 0" class="empty-documentos">
                  <p>⚠️ Nenhum documento encontrado</p>
                  <button @click="carregarDocumentosProcesso(processoSelecionado.id)" class="btn-secondary">
                    🔄 Recarregar
                  </button>
                </div>
                <div v-else class="lista-documentos">
                  <div 
                    v-for="doc in documentosProcessoFiltrados" 
                    :key="doc.id"
                    class="documento-item"
                  >
                    <div class="doc-numero">{{ doc.folha_numero || `Fl. ${String(doc.numero_sequencial || 0).padStart(3, '0')}` }}</div>
                    <div class="doc-info">
                      <h5>{{ doc.titulo }}</h5>
                      <p>{{ doc.descricao }}</p>
                      <small>{{ formatarData(doc.data_autuacao) }}</small>
                    </div>
                    <div class="doc-status">
                      <span v-if="doc.assinado" class="status-assinado">✅ Assinado</span>
                      <span v-else-if="doc.status === 'disponivel'" class="status-disponivel">📄 Disponível</span>
                      <span v-else class="status-pendente">⏳ Pendente</span>
                    </div>
                    <div class="doc-actions">
                      <button v-if="doc.arquivo_url || doc.url_arquivo" @click="visualizarDocumento(doc)" class="btn-visualizar">
                        👁️ Ver
                      </button>
                      <button v-else-if="doc.tipo_documento === 'EDITAL'" @click="buscarUrlEdital(doc)" class="btn-visualizar">
                        👁️ Ver
                      </button>
                      <span v-else class="no-file">
                        📄 Sem arquivo
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div v-if="false" class="manual-preview">
                  <div class="manual-content">
                    <div class="manual-header">
                      <h5>📖 Manual do Sistema Comprar Bem</h5>
                      <p class="manual-subtitle">Compras Públicas Inteligentes - Guia Completo</p>
                    </div>
                    
                    <div class="manual-nav">
                      <button 
                        v-for="(secao, index) in manuaisSections" 
                        :key="index"
                        @click="secaoAtiva = index"
                        :class="{ active: secaoAtiva === index }"
                        class="nav-btn"
                      >
                        {{ secao.icone }} {{ secao.titulo }}
                      </button>
                    </div>

                    <div class="manual-sections">
                      <div v-if="secaoAtiva === 0" class="manual-section">
                        <h6>🎯 O que é o Sistema Comprar Bem</h6>
                        <div class="subsection">
                          <h7>🔍 Objetivo Principal</h7>
                          <p>O sistema <strong>Comprar Bem</strong> foi criado para facilitar e otimizar os processos de compras públicas, implementando a pré-qualificação técnica de produtos conforme a <strong>Lei Federal nº 14.133/2021</strong>.</p>
                          
                          <h7>🎡 Conceito "Comprar Bem"</h7>
                          <p>Significa conseguir adquirir os produtos <strong>certos</strong>, técnica e funcionalmente adequados para atender às necessidades do órgão, com <em>qualidade, economicidade e conformidade legal</em>.</p>
                          
                          <h7>🎯 Como Funciona</h7>
                          <p>O sistema permite que os órgãos públicos:</p>
                          <ul>
                            <li><strong>Pré-qualifiquem produtos</strong> antes das compras</li>
                            <li><strong>Tenham segurança</strong> de que estão comprando produtos adequados</li>
                            <li><strong>Agilizem licitações</strong> usando o catálogo pré-aprovado</li>
                            <li><strong>Avaliem fornecedores</strong> após as compras</li>
                          </ul>
                          
                          <h7>🔄 Processo Completo</h7>
                          <div class="workflow">
                            <div class="step">Solicitação de Pré-qualificação</div>
                            <div class="step">Análise técnica pela CPM</div>
                            <div class="step">Julgamento pela CCL</div>
                            <div class="step">Emissão da DCB</div>
                            <div class="step">Inclusão no Catálogo</div>
                            <div class="step">Uso em Licitações</div>
                          </div>
                        </div>
                      </div>

                      <div v-if="secaoAtiva === 1" class="manual-section">
                        <h6>📊 Dashboard CPM - Comissão de Padronização</h6>
                        <div class="subsection">
                          <h7>🎯 O que faz a CPM</h7>
                          <p>A CPM é responsável por <strong>analisar tecnicamente</strong> os produtos que serão pré-qualificados. É uma equipe de servidores especializados que garante que apenas produtos adequados entrem no catálogo.</p>
                          
                          <h7>📋 Como Funciona a Análise</h7>
                          <ul>
                            <li><strong>Recebe solicitações</strong> de pré-qualificação</li>
                            <li><strong>Analisa documentação</strong> técnica do produto</li>
                            <li><strong>Avalia amostras</strong> (quando necessário)</li>
                            <li><strong>Emite parecer</strong> técnico fundamentado</li>
                            <li><strong>Recomenda</strong> aprovação ou reprovação</li>
                          </ul>
                          
                          <h7>⏰ Prazos da CPM</h7>
                          <ul>
                            <li><strong>Análise técnica:</strong> Até 10 dias úteis</li>
                            <li><strong>Parecer:</strong> Deve ser fundamentado e detalhado</li>
                            <li><strong>Envio para CCL:</strong> Após conclusão da análise</li>
                          </ul>
                          
                          <h7>📋 Como Usar o Painel CPM</h7>
                          <ul>
                            <li><strong>Produtos Pendentes:</strong> Novos pedidos de pré-qualificação</li>
                            <li><strong>Em Análise:</strong> Produtos sendo avaliados pela equipe</li>
                            <li><strong>Pareceres Prontos:</strong> Análises concluídas</li>
                            <li><strong>Alertas de Prazo:</strong> Produtos com prazo vencendo</li>
                          </ul>
                          
                          <h7>✅ Critérios de Aprovação</h7>
                          <ul>
                            <li><strong>Conformidade técnica</strong> com especificações</li>
                            <li><strong>Documentação completa</strong> e adequada</li>
                            <li><strong>Qualidade do produto</strong> compatvel com o uso</li>
                            <li><strong>Segurança</strong> e adequação às normas</li>
                          </ul>
                        </div>
                      </div>

                      <div v-if="secaoAtiva === 2" class="manual-section">
                        <h6>⚖️ Dashboard CCL - Comissão de Contratação</h6>
                        <div class="subsection">
                          <h7>🎯 O que faz a CCL</h7>
                          <p>A CCL é responsável pelo <strong>julgamento administrativo</strong> dos processos de pré-qualificação. Ela analisa os pareceres da CPM e toma a decisão final sobre aprovar ou reprovar produtos.</p>
                          
                          <h7>📋 Como Funciona o Julgamento</h7>
                          <ul>
                            <li><strong>Recebe pareceres</strong> técnicos da CPM</li>
                            <li><strong>Analisa documentação</strong> administrativa</li>
                            <li><strong>Verifica conformidade</strong> legal do processo</li>
                            <li><strong>Emite ata</strong> de julgamento</li>
                            <li><strong>Abre prazo</strong> para recursos</li>
                          </ul>
                          
                          <h7>⏰ Prazos da CCL</h7>
                          <ul>
                            <li><strong>Julgamento:</strong> Após receber parecer da CPM</li>
                            <li><strong>Prazo recursal:</strong> 3 dias úteis após publicação</li>
                            <li><strong>Análise de recursos:</strong> Conforme complexidade</li>
                            <li><strong>Encaminhamento:</strong> Para autoridade competente</li>
                          </ul>
                          
                          <h7>📋 Como Usar o Painel CCL</h7>
                          <ul>
                            <li><strong>Aguardando Julgamento:</strong> Pareceres da CPM para analisar</li>
                            <li><strong>Atas Publicadas:</strong> Decisões aguardando prazo recursal</li>
                            <li><strong>Com Recursos:</strong> Processos com impugnações</li>
                            <li><strong>Prontos para Homologação:</strong> Processos finalizados</li>
                          </ul>
                          
                          <h7>⚖️ Decisões Possíveis</h7>
                          <ul>
                            <li><strong>Aprovado:</strong> Produto atende aos requisitos</li>
                            <li><strong>Aprovado com ressalvas:</strong> Produto aprovado com restrições</li>
                            <li><strong>Reprovado:</strong> Produto não atende aos critérios</li>
                            <li><strong>Diligência:</strong> Solicitação de informações adicionais</li>
                          </ul>
                        </div>
                      </div>

                      <div v-if="secaoAtiva === 3" class="manual-section">
                        <h6>📝 DCB - Declaração de Conformidade de Bem</h6>
                        <div class="subsection">
                          <h7>🎯 O que é a DCB</h7>
                          <p>A DCB é o <strong>"certificado de aprovação"</strong> do produto. É o documento que comprova que aquele produto específico foi analisado, aprovado e pode ser comprado pelos órgãos públicos sem nova análise técnica.</p>
                          
                          <h7>📝 O que tem na DCB</h7>
                          <ul>
                            <li><strong>Nome completo do produto</strong> aprovado</li>
                            <li><strong>Marca e modelo</strong> específicos</li>
                            <li><strong>Fabricante</strong> responsável</li>
                            <li><strong>Especificações técnicas</strong> detalhadas</li>
                            <li><strong>Data de validade</strong> da aprovação</li>
                            <li><strong>Observações especiais</strong> (se houver)</li>
                          </ul>
                          
                          <h7>⏰ Validade da DCB</h7>
                          <ul>
                            <li><strong>Prazo máximo:</strong> 1 ano a partir da emissão</li>
                            <li><strong>Renovação:</strong> Possível mediante nova solicitação</li>
                            <li><strong>Cancelamento:</strong> Se o produto apresentar problemas</li>
                            <li><strong>Controle:</strong> Acompanhado via RDM</li>
                          </ul>
                          
                          <h7>📋 Como Usar a DCB</h7>
                          <ul>
                            <li><strong>Consulte no Catálogo</strong> se o produto tem DCB válida</li>
                            <li><strong>Use diretamente na licitação</strong> - não precisa nova análise</li>
                            <li><strong>Cite a DCB no edital</strong> como comprovação técnica</li>
                            <li><strong>Verifique sempre a validade</strong> antes de usar</li>
                          </ul>
                          
                          <h7>✅ Vantagens da DCB</h7>
                          <ul>
                            <li><strong>Segurança:</strong> Produto já foi analisado tecnicamente</li>
                            <li><strong>Agilidade:</strong> Não precisa nova análise na licitação</li>
                            <li><strong>Qualidade:</strong> Garantia de conformidade técnica</li>
                            <li><strong>Legal:</strong> Atende exigências da Lei 14.133/2021</li>
                          </ul>
                        </div>
                      </div>

                      <div v-if="secaoAtiva === 4" class="manual-section">
                        <h6>📊 RDM - Relatório de Desempenho de Material</h6>
                        <div class="subsection">
                          <h7>🎯 Para que serve o RDM</h7>
                          <p>O RDM serve para <strong>avaliar se os produtos comprados realmente funcionaram bem</strong>. É como uma "avaliação" que você faz do produto depois de usá-lo, para ajudar outros órgãos a decidir se devem comprar o mesmo produto.</p>
                          
                          <h7>👥 Quem faz a Avaliação</h7>
                          <ul>
                            <li><strong>Quem usa o produto</strong> no dia a dia</li>
                            <li><strong>Responsáveis pelo estoque</strong></li>
                            <li><strong>Gestores</strong> que acompanham o uso</li>
                            <li><strong>Técnicos</strong> quando necessário</li>
                          </ul>
                          
                          <h7>📊 O que é Avaliado</h7>
                          <div class="criterios">
                            <div class="criterio">
                              <strong>✅ Qualidade:</strong> O produto funcionou como esperado?
                            </div>
                            <div class="criterio">
                              <strong>⏱️ Durabilidade:</strong> Durou o tempo previsto?
                            </div>
                            <div class="criterio">
                              <strong>⚡ Eficácia:</strong> Resolveu o problema que deveria?
                            </div>
                            <div class="criterio">
                              <strong>💰 Custo-benefício:</strong> Valeu o preço pago?
                            </div>
                          </div>
                          
                          <h7>📋 Como Fazer uma Avaliação RDM</h7>
                          <ul>
                            <li><strong>Acesse o menu RDM</strong> no sistema</li>
                            <li><strong>Procure o produto</strong> que você comprou</li>
                            <li><strong>Preencha o formulário</strong> com sua experiência</li>
                            <li><strong>Seja honesto:</strong> Sua avaliação ajuda outros órgãos</li>
                            <li><strong>Envie o relatório</strong> - a CPM vai analisar</li>
                          </ul>
                          
                          <h7>✨ Importância do RDM</h7>
                          <ul>
                            <li><strong>Produtos ruins</strong> são removidos do catálogo</li>
                            <li><strong>Produtos bons</strong> continuam disponíveis</li>
                            <li><strong>Outros órgãos</strong> se beneficiam da sua experiência</li>
                            <li><strong>Melhora continu</strong> da qualidade das compras</li>
                          </ul>
                        </div>
                      </div>

                      <div v-if="secaoAtiva === 5" class="manual-section">
                        <h6>📚 Catálogo - Produtos Pré-Qualificados</h6>
                        <div class="subsection">
                          <h7>🎯 Para que serve o Catálogo</h7>
                          <p>O Catálogo é onde ficam listados todos os produtos que já foram <strong>pré-qualificados</strong> e estão aprovados para compra pelos órgãos públicos.</p>
                          
                          <h7>🔍 Como Buscar Produtos</h7>
                          <ul>
                            <li><strong>Por categoria:</strong> Escolha entre Saúde, Administrativa, TI, etc.</li>
                            <li><strong>Por nome:</strong> Digite o nome do produto que procura</li>
                            <li><strong>Por marca:</strong> Busque por fabricantes específicos</li>
                            <li><strong>Por especificação:</strong> Encontre produtos com características técnicas específicas</li>
                          </ul>
                          
                          <h7>📋 Como Usar na Prática</h7>
                          <ul>
                            <li><strong>Acesse o Catálogo</strong> no menu principal</li>
                            <li><strong>Busque o produto</strong> que precisa comprar</li>
                            <li><strong>Verifique se está pré-qualificado</strong> (tem DCB válida)</li>
                            <li><strong>Use diretamente na licitação</strong> - sem need de nova análise técnica</li>
                            <li><strong>Exporte a lista</strong> de produtos para seu edital</li>
                          </ul>
                          
                          <h7>✅ Vantagens do Catálogo</h7>
                          <ul>
                            <li>Produtos já <strong>analisados tecnicamente</strong></li>
                            <li><strong>Licitações mais rápidas</strong></li>
                            <li><strong>Menor risco</strong> de comprar produto inadequado</li>
                            <li><strong>Facilita comparação</strong> entre opções</li>
                          </ul>
                        </div>
                      </div>

                    </div>
                  </div>
                </div>
                <div v-if="false" class="lei-preview">
                  <div class="lei-content">
                    <div class="lei-header">
                      <h5>⚖️ Lei 14.133/2021 - Nova Lei de Licitações</h5>
                      <p class="lei-subtitle">Guia Prático para Gestores de Compras Públicas</p>
                    </div>
                    
                    <div class="lei-nav">
                      <button 
                        v-for="(secao, index) in leiSections" 
                        :key="index"
                        @click="secaoLeiAtiva = index"
                        :class="{ active: secaoLeiAtiva === index }"
                        class="nav-btn"
                      >
                        {{ secao.icone }} {{ secao.titulo }}
                      </button>
                    </div>

                    <div class="lei-sections">
                      <div v-if="secaoLeiAtiva === 0" class="lei-section">
                        <h6>🎯 O que Mudou com a Nova Lei</h6>
                        <div class="subsection">
                          <h7>🗓️ Quando Entrou em Vigor</h7>
                          <p>A Lei 14.133/2021 está em <strong>plena vigência desde janeiro de 2024</strong>, substituindo completamente a antiga Lei 8.666/93 que vigorou por mais de 30 anos.</p>
                          
                          <h7>🎯 Principais Objetivos</h7>
                          <ul>
                            <li><strong>Qualidade acima do preço baixo:</strong> Buscar o "resultado mais vantajoso"</li>
                            <li><strong>Modernização:</strong> Tecnologias digitais e processos eficientes</li>
                            <li><strong>Transparência:</strong> Maior controle social e publicidade</li>
                            <li><strong>Sustentabilidade:</strong> Critérios sociais e ambientais</li>
                          </ul>
                          
                          <h7>🔄 Mudança de Mentalidade</h7>
                          <div class="comparison">
                            <div class="before">
                              <h8>❌ ANTES (Lei 8.666/93)</h8>
                              <p>Foco no <strong>menor preço</strong> como critério principal</p>
                            </div>
                            <div class="after">
                              <h8>✅ AGORA (Lei 14.133/21)</h8>
                              <p>Foco no <strong>resultado mais vantajoso</strong> considerando qualidade, durabilidade e custo-benefício</p>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div v-if="secaoLeiAtiva === 1" class="lei-section">
                        <h6>📋 Modalidades de Licitação</h6>
                        <div class="subsection">
                          <h7>❌ Modalidades Extintas</h7>
                          <ul>
                            <li><strong>Tomada de Preços</strong> - Não existe mais</li>
                            <li><strong>Convite</strong> - Não existe mais</li>
                          </ul>
                          
                          <h7>✅ Modalidades Vigentes</h7>
                          <div class="modalidades">
                            <div class="modalidade">
                              <strong>📝 Pregão:</strong> OBRIGATÓRIO para bens e serviços comuns
                            </div>
                            <div class="modalidade">
                              <strong>🏢 Concorrência:</strong> Para bens/serviços especiais e obras
                            </div>
                            <div class="modalidade">
                              <strong>🔄 Diálogo Competitivo:</strong> NOVA modalidade para soluções inovadoras
                            </div>
                            <div class="modalidade">
                              <strong>🏆 Concurso:</strong> Para trabalhos técnicos e artísticos
                            </div>
                            <div class="modalidade">
                              <strong>💰 Leilão:</strong> Para venda de bens públicos
                            </div>
                          </div>
                          
                          <h7>⚡ Mudança Fundamental</h7>
                          <p>A escolha da modalidade <strong>NÃO depende mais do valor</strong>, mas da <strong>natureza do objeto</strong>.</p>
                        </div>
                      </div>

                      <div v-if="secaoLeiAtiva === 2" class="lei-section">
                        <h6>⏰ Prazos Essenciais</h6>
                        <div class="subsection">
                          <h7>📅 Prazos Para Apresentação de Propostas</h7>
                          <div class="prazos-tabela">
                            <div class="prazo-item">
                              <strong>Aquisição de Bens (menor preço):</strong>
                              <span class="prazo">8 dias úteis</span>
                            </div>
                            <div class="prazo-item">
                              <strong>Serviços Comuns (menor preço):</strong>
                              <span class="prazo">10 dias úteis</span>
                            </div>
                            <div class="prazo-item">
                              <strong>Serviços Especiais:</strong>
                              <span class="prazo">25 dias úteis</span>
                            </div>
                            <div class="prazo-item">
                              <strong>Técnica e Preço:</strong>
                              <span class="prazo">35 dias úteis</span>
                            </div>
                          </div>
                          
                          <h7>⚖️ Prazos Para Recursos</h7>
                          <ul>
                            <li><strong>Manifestação de interesse:</strong> Mínimo 10 minutos na sessão</li>
                            <li><strong>Apresentação de razões:</strong> 3 dias úteis</li>
                            <li><strong>Contrarrazões:</strong> 3 dias úteis</li>
                            <li><strong>Decisão da autoridade:</strong> 10 dias úteis</li>
                          </ul>
                        </div>
                      </div>

                      <div v-if="secaoLeiAtiva === 3" class="lei-section">
                        <h6>🎯 Pré-Qualificação na Nova Lei</h6>
                        <div class="subsection">
                          <h7>📄 Base Legal</h7>
                          <ul>
                            <li><strong>Art. 78, inciso II:</strong> Pré-qualificação como procedimento auxiliar</li>
                            <li><strong>Art. 80:</strong> Regulamentação específica da pré-qualificação permanente</li>
                            <li><strong>Art. 41, inciso II:</strong> Possibilidade de exigir marcas específicas</li>
                          </ul>
                          
                          <h7>🔄 Como Funciona</h7>
                          <div class="workflow">
                            <div class="step">Publicação do Edital</div>
                            <div class="step">Análise Técnica (10 dias)</div>
                            <div class="step">Julgamento CCL</div>
                            <div class="step">Emissão da DCB</div>
                            <div class="step">Inclusão no Catálogo</div>
                          </div>
                          
                          <h7>✅ Vantagens</h7>
                          <ul>
                            <li><strong>Licitações mais rápidas:</strong> Sem nova análise técnica</li>
                            <li><strong>Maior segurança:</strong> Produtos já certificados</li>
                            <li><strong>Padronização:</strong> Catálogo institucional</li>
                            <li><strong>Qualidade garantida:</strong> Testes prévios realizados</li>
                          </ul>
                        </div>
                      </div>

                      <div v-if="secaoLeiAtiva === 4" class="lei-section">
                        <h6>📊 Critérios de Julgamento</h6>
                        <div class="subsection">
                          <h7>🎯 Novos Critérios Disponíveis</h7>
                          <div class="criterios-lei">
                            <div class="criterio-lei">
                              <strong>💰 Menor Preço:</strong> Critério tradicional mantido
                            </div>
                            <div class="criterio-lei">
                              <strong>📈 Maior Desconto:</strong> Novo critério para negociações
                            </div>
                            <div class="criterio-lei">
                              <strong>🎯 Melhor Técnica:</strong> Foco na qualidade técnica
                            </div>
                            <div class="criterio-lei">
                              <strong>⚖️ Técnica e Preço:</strong> Combinação equilibrada
                            </div>
                            <div class="criterio-lei">
                              <strong>📈 Maior Retorno Econômico:</strong> Novo - para concessões
                            </div>
                          </div>
                          
                          <h7>🌱 Sustentabilidade</h7>
                          <ul>
                            <li><strong>Dimensão ambiental:</strong> Produtos ecológicos, menor impacto</li>
                            <li><strong>Dimensão social:</strong> Inclusão de grupos vulneráveis</li>
                            <li><strong>Ciclo de vida:</strong> Custos durante toda a vida útil</li>
                          </ul>
                        </div>
                      </div>

                      <div v-if="secaoLeiAtiva === 5" class="lei-section">
                        <h6>🔍 Transparência e Publicidade</h6>
                        <div class="subsection">
                          <h7>🌐 Obrigações de Divulgação</h7>
                          <ul>
                            <li><strong>Portal Nacional (PNCP):</strong> Todas as licitações obrigatoriamente</li>
                            <li><strong>Site oficial:</strong> Editais, resultados e contratos</li>
                            <li><strong>Diário Oficial:</strong> Avisos e extratos</li>
                            <li><strong>Audiências públicas:</strong> Para projetos relevantes</li>
                          </ul>
                          
                          <h7>📚 Catálogo Eletrônico</h7>
                          <ul>
                            <li><strong>Publicação permanente</strong> no site oficial</li>
                            <li><strong>Acesso livre</strong> para consulta</li>
                            <li><strong>Atualização automática</strong> com inclusões/exclusões</li>
                            <li><strong>Filtros por categoria</strong> para facilitar busca</li>
                          </ul>
                          
                          <h7>⚡ Benefícios da Transparência</h7>
                          <ul>
                            <li>Maior <strong>controle social</strong></li>
                            <li><strong>Redução de questionamentos</strong></li>
                            <li><strong>Segurança jurídica</strong> para gestores</li>
                            <li><strong>Facilita fiscalização</strong> pelos órgãos de controle</li>
                          </ul>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div v-if="false" class="processo-placeholder">
                  <div class="placeholder-icon">🏛️</div>
                  <h5>Processo Administrativo</h5>
                  <p>Visualização completa dos documentos em desenvolvimento</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Modal para Vincular Edital -->
      <ModalVincularEdital
        :visivel="mostrarModalEdital"
        :processo="processoSelecionado || {}"
        @edital-vinculado="onEditalVinculado"
        @fechar="fecharModalEdital"
      />
      
      <!-- Modal para Visualizar Documentação -->
      <div v-if="mostrarDocumentacao && processoSelecionado" class="modal-overlay" @click="fecharDocumentacao">
        <div class="modal-documentacao" @click.stop>
          <div class="modal-header">
            <h3>📋 Documentação dos Produtos - {{ processoSelecionado.numero_processo }}</h3>
            <button @click="fecharDocumentacao" class="btn-close">&times;</button>
          </div>
          <div class="modal-body">
            <DocumentacaoProdutos :processoId="processoSelecionado.id" />
          </div>
        </div>
      </div>

      <!-- Modal para Adicionar Documento -->
      <div v-if="mostrarModalAdicionarDoc && processoSelecionado" class="modal-overlay" @click="fecharModalAdicionarDoc">
        <div class="modal-adicionar-doc" @click.stop>
          <div class="modal-header">
            <h3>📎 Adicionar Documento - {{ processoSelecionado.numero_processo }}</h3>
            <button @click="fecharModalAdicionarDoc" class="btn-close">&times;</button>
          </div>
          <div class="modal-body">
            <div class="adicionar-documento-form">
              <div class="info-processo">
                <div class="info-item">
                  <strong>Processo:</strong> {{ processoSelecionado.numero_processo }}
                </div>
                <div class="info-item">
                  <strong>Status:</strong> <span :class="`status-${obterStatusProcesso(processoSelecionado.status).cor}`">{{ obterStatusProcesso(processoSelecionado.status).label }}</span>
                </div>
                <div class="info-item">
                  <strong>Tipo:</strong> {{ obterTipoProcesso(processoSelecionado.tipo_processo).label }}
                </div>
              </div>

              <div class="upload-section">
                <h4>📄 Selecionar Documento</h4>
                <div class="upload-area" @drop="onDropDocumento($event)" @dragover.prevent @dragenter.prevent>
                  <input ref="documentoInput" type="file" @change="onSelectDocumento($event)" multiple accept=".pdf" style="display: none;">
                  <div class="upload-content">
                    <div class="upload-icon">📎</div>
                    <p>Clique para selecionar ou arraste arquivos aqui</p>
                    <small>Formato aceito: Apenas arquivos PDF</small>
                    <button type="button" @click="$refs.documentoInput.click()" class="btn-upload-doc">
                      Selecionar Arquivos
                    </button>
                  </div>
                </div>
                
                <div v-if="documentosParaUpload.length > 0" class="documentos-selecionados">
                  <h5>📋 Documentos Selecionados:</h5>
                  <div v-for="(doc, index) in documentosParaUpload" :key="index" class="documento-item">
                    <div class="doc-info">
                      <span class="doc-nome">{{ doc.name }}</span>
                      <span class="doc-tamanho">{{ formatarTamanho(doc.size) }}</span>
                    </div>
                    <button @click="removerDocumento(index)" class="btn-remover">❌</button>
                  </div>
                </div>
                
                <!-- Informação para órgão administrativo -->
                <div v-if="isOrgaoAdministrativo()" class="info-orgao-admin">
                  <div class="alert alert-info">
                    <span>ℹ️</span>
                    <strong>Documento Assinado:</strong> Este documento será automaticamente marcado como "Documento Assinado" pelo órgão administrativo.
                  </div>
                </div>

                <div class="form-group" v-if="!isOrgaoAdministrativo()">
                  <label for="tipoDocumento">Tipo do Documento:</label>
                  <select id="tipoDocumento" v-model="tipoDocumentoSelecionado">
                    <option value="">Selecione o tipo</option>
                    <option value="COMPLEMENTAR">Documento Complementar</option>
                    <option value="CORRECAO">Correção/Retificação</option>
                    <option value="ADICIONAL">Documento Adicional</option>
                    <option value="PARECER">Parecer Técnico</option>
                    <option value="MANIFESTACAO">Manifestação</option>
                  </select>
                </div>

                <div class="form-group">
                  <label for="observacoesDoc">Observações (opcional):</label>
                  <textarea id="observacoesDoc" v-model="observacoesDocumento" rows="3" placeholder="Descreva o conteúdo do documento ou justificativa para a inclusão"></textarea>
                </div>
              </div>

              <div class="modal-actions">
                <button @click="fecharModalAdicionarDoc" class="btn-secondary">Cancelar</button>
                <button @click="uploadDocumentos" :disabled="documentosParaUpload.length === 0 || (!isOrgaoAdministrativo() && !tipoDocumentoSelecionado) || processandoUpload" class="btn-primary">
                  {{ processandoUpload ? 'Enviando...' : `📤 Adicionar ${documentosParaUpload.length} Documento${documentosParaUpload.length > 1 ? 's' : ''}` }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Modal para Ver Tramitação -->
      <div v-if="mostrarModalTramitacao && processoSelecionado" class="modal-overlay" @click="fecharModalTramitacao">
        <div class="modal-tramitacao" @click.stop>
          <div class="modal-header">
            <h3>📋 Histórico de Tramitação - {{ processoSelecionado.numero_processo }}</h3>
            <button @click="fecharModalTramitacao" class="btn-close">&times;</button>
          </div>
          <div class="modal-body">
            <div class="tramitacao-info">
              <div class="processo-info">
                <div class="info-row">
                  <span class="label">Status Atual:</span>
                  <span :class="`status-badge status-${obterStatusProcesso(processoSelecionado.status).cor}`">
                    {{ obterStatusProcesso(processoSelecionado.status).label }}
                  </span>
                </div>
                <div class="info-row">
                  <span class="label">Data de Autuação:</span>
                  <span>{{ formatarData(processoSelecionado.data_autuacao) }}</span>
                </div>
                <div class="info-row">
                  <span class="label">Tipo:</span>
                  <span>{{ obterTipoProcesso(processoSelecionado.tipo_processo).label }}</span>
                </div>
              </div>

              <!-- Ações de Tramitação -->
              <div v-if="acoesDisponiveis[processoSelecionado.id] && acoesDisponiveis[processoSelecionado.id].length > 0" class="tramitacao-actions-container">
                <h4>🔄 Ações de Tramitação</h4>
                <div class="workflow-buttons-modal">
                  <button 
                    v-for="acao in acoesDisponiveis[processoSelecionado.id]" 
                    :key="acao.tipo"
                    @click="executarAcaoTramitacao(processoSelecionado, acao)"
                    class="btn-workflow-modal"
                    :class="{ 
                      'success': acao.cor === 'success',
                      'warning': acao.cor === 'warning',
                      'danger': acao.cor === 'danger'
                    }"
                    :title="acao.descricao"
                  >
                    {{ acao.label }}
                  </button>
                </div>
              </div>

              <div class="historico-container">
                <h4>📈 Linha do Tempo</h4>
                <div v-if="historicoTramitacao.length === 0" class="sem-historico">
                  <p>⏳ Nenhuma tramitação registrada ainda</p>
                </div>
                <div v-else class="linha-tempo">
                  <div v-for="(evento, index) in historicoTramitacao" :key="index" class="evento-tramitacao">
                    <div class="evento-data">{{ formatarDataHora(evento.data_evento) }}</div>
                    <div class="evento-status">
                      <span :class="`status-badge status-${evento.cor || 'gray'}`">
                        {{ evento.status_destino }}
                      </span>
                    </div>
                    <div class="evento-descricao">{{ evento.descricao || evento.observacoes }}</div>
                    <div v-if="evento.responsavel" class="evento-responsavel">
                      👤 {{ evento.responsavel }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Modal de Confirmação de Tramitação -->
      <div v-if="mostrarModalConfirmacaoTramitacao" class="modal-overlay" @click="fecharModalConfirmacaoTramitacao">
      <div class="modal-confirmacao-tramitacao" @click.stop>
        <div class="modal-header-tramitacao">
          <div class="header-icon">
            <span class="tramitacao-icon">{{ dadosConfirmacaoTramitacao.icone }}</span>
          </div>
          <div class="header-content">
            <h3>{{ dadosConfirmacaoTramitacao.titulo }}</h3>
            <p class="processo-numero">Processo: {{ dadosConfirmacaoTramitacao.numeroProcesso }}</p>
          </div>
          <button @click="fecharModalConfirmacaoTramitacao" class="btn-close-tramitacao">&times;</button>
        </div>
        
        <div class="modal-body-tramitacao">
          <div class="confirmacao-info">
            <div class="status-flow">
              <div class="status-atual">
                <span class="status-label">Status Atual</span>
                <span class="status-badge atual">{{ dadosConfirmacaoTramitacao.statusAtual }}</span>
              </div>
              <div class="flow-arrow">→</div>
              <div class="status-proximo">
                <span class="status-label">Próximo Status</span>
                <span class="status-badge proximo">{{ dadosConfirmacaoTramitacao.proximoStatus }}</span>
              </div>
            </div>
            
            <div class="observacoes-section">
              <label for="observacoesTramitacao" class="obs-label">
                💭 Observações (opcional)
              </label>
              <textarea 
                id="observacoesTramitacao"
                v-model="observacoesTramitacao"
                class="obs-textarea"
                :placeholder="dadosConfirmacaoTramitacao.placeholderObservacoes"
                rows="3"
              ></textarea>
            </div>
            
            <div class="tramitacao-aviso">
              <div class="aviso-icon">ℹ️</div>
              <div class="aviso-texto">
                <p><strong>O que acontece após a tramitação:</strong></p>
                <ul>
                  <li>{{ dadosConfirmacaoTramitacao.consequencia1 }}</li>
                  <li>{{ dadosConfirmacaoTramitacao.consequencia2 }}</li>
                  <li>{{ dadosConfirmacaoTramitacao.consequencia3 }}</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
        
        <div class="modal-footer-tramitacao">
          <button 
            @click="fecharModalConfirmacaoTramitacao" 
            class="btn-cancelar"
          >
            ❌ Cancelar
          </button>
          <button 
            @click="confirmarTramitacao" 
            class="btn-confirmar"
            :disabled="processandoTramitacao"
          >
            <span v-if="!processandoTramitacao">
              {{ dadosConfirmacaoTramitacao.icone }} {{ dadosConfirmacaoTramitacao.textoBotao }}
            </span>
            <span v-else>
              ⏳ Processando...
            </span>
          </button>
        </div>
      </div>
    </div>
    
    <!-- Modal de Devolução para CPM -->
    <div v-if="mostrarModalDevolucao" class="modal-overlay" @click="fecharModalDevolucao">
      <div class="modal-devolucao" @click.stop>
        <div class="modal-header-devolucao">
          <div class="header-icon">
            <span class="devolucao-icon">↩️</span>
          </div>
          <div class="header-content">
            <h3>Devolver Processo para CPM</h3>
            <p>{{ processoParaDevolucao?.numero_processo }}</p>
          </div>
          <button @click="fecharModalDevolucao" class="btn-close">&times;</button>
        </div>
        
        <div class="modal-body-devolucao">
          <div class="status-flow">
            <div class="status-item status-atual">
              <span class="status-badge">📋 {{ obterNomeStatus(processoParaDevolucao?.status) }}</span>
              <span class="status-label">Status Atual</span>
            </div>
            <div class="flow-arrow">→</div>
            <div class="status-item status-destino">
              <span class="status-badge blue">✅ Criado pela CPM</span>
              <span class="status-label">Após Devolução</span>
            </div>
          </div>
          
          <div class="motivo-section">
            <label for="motivoDevolucao" class="field-label">
              <span class="label-icon">📝</span>
              Motivo da Devolução *
            </label>
            <textarea 
              id="motivoDevolucao"
              v-model="motivoDevolucao" 
              class="motivo-textarea"
              placeholder="Descreva o motivo da devolução do processo..."
              rows="4"
              required
            ></textarea>
          </div>
          
          <div class="observacoes-section">
            <label for="observacoesDevolucao" class="field-label">
              <span class="label-icon">📝</span>
              Observações Adicionais
            </label>
            <textarea 
              id="observacoesDevolucao"
              v-model="observacoesDevolucao" 
              class="observacoes-textarea"
              placeholder="Observações adicionais (opcional)..."
              rows="3"
            ></textarea>
          </div>
        </div>
        
        <div class="modal-footer-devolucao">
          <button @click="fecharModalDevolucao" class="btn-cancel">
            ❌ Cancelar
          </button>
          <button 
            @click="confirmarDevolucao" 
            class="btn-confirm-devolucao"
            :disabled="!motivoDevolucao.trim() || processandoDevolucao"
          >
            <span v-if="!processandoDevolucao">
              ↩️ Devolver para CPM
            </span>
            <span v-else>
              ⏳ Devolvendo...
            </span>
          </button>
        </div>
      </div>
    </div>
    
  </div>
</template>

<script>
import ProcessosAdministrativosService from '../../services/processosAdministrativosService'
import DocumentosAdministrativosService from '../../services/documentosAdministrativos'
import NumeracaoDocumentosService from '../../services/numeracaoDocumentosService'
import TramitacaoProcessosService from '../../services/tramitacaoProcessosService'
import AssistenteProcesso from './AssistenteProcesso.vue'
import ModalVincularEdital from './ModalVincularEdital.vue'
import DocumentacaoProdutos from './DocumentacaoProdutos.vue'
import { supabase } from '../../services/supabase'

export default {
  name: 'ProcessosAdministrativosComponent',
  components: {
    AssistenteProcesso,
    ModalVincularEdital,
    DocumentacaoProdutos
  },
  data() {
    return {
      processos: [],
      processosFiltrados: [],
      documentosProcesso: [],
      estatisticas: null,
      carregando: true,
      
      filtroTipo: '',
      filtroStatus: '',
      termoBusca: '',
      ordenacao: 'data_desc',
      visualizacao: 'grid',
      
      // Controle de fluxo
      perfilUsuario: '',
      acoesDisponiveis: {}, // Ações de tramitação por processo
      
      // Modais
      mostrarAssistente: false,
      mostrarModalEdital: false,
      mostrarDocumentacao: false,
      mostrarModalAdicionarDoc: false,
      mostrarModalTramitacao: false,
      processoSelecionado: null,
      
      // Edição
      modoEdicao: false,
      processoParaEditar: null,
      tipoProcessoInicial: null,
      
      // Dados auxiliares para visualização detalhada
      produtosProcesso: [],
      historicoTramitacao: [],
      
      // Upload de documentos
      documentosParaUpload: [],
      tipoDocumentoSelecionado: '',
      observacoesDocumento: '',
      processandoUpload: false,
      
      // Modal de confirmação de tramitação
      mostrarModalConfirmacaoTramitacao: false,
      dadosConfirmacaoTramitacao: {},
      observacoesTramitacao: '',
      processandoTramitacao: false,
      callbackConfirmacao: null,
      
      // Modal de devolução
      mostrarModalDevolucao: false,
      processoParaDevolucao: null,
      motivoDevolucao: '',
      observacoesDevolucao: '',
      processandoDevolucao: false,
    }
  },

  computed: {
    // Filtra documentos para mostrar apenas edital e documentos inseridos pelo cliente
    // Inclui: documentos oficiais, documentos dos produtos, documentos adicionais
    // Exclui: folha de rosto, DFD e documentos null/vazios
    documentosProcessoFiltrados() {
      console.log('🔍 DEBUG - Filtrando documentos. Total de documentos:', this.documentosProcesso.length)
      console.log('🔍 DEBUG - Documentos brutos:', this.documentosProcesso)
      
      return this.documentosProcesso.filter(doc => {
        console.log(`🔍 DEBUG - Analisando documento: ${doc.titulo || doc.nome_documento} (tipo: ${doc.tipo_documento})`)
        
        // ❌ EXCLUIR FOLHA DE ROSTO - todas as variações possíveis
        if (doc.tipo_documento === 'FOLHA_ROSTO' || 
            doc.tipo_documento === 'folha_rosto' ||
            (doc.nome_documento && doc.nome_documento.toLowerCase().includes('folha de rosto')) ||
            (doc.titulo && doc.titulo.toLowerCase().includes('folha de rosto'))) {
          console.log('❌ DEBUG - EXCLUINDO FOLHA DE ROSTO:', doc.titulo || doc.nome_documento)
          return false;
        }
        
        // ❌ EXCLUIR DFD - todas as variações possíveis
        if (doc.tipo_documento === 'DFD' || 
            doc.tipo_documento === 'dfd' ||
            (doc.nome_documento && (
              doc.nome_documento.toLowerCase().includes('formalização de demanda') ||
              doc.nome_documento.toLowerCase().includes('dfd')
            )) ||
            (doc.titulo && (
              doc.titulo.toLowerCase().includes('formalização de demanda') ||
              doc.titulo.toLowerCase().includes('dfd')
            ))) {
          console.log('❌ DEBUG - EXCLUINDO DFD:', doc.titulo || doc.nome_documento)
          return false;
        }
        
        // INCLUIR documentos dos produtos (SEM verificar descrição)
        if (doc.tipo_documento === 'DOCUMENTO_PRODUTO') {
          console.log('✅ DEBUG - Incluindo documento de produto:', doc.titulo || doc.nome_documento)
          return true;
        }
        
        // INCLUIR documentos adicionais (SEM verificar descrição)
        if (doc.tipo_documento === 'DOCUMENTO_ADICIONAL') {
          console.log('✅ DEBUG - Incluindo documento adicional')
          return true;
        }
        
        // INCLUIR edital (SEM verificar descrição)
        if (doc.tipo_documento === 'EDITAL') {
          console.log('✅ DEBUG - Incluindo edital')
          return true;
        }
        
        // INCLUIR documentos adicionados via modal (novos tipos)
        if (['COMPLEMENTAR', 'CORRECAO', 'ADICIONAL', 'PARECER', 'MANIFESTACAO'].includes(doc.tipo_documento)) {
          console.log('✅ DEBUG - Incluindo documento adicionado:', doc.tipo_documento, doc.titulo || doc.nome_documento)
          return true;
        }
        
        // Para outros tipos de documento, verificar se têm título
        if (!doc.titulo || doc.titulo === null || doc.titulo.trim() === '') {
          console.log('❌ DEBUG - Excluindo por falta de título')
          return false;
        }
        
        // Para documentos oficiais (não de produto), verificar descrição
        if (doc.tipo_documento !== 'DOCUMENTO_PRODUTO' && 
            doc.tipo_documento !== 'DOCUMENTO_ADICIONAL' && 
            doc.tipo_documento !== 'EDITAL' &&
            (!doc.descricao || doc.descricao === null || doc.descricao.trim() === '')) {
          console.log('❌ DEBUG - Excluindo documento oficial por falta de descrição')
          return false;
        }
        
        console.log('✅ DEBUG - Incluindo documento')
        return true;
      })
      // REMOVER DOCUMENTOS DUPLICADOS (mesmo ID exato - não título)
      .filter((doc, index, array) => {
        const isDuplicate = array.findIndex(d => d.id === doc.id) < index;
        
        if (isDuplicate) {
          console.log('🗑️ DEBUG - Removendo documento com ID duplicado:', doc.titulo, 'ID:', doc.id)
        }
        
        return !isDuplicate;
      })
      .map(doc => {
        // Remover status "pendente" - todos os documentos são visualizáveis
        return {
          ...doc,
          visualizavel: true,
          status: doc.assinado ? 'assinado' : 'disponivel'
        };
      });
    }
  },
  
  async mounted() {
    await this.carregarPerfilUsuario()
    await this.carregarProcessos()
    await this.carregarEstatisticas()
  },
  
  beforeUnmount() {
    // Garantir que o scroll seja restaurado ao sair
    document.body.style.overflow = 'auto'
  },
  
  methods: {
    // =====================================================
    // MÉTODOS AUXILIARES
    // =====================================================
    
    isOrgaoAdministrativo() {
      return this.perfilUsuario?.toLowerCase() === 'orgao_administrativo'
    },
    
    // =====================================================
    // CARREGAMENTO DE DADOS
    // =====================================================
    
    async buscarUrlEdital(doc) {
      try {
        console.log('🔍 Buscando URL do edital:', doc.titulo)
        
        // Buscar o edital diretamente na tabela documentos_processo
        const { data: editalDoc, error } = await supabase
          .from('documentos_processo')
          .select('*')
          .eq('processo_id', this.processoSelecionado.id)
          .eq('tipo_documento', 'EDITAL')
          .single()
        
        console.log('📄 Edital encontrado na tabela documentos_processo:', { editalDoc, error })
        
        if (editalDoc && editalDoc.arquivo_url) {
          // Atualizar o documento com a URL encontrada
          doc.url_arquivo = editalDoc.arquivo_url
          console.log('✅ URL do edital encontrada:', doc.url_arquivo)
          
          // Visualizar o documento
          this.visualizarDocumento(doc)
        } else {
          alert('❌ URL do PDF do edital não encontrada na tabela documentos_processo.')
        }
      } catch (error) {
        console.error('❌ Erro ao buscar URL do edital:', error)
        alert('Erro ao localizar o arquivo do edital: ' + error.message)
      }
    },
    
    async carregarPerfilUsuario() {
      try {
        this.perfilUsuario = await ProcessosAdministrativosService.obterPerfilUsuario()
      } catch (error) {
        console.error('Erro ao carregar perfil do usuário:', error)
        this.perfilUsuario = ''
      }
    },
    
    async carregarProcessos() {
      try {
        this.carregando = true
        const filtros = {
          tipo_processo: this.filtroTipo,
          status: this.filtroStatus,
          busca: this.termoBusca
        }
        this.processos = await ProcessosAdministrativosService.listarProcessos(filtros)
        await this.carregarAcoesDisponiveis()
        this.filtrarProcessos()
      } catch (error) {
        console.error('Erro ao carregar processos:', error)
        this.processos = []
        alert('Erro ao carregar processos. Tente novamente.')
      } finally {
        this.carregando = false
      }
    },
    
    async carregarEstatisticas() {
      try {
        this.estatisticas = await ProcessosAdministrativosService.obterEstatisticas()
      } catch (error) {
        console.error('Erro ao carregar estatísticas:', error)
      }
    },
    
    async carregarDocumentosProcesso(processoId) {
      try {
        console.log('🔍 DEBUG - Carregando documentos para processo:', processoId)
        
        // SEMPRE carregar documentos principais do processo (folha de rosto, DFD, edital)
        let documentos = await ProcessosAdministrativosService.listarDocumentosProcesso(processoId)
        console.log('🔍 DEBUG - Documentos principais carregados (folha de rosto, DFD, edital):', documentos)
        
        // SEMPRE carregar documentos dos produtos da nova tabela (independente do tipo de processo)
        console.log('🔄 DEBUG - Carregando documentos de produtos da nova tabela para TODOS os processos')
        
        // Buscar documentos dos produtos diretamente da nova tabela dedicada  
        const tenantId = await ProcessosAdministrativosService.getTenantId()
        const { data: documentosProdutos, error: erroDocProdutos } = await supabase
          .from('documentos_produtos_processo')
          .select('*')
          .eq('processo_id', processoId)
          .eq('tenant_id', tenantId)
        
        console.log(`📋 DEBUG - Documentos de produtos encontrados na nova tabela:`, documentosProdutos)
        
        if (erroDocProdutos) {
          console.warn('⚠️ Erro ao buscar documentos de produtos do processo:', erroDocProdutos)
        }
        
        // SEMPRE adicionar os documentos de produtos encontrados à lista
        if (documentosProdutos && documentosProdutos.length > 0) {
          console.log(`✅ DEBUG - Adicionando ${documentosProdutos.length} documentos de produtos à lista`)
          for (const docProduto of documentosProdutos) {
            const documentoProdutoFormatado = {
              id: `produto_${docProduto.id}`, // ID único para evitar conflitos
              tipo_documento: 'DOCUMENTO_PRODUTO',
                titulo: `${docProduto.nome_produto} - ${docProduto.nome_arquivo}`,
                descricao: `Documento técnico do produto ${docProduto.nome_produto} (${docProduto.marca})`,
                data_autuacao: docProduto.created_at,
                numero_folha: null,
                url_arquivo: docProduto.url_arquivo,
                nome_arquivo: docProduto.nome_arquivo,
                tipo_arquivo: docProduto.tipo_arquivo,
                tamanho: docProduto.tamanho,
                assinado: false,
                // Informações extras do produto
                produto_id: docProduto.produto_id,
                nome_produto: docProduto.nome_produto,
                marca: docProduto.marca,
                fabricante: docProduto.fabricante
              }
              documentos.push(documentoProdutoFormatado)
            }
            console.log(`✅ ${documentosProdutos.length} documentos de produtos adicionados à lista`)
          } else {
            console.log('ℹ️ Nenhum documento de produto encontrado para este processo')
          }
        
        // Carregar documentos adicionais do processo
        // NOTA: Tabela documentos_adicionais_processo não existe ainda
        // Por enquanto, vamos buscar na própria tabela de documentos_processo com tipo específico
        try {
          console.log(`🔍 Buscando documentos adicionais para processo ${processoId}`)
          const { data: documentosAdicionais, error: erroDocAdicionais } = await supabase
            .from('documentos_processo')
            .select('*')
            .eq('processo_id', processoId)
            .in('tipo_documento', ['DOCUMENTO_ADICIONAL', 'documento_adicional', 'ANEXO', 'anexo'])
            
          console.log(`📎 Documentos adicionais encontrados:`, documentosAdicionais)
          if (erroDocAdicionais) {
            console.warn('⚠️ Erro ao buscar documentos adicionais:', erroDocAdicionais)
          }
            
          if (documentosAdicionais && documentosAdicionais.length > 0) {
            for (const docAdicional of documentosAdicionais) {
              // Verificar se já não foi incluído na busca principal
              const jaExiste = documentos.find(d => d.id === docAdicional.id)
              if (!jaExiste) {
                const documento = {
                  id: docAdicional.id,
                  tipo_documento: 'DOCUMENTO_ADICIONAL',
                  titulo: docAdicional.titulo || docAdicional.nome_documento || 'Documento Adicional',
                  descricao: docAdicional.descricao || 'Documento adicional anexado ao processo',
                  data_autuacao: docAdicional.data_autuacao || docAdicional.created_at,
                  numero_folha: docAdicional.numero_folha,
                  url_arquivo: docAdicional.url_arquivo,
                  nome_arquivo: docAdicional.nome_arquivo,
                  tipo_arquivo: docAdicional.tipo_arquivo,
                  tamanho: docAdicional.tamanho,
                  assinado: docAdicional.assinado || false
                }
                documentos.push(documento)
              }
            }
          }
        } catch (error) {
          console.warn('Erro ao buscar documentos adicionais:', error)
        }
        
        console.log(`📋 Total de documentos carregados: ${documentos.length}`, documentos)
        this.documentosProcesso = documentos
      } catch (error) {
        console.error('Erro ao carregar documentos do processo:', error)
        this.documentosProcesso = []
      }
    },
    
    async carregarProdutosProcesso(processoId) {
      try {
        this.produtosProcesso = await ProcessosAdministrativosService.listarProdutosProcesso(processoId)
      } catch (error) {
        console.error('Erro ao carregar produtos do processo:', error)
        this.produtosProcesso = []
      }
    },
    
    async carregarHistoricoTramitacao(processoId) {
      try {
        this.historicoTramitacao = await ProcessosAdministrativosService.obterHistoricoTramitacao(processoId)
      } catch (error) {
        console.error('Erro ao carregar histórico de tramitação:', error)
        this.historicoTramitacao = []
      }
    },
    
    podeEditarProcesso(processo) {
      // Só pode editar processos que estão em criação
      const statusProcesso = processo?.status?.toLowerCase() || ''
      return statusProcesso === 'em_criacao' || statusProcesso === 'rascunho'
    },
    
    podeEnviarParaAnalise(processo) {
      console.log('🔍 DEBUG - Verificando botão enviar:', {
        processo: processo?.numero_processo || processo?.id,
        status: processo?.status,
        tipo: processo?.tipo_processo,
        perfilUsuario: this.perfilUsuario,
        documentos: this.documentosProcesso?.length || 0,
        produtos: this.produtosProcesso?.length || 0
      })
      
      const statusProcesso = processo?.status?.toLowerCase() || ''
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      
      // CPM pode enviar processos com status 'criado_cpm'
      if (perfilUsuario === 'cpm' && statusProcesso === 'criado_cpm') {
        console.log('🎯 Resultado CPM:', '✅ MOSTRAR BOTÃO - CPM pode enviar criado_cpm')
        return true
      }
      
      // CPM pode enviar processos em rascunho/aguardando_aprovacao
      if (perfilUsuario === 'cpm' && ['rascunho', 'aguardando_aprovacao'].includes(statusProcesso)) {
        console.log('🎯 Resultado CPM:', '✅ MOSTRAR BOTÃO - CPM pode enviar rascunho/aguardando')
        return true
      }
      
      // Órgão Administrativo NÃO deve ver botão "Enviar para Análise" em processos criado_cpm
      if (perfilUsuario === 'orgao_administrativo' && statusProcesso === 'criado_cpm') {
        console.log('🎯 Resultado ORGAO:', '❌ OCULTAR BOTÃO - Órgão não pode enviar criado_cpm')
        return false
      }
      
      console.log('🎯 Resultado:', '❌ OCULTAR BOTÃO - Sem permissão')
      return false
    },
    
    // Função para verificar se deve mostrar botões específicos do Órgão Administrativo
    podeOrgaoAssinarDocumento(processo) {
      const statusProcesso = processo?.status?.toLowerCase() || ''
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      
      // Órgão Administrativo pode assinar documentos em status "aguardando_assinatura_orgao"
      return perfilUsuario === 'orgao_administrativo' && statusProcesso === 'aguardando_assinatura_orgao'
    },
    
    // Função para verificar se deve mostrar botão de devolver para CPM
    podeDevolverParaCPM(processo) {
      const statusProcesso = processo?.status?.toLowerCase() || ''
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      
      // Órgão Administrativo pode devolver em status "aguardando_assinatura_orgao"
      return perfilUsuario === 'orgao_administrativo' && statusProcesso === 'aguardando_assinatura_orgao'
    },
    
    // Função para obter o texto correto do botão Adicionar Documento
    obterTextoAdicionarDocumento() {
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      
      if (perfilUsuario === 'orgao_administrativo') {
        return 'Adicionar Documento Assinado'
      }
      
      return 'Adicionar Documento'
    },
    
    podeTramitarParaCCL(processo) {
      console.log('🔍 DEBUG - Verificando botão tramitar para CCL:', {
        processo: processo?.numero_processo || processo?.id,
        status: processo?.status,
        tipo: processo?.tipo_processo
      })
      
      const statusProcesso = processo?.status?.toLowerCase() || ''
      const podeTramitar = statusProcesso === 'assinado_admin'
      
      console.log('⚖️ Resultado tramitação CCL:', podeTramitar ? '✅ MOSTRAR BOTÃO' : '❌ OCULTAR BOTÃO')
      
      return podeTramitar
    },
    
    obterTextoBotaoTramitacao(processo) {
      if (!processo) return 'Tramitar Processo'
      
      return TramitacaoProcessosService.obterNomeBotaoTramitacao(processo.status, processo.tipo_processo)
    },
    
    async tramitarProcessoParaCCL(processo) {
      try {
        const confirmacao = confirm(
          `⚖️ TRAMITAR PROCESSO PARA CCL\n\n` +
          `Processo: ${processo.numero_processo}\n` +
          `Status atual: Assinado pelo Órgão\n` +
          `Próximo status: Em Julgamento pela CCL\n\n` +
          `Confirma a tramitação?`
        )

        if (!confirmacao) return

        console.log('⚖️ Tramitando processo para CCL:', processo.id)
        console.log('📊 Status atual do processo:', processo.status)
        console.log('📊 Tipo do processo:', processo.tipo_processo)
        
        const resultado = await TramitacaoProcessosService.enviarProcesso(processo.id, 'Processo tramitado para julgamento da CCL')
        console.log('📊 Resultado da tramitação:', resultado)
        
        if (resultado && resultado.sucesso) {
          this.$swal({
            title: '✅ Processo Tramitado!',
            text: `O processo ${processo.numero_processo} foi tramitado para julgamento da CCL com sucesso.`,
            icon: 'success'
          })
          
          // Recarregar dados
          await this.carregarProcessos()
          
          // Atualizar processo na lista local para refletir a mudança
          const index = this.processos.findIndex(p => p.id === processo.id)
          if (index !== -1) {
            this.processos[index].status = resultado.statusNovo
          }
          
        } else {
          throw new Error('Falha na tramitação do processo')
        }
        
      } catch (error) {
        console.error('Erro ao tramitar processo:', error)
        this.$swal({
          title: '❌ Erro na Tramitação',
          text: `Erro ao tramitar processo: ${error.message}`,
          icon: 'error'
        })
      }
    },
    
    gerarHTMLRelatorio(processo, documentos, produtos) {
      const dataAtual = new Date().toLocaleDateString('pt-BR')
      
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Caderno do Processo ${processo.numero_processo || processo.id}</title>
          <style>
            @page {
              margin: 2cm;
              @bottom-center {
                content: "Página " counter(page) " - Processo ${processo.numero_processo || processo.id}";
                font-size: 10pt;
                color: #666;
              }
            }
            
            body { 
              font-family: 'Times New Roman', serif; 
              font-size: 12pt;
              line-height: 1.6;
              color: #000;
              margin: 0;
              padding: 0;
              background: white;
            }
            
            .page-break {
              page-break-before: always;
            }
            
            .documento-pagina {
              width: 21cm;
              min-height: 29.7cm;
              margin: 0 auto 2cm auto;
              padding: 2cm;
              background: white;
              box-shadow: 0 0 10px rgba(0,0,0,0.1);
              position: relative;
              overflow: visible;
              word-wrap: break-word;
            }
            
            /* === ESTILOS PADRONIZADOS PARA TODOS OS DOCUMENTOS === */
            
            .folha-numero {
              position: absolute;
              top: 0.5cm;
              right: 1cm;
              font-size: 11pt;
              color: #333;
              font-weight: bold;
              background: white;
              padding: 5px 10px;
              border: 1px solid #ddd;
              border-radius: 3px;
            }
            
            .documento-header {
              text-align: center;
              margin-bottom: 2.5cm;
              border-bottom: 2px solid #000;
              padding-bottom: 1.5cm;
            }
            
            .documento-header h1 {
              font-family: 'Times New Roman', serif;
              font-size: 16pt;
              font-weight: bold;
              margin: 1cm 0 0.8cm 0;
              color: #000;
              line-height: 1.4;
            }
            
            .documento-header h2 {
              font-family: 'Times New Roman', serif;
              font-size: 14pt;
              font-weight: bold;
              margin: 0.8cm 0 0.5cm 0;
              color: #000;
              line-height: 1.3;
            }
            
            .documento-conteudo {
              font-family: 'Times New Roman', serif;
              font-size: 12pt;
              line-height: 1.7;
              text-align: justify;
              color: #000;
            }
            
            .documento-conteudo h1,
            .documento-conteudo h2,
            .documento-conteudo h3 {
              font-family: 'Times New Roman', serif;
              font-weight: bold;
              color: #000;
              margin: 1.5cm 0 0.8cm 0;
              line-height: 1.4;
            }
            
            .documento-conteudo h1 { font-size: 16pt; }
            .documento-conteudo h2 { font-size: 14pt; }
            .documento-conteudo h3 { font-size: 12pt; }
            
            .documento-conteudo p {
              font-family: 'Times New Roman', serif;
              font-size: 12pt;
              line-height: 1.7;
              margin-bottom: 1.2cm;
              text-align: justify;
            }
            
            .documento-conteudo strong {
              font-weight: bold;
            }
            
            .caixa-bordered {
              border: 2px solid #000;
              padding: 1.5cm;
              margin: 2cm auto;
              max-width: 16cm;
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
            
            .numero-processo {
              font-weight: bold;
              font-size: 14pt;
              margin-bottom: 1cm;
              text-align: center;
            }
            
            .tabela {
              width: 100%;
              border-collapse: collapse;
              margin: 1cm 0;
              font-size: 11pt;
              table-layout: fixed;
            }
            
            .tabela th, .tabela td {
              border: 1px solid #333;
              padding: 8px;
              text-align: left;
              vertical-align: top;
              word-wrap: break-word;
              overflow-wrap: break-word;
              hyphens: auto;
            }
            
            .tabela th {
              background-color: #f5f5f5;
              font-weight: bold;
              text-align: center;
            }
            
            .assinatura {
              margin-top: 4cm;
              text-align: center;
              page-break-inside: avoid;
            }
            
            .linha-assinatura {
              border-top: 1px solid #000;
              width: 300px;
              margin: 2.5cm auto 1cm auto;
            }
            
            @media print {
              .documento-pagina {
                box-shadow: none;
                margin: 0;
                padding: 2cm 2cm 3cm 2cm; /* Margem inferior extra */
                page-break-inside: avoid;
              }
              
              .page-break {
                page-break-before: always;
              }
              
              .tabela {
                page-break-inside: auto;
              }
              
              .tabela tr {
                page-break-inside: avoid;
              }
              
              .documento-conteudo {
                orphans: 3;
                widows: 3;
              }
            }
          </style>
        </head>
        <body>
          <!-- DOCUMENTOS DO PROCESSO -->
          ${documentos.map((doc, index) => `
            ${index > 0 ? '<div class="page-break"></div>' : ''}
            <div class="documento-pagina">
              <div class="folha-numero">Fl. ${String(doc.numero_sequencial || index + 1).padStart(3, '0')}</div>
              
              ${doc.conteudo_html ? doc.conteudo_html : `
                <div class="documento-header">
                  <h1>${processo.nome_orgao}</h1>
                  <h2>${doc.nome_documento || doc.tipo_documento}</h2>
                  <p>Processo nº ${processo.numero_processo}</p>
                </div>
                
                <div class="documento-conteudo">
                  <h3>INFORMAÇÕES DO DOCUMENTO</h3>
                  <p><strong>Tipo:</strong> ${doc.tipo_documento}</p>
                  <p><strong>Título:</strong> ${doc.titulo || doc.nome_documento || 'Sem título'}</p>
                  <p><strong>Descrição:</strong> ${doc.descricao || 'Documento do processo administrativo'}</p>
                  <p><strong>Data de Autuação:</strong> ${this.formatarData(doc.data_autuacao)}</p>
                  
                  ${doc.arquivo_url ? `
                  <h3>ARQUIVO ANEXO</h3>
                  <p><strong>Observação:</strong> Este documento possui arquivo anexo com informações complementares.</p>
                  
                  <p style="margin-top: 1cm;"><strong>Arquivo:</strong> 
                    <a href="${doc.arquivo_url}" target="_blank" style="color: #1976d2; text-decoration: underline; font-weight: bold;">
                      ${doc.arquivo_url}
                    </a>
                  </p>
                  ` : ''}
                  
                  ${doc.observacoes ? `
                  <h3>OBSERVAÇÕES</h3>
                  <div style="background: #f8f9fa; padding: 1cm; border-left: 4px solid #007bff; margin: 1cm 0;">
                    ${doc.observacoes}
                  </div>
                  ` : ''}
                  
                  <div style="margin-top: 3cm; text-align: center; border-top: 1px solid #ccc; padding-top: 1cm; color: #666;">
                    <p>Sistema Comprar Bem - Processo nº ${processo.numero_processo}</p>
                  </div>
                </div>
              `}
            </div>
          `).join('')}
          
          ${produtos.length > 0 ? `
            <div class="page-break"></div>
            <div class="documento-pagina">
              <div class="folha-numero">Anexo - Produtos</div>
              
              <div class="documento-header">
                <h1>${processo.nome_orgao}</h1>
                <h2>RELAÇÃO DE PRODUTOS</h2>
                <p>Processo nº ${processo.numero_processo}</p>
              </div>
              
              <div class="documento-conteudo">
                <table class="tabela">
                  <thead>
                    <tr>
                      <th>ITEM</th>
                      <th>CÓDIGO</th>
                      <th>PRODUTO</th>
                      <th>ESPECIFICAÇÕES</th>
                      ${processo.tipo_processo === 'padronizacao' ? '<th>VALOR ESTIMADO</th>' : '<th>MOTIVO</th>'}
                    </tr>
                  </thead>
                  <tbody>
                    ${produtos.map((produto, idx) => `
                      <tr>
                        <td>${idx + 1}</td>
                        <td>${produto.codigo || 'N/A'}</td>
                        <td>${produto.nome_produto || produto.nome}</td>
                        <td>${produto.especificacoes_tecnicas || 'A definir'}</td>
                        <td>${processo.tipo_processo === 'padronizacao' ? 
                          (produto.valor_estimado ? `R$ ${produto.valor_estimado}` : 'A definir') :
                          (produto.observacoes_processo || 'Conforme avaliação técnica')
                        }</td>
                      </tr>
                    `).join('')}
                  </tbody>
                </table>
              </div>
            </div>
          ` : ''}
          
          <!-- ÍNDICE DE DOCUMENTOS -->
          <div class="page-break"></div>
          <div class="documento-pagina">
            <div class="folha-numero">Índice</div>
            
            <div class="documento-header">
              <h1>${processo.nome_orgao}</h1>
              <h2>ÍNDICE DE DOCUMENTOS</h2>
              <p>Processo nº ${processo.numero_processo}</p>
            </div>
            
            <div class="documento-conteudo">
              <h3>📋 DADOS GERAIS DO PROCESSO</h3>
              <p><strong>Número:</strong> ${processo.numero_processo || 'Não definido'}</p>
              <p><strong>Tipo:</strong> ${processo.tipo_processo === 'padronizacao' ? 'Padronização de Produtos' : 'Despadronização de Produtos'}</p>
              <p><strong>Status:</strong> ${this.formatarStatus(processo.status)}</p>
              <p><strong>Órgão:</strong> ${processo.nome_orgao}</p>
              <p><strong>Unidade:</strong> ${processo.unidade_interessada}</p>
              <p><strong>Data:</strong> ${this.formatarData(processo.data_autuacao)}</p>
              
              
              <h3 style="margin-top: 2cm;">RELAÇÃO DE DOCUMENTOS</h3>
              
              <table class="tabela" style="margin-top: 1cm;">
                <thead>
                  <tr>
                    <th style="width: 12%;">FOLHA</th>
                    <th style="width: 50%;">DOCUMENTO</th>
                    <th style="width: 18%;">DATA</th>
                    <th style="width: 20%;">ARQUIVO</th>
                  </tr>
                </thead>
                <tbody>
                  ${documentos
                    .filter(doc => doc.tipo_documento !== 'DFD' && doc.tipo_documento !== 'FOLHA_ROSTO')
                    .map(doc => `
                    <tr>
                      <td style="text-align: center; font-weight: bold;">Fl. ${String(doc.numero_sequencial || 1).padStart(3, '0')}</td>
                      <td>
                        <strong>${doc.nome_documento || doc.tipo_documento}</strong>
                        ${doc.tipo_documento !== (doc.nome_documento || doc.tipo_documento) ? `<br><small style="color: #666;">(${doc.tipo_documento})</small>` : ''}
                      </td>
                      <td style="text-align: center;">${this.formatarData(doc.data_autuacao)}</td>
                      <td style="text-align: center;">
                        ${doc.arquivo_url ? `
                          <a href="${doc.arquivo_url}" target="_blank" style="color: #1976d2; text-decoration: underline; font-weight: bold;">
                            Abrir PDF
                          </a>
                        ` : '-'}
                      </td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
              
              <div style="margin-top: 2cm; text-align: center; border-top: 1px solid #ccc; padding-top: 1cm;">
                <p><strong>Total de documentos:</strong> ${documentos.filter(d => d.tipo_documento !== 'DFD' && d.tipo_documento !== 'FOLHA_ROSTO').length} | <strong>Com arquivos:</strong> ${documentos.filter(d => d.arquivo_url && d.tipo_documento !== 'DFD' && d.tipo_documento !== 'FOLHA_ROSTO').length}</p>
                ${produtos.length > 0 ? `<p><strong>Total de produtos:</strong> ${produtos.length}</p>` : ''}
                <p style="color: #666; margin-top: 1cm;">Gerado em ${dataAtual} - Sistema Comprar Bem</p>
              </div>
              
            </div>
          </div>
          
          ${produtos.length > 0 ? `
          <!-- RESUMO DOS PRODUTOS -->
          <div class="page-break"></div>
          <div class="documento-pagina">
            <div class="folha-numero">Produtos</div>
            
            <div class="documento-header">
              <h1>${processo.nome_orgao}</h1>
              <h2>PRODUTOS ${processo.tipo_processo === 'padronizacao' ? 'PARA PRÉ-QUALIFICAÇÃO' : 'PARA DESPADRONIZAÇÃO'}</h2>
              <p>Processo nº ${processo.numero_processo}</p>
            </div>
            
            <div class="documento-conteudo">
              <table class="tabela">
                <thead>
                  <tr>
                    <th style="width: 8%;">ITEM</th>
                    <th style="width: 15%;">CÓDIGO</th>
                    <th style="width: 35%;">PRODUTO</th>
                    <th style="width: 25%;">ESPECIFICAÇÕES</th>
                    <th style="width: 17%;">STATUS</th>
                  </tr>
                </thead>
                <tbody>
                  ${produtos.map((produto, idx) => `
                    <tr>
                      <td style="text-align: center; font-weight: bold;">${idx + 1}</td>
                      <td style="text-align: center;">${produto.codigo || 'N/A'}</td>
                      <td><strong>${produto.nome_produto || produto.nome}</strong><br>
                          <small>Marca: ${produto.marca || 'N/A'} | Modelo: ${produto.modelo || 'N/A'}</small></td>
                      <td style="font-size: 10pt;">${produto.especificacoes_tecnicas || produto.especificacoes || 'A definir'}</td>
                      <td style="text-align: center;">${produto.status_avaliacao || 'Pendente'}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
              
              <div class="assinatura">
                <div class="linha-assinatura"></div>
                <p><strong>Equipe Técnica Responsável</strong></p>
                <p>${processo.nome_orgao}</p>
              </div>
            </div>
          </div>
          ` : ''}
        </body>
        </html>
      `
    },

    async completarDocumentosProcesso(processo, documentosExistentes, produtos, dadosDFD) {
      let documentosCompletos = [...documentosExistentes]
      
      // Limpar numerações antigas para renumerar corretamente
      documentosCompletos.forEach(doc => {
        if (doc.tipo_documento !== 'FOLHA_ROSTO' && doc.tipo_documento !== 'DFD') {
          delete doc.numero_folha
        }
      })
      
      // Usar apenas a folha de rosto que vem do banco (não gerar nova)
      // A folha de rosto com conteúdo HTML completo já está nos documentosExistentes
      const folhasRosto = documentosExistentes.filter(doc => doc.tipo_documento === 'FOLHA_ROSTO')
      console.log('🔍 DEBUG - Folhas de rosto encontradas:', folhasRosto.length)
      folhasRosto.forEach((folha, index) => {
        console.log(`📄 Folha ${index + 1}:`, {
          nome: folha.nome_documento,
          titulo: folha.titulo,
          temConteudoHTML: !!folha.conteudo_html,
          tipoConteudo: folha.conteudo_html ? 'Com HTML' : 'Sem HTML',
          primeirosPedacos: folha.conteudo_html ? folha.conteudo_html.substring(0, 200) + '...' : 'N/A'
        })
      })
      
      // Verificar se existe DFD - SEMPRE INCLUIR
      const temDFD = documentosExistentes.find(doc => doc.tipo_documento === 'DFD' || doc.tipo_documento === 'dfd')
      console.log('Tem DFD existente?', !!temDFD)
      console.log('Dados DFD passados:', dadosDFD)
      
      if (!temDFD) {
        // Buscar DFD se não foi passado
        if (!dadosDFD) {
          console.log('Buscando DFD no banco...')
          try {
            const { data: dfdData } = await supabase
              .from('dfd_processo')
              .select('*')
              .eq('processo_id', processo.id)
              .single()
            dadosDFD = dfdData
            console.log('DFD encontrado no banco:', dadosDFD)
          } catch (error) {
            console.log('DFD não encontrado no banco, criando com dados padrão')
            dadosDFD = {
              justificativa: 'Justificativa da necessidade conforme demanda apresentada',
              descricao_necessidade: 'Descrição detalhada da necessidade identificada',
              criterios_aceitacao: 'Critérios de aceitação e ensaios estabelecidos',
              observacoes_especiais: 'Observações especiais e condições do processo'
            }
          }
        }
        
        const modeloDFD = processo.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'
        const dfd = {
          numero_folha: 2, // Conforme Instrução: sempre Fl. 002
          tipo_documento: 'DFD',
          nome_documento: `Documento de Formalização de Demanda - ${modeloDFD}`,
          titulo: `DFD - Documento de Formalização de Demanda (${modeloDFD})`,
          descricao: `Documento de Formalização de Demanda do processo de ${processo.tipo_processo}`,
          data_autuacao: dadosDFD?.created_at || processo.created_at,
          conteudo_html: this.gerarHTMLDFD(processo, dadosDFD, produtos)
        }
        
        console.log('Criando DFD:', dfd)
        
        // Inserir DFD após folha de rosto
        const folhaRostoIndex = documentosCompletos.findIndex(doc => doc.tipo_documento === 'FOLHA_ROSTO')
        if (folhaRostoIndex >= 0) {
          documentosCompletos.splice(folhaRostoIndex + 1, 0, dfd)
        } else {
          documentosCompletos.push(dfd)
        }
        console.log('DFD adicionado aos documentos')
      } else {
        // DFD existe, garantir que tenha conteúdo HTML
        console.log('DFD existente encontrado')
        const dfd = documentosCompletos.find(doc => doc.tipo_documento === 'DFD' || doc.tipo_documento === 'dfd')
        if (dfd) {
          dfd.numero_folha = 2
          const modeloDFD = processo.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'
          dfd.nome_documento = `Documento de Formalização de Demanda - ${modeloDFD}`
          dfd.titulo = `DFD - Documento de Formalização de Demanda (${modeloDFD})`
          
          // Garantir que tenha conteúdo HTML
          if (!dfd.conteudo_html) {
            console.log('Gerando HTML para DFD existente')
            dfd.conteudo_html = this.gerarHTMLDFD(processo, dadosDFD || {}, produtos)
          }
        }
      }
      
      // Buscar edital apenas para incluir no índice (sem gerar página)
      if (processo.edital_id && processo.tipo_processo === 'padronizacao') {
        try {
          const temEdital = documentosCompletos.find(doc => doc.tipo_documento === 'EDITAL')
          if (!temEdital) {
            const { data: edital } = await supabase
              .from('editais')
              .select('*')
              .eq('id', processo.edital_id)
              .single()
              
            if (edital && edital.arquivo_url) {
              // Adicionar apenas para referência no índice (sem conteúdo HTML)
              const referenciaEdital = {
                numero_folha: null, // Não será incluído no caderno principal
                tipo_documento: 'EDITAL_REFERENCIA',
                nome_documento: `Edital - ${edital.titulo}`,
                titulo: edital.titulo,
                descricao: 'Edital de Chamamento Público (arquivo externo)',
                data_autuacao: edital.created_at,
                arquivo_url: edital.arquivo_url,
                conteudo_html: null // Sem página própria
              }
              documentosCompletos.push(referenciaEdital)
              console.log('Edital adicionado apenas para referência no índice')
            }
          }
        } catch (error) {
          console.log('Erro ao buscar edital:', error)
        }
      }
      
      // Coletar todos os documentos de produtos para criar uma página consolidada
      let documentosProdutoConsolidados = []
      
      if (produtos && produtos.length > 0) {
        for (const produto of produtos) {
          try {
            // Verificar se tem documentos específicos do produto
            const { data: documentosProduto } = await supabase
              .from('produtos_prequalificacao')
              .select('documentos_adicionados')
              .eq('id', produto.id)
              .single()
              
            if (documentosProduto?.documentos_adicionados && documentosProduto.documentos_adicionados.length > 0) {
              for (const doc of documentosProduto.documentos_adicionados) {
                documentosProdutoConsolidados.push({
                  produto: produto,
                  documento: doc
                })
              }
            }
          } catch (error) {
            console.log('Erro ao buscar documentos do produto:', produto.id, error)
          }
        }
      }

      // Adicionar documentos da nova tabela dedicada (documentos_produtos_processo)
      const documentosProcessoProdutos = documentosCompletos.filter(doc => doc.tipo_documento === 'DOCUMENTO_PRODUTO')
      documentosProcessoProdutos.forEach(doc => {
        // Extrair informações do documento formatado
        documentosProdutoConsolidados.push({
          documento: {
            nome: doc.nome_arquivo || 'Documento',
            url: doc.arquivo_url
          },
          produto: {
            nome: doc.nome_produto || doc.titulo.split(' - ')[0] || 'Produto',
            marca: doc.marca || 'N/A',
            modelo: doc.modelo || 'N/A',
            categoria: doc.categoria || 'N/A',
            fabricante: doc.fabricante || 'N/A',
            created_at: doc.data_autuacao
          }
        })
      })

      // GARANTIR QUE EDITAL TENHA CONTEÚDO HTML COMPLETO
      const editalExistente = documentosCompletos.find(doc => doc.tipo_documento === 'EDITAL')
      if (editalExistente && !editalExistente.conteudo_html) {
        console.log('🔧 Gerando conteúdo HTML para edital existente')
        // Extrair número do edital do título
        const numeroEdital = editalExistente.titulo ? 
          (editalExistente.titulo.match(/\d+\/\d+/) ? editalExistente.titulo.match(/\d+\/\d+/)[0] : '001/2025') : 
          '001/2025'
          
        editalExistente.conteudo_html = `
          <div class="documento-header">
            <h1>${processo.nome_orgao}</h1>
            <h2>EDITAL DE PRÉ-QUALIFICAÇÃO DE BENS</h2>
            <h3>Nº ${numeroEdital}</h3>
          </div>
          
          <div class="documento-conteudo">
            <h3>IDENTIFICAÇÃO</h3>
            <p><strong>Número do Edital:</strong> ${numeroEdital}</p>
            <p><strong>Ano:</strong> ${new Date().getFullYear()}</p>
            <p><strong>Data de Vinculação ao Processo:</strong> ${editalExistente.data_autuacao ? new Date(editalExistente.data_autuacao).toLocaleDateString('pt-BR') : new Date().toLocaleDateString('pt-BR')}</p>
            <p><strong>Data de Publicação:</strong> ${editalExistente.data_publicacao ? new Date(editalExistente.data_publicacao).toLocaleDateString('pt-BR') : new Date().toLocaleDateString('pt-BR')}</p>
            
            <h3>DOCUMENTO ANEXADO</h3>
            <p>O edital completo com todos os anexos obrigatórios está disponível em formato PDF.</p>
            ${editalExistente.arquivo_url ? `
            <p><strong>Link do documento:</strong> 
              <a href="${editalExistente.arquivo_url}" target="_blank" style="color: #1976d2; text-decoration: underline; font-weight: bold;">
                📄 Abrir Edital Completo (PDF)
              </a>
            </p>` : ''}
            
            <div style="margin-top: 3cm;">
              <p>Data: ${new Date().toLocaleDateString('pt-BR')}</p>
              <div style="margin-top: 2cm; text-align: center;">
                <div style="border-top: 1px solid #000; width: 300px; margin: 0 auto;">
                  Responsável pela vinculação do edital
                </div>
              </div>
            </div>
          </div>
        `
        console.log('✅ Conteúdo HTML do edital gerado com link para download')
      }

      // CRIAR PÁGINAS INDIVIDUAIS DE CADA PRODUTO (antes da página consolidada)
      if (produtos && produtos.length > 0) {
        for (const [index, produto] of produtos.entries()) {
          // Buscar documentos específicos deste produto
          const documentosProduto = documentosProdutoConsolidados.filter(doc => 
            doc.produto.nome === produto.nome_produto || doc.produto.nome === produto.nome
          )

          // Criar página individual detalhada do produto
          const paginaProduto = {
            numero_folha: null, // Será numerado depois
            tipo_documento: 'DOCUMENTACAO_PRODUTO',
            nome_documento: `Documentação de Produto`,
            titulo: `DOCUMENTAÇÃO DE PRODUTO`,
            descricao: `Documentação técnica detalhada do produto ${produto.nome_produto || produto.nome}`,
            data_autuacao: new Date(),
            ordem_especial: 800 + index, // Para aparecer antes da consolidada
            conteudo_html: `
              <div class="documento-header">
                <h1>${processo.nome_orgao}</h1>
                <h2>DOCUMENTAÇÃO DE PRODUTO</h2>
                <p>Processo nº ${processo.numero_processo}</p>
              </div>
              
              <div class="documento-conteudo">
                <h3>DADOS DO PRODUTO</h3>
                <p><strong>Nome do Produto:</strong> ${produto.nome_produto || produto.nome}</p>
                <p><strong>Marca:</strong> ${produto.marca || 'N/A'}</p>
                <p><strong>Modelo:</strong> ${produto.modelo || 'N/A'}</p>
                <p><strong>Categoria:</strong> ${produto.categoria || 'N/A'}</p>
                <p><strong>Fabricante:</strong> ${produto.fabricante || produto.marca || 'N/A'}</p>
                
                <h3>ESPECIFICAÇÕES TÉCNICAS</h3>
                <p><em>${produto.especificacoes_tecnicas || 'Especificações não informadas'}</em></p>
                
                <h3>DOCUMENTO ANEXO</h3>
                <p><strong>Tipo de Documento:</strong> ${documentosProduto.length > 0 ? documentosProduto[0].documento.nome : 'undefined'}</p>
                <p><strong>Descrição:</strong> Documento técnico do produto anexado ao processo</p>
                <p><strong>Arquivo:</strong> ${documentosProduto.length > 0 ? '<span style="text-decoration: underline; color: #1976d2;">undefined</span>' : 'undefined'}</p>
                
                <h3>AVALIAÇÃO TÉCNICA</h3>
                <p><strong>Status:</strong> ${produto.status || 'Pendente de avaliação'}</p>
                <p><strong>Data de Inclusão:</strong> ${produto.created_at ? new Date(produto.created_at).toLocaleDateString('pt-BR') : new Date().toLocaleDateString('pt-BR')}</p>
                
                <div style="margin: 2cm 0; padding: 1cm; border: 2px solid #000;">
                  <h3 style="text-align: center; margin-bottom: 1cm;">DECLARAÇÃO DE CONFORMIDADE</h3>
                  <p style="text-align: justify; line-height: 1.5;">
                    Declaro que o produto acima especificado atende aos requisitos técnicos estabelecidos no Edital de Pré-qualificação, 
                    estando em conformidade com as normas aplicáveis e possuindo os padrões mínimos de qualidade exigidos para inclusão 
                    no Catálogo Eletrônico de Bens Padronizados.
                  </p>
                  <div style="margin-top: 2cm; text-align: center;">
                    <div style="border-top: 1px solid #000; width: 200px; margin: 0 auto;">
                      Responsável Técnico
                    </div>
                  </div>
                </div>
              </div>
            `
          }
          
          documentosCompletos.push(paginaProduto)
          console.log(`✅ Criada página individual para produto: ${produto.nome_produto || produto.nome}`)
        }
      }

      // Se há documentos de produtos, criar uma única página consolidada
      if (documentosProdutoConsolidados.length > 0) {
        // Remover documentos individuais de produtos da lista
        documentosCompletos = documentosCompletos.filter(doc => doc.tipo_documento !== 'DOCUMENTO_PRODUTO')
        
        // Criar página consolidada de documentação de produtos
        // Esta página deve aparecer APÓS a página de dados dos produtos
        const documentacaoConsolidada = {
          numero_folha: null, // Será numerado depois
          tipo_documento: 'DOCUMENTACAO_PRODUTOS',
          nome_documento: 'Documentação de Produtos',
          titulo: 'Documentação de Produtos',
          descricao: 'Documentos técnicos dos produtos do processo',
          data_autuacao: new Date(),
          ordem_especial: 999, // Para aparecer depois dos produtos
          conteudo_html: `
            <div class="documento-header">
              <h1>${processo.nome_orgao}</h1>
              <h2>DOCUMENTAÇÃO DE PRODUTOS</h2>
              <p>Processo nº ${processo.numero_processo}</p>
            </div>
            
            <div class="documento-conteudo">
              <h3>RELAÇÃO DE DOCUMENTOS DE PRODUTOS</h3>
              <p>Os seguintes documentos técnicos estão anexados aos produtos deste processo:</p>
              
              ${documentosProdutoConsolidados.map((item, index) => `
                <div style="margin: 1cm 0; padding: 0.5cm; border-left: 3px solid #1976d2;">
                  <p><strong>${index + 1}. ${item.produto.nome}</strong></p>
                  <p><strong>Documento:</strong> ${item.documento.nome}</p>
                  <p><strong>Link:</strong> 
                    <a href="${item.documento.url}" target="_blank" style="color: #1976d2; text-decoration: underline; font-weight: bold;">
                      Abrir documento
                    </a>
                  </p>
                </div>
              `).join('')}
            </div>
          `
        }
        
        documentosCompletos.push(documentacaoConsolidada)
        console.log(`✅ Criada página consolidada com ${documentosProdutoConsolidados.length} documentos de produtos`)
      }
      
      // Primeiro, separar folhas de rosto e escolher a melhor
      const folhasRostoParaFiltrar = documentosCompletos.filter(doc => doc.tipo_documento === 'FOLHA_ROSTO')
      const outrosDocumentos = documentosCompletos.filter(doc => doc.tipo_documento !== 'FOLHA_ROSTO')
      
      let melhorFolhaRosto = null
      if (folhasRostoParaFiltrar.length > 0) {
        // Ordenar folhas de rosto por complexidade do conteúdo (mais completa primeiro)
        folhasRostoParaFiltrar.sort((a, b) => {
          const scoreA = (a.conteudo_html || '').length + 
                        ((a.conteudo_html || '').includes('NOME DO ÓRGÃO') ? 1000 : 0) +
                        ((a.conteudo_html || '').includes('INTERESSADO') ? 1000 : 0) +
                        ((a.conteudo_html || '').includes('DATA DE AUTUAÇÃO') ? 1000 : 0) +
                        ((a.conteudo_html || '').includes('OBJETO:') ? 1000 : 0)
          
          const scoreB = (b.conteudo_html || '').length + 
                        ((b.conteudo_html || '').includes('NOME DO ÓRGÃO') ? 1000 : 0) +
                        ((b.conteudo_html || '').includes('INTERESSADO') ? 1000 : 0) +
                        ((b.conteudo_html || '').includes('DATA DE AUTUAÇÃO') ? 1000 : 0) +
                        ((b.conteudo_html || '').includes('OBJETO:') ? 1000 : 0)
          
          return scoreB - scoreA // Ordem decrescente (mais completa primeiro)
        })
        
        melhorFolhaRosto = folhasRostoParaFiltrar[0]
        console.log(`✅ Escolhida melhor folha de rosto: ${melhorFolhaRosto.nome_documento}`)
        console.log(`📊 Score: ${(melhorFolhaRosto.conteudo_html || '').length}`)
        
        if (folhasRostoParaFiltrar.length > 1) {
          console.log(`❌ Removidas ${folhasRostoParaFiltrar.length - 1} folhas de rosto duplicadas`)
        }
      }
      
      // Remover DFDs duplicados
      const dfds = outrosDocumentos.filter(doc => doc.tipo_documento === 'DFD')
      const outrosDocumentosSemDFD = outrosDocumentos.filter(doc => doc.tipo_documento !== 'DFD')
      const melhorDFD = dfds.length > 0 ? dfds[0] : null
      
      if (dfds.length > 1) {
        console.log(`❌ Removidos ${dfds.length - 1} DFDs duplicados`)
      }
      
      // Recriar lista com apenas os documentos únicos
      documentosCompletos = []
      if (melhorFolhaRosto) documentosCompletos.push(melhorFolhaRosto)
      if (melhorDFD) documentosCompletos.push(melhorDFD)
      documentosCompletos.push(...outrosDocumentosSemDFD)
      
      // Renumerar documentos seguindo Instrução Processual
      let proximoNumero = 1
      
      documentosCompletos.forEach((doc, index) => {
        // Atribuir numeração sequencial
        doc.numero_sequencial = proximoNumero++
        doc.numero_folha = doc.numero_sequencial
      })
      
      // Reordenar por número de folha garantindo ordem correta
      return documentosCompletos.sort((a, b) => {
        // Folha de rosto sempre primeiro
        if (a.tipo_documento === 'FOLHA_ROSTO') return -1
        if (b.tipo_documento === 'FOLHA_ROSTO') return 1
        
        // DFD sempre segundo
        if (a.tipo_documento === 'DFD') return b.tipo_documento === 'FOLHA_ROSTO' ? 1 : -1
        if (b.tipo_documento === 'DFD') return a.tipo_documento === 'FOLHA_ROSTO' ? -1 : 1
        
        // Demais documentos por número
        return (a.numero_folha || 999) - (b.numero_folha || 999)
      })
    },

    gerarHTMLFolhaRosto(processo) {
      // Texto conforme INSTRUÇÃO PROCESSUAL oficial
      const objetoTexto = processo.tipo_processo === 'padronizacao' ? 
        `CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS.` :
        `DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE E ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS.`
      
      return `
        <div class="folha-rosto-simples" style="display: flex; flex-direction: column; justify-content: center; align-items: center; min-height: 25cm;">
          <div class="caixa-bordered" style="border: 2px solid #000; padding: 1.5cm; max-width: 16cm; width: 100%;">
            
            <div class="numero-processo" style="font-weight: bold; font-size: 14pt; margin-bottom: 1cm; text-align: center;">
              <strong>PROCESSO ADMINISTRATIVO Nº ${processo.numero_processo || '[não definido]'}</strong>
            </div>
            
            <div class="campo" style="margin-bottom: 1cm; text-align: left;">
              <strong>NOME DO ÓRGÃO:</strong> ${processo.nome_orgao}
            </div>
            
            <div class="campo" style="margin-bottom: 1cm; text-align: left;">
              <strong>INTERESSADO(A):</strong> ${processo.unidade_interessada || 'DEPARTAMENTO DE COMPRAS E LICITAÇÕES'}
            </div>
            
            <div class="campo" style="margin-bottom: 1cm; text-align: left;">
              <strong>DATA DE AUTUAÇÃO:</strong> ${this.formatarData(processo.data_autuacao)}
            </div>
            
            <div class="campo objeto" style="margin-bottom: 1cm; text-align: justify; line-height: 1.4;">
              <strong>OBJETO:</strong> ${objetoTexto}
            </div>

            ${processo.observacoes ? `
            <div class="campo observacoes" style="margin-top: 1.5cm; border-top: 1px solid #ccc; padding-top: 1cm;">
              <strong>OBSERVAÇÕES:</strong>
              <div class="observacoes-conteudo" style="margin-top: 0.5cm; text-align: justify; line-height: 1.5; font-style: italic;">${processo.observacoes}</div>
            </div>
            ` : ''}
            
          </div>
        </div>
      `
    },

    gerarHTMLDFD(processo, dadosDFD, produtos) {
      const modeloTipo = processo.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'
      const finalidade = processo.tipo_processo === 'padronizacao' ? 
        'PADRONIZAÇÃO DE MARCAS E MODELOS DE PRODUTOS' : 
        'DESPADRONIZAÇÃO DE MARCAS E MODELOS DE PRODUTOS'
        
      const tituloCompleto = `DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${modeloTipo}`

      // Função auxiliar para renderizar valor booleano
      const formatarBooleano = (valor) => valor ? 'SIM' : 'NÃO'

      let htmlConteudo = `
        <div class="documento-header" style="text-align: center; margin-bottom: 1.5cm;">
          <h1 style="font-size: 16pt; font-weight: bold; margin: 10px 0;">${tituloCompleto}</h1>
        </div>
        
        <div class="documento-conteudo" style="text-align: justify; line-height: 1.6; font-size: 12pt; word-wrap: break-word; overflow-wrap: break-word;">
          
          <h2 style="margin: 1cm 0 0.5cm 0; font-size: 14pt; text-transform: uppercase;">JUSTIFICATIVA</h2>
          <p style="text-indent: 1.5cm; margin-bottom: 0.8cm;">${dadosDFD?.justificativa || 'Justificativa da necessidade conforme processo administrativo.'}</p>
          
          <h2 style="margin: 1cm 0 0.5cm 0; font-size: 14pt; text-transform: uppercase;">DESCRIÇÃO DA NECESSIDADE</h2>
          <p style="text-indent: 1.5cm; margin-bottom: 0.8cm;">${dadosDFD?.descricao_necessidade || 'Descrição detalhada da necessidade identificada.'}</p>
          
          <h2 style="margin: 1cm 0 0.5cm 0; font-size: 14pt; text-transform: uppercase;">CRITÉRIOS DE ACEITAÇÃO</h2>
          <p style="text-indent: 1.5cm; margin-bottom: 0.8cm;">${dadosDFD?.criterios_aceitacao || 'Critérios de aceitação conforme normas técnicas aplicáveis.'}</p>
          
          <h2 style="margin: 1cm 0 0.5cm 0; font-size: 14pt; text-transform: uppercase;">OBSERVAÇÕES ESPECIAIS</h2>
          <p style="text-indent: 1.5cm; margin-bottom: 0.8cm;">${dadosDFD?.observacoes_especiais || 'Observações especiais do processo.'}</p>`

      // Incluir produtos se existirem
      if (produtos && produtos.length > 0) {
        htmlConteudo += `
          <h3 style="font-size: 13pt; margin-top: 1.5cm;">1.1. Relação de ${processo.tipo_processo === 'padronizacao' ? 'Bens' : 'Bens Passíveis de Despadronização'}:</h3>
          <table class="tabela" style="width: 100%; border-collapse: collapse; margin: 1cm 0; font-size: 11pt;">
            <thead>
              <tr style="background-color: #f0f0f0;">
                <th style="border: 1px solid #000; padding: 8px; text-align: center; font-weight: bold;">ITEM</th>
                <th style="border: 1px solid #000; padding: 8px; text-align: center; font-weight: bold;">CÓDIGO</th>
                <th style="border: 1px solid #000; padding: 8px; text-align: center; font-weight: bold;">DESCRIÇÃO</th>
                <th style="border: 1px solid #000; padding: 8px; text-align: center; font-weight: bold;">UNIDADE</th>
                <th style="border: 1px solid #000; padding: 8px; text-align: center; font-weight: bold;">${processo.tipo_processo === 'padronizacao' ? 'REQUISITOS MÍNIMOS' : 'MOTIVAÇÃO'}</th>
                ${processo.tipo_processo === 'padronizacao' ? '<th style="border: 1px solid #000; padding: 8px; text-align: center; font-weight: bold;">PREÇO ESTIMADO</th>' : ''}
              </tr>
            </thead>
            <tbody>
              ${produtos.map((produto, index) => `
                <tr>
                  <td style="border: 1px solid #000; padding: 8px; text-align: center;">${index + 1}</td>
                  <td style="border: 1px solid #000; padding: 8px;">${produto.codigo || 'N/A'}</td>
                  <td style="border: 1px solid #000; padding: 8px;">${produto.nome_produto}</td>
                  <td style="border: 1px solid #000; padding: 8px; text-align: center;">UN</td>
                  <td style="border: 1px solid #000; padding: 8px;">${produto.especificacoes_tecnicas || 'A definir'}</td>
                  ${processo.tipo_processo === 'padronizacao' ? `<td style="border: 1px solid #000; padding: 8px; text-align: right;">R$ ${produto.valor_estimado || '0,00'}</td>` : ''}
                </tr>
              `).join('')}
            </tbody>
          </table>`
      }

      // Seção específica para PADRONIZAÇÃO (MODELO_1)
      if (processo.tipo_processo === 'padronizacao') {
        if (dadosDFD?.produtos_especificacao) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">2. ESPECIFICAÇÃO DOS PRODUTOS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.produtos_especificacao}</p>`
        }

        if (dadosDFD?.quantidade_amostras) {
          htmlConteudo += `
            <h3 style="margin-top: 1cm; font-size: 13pt;">2.1. Quantidades de Amostras:</h3>
            <p style="text-indent: 1.5cm;">${dadosDFD.quantidade_amostras} unidades</p>`
        }

        if (dadosDFD?.previsao_aquisicoes) {
          htmlConteudo += `
            <h3 style="margin-top: 1cm; font-size: 13pt;">2.2. Previsão de Aquisições:</h3>
            <p style="text-indent: 1.5cm;">${dadosDFD.previsao_aquisicoes} unidades</p>`
        }

        if (dadosDFD?.especificacoes_tecnicas) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">3. ESPECIFICAÇÕES TÉCNICAS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.especificacoes_tecnicas}</p>`
        }

        if (dadosDFD?.ensaios_exigidos) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">4. ENSAIOS EXIGIDOS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.ensaios_exigidos}</p>`
        }

        if (dadosDFD?.local_entrega_amostras) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">5. LOCAL DE ENTREGA DAS AMOSTRAS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.local_entrega_amostras}</p>`
        }

        if (dadosDFD?.prazo_entrega_amostras) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">6. PRAZO PARA ENTREGA DAS AMOSTRAS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.prazo_entrega_amostras}</p>`
        }
      }

      // Seção específica para DESPADRONIZAÇÃO (MODELO_2)
      if (processo.tipo_processo === 'despadronizacao') {
        if (dadosDFD?.produtos_despadronizar) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">2. PRODUTOS A SEREM DESPADRONIZADOS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.produtos_despadronizar}</p>`
        }

        // Fontes da demanda
        htmlConteudo += `
          <h2 style="margin-top: 2cm; font-size: 14pt;">3. FONTES DA DEMANDA:</h2>`

        const fontes = []
        if (dadosDFD?.fonte_rdm) fontes.push('Relatórios de Desempenho de Material (RDM)')
        if (dadosDFD?.fonte_reclamacoes_usuarios) fontes.push('Reclamações de usuários')
        if (dadosDFD?.fonte_sistema_comprar_bem) fontes.push('Sistema Comprar Bem')
        if (dadosDFD?.fonte_analise_tecnica) fontes.push('Análise técnica')
        if (dadosDFD?.fonte_outros) fontes.push('Outros')

        if (fontes.length > 0) {
          htmlConteudo += `<ul style="margin-left: 2cm;">`
          fontes.forEach(fonte => {
            htmlConteudo += `<li>${fonte}</li>`
          })
          htmlConteudo += `</ul>`
        }

        if (dadosDFD?.outras_fontes) {
          htmlConteudo += `
            <h3 style="margin-top: 1cm; font-size: 13pt;">3.1. Outras Fontes:</h3>
            <p style="text-indent: 1.5cm;">${dadosDFD.outras_fontes}</p>`
        }

        if (dadosDFD?.problemas_identificados) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">4. PROBLEMAS IDENTIFICADOS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.problemas_identificados}</p>`
        }

        if (dadosDFD?.frequencia_problemas) {
          htmlConteudo += `
            <h3 style="margin-top: 1cm; font-size: 13pt;">4.1. Frequência dos Problemas:</h3>
            <p style="text-indent: 1.5cm;">${dadosDFD.frequencia_problemas}</p>`
        }

        if (dadosDFD?.impacto_problemas) {
          htmlConteudo += `
            <h3 style="margin-top: 1cm; font-size: 13pt;">4.2. Impacto dos Problemas:</h3>
            <p style="text-indent: 1.5cm;">${dadosDFD.impacto_problemas}</p>`
        }

        if (dadosDFD?.quantidade_adquirida) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">5. QUANTIDADES:</h2>
            <p style="text-indent: 1.5cm;"><strong>Quantidade adquirida:</strong> ${dadosDFD.quantidade_adquirida} unidades</p>`
        }

        if (dadosDFD?.quantidade_problemas) {
          htmlConteudo += `
            <p style="text-indent: 1.5cm;"><strong>Quantidade com problemas:</strong> ${dadosDFD.quantidade_problemas} unidades</p>`
        }

        if (dadosDFD?.prejuizo_estimado) {
          htmlConteudo += `
            <p style="text-indent: 1.5cm;"><strong>Prejuízo estimado:</strong> R$ ${dadosDFD.prejuizo_estimado}</p>`
        }

        if (dadosDFD?.rdms_negativos) {
          htmlConteudo += `
            <p style="text-indent: 1.5cm;"><strong>RDMs negativos:</strong> ${dadosDFD.rdms_negativos}</p>`
        }

        if (dadosDFD?.parecer_tecnico) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">6. PARECER TÉCNICO:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.parecer_tecnico}</p>`
        }

        if (dadosDFD?.alternativas_avaliadas) {
          htmlConteudo += `
            <h2 style="margin-top: 2cm; font-size: 14pt;">7. ALTERNATIVAS AVALIADAS:</h2>
            <p style="text-indent: 1.5cm;">${dadosDFD.alternativas_avaliadas}</p>`
        }
      }

      // Seção GERAL (MODELO_GERAL) - aplicável a ambos os tipos
      if (dadosDFD?.base_legal) {
        htmlConteudo += `
          <h2 style="margin-top: 2cm; font-size: 14pt;">BASE LEGAL:</h2>
          <p style="text-indent: 1.5cm;">${dadosDFD.base_legal}</p>`
      }

      if (dadosDFD?.impacto_esperado) {
        htmlConteudo += `
          <h2 style="margin-top: 2cm; font-size: 14pt;">IMPACTO ESPERADO:</h2>
          <p style="text-indent: 1.5cm;">${dadosDFD.impacto_esperado}</p>`
      }

      if (dadosDFD?.riscos_identificados) {
        htmlConteudo += `
          <h2 style="margin-top: 2cm; font-size: 14pt;">RISCOS IDENTIFICADOS:</h2>
          <p style="text-indent: 1.5cm;">${dadosDFD.riscos_identificados}</p>`
      }

      if (dadosDFD?.medidas_mitigadoras) {
        htmlConteudo += `
          <h2 style="margin-top: 2cm; font-size: 14pt;">MEDIDAS MITIGADORAS:</h2>
          <p style="text-indent: 1.5cm;">${dadosDFD.medidas_mitigadoras}</p>`
      }

      if (dadosDFD?.prazo_vigencia) {
        htmlConteudo += `
          <h2 style="margin-top: 2cm; font-size: 14pt;">PRAZO DE VIGÊNCIA:</h2>
          <p style="text-indent: 1.5cm;">${dadosDFD.prazo_vigencia} meses</p>`
      }

      if (dadosDFD?.periodicidade_revisao) {
        htmlConteudo += `
          <h2 style="margin-top: 2cm; font-size: 14pt;">PERIODICIDADE DE REVISÃO:</h2>
          <p style="text-indent: 1.5cm;">${dadosDFD.periodicidade_revisao}</p>`
      }

      // Conclusão
      htmlConteudo += `
          <p style="margin-top: 2cm; text-align: justify;">
            Nestes termos, encaminha-se o presente DFD à autoridade competente, para ciência da presente demanda e autorização para a abertura e instrução do pertinente processo administrativo.
          </p>
          
          <p style="margin-top: 1cm;">Em ${new Date().toLocaleDateString('pt-BR')}.</p>
          
          <div style="margin-top: 2cm; text-align: center;">
            <p><strong>Data:</strong> ${new Date().toLocaleDateString('pt-BR')}</p>
            <div style="border-top: 1px solid #000; width: 400px; margin: 1.5cm auto 0.5cm auto;"></div>
            <p><strong>Presidente da CPPM</strong></p>
          </div>
        </div>
      `

      return htmlConteudo
    },
    
    // =====================================================
    // FILTROS E BUSCA
    // =====================================================
    
    async filtrarProcessos() {
      try {
        // Aplicar filtros localmente primeiro
        let filtrados = [...this.processos]
        
        if (this.filtroTipo) {
          filtrados = filtrados.filter(p => p.tipo_processo === this.filtroTipo)
        }
        
        if (this.filtroStatus) {
          filtrados = filtrados.filter(p => p.status === this.filtroStatus)
        }
        
        if (this.termoBusca) {
          const termo = this.termoBusca.toLowerCase()
          filtrados = filtrados.filter(p => 
            p.numero_processo.toLowerCase().includes(termo) ||
            p.objeto.toLowerCase().includes(termo) ||
            p.nome_orgao.toLowerCase().includes(termo)
          )
        }
        
        // Aplicar ordenação
        this.aplicarOrdenacao(filtrados)
        
        this.processosFiltrados = filtrados
      } catch (error) {
        console.error('Erro ao filtrar processos:', error)
        this.processosFiltrados = [...this.processos]
      }
    },
    
    aplicarOrdenacao(processos) {
      switch (this.ordenacao) {
        case 'data_desc':
          processos.sort((a, b) => new Date(b.data_autuacao) - new Date(a.data_autuacao))
          break
        case 'data_asc':
          processos.sort((a, b) => new Date(a.data_autuacao) - new Date(b.data_autuacao))
          break
        case 'numero_asc':
          processos.sort((a, b) => a.numero_processo.localeCompare(b.numero_processo))
          break
        case 'numero_desc':
          processos.sort((a, b) => b.numero_processo.localeCompare(a.numero_processo))
          break
        case 'status':
          processos.sort((a, b) => a.status.localeCompare(b.status))
          break
      }
    },
    
    // =====================================================
    // GESTÃO DE PROCESSOS
    // =====================================================
    
    abrirAssistente(tipo = null) {
      // SEMPRE criar novo processo - nunca editar um existente
      this.modoEdicao = false
      this.processoParaEditar = null
      this.tipoProcessoInicial = tipo // Passar o tipo clicado para o assistente
      
      this.mostrarAssistente = true
      // Prevenir scroll da página de fundo
      document.body.style.overflow = 'hidden'
      
      console.log('🆕 Abrindo assistente para criar NOVO processo. Tipo pré-selecionado:', tipo)
    },
    
    processoCriado(processo) {
      this.fecharAssistente()
      this.carregarProcessos()
      alert(`Processo ${processo.numero_processo} criado com sucesso!`)
      
      // Abrir o processo recém-criado
      this.abrirProcesso(processo)
    },
    
    async abrirProcesso(processo) {
      try {
        console.log('Carregando processo:', processo.id)
        this.processoSelecionado = await ProcessosAdministrativosService.obterProcesso(processo.id)
        
        if (!this.processoSelecionado) {
          throw new Error('Processo não encontrado')
        }
        
        // Carregar documentos do processo
        await this.carregarDocumentosProcesso(processo.id)
        
        // Carregar produtos se for padronização
        if (this.processoSelecionado.tipo_processo === 'padronizacao') {
          await this.carregarProdutosProcesso(processo.id)
        }
        
        // Carregar histórico de tramitação
        await this.carregarHistoricoTramitacao(processo.id)
        
        console.log('Processo carregado com sucesso:', this.processoSelecionado)
        
      } catch (error) {
        console.error('Erro ao abrir processo:', error)
        alert(`Erro ao carregar detalhes do processo: ${error.message}`)
      }
    },
    
    visualizarProcesso(processo) {
      console.log('🔍 DEBUG - Visualizando processo:', processo.numero_processo, 'Status:', `"${processo.status}"`)
      console.log('🔍 DEBUG - Processo completo:', processo)
      console.log('🔍 DEBUG - Comparação:', processo.status === 'em_criacao', processo.status, typeof processo.status)
      
      // Se o processo está em criação (status = rascunho), abrir Assistente para continuar editando
      if (processo.status === 'rascunho' || processo.status === 'em_criacao') {
        console.log('🔧 Processo EM CRIAÇÃO/RASCUNHO - Abrindo Assistente para edição')
        this.editarProcesso(processo)
      } else {
        console.log('👁️ Processo FINALIZADO - Abrindo visualização normal, status:', processo.status)
        this.abrirProcesso(processo)
      }
    },
    
    // =====================================================
    // GESTÃO DE MODAIS
    // =====================================================
    
    fecharAssistente() {
      this.mostrarAssistente = false
      // Limpar variáveis de edição
      this.modoEdicao = false
      this.processoParaEditar = null
      this.tipoProcessoInicial = null
      // Restaurar scroll da página
      document.body.style.overflow = 'auto'
    },
    
    fecharVisualizacaoProcesso() {
      this.processoSelecionado = null
      this.documentosProcesso = []
    },
    
    // =====================================================
    // AÇÕES DOS PROCESSOS
    // =====================================================
    
    editarProcesso(processo) {
      console.log('✏️ EDITAR processo existente:', processo.numero_processo, 'Status:', processo.status)
      
      // Verificar se o processo pode ser editado
      if (!this.podeEditarProcesso(processo)) {
        alert('Apenas processos em criação podem ser editados. Depois de criados, é possível apenas adicionar documentos.')
        return
      }
      
      // Abrir o assistente em modo de edição
      this.modoEdicao = true
      this.processoParaEditar = processo
      this.mostrarAssistente = true
      // Prevenir scroll da página de fundo
      document.body.style.overflow = 'hidden'
      
      console.log('✏️ Assistente aberto em modo EDIÇÃO para processo:', processo.numero_processo)
    },
    
    async gerarRelatorio(processo) {
      try {
        console.log('Gerando relatório PDF para processo:', processo.id)
        
        // Buscar dados completos do processo
        const processoCompleto = await ProcessosAdministrativosService.obterProcesso(processo.id)
        
        // Buscar todos os documentos com conteúdo HTML
        let documentos = await ProcessosAdministrativosService.listarDocumentosProcesso(processo.id)
        
        // Buscar produtos e seus documentos
        let produtos = []
        if (processoCompleto.tipo_processo === 'padronizacao') {
          produtos = await ProcessosAdministrativosService.listarProdutosProcesso(processo.id)
          
          // Buscar documentos dos produtos para incluir no relatório
          const tenantId = await ProcessosAdministrativosService.getTenantId()
          const { data: documentosProdutos } = await supabase
            .from('documentos_produtos_processo')
            .select('*')
            .eq('processo_id', processo.id)
            .eq('tenant_id', tenantId)
          
          if (documentosProdutos && documentosProdutos.length > 0) {
            // Adicionar documentos de produtos à lista de documentos
            for (const docProduto of documentosProdutos) {
              documentos.push({
                id: `produto_${docProduto.id}`,
                tipo_documento: 'DOCUMENTO_PRODUTO',
                nome_documento: `${docProduto.nome_produto} - ${docProduto.nome_arquivo}`,
                titulo: `${docProduto.nome_produto} - ${docProduto.nome_arquivo}`,
                descricao: `Documento técnico do produto ${docProduto.nome_produto}`,
                data_autuacao: docProduto.created_at,
                arquivo_url: docProduto.url_arquivo,
                nome_arquivo: docProduto.nome_arquivo
              })
            }
          }
        }
        
        // Buscar dados DFD se existir
        let dadosDFD = null
        try {
          const { data: dfd } = await supabase
            .from('dfd_processo')
            .select('*')
            .eq('processo_id', processo.id)
            .single()
          dadosDFD = dfd
          console.log('✅ DFD carregado do banco:', dadosDFD)
        } catch (error) {
          console.log('⚠️ DFD não encontrado no banco, usando dados padrão')
          // Dados padrão mais ricos se não encontrar no banco
          dadosDFD = {
            justificativa: 'Justificativa da necessidade conforme processo administrativo e demanda apresentada pelos setores solicitantes.',
            descricao_necessidade: 'Descrição detalhada da necessidade identificada para padronização/despadronização dos produtos especificados.',
            criterios_aceitacao: 'Critérios de aceitação e ensaios estabelecidos conforme normas técnicas aplicáveis.',
            observacoes_especiais: 'Observações especiais e condições específicas do processo de avaliação.',
            modelo_usado: 'MODELO_1'
          }
        }
        
        // Debug: verificar documentos encontrados
        console.log('Documentos encontrados:', documentos)
        console.log('Produtos encontrados:', produtos)
        console.log('DFD encontrado:', dadosDFD)
        
        // Gerar documentos que faltam se necessário
        const documentosCompletos = await this.completarDocumentosProcesso(processoCompleto, documentos, produtos, dadosDFD)
        
        console.log('Documentos completos após processamento:', documentosCompletos)
        
        // Gerar HTML do relatório
        const htmlRelatorio = this.gerarHTMLRelatorio(processoCompleto, documentosCompletos, produtos)
        
        // Criar blob para visualização
        const blob = new Blob([htmlRelatorio], { type: 'text/html' })
        const url = URL.createObjectURL(blob)
        
        // Criar nome do arquivo PDF
        const nomeArquivo = `Processo_${processoCompleto.numero_processo || processoCompleto.id}_${new Date().toISOString().split('T')[0]}.pdf`
        
        // Abrir em nova janela com funcionalidades de download
        const novaJanela = window.open('', '_blank')
        novaJanela.document.write(htmlRelatorio)
        novaJanela.document.close()
        
        // Adicionar funcionalidade de download PDF à nova janela
        setTimeout(() => {
          if (novaJanela && !novaJanela.closed) {
            // Criar elementos de download dinamicamente
            const downloadControls = novaJanela.document.createElement('div')
            downloadControls.id = 'download-controls'
            downloadControls.style.cssText = `
              position: fixed; 
              top: 10px; 
              right: 10px; 
              background: #fff; 
              border: 2px solid #dc3545; 
              border-radius: 8px; 
              padding: 15px; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.2); 
              z-index: 9999;
              display: flex;
              gap: 10px;
              font-family: Arial, sans-serif;
            `
            
            // Botão baixar PDF
            const btnDownloadPDF = novaJanela.document.createElement('button')
            btnDownloadPDF.innerHTML = '📄 Baixar PDF'
            btnDownloadPDF.style.cssText = `
              background: #dc3545; 
              color: white; 
              border: none; 
              padding: 8px 15px; 
              border-radius: 5px; 
              cursor: pointer;
              font-weight: bold;
            `
            btnDownloadPDF.onclick = () => {
              // Esconder os controles temporariamente
              downloadControls.style.display = 'none'
              
              // Aguardar um momento para garantir que os controles foram escondidos
              setTimeout(() => {
                // Usar a API print() do navegador que permite salvar como PDF
                novaJanela.print()
                
                // Mostrar os controles novamente após um tempo
                setTimeout(() => {
                  if (!novaJanela.closed) {
                    downloadControls.style.display = 'flex'
                  }
                }, 2000)
              }, 100)
            }
            
            // Botão fechar
            const btnClose = novaJanela.document.createElement('button')
            btnClose.innerHTML = '✕'
            btnClose.style.cssText = `
              background: #6c757d; 
              color: white; 
              border: none; 
              padding: 8px 12px; 
              border-radius: 5px; 
              cursor: pointer;
              font-weight: bold;
            `
            btnClose.onclick = () => {
              downloadControls.style.display = 'none'
            }
            
            // Adicionar botões ao container
            downloadControls.appendChild(btnDownloadPDF)
            downloadControls.appendChild(btnClose)
            
            // Adicionar container ao body
            novaJanela.document.body.insertBefore(downloadControls, novaJanela.document.body.firstChild)
            
            // Adicionar dica no console
            novaJanela.console.log('💡 DICA: Clique em "Baixar PDF" e escolha "Salvar como PDF" no destino da impressão.')
            
            // Adicionar CSS para esconder controles durante a impressão
            const printStyle = novaJanela.document.createElement('style')
            printStyle.textContent = `
              @media print {
                #download-controls {
                  display: none !important;
                }
              }
            `
            novaJanela.document.head.appendChild(printStyle)
          }
        }, 1000)
        
        // Limpar URL do blob principal após um tempo
        setTimeout(() => {
          URL.revokeObjectURL(url)
        }, 10000)
        
      } catch (error) {
        console.error('Erro ao gerar relatório:', error)
        alert(`Erro ao gerar relatório: ${error.message}`)
      }
    },
    
    async enviarParaAnaliseAdministrativa(processo) {
      // Configurar dados do modal de confirmação
      this.dadosConfirmacaoTramitacao = {
        icone: '🚀',
        titulo: 'Enviar para Análise Administrativa',
        numeroProcesso: processo.numero_processo,
        statusAtual: 'Criado pela CPM',
        proximoStatus: 'Aguardando Assinatura',
        placeholderObservacoes: 'Ex: Processo revisado e aprovado pela equipe técnica...',
        consequencia1: 'O processo será encaminhado para o órgão administrativo',
        consequencia2: 'Você receberá uma notificação por email sobre o andamento',
        consequencia3: 'O status será alterado para "Aguardando Assinatura"',
        textoBotao: 'Enviar para Análise'
      }
      
      // Configurar callback para executar após confirmação
      this.callbackConfirmacao = async () => {
        try {
          console.log('Enviando processo para análise administrativa:', processo.id)
          
          const observacoes = this.observacoesTramitacao || 'Processo enviado para análise administrativa'
          
          // Usar o novo sistema de tramitação
          const resultado = await TramitacaoProcessosService.enviarProcesso(processo.id, observacoes)
          
          if (resultado && resultado.sucesso) {
            console.log('✅ Processo enviado com sucesso:', resultado)
          
          // Atualizar na lista local
          const index = this.processos.findIndex(p => p.id === processo.id)
          if (index !== -1) {
            this.processos[index].status = resultado.statusNovo
          }
          
          // Atualizar processo selecionado se necessário
          if (this.processoSelecionado && this.processoSelecionado.id === processo.id) {
            this.processoSelecionado.status = resultado.statusNovo
          }
          
            // Recarregar ações disponíveis
            await this.carregarAcoesDisponiveis()
            
            // Mostrar notificação de sucesso
            this.$toast?.success(`✅ Processo enviado com sucesso!\n\nStatus: ${resultado.statusAnterior} → ${resultado.statusNovo}`)
            
            // Recarregar dados
            await this.carregarProcessos()
          } else {
            throw new Error('Falha na tramitação do processo')
          }
          
        } catch (error) {
          console.error('Erro ao enviar processo para análise:', error)
          this.$toast?.error(`❌ Erro ao enviar processo: ${error.message}`) || alert(`❌ Erro: ${error.message}`)
        }
      }
      
      // Mostrar o modal de confirmação
      this.observacoesTramitacao = ''
      this.mostrarModalConfirmacaoTramitacao = true
    },
    
    adicionarDocumento(processo) {
      console.log('📎 Abrindo modal para adicionar documento ao processo:', processo.numero_processo)
      this.processoSelecionado = processo
      this.mostrarModalAdicionarDoc = true
    },
    
    async verTramitacao(processo) {
      console.log('📋 Carregando tramitação do processo:', processo.numero_processo)
      this.processoSelecionado = processo
      
      try {
        // Carregar histórico de tramitação
        await this.carregarHistoricoTramitacao(processo.id)
        this.mostrarModalTramitacao = true
      } catch (error) {
        console.error('Erro ao carregar histórico de tramitação:', error)
        alert('Erro ao carregar histórico de tramitação: ' + error.message)
      }
    },
    
    // =====================================================
    // AÇÕES RÁPIDAS
    // =====================================================
    
    abrirRelatorios() {
      alert('Funcionalidade de relatórios em desenvolvimento')
    },
    
    abrirConfiguracoes() {
      alert('Funcionalidade de configurações em desenvolvimento')
    },
    
    // =====================================================
    // GESTÃO DE EDITAIS E DOCUMENTAÇÃO
    // =====================================================
    
    abrirModalEdital(processo) {
      this.processoSelecionado = processo
      this.mostrarModalEdital = true
    },
    
    fecharModalEdital() {
      this.mostrarModalEdital = false
      this.processoSelecionado = null
    },
    
    async onEditalVinculado(evento) {
      try {
        console.log('🔗 DEBUG - Edital vinculado, evento recebido:', evento)
        
        // Atualizar processo na lista
        const index = this.processos.findIndex(p => p.id === evento.processo.id)
        if (index !== -1) {
          this.processos[index] = { ...this.processos[index], ...evento.processo }
        }
        
        // Atualizar processo selecionado se for o mesmo
        if (this.processoSelecionado && this.processoSelecionado.id === evento.processo.id) {
          this.processoSelecionado = { ...this.processoSelecionado, ...evento.processo }
          console.log('✅ DEBUG - Processo selecionado atualizado')
        }
        
        // RECARREGAR APENAS OS DOCUMENTOS do processo atual (não toda a lista)
        if (this.processoSelecionado && this.processoSelecionado.id === evento.processo.id) {
          console.log('🔄 DEBUG - Recarregando documentos do processo após vincular edital')
          await this.carregarDocumentosProcesso(this.processoSelecionado.id)
        }
        
        console.log('✅ Edital vinculado com sucesso:', evento.dadosEdital)
        
      } catch (error) {
        console.error('❌ Erro ao processar vinculação de edital:', error)
      }
    },
    
    visualizarDocumentacao(processo) {
      this.processoSelecionado = processo
      this.mostrarDocumentacao = true
    },
    
    fecharDocumentacao() {
      this.mostrarDocumentacao = false
      this.processoSelecionado = null
    },
    
    fecharModalAdicionarDoc() {
      this.mostrarModalAdicionarDoc = false
      this.processoSelecionado = null
    },
    
    fecharModalTramitacao() {
      this.mostrarModalTramitacao = false
      this.processoSelecionado = null
    },
    
    // =====================================================
    // GESTÃO DE TRAMITAÇÃO DE PROCESSOS
    // =====================================================
    
    async carregarAcoesDisponiveis() {
      try {
        const acoes = {}
        for (const processo of this.processos) {
          acoes[processo.id] = await TramitacaoProcessosService.obterAcoesDisponiveis(processo)
        }
        this.acoesDisponiveis = acoes
      } catch (error) {
        console.error('Erro ao carregar ações disponíveis:', error)
        this.acoesDisponiveis = {}
      }
    },
    
    async executarAcaoTramitacao(processo, acao) {
      try {
        let observacoes = ''
        let motivo = ''
        
        // Solicitar observações baseadas no tipo de ação
        if (acao.tipo === 'ENVIAR') {
          observacoes = prompt(`Observações para envio:`) || ''
        } else if (acao.tipo === 'DEVOLVER') {
          motivo = prompt(`Motivo da devolução (obrigatório):`)
          if (!motivo || motivo.trim() === '') {
            alert('Motivo é obrigatório para devolver um processo.')
            return
          }
          observacoes = prompt(`Observações adicionais:`) || ''
        } else if (acao.tipo === 'REJEITAR') {
          motivo = prompt(`Motivo da rejeição (obrigatório):`)
          if (!motivo || motivo.trim() === '') {
            alert('Motivo é obrigatório para rejeitar um processo.')
            return
          }
          observacoes = prompt(`Observações adicionais:`) || ''
        }
        
        // Confirmar ação
        const confirmacao = confirm(`Confirma ${acao.label.toLowerCase()}?\n\n${acao.descricao}`)
        if (!confirmacao) return
        
        let resultado
        
        switch (acao.tipo) {
          case 'ENVIAR':
            resultado = await TramitacaoProcessosService.enviarProcesso(processo.id, observacoes)
            break
          case 'DEVOLVER':
            resultado = await TramitacaoProcessosService.devolverProcesso(processo.id, motivo, observacoes)
            break
          case 'REJEITAR':
            resultado = await TramitacaoProcessosService.rejeitarProcesso(processo.id, motivo, observacoes)
            break
          default:
            throw new Error(`Ação não implementada: ${acao.tipo}`)
        }
        
        if (resultado && resultado.sucesso) {
          const statusInfo = this.obterInfoStatus(resultado.statusNovo)
          alert(`✅ Ação executada com sucesso!\n\nStatus anterior: ${resultado.statusAnterior}\nNovo status: ${resultado.statusNovo}`)
          
          // Recarregar lista de processos
          await this.carregarProcessos()
          
          // Atualizar processo no modal se ele estiver aberto
          if (this.processoSelecionado && this.processoSelecionado.id === processo.id) {
            // Buscar o processo atualizado
            const processoAtualizado = this.processos.find(p => p.id === processo.id)
            if (processoAtualizado) {
              this.processoSelecionado = processoAtualizado
              // Recarregar ações disponíveis para o novo status
              await this.carregarAcoesDisponiveis()
            }
          }
        }
      } catch (error) {
        console.error('Erro ao executar ação:', error)
        alert(`Erro ao executar ação: ${error.message}`)
      }
    },
    
    obterInfoStatus(status) {
      const statusInfo = {
        'criado_cpm': '🎯 Criado pela CPM',
        'aprovado_cpm': '📋 Aprovado pela CPM',
        'assinado_admin': '✅ Assinado pelo Órgão',
        'julgamento_ccl': '⚖️ Julgamento CCL',
        'aprovado_ccl': '💜 Aprovado pela CCL',
        'aprovado_juridico': '⚖️ Aprovado Juridicamente',
        'homologado': '✅ Com Homologação',
        'finalizado': '🏆 Finalizado',
        'criado_cpm_desp': '🎯 Criado pela CPM',
        'submetido_autoridade_desp': '📋 Submetido à Autoridade',
        'abertura_autorizada_desp': '✅ Abertura Autorizada',
        'homologado_desp': '✅ Com Homologação',
        'rejeitado_cpm': '❌ Rejeitado pela CPM',
        'rejeitado_admin': '❌ Rejeitado pelo Órgão',
        'rejeitado_ccl': '❌ Rejeitado pela CCL',
        'rejeitado_juridico': '❌ Rejeitado Juridicamente'
      }
      return statusInfo[status] || status
    },
    
    obterLabelAcao(acao) {
      const labels = {
        'submeter_analise': '🎯 Submeter para Análise',
        'aprovar_cpm': '✅ Aprovar (CPM)',
        'rejeitar_cpm': '❌ Rejeitar (CPM)',
        'assinar_admin': '✍️ Assinar (Órgão)',
        'rejeitar_admin': '❌ Rejeitar (Órgão)',
        'enviar_ccl': '📤 Enviar para CCL',
        'aprovar_ccl': '⚖️ Aprovar (CCL)',
        'rejeitar_ccl': '❌ Rejeitar (CCL)',
        'aprovar_juridico': '⚖️ Aprovar (Jurídico)',
        'rejeitar_juridico': '❌ Rejeitar (Jurídico)',
        'homologar': '🏆 Homologar',
        'rejeitar_final': '❌ Rejeitar Final'
      }
      
      return labels[acao] || acao
    },
    
    // =====================================================
    // UTILITÁRIOS
    // =====================================================
    
    formatarData(data) {
      if (!data) return 'N/A'
      return new Date(data).toLocaleDateString('pt-BR')
    },
    
    visualizarDocumento(documento) {
      const url = documento.arquivo_url || documento.url_arquivo
      if (url) {
        console.log('📄 Abrindo documento:', documento.nome_documento, 'URL:', url)
        // Abrir documento em nova aba
        window.open(url, '_blank')
      } else {
        console.warn('⚠️ Documento sem URL:', documento)
        alert('Este documento não possui arquivo anexo para visualização.')
      }
    },
    
    obterTipoProcesso(tipo) {
      return ProcessosAdministrativosService.obterTipoProcesso(tipo)
    },
    
    obterStatusProcesso(status) {
      return ProcessosAdministrativosService.obterStatusProcesso(status)
    },

    formatarStatus(status) {
      return ProcessosAdministrativosService.obterStatusProcesso(status).label
    },
    
    // =====================================================
    // UPLOAD DE DOCUMENTOS
    // =====================================================
    
    onSelectDocumento(event) {
      const files = Array.from(event.target.files)
      this.adicionarArquivos(files)
    },
    
    onDropDocumento(event) {
      event.preventDefault()
      const files = Array.from(event.dataTransfer.files)
      this.adicionarArquivos(files)
    },
    
    adicionarArquivos(files) {
      const formatosPermitidos = ['.pdf']
      const tamanhoMaximo = 50 * 1024 * 1024 // 50MB
      
      files.forEach(file => {
        const extensao = '.' + file.name.split('.').pop().toLowerCase()
        
        if (!formatosPermitidos.includes(extensao)) {
          alert(`Formato não permitido: ${file.name}. Use apenas arquivos PDF`)
          return
        }
        
        if (file.size > tamanhoMaximo) {
          alert(`Arquivo muito grande: ${file.name}. Máximo: 50MB`)
          return
        }
        
        // Evitar duplicatas
        const jaExiste = this.documentosParaUpload.some(doc => doc.name === file.name && doc.size === file.size)
        if (!jaExiste) {
          this.documentosParaUpload.push(file)
        }
      })
    },
    
    removerDocumento(index) {
      this.documentosParaUpload.splice(index, 1)
    },
    
    formatarTamanho(bytes) {
      if (bytes === 0) return '0 Bytes'
      const k = 1024
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    },
    
    async uploadDocumentos() {
      if (this.documentosParaUpload.length === 0) {
        alert('Selecione pelo menos um documento')
        return
      }
      
      // Para órgão administrativo, definir automaticamente como ASSINADO
      // Para outros perfis, exigir seleção do tipo
      if (!this.isOrgaoAdministrativo() && !this.tipoDocumentoSelecionado) {
        alert('Selecione o tipo do documento')
        return
      }
      
      try {
        this.processandoUpload = true
        let sucessos = 0
        let falhas = []
        
        for (let i = 0; i < this.documentosParaUpload.length; i++) {
          const arquivo = this.documentosParaUpload[i]
          
          try {
            console.log(`📤 Enviando arquivo ${i + 1}/${this.documentosParaUpload.length}: ${arquivo.name}`)
            
            // Upload do arquivo para storage com retry
            const nomeArquivo = `${Date.now()}_${arquivo.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`
            let uploadTentativas = 0
            let uploadSucesso = false
            let uploadData, uploadError
            
            while (uploadTentativas < 3 && !uploadSucesso) {
              uploadTentativas++
              console.log(`🔄 Tentativa ${uploadTentativas} de upload para: ${arquivo.name}`)
              
              const result = await supabase.storage
                .from('documentosprocessos')
                .upload(nomeArquivo, arquivo)
              
              uploadData = result.data
              uploadError = result.error
              
              if (!uploadError) {
                uploadSucesso = true
                console.log(`✅ Upload realizado com sucesso: ${arquivo.name}`)
              } else {
                console.warn(`⚠️ Tentativa ${uploadTentativas} falhou:`, uploadError)
                if (uploadTentativas < 3) {
                  await new Promise(resolve => setTimeout(resolve, 2000)) // Aguardar 2s antes da próxima tentativa
                }
              }
            }
            
            if (!uploadSucesso) {
              throw new Error(`Falha no upload após 3 tentativas: ${uploadError?.message || 'Erro desconhecido'}`)
            }
            
            // Obter URL pública
            const { data: { publicUrl } } = supabase.storage
              .from('documentosprocessos')
              .getPublicUrl(nomeArquivo)
            
            console.log(`🔗 URL gerada: ${publicUrl}`)
            
            // Obter próxima numeração sequencial usando o serviço
            const { numero, folha } = await NumeracaoDocumentosService.obterProximoNumero(this.processoSelecionado.id)
            console.log(`📋 Numeração gerada: ${folha} (número ${numero})`)
            
            // Definir tipo do documento
            const tipoDocumento = this.isOrgaoAdministrativo() ? 'ASSINADO' : this.tipoDocumentoSelecionado
            
            // Inserir registro na tabela documentos_processo com retry
            const documentoData = {
              processo_id: this.processoSelecionado.id,
              tenant_id: await ProcessosAdministrativosService.getTenantId(),
              numero_sequencial: numero,
              folha_numero: folha,
              tipo_documento: tipoDocumento,
              nome_documento: arquivo.name,
              titulo: arquivo.name,
              descricao: this.observacoesDocumento || `Documento ${tipoDocumento.toLowerCase()} adicionado pelo órgão administrativo`,
              arquivo_url: publicUrl,
              data_autuacao: new Date().toISOString(),
              assinado: false,
              status: 'ativo'
            }
            
            let dbTentativas = 0
            let dbSucesso = false
            let dbError
            
            while (dbTentativas < 3 && !dbSucesso) {
              dbTentativas++
              console.log(`🔄 Tentativa ${dbTentativas} de registro no banco para: ${arquivo.name}`)
              
              const result = await supabase
                .from('documentos_processo')
                .insert([documentoData])
              
              dbError = result.error
              
              if (!dbError) {
                dbSucesso = true
                console.log(`✅ Registro no banco realizado com sucesso: ${arquivo.name}`)
              } else {
                console.warn(`⚠️ Tentativa ${dbTentativas} do banco falhou:`, dbError)
                if (dbTentativas < 3) {
                  await new Promise(resolve => setTimeout(resolve, 1000)) // Aguardar 1s antes da próxima tentativa
                }
              }
            }
            
            if (!dbSucesso) {
              throw new Error(`Falha no registro no banco após 3 tentativas: ${dbError?.message || 'Erro desconhecido'}`)
            }
            
            sucessos++
            console.log(`✅ Arquivo processado com sucesso: ${arquivo.name}`)
            
          } catch (fileError) {
            console.error(`❌ Erro ao processar ${arquivo.name}:`, fileError)
            falhas.push(`${arquivo.name}: ${fileError.message}`)
          }
        }
        
        // Mostrar resultado
        if (sucessos > 0) {
          let mensagem = `✅ ${sucessos} documento(s) adicionado(s) com sucesso!`
          if (falhas.length > 0) {
            mensagem += `\n\n❌ ${falhas.length} falha(s):\n${falhas.join('\n')}`
          }
          alert(mensagem)
          
          // Limpar formulário apenas se houve pelo menos um sucesso
          this.documentosParaUpload = []
          this.tipoDocumentoSelecionado = ''
          this.observacoesDocumento = ''
          
          // Recarregar documentos do processo
          try {
            await this.carregarDocumentosProcesso(this.processoSelecionado.id)
          } catch (reloadError) {
            console.warn('Erro ao recarregar documentos:', reloadError)
          }
          
          this.fecharModalAdicionarDoc()
        } else {
          alert(`❌ Nenhum documento foi adicionado.\n\nErros:\n${falhas.join('\n')}`)
        }
        
      } catch (error) {
        console.error('Erro geral no upload de documentos:', error)
        alert('❌ Erro inesperado no upload: ' + error.message)
      } finally {
        this.processandoUpload = false
      }
    },
    
    formatarDataHora(data) {
      if (!data) return 'N/A'
      return new Date(data).toLocaleString('pt-BR')
    },
    
    // Métodos para o modal de confirmação de tramitação
    fecharModalConfirmacaoTramitacao() {
      this.mostrarModalConfirmacaoTramitacao = false
      this.dadosConfirmacaoTramitacao = {}
      this.observacoesTramitacao = ''
      this.processandoTramitacao = false
      this.callbackConfirmacao = null
    },
    
    async confirmarTramitacao() {
      if (!this.callbackConfirmacao) return
      
      this.processandoTramitacao = true
      
      try {
        await this.callbackConfirmacao()
        this.fecharModalConfirmacaoTramitacao()
      } catch (error) {
        console.error('Erro na tramitação:', error)
        this.processandoTramitacao = false
      }
    },
    
    // =====================================================
    // MÉTODOS PARA ÓRGÃO ADMINISTRATIVO
    // =====================================================
    
    // Abrir modal de devolução
    abrirModalDevolucao(processo) {
      console.log('📝 Abrindo modal de devolução para processo:', processo.numero_processo)
      this.processoParaDevolucao = processo
      this.motivoDevolucao = ''
      this.observacoesDevolucao = ''
      this.processandoDevolucao = false
      this.mostrarModalDevolucao = true
    },
    
    // Fechar modal de devolução
    fecharModalDevolucao() {
      this.mostrarModalDevolucao = false
      this.processoParaDevolucao = null
      this.motivoDevolucao = ''
      this.observacoesDevolucao = ''
      this.processandoDevolucao = false
    },
    
    // Confirmar devolução do processo
    async confirmarDevolucao() {
      if (!this.motivoDevolucao.trim()) {
        alert('⚠️ Por favor, informe o motivo da devolução.')
        return
      }
      
      this.processandoDevolucao = true
      
      try {
        console.log('🔄 Devolvendo processo:', this.processoParaDevolucao.numero_processo)
        
        const resultado = await TramitacaoProcessosService.devolverProcesso(
          this.processoParaDevolucao.id,
          this.motivoDevolucao,
          this.observacoesDevolucao
        )
        
        if (resultado.sucesso) {
          console.log('✅ Processo devolvido com sucesso')
          
          // Mostrar mensagem de sucesso
          alert(
            `✅ PROCESSO DEVOLVIDO COM SUCESSO\n\n` +
            `Processo: ${this.processoParaDevolucao.numero_processo}\n` +
            `Status anterior: ${this.obterNomeStatus(resultado.statusAnterior)}\n` +
            `Status atual: ${this.obterNomeStatus(resultado.statusNovo)}\n\n` +
            `O processo foi devolvido para a CPM com o motivo informado.`
          )
          
          // Recarregar processos e fechar modal
          await this.carregarProcessos()
          this.fecharModalDevolucao()
          this.fecharVisualizacaoProcesso()
        }
        
      } catch (error) {
        console.error('❌ Erro ao devolver processo:', error)
        alert(`❌ Erro ao devolver processo: ${error.message}`)
      } finally {
        this.processandoDevolucao = false
      }
    },
    
    // Assinar documento e enviar para CCL
    async assinarEEnviarProcesso(processo) {
      try {
        console.log('✍️ Assinando e enviando processo para CCL:', processo.numero_processo)
        
        const confirmacao = confirm(
          `✍️ ASSINAR E ENVIAR PROCESSO\n\n` +
          `Processo: ${processo.numero_processo}\n` +
          `Status atual: Aguardando Assinatura do Órgão\n` +
          `Próximo status: Assinado pelo Órgão Administrativo\n\n` +
          `Confirma a assinatura e envio para a CCL?`
        )
        
        if (!confirmacao) return
        
        const resultado = await TramitacaoProcessosService.enviarProcesso(
          processo.id,
          'Documento assinado pelo Órgão Administrativo'
        )
        
        if (resultado.sucesso) {
          console.log('✅ Processo assinado e enviado com sucesso')
          
          alert(
            `✅ PROCESSO ASSINADO E ENVIADO\n\n` +
            `Processo: ${processo.numero_processo}\n` +
            `Status anterior: ${this.obterNomeStatus(resultado.statusAnterior)}\n` +
            `Status atual: ${this.obterNomeStatus(resultado.statusNovo)}\n\n` +
            `O processo foi assinado e enviado para julgamento da CCL.`
          )
          
          // Recarregar processos
          await this.carregarProcessos()
          this.fecharVisualizacaoProcesso()
        }
        
      } catch (error) {
        console.error('❌ Erro ao assinar e enviar processo:', error)
        alert(`❌ Erro ao processar assinatura: ${error.message}`)
      }
    },
    
    // =====================================================
    // MÉTODOS UTILITÁRIOS
    // =====================================================
    
    // Obter nome legível do status
    obterNomeStatus(status) {
      const nomes = {
        'rascunho': 'Rascunho',
        'criado_cpm': 'Criado pela CPM',
        'aguardando_assinatura_orgao': 'Aguardando Assinatura do Órgão',
        'assinado_admin': 'Assinado pelo Órgão Administrativo',
        'julgamento_ccl': 'Em Julgamento pela CCL',
        'aprovado_ccl': 'Aprovado pela CCL',
        'aprovado_juridico': 'Aprovado pela Assessoria Jurídica',
        'edital_publicado': 'Edital Publicado',
        'homologado': 'Processo Homologado',
        'finalizado': 'Processo Finalizado',
        
        // STATUS DE DEVOLUÇÃO
        'devolvido_pelo_orgao': 'Devolvido pelo Órgão Administrativo',
        'devolvido_pela_ccl': 'Devolvido pela CCL',
        'devolvido_pelo_juridico': 'Devolvido pela Assessoria Jurídica'
      }
      
      return nomes[status?.toLowerCase()] || status || 'Status Desconhecido'
    },
    
    // Verificar se processo foi devolvido
    processoFoiDevolvido(processo) {
      const statusDevolvido = ['devolvido_pelo_orgao', 'devolvido_pela_ccl', 'devolvido_pelo_juridico']
      return statusDevolvido.includes(processo?.status?.toLowerCase())
    },
    
    // Verificar se CPM pode reenviar processo devolvido
    podeReenviarProcesso(processo) {
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      return perfilUsuario === 'cpm' && this.processoFoiDevolvido(processo)
    },
    
    // Reenviar processo devolvido
    async reenviarProcessoDevolvido(processo) {
      try {
        const observacoes = prompt(
          `🔄 REENVIAR PROCESSO APÓS CORREÇÕES\n\n` +
          `Processo: ${processo.numero_processo}\n` +
          `Status atual: ${this.obterNomeStatus(processo.status)}\n\n` +
          `Informe observações sobre as correções realizadas (opcional):`
        )
        
        if (observacoes === null) return // Usuário cancelou
        
        console.log('🔄 Reenviando processo devolvido:', processo.numero_processo)
        
        const resultado = await TramitacaoProcessosService.reenviarProcessoDevolvido(
          processo.id,
          observacoes || 'Processo reenviado após correções'
        )
        
        if (resultado.sucesso) {
          alert(
            `✅ PROCESSO REENVIADO COM SUCESSO\n\n` +
            `Processo: ${processo.numero_processo}\n` +
            `Status anterior: ${this.obterNomeStatus(resultado.statusAnterior)}\n` +
            `Status atual: ${this.obterNomeStatus(resultado.statusNovo)}\n` +
            `Destinatário: ${resultado.destinatario}\n\n` +
            `O processo foi reenviado após as correções.`
          )
          
          // Recarregar processos
          await this.carregarProcessos()
          this.fecharVisualizacaoProcesso()
        }
        
      } catch (error) {
        console.error('❌ Erro ao reenviar processo:', error)
        alert(`❌ Erro ao reenviar processo: ${error.message}`)
      }
    },
  }
}
</script>

<style scoped>
.content-wrapper {
  display: grid;
  grid-template-columns: 350px 1fr;
  gap: 0;
  height: 100vh;
  overflow: hidden;
}

.sidebar {
  background: white;
  padding: 0.75rem; /* Reduzido ainda mais para economizar espaço */
  border-right: 1px solid #e2e8f0;
  height: 100vh;
  overflow: hidden; /* Sidebar não vai ter scroll */
  display: flex;
  flex-direction: column;
}

.filter-section h3,
.upload-section h3 {
  margin-bottom: 0.5rem; /* Reduzido de 1rem */
  color: #2d3748;
  font-size: 1rem; /* Reduzido de 1.1rem */
}

.filter-group {
  margin-bottom: 0.75rem; /* Reduzido de 1rem */
}

.filter-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #4a5568;
}

.filter-group select,
.search-input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
}

.upload-section {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.btn-upload {
  width: 100%;
  padding: 0.75rem;
  background: #2c3e50;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.btn-upload:hover {
  background: #34495e;
}

.iniciar-processo-section {
  margin-bottom: 1rem; /* Aumentado um pouco para melhor visual */
  padding: 0.75rem; /* Aumentado um pouco para melhor visual */
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  text-align: center;
}

.iniciar-processo-section h3 {
  margin: 0 0 0.3rem 0; /* Aumentado um pouco para melhor visual */
  font-size: 1.1rem; /* Aumentado um pouco para melhor visual */
  font-weight: 700;
  color: #2d3748;
}

.subtitle {
  margin: 0 0 1rem 0; /* Aumentado um pouco para melhor visual */
  color: #4a5568;
  font-size: 0.9rem; /* Aumentado um pouco para melhor visual */
}

.sistema-titulo {
  margin: 0 0 0.75rem 0; /* Aumentado um pouco para melhor visual */
  text-align: center;
}

.sistema-nome {
  margin: 0;
  font-size: 1rem; /* Reduzido para economizar espaço */
  font-weight: 600;
  color: #2d3748;
  line-height: 1.2;
}

.sistema-slogan {
  margin: 0.1rem 0 0 0; /* Reduzido para economizar espaço */
  font-size: 0.8rem; /* Reduzido para economizar espaço */
  color: #4a5568;
  font-style: italic;
  line-height: 1.2;
}

.aviso-desenvolvimento {
  display: flex;
  align-items: flex-start;
  background: linear-gradient(135deg, #fef3cd, #fde68a);
  border: 2px solid #f59e0b;
  border-radius: 12px;
  padding: 1rem;
  margin-bottom: 1.5rem;
  box-shadow: 0 4px 6px rgba(245, 158, 11, 0.1);
}

.aviso-icon {
  font-size: 1.5rem;
  margin-right: 0.75rem;
  flex-shrink: 0;
}

.aviso-content h4 {
  margin: 0 0 0.5rem 0;
  color: #92400e;
  font-size: 1rem;
  font-weight: 600;
}

.aviso-content p {
  margin: 0 0 0.25rem 0;
  color: #a16207;
  font-size: 0.9rem;
  line-height: 1.4;
}

.aviso-content small {
  color: #b45309;
  font-size: 0.8rem;
  opacity: 0.8;
}

.botoes-principais {
  display: flex;
  gap: 0.75rem; /* Aumentado um pouco para melhor visual */
  flex-direction: column;
}

.btn-processo {
  background: white;
  border: 2px solid #e2e8f0;
  color: #2d3748;
  padding: 0.75rem; /* Reduzido de 1rem */
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 1rem;
  text-align: left;
}

.btn-processo:hover {
  background: #f7fafc;
  border-color: #cbd5e0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.btn-processo .icone {
  font-size: 2rem;
  flex-shrink: 0;
}

.btn-processo .texto strong {
  display: block;
  font-size: 1rem;
  margin-bottom: 0.25rem;
  color: #2d3748;
}

.btn-processo .texto small {
  font-size: 0.8rem;
  color: #718096;
}

.acoes-rapidas-section {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.btn-acao {
  width: 100%;
  padding: 0.75rem;
  margin-bottom: 0.5rem;
  background: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9rem;
  text-align: left;
}

.btn-acao:hover {
  background: #edf2f7;
  border-color: #cbd5e0;
}

.processos-section {
  background: white;
  padding: 1.5rem;
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.processos-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.processos-header h3 {
  color: #2d3748;
  margin: 0;
}

.view-options {
  display: flex;
  gap: 0.5rem;
}

.view-options button {
  padding: 0.5rem 1rem;
  border: 1px solid #e2e8f0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
  transition: all 0.3s ease;
}

.view-options button.active {
  background: #2c3e50;
  color: white;
  border-color: #2c3e50;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: #718096;
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e2e8f0;
  border-top: 4px solid #2c3e50;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 3rem;
  color: #718096;
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.processos-container {
  flex: 1;
  overflow-y: auto;
  padding-right: 0.5rem;
}

.processos-container.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.processos-container.list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.processo-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  will-change: box-shadow, border-color;
}

.processo-card:hover {
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
  border-color: #cbd5e0;
}

.processo-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.processo-numero {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.numero {
  font-size: 1.2rem;
  font-weight: 700;
  color: #2d3748;
}

.tipo {
  font-size: 0.8rem;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-weight: 600;
}

.tipo.padronizacao {
  background: #dcfce7;
  color: #166534;
}

.tipo.despadronizacao {
  background: #fee2e2;
  color: #dc2626;
}

.processo-status {
  display: flex;
  align-items: center;
}

.status-badge {
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.status-badge.blue {
  background: #dbeafe;
  color: #1e40af;
}

.status-badge.green {
  background: #dcfce7;
  color: #166534;
}

.status-badge.yellow {
  background: #fef3c7;
  color: #d97706;
}

.status-badge.red {
  background: #fee2e2;
  color: #dc2626;
}

.status-badge.gray {
  background: #f3f4f6;
  color: #6b7280;
}

.status-badge.pink {
  background: #fce7f3;
  color: #be185d;
}

.status-badge.purple {
  background: #ede9fe;
  color: #7c3aed;
}

.status-badge.orange {
  background: #fed7aa;
  color: #ea580c;
}

.status-badge.cyan {
  background: #cffafe;
  color: #0891b2;
}

.status-badge.indigo {
  background: #e0e7ff;
  color: #4338ca;
}

.status-badge.amber {
  background: #fef3c7;
  color: #d97706;
}

/* Ações de Tramitação no Modal */
.tramitacao-actions-container {
  margin: 2rem 0;
  padding: 1.5rem;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}

.tramitacao-actions-container h4 {
  margin: 0 0 1rem 0;
  color: #2d3748;
  font-size: 1.1rem;
  font-weight: 600;
}

.workflow-buttons-modal {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.btn-workflow-modal {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9rem;
  min-width: 140px;
  text-align: center;
}

.btn-workflow-modal.success {
  background: #dcfce7;
  color: #166534;
  border: 2px solid #16a34a;
}

.btn-workflow-modal.success:hover {
  background: #16a34a;
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(22, 163, 74, 0.3);
}

.btn-workflow-modal.warning {
  background: #fed7aa;
  color: #ea580c;
  border: 2px solid #f97316;
}

.btn-workflow-modal.warning:hover {
  background: #f97316;
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(249, 115, 22, 0.3);
}

.btn-workflow-modal.danger {
  background: #fee2e2;
  color: #dc2626;
  border: 2px solid #ef4444;
}

.btn-workflow-modal.danger:hover {
  background: #ef4444;
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
}

.processo-info {
  margin-bottom: 1rem;
}

.processo-info h4 {
  margin: 0 0 0.5rem;
  color: #1f2937;
  font-size: 1.1rem;
  font-weight: 600;
}

.interessado {
  margin: 0 0 0.5rem;
  color: #6b7280;
  font-size: 0.9rem;
}

.objeto {
  margin: 0;
  color: #4b5563;
  font-size: 0.9rem;
  line-height: 1.4;
}

.processo-meta {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 0.75rem;
  margin-bottom: 1rem;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 8px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.meta-label {
  font-size: 0.75rem;
  color: #6b7280;
  font-weight: 500;
}

.meta-value {
  font-size: 0.9rem;
  color: #1f2937;
  font-weight: 600;
}

.processo-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  justify-content: flex-start;
  margin-top: 1rem;
}

.btn-action {
  padding: 0.4rem 0.8rem;
  border: 1px solid #e2e8f0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.75rem;
  white-space: nowrap;
  flex: 0 0 auto;
  min-width: fit-content;
}

.btn-action:hover {
  background: #f7fafc;
  border-color: #cbd5e0;
}

.btn-action.primary {
  background: #2c3e50;
  color: white;
  border-color: #2c3e50;
}

.btn-action.primary:hover {
  background: #34495e;
}

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

.modal {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow: auto;
}

.modal-large {
  max-width: 1200px;
  height: 90vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e2e8f0;
}

.modal-header h3 {
  margin: 0;
  color: #2d3748;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #a0aec0;
}

.modal-body {
  padding: 1.5rem;
  flex: 1;
  overflow-y: auto;
}

/* Modal específico para documentação */
.modal-documentacao {
  background: white;
  border-radius: 12px;
  width: 95%;
  max-width: 1400px;
  height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
}

.modal-documentacao .modal-header {
  background: #f7fafc;
  border-bottom: 2px solid #e2e8f0;
  padding: 1.5rem 2rem;
}

.modal-documentacao .modal-header h3 {
  font-size: 1.3rem;
  color: #2d3748;
  margin: 0;
}

.modal-documentacao .modal-body {
  flex: 1;
  overflow: hidden;
  padding: 0;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #4a5568;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
}

.form-group small {
  display: block;
  margin-top: 0.25rem;
  color: #718096;
  font-size: 0.8rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1.5rem;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.btn-primary {
  background: #2c3e50;
  color: white;
}

.btn-primary:hover {
  background: #34495e;
}

.btn-primary:disabled {
  background: #a0aec0;
  cursor: not-allowed;
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.btn-secondary:hover {
  background: #cbd5e0;
}

.btn-success {
  background: #48bb78;
  color: white;
}

.btn-success:hover {
  background: #38a169;
}

.document-details {
  margin-bottom: 1.5rem;
}

.document-details p {
  margin-bottom: 0.75rem;
  line-height: 1.5;
}


.processo-title-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.processo-icon-large {
  font-size: 2.5rem;
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f7fafc;
  border-radius: 12px;
}

.processo-tipo-badge {
  background: #e2e8f0;
  color: #4a5568;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
  margin-right: 0.5rem;
}

.processo-tipo-badge.padronizacao {
  background: #dcfce7;
  color: #166534;
}

.processo-tipo-badge.despadronizacao {
  background: #fee2e2;
  color: #dc2626;
}

.processo-status-badge {
  background: #dbeafe;
  color: #1e40af;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.processo-viewer-container {
  display: grid;
  grid-template-columns: 350px 1fr;
  gap: 2rem;
  height: 100%;
}

.processo-details-panel {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1.5rem;
  height: fit-content;
}

.processo-details-panel h4 {
  margin: 0 0 1.5rem 0;
  color: #2d3748;
  font-size: 1.1rem;
}

.detail-item {
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e2e8f0;
}

.detail-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.detail-item strong {
  display: block;
  margin-bottom: 0.5rem;
  color: #4a5568;
  font-size: 0.9rem;
}

.detail-item p {
  margin: 0;
  color: #2d3748;
  line-height: 1.5;
}

.category-pill {
  background: #2c3e50;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.processo-actions-panel {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 2px solid #e2e8f0;
}

.actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 0.75rem;
  margin-top: 1rem;
}

.action-btn {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  padding: 0.875rem 1.25rem;
  border: none;
  border-radius: 10px;
  font-weight: 600;
  font-size: 0.95rem;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
}

.action-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.action-btn:active {
  transform: translateY(0);
}

.btn-icon {
  font-size: 1.2rem;
  margin-right: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
}

.btn-text {
  flex: 1;
  text-align: left;
  font-weight: 600;
}

/* Cores específicas para cada tipo de botão */
.action-btn-primary {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
}

.action-btn-primary:hover {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
}

.action-btn-info {
  background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
  color: white;
}

.action-btn-info:hover {
  background: linear-gradient(135deg, #0891b2 0%, #0e7490 100%);
}

.action-btn-success {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
}

.action-btn-success:hover {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
}

.action-btn-secondary {
  background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
  color: white;
}

.action-btn-secondary:hover {
  background: linear-gradient(135deg, #4b5563 0%, #374151 100%);
}

.action-btn-warning {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: white;
}

.action-btn-warning:hover {
  background: linear-gradient(135deg, #d97706 0%, #b45309 100%);
}

@media (max-width: 768px) {
  .actions-grid {
    grid-template-columns: 1fr;
  }
}

.processo-content-panel {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
  overflow-y: auto;
}

.processo-content-panel h4 {
  margin: 0 0 1.5rem 0;
  color: #2d3748;
  font-size: 1.1rem;
}

.objeto-container {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
  margin-bottom: 2rem;
}

.objeto-texto {
  margin: 0;
  color: #4b5563;
  line-height: 1.6;
  text-align: justify;
}

.documentos-container {
  margin-bottom: 2rem;
  max-height: 400px;
  overflow-y: auto;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 1rem;
}

.empty-documentos {
  text-align: center;
  padding: 2rem;
  color: #6b7280;
  background: #f9fafb;
  border-radius: 8px;
  border: 1px dashed #d1d5db;
}

.lista-documentos {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.documento-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: white;
  transition: all 0.3s ease;
}

.documento-item:hover {
  border-color: #cbd5e0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.doc-numero {
  background: #2c3e50;
  color: white;
  padding: 0.5rem;
  border-radius: 6px;
  font-weight: 600;
  font-size: 0.9rem;
  min-width: 60px;
  text-align: center;
}

.doc-info {
  flex: 1;
}

.doc-info h5 {
  margin: 0 0 0.25rem 0;
  color: #1f2937;
  font-size: 1rem;
}

.doc-info p {
  margin: 0 0 0.25rem 0;
  color: #6b7280;
  font-size: 0.9rem;
}

.doc-info small {
  color: #9ca3af;
  font-size: 0.8rem;
}

.doc-status {
  text-align: center;
}

.status-assinado {
  color: #059669;
  font-size: 0.8rem;
  font-weight: 600;
}

.status-disponivel {
  color: #0369a1;
  font-size: 0.8rem;
  font-weight: 600;
}

.status-pendente {
  color: #d97706;
  font-size: 0.8rem;
  font-weight: 600;
}

.doc-actions {
  margin-top: 0.5rem;
  text-align: center;
}

.btn-visualizar {
  background: linear-gradient(135deg, #0ea5e9, #0284c7);
  color: white;
  border: none;
  padding: 0.375rem 0.75rem;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-visualizar:hover {
  background: linear-gradient(135deg, #0284c7, #0369a1);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(14, 165, 233, 0.3);
}

.btn-visualizar.btn-warning {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: white;
}

.btn-visualizar.btn-warning:hover {
  background: linear-gradient(135deg, #d97706, #b45309);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
}

.no-file {
  color: #9ca3af;
  font-size: 0.8rem;
  font-style: italic;
}

.preview-container {
  min-height: 400px;
}

.manual-preview {
  height: 100%;
  overflow-y: auto;
}

.manual-header {
  text-align: center;
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 2px solid #e2e8f0;
}

.manual-header h5 {
  color: #2c3e50;
  font-size: 1.8rem;
  margin-bottom: 0.5rem;
  font-weight: 700;
}

.manual-subtitle {
  color: #718096;
  font-size: 1rem;
  font-style: italic;
}

.manual-nav {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 2rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.nav-btn {
  padding: 0.5rem 1rem;
  border: 1px solid #d1d5db;
  background: white;
  color: #6b7280;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
  transition: all 0.3s ease;
  white-space: nowrap;
}

.nav-btn:hover {
  background: #f3f4f6;
  border-color: #9ca3af;
}

.nav-btn.active {
  background: #2c3e50;
  color: white;
  border-color: #2c3e50;
  font-weight: 600;
}

.manual-section {
  margin-bottom: 2rem;
  padding: 2rem;
  background: white;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.manual-section h6 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
  font-size: 1.4rem;
  font-weight: 700;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #e2e8f0;
}

.subsection {
  margin-bottom: 1.5rem;
}

.subsection h7 {
  display: block;
  color: #374151;
  font-size: 1.1rem;
  font-weight: 600;
  margin: 1.5rem 0 0.75rem 0;
}

.manual-section p {
  color: #4a5568;
  line-height: 1.7;
  margin-bottom: 1rem;
  text-align: justify;
}

.manual-section ul {
  margin: 1rem 0 1rem 1.5rem;
}

.manual-section li {
  color: #4a5568;
  line-height: 1.6;
  margin-bottom: 0.75rem;
}

.manual-section strong {
  color: #2c3e50;
  font-weight: 600;
}

.manual-section em {
  color: #059669;
  font-style: italic;
}

.workflow {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin: 1.5rem 0;
}

.step {
  flex: 1;
  min-width: 120px;
  padding: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 8px;
  text-align: center;
  font-size: 0.9rem;
  font-weight: 500;
  position: relative;
}

.step:not(:last-child)::after {
  content: '→';
  position: absolute;
  right: -0.75rem;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
  font-size: 1.2rem;
  font-weight: bold;
}

.criterios, .categorias, .principios {
  display: grid;
  gap: 1rem;
  margin: 1.5rem 0;
}

.criterio, .categoria, .principio {
  padding: 1rem;
  background: #f0f9ff;
  border-left: 4px solid #0ea5e9;
  border-radius: 6px;
}

.criterio strong, .categoria strong, .principio strong {
  color: #0c4a6e;
}

@media (max-width: 768px) {
  .manual-nav {
    flex-direction: column;
  }
  
  .nav-btn {
    text-align: center;
  }
  
  .workflow {
    flex-direction: column;
  }
  
  .step:not(:last-child)::after {
    display: none;
  }
  
  .criterios, .categorias, .principios {
    grid-template-columns: 1fr;
  }
}

.processo-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 400px;
  text-align: center;
  color: #718096;
}

.placeholder-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
  opacity: 0.5;
}

/* Estilos específicos para o assistente */
.assistente-overlay {
  z-index: 2000;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  overflow: hidden;
}

.assistente-modal {
  width: 95vw;
  height: 95vh;
  max-width: none;
  max-height: none;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

.assistente-header-modal {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  background: #2c3e50;
  color: white;
  border-radius: 12px 12px 0 0;
  flex-shrink: 0;
}

.assistente-header-modal h3 {
  margin: 0;
  color: white;
}

.assistente-content {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  background: #f8fafc;
  border-radius: 0 0 12px 12px;
  position: relative;
  max-height: calc(95vh - 80px);
}

/* Scroll customizado para o assistente */
.assistente-content::-webkit-scrollbar {
  width: 8px;
}

.assistente-content::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 4px;
}

.assistente-content::-webkit-scrollbar-thumb {
  background: #94a3b8;
  border-radius: 4px;
}

.assistente-content::-webkit-scrollbar-thumb:hover {
  background: #64748b;
}

.stats-section {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.stats-section h4 {
  margin-bottom: 1rem;
  color: #2d3748;
  font-size: 1rem;
}

.stats-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  padding: 0.5rem;
  background: #f7fafc;
  border-radius: 4px;
}

.stats-label {
  color: #4a5568;
  font-size: 0.9rem;
}

.stats-value {
  color: #2c3e50;
  font-weight: 600;
}

/* Estilos específicos para a Lei 14.133/2021 */
.lei-preview {
  height: 100%;
  overflow-y: auto;
}

.lei-header {
  text-align: center;
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 2px solid #dc2626;
  background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
  padding: 1.5rem;
  border-radius: 8px;
}

.lei-header h5 {
  color: #dc2626;
  font-size: 1.8rem;
  margin-bottom: 0.5rem;
  font-weight: 700;
}

.lei-subtitle {
  color: #7f1d1d;
  font-size: 1rem;
  font-style: italic;
}

.lei-nav {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 2rem;
  padding: 1rem;
  background: #f3f4f6;
  border-radius: 8px;
  border: 1px solid #d1d5db;
}

.lei-section {
  margin-bottom: 2rem;
  padding: 2rem;
  background: white;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.lei-section h6 {
  color: #dc2626;
  margin-bottom: 1.5rem;
  font-size: 1.4rem;
  font-weight: 700;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid #fecaca;
}

.lei-section h7 {
  display: block;
  color: #374151;
  font-size: 1.1rem;
  font-weight: 600;
  margin: 1.5rem 0 0.75rem 0;
}

.lei-section h8 {
  display: block;
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.comparison {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin: 1.5rem 0;
}

.before, .after {
  padding: 1rem;
  border-radius: 8px;
  text-align: center;
}

.before {
  background: #fef2f2;
  border: 2px solid #fecaca;
}

.before h8 {
  color: #dc2626;
}

.after {
  background: #f0f9ff;
  border: 2px solid #bae6fd;
}

.after h8 {
  color: #0369a1;
}

.modalidades {
  display: grid;
  gap: 1rem;
  margin: 1.5rem 0;
}

.modalidade {
  padding: 1rem;
  background: #f8fafc;
  border-left: 4px solid #0ea5e9;
  border-radius: 6px;
}

.prazos-tabela {
  display: grid;
  gap: 0.75rem;
  margin: 1.5rem 0;
}

.prazo-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #fffbeb;
  border: 1px solid #fed7aa;
  border-radius: 6px;
}

.prazo {
  background: #ea580c;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-weight: 600;
  font-size: 0.9rem;
}

.criterios-lei {
  display: grid;
  gap: 1rem;
  margin: 1.5rem 0;
}

.criterio-lei {
  padding: 1rem;
  background: #fef3c7;
  border-left: 4px solid #f59e0b;
  border-radius: 6px;
}

.criterio-lei strong {
  color: #92400e;
}

@media (max-width: 768px) {
  .lei-nav {
    flex-direction: column;
  }
  
  .comparison {
    grid-template-columns: 1fr;
  }
  
  .prazos-tabela .prazo-item {
    flex-direction: column;
    text-align: center;
    gap: 0.5rem;
  }
}

/* Scrollbar customizada para área de documentos */
.documents-container::-webkit-scrollbar {
  width: 8px;
}

.documents-container::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.documents-container::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 4px;
}

.documents-container::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}

/* Scrollbar customizada para sidebar */
.sidebar::-webkit-scrollbar {
  width: 6px;
}

.sidebar::-webkit-scrollbar-track {
  background: #f8f9fa;
}

.sidebar::-webkit-scrollbar-thumb {
  background: #dee2e6;
  border-radius: 3px;
}

.sidebar::-webkit-scrollbar-thumb:hover {
  background: #ced4da;
}

@media (max-width: 1200px) {
  .document-viewer-container {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .document-details-panel {
    order: 2;
  }
  
  .document-preview-panel {
    order: 1;
  }
}

@media (max-width: 768px) {
  .content-wrapper {
    grid-template-columns: 1fr;
    height: 100vh;
  }
  
  .sidebar {
    display: none;
  }
  
  .documents-container.grid {
    grid-template-columns: 1fr;
  }
  
  .modal-large {
    width: 95%;
    height: 95vh;
  }
  
  .document-title-section {
    flex-direction: column;
    text-align: center;
    gap: 0.5rem;
  }
}

/* Estilos para Workflow Actions */
.workflow-actions {
  margin-top: 1rem;
  padding: 1rem;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.workflow-header {
  margin-bottom: 0.75rem;
  text-align: center;
}

.workflow-label {
  font-size: 0.8rem;
  color: #4a5568;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.workflow-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  justify-content: center;
}

.btn-workflow {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.8rem;
  font-weight: 600;
  white-space: nowrap;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.btn-workflow.aprovacao {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
  box-shadow: 0 2px 4px rgba(16, 185, 129, 0.3);
}

.btn-workflow.aprovacao:hover {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(16, 185, 129, 0.4);
}

.btn-workflow.rejeicao {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  color: white;
  box-shadow: 0 2px 4px rgba(239, 68, 68, 0.3);
}

.btn-workflow.rejeicao:hover {
  background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(239, 68, 68, 0.4);
}

.btn-workflow.submissao {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  box-shadow: 0 2px 4px rgba(59, 130, 246, 0.3);
}

.btn-workflow.submissao:hover {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(59, 130, 246, 0.4);
}

/* Responsividade para workflow actions */
@media (max-width: 768px) {
  .workflow-buttons {
    flex-direction: column;
  }
  
  .btn-workflow {
    width: 100%;
    text-align: center;
  }
}

/* =====================================================
   ESTILOS DOS MODAIS DE ADICIONAR DOCUMENTO E TRAMITAÇÃO
   ===================================================== */

.modal-adicionar-doc,
.modal-tramitacao {
  background: white;
  border-radius: 16px;
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  overflow: hidden;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  display: flex;
  flex-direction: column;
}

.modal-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1.5rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-radius: 16px 16px 0 0;
}

.modal-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
}

.btn-close {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  font-size: 1.5rem;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.3s ease;
}

.btn-close:hover {
  background: rgba(255, 255, 255, 0.3);
}

.modal-body {
  flex: 1;
  overflow-y: auto;
  padding: 0;
}

/* ===== MODAL ADICIONAR DOCUMENTO ===== */
.adicionar-documento-form {
  padding: 2rem;
}

.info-processo {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.info-item strong {
  color: #374151;
  font-size: 0.9rem;
  font-weight: 600;
}

.upload-section {
  background: #ffffff;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 2rem;
  margin-bottom: 2rem;
}

.upload-section h4 {
  color: #374151;
  margin: 0 0 1.5rem 0;
  font-size: 1.1rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.upload-area {
  border: 3px dashed #cbd5e0;
  border-radius: 12px;
  padding: 3rem 2rem;
  text-align: center;
  background: #f8fafc;
  transition: all 0.3s ease;
  cursor: pointer;
}

.upload-area:hover {
  border-color: #667eea;
  background: #f0f4ff;
}

.upload-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.upload-icon {
  font-size: 3rem;
  opacity: 0.7;
}

.upload-content p {
  color: #4a5568;
  font-size: 1.1rem;
  margin: 0;
}

.upload-content small {
  color: #718096;
  font-size: 0.9rem;
}

.btn-upload-doc {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.btn-upload-doc:hover {
  transform: translateY(-2px);
}

.documentos-selecionados {
  margin-top: 2rem;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 12px;
  padding: 1.5rem;
}

.documentos-selecionados h5 {
  color: #0c4a6e;
  margin: 0 0 1rem 0;
  font-weight: 600;
}

.documento-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: white;
  border: 1px solid #e0f2fe;
  border-radius: 8px;
  margin-bottom: 0.5rem;
}

.doc-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.doc-nome {
  font-weight: 500;
  color: #0f172a;
}

.doc-tamanho {
  font-size: 0.8rem;
  color: #64748b;
}

.btn-remover {
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 4px;
  transition: background 0.2s ease;
}

.btn-remover:hover {
  background: #fef2f2;
}

.modal-actions {
  background: #f8fafc;
  padding: 1.5rem 2rem;
  border-top: 1px solid #e2e8f0;
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.btn-primary {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary {
  background: #6b7280;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s ease;
}

.btn-secondary:hover {
  background: #4b5563;
}

/* ===== MODAL TRAMITAÇÃO ===== */
.tramitacao-info {
  padding: 2rem;
}

.processo-info {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f1f5f9;
}

.info-row:last-child {
  border-bottom: none;
}

.info-row .label {
  font-weight: 600;
  color: #374151;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: uppercase;
}

.status-blue {
  background: #dbeafe;
  color: #1e40af;
}

.status-green {
  background: #d1fae5;
  color: #065f46;
}

.status-yellow {
  background: #fef3cd;
  color: #92400e;
}

.status-red {
  background: #fee2e2;
  color: #7f1d1d;
}

.status-gray {
  background: #f3f4f6;
  color: #374151;
}

.historico-container h4 {
  color: #374151;
  margin: 0 0 1.5rem 0;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.sem-historico {
  text-align: center;
  padding: 3rem;
  color: #6b7280;
}

.linha-tempo {
  position: relative;
  padding-left: 2rem;
}

.linha-tempo::before {
  content: '';
  position: absolute;
  left: 0.75rem;
  top: 0;
  bottom: 0;
  width: 2px;
  background: #e5e7eb;
}

.evento-tramitacao {
  position: relative;
  padding: 1.5rem 0;
  margin-left: 1rem;
}

.evento-tramitacao::before {
  content: '';
  position: absolute;
  left: -1.75rem;
  top: 1.75rem;
  width: 12px;
  height: 12px;
  background: #667eea;
  border: 3px solid white;
  border-radius: 50%;
  box-shadow: 0 0 0 3px #e5e7eb;
}

.evento-data {
  font-size: 0.8rem;
  color: #6b7280;
  margin-bottom: 0.5rem;
}

.evento-status {
  margin-bottom: 0.5rem;
}

.evento-descricao {
  color: #374151;
  line-height: 1.5;
  margin-bottom: 0.5rem;
}

.evento-responsavel {
  font-size: 0.8rem;
  color: #6b7280;
  font-style: italic;
}

/* Responsividade */
@media (max-width: 768px) {
  .modal-adicionar-doc,
  .modal-tramitacao {
    width: 95%;
    margin: 1rem;
  }
  
  .modal-header {
    padding: 1rem;
  }
  
  .adicionar-documento-form,
  .tramitacao-info {
    padding: 1rem;
  }
  
  .info-processo {
    grid-template-columns: 1fr;
  }
  
  .upload-area {
    padding: 2rem 1rem;
  }
  
  .modal-actions {
    flex-direction: column;
  }
}

/* ===== MODAL DE CONFIRMAÇÃO DE TRAMITAÇÃO ===== */
.modal-confirmacao-tramitacao {
  background: white;
  border-radius: 16px;
  width: 90%;
  max-width: 600px;
  max-height: 90vh;
  overflow: hidden;
  box-shadow: 0 25px 50px rgba(0, 0, 0, 0.25);
  animation: modalSlideIn 0.3s ease-out;
}

@keyframes modalSlideIn {
  from {
    transform: scale(0.9) translateY(-20px);
    opacity: 0;
  }
  to {
    transform: scale(1) translateY(0);
    opacity: 1;
  }
}

.modal-header-tramitacao {
  display: flex;
  align-items: center;
  padding: 2rem 2rem 1rem 2rem;
  background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
  border-bottom: 3px solid #e2e8f0;
  position: relative;
}

.header-icon {
  margin-right: 1rem;
}

.tramitacao-icon {
  font-size: 3rem;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 20%, 50%, 80%, 100% {
    transform: translateY(0);
  }
  40% {
    transform: translateY(-8px);
  }
  60% {
    transform: translateY(-4px);
  }
}

.header-content {
  flex: 1;
}

.header-content h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.4rem;
  font-weight: 700;
  color: #1a202c;
}

.processo-numero {
  margin: 0;
  font-size: 0.9rem;
  color: #4a5568;
  font-weight: 500;
}

.btn-close-tramitacao {
  background: none;
  border: none;
  font-size: 2rem;
  cursor: pointer;
  color: #a0aec0;
  transition: color 0.3s ease;
  padding: 0.5rem;
  border-radius: 50%;
}

.btn-close-tramitacao:hover {
  color: #e53e3e;
  background: #fed7d7;
}

.modal-body-tramitacao {
  padding: 2rem;
}

.status-flow {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: #f7fafc;
  border-radius: 12px;
  border: 2px solid #e2e8f0;
}

.status-atual, .status-proximo {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.status-label {
  font-size: 0.8rem;
  color: #718096;
  font-weight: 600;
  margin-bottom: 0.5rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.status-badge.atual {
  background: #bee3f8;
  color: #2c5282;
  padding: 0.75rem 1.25rem;
  border-radius: 25px;
  font-weight: 700;
  font-size: 0.85rem;
}

.status-badge.proximo {
  background: #c6f6d5;
  color: #276749;
  padding: 0.75rem 1.25rem;
  border-radius: 25px;
  font-weight: 700;
  font-size: 0.85rem;
}

.flow-arrow {
  font-size: 2rem;
  color: #4299e1;
  font-weight: bold;
  margin: 0 1rem;
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

.observacoes-section {
  margin-bottom: 2rem;
}

.obs-label {
  display: block;
  margin-bottom: 0.75rem;
  font-size: 1rem;
  font-weight: 600;
  color: #2d3748;
}

.obs-textarea {
  width: 100%;
  min-height: 80px;
  padding: 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  font-size: 0.95rem;
  resize: vertical;
  transition: border-color 0.3s ease, box-shadow 0.3s ease;
  font-family: inherit;
}

.obs-textarea:focus {
  outline: none;
  border-color: #4299e1;
  box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
}

.obs-textarea::placeholder {
  color: #a0aec0;
  font-style: italic;
}

.tramitacao-aviso {
  display: flex;
  align-items: flex-start;
  padding: 1.5rem;
  background: #edf2f7;
  border-radius: 12px;
  border-left: 4px solid #4299e1;
  margin-bottom: 2rem;
}

.aviso-icon {
  font-size: 1.5rem;
  margin-right: 1rem;
  color: #4299e1;
  flex-shrink: 0;
}

.aviso-texto {
  flex: 1;
}

.aviso-texto p {
  margin: 0 0 0.75rem 0;
  font-weight: 600;
  color: #2d3748;
}

.aviso-texto ul {
  margin: 0;
  padding-left: 1.25rem;
  color: #4a5568;
}

.aviso-texto li {
  margin-bottom: 0.5rem;
  line-height: 1.5;
}

.modal-footer-tramitacao {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  padding: 1.5rem 2rem 2rem 2rem;
  background: #f8fafc;
  border-top: 2px solid #e2e8f0;
}

.btn-cancelar {
  padding: 0.875rem 1.5rem;
  background: #e2e8f0;
  color: #4a5568;
  border: 2px solid #cbd5e0;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.95rem;
}

.btn-cancelar:hover {
  background: #cbd5e0;
  border-color: #a0aec0;
  transform: translateY(-1px);
}

.btn-confirmar {
  padding: 0.875rem 2rem;
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  color: white;
  border: 2px solid #38a169;
  border-radius: 10px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.95rem;
}

.btn-confirmar:hover:not(:disabled) {
  background: linear-gradient(135deg, #38a169 0%, #2f855a 100%);
  border-color: #2f855a;
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(56, 161, 105, 0.3);
}

.btn-confirmar:disabled {
  background: #a0aec0;
  border-color: #a0aec0;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* Responsividade para o modal */
@media (max-width: 768px) {
  .modal-confirmacao-tramitacao {
    width: 95%;
    margin: 1rem;
  }
  
  .modal-header-tramitacao {
    padding: 1.5rem;
    flex-direction: column;
    text-align: center;
  }
  
  .header-icon {
    margin-right: 0;
    margin-bottom: 1rem;
  }
  
  .status-flow {
    flex-direction: column;
    gap: 1rem;
  }
  
  .flow-arrow {
    transform: rotate(90deg);
    margin: 0.5rem 0;
  }
  
  .modal-footer-tramitacao {
    flex-direction: column;
  }
  
  .btn-cancelar, .btn-confirmar {
    width: 100%;
  }
}

/* ===================================== */
/* MODAL DE DEVOLUÇÃO */
/* ===================================== */

.modal-devolucao {
  background: white;
  border-radius: 16px;
  width: 600px;
  max-width: 90vw;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  position: relative;
  z-index: 1001;
  animation: slideInUp 0.3s ease-out;
}

.modal-header-devolucao {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: white;
  padding: 1.5rem;
  border-radius: 16px 16px 0 0;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.devolucao-icon {
  font-size: 2rem;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
}

.modal-body-devolucao {
  padding: 1.5rem;
}

.motivo-section, .observacoes-section {
  margin-bottom: 1.5rem;
}

.field-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: #374151;
  margin-bottom: 0.5rem;
}

.label-icon {
  font-size: 1.1rem;
}

.motivo-textarea, .observacoes-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  font-family: inherit;
  font-size: 0.9rem;
  line-height: 1.5;
  resize: vertical;
  transition: border-color 0.2s;
}

.motivo-textarea:focus, .observacoes-textarea:focus {
  outline: none;
  border-color: #f59e0b;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}

.motivo-textarea {
  border-color: #f59e0b;
  background: #fffbeb;
}

.modal-footer-devolucao {
  display: flex;
  gap: 1rem;
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
  justify-content: flex-end;
}

.btn-cancel {
  padding: 0.75rem 1.5rem;
  border: 2px solid #6b7280;
  background: white;
  color: #6b7280;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel:hover {
  background: #f3f4f6;
  border-color: #4b5563;
  color: #4b5563;
}

.btn-confirm-devolucao {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  min-width: 180px;
}

.btn-confirm-devolucao:hover:not(:disabled) {
  background: linear-gradient(135deg, #d97706 0%, #b45309 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
}

.btn-confirm-devolucao:disabled {
  background: #9ca3af;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* ===================================== */
/* SEÇÃO DE DEVOLUÇÃO */
/* ===================================== */

.devolucao-info {
  margin: 1.5rem 0;
  padding: 1rem;
  background: #fef3c7;
  border: 2px solid #f59e0b;
  border-radius: 12px;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% {
    border-color: #f59e0b;
  }
  50% {
    border-color: #d97706;
  }
}

.devolucao-container {
  margin-top: 0.75rem;
}

.devolucao-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding: 0.5rem;
  background: #fed7aa;
  border-radius: 8px;
}

.devolucao-status {
  font-weight: 600;
  color: #ea580c;
  font-size: 0.9rem;
}

.devolucao-data {
  font-size: 0.8rem;
  color: #9a3412;
  font-style: italic;
}

.motivo-devolucao, .observacoes-devolucao {
  margin-bottom: 1rem;
  padding: 0.75rem;
  background: white;
  border-radius: 8px;
  border-left: 4px solid #f59e0b;
}

.motivo-devolucao h5, .observacoes-devolucao h5 {
  margin: 0 0 0.5rem 0;
  font-size: 0.9rem;
  color: #92400e;
  font-weight: 600;
}

.motivo-texto, .observacoes-texto {
  margin: 0;
  padding: 0.5rem;
  background: #fffbeb;
  border-radius: 6px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: #451a03;
  border: 1px solid #fbbf24;
}

.acao-requerida {
  padding: 0.75rem;
  background: #ecfdf5;
  border: 1px solid #10b981;
  border-radius: 8px;
  margin-top: 1rem;
}

.acao-requerida p {
  margin: 0;
  font-size: 0.9rem;
  color: #047857;
}

.acao-requerida strong {
  color: #065f46;
}

/* Estilos para mensagem informativa do órgão administrativo */
.info-orgao-admin {
  margin: 1rem 0;
}

.alert {
  padding: 0.75rem 1rem;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
}

.alert-info {
  background-color: #e0f2fe;
  border: 1px solid #0288d1;
  color: #01579b;
}

.alert span {
  font-size: 1rem;
  opacity: 0.8;
}

</style>