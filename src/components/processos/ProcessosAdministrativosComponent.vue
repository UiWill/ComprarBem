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
              <button @click.stop="visualizarDocumentacao(processo)" class="btn-action">
                📋 Docs
              </button>
              <button @click.stop="gerarRelatorio(processo)" class="btn-action">
                📄 PDF
              </button>
            </div>
            
            <!-- Ações de Workflow baseadas no perfil do usuário -->
            <div v-if="obterAcoesProcesso(processo).length > 0" class="workflow-actions">
              <div class="workflow-header">
                <span class="workflow-label">🔄 Ações Disponíveis</span>
              </div>
              <div class="workflow-buttons">
                <button 
                  v-for="acao in obterAcoesProcesso(processo)" 
                  :key="acao"
                  @click.stop="executarAcaoWorkflow(processo, acao)"
                  class="btn-workflow"
                  :class="{ 
                    'aprovacao': acao.includes('aprovar') || acao.includes('homologar') || acao.includes('assinar'),
                    'rejeicao': acao.includes('rejeitar'),
                    'submissao': acao.includes('submeter')
                  }"
                >
                  {{ obterLabelAcao(acao) }}
                </button>
              </div>
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
                <button @click="gerarRelatorio(processoSelecionado)" class="btn-primary btn-large">
                  📄 Gerar Relatório PDF
                </button>
                
                <!-- Botão para enviar para análise administrativa -->
                <button 
                  v-if="podeEnviarParaAnalise(processoSelecionado)" 
                  @click="enviarParaAnaliseAdministrativa(processoSelecionado)" 
                  class="btn-success btn-large"
                >
                  🚀 Enviar para Análise Administrativa
                </button>
                
                <button @click="adicionarDocumento(processoSelecionado)" class="btn-secondary">
                  📎 Adicionar Documento
                </button>
                <button 
                  v-if="podeEditarProcesso(processoSelecionado)" 
                  @click="editarProcesso(processoSelecionado)" 
                  class="btn-secondary">
                  ✏️ Editar Processo
                </button>
                <button @click="verTramitacao(processoSelecionado)" class="btn-secondary">
                  📋 Ver Tramitação
                </button>
              </div>
            </div>
            
            <div class="processo-content-panel">
              <h4>🎯 Objeto do Processo</h4>
              <div class="objeto-container">
                <p class="objeto-texto">{{ processoSelecionado.objeto }}</p>
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
                    <div class="doc-numero">Fl. {{ String(doc.numero_folha).padStart(3, '0') }}</div>
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
                      <button v-if="doc.url_arquivo" @click="visualizarDocumento(doc)" class="btn-visualizar">
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
    </div>
    
  </div>
</template>

<script>
import ProcessosAdministrativosService from '../../services/processosAdministrativosService'
import DocumentosAdministrativosService from '../../services/documentosAdministrativos'
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
      
      // Modais
      mostrarAssistente: false,
      mostrarModalEdital: false,
      mostrarDocumentacao: false,
      processoSelecionado: null,
      
      // Edição
      modoEdicao: false,
      processoParaEditar: null,
      
      // Dados auxiliares para visualização detalhada
      produtosProcesso: [],
      historicoTramitacao: [],
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
        documentos: this.documentosProcesso?.length || 0,
        produtos: this.produtosProcesso?.length || 0
      })
      
      // Status permitidos (considerando maiúsculo e minúsculo)
      const statusPermitidos = ['rascunho', 'RASCUNHO', 'aguardando_aprovacao', 'AGUARDANDO_APROVACAO']
      const statusProcesso = processo?.status?.toLowerCase() || ''
      const podeEnviar = ['rascunho', 'aguardando_aprovacao'].includes(statusProcesso)
      
      console.log('🎯 Resultado:', podeEnviar ? '✅ MOSTRAR BOTÃO' : '❌ OCULTAR BOTÃO')
      
      return podeEnviar
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
              margin-bottom: 2cm;
              border-bottom: 2px solid #000;
              padding-bottom: 1cm;
            }
            
            .documento-header h1 {
              font-family: 'Times New Roman', serif;
              font-size: 16pt;
              font-weight: bold;
              margin: 10px 0;
              color: #000;
            }
            
            .documento-header h2 {
              font-family: 'Times New Roman', serif;
              font-size: 14pt;
              font-weight: bold;
              margin: 5px 0;
              color: #000;
            }
            
            .documento-conteudo {
              font-family: 'Times New Roman', serif;
              font-size: 12pt;
              line-height: 1.6;
              text-align: justify;
              color: #000;
            }
            
            .documento-conteudo h1,
            .documento-conteudo h2,
            .documento-conteudo h3 {
              font-family: 'Times New Roman', serif;
              font-weight: bold;
              color: #000;
              margin: 1cm 0 0.5cm 0;
            }
            
            .documento-conteudo h1 { font-size: 16pt; }
            .documento-conteudo h2 { font-size: 14pt; }
            .documento-conteudo h3 { font-size: 12pt; }
            
            .documento-conteudo p {
              font-family: 'Times New Roman', serif;
              font-size: 12pt;
              line-height: 1.6;
              margin-bottom: 1cm;
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
            }
            
            .tabela th, .tabela td {
              border: 1px solid #333;
              padding: 8px;
              text-align: left;
              vertical-align: top;
            }
            
            .tabela th {
              background-color: #f5f5f5;
              font-weight: bold;
              text-align: center;
            }
            
            .assinatura {
              margin-top: 3cm;
              text-align: center;
            }
            
            .linha-assinatura {
              border-top: 1px solid #000;
              width: 300px;
              margin: 2cm auto 0.5cm auto;
            }
            
            @media print {
              .documento-pagina {
                box-shadow: none;
                margin: 0;
                padding: 0;
              }
              
              .page-break {
                page-break-before: always;
              }
            }
          </style>
        </head>
        <body>
          <!-- DOCUMENTOS DO PROCESSO -->
          ${documentos.map((doc, index) => `
            ${index > 0 ? '<div class="page-break"></div>' : ''}
            <div class="documento-pagina">
              <div class="folha-numero">Fl. ${String(doc.numero_folha).padStart(3, '0')}</div>
              
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
                  ${documentos.map(doc => `
                    <tr>
                      <td style="text-align: center; font-weight: bold;">Fl. ${String(doc.numero_folha).padStart(3, '0')}</td>
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
                <p><strong>Total de documentos:</strong> ${documentos.length} | <strong>Com arquivos:</strong> ${documentos.filter(d => d.arquivo_url).length}</p>
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
      
      // Verificar se existe Folha de Rosto
      const temFolhaRosto = documentosExistentes.find(doc => doc.tipo_documento === 'FOLHA_ROSTO' || doc.tipo_documento === 'folha_rosto')
      if (!temFolhaRosto) {
        const folhaRosto = {
          numero_folha: 1,
          tipo_documento: 'FOLHA_ROSTO',
          nome_documento: 'Folha de Rosto do Processo Administrativo',
          titulo: 'Folha de Rosto',
          descricao: 'Folha de rosto do processo administrativo',
          data_autuacao: processo.data_autuacao || processo.created_at,
          conteudo_html: this.gerarHTMLFolhaRosto(processo)
        }
        documentosCompletos.unshift(folhaRosto)
      } else {
        // Garantir que folha de rosto seja sempre número 1
        const folhaRosto = documentosCompletos.find(doc => doc.tipo_documento === 'FOLHA_ROSTO' || doc.tipo_documento === 'folha_rosto')
        if (folhaRosto) folhaRosto.numero_folha = 1
      }
      
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
      
      // Buscar e incluir documentos dos produtos se existirem
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
                const temDocumento = documentosCompletos.find(d => 
                  d.nome_documento === `${produto.nome} - ${doc.nome}` ||
                  d.arquivo_url === doc.url
                )
                
                if (!temDocumento) {
                  const documentoProduto = {
                    numero_folha: null, // Será numerado depois
                    tipo_documento: 'DOCUMENTO_PRODUTO',
                    nome_documento: `${produto.nome} - ${doc.nome}`,
                    titulo: `Documentação: ${produto.nome}`,
                    descricao: `Documento do produto: ${doc.nome}`,
                    data_autuacao: produto.created_at || new Date(),
                    arquivo_url: doc.url,
                    conteudo_html: `
                      <div class="documento-header">
                        <h1>${processo.nome_orgao}</h1>
                        <h2>DOCUMENTAÇÃO DE PRODUTO</h2>
                        <p>Processo nº ${processo.numero_processo}</p>
                      </div>
                      
                      <div class="documento-conteudo">
                        <h3>DADOS DO PRODUTO</h3>
                        
                        <p><strong>Nome do Produto:</strong> ${produto.nome}</p>
                        <p><strong>Marca:</strong> ${produto.marca || 'N/A'}</p>
                        <p><strong>Modelo:</strong> ${produto.modelo || 'N/A'}</p>
                        <p><strong>Categoria:</strong> ${produto.categoria || produto.categoria_nome || 'N/A'}</p>
                        <p><strong>Fabricante:</strong> ${produto.fabricante || 'N/A'}</p>
                        
                        <h3>ESPECIFICAÇÕES TÉCNICAS</h3>
                        ${produto.especificacoes ? `<div style="margin-left: 1cm; background: #f9f9f9; padding: 1cm; border: 1px solid #ddd;">${produto.especificacoes}</div>` : '<p style="font-style: italic; color: #666;">Especificações não informadas</p>'}
                        
                        <h3>DOCUMENTO ANEXO</h3>
                        <p><strong>Tipo de Documento:</strong> ${doc.nome}</p>
                        <p><strong>Descrição:</strong> Documento técnico do produto anexado ao processo</p>
                        
                        <p style="margin-top: 2cm;"><strong>Arquivo:</strong> 
                          <a href="${doc.url}" target="_blank" style="color: #1976d2; text-decoration: underline; font-weight: bold;">
                            ${doc.url}
                          </a>
                        </p>
                        
                        ${produto.observacoes ? `
                        <h3>OBSERVAÇÕES</h3>
                        <p style="margin-left: 1cm; font-style: italic; text-align: justify;">
                          ${produto.observacoes}
                        </p>
                        ` : ''}
                        
                        <h3>AVALIAÇÃO TÉCNICA</h3>
                        <p><strong>Status:</strong> ${produto.status_avaliacao || 'Pendente de avaliação'}</p>
                        <p><strong>Data de Inclusão:</strong> ${this.formatarData(produto.created_at)}</p>
                        
                        <div style="margin-top: 2cm; padding: 1cm; border: 2px solid #000; text-align: center;">
                          <p><strong>DECLARAÇÃO DE CONFORMIDADE</strong></p>
                          <p style="text-align: justify; margin-top: 1cm;">
                            Declaro que o produto acima especificado atende aos requisitos técnicos estabelecidos 
                            no Edital de Pré-qualificação, estando em conformidade com as normas aplicáveis 
                            e possuindo os padrões mínimos de qualidade exigidos para inclusão no Catálogo 
                            Eletrônico de Bens Padronizados.
                          </p>
                          
                          <div class="assinatura">
                            <div class="linha-assinatura"></div>
                            <p>Responsável Técnico</p>
                          </div>
                        </div>
                      </div>
                    `
                  }
                  documentosCompletos.push(documentoProduto)
                }
              }
            }
          } catch (error) {
            console.log('Erro ao buscar documentos do produto:', produto.id, error)
          }
        }
      }
      
      // Renumerar documentos seguindo Instrução Processual
      let proximoNumero
      if (processo.tipo_processo === 'padronizacao') {
        // PADRONIZAÇÃO: Fl. 001 (Folha Rosto), Fl. 002 (DFD), Fl. 003 (Edital), Fl. 004+ (demais)
        proximoNumero = 4
      } else {
        // DESPADRONIZAÇÃO: Fl. 001 (Folha Rosto), Fl. 002 (DFD), Fl. 003+ (demais) - SEM EDITAL
        proximoNumero = 3
      }
      
      documentosCompletos.forEach(doc => {
        if (!doc.numero_folha) {
          doc.numero_folha = proximoNumero++
        }
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
        <div class="documento-header" style="text-align: center; margin-bottom: 2cm;">
          <h1 style="font-size: 16pt; font-weight: bold; margin: 10px 0;">${tituloCompleto}</h1>
          <h2 style="font-size: 12pt; margin: 10px 0;">(${finalidade})</h2>
        </div>
        
        <div class="documento-conteudo" style="text-align: justify; line-height: 1.8; font-size: 12pt;">
          <div class="campo" style="margin-bottom: 1cm;">
            <span style="font-weight: bold;">Demandante:</span> Comissão Permanente de Padronização de Materiais - CPPM
          </div>
          
          <div class="campo" style="margin-bottom: 1cm;">
            <span style="font-weight: bold;">Presidente:</span> ${dadosDFD?.nome_presidente || '_________________________________'}
            <span style="font-weight: bold; margin-left: 2cm;">Matrícula:</span> ${dadosDFD?.matricula_presidente || '_________________'}
          </div>
          
          <div class="campo" style="margin-bottom: 1cm;">
            <span style="font-weight: bold;">E-mail:</span> ${dadosDFD?.email_presidente || '________________________'}
            <span style="font-weight: bold; margin-left: 2cm;">Telefone:</span> ${dadosDFD?.telefone_presidente || '_________________'}
          </div>
          
          <h2 style="margin-top: 2cm; font-size: 14pt;">1. OBJETO DESTE DFD:</h2>
          <p>${finalidade.charAt(0).toUpperCase() + finalidade.slice(1)} que ${processo.tipo_processo === 'padronizacao' ? 'possuam os padrões mínimos de qualidade' : 'não mais atendem aos padrões mínimos de qualidade'}, estética, rendimento, durabilidade e adequação ao uso.</p>`

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
          
          <div class="assinatura" style="margin-top: 3cm; text-align: center;">
            <div class="linha-assinatura" style="border-top: 1px solid #000; width: 300px; margin: 2cm auto 0.5cm auto;"></div>
            <p><strong>${dadosDFD?.nome_presidente || 'Nome do Presidente da CPPM'}</strong></p>
            <p>Presidente da Comissão Permanente de Padronização de Materiais - CPPM</p>
            <p>Matrícula: ${dadosDFD?.matricula_presidente || '[não informada]'}</p>
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
      this.mostrarAssistente = true
      // Prevenir scroll da página de fundo
      document.body.style.overflow = 'hidden'
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
      console.log('Editar processo:', processo)
      
      // Verificar se o processo pode ser editado
      if (!this.podeEditarProcesso(processo)) {
        alert('Apenas processos em criação podem ser editados. Depois de criados, é possível apenas adicionar documentos.')
        return
      }
      
      // Abrir o assistente em modo de edição
      this.modoEdicao = true
      this.processoParaEditar = processo
      this.mostrarAssistente = true
    },
    
    async gerarRelatorio(processo) {
      try {
        console.log('Gerando relatório PDF para processo:', processo.id)
        
        // Buscar dados completos do processo
        const processoCompleto = await ProcessosAdministrativosService.obterProcesso(processo.id)
        
        // Buscar todos os documentos com conteúdo HTML
        let documentos = await ProcessosAdministrativosService.listarDocumentosProcesso(processo.id)
        
        // Buscar produtos
        let produtos = []
        if (processoCompleto.tipo_processo === 'padronizacao') {
          produtos = await ProcessosAdministrativosService.listarProdutosProcesso(processo.id)
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
        } catch (error) {
          console.log('DFD não encontrado para o processo')
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
        
        // Criar blob e abrir em nova janela
        const blob = new Blob([htmlRelatorio], { type: 'text/html' })
        const url = URL.createObjectURL(blob)
        const novaJanela = window.open(url, '_blank')
        
        // Aguardar carregar
        setTimeout(() => {
          URL.revokeObjectURL(url)
        }, 5000)
        
      } catch (error) {
        console.error('Erro ao gerar relatório:', error)
        alert(`Erro ao gerar relatório: ${error.message}`)
      }
    },
    
    async enviarParaAnaliseAdministrativa(processo) {
      try {
        const confirmacao = confirm(
          `🚀 ENVIAR PARA ANÁLISE ADMINISTRATIVA\n\n` +
          `Tem certeza que deseja enviar o processo "${processo.numero_processo}" para análise administrativa?\n\n` +
          `Após o envio, o processo não poderá mais ser editado até retornar para revisão.`
        )
        
        if (!confirmacao) return
        
        console.log('Enviando processo para análise administrativa:', processo.id)
        
        // Atualizar status do processo
        await ProcessosAdministrativosService.tramitarProcesso(
          processo.id, 
          'analise_administrativa',
          'Processo enviado para análise administrativa'
        )
        
        // Atualizar na lista local
        const index = this.processos.findIndex(p => p.id === processo.id)
        if (index !== -1) {
          this.processos[index].status = 'analise_administrativa'
        }
        
        // Atualizar processo selecionado se necessário
        if (this.processoSelecionado && this.processoSelecionado.id === processo.id) {
          this.processoSelecionado.status = 'analise_administrativa'
        }
        
        alert('✅ Processo enviado para análise administrativa com sucesso!')
        
        // Recarregar dados
        await this.carregarProcessos()
        
      } catch (error) {
        console.error('Erro ao enviar processo para análise:', error)
        alert(`❌ Erro ao enviar processo para análise: ${error.message}`)
      }
    },
    
    adicionarDocumento(processo) {
      // TODO: Implementar adição de documento
      console.log('Adicionar documento:', processo)
      alert('Funcionalidade de adição de documento em desenvolvimento')
    },
    
    verTramitacao(processo) {
      // TODO: Implementar visualização de tramitação
      console.log('Ver tramitação:', processo)
      alert('Funcionalidade de tramitação em desenvolvimento')
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
    
    // =====================================================
    // GESTÃO DE FLUXO - AÇÕES DE WORKFLOW
    // =====================================================
    
    obterAcoesProcesso(processo) {
      if (!this.perfilUsuario) return []
      return ProcessosAdministrativosService.obterAcoesDisponiveis(processo.status, this.perfilUsuario)
    },
    
    async executarAcaoWorkflow(processo, acao) {
      try {
        const observacoes = prompt(`Observações para ${acao}:`) || ''
        
        let resultado
        
        switch (acao) {
          case 'submeter_analise':
            resultado = await ProcessosAdministrativosService.submeterParaAnalise(processo.id, observacoes)
            break
          case 'aprovar_cpm':
            resultado = await ProcessosAdministrativosService.aprovarCPM(processo.id, observacoes)
            break
          case 'rejeitar_cpm':
            resultado = await ProcessosAdministrativosService.rejeitarCPM(processo.id, observacoes)
            break
          case 'assinar_admin':
            resultado = await ProcessosAdministrativosService.assinarAdministrativo(processo.id, observacoes)
            break
          case 'rejeitar_admin':
            resultado = await ProcessosAdministrativosService.rejeitarAdministrativo(processo.id, observacoes)
            break
          case 'enviar_ccl':
            resultado = await ProcessosAdministrativosService.enviarParaCCL(processo.id, observacoes)
            break
          case 'aprovar_ccl':
            resultado = await ProcessosAdministrativosService.aprovarCCL(processo.id, observacoes)
            break
          case 'rejeitar_ccl':
            resultado = await ProcessosAdministrativosService.rejeitarCCL(processo.id, observacoes)
            break
          case 'aprovar_juridico':
            resultado = await ProcessosAdministrativosService.aprovarJuridico(processo.id, observacoes)
            break
          case 'rejeitar_juridico':
            resultado = await ProcessosAdministrativosService.rejeitarJuridico(processo.id, observacoes)
            break
          case 'homologar':
            resultado = await ProcessosAdministrativosService.homologarProcesso(processo.id, observacoes)
            break
          case 'rejeitar_final':
            resultado = await ProcessosAdministrativosService.rejeitarFinal(processo.id, observacoes)
            break
          default:
            throw new Error(`Ação não reconhecida: ${acao}`)
        }
        
        if (resultado) {
          alert(`Ação executada com sucesso! Processo agora está: ${resultado.processo.status}`)
          await this.carregarProcessos()
          
          // Se há processo selecionado, atualizar
          if (this.processoSelecionado && this.processoSelecionado.id === processo.id) {
            this.processoSelecionado = resultado.processo
          }
        }
      } catch (error) {
        console.error('Erro ao executar ação:', error)
        alert(`Erro ao executar ação: ${error.message}`)
      }
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
      if (documento.url_arquivo) {
        // Abrir documento em nova aba
        window.open(documento.url_arquivo, '_blank')
      } else {
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

.btn-large {
  width: 100%;
  padding: 1rem;
  font-size: 1rem;
  margin-bottom: 0.75rem;
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
</style>