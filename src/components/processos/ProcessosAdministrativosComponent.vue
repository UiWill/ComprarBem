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
              
              <!-- STATUS PADRONIZAÇÃO (VERDE) - Sequência lógica conforme cliente -->
              <optgroup label="🟢 PADRONIZAÇÃO">
                <option value="em_criacao">📝 Em Criação</option>
                <option value="criado_cpm">🎯 Criado pela CPM</option>
                <option value="submetido_autoridade">📋 Submetido à Autoridade Competente</option>
                <option value="abertura_autorizada">✅ Abertura Autorizada</option>
                <option value="edital_chamamento">📢 Edital de Chamamento Público</option>
                <option value="analise_juridica">⚖️ Em Análise Jurídica</option>
                <option value="edital_publicado">📃 Com Edital Publicado</option>
                <option value="com_impugnacao">❓ Com Impugnação ao Edital</option>
                <option value="recebendo_amostras">📦 Recebendo Amostras e Documentação</option>
                <option value="avaliacao_cpm">🔍 Com Avaliação e Relatório da CPM</option>
                <option value="julgamento_ccl">⚖️ Submetido ao Julgamento da CCL</option>
                <option value="ata_ccl">📋 Ata de Julgamento da CCL</option>
                <option value="publicacao_ata">📰 Publicação da Ata e Prazo Recursal</option>
                <option value="com_recurso">📝 Com Recurso Administrativo</option>
                <option value="homologado">✅ Com Homologação</option>
                <option value="expedindo_dcbs">📄 Expedindo as DCBs</option>
                <option value="incluindo_marcas">➕ Incluindo Marcas no Catálogo</option>
              </optgroup>
              
              <!-- STATUS DESPADRONIZAÇÃO (VERMELHO) - Sequência lógica conforme cliente -->
              <optgroup label="🔴 DESPADRONIZAÇÃO">
                <option value="em_criacao_desp">📝 Em Criação</option>
                <option value="criado_cpm_desp">🎯 Criado pela CPM</option>
                <option value="submetido_autoridade_desp">📋 Submetido à Autoridade Competente</option>
                <option value="abertura_autorizada_desp">✅ Abertura Autorizada</option>
                <option value="aviso_publicado_desp">📢 Com Aviso Publicado</option>
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
              
              <!-- Lembrete para tramitar para CCL quando assinado_admin (apenas para perfil administrativo) -->
              <div v-if="processo.status === 'assinado_admin' && perfilUsuario?.toLowerCase() === 'orgao_administrativo'" class="tramitar-reminder">
                <div class="reminder-icon">⚖️</div>
                <div class="reminder-text">
                  <strong>Pronto para CCL!</strong><br>
                  <small>Clique em "Ver" → "Tramitar para CCL"</small>
                </div>
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
                    <span class="btn-text">Enviar para Análise/Aprovação</span>
                  </button>
                  
                  <!-- Botão Universal de Assinatura Digital -->
                  <button
                    v-if="podeUsuarioAssinar(processoSelecionado)"
                    @click="assinarProcesso(processoSelecionado)"
                    class="action-btn action-btn-signature"
                  >
                    <span class="btn-icon">✍️</span>
                    <span class="btn-text">Assinar Digitalmente</span>
                  </button>

                  <!-- Botão para Vincular Edital -->
                  <button
                    v-if="podeVincularEdital(processoSelecionado)"
                    @click="abrirModalVincularEdital(processoSelecionado)"
                    class="action-btn action-btn-edital"
                  >
                    <span class="btn-icon">📋</span>
                    <span class="btn-text">Vincular Edital</span>
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
                  
                  <!-- Botões de Tramitação Geral -->
                  <button 
                    v-if="temAcaoTramitacaoEnviar(processoSelecionado) && !podeEnviarParaAnalise(processoSelecionado)" 
                    @click="enviarParaProximaEtapa(processoSelecionado)" 
                    class="action-btn action-btn-success"
                  >
                    <span class="btn-icon">🚀</span>
                    <span class="btn-text">Enviar para Próxima Etapa</span>
                  </button>
                  
                  <button 
                    v-if="temAcaoTramitacaoDevolver(processoSelecionado)" 
                    @click="abrirModalDevolucaoGenerica(processoSelecionado)" 
                    class="action-btn action-btn-warning"
                  >
                    <span class="btn-icon">↩️</span>
                    <span class="btn-text">Devolver para Correção</span>
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
                  
                  <button 
                    v-if="podeAdicionarDoc" 
                    @click="adicionarDocumento(processoSelecionado)" 
                    class="action-btn action-btn-secondary">
                    <span class="btn-icon">📎</span>
                    <span class="btn-text">{{ obterTextoAdicionarDocumento() }}</span>
                  </button>
                  
                  <div 
                    v-else
                    class="action-info"
                    style="padding: 8px 12px; background: #f5f5f5; border-radius: 6px; color: #666; font-size: 0.9em; margin: 4px 0;">
                    <span class="btn-icon" style="opacity: 0.5;">📎</span>
                    <span>{{ obterMensagemNaoPodeAdicionarDoc() }}</span>
                  </div>
                  
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
                  
                  <!-- Botão para gerar documento de assinatura -->
                  <div class="gerar-assinatura-section">
                    <h5>📝 Documento de Assinatura</h5>
                    <p>Precisa do modelo de documento para assinar? Gere o documento padrão:</p>
                    <button 
                      @click="gerarDocumentoAssinaturaParaDownload(processoSelecionado)" 
                      class="btn-gerar-assinatura"
                      type="button"
                    >
                      🖊️ Gerar Documento de Assinatura
                    </button>
                    <small>Este documento contém os campos obrigatórios para sua assinatura.</small>
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
    
    <!-- Modal de Assinatura Digital -->
    <div v-if="mostrarModalAssinatura" class="modal-overlay" @click="fecharModalAssinatura">
      <div class="modal-assinatura-digital" @click.stop>
        <div class="modal-header-assinatura">
          <div class="header-icon">
            <span class="assinatura-icon">✍️</span>
          </div>
          <div class="header-content">
            <h3>Assinatura Digital do Documento</h3>
            <p class="processo-numero">Processo: {{ dadosAssinatura.numeroProcesso }}</p>
          </div>
          <button @click="fecharModalAssinatura" class="btn-close-assinatura">&times;</button>
        </div>
        
        <div class="modal-body-assinatura">
          <div class="assinatura-info">
            <div class="documento-info">
              <h4>📄 Documento a ser assinado</h4>
              <p>{{ dadosAssinatura.tipoDocumento }}</p>
              <p class="status-info">{{ dadosAssinatura.statusAtual }} → {{ dadosAssinatura.proximoStatus }}</p>
            </div>
            
            <div class="signatario-section">
              <label for="nomeSignatario" class="signatario-label">
                👤 Nome do Signatário
              </label>
              <input 
                id="nomeSignatario"
                v-model="dadosAssinatura.nomeSignatario"
                type="text"
                class="signatario-input"
                placeholder="Digite seu nome completo"
                :disabled="processandoAssinatura"
              />
            </div>
            
            <div class="cargo-section">
              <label for="cargoSignatario" class="cargo-label">
                🏢 Cargo/Função
              </label>
              <input 
                id="cargoSignatario"
                v-model="dadosAssinatura.cargoSignatario"
                type="text"
                class="cargo-input"
                placeholder="Ex: Procurador do Estado, Advogado Autárquico"
                :disabled="processandoAssinatura"
              />
            </div>
            
            
            <div class="assinatura-aviso">
              <div class="aviso-icon">⚠️</div>
              <div class="aviso-texto">
                <p><strong>Importante:</strong></p>
                <ul>
                  <li>Esta assinatura será incorporada permanentemente ao documento PDF</li>
                  <li>A data e hora da assinatura serão registradas automaticamente</li>
                  <li>A assinatura digital terá validade jurídica conforme legislação vigente</li>
                  <li>Após assinar, o processo seguirá para a próxima etapa</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
        
        <div class="modal-footer-assinatura">
          <button 
            @click="fecharModalAssinatura" 
            class="btn-cancelar"
            :disabled="processandoAssinatura"
          >
            ❌ Cancelar
          </button>
          <button 
            @click="confirmarAssinatura" 
            class="btn-assinar"
            :disabled="processandoAssinatura || !dadosAssinatura.nomeSignatario || !dadosAssinatura.cargoSignatario"
          >
            <span v-if="!processandoAssinatura">
              ✍️ Assinar Documento
            </span>
            <span v-else>
              ⏳ Processando Assinatura...
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

    <!-- Modal para Vincular Editais Selecionados -->
    <div v-if="mostrarModalVincularEditaisSelecionados" class="modal-overlay" @click="fecharModalVincularEditais">
      <div class="modal-vincular-editais" @click.stop>
        <div class="modal-header">
          <h3>📋 Vincular Editais ao Processo</h3>
          <button @click="fecharModalVincularEditais" class="btn-close">&times;</button>
        </div>

        <div class="modal-body">
          <div class="processo-info">
            <h4>{{ processoSelecionado?.numero_processo || 'Processo em edição' }}</h4>
            <p>{{ processoSelecionado?.tipo_processo === 'padronizacao' ? '✅ Padronização' : '❌ Despadronização' }}</p>
          </div>

          <div v-if="carregandoEditais" class="loading-editais">
            <div class="loading-spinner"></div>
            <p>Carregando editais publicados...</p>
          </div>

          <div v-else>
            <div class="editais-info">
              <p><strong>📋 {{ editaisDisponiveis.length }}</strong> editais publicados disponíveis</p>
              <p v-if="editaisSelecionados.length > 0"><strong>✅ {{ editaisSelecionados.length }}</strong> editais selecionados</p>
            </div>

            <div v-if="editaisDisponiveis.length === 0" class="sem-editais">
              <div class="sem-editais-icon">📋</div>
              <h4>Nenhum edital publicado encontrado</h4>
              <p>Não há editais com status "PUBLICADO" disponíveis para vinculação.</p>
            </div>

            <div v-else class="editais-lista">
              <div v-for="edital in editaisDisponiveis" :key="edital.id" class="edital-item">
                <div class="edital-checkbox">
                  <input
                    type="checkbox"
                    :id="`edital-${edital.id}`"
                    :value="edital.id"
                    v-model="editaisSelecionados"
                    class="checkbox-edital"
                  >
                  <label :for="`edital-${edital.id}`" class="checkbox-label"></label>
                </div>

                <div class="edital-content">
                  <div class="edital-header">
                    <h4>{{ edital.numero }}</h4>
                    <span class="edital-status">📋 Publicado</span>
                  </div>

                  <div class="edital-info">
                    <p><strong>Descrição:</strong> {{ edital.descricao || 'Sem descrição' }}</p>
                    <p><strong>Data de Publicação:</strong> {{ formatarData(edital.data_publicacao) }}</p>
                    <p v-if="edital.pdf_convertido_url || edital.url_documento">
                      <strong>📄 Arquivo:</strong>
                      <span class="arquivo-disponivel">PDF disponível</span>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="fecharModalVincularEditais" class="btn-secondary">
            Cancelar
          </button>
          <button
            @click="confirmarVinculacaoEditais"
            class="btn-primary"
            :disabled="editaisSelecionados.length === 0 || carregandoEditais"
          >
            Vincular {{ editaisSelecionados.length }} Edital{{ editaisSelecionados.length !== 1 ? 's' : '' }}
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
      podeAdicionarDoc: false, // Permissão para adicionar documento ao processo selecionado
      
      // Modais
      mostrarAssistente: false,
      mostrarModalEdital: false,
      mostrarDocumentacao: false,
      mostrarModalAdicionarDoc: false,
      processoSelecionado: null,
      
      // Edição
      modoEdicao: false,
      processoParaEditar: null,
      tipoProcessoInicial: null,
      
      // Dados auxiliares para visualização detalhada
      produtosProcesso: [],
      
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
      
      // Modal de assinatura digital
      mostrarModalAssinatura: false,
      dadosAssinatura: {},
      processandoAssinatura: false,
      callbackAssinatura: null,
      
      // Modal de devolução
      mostrarModalDevolucao: false,
      processoParaDevolucao: null,
      motivoDevolucao: '',
      observacoesDevolucao: '',
      processandoDevolucao: false,

      // Modal de vincular editais selecionados
      mostrarModalVincularEditaisSelecionados: false,
      editaisDisponiveis: [],
      editaisSelecionados: [],
      carregandoEditais: false,
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
        
        // REMOVIDO FILTRO: DFD agora incluído conforme solicitado pelo usuário
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
          console.log('✅ DEBUG - INCLUINDO DFD (sem filtro):', doc.titulo || doc.nome_documento)
          return true; // MUDANÇA: Agora retorna true para incluir DFD
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
    
    
    podeEditarProcesso(processo) {
      // Só pode editar processos que estão em criação
      const statusProcesso = processo?.status?.toLowerCase() || ''
      return statusProcesso === 'em_criacao' || statusProcesso === 'rascunho'
    },

    async podeAdicionarDocumento(processo) {
      try {
        // Status onde não se pode mais adicionar documentos (processo já foi julgado)
        const statusBloqueados = [
          'expedindo_dcbs',      // Expedindo as DCBs - processo já foi julgado
          'incluindo_marcas',    // Incluindo Marcas no Catálogo - processo já finalizado
          'finalizado',          // Processo finalizado
          'arquivado'           // Processo arquivado
        ]
        
        // Se o processo está em um status onde não pode mais adicionar documentos
        if (statusBloqueados.includes(processo.status)) {
          console.log(`🚫 Não é possível adicionar documentos no status "${processo.status}" - processo já foi julgado`)
          return false
        }
        
        // Usar a lógica do TramitacaoProcessosService para verificar se o usuário pode tramitar
        // Se pode tramitar, significa que é o responsável pelo status atual e pode adicionar documentos
        const podeTrampitar = await TramitacaoProcessosService.podeUsuarioTramitar(processo)
        return podeTrampitar
      } catch (error) {
        console.error('Erro ao verificar permissão de adicionar documento:', error)
        return false
      }
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
      
      // CPM pode enviar processos em rascunho, criado_cpm, criado_cpm_desp ou aguardando_aprovacao (legado)
      if (perfilUsuario === 'cpm' && ['rascunho', 'aguardando_aprovacao', 'criado_cpm', 'criado_cpm_desp'].includes(statusProcesso)) {
        console.log('🎯 Resultado CPM:', '✅ MOSTRAR BOTÃO - CPM pode enviar rascunho/criado')
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
    
    // Função para verificar se o usuário pode assinar digitalmente o processo
    async podeUsuarioAssinar(processo) {
      try {
        console.log(`🔍 DEBUG - podeUsuarioAssinar INÍCIO para processo ${processo.numero_processo}`)
        
        // Se o processo está finalizado, ninguém pode assinar
        if (processo?.status === 'finalizado') {
          console.log(`🔍 DEBUG - Processo finalizado, não pode assinar`)
          return false
        }
        
        // Verificação específica para CCL nos status de julgamento
        const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
        const statusProcesso = processo?.status?.toLowerCase() || ''
        
        // Verificar se pode tramitar (inicializar como true para CCL em status apropriados)
        let podeTrampitar = true

        // CCL pode assinar nos status de julgamento e ata
        const statusCCL = ['julgamento_ccl', 'ata_ccl']
        if (perfilUsuario === 'ccl' && statusCCL.includes(statusProcesso)) {
          console.log(`🔍 DEBUG - CCL pode assinar no status ${statusProcesso}`)
          podeTrampitar = true
        } else {
          // Para outros perfis, verificar se pode tramitar
          podeTrampitar = await TramitacaoProcessosService.podeUsuarioTramitar(processo)

          if (!podeTrampitar) {
            console.log(`🔍 DEBUG - Usuário não pode tramitar, não pode assinar`)
            return false
          }
        }
        
        console.log(`🔍 DEBUG - Usuário pode tramitar, verificando assinaturas existentes...`)
        
        // Verificar se o usuário atual já assinou neste processo
        const usuarioAtual = this.$store.state.user
        if (usuarioAtual?.id) {
          console.log(`🔍 DEBUG - Verificando assinaturas existentes para usuário ${usuarioAtual.id} no processo ${processo.id}`)
          
          try {
            // Usar o serviço para consultar o processo completo
            const processoCompleto = await ProcessosAdministrativosService.obterProcesso(processo.id)
            
            console.log(`🔍 DEBUG - Processo obtido via serviço:`, processoCompleto)
            
            if (processoCompleto) {
              // Verificar se o usuário já assinou no status atual
              const assinaturasExistentes = processoCompleto.assinaturas || []
              const statusAtual = processoCompleto.status
              
              const jaAssinouNoStatusAtual = assinaturasExistentes.some(assinatura => 
                assinatura.usuario_id === usuarioAtual.id && 
                assinatura.status_processo === statusAtual
              )
              
              console.log(`🔍 DEBUG - Status atual do processo:`, statusAtual)
              console.log(`🔍 DEBUG - Assinaturas existentes:`, assinaturasExistentes)
              console.log(`🔍 DEBUG - Usuario ${usuarioAtual.id} já assinou no status "${statusAtual}"?`, jaAssinouNoStatusAtual)
              
              if (jaAssinouNoStatusAtual) {
                console.log(`🔍 DEBUG - ❌ Usuário já assinou este processo no status atual "${statusAtual}"`)
                return false
              } else {
                console.log(`🔍 DEBUG - ✅ Usuário ainda não assinou no status atual "${statusAtual}", pode assinar`)
              }
            } else {
              console.log(`🔍 DEBUG - Erro ao consultar processo, permitindo assinatura`)
            }
          } catch (error) {
            console.log(`🔍 DEBUG - Erro ao consultar processo via serviço, permitindo assinatura:`, error)
          }
        }
        
        // Log para debug
        console.log(`🔍 DEBUG - podeUsuarioAssinar:`, {
          numeroProcesso: processo.numero_processo,
          status: processo.status,
          perfilUsuario: this.perfilUsuario,
          podeTrampitar: podeTrampitar,
          podeAssinar: true
        })
        
        return true
        
      } catch (error) {
        console.error('❌ Erro ao verificar se usuário pode assinar:', error)
        return false
      }
    },

    // Função para verificar se pode vincular edital ao processo
    podeVincularEdital(processo) {
      try {
        if (!processo) return false

        // Apenas processos com status "abertura autorizada" podem vincular editais
        const statusPermitidos = ['abertura_autorizada', 'abertura_autorizada_desp']

        if (!statusPermitidos.includes(processo.status)) {
          return false
        }

        // Verificar se o usuário tem permissão (CPM ou Orgao Administrativo)
        const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
        const perfisPermitidos = ['cpm', 'orgao_administrativo']

        return perfisPermitidos.includes(perfilUsuario)

      } catch (error) {
        console.error('❌ Erro ao verificar se pode vincular edital:', error)
        return false
      }
    },
    
    // Função para obter o texto correto do botão Adicionar Documento
    obterTextoAdicionarDocumento() {
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      
      if (perfilUsuario === 'orgao_administrativo') {
        return 'Adicionar Documento Assinado'
      }
      
      return 'Adicionar Documento'
    },

    // Função para obter a mensagem apropriada quando não pode adicionar documento
    obterMensagemNaoPodeAdicionarDoc() {
      if (!this.processoSelecionado) {
        return 'Processo não carregado'
      }
      
      const status = this.processoSelecionado.status
      
      // Status onde não se pode mais adicionar documentos (processo já foi julgado)
      const statusBloqueados = [
        'expedindo_dcbs',      // Expedindo as DCBs - processo já foi julgado
        'incluindo_marcas',    // Incluindo Marcas no Catálogo - processo já finalizado
        'finalizado',          // Processo finalizado
        'arquivado'           // Processo arquivado
      ]
      
      if (statusBloqueados.includes(status)) {
        return 'Não é possível adicionar documentos - processo já foi julgado'
      }
      
      return 'Apenas o perfil responsável pelo status atual pode adicionar documentos'
    },

    // Verificar se tem ação de enviar disponível para este processo
    temAcaoTramitacaoEnviar(processo) {
      if (!processo?.id || !this.acoesDisponiveis[processo.id]) {
        console.log(`🔍 DEBUG - temAcaoTramitacaoEnviar: FALSO para ${processo?.numero_processo} - sem ações disponíveis`)
        return false
      }
      
      const acoes = this.acoesDisponiveis[processo.id]
      // Verificar tanto ações ENVIAR quanto ENVIAR_FLEXIVEL
      const temEnviar = acoes.some(acao => acao.tipo === 'ENVIAR' || acao.tipo === 'ENVIAR_FLEXIVEL')
      console.log(`🔍 DEBUG - temAcaoTramitacaoEnviar: ${temEnviar ? 'VERDADEIRO' : 'FALSO'} para ${processo.numero_processo}`)
      console.log(`🔍 DEBUG - Ações disponíveis:`, acoes)
      console.log(`🔍 DEBUG - Tipos de ações encontradas:`, acoes.map(a => a.tipo))
      return temEnviar
    },

    // Verificar se tem ação de devolver disponível para este processo
    temAcaoTramitacaoDevolver(processo) {
      if (!processo?.id || !this.acoesDisponiveis[processo.id]) {
        return false
      }
      
      const acoes = this.acoesDisponiveis[processo.id]
      return acoes.some(acao => acao.tipo === 'DEVOLVER')
    },

    // Executar ação de enviar para próxima etapa
    async enviarParaProximaEtapa(processo) {
      if (!this.temAcaoTramitacaoEnviar(processo)) {
        return
      }

      const acoes = this.acoesDisponiveis[processo.id]
      // Buscar tanto ações ENVIAR quanto ENVIAR_FLEXIVEL, priorizando ENVIAR
      let acaoEnviar = acoes.find(acao => acao.tipo === 'ENVIAR')
      if (!acaoEnviar) {
        acaoEnviar = acoes.find(acao => acao.tipo === 'ENVIAR_FLEXIVEL')
      }
      
      console.log(`🚀 DEBUG - enviarParaProximaEtapa: ação encontrada:`, acaoEnviar)
      
      if (acaoEnviar) {
        await this.executarAcaoTramitacao(processo, acaoEnviar)
      }
    },

    // Abrir modal de devolução genérica
    abrirModalDevolucaoGenerica(processo) {
      if (!this.temAcaoTramitacaoDevolver(processo)) {
        return
      }

      // Usar a modal de devolução existente
      this.abrirModalDevolucao(processo)
    },
    
    podeTramitarParaCCL(processo) {
      console.log('🔍 DEBUG - Verificando botão tramitar para CCL:', {
        processo: processo?.numero_processo || processo?.id,
        status: processo?.status,
        tipo: processo?.tipo_processo,
        perfilUsuario: this.perfilUsuario
      })
      
      const statusProcesso = processo?.status?.toLowerCase() || ''
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      
      // Só órgão administrativo pode tramitar para CCL processos assinados
      const podeTramitar = statusProcesso === 'assinado_admin' && perfilUsuario === 'orgao_administrativo'
      
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
    
    gerarHTMLRelatorio(processo, documentos, produtos, ataJulgamento = null) {
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
              @top-left { content: none; }
              @top-center { content: none; }
              @top-right { content: none; }
              @bottom-left { content: none; }
              @bottom-center {
                content: "Página " counter(page) " - Processo ${processo.numero_processo || processo.id}";
                font-size: 10pt;
                color: #666;
              }
              @bottom-right { content: none; }
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
                border: 2px solid #000 !important;
                margin: 0.5cm auto !important;
                padding: 1cm !important;
                width: 19cm !important;
                min-height: 24cm !important;
                page-break-after: always !important;
                box-sizing: border-box !important;
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

              ${doc.conteudo_html ?
                // Se tem conteúdo HTML, usar diretamente (DFD e Folha de Rosto já tem formato completo)
                doc.conteudo_html
                :
                // Se não tem conteúdo HTML, gerar layout padrão
                `<div class="documento-header">
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

                  <div style="margin-top: 3cm; text-align: center; border-top: 1px solid #ccc; padding-top: 1cm; color: #666;">
                    <p>Sistema Comprar Bem - Processo nº ${processo.numero_processo}</p>
                  </div>
                </div>`
              }
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
          
          <!-- ANEXOS (só aparece se houver documentos anexados) -->
          ${documentos.filter(doc => doc.tipo_documento !== 'FOLHA_ROSTO' && doc.tipo_documento !== 'DFD' && doc.arquivo_url && doc.arquivo_url !== 'undefined').length > 0 ? `
          <div class="page-break"></div>
          <div class="documento-pagina">
            <div class="folha-numero">Anexos</div>

            <div class="documento-header">
              <h1>${processo.nome_orgao}</h1>
              <h2>ANEXOS</h2>
              <p>Processo nº ${processo.numero_processo}</p>
            </div>

            <div class="documento-conteudo">
              <h3>📎 DOCUMENTOS ANEXADOS AO PROCESSO</h3>

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
                    .filter(doc => doc.tipo_documento !== 'FOLHA_ROSTO' && doc.tipo_documento !== 'DFD' && doc.arquivo_url && doc.arquivo_url !== 'undefined')
                    .map(doc => `
                    <tr>
                      <td style="text-align: center; font-weight: bold;">Fl. ${String(doc.numero_sequencial || 1).padStart(3, '0')}</td>
                      <td>
                        <strong>${doc.nome_documento || doc.tipo_documento}</strong>
                        ${doc.tipo_documento !== (doc.nome_documento || doc.tipo_documento) ? `<br><small style="color: #666;">(${doc.tipo_documento})</small>` : ''}
                      </td>
                      <td style="text-align: center;">${this.formatarData(doc.data_autuacao)}</td>
                      <td style="text-align: center;">📎 Anexo</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>

              <div style="margin-top: 2cm; text-align: center; border-top: 1px solid #ccc; padding-top: 1cm;">
                <p><strong>Total de anexos:</strong> ${documentos.filter(d => d.tipo_documento !== 'FOLHA_ROSTO' && d.tipo_documento !== 'DFD' && d.arquivo_url && d.arquivo_url !== 'undefined').length}</p>
                <p style="color: #666; margin-top: 1cm;">Gerado em ${dataAtual} - Sistema Comprar Bem</p>
              </div>

            </div>
          </div>
          ` : ''}
          
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
              
              <div style="margin-top: 2cm; text-align: center; border-top: 1px solid #ccc; padding-top: 1cm; color: #666;">
                <p><strong>Relatório gerado automaticamente pelo Sistema Comprar Bem</strong></p>
                <p>Processo nº ${processo.numero_processo} - ${new Date().toLocaleDateString('pt-BR')}</p>
              </div>
            </div>
          </div>
          ` : ''}
          
          <!-- SEÇÃO DA ATA DE JULGAMENTO CCL - FORMATO OFICIAL IDÊNTICO AO PAINEL CCL -->
          ${ataJulgamento ? `
          <div class="page-break"></div>
          <div class="documento-pagina">
            <div class="folha-numero">Ata CCL</div>
            
            <!-- CABEÇALHO OFICIAL EXATO DO PAINEL CCL -->
            <div style="text-align: center; margin-bottom: 25px;">
              <h1 style="font-size: 16pt; font-weight: bold; margin-bottom: 8px; font-family: 'Times New Roman', serif;">
                COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)
              </h1>
              <p style="font-size: 12pt; font-weight: normal; margin: 8px 0; font-family: 'Times New Roman', serif;">
                Sistema de Pré-Qualificação de Bens - Lei 14.133/2021
              </p>
              
              <!-- Linha decorativa -->
              <div style="border-top: 1px solid #000; margin: 15px auto; width: 60%;"></div>
              
              <h1 style="font-size: 18pt; font-weight: bold; margin-top: 15px; font-family: 'Times New Roman', serif;">
                ATA DE JULGAMENTO
              </h1>
            </div>

            <!-- DADOS DA ATA - FORMATO OFICIAL -->
            <div style="margin: 20px 0; font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.6;">
              <p><strong>Número:</strong> ${ataJulgamento.numero || 'Não informado'}</p>
              ${ataJulgamento.periodo && ataJulgamento.periodo !== 'Não informado' ? `
              <p><strong>Período:</strong> ${ataJulgamento.periodo}</p>
              ` : ''}
              <p><strong>Data de Publicação:</strong> ${ataJulgamento.data_publicacao ? new Date(ataJulgamento.data_publicacao).toLocaleDateString('pt-BR') : 'Não informada'}</p>
              ${ataJulgamento.status_ata && ataJulgamento.status_ata !== 'HOMOLOGACAO_DIRETA' ? `
              <p><strong>Status:</strong> ${ataJulgamento.status_ata}</p>
              ` : ''}
            </div>

            <!-- RESUMO DOS JULGAMENTOS -->
            <div style="margin: 25px 0;">
              <h3 style="font-size: 14pt; font-weight: bold; font-family: 'Times New Roman', serif; margin-bottom: 15px;">
                RESUMO DOS JULGAMENTOS
              </h3>
              <div style="margin-left: 15px; font-size: 11pt; line-height: 1.4;">
                <p>Total de processos julgados: 1</p>
                <p>Processo analisado: ${processo.numero_processo || 'Não informado'}</p>
                <p>Status da análise: APROVADO</p>
              </div>
            </div>

            <!-- CONTEÚDO COMPLETO DA ATA - FORMATO OFICIAL -->
            <div style="margin: 25px 0;">
              <h3 style="font-size: 14pt; font-weight: bold; font-family: 'Times New Roman', serif; margin-bottom: 15px;">
                CONTEÚDO COMPLETO DA ATA
              </h3>
              
              <div style="
                border: 1px solid #000; 
                padding: 20px; 
                margin: 10px 0;
                font-family: 'Times New Roman', serif;
                font-size: 10pt;
                line-height: 1.5;
                text-align: justify;
                background: #fafafa;
              ">
                ${ataJulgamento.conteudo_ata ? 
                  ataJulgamento.conteudo_ata.replace(/\n/g, '<br>') : 
                  `
                  <strong>PROCESSO Nº:</strong> ${processo.numero_processo || 'Não informado'}<br><br>
                  
                  <strong>OBJETO:</strong> Pré-qualificação de bens conforme Lei 14.133/2021<br><br>
                  
                  <strong>DECISÃO DA CCL:</strong> APROVADO<br><br>
                  
                  <strong>FUNDAMENTAÇÃO:</strong> A Comissão Central de Licitação, após análise técnica detalhada dos produtos apresentados, considerando os aspectos técnicos, normativos e de conformidade com as especificações estabelecidas, deliberou pela APROVAÇÃO dos produtos relacionados neste processo.<br><br>
                  
                  Os produtos aprovados atendem aos requisitos técnicos e normativos aplicáveis, estando aptos para inclusão no catálogo eletrônico de bens padronizados.<br><br>
                  
                  <strong>PRÓXIMOS PASSOS:</strong> Processo encaminhado à Assessoria Jurídica para análise da conformidade legal.<br><br>
                  
                  <strong>Data do julgamento:</strong> ${ataJulgamento.data_publicacao ? new Date(ataJulgamento.data_publicacao).toLocaleDateString('pt-BR') : new Date().toLocaleDateString('pt-BR')}
                  `
                }
              </div>
            </div>

            
            <!-- RODAPÉ OFICIAL -->
            <div style="
              text-align: center; 
              margin-top: 40px; 
              padding-top: 20px;
              border-top: 1px solid #333;
              font-size: 10pt;
              font-style: italic;
              color: #666;
            ">
              <p><strong>Sistema Comprar Bem - Ata de Julgamento CCL</strong></p>
              <p>Documento oficial gerado automaticamente pelo sistema</p>
              <p>Lei 14.133/2021 - Sistema de Pré-Qualificação de Bens</p>
            </div>
          </div>
          ` : ''}

          ${this.gerarHTMLAssinaturasDigitais(processo)}
          
        </body>
        </html>
      `
    },

    // =====================================================
    // GERAÇÃO DE SEÇÃO DE ASSINATURAS DIGITAIS NO PDF
    // =====================================================
    
    gerarHTMLAssinaturasDigitais(processo) {
      // Página simplificada - só mostra assinaturas quando existirem
      return `
        <div class="page-break"></div>
        <div class="documento-pagina">
          <div class="documento-conteudo">
            <div id="lista-assinaturas-digitais">
              <!-- As assinaturas aparecerão aqui quando forem feitas -->
            </div>
          </div>
        </div>
      `
    },

    // Método para carregar assinaturas do processo
    async carregarAssinaturasProcesso(processoId) {
      try {
        console.log('🔍 Carregando assinaturas para processo:', processoId)
        
        // Usar o serviço para obter o processo completo
        const processo = await ProcessosAdministrativosService.obterProcesso(processoId)
        
        if (!processo) {
          console.error('Processo não encontrado para carregar assinaturas:', processoId)
          return []
        }
        
        const assinaturas = processo.assinaturas || []
        console.log('✅ Assinaturas carregadas:', assinaturas)
        
        return assinaturas
      } catch (error) {
        console.error('Erro ao carregar assinaturas:', error)
        return []
      }
    },
    
    // =====================================================
    // GERAÇÃO DE DOCUMENTO DE ASSINATURA SEPARADO
    // =====================================================
    
    gerarDocumentoAssinatura(processo, assinaturas = []) {
      const dataAtual = new Date().toLocaleDateString('pt-BR')
      const horaAtual = new Date().toLocaleTimeString('pt-BR')
      
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Declaração de Conformidade - Processo ${processo.numero_processo}</title>
          <style>
            @page {
              margin: 3cm 2cm;
              size: A4;
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
            
            .folha-declaracao {
              width: 100%;
              height: 29.7cm;
              padding: 2cm;
              background: white;
              display: flex;
              flex-direction: column;
              justify-content: center;
              align-items: center;
            }
            
            .cabecalho {
              text-align: center;
              margin-bottom: 3cm;
            }
            
            .cabecalho h1 {
              font-size: 16pt;
              font-weight: bold;
              margin-bottom: 0.5cm;
              text-transform: uppercase;
            }
            
            .cabecalho h2 {
              font-size: 14pt;
              font-weight: bold;
              margin-bottom: 0.3cm;
              text-transform: uppercase;
            }
            
            .numero-processo {
              font-size: 12pt;
              font-weight: bold;
              color: #333;
              margin-top: 0.5cm;
            }
            
            .quadro-declaracao {
              border: 2px solid #000;
              padding: 2.5cm;
              margin: 1cm auto;
              width: 15cm;
              min-height: 10cm;
              background: white;
            }
            
            .titulo-declaracao {
              text-align: center;
              font-size: 16pt;
              font-weight: bold;
              margin-bottom: 2cm;
              text-transform: uppercase;
            }
            
            .texto-declaracao {
              text-align: justify;
              line-height: 1.8;
              margin-bottom: 3cm;
              font-size: 12pt;
            }
            
            .area-assinatura {
              margin-top: 3cm;
              text-align: center;
            }
            
            .data-local {
              margin-bottom: 2cm;
              text-align: right;
            }
            
            .linha-assinatura {
              border-top: 1px solid #000;
              width: 8cm;
              margin: 2cm auto 0.5cm auto;
            }
            
            .texto-responsavel {
              font-size: 12pt;
              font-weight: bold;
              text-transform: uppercase;
            }
          </style>
        </head>
        <body>
          <div class="folha-declaracao">
            <div class="cabecalho">
              <h1>${processo.nome_orgao}</h1>
              <h2>Declaração de Conformidade</h2>
              <p class="numero-processo">Processo nº ${processo.numero_processo}</p>
            </div>
            
            <div class="quadro-declaracao">
              <div class="titulo-declaracao">DECLARAÇÃO DE CONFORMIDADE</div>
              
              <div class="texto-declaracao">
                <p>Declaro que o produto acima especificado atende aos requisitos técnicos estabelecidos no Edital de Pré-qualificação, estando em conformidade com as normas aplicáveis e possuindo os padrões mínimos de qualidade exigidos para inclusão no Catálogo Eletrônico de Bens Padronizados.</p>
              </div>
              
              <div class="area-assinatura">
                ${assinaturas.length > 0 ? '' : 
                  `<div class="data-local">
                     _________________, ${dataAtual}
                   </div>
                   
                   <div class="linha-assinatura"></div>
                   
                   <div class="texto-responsavel">
                     <p>Responsável Técnico</p>
                     <p style="font-size: 10pt; color: #666; margin-top: 1cm;">
                       (Documento ainda não foi assinado digitalmente)
                     </p>
                   </div>`
                }
              </div>
            </div>
          </div>
          
          ${assinaturas.length > 0 ? `
          <div style="page-break-before: always; padding: 2cm;">
            <div style="text-align: center; margin-bottom: 2cm;">
              <h2 style="font-size: 14pt; font-weight: bold; text-transform: uppercase;">ASSINATURAS DIGITAIS</h2>
              <p style="font-size: 12pt; margin-top: 0.5cm;">Processo: ${processo.numero_processo}</p>
            </div>
            
            <div style="border-top: 1px solid #000; border-bottom: 1px solid #000; padding: 1cm 0;">
              ${assinaturas.map((assinatura, index) => {
                const dataAssinatura = new Date(assinatura.data_assinatura)
                const dataFormatada = dataAssinatura.toLocaleDateString('pt-BR')
                const horaFormatada = dataAssinatura.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
                
                return `
                <div style="margin-bottom: 1cm; padding: 0.5cm 0; border-bottom: ${index < assinaturas.length - 1 ? '1px solid #ccc' : 'none'};">
                  <p style="font-size: 11pt; line-height: 1.4; margin: 0; text-align: justify;">
                    Documento assinado eletronicamente por <strong>${assinatura.nome_signatario}</strong>, 
                    <strong>${assinatura.cargo_signatario}</strong>, em <strong>${dataFormatada}</strong>, 
                    às <strong>${horaFormatada}</strong>, conforme horário oficial de Brasília, 
                    com fundamento no art. 6º, § 1º, do Decreto nº 47.222, de 26 de julho de 2025.
                  </p>
                </div>`
              }).join('')}
            </div>
          </div>
          ` : ''}
        </body>
        </html>
      `
    },
    
    // Método para gerar e baixar documento de assinatura
    async gerarDocumentoAssinaturaParaDownload(processo) {
      try {
        console.log('🖊️ Gerando documento de assinatura para processo:', processo.numero_processo)
        
        // Carregar assinaturas do processo
        const assinaturas = await this.carregarAssinaturasProcesso(processo.id)
        console.log('✍️ Assinaturas encontradas:', assinaturas)
        
        // Gerar HTML do documento de assinatura
        const htmlAssinatura = this.gerarDocumentoAssinatura(processo, assinaturas)
        
        // Criar nome do arquivo
        const nomeArquivo = `Declaracao_Conformidade_${processo.numero_processo}_${new Date().toISOString().split('T')[0]}.pdf`
        
        // Abrir em nova janela com funcionalidades de download
        const novaJanela = window.open('', '_blank')
        novaJanela.document.write(htmlAssinatura)
        novaJanela.document.close()
        
        // Adicionar funcionalidade de download PDF à nova janela
        setTimeout(() => {
          if (novaJanela && !novaJanela.closed) {
            // Criar elementos de download dinamicamente
            const downloadControls = novaJanela.document.createElement('div')
            downloadControls.style.cssText = `
              position: fixed; 
              top: 10px; 
              right: 10px; 
              background: #fff; 
              border: 2px solid #28a745; 
              border-radius: 8px; 
              padding: 15px; 
              box-shadow: 0 4px 8px rgba(0,0,0,0.2); 
              z-index: 9999;
              font-family: Arial, sans-serif;
            `
            
            // Botão baixar PDF
            const btnDownloadPDF = novaJanela.document.createElement('button')
            btnDownloadPDF.innerHTML = '📋 Baixar Declaração de Conformidade'
            btnDownloadPDF.style.cssText = `
              background: #28a745; 
              color: white; 
              border: none; 
              padding: 10px 20px; 
              border-radius: 5px; 
              cursor: pointer;
              font-weight: bold;
              font-size: 14px;
            `
            btnDownloadPDF.onclick = () => {
              // Esconder os controles temporariamente
              downloadControls.style.display = 'none'

              // Aguardar um pouco e then imprimir
              setTimeout(() => {
                try {
                  if (!novaJanela.closed) {
                    novaJanela.print()
                  }
                } catch (error) {
                  console.warn('Erro ao imprimir:', error)
                }
                downloadControls.style.display = 'block'
              }, 500)
            }
            
            downloadControls.appendChild(btnDownloadPDF)
            novaJanela.document.body.appendChild(downloadControls)
            
            // Focar na nova janela
            novaJanela.focus()
          }
        }, 1000)
        
        this.$swal({
          title: '📋 Declaração de Conformidade Gerada',
          html: `
            <p><strong>Declaração de Conformidade criada com sucesso!</strong></p>
            <p>📄 Arquivo: <code>${nomeArquivo}</code></p>
            <br>
            <p>📝 <strong>Instruções:</strong></p>
            <ul style="text-align: left; margin: 0 auto; display: inline-block;">
              <li>Baixe o documento usando o botão verde</li>
              <li>Imprima, assine como Responsável Técnico</li>
              <li>Digitalize o documento assinado</li>
              <li>Use "Adicionar Documento Assinado" para anexar</li>
            </ul>
          `,
          icon: 'success',
          confirmButtonText: '✅ Entendi',
          confirmButtonColor: '#28a745'
        })
        
      } catch (error) {
        console.error('❌ Erro ao gerar documento de assinatura:', error)
        this.$swal({
          title: '❌ Erro na Geração',
          text: `Erro ao gerar documento de assinatura: ${error.message}`,
          icon: 'error'
        })
      }
    },

    /**
     * Valida se um DFD tem conteúdo suficiente para ser incluído no relatório
     * @param {Object} dfd - Objeto DFD a ser validado
     * @returns {boolean} - true se o DFD é válido, false se está vazio
     */
    validarDFDPreenchido(dfd) {
      if (!dfd) return false

      // REMOVIDO FILTRO: Aceitar TODOS os DFDs sem validação de conteúdo
      console.log(`✅ DFD ${dfd.id} aceito SEM FILTRO (conforme solicitado pelo usuário)`)

      // Garantir que sempre tenha HTML para exibição
      if (!dfd.conteudo_html || dfd.conteudo_html.trim().length < 50) {
        const htmlGerado = this.gerarHTMLDFDSimples(dfd)
        dfd.conteudo_html = htmlGerado
        console.log(`🔧 HTML gerado automaticamente para DFD ${dfd.id} (${htmlGerado.length} caracteres)`)
      }

      return true // SEMPRE retorna true - sem filtros
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
        // Buscar DFDs se não foram passados
        if (!dadosDFD || dadosDFD.length === 0) {
          console.log('Buscando DFDs no banco...')
          try {
            const { data: dfdsData } = await supabase
              .from('dfd_processo')
              .select('*')
              .eq('processo_id', processo.id)
              .order('created_at', { ascending: true })

            // REMOVIDO FILTRO: Aceitar TODOS os DFDs
            dadosDFD = dfdsData || []

            console.log(`📋 DEBUG DETALHADO: ${dadosDFD.length} DFD(s) encontrado(s) para processo ${processo.id}:`)
            dadosDFD.forEach((dfd, index) => {
              console.log(`📄 DFD ${index + 1}:`, {
                id: dfd.id,
                justificativa: dfd.justificativa || '[VAZIO]',
                justificativa_length: dfd.justificativa?.length || 0,
                necessidade_descricao: dfd.necessidade_descricao || '[VAZIO]',
                necessidade_descricao_length: dfd.necessidade_descricao?.length || 0,
                modelo_usado: dfd.modelo_usado || '[SEM MODELO]',
                created_at: dfd.created_at
              })
            })
          } catch (error) {
            console.log('DFD não encontrado no banco, criando com dados padrão')
            dadosDFD = [{
              justificativa: 'Justificativa da necessidade conforme demanda apresentada',
              descricao_necessidade: 'Descrição detalhada da necessidade identificada',
              criterios_aceitacao: 'Critérios de aceitação e ensaios estabelecidos',
              observacoes_especiais: 'Observações especiais e condições do processo'
            }]
          }
        }
        
        const modeloDFD = processo.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'

        // Criar um documento para cada DFD
        console.log(`🔧 DEBUG: Criando documentos para ${dadosDFD.length} DFD(s)`)
        console.log('🔧 DEBUG: Dados DFD recebidos:', dadosDFD)
        let folhaAtual = 2 // DFDs começam na Fl. 002

        dadosDFD.forEach((dfdData, index) => {
          console.log(`🔧 DEBUG: Processando DFD ${index + 1}:`, dfdData.id)
          const dfd = {
            numero_folha: folhaAtual + index, // Folhas sequenciais para cada DFD
            tipo_documento: 'DFD',
            nome_documento: `Documento de Formalização de Demanda ${index + 1} - ${modeloDFD}`,
            titulo: `DFD ${index + 1} - Documento de Formalização de Demanda (${modeloDFD})`,
            descricao: `Documento de Formalização de Demanda ${index + 1} do processo de ${processo.tipo_processo}`,
            data_autuacao: dfdData?.created_at || processo.created_at,
            conteudo_html: this.gerarHTMLDFD(processo, dfdData, produtos, index + 1)
          }

          console.log(`🔧 DEBUG: Criando DFD ${index + 1}:`, dfd.titulo)

          // Inserir DFD após folha de rosto (ou último DFD inserido)
          const folhaRostoIndex = documentosCompletos.findIndex(doc => doc.tipo_documento === 'FOLHA_ROSTO')
          const ultimoDFDIndex = documentosCompletos.findLastIndex(doc => doc.tipo_documento === 'DFD')

          console.log(`🔧 DEBUG: Índices - Folha Rosto: ${folhaRostoIndex}, Último DFD: ${ultimoDFDIndex}`)

          if (ultimoDFDIndex >= 0) {
            documentosCompletos.splice(ultimoDFDIndex + 1, 0, dfd)
            console.log(`🔧 DEBUG: DFD ${index + 1} inserido após último DFD na posição ${ultimoDFDIndex + 1}`)
          } else if (folhaRostoIndex >= 0) {
            documentosCompletos.splice(folhaRostoIndex + 1, 0, dfd)
            console.log(`🔧 DEBUG: DFD ${index + 1} inserido após folha de rosto na posição ${folhaRostoIndex + 1}`)
          } else {
            documentosCompletos.push(dfd)
            console.log(`🔧 DEBUG: DFD ${index + 1} inserido no final do array`)
          }
        })

        console.log(`🔧 DEBUG: ${dadosDFD.length} DFD(s) adicionado(s) aos documentos`)
        console.log('🔧 DEBUG: Documentos completos após adição de DFDs:')
        documentosCompletos.forEach((doc, index) => {
          console.log(`   ${index + 1}. ${doc.tipo_documento} - ${doc.titulo || doc.nome_documento}`)
        })
      } else {
        // DFDs existem, garantir que tenham conteúdo HTML
        console.log('DFD(s) existente(s) encontrado(s)')
        const dfdsExistentes = documentosCompletos.filter(doc => doc.tipo_documento === 'DFD' || doc.tipo_documento === 'dfd')

        dfdsExistentes.forEach((dfd, index) => {
          const modeloDFD = processo.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'
          const numeroDFD = index + 1

          dfd.numero_folha = 2 + index // Folhas sequenciais
          dfd.nome_documento = `Documento de Formalização de Demanda ${numeroDFD} - ${modeloDFD}`
          dfd.titulo = `DFD ${numeroDFD} - Documento de Formalização de Demanda (${modeloDFD})`

          // FORÇAR REGENERAÇÃO DO HTML com dados atuais do banco
          console.log(`🔧 FORÇANDO regeneração de HTML para DFD ${numeroDFD} com dados atuais`)
          // Usar dados DFD específicos ou o primeiro se disponível
          const dadosDFDEspecifico = Array.isArray(dadosDFD) && dadosDFD[index] ? dadosDFD[index] : (dadosDFD || {})

          console.log('📊 DEBUG: Dados para regeneração HTML:', {
            id: dadosDFDEspecifico?.id,
            justificativa: dadosDFDEspecifico?.justificativa || '[VAZIO]',
            justificativa_length: dadosDFDEspecifico?.justificativa?.length || 0,
            necessidade_descricao: dadosDFDEspecifico?.necessidade_descricao || '[VAZIO]',
            necessidade_descricao_length: dadosDFDEspecifico?.necessidade_descricao?.length || 0
          })

          dfd.conteudo_html = this.gerarHTMLDFD(processo, dadosDFDEspecifico, produtos, numeroDFD)
          console.log(`✅ HTML REGENERADO com ${dfd.conteudo_html.length} caracteres usando dados atuais`)
        })
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
                // Apenas adicionar se o documento tiver dados válidos
                if (doc && doc.nome && doc.nome !== 'undefined' && doc.url && doc.url !== 'undefined') {
                  documentosProdutoConsolidados.push({
                    produto: produto,
                    documento: doc
                  })
                }
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
        // Extrair informações do documento formatado - apenas se tiver dados válidos
        if (doc.arquivo_url && doc.arquivo_url !== 'undefined' && doc.nome_arquivo && doc.nome_arquivo !== 'undefined') {
          documentosProdutoConsolidados.push({
            documento: {
              nome: doc.nome_arquivo,
              url: doc.arquivo_url
            },
            produto: {
              nome: doc.nome_produto || doc.titulo?.split(' - ')[0] || 'Produto',
              marca: doc.marca || 'N/A',
              modelo: doc.modelo || 'N/A',
              categoria: doc.categoria || 'N/A',
              fabricante: doc.fabricante || 'N/A',
              created_at: doc.data_autuacao
            }
          })
        }
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
                
                
                <h3>AVALIAÇÃO TÉCNICA</h3>
                <p><strong>Status:</strong> ${produto.status || 'Pendente de avaliação'}</p>
                <p><strong>Data de Inclusão:</strong> ${produto.created_at ? new Date(produto.created_at).toLocaleDateString('pt-BR') : new Date().toLocaleDateString('pt-BR')}</p>
                
              </div>
            `
          }
          
          documentosCompletos.push(paginaProduto)
          console.log(`✅ Criada página individual para produto: ${produto.nome_produto || produto.nome}`)
        }
      }

      // Filtrar documentos válidos antes de criar a página consolidada
      documentosProdutoConsolidados = documentosProdutoConsolidados.filter(item => {
        return item.documento && 
               item.documento.nome && 
               item.documento.nome !== 'undefined' && 
               item.documento.url && 
               item.documento.url !== 'undefined'
      })
      
      // Se há documentos de produtos válidos, criar uma única página consolidada
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
              
              ${documentosProdutoConsolidados
                .filter(item => item.documento && item.documento.nome && item.documento.nome !== 'undefined' && item.documento.url && item.documento.url !== 'undefined')
                .map((item, index) => `
                <div style="margin: 1cm 0; padding: 0.5cm; border-left: 3px solid #1976d2;">
                  <p><strong>${index + 1}. ${item.produto.nome || 'Produto'}</strong></p>
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
      
      // Manter TODOS os DFDs (não remover como duplicados)
      const dfds = outrosDocumentos.filter(doc => doc.tipo_documento === 'DFD')
      const outrosDocumentosSemDFD = outrosDocumentos.filter(doc => doc.tipo_documento !== 'DFD')

      console.log(`✅ Mantendo ${dfds.length} DFD(s) encontrado(s)`)

      // Recriar lista com TODOS os DFDs
      documentosCompletos = []
      if (melhorFolhaRosto) documentosCompletos.push(melhorFolhaRosto)

      // Adicionar TODOS os DFDs SEM FILTRO ordenados por data de criação
      if (dfds.length > 0) {
        // REMOVIDO FILTRO: Aceitar todos os DFDs independente do conteúdo
        const dfdsOrdenados = dfds.sort((a, b) => new Date(a.data_autuacao || a.created_at) - new Date(b.data_autuacao || b.created_at))

        console.log(`📄 Adicionando ${dfdsOrdenados.length} DFD(s) SEM FILTRO ao relatório`)

        documentosCompletos.push(...dfdsOrdenados)
      }

      documentosCompletos.push(...outrosDocumentosSemDFD)
      
      // Renumerar documentos seguindo Instrução Processual
      let proximoNumero = 1
      
      documentosCompletos.forEach((doc, index) => {
        // Gerar conteúdo HTML para documentos ASSINADOS (para integrar como página)
        if (doc.tipo_documento === 'ASSINADO' && !doc.conteudo_html) {
          console.log('🖊️ Gerando conteúdo HTML para documento ASSINADO:', doc.nome_documento)
          doc.conteudo_html = this.gerarHTMLDocumentoAssinado(processo, doc)
        }
        
        // Atribuir numeração sequencial
        doc.numero_sequencial = proximoNumero++
        doc.numero_folha = doc.numero_sequencial
      })
      
      // Reordenar por número de folha garantindo ordem correta
      const documentosOrdenados = documentosCompletos.sort((a, b) => {
        // Folha de rosto sempre primeiro
        if (a.tipo_documento === 'FOLHA_ROSTO') return -1
        if (b.tipo_documento === 'FOLHA_ROSTO') return 1

        // DFD sempre segundo
        if (a.tipo_documento === 'DFD') return b.tipo_documento === 'FOLHA_ROSTO' ? 1 : -1
        if (b.tipo_documento === 'DFD') return a.tipo_documento === 'FOLHA_ROSTO' ? -1 : 1

        // Documentos ASSINADOS sempre por último (página final do processo)
        if (a.tipo_documento === 'ASSINADO' && b.tipo_documento !== 'ASSINADO') return 1
        if (b.tipo_documento === 'ASSINADO' && a.tipo_documento !== 'ASSINADO') return -1

        // Entre documentos ASSINADOS, manter ordem cronológica (mais recente por último)
        if (a.tipo_documento === 'ASSINADO' && b.tipo_documento === 'ASSINADO') {
          return new Date(a.data_autuacao || 0) - new Date(b.data_autuacao || 0)
        }

        // Demais documentos por número sequencial (evita problema com strings)
        return (a.numero_sequencial || 999) - (b.numero_sequencial || 999)
      })

      // RENUMERAR documentos após reordenação para corrigir numeração
      documentosOrdenados.forEach((doc, index) => {
        doc.numero_sequencial = index + 1
        doc.numero_folha = index + 1
        console.log(`🔢 DEBUG: Documento ${doc.tipo_documento} numerado como Fl. ${String(index + 1).padStart(3, '0')}`)

        // LIMPAR CABEÇALHOS DUPLICADOS do conteudo_html
        if (doc.conteudo_html) {
          const htmlOriginal = doc.conteudo_html

          // Limpeza muito mais agressiva
          doc.conteudo_html = doc.conteudo_html
            // Remover linhas completas com data/hora e "Caderno do Processo"
            .replace(/^.*\d{2}\/\d{2}\/\d{4},?\s*\d{2}:\d{2}.*Caderno do Processo.*$/gmi, '')
            .replace(/^.*15\/09\/2025,?\s*07:\d{2}.*$/gmi, '')
            .replace(/^.*Caderno do Processo\s*\d+.*$/gmi, '')
            // Remover Fl. xxx duplicados no início de linhas
            .replace(/^.*Fl\.\s*\d{3}.*$/gmi, '')
            // Remover apenas data/hora no início de linhas
            .replace(/^\d{2}\/\d{2}\/\d{4},?\s*\d{2}:\d{2}\s*/gm, '')
            // Limpar linhas vazias múltiplas
            .replace(/\n\s*\n\s*\n/g, '\n\n')
            .trim()

          if (htmlOriginal !== doc.conteudo_html) {
            console.log(`🧹 DEBUG: Limpeza aplicada em ${doc.tipo_documento}:`)
            console.log(`   Antes: ${htmlOriginal.length} chars`)
            console.log(`   Depois: ${doc.conteudo_html.length} chars`)
          }
        }
      })

      return documentosOrdenados
    },

    // =====================================================
    // GERAÇÃO DE HTML PARA DOCUMENTO ASSINADO INTEGRADO
    // =====================================================
    
    gerarHTMLDocumentoAssinado(processo, documento) {
      const dataAssinatura = new Date(documento.data_autuacao).toLocaleDateString('pt-BR')
      
      return `
        <div class="documento-header">
          <h1>${processo.nome_orgao}</h1>
          <h2>DOCUMENTO ASSINADO PELA AUTORIDADE COMPETENTE</h2>
          <p>Processo nº ${processo.numero_processo}</p>
        </div>
        
        <div class="documento-conteudo">
          <div class="caixa-bordered" style="margin: 2cm auto; padding: 1.5cm; border: 2px solid #000;">
            <h3 style="text-align: center; margin-bottom: 1.5cm; font-size: 14pt;">DECLARAÇÃO DE RESPONSABILIDADE</h3>
            
            <div class="campo" style="margin-bottom: 1cm;">
              <p><strong>Tipo de Processo:</strong> ${processo.tipo_processo === 'padronizacao' ? 'Padronização de Produtos' : 'Despadronização de Produtos'}</p>
            </div>
            
            <div class="campo" style="margin-bottom: 1cm;">
              <p><strong>Status do Processo:</strong> ${this.formatarStatus(processo.status)}</p>
            </div>
            
            <div class="campo" style="margin-bottom: 1cm;">
              <p><strong>Unidade Interessada:</strong> ${processo.unidade_interessada || 'Não informado'}</p>
            </div>
            
            <div class="campo" style="margin-bottom: 1.5cm;">
              <p><strong>Data de Autuação:</strong> ${this.formatarData(processo.data_autuacao)}</p>
            </div>
            
            <p style="text-align: justify; margin-bottom: 1.5cm; line-height: 1.8;">Eu, na qualidade de <strong>AUTORIDADE COMPETENTE</strong> do órgão acima identificado, declaro que:</p>
            
            <ul style="margin: 1.5cm 0; line-height: 1.8; text-align: justify;">
              <li>Analisei toda a documentação que compõe o presente processo administrativo;</li>
              <li>Verifico que o processo está devidamente instruído e em conformidade com as normas aplicáveis;</li>
              <li>As informações e documentos apresentados são verdadeiros e estão em conformidade com a legislação vigente;</li>
              <li>Assumo a responsabilidade pelos atos administrativos decorrentes desta assinatura.</li>
            </ul>
            
            <div style="margin-top: 2cm; text-align: center;">
              <p style="margin-bottom: 1cm;"><strong>PROCESSO DEVIDAMENTE ASSINADO</strong></p>
              <p style="margin-bottom: 0.5cm;"><strong>Data da Assinatura:</strong> ${dataAssinatura}</p>
              
              <div style="border-top: 2px solid #000; width: 10cm; margin: 2cm auto 0.5cm auto;"></div>
              <p><strong>AUTORIDADE COMPETENTE</strong></p>
              <p>${processo.nome_orgao}</p>
            </div>
          </div>
          
          <div style="margin-top: 1.5cm; padding: 1cm; background: #f8f9fa; border-radius: 8px; border: 1px solid #dee2e6;">
            <h4 style="margin: 0 0 0.5cm 0; color: #495057;">Informações do Documento Assinado</h4>
            <p style="margin: 0.3cm 0;"><strong>Nome do Arquivo:</strong> ${documento.nome_documento}</p>
            <p style="margin: 0.3cm 0;"><strong>Data de Anexação:</strong> ${dataAssinatura}</p>
            <p style="margin: 0.3cm 0;"><strong>Observações:</strong> ${documento.descricao || 'Documento assinado pela autoridade competente'}</p>
          </div>
          
          <div style="margin-top: 2cm; text-align: center; border-top: 1px solid #ccc; padding-top: 1cm; color: #666;">
            <p><strong>Sistema Comprar Bem</strong> - Página Final do Processo</p>
            <p>Documento integrado automaticamente - Processo nº ${processo.numero_processo}</p>
          </div>
        </div>
      `
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
              <strong>OBJETO:</strong> ${(() => {
                console.log('🔍 DEBUG OBJETO Component:', {
                  objeto_customizado: processo.objeto_customizado,
                  tipo_processo: processo.tipo_processo,
                  campos_disponveis: Object.keys(processo)
                })
                return processo.objeto_customizado || objetoTexto
              })()}
            </div>

            
          </div>
        </div>
      `
    },

    gerarHTMLDFD(processo, dadosDFD, produtos, numeroDFD = 1) {
      console.log('🔧 DEBUG gerarHTMLDFD (Component) - Dados recebidos:', {
        processoId: processo?.id,
        tipoProcesso: processo?.tipo_processo,
        dadosDFD: {
          justificativa: dadosDFD?.justificativa?.length || 0,
          necessidade_descricao: dadosDFD?.necessidade_descricao?.length || 0,
          criterios_aceitacao: dadosDFD?.criterios_aceitacao?.length || 0,
          observacoes_especiais: dadosDFD?.observacoes_especiais?.length || 0
        },
        numeroDFD,
        totalProdutos: produtos?.length || 0
      })

      const modeloTipo = processo.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'
      const finalidade = processo.tipo_processo === 'padronizacao' ?
        'PADRONIZAÇÃO DE MARCAS E MODELOS DE PRODUTOS' :
        'DESPADRONIZAÇÃO DE MARCAS E MODELOS DE PRODUTOS'

      const tituloCompleto = `DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA${numeroDFD > 1 ? ` ${numeroDFD}` : ''} - ${modeloTipo}`

      // Função auxiliar para renderizar valor booleano
      const formatarBooleano = (valor) => valor ? 'SIM' : 'NÃO'

      console.log('🎨 DEBUG: Aplicando NOVA formatação compacta do DFD no Component')

      let htmlConteudo = `
        <div class="documento-header" style="text-align: center; margin-bottom: 0.1cm;">
          <h1 style="font-size: 12pt; font-weight: bold; margin: 0.1cm 0; page-break-inside: avoid;">${processo.nome_orgao}</h1>
          <h2 style="font-size: 11pt; font-weight: bold; margin: 0.05cm 0; page-break-inside: avoid;">${tituloCompleto}</h2>
          <p style="font-size: 9pt; margin: 0.02cm 0;">Processo nº ${processo.numero_processo}</p>
        </div>

        <div class="documento-conteudo" style="text-align: justify; line-height: 1.1; font-size: 9pt; word-wrap: break-word; overflow-wrap: break-word; padding: 0.05cm;">

          <h3 style="margin: 0.1cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">1. JUSTIFICATIVA</h3>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm; page-break-inside: avoid;">${dadosDFD?.justificativa || 'Justificativa da necessidade conforme processo administrativo de ' + (processo.tipo_processo === 'padronizacao' ? 'padronização' : 'despadronização') + ' de produtos.'}</p>

          <h3 style="margin: 0.1cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">2. DESCRIÇÃO DA NECESSIDADE</h3>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm; page-break-inside: avoid;">${dadosDFD?.necessidade_descricao || 'Descrição detalhada da necessidade identificada para o processo de ' + (processo.tipo_processo === 'padronizacao' ? 'padronização' : 'despadronização') + ' dos produtos especificados.'}</p>

          <h3 style="margin: 0.1cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">3. CRITÉRIOS DE ACEITAÇÃO</h3>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm; page-break-inside: avoid;">${dadosDFD?.criterios_aceitacao || 'Critérios de aceitação conforme normas técnicas aplicáveis e especificações definidas para o processo.'}</p>

          <h2 style="margin: 0.1cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase;">OBSERVAÇÕES ESPECIAIS</h2>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD?.observacoes_especiais || 'Observações especiais do processo.'}</p>`

      // Incluir produtos se existirem
      if (produtos && produtos.length > 0) {
        htmlConteudo += `
          <h3 style="font-size: 10pt; margin-top: 0.3cm;">1.1. Relação de ${processo.tipo_processo === 'padronizacao' ? 'Bens' : 'Bens Passíveis de Despadronização'}:</h3>
          <table class="tabela" style="width: 100%; border-collapse: collapse; margin: 0.2cm 0; font-size: 8pt;">
            <thead>
              <tr style="background-color: #f0f0f0;">
                <th style="border: 1px solid #000; padding: 3px; text-align: center; font-weight: bold;">ITEM</th>
                <th style="border: 1px solid #000; padding: 3px; text-align: center; font-weight: bold;">CÓDIGO</th>
                <th style="border: 1px solid #000; padding: 3px; text-align: center; font-weight: bold;">DESCRIÇÃO</th>
                <th style="border: 1px solid #000; padding: 3px; text-align: center; font-weight: bold;">UNIDADE</th>
                <th style="border: 1px solid #000; padding: 3px; text-align: center; font-weight: bold;">${processo.tipo_processo === 'padronizacao' ? 'REQUISITOS MÍNIMOS' : 'MOTIVAÇÃO'}</th>
                ${processo.tipo_processo === 'padronizacao' ? '<th style="border: 1px solid #000; padding: 3px; text-align: center; font-weight: bold;">PREÇO ESTIMADO</th>' : ''}
              </tr>
            </thead>
            <tbody>
              ${produtos.map((produto, index) => `
                <tr>
                  <td style="border: 1px solid #000; padding: 3px; text-align: center;">${index + 1}</td>
                  <td style="border: 1px solid #000; padding: 3px;">${produto.codigo || 'N/A'}</td>
                  <td style="border: 1px solid #000; padding: 3px;">${produto.nome_produto}</td>
                  <td style="border: 1px solid #000; padding: 3px; text-align: center;">UN</td>
                  <td style="border: 1px solid #000; padding: 3px;">${produto.especificacoes_tecnicas || 'A definir'}</td>
                  ${processo.tipo_processo === 'padronizacao' ? `<td style="border: 1px solid #000; padding: 3px; text-align: right;">R$ ${produto.valor_estimado || '0,00'}</td>` : ''}
                </tr>
              `).join('')}
            </tbody>
          </table>`
      }

      // Seção específica para PADRONIZAÇÃO (MODELO_1)
      if (processo.tipo_processo === 'padronizacao') {
        if (dadosDFD?.produtos_especificacao) {
          htmlConteudo += `
            <h3 style="margin: 0.05cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">4. ESPECIFICAÇÃO DOS PRODUTOS</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm; page-break-inside: avoid;">${dadosDFD.produtos_especificacao}</p>`
        }

        if (dadosDFD?.quantidade_amostras) {
          htmlConteudo += `
            <h4 style="margin: 0.05cm 0 0.02cm 0; font-size: 9pt; page-break-after: avoid;">4.1. Quantidades de Amostras</h4>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.quantidade_amostras} unidades</p>`
        }

        if (dadosDFD?.previsao_aquisicoes) {
          htmlConteudo += `
            <h4 style="margin: 0.05cm 0 0.02cm 0; font-size: 9pt; page-break-after: avoid;">4.2. Previsão de Aquisições</h4>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.previsao_aquisicoes} unidades</p>`
        }

        if (dadosDFD?.especificacoes_tecnicas) {
          htmlConteudo += `
            <h3 style="margin: 0.05cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">5. ESPECIFICAÇÕES TÉCNICAS</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.especificacoes_tecnicas}</p>`
        }

        if (dadosDFD?.ensaios_exigidos) {
          htmlConteudo += `
            <h3 style="margin: 0.05cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">6. ENSAIOS EXIGIDOS</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.ensaios_exigidos}</p>`
        }

        if (dadosDFD?.local_entrega_amostras) {
          htmlConteudo += `
            <h3 style="margin: 0.05cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">7. LOCAL DE ENTREGA DAS AMOSTRAS</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.local_entrega_amostras}</p>`
        }

        if (dadosDFD?.prazo_entrega_amostras) {
          htmlConteudo += `
            <h3 style="margin: 0.05cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">8. PRAZO PARA ENTREGA DAS AMOSTRAS</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.prazo_entrega_amostras}</p>`
        }
      }

      // Seção específica para DESPADRONIZAÇÃO (MODELO_2)
      if (processo.tipo_processo === 'despadronizacao') {
        if (dadosDFD?.produtos_despadronizar) {
          htmlConteudo += `
            <h3 style="margin: 0.05cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">3. PRODUTOS A SEREM DESPADRONIZADOS</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.produtos_despadronizar}</p>`
        }

        // Fontes da demanda
        htmlConteudo += `
          <h3 style="margin: 0.05cm 0 0.02cm 0; font-size: 10pt; text-transform: uppercase; page-break-after: avoid;">4. FONTES DA DEMANDA</h3>`

        const fontes = []
        if (dadosDFD?.fonte_rdm) fontes.push('Relatórios de Desempenho de Material (RDM)')
        if (dadosDFD?.fonte_reclamacoes_usuarios) fontes.push('Reclamações de usuários')
        if (dadosDFD?.fonte_sistema_comprar_bem) fontes.push('Sistema Comprar Bem')
        if (dadosDFD?.fonte_analise_tecnica) fontes.push('Análise técnica')
        if (dadosDFD?.fonte_outros) fontes.push('Outros')

        if (fontes.length > 0) {
          htmlConteudo += `<ul style="margin-left: 1cm; margin-bottom: 0.05cm;">`
          fontes.forEach(fonte => {
            htmlConteudo += `<li style="margin-bottom: 0.02cm;">${fonte}</li>`
          })
          htmlConteudo += `</ul>`
        }

        if (dadosDFD?.outras_fontes) {
          htmlConteudo += `
            <h3 style="margin-top: 0.1cm; font-size: 9pt;">3.1. Outras Fontes:</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.outras_fontes}</p>`
        }

        if (dadosDFD?.problemas_identificados) {
          htmlConteudo += `
            <h2 style="margin-top: 0.1cm; font-size: 10pt;">4. PROBLEMAS IDENTIFICADOS:</h2>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.problemas_identificados}</p>`
        }

        if (dadosDFD?.frequencia_problemas) {
          htmlConteudo += `
            <h3 style="margin-top: 0.05cm; font-size: 9pt;">4.1. Frequência dos Problemas:</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.frequencia_problemas}</p>`
        }

        if (dadosDFD?.impacto_problemas) {
          htmlConteudo += `
            <h3 style="margin-top: 0.05cm; font-size: 9pt;">4.2. Impacto dos Problemas:</h3>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.impacto_problemas}</p>`
        }

        if (dadosDFD?.quantidade_adquirida) {
          htmlConteudo += `
            <h2 style="margin-top: 0.05cm; font-size: 10pt;">5. QUANTIDADES:</h2>
            <p style="text-indent: 0.5cm; margin-bottom: 0.02cm;"><strong>Quantidade adquirida:</strong> ${dadosDFD.quantidade_adquirida} unidades</p>`
        }

        if (dadosDFD?.quantidade_problemas) {
          htmlConteudo += `
            <p style="text-indent: 0.5cm; margin-bottom: 0.02cm;"><strong>Quantidade com problemas:</strong> ${dadosDFD.quantidade_problemas} unidades</p>`
        }

        if (dadosDFD?.prejuizo_estimado) {
          htmlConteudo += `
            <p style="text-indent: 0.5cm; margin-bottom: 0.02cm;"><strong>Prejuízo estimado:</strong> R$ ${dadosDFD.prejuizo_estimado}</p>`
        }

        if (dadosDFD?.rdms_negativos) {
          htmlConteudo += `
            <p style="text-indent: 0.5cm; margin-bottom: 0.02cm;"><strong>RDMs negativos:</strong> ${dadosDFD.rdms_negativos}</p>`
        }

        if (dadosDFD?.parecer_tecnico) {
          htmlConteudo += `
            <h2 style="margin-top: 0.05cm; font-size: 10pt;">6. PARECER TÉCNICO:</h2>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.parecer_tecnico}</p>`
        }

        if (dadosDFD?.alternativas_avaliadas) {
          htmlConteudo += `
            <h2 style="margin-top: 0.05cm; font-size: 10pt;">7. ALTERNATIVAS AVALIADAS:</h2>
            <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.alternativas_avaliadas}</p>`
        }
      }

      // Seção GERAL (MODELO_GERAL) - aplicável a ambos os tipos
      if (dadosDFD?.base_legal) {
        htmlConteudo += `
          <h2 style="margin-top: 0.05cm; font-size: 10pt;">BASE LEGAL:</h2>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.base_legal}</p>`
      }

      if (dadosDFD?.impacto_esperado) {
        htmlConteudo += `
          <h2 style="margin-top: 0.05cm; font-size: 10pt;">IMPACTO ESPERADO:</h2>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.impacto_esperado}</p>`
      }

      if (dadosDFD?.riscos_identificados) {
        htmlConteudo += `
          <h2 style="margin-top: 0.05cm; font-size: 10pt;">RISCOS IDENTIFICADOS:</h2>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.riscos_identificados}</p>`
      }

      if (dadosDFD?.medidas_mitigadoras) {
        htmlConteudo += `
          <h2 style="margin-top: 0.05cm; font-size: 10pt;">MEDIDAS MITIGADORAS:</h2>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.medidas_mitigadoras}</p>`
      }

      if (dadosDFD?.prazo_vigencia) {
        htmlConteudo += `
          <h2 style="margin-top: 0.05cm; font-size: 10pt;">PRAZO DE VIGÊNCIA:</h2>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.prazo_vigencia} meses</p>`
      }

      if (dadosDFD?.periodicidade_revisao) {
        htmlConteudo += `
          <h2 style="margin-top: 0.05cm; font-size: 10pt;">PERIODICIDADE DE REVISÃO:</h2>
          <p style="text-indent: 0.5cm; margin-bottom: 0.05cm;">${dadosDFD.periodicidade_revisao}</p>`
      }

      // Conclusão
      htmlConteudo += `
          <div style="margin-top: 0.2cm; page-break-inside: avoid;">
            <p style="text-align: justify; margin-bottom: 0.1cm; font-size: 9pt;">Nestes termos, encaminha-se o presente DFD à autoridade competente, para ciência da presente demanda e autorização para a abertura e instrução do pertinente processo administrativo.</p>

            <p style="margin-bottom: 0.1cm; font-size: 9pt;">Em ${new Date().toLocaleDateString('pt-BR')}.</p>

            <div style="text-align: center; margin-top: 0.3cm;">
              <p style="margin-bottom: 0.1cm; font-size: 9pt;"><strong>Data:</strong> ${new Date().toLocaleDateString('pt-BR')}</p>
              <div style="border-top: 1px solid #000; width: 6cm; margin: 0.2cm auto 0.1cm auto;"></div>
              <p style="font-size: 9pt;"><strong>Equipe Técnica Responsável</strong></p>
              <p style="font-size: 9pt;">${processo.nome_orgao}</p>
            </div>
          </div>
        </div>
      `

      console.log('✅ DEBUG gerarHTMLDFD (Component) - HTML gerado:', {
        tamanho: htmlConteudo.length,
        temJustificativa: htmlConteudo.includes('JUSTIFICATIVA'),
        temDescricao: htmlConteudo.includes('DESCRIÇÃO DA NECESSIDADE'),
        temDadosReais: htmlConteudo.includes(dadosDFD?.justificativa?.substring(0, 20)) || false,
        preview: htmlConteudo.substring(0, 200) + '...'
      })

      return htmlConteudo
    },

    // Método simplificado para gerar HTML do DFD (PATCH TEMPORÁRIO)
    gerarHTMLDFDSimples(dadosDFD) {
      console.log('🔧 PATCH gerarHTMLDFDSimples - Gerando HTML direto dos dados DFD')
      console.log('📊 DEBUG: Dados recebidos no gerarHTMLDFDSimples:', {
        id: dadosDFD?.id || '[SEM ID]',
        justificativa_length: dadosDFD?.justificativa?.length || 0,
        justificativa_preview: dadosDFD?.justificativa?.substring(0, 50) || '[VAZIO]',
        necessidade_descricao_length: dadosDFD?.necessidade_descricao?.length || 0,
        necessidade_descricao_preview: dadosDFD?.necessidade_descricao?.substring(0, 50) || '[VAZIO]',
        modelo_usado: dadosDFD?.modelo_usado || '[SEM MODELO]'
      })

      const html = `
        <div class="documento-dfd" style="font-family: Arial, sans-serif; line-height: 1.6;">
          <h1 style="text-align: center; margin-bottom: 1cm;">DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${dadosDFD.modelo_usado?.toUpperCase() || 'MODELO_1'}</h1>

          ${dadosDFD.nome_presidente ? `
          <div style="margin-bottom: 1cm;">
            <h2>DADOS DO DEMANDANTE</h2>
            <p><strong>Nome do Presidente da CPPM:</strong> ${dadosDFD.nome_presidente}</p>
            ${dadosDFD.matricula_presidente ? `<p><strong>Matrícula:</strong> ${dadosDFD.matricula_presidente}</p>` : ''}
            ${dadosDFD.email_presidente ? `<p><strong>E-mail:</strong> ${dadosDFD.email_presidente}</p>` : ''}
            ${dadosDFD.telefone_presidente ? `<p><strong>Telefone:</strong> ${dadosDFD.telefone_presidente}</p>` : ''}
          </div>
          ` : ''}

          <div style="margin-bottom: 1cm;">
            <h2>1. JUSTIFICATIVA</h2>
            <p style="text-align: justify;">${dadosDFD.justificativa || 'Justificativa não preenchida.'}</p>
          </div>

          <div style="margin-bottom: 1cm;">
            <h2>2. DESCRIÇÃO DA NECESSIDADE</h2>
            <p style="text-align: justify;">${dadosDFD.necessidade_descricao || 'Descrição da necessidade não preenchida.'}</p>
          </div>

          ${dadosDFD.produtos_especificacao ? `
          <div style="margin-bottom: 1cm;">
            <h2>3. PRODUTOS A SEREM PRÉ-QUALIFICADOS</h2>
            <p style="text-align: justify;"><strong>Especificação dos Produtos/Serviços:</strong> ${dadosDFD.produtos_especificacao}</p>
          </div>
          ` : ''}

          ${dadosDFD.criterios_aceitacao ? `
          <div style="margin-bottom: 1cm;">
            <h2>4. CRITÉRIOS DE ACEITAÇÃO</h2>
            <p style="text-align: justify;">${dadosDFD.criterios_aceitacao}</p>
          </div>
          ` : ''}

          ${dadosDFD.especificacoes_tecnicas ? `
          <div style="margin-bottom: 1cm;">
            <h2>5. ESPECIFICAÇÕES TÉCNICAS</h2>
            <p style="text-align: justify;">${dadosDFD.especificacoes_tecnicas}</p>
          </div>
          ` : ''}

          ${dadosDFD.ensaios_exigidos ? `
          <div style="margin-bottom: 1cm;">
            <h2>6. ENSAIOS EXIGIDOS</h2>
            <p style="text-align: justify;">${dadosDFD.ensaios_exigidos}</p>
          </div>
          ` : ''}

          ${dadosDFD.observacoes_especiais ? `
          <div style="margin-bottom: 1cm;">
            <h2>OBSERVAÇÕES ESPECIAIS</h2>
            <p style="text-align: justify;">${dadosDFD.observacoes_especiais}</p>
          </div>
          ` : ''}

          <div style="margin-top: 2cm; text-align: center;">
            <p>Data: ${new Date().toLocaleDateString('pt-BR')}</p>
            <br><br>
            <p>_________________________________________</p>
            <p>Presidente da CPPM</p>
          </div>
        </div>
      `

      console.log('✅ PATCH gerarHTMLDFDSimples - HTML gerado:', {
        tamanho: html.length,
        preview: html.substring(0, 200) + '...'
      })

      return html
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
        
        
        // Verificar se o usuário pode adicionar documentos ao processo
        this.podeAdicionarDoc = await this.podeAdicionarDocumento(this.processoSelecionado)
        
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
      
      // Debug específico para status de autoridade
      if (processo.status && processo.status.includes('submetido')) {
        console.log('🚨 DEBUG ESPECÍFICO - Status contém "submetido":', {
          statusOriginal: processo.status,
          statusTrimmed: processo.status.trim(),
          statusLength: processo.status.length,
          statusBytes: Array.from(processo.status).map(c => c.charCodeAt(0)),
          isExactMatch: processo.status === 'submetido_autoridade'
        })
      }
      
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
      this.podeAdicionarDoc = false
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
      // Chamar nova função limpa
      return this.gerarRelatorioPDF(processo)
    },

    async gerarRelatorioPDF(processo) {
      try {
        console.log('🆕 NOVA LÓGICA: Gerando relatório PDF para processo:', processo.id)

        // 1. Buscar dados completos do processo
        const processoCompleto = await ProcessosAdministrativosService.obterProcesso(processo.id)
        console.log('🔍 Processo completo:', {
          id: processoCompleto.id,
          numero_processo: processoCompleto.numero_processo,
          objeto_customizado: processoCompleto.objeto_customizado,
          nome_orgao: processoCompleto.nome_orgao
        })

        // 2. Buscar DFDs reais do banco
        const { data: dfdsReais } = await supabase
          .from('dfd_processo')
          .select('*')
          .eq('processo_id', processo.id)
          .order('created_at', { ascending: true })

        console.log('📋 DFDs encontrados:', dfdsReais?.length || 0)
        console.log('📋 DFDs DADOS DETALHADOS:', dfdsReais?.map((dfd, i) => ({
          [`DFD ${i+1}`]: {
            id: dfd.id,
            justificativa: dfd.justificativa,
            necessidade_descricao: dfd.necessidade_descricao,
            criterios_aceitacao: dfd.criterios_aceitacao,
            observacoes_especiais: dfd.observacoes_especiais,
            'todas as chaves': Object.keys(dfd)
          }
        })))

        // 3. Buscar produtos se for padronização
        let produtos = []
        if (processoCompleto.tipo_processo === 'padronizacao') {
          produtos = await ProcessosAdministrativosService.listarProdutosProcesso(processo.id)
          console.log('📦 Produtos encontrados:', produtos?.length || 0)
        }

        // 4. Buscar documentos anexados ao processo - busca direta pelos tipos que queremos
        let documentosAnexados = []

        try {
          console.log('🔍 Buscando documentos anexados para processo:', processo.id)

          const { data: resultados, error: erroDocumentos } = await supabase
            .from('documentos_processo')
            .select('*')
            .eq('processo_id', processo.id)
            .in('tipo_documento', ['COMPLEMENTAR', 'CORRECAO', 'ADICIONAL', 'PARECER', 'MANIFESTACAO', 'ASSINADO'])
            .order('created_at', { ascending: true })

          if (erroDocumentos) {
            console.error('❌ Erro ao buscar documentos anexados:', erroDocumentos)
          } else {
            documentosAnexados = resultados || []
            console.log('✅ Busca de documentos concluída com sucesso')
          }
        } catch (error) {
          console.error('❌ Erro na busca de documentos:', error)
        }

        console.log('📄 Documentos anexados encontrados:', documentosAnexados?.length || 0)
        console.log('📄 Documentos anexados detalhes:', documentosAnexados?.map(doc => ({
          id: doc.id,
          nome: doc.nome_documento,
          tipo: doc.tipo_documento,
          arquivo_url: doc.arquivo_url,
          todas_as_chaves: Object.keys(doc)
        })))

        // 5. Buscar assinaturas do processo
        const assinaturas = await this.carregarAssinaturasProcesso(processo.id)
        console.log('✍️ Assinaturas encontradas:', assinaturas?.length || 0)

        // 6. Buscar editais vinculados ao processo
        let editaisVinculados = []
        try {
          console.log('🔍 Buscando editais vinculados ao processo:', processo.id)

          // Primeiro, buscar as vinculações
          const { data: vinculacoes, error: erroVinculacoes } = await supabase
            .from('processo_editais')
            .select('edital_id, data_vinculacao')
            .eq('processo_id', processo.id)
            .order('data_vinculacao', { ascending: true })

          if (erroVinculacoes) {
            console.error('❌ Erro ao buscar vinculações:', erroVinculacoes)
          } else if (vinculacoes && vinculacoes.length > 0) {
            console.log('📋 Vinculações encontradas:', vinculacoes.length)

            // Buscar os editais correspondentes
            const editaisIds = vinculacoes.map(v => v.edital_id)
            const { data: editaisData, error: erroEditais } = await supabase
              .from('editais')
              .select(`
                id,
                numero,
                descricao,
                pdf_convertido_url,
                url_documento,
                data_publicacao
              `)
              .in('id', editaisIds)

            if (erroEditais) {
              console.error('❌ Erro ao buscar editais:', erroEditais)
            } else {
              editaisVinculados = editaisData || []
              console.log('📋 Editais vinculados encontrados:', editaisVinculados.length)
              console.log('📋 Detalhes dos editais:', editaisVinculados.map(e => ({
                numero: e.numero,
                descricao: e.descricao,
                tem_pdf: !!(e.pdf_convertido_url || e.url_documento)
              })))
            }
          } else {
            console.log('📋 Nenhuma vinculação encontrada para este processo')
          }
        } catch (error) {
          console.error('❌ Erro na busca de editais vinculados:', error)
        }

        // 7. Gerar HTML limpo do PDF (incluindo documentos anexados, editais e assinaturas)
        const htmlLimpo = this.gerarHTMLPDFLimpo(processoCompleto, dfdsReais || [], produtos, documentosAnexados || [], editaisVinculados || [], assinaturas)

        // 5. Abrir em nova janela
        const novaJanela = window.open('', '_blank')
        if (!novaJanela) {
          alert('Por favor, permita pop-ups para gerar o PDF')
          return
        }

        novaJanela.document.write(htmlLimpo)
        novaJanela.document.close()

        // Adicionar botão de download após carregar
        setTimeout(() => {
          this.adicionarBotaoDownloadPDF(novaJanela, processoCompleto)
        }, 500)

        console.log('✅ PDF gerado com nova lógica limpa')

      } catch (error) {
        console.error('❌ Erro na nova lógica de PDF:', error)
        alert(`Erro ao gerar PDF: ${error.message}`)
      }
    },

    gerarHTMLPDFLimpo(processo, dfds, produtos, documentosAnexados = [], editaisVinculados = [], assinaturas = []) {
      console.log('🎨 Gerando HTML limpo do PDF', {
        dfds: dfds?.length || 0,
        produtos: produtos?.length || 0,
        documentosAnexados: documentosAnexados?.length || 0,
        editaisVinculados: editaisVinculados?.length || 0,
        assinaturas: assinaturas?.length || 0
      })

      // CSS base limpo e profissional
      const cssLimpo = `
        <style>
          @page {
            size: A4;
            margin: 3cm 2.5cm 2.5cm 3cm;
          }

          body {
            font-family: 'Times New Roman', serif;
            font-size: 12pt;
            line-height: 1.4;
            color: #000;
            margin: 0;
            padding: 0;
            background: white;
          }

          .page-break {
            page-break-before: always;
          }

          .documento-pagina {
            width: 100%;
            min-height: 24cm;
            position: relative;
            padding: 1cm;
            background: white;
            border: 1px solid #ddd;
            margin: 0.5cm auto;
            max-width: 19cm;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }

          .documento-pagina:not(:last-child) {
            page-break-after: always;
          }

          .folha-numero {
            position: absolute;
            top: 0.3cm;
            right: 0.5cm;
            font-size: 10pt;
            font-weight: bold;
            color: #666;
            z-index: 999;
            font-family: 'Times New Roman', serif;
          }

          .caixa-bordered {
            border: 2px solid #000;
            padding: 2cm 1.5cm;
            margin: 1cm auto;
            background: white;
          }

          .campo {
            margin-bottom: 1cm;
            text-align: justify;
            line-height: 1.5;
          }

          .campo strong {
            font-weight: bold;
          }

          .titulo-processo {
            font-weight: bold;
            font-size: 14pt;
            text-align: center;
            margin-bottom: 1.5cm;
            text-transform: uppercase;
          }

          .folha-rosto {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 20cm;
          }

          /* DFD Específico */
          .dfd-container {
            padding: 0.5cm;
          }

          .dfd-titulo {
            font-weight: bold;
            font-size: 12pt;
            text-align: center;
            margin-bottom: 1.5cm;
            text-transform: uppercase;
            border-bottom: 2px solid #000;
            padding-bottom: 0.5cm;
            line-height: 1.3;
          }

          .dfd-secao {
            margin-bottom: 0.8cm;
            page-break-inside: avoid;
          }

          .dfd-secao-titulo {
            font-weight: bold;
            font-size: 10pt;
            margin-bottom: 0.3cm;
            text-transform: uppercase;
            color: #000;
          }

          .dfd-conteudo {
            text-align: justify;
            line-height: 1.2;
            font-size: 10pt;
            margin-bottom: 0.3cm;
            text-indent: 0;
          }

          .dfd-campo-inline {
            margin-bottom: 0.1cm;
          }

          .dfd-campo-inline strong {
            font-weight: bold;
          }

          /* Estilos para Assinaturas */
          .pagina-assinatura {
            width: 100%;
            min-height: 24cm;
            position: relative;
            padding: 1cm 0;
            page-break-before: always;
          }

          .header-assinatura {
            text-align: center;
            margin-bottom: 2cm;
            border-bottom: 2px solid #000;
            padding-bottom: 0.5cm;
          }

          .titulo-assinatura {
            font-size: 14pt;
            font-weight: bold;
            text-transform: uppercase;
            margin-bottom: 0.5cm;
          }

          .info-assinatura {
            background: #f8f9fa;
            border: 1px solid #ccc;
            padding: 1cm;
            margin-bottom: 1cm;
            border-radius: 5px;
          }

          .campo-assinatura {
            margin-bottom: 0.8cm;
            display: flex;
            align-items: flex-start;
          }

          .label-assinatura {
            font-weight: bold;
            min-width: 150px;
            margin-right: 10px;
          }

          .valor-assinatura {
            flex: 1;
            border-bottom: 1px solid #000;
            min-height: 20px;
            padding-bottom: 2px;
          }

          .espaco-assinatura {
            border: 1px solid #333;
            height: 100px;
            margin: 1.5cm 0;
            text-align: center;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #f9f9f9;
            font-style: italic;
            color: #666;
          }

          /* Layout para páginas com múltiplas assinaturas */
          .pagina-assinaturas-multiplas {
            padding: 1cm 0.5cm;
          }

          .titulo-assinaturas {
            font-size: 14pt;
            font-weight: bold;
            text-align: center;
            margin-bottom: 2cm;
            border-bottom: 2px solid #333;
            padding-bottom: 0.5cm;
          }

          .assinatura-item {
            margin-bottom: 1.5cm;
            padding: 0.8cm;
            border: 1px solid #ddd;
            border-radius: 8px;
            background: #fafafa;
          }

          .assinatura-numero {
            font-size: 11pt;
            font-weight: bold;
            color: #333;
            margin-bottom: 0.5cm;
          }

          .assinatura-texto {
            font-size: 10pt;
            line-height: 1.6;
            text-align: justify;
          }

          /* Layout para páginas de documentos anexados */
          .documento-anexado-container {
            padding: 0;
            margin: 0;
            width: 100%;
            height: 100%;
          }

          /* Página especial para PDFs - sem padding */
          .documento-pagina.pdf-pagina-completa {
            padding: 0 !important;
            margin: 0.5cm auto !important;
            position: relative;
            max-width: 19cm;
            display: block;
          }

          /* Ajustar posição do número da folha em PDFs completos */
          .documento-pagina.pdf-pagina-completa .folha-numero {
            position: absolute;
            top: 0.5cm;
            right: 0.5cm;
            z-index: 1000;
            background: white;
            border: 2px solid #000;
            padding: 4px 8px;
            font-size: 10pt;
            font-weight: bold;
          }

          .titulo-documento-anexado {
            font-size: 14pt;
            font-weight: bold;
            text-align: center;
            margin-bottom: 2cm;
            border-bottom: 2px solid #333;
            padding-bottom: 0.5cm;
          }

          .info-documento {
            margin-bottom: 2cm;
            background: #f9f9f9;
            padding: 1cm;
            border-radius: 8px;
            border: 1px solid #ddd;
          }

          .campo-documento {
            margin-bottom: 0.8cm;
            font-size: 11pt;
            line-height: 1.4;
          }

          .preview-documento {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 1cm;
            background: white;
            min-height: 10cm;
          }

          .preview-indisponivel,
          .preview-pdf,
          .preview-arquivo {
            text-align: center;
            padding: 2cm;
          }

          .preview-imagem {
            text-align: center;
          }

          /* Layout para PDFs página completa */
          .preview-pdf-pagina-completa {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            border: none;
            position: relative;
          }

          .preview-pdf-pagina-completa object,
          .preview-pdf-pagina-completa iframe {
            width: 100% !important;
            height: calc(100vh - 2cm) !important;
            min-height: 22cm;
            max-height: 24cm;
            border: none !important;
            margin: 0 !important;
            padding: 0 !important;
            display: block;
          }

          .pdf-fallback {
            min-height: 300px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
          }

          .icone-documento {
            font-size: 3em;
            margin-bottom: 1cm;
          }

          .tipo-arquivo {
            font-size: 12pt;
            font-weight: bold;
            margin-bottom: 1cm;
          }

          .url-documento {
            background: #f5f5f5;
            padding: 0.5cm;
            border-radius: 4px;
            margin: 1cm 0;
            font-family: monospace;
          }

          .observacao-preview {
            font-style: italic;
            color: #666;
            margin-top: 1cm;
            font-size: 10pt;
          }

          @media print {
            * {
              -webkit-print-color-adjust: exact !important;
              color-adjust: exact !important;
              print-color-adjust: exact !important;
            }

            body {
              background: white !important;
              margin: 0 !important;
            }

            .documento-pagina {
              background: white !important;
              border: 2px solid #000 !important;
              margin: 0.5cm auto !important;
              padding: 1cm !important;
              width: 19cm !important;
              min-height: 24cm !important;
              box-sizing: border-box !important;
              page-break-after: always !important;
            }

            .documento-pagina:last-child {
              page-break-after: avoid !important;
            }

            .folha-numero {
              position: absolute !important;
              top: 0.3cm !important;
              right: 0.5cm !important;
              background: white !important;
              border: 2px solid #000 !important;
              padding: 4px 8px !important;
              font-size: 10pt !important;
              font-weight: bold !important;
            }

            .caixa-bordered {
              border: 2px solid #000 !important;
              background: white !important;
            }

            .assinatura-item {
              border: 1px solid #000 !important;
              background: white !important;
              margin-bottom: 1.2cm !important;
              page-break-inside: avoid !important;
            }

            .titulo-assinaturas {
              border-bottom: 2px solid #000 !important;
            }

            .info-documento {
              border: 1px solid #000 !important;
              background: white !important;
            }

            .preview-documento {
              border: 1px solid #000 !important;
              background: white !important;
            }

            .titulo-documento-anexado {
              border-bottom: 2px solid #000 !important;
            }

            .url-documento {
              background: #f5f5f5 !important;
              border: 1px solid #000 !important;
            }

            .preview-pdf-pagina-completa {
              background: white !important;
              margin: 0 !important;
              padding: 0 !important;
            }

            .preview-pdf-pagina-completa object,
            .preview-pdf-pagina-completa iframe {
              border: none !important;
              background: white !important;
              width: 100% !important;
              height: 100% !important;
            }

            .documento-pagina.pdf-pagina-completa {
              padding: 0 !important;
              margin: 0.5cm auto !important;
              max-width: 19cm !important;
              display: block !important;
            }

            .documento-pagina.pdf-pagina-completa .folha-numero {
              position: absolute !important;
              top: 0.3cm !important;
              right: 0.3cm !important;
              z-index: 1000 !important;
              background: white !important;
              border: 2px solid #000 !important;
            }
          }
        </style>
      `

      let numeroPagina = 1
      let htmlCompleto = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Processo ${processo.numero_processo || processo.id}</title>
          ${cssLimpo}
        </head>
        <body>
      `

      // PÁGINA 1: FOLHA DE ROSTO LIMPA
      htmlCompleto += this.gerarFolhaRostoLimpa(processo, numeroPagina++)

      // PÁGINAS DFD: Somente se existirem DFDs reais
      if (dfds && dfds.length > 0) {
        dfds.forEach((dfd, index) => {
          htmlCompleto += '<div class="page-break"></div>'
          htmlCompleto += this.gerarDFDLimpo(processo, dfd, produtos, numeroPagina++, index + 1)
        })
      }

      // PÁGINAS DE DOCUMENTOS ANEXADOS: Se existirem documentos
      if (documentosAnexados && documentosAnexados.length > 0) {
        documentosAnexados.forEach((documento, index) => {
          htmlCompleto += this.gerarPaginaDocumentoAnexado(processo, documento, numeroPagina++, index + 1)
        })
      }

      // PÁGINAS DE EDITAIS VINCULADOS: Se existirem editais
      if (editaisVinculados && editaisVinculados.length > 0) {
        editaisVinculados.forEach((edital, index) => {
          htmlCompleto += this.gerarPaginaEditalVinculado(processo, edital, numeroPagina++, index + 1)
        })
      }

      // PÁGINAS DE ASSINATURA: Se existirem assinaturas (múltiplas por página)
      if (assinaturas && assinaturas.length > 0) {
        htmlCompleto += this.gerarPaginasAssinaturasOtimizadas(processo, assinaturas, numeroPagina)
        numeroPagina += Math.ceil(assinaturas.length / 3) // 3 assinaturas por página
      }

      htmlCompleto += `
        </body>
        </html>
      `

      return htmlCompleto
    },

    gerarFolhaRostoLimpa(processo, numeroPagina) {
      // SEMPRE mostrar mensagem padrão primeiro
      const mensagemPadrao = processo.tipo_processo === 'padronizacao' ?
        'CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS.' :
        'DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE E ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS.'

      // Se houver texto personalizado, adicionar diretamente após a mensagem padrão
      const objetoFinal = processo.objeto_customizado ?
        `${mensagemPadrao} ${processo.objeto_customizado}` :
        mensagemPadrao

      console.log('📄 FOLHA DE ROSTO:', {
        objeto_customizado: processo.objeto_customizado,
        objetoFinal: objetoFinal.substring(0, 50) + '...'
      })

      return `
        <div class="documento-pagina">
          <div class="folha-numero">Fl. ${String(numeroPagina).padStart(3, '0')}</div>

          <div class="folha-rosto">
            <div class="caixa-bordered">

              <div class="titulo-processo">
                PROCESSO ADMINISTRATIVO Nº ${processo.numero_processo || '[não definido]'}
              </div>

              <div class="campo">
                <strong>NOME DO ÓRGÃO:</strong> ${processo.nome_orgao || 'Não informado'}
              </div>

              <div class="campo">
                <strong>INTERESSADO(A):</strong> ${processo.unidade_interessada || 'DEPARTAMENTO DE COMPRAS E LICITAÇÕES'}
              </div>

              <div class="campo">
                <strong>DATA DE AUTUAÇÃO:</strong> ${this.formatarData(processo.data_autuacao)}
              </div>

              <div class="campo" style="text-align: justify; line-height: 1.4;">
                <strong>OBJETO:</strong> ${objetoFinal}
              </div>

            </div>
          </div>
        </div>
      `
    },

    gerarDFDLimpo(processo, dfd, produtos, numeroPagina, numeroDFD) {
      const modeloTipo = processo.tipo_processo === 'padronizacao' ? 'MODELO_1' : 'MODELO_2'
      const tituloCompleto = `DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA${numeroDFD > 1 ? ` ${numeroDFD}` : ''} - ${modeloTipo}`

      console.log('📋 DFD LIMPO - CAMPOS DETALHADOS:', {
        numeroDFD,
        modelo: modeloTipo,
        dfd_id: dfd?.id,
        justificativa: dfd?.justificativa,
        necessidade_descricao: dfd?.necessidade_descricao,
        produtos_especificacao: dfd?.produtos_especificacao,
        especificacoes_tecnicas: dfd?.especificacoes_tecnicas,
        criterios_aceitacao: dfd?.criterios_aceitacao,
        ensaios_exigidos: dfd?.ensaios_exigidos,
        observacoes_especiais: dfd?.observacoes_especiais
      })

      return `
        <div class="documento-pagina">
          <div class="folha-numero">Fl. ${String(numeroPagina).padStart(3, '0')}</div>

          <div class="dfd-container">
            <div class="dfd-titulo">
              ${processo.nome_orgao || 'ÓRGÃO NÃO INFORMADO'}<br>
              ${tituloCompleto}<br>
              <span style="font-size: 10pt; font-weight: normal;">PROCESSO Nº ${processo.numero_processo || '[NÃO DEFINIDO]'}</span>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">1. JUSTIFICATIVA</div>
              <div class="dfd-conteudo">${dfd?.justificativa || 'Justificativa não informada.'}</div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">2. DESCRIÇÃO DA NECESSIDADE</div>
              <div class="dfd-conteudo">${dfd?.necessidade_descricao || 'Descrição da necessidade não informada.'}</div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">3. ESPECIFICAÇÃO DOS PRODUTOS/SERVIÇOS</div>
              <div class="dfd-conteudo">${dfd?.produtos_especificacao || 'Especificação não informada.'}</div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">4. ESPECIFICAÇÕES TÉCNICAS</div>
              <div class="dfd-conteudo">${dfd?.especificacoes_tecnicas || 'Especificações técnicas não informadas.'}</div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">5. CRITÉRIOS DE ACEITAÇÃO</div>
              <div class="dfd-conteudo">${dfd?.criterios_aceitacao || 'Critérios de aceitação não informados.'}</div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">6. QUANTIDADES E AMOSTRAGEM</div>
              <div class="dfd-conteudo">
                <strong>Quantidade de Amostras:</strong> ${dfd?.quantidade_amostras || 'Não informado'}<br>
                <strong>Previsão de Aquisições:</strong> ${dfd?.previsao_aquisicoes || 'Não informado'}
              </div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">7. CONDIÇÕES DE ENTREGA</div>
              <div class="dfd-conteudo">
                <strong>Local de Entrega das Amostras:</strong> ${dfd?.local_entrega_amostras || 'Não informado'}<br>
                <strong>Prazo de Entrega das Amostras:</strong> ${dfd?.prazo_entrega_amostras || 'Não informado'}
              </div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">8. ENSAIOS EXIGIDOS</div>
              <div class="dfd-conteudo">${dfd?.ensaios_exigidos || 'Ensaios não informados.'}</div>
            </div>

            <div class="dfd-secao">
              <div class="dfd-secao-titulo">9. OBSERVAÇÕES ESPECIAIS</div>
              <div class="dfd-conteudo">${dfd?.observacoes_especiais || 'Observações especiais não informadas.'}</div>
            </div>

            <div style="margin-top: 2cm; page-break-inside: avoid;">
              <div class="dfd-conteudo" style="text-align: justify;">Nestes termos, encaminha-se o presente DFD à autoridade competente, para ciência da presente demanda e autorização para a abertura e instrução do pertinente processo administrativo.</div>

              <div style="text-align: center; margin-top: 2cm;">
                <p style="margin-bottom: 1cm; font-size: 10pt;"><strong>Data:</strong> ${new Date().toLocaleDateString('pt-BR')}</p>
                <div style="border-top: 1px solid #000; width: 8cm; margin: 1cm auto 0.5cm auto;"></div>
                <p style="font-size: 10pt; font-weight: bold; margin-bottom: 0.3cm;">Equipe Técnica Responsável</p>
                <p style="font-size: 10pt;">${processo.nome_orgao || 'Órgão Responsável'}</p>
              </div>
            </div>

          </div>
        </div>
      `
    },

    gerarPaginaAssinatura(processo, assinatura, numeroPagina, numeroAssinatura) {
      console.log('✍️ Gerando página de assinatura:', {
        numeroAssinatura,
        nome_signatario: assinatura?.nome_signatario,
        cargo_signatario: assinatura?.cargo_signatario,
        data_assinatura: assinatura?.data_assinatura
      })

      // Formatar data e hora da assinatura
      const dataAssinatura = new Date(assinatura?.data_assinatura || new Date())
      const dataFormatada = dataAssinatura.toLocaleDateString('pt-BR')
      const horaFormatada = dataAssinatura.toLocaleTimeString('pt-BR')

      return `
        <div class="documento-pagina">
          <div class="folha-numero">Fl. ${String(numeroPagina).padStart(3, '0')}</div>

          <div style="display: flex; justify-content: center; align-items: center; min-height: 20cm;">
            <div style="margin: 2cm; padding: 2cm; text-align: justify; line-height: 1.8; font-size: 12pt;">
              <p>
                Documento assinado eletronicamente por <strong>${assinatura?.nome_signatario || 'Nome não informado'}</strong>,
                <strong>${assinatura?.cargo_signatario || 'Cargo não informado'}</strong>, em <strong>${dataFormatada}</strong>,
                às <strong>${horaFormatada}</strong>, conforme horário oficial de Brasília,
                com fundamento no art. 6º, § 1º, do Decreto nº 47.222, de 26 de julho de 2017.
              </p>
            </div>
          </div>

        </div>
      `
    },

    gerarPaginaDocumentoAnexado(processo, documento, numeroPagina, numeroDocumento) {
      console.log('📄 Gerando página de documento anexado:', {
        numeroDocumento,
        nome_documento: documento?.nome_documento,
        tipo_documento: documento?.tipo_documento,
        url_documento: documento?.url_documento
      })

      // Verificar se é PDF para aplicar classe especial
      const urlDocumento = documento?.url_documento || documento?.arquivo_url || documento?.publicUrl
      const isPDF = urlDocumento && urlDocumento.toLowerCase().includes('.pdf')
      const classeEspecial = isPDF ? ' pdf-pagina-completa' : ''

      return `
        <div class="documento-pagina${classeEspecial}">
          <div class="folha-numero">Fl. ${String(numeroPagina).padStart(3, '0')}</div>

          <div class="documento-anexado-container">
            ${this.gerarPreviewDocumento(documento)}
          </div>
        </div>
      `
    },

    gerarPaginaEditalVinculado(processo, edital, numeroPagina, numeroEdital) {
      console.log('📋 Gerando página de edital vinculado:', {
        numeroEdital,
        numero: edital?.numero,
        descricao: edital?.descricao,
        pdf_url: edital?.pdf_convertido_url || edital?.url_documento
      })

      const urlEdital = edital?.pdf_convertido_url || edital?.url_documento
      const dataPublicacao = edital?.data_publicacao ? new Date(edital.data_publicacao).toLocaleDateString('pt-BR') : 'Não informada'

      return `
        <div class="documento-pagina pdf-pagina-completa">
          <div class="folha-numero">Fl. ${String(numeroPagina).padStart(3, '0')}</div>

          <div class="edital-anexado-container">
            <div class="edital-header-info">
              <h3>📋 EDITAL DE PRÉ-QUALIFICAÇÃO ${edital?.numero || 'N/A'}</h3>
              <p><strong>Descrição:</strong> ${edital?.descricao || 'Não informada'}</p>
              <p><strong>Data de Publicação:</strong> ${dataPublicacao}</p>
            </div>

            ${this.gerarPreviewEdital(edital)}
          </div>
        </div>
      `
    },

    gerarPreviewEdital(edital) {
      const urlEdital = edital?.pdf_convertido_url || edital?.url_documento

      if (!urlEdital) {
        return `
          <div class="preview-indisponivel">
            <div class="icone-documento">📋</div>
            <div class="mensagem">Edital não disponível</div>
            <div class="detalhes">URL do edital não encontrada</div>
          </div>
        `
      }

      // Para editais, sempre tratar como PDF
      return `
        <div class="preview-pdf-pagina-completa">
          <object
            data="${urlEdital}#toolbar=0&navpanes=0&scrollbar=0&statusbar=0&messages=0&scrollbar=0"
            type="application/pdf"
            width="100%"
            height="22cm"
            style="border: none; max-width: 100%;">

            <!-- Fallback para navegadores que não suportam object -->
            <iframe
              src="${urlEdital}#toolbar=0&navpanes=0&scrollbar=0&statusbar=0&messages=0&scrollbar=0"
              width="100%"
              height="22cm"
              style="border: none; max-width: 100%;">

              <!-- Fallback final se iframe também não funcionar -->
              <div class="pdf-fallback" style="text-align: center; padding: 4cm; background: white; min-height: 18cm;">
                <div style="font-size: 4em; margin-bottom: 1cm;">📋</div>
                <div style="margin: 1cm 0; font-weight: bold; font-size: 14pt;">Edital não pode ser exibido diretamente</div>
                <div style="font-size: 12pt; margin-bottom: 2cm; color: #666;">
                  O navegador não suporta visualização de PDF incorporada.
                </div>
                <a href="${urlEdital}" target="_blank"
                   style="display: inline-block; padding: 1cm 2cm; background: #007bff; color: white; text-decoration: none; border-radius: 8px; font-size: 12pt;">
                  📋 Abrir Edital em Nova Aba
                </a>
                <div style="margin-top: 2cm; font-size: 10pt; color: #999;">
                  <strong>Edital:</strong> ${edital?.numero || 'N/A'}
                </div>
              </div>

            </iframe>
          </object>
        </div>
      `
    },

    gerarPreviewDocumento(documento) {
      // Tentar múltiplos campos para URL
      const urlDocumento = documento?.url_documento || documento?.arquivo_url || documento?.publicUrl

      if (!urlDocumento) {
        return `
          <div class="preview-indisponivel">
            <div class="icone-documento">📄</div>
            <div class="mensagem">Preview não disponível</div>
            <div class="detalhes">Documento sem URL válida</div>
            <div class="debug-campos" style="font-size: 8pt; margin-top: 1cm; color: #999;">
              Campos disponíveis: ${Object.keys(documento || {}).join(', ')}
            </div>
          </div>
        `
      }

      const urlLower = urlDocumento.toLowerCase()

      // Se for PDF - incorporar o conteúdo diretamente (página completa)
      if (urlLower.includes('.pdf')) {
        return `
          <div class="preview-pdf-pagina-completa">
            <object
              data="${urlDocumento}#toolbar=0&navpanes=0&scrollbar=0&statusbar=0&messages=0&scrollbar=0"
              type="application/pdf"
              width="100%"
              height="23cm"
              style="border: none; max-width: 100%;">

              <!-- Fallback para navegadores que não suportam object -->
              <iframe
                src="${urlDocumento}#toolbar=0&navpanes=0&scrollbar=0&statusbar=0&messages=0&scrollbar=0"
                width="100%"
                height="23cm"
                style="border: none; max-width: 100%;">

                <!-- Fallback final se iframe também não funcionar -->
                <div class="pdf-fallback" style="text-align: center; padding: 4cm; background: white; min-height: 20cm;">
                  <div style="font-size: 4em; margin-bottom: 1cm;">📋</div>
                  <div style="margin: 1cm 0; font-weight: bold; font-size: 14pt;">PDF não pode ser exibido diretamente</div>
                  <div style="font-size: 12pt; margin-bottom: 2cm; color: #666;">
                    O navegador não suporta visualização de PDF incorporada.
                  </div>
                  <a href="${urlDocumento}" target="_blank"
                     style="display: inline-block; padding: 1cm 2cm; background: #007bff; color: white; text-decoration: none; border-radius: 8px; font-size: 12pt;">
                    📄 Abrir PDF em Nova Aba
                  </a>
                  <div style="margin-top: 2cm; font-size: 10pt; color: #999;">
                    <strong>Arquivo:</strong> ${urlDocumento.split('/').pop()}
                  </div>
                </div>

              </iframe>
            </object>
          </div>
        `
      }

      // Se for imagem
      if (urlLower.match(/\.(jpg|jpeg|png|gif|bmp|webp)$/)) {
        return `
          <div class="preview-imagem">
            <div class="imagem-container">
              <img src="${urlDocumento}"
                   alt="Documento anexado"
                   style="max-width: 100%; max-height: 15cm; object-fit: contain; border: 1px solid #ddd;"
                   onerror="this.style.display='none'; this.nextElementSibling.style.display='block';" />
              <div style="display: none; text-align: center; padding: 2cm; background: #f5f5f5;">
                <div class="icone-documento">🖼️</div>
                <div>Erro ao carregar imagem</div>
                <div style="font-size: 9pt; margin-top: 1cm;">${urlDocumento}</div>
              </div>
            </div>
          </div>
        `
      }

      // Outros tipos de arquivo
      return `
        <div class="preview-arquivo">
          <div class="icone-documento">📎</div>
          <div class="tipo-arquivo">Arquivo Anexado</div>
          <div class="url-documento">
            <strong>URL:</strong> <br>
            <span style="font-size: 9pt; word-break: break-all;">${urlDocumento}</span>
          </div>
          <div class="observacao-preview">
            Este arquivo foi anexado ao processo e está disponível na URL acima.
          </div>
        </div>
      `
    },

    gerarPaginasAssinaturasOtimizadas(processo, assinaturas, numeroPaginaInicial) {
      console.log('📝 Gerando páginas de assinaturas otimizadas:', {
        totalAssinaturas: assinaturas.length,
        assinaturasPorPagina: 3,
        paginasNecessarias: Math.ceil(assinaturas.length / 3)
      })

      let htmlCompleto = ''
      let numeroPagina = numeroPaginaInicial

      // Agrupar assinaturas em grupos de 3
      for (let i = 0; i < assinaturas.length; i += 3) {
        const grupoAssinaturas = assinaturas.slice(i, i + 3)

        htmlCompleto += `
          <div class="documento-pagina">
            <div class="folha-numero">Fl. ${String(numeroPagina).padStart(3, '0')}</div>

            <div class="pagina-assinaturas-multiplas">
              <div class="titulo-assinaturas">ASSINATURAS ELETRÔNICAS</div>
        `

        grupoAssinaturas.forEach((assinatura, indexGrupo) => {
          const dataAssinatura = new Date(assinatura?.data_assinatura || new Date())
          const dataFormatada = dataAssinatura.toLocaleDateString('pt-BR')
          const horaFormatada = dataAssinatura.toLocaleTimeString('pt-BR')

          htmlCompleto += `
            <div class="assinatura-item">
              <div class="assinatura-numero">${i + indexGrupo + 1}ª Assinatura:</div>
              <div class="assinatura-texto">
                Documento assinado eletronicamente por <strong>${assinatura?.nome_signatario || 'Nome não informado'}</strong>,
                <strong>${assinatura?.cargo_signatario || 'Cargo não informado'}</strong>, em <strong>${dataFormatada}</strong>,
                às <strong>${horaFormatada}</strong>, conforme horário oficial de Brasília,
                com fundamento no art. 6º, § 1º, do Decreto nº 47.222, de 26 de julho de 2017.
              </div>
            </div>
          `
        })

        htmlCompleto += `
            </div>
          </div>
        `

        numeroPagina++
      }

      return htmlCompleto
    },

    adicionarBotaoDownloadPDF(novaJanela, processo) {
      if (!novaJanela || novaJanela.closed) return

      // Criar container de controles
      const controles = novaJanela.document.createElement('div')
      controles.id = 'controles-pdf'
      controles.style.cssText = `
        position: fixed;
        top: 10px;
        right: 10px;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border: none;
        border-radius: 8px;
        padding: 15px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        z-index: 9999;
        font-family: 'Segoe UI', sans-serif;
        display: flex;
        gap: 10px;
        align-items: center;
      `

      // Botão baixar PDF
      const btnDownload = novaJanela.document.createElement('button')
      btnDownload.innerHTML = 'Baixar'
      btnDownload.style.cssText = `
        background: rgba(255,255,255,0.2);
        color: white;
        border: 1px solid rgba(255,255,255,0.3);
        padding: 8px 15px;
        border-radius: 5px;
        cursor: pointer;
        font-weight: bold;
        font-size: 12px;
        transition: all 0.3s ease;
      `

      btnDownload.onmouseover = () => {
        btnDownload.style.background = 'rgba(255,255,255,0.3)'
      }

      btnDownload.onmouseout = () => {
        btnDownload.style.background = 'rgba(255,255,255,0.2)'
      }

      btnDownload.onclick = () => {
        console.log('💾 Download direto clicado')
        try {
          // Criar blob com o conteúdo HTML
          const htmlContent = novaJanela.document.documentElement.outerHTML
          const blob = new Blob([htmlContent], { type: 'text/html' })
          const url = URL.createObjectURL(blob)

          // Criar link temporário para download
          const link = document.createElement('a')
          link.href = url
          link.download = `Processo_${processo.numero_processo || processo.id}_${new Date().toISOString().slice(0,10)}.html`
          link.style.display = 'none'

          // Adicionar ao DOM, clicar e remover
          document.body.appendChild(link)
          link.click()
          document.body.removeChild(link)

          // Limpar URL
          setTimeout(() => URL.revokeObjectURL(url), 1000)

          console.log('✅ Download HTML iniciado')

        } catch (error) {
          console.error('❌ Erro no download:', error)
          alert('Erro no download. Tente usar Ctrl+P na janela.')
        }
      }

      // Botão fechar
      const btnFechar = novaJanela.document.createElement('button')
      btnFechar.innerHTML = '✕'
      btnFechar.style.cssText = `
        background: rgba(255,0,0,0.7);
        color: white;
        border: none;
        padding: 6px 10px;
        border-radius: 4px;
        cursor: pointer;
        font-weight: bold;
        font-size: 12px;
        transition: all 0.3s ease;
      `

      btnFechar.onmouseover = () => {
        btnFechar.style.background = 'rgba(255,0,0,0.9)'
      }

      btnFechar.onmouseout = () => {
        btnFechar.style.background = 'rgba(255,0,0,0.7)'
      }

      btnFechar.onclick = () => {
        novaJanela.close()
      }

      // Título do documento
      const titulo = novaJanela.document.createElement('span')
      titulo.innerHTML = `Caderno do Processo ${processo.numero_processo || processo.id}`
      titulo.style.cssText = `
        font-size: 11px;
        font-weight: bold;
        margin-right: 10px;
        opacity: 0.9;
      `


      // Adicionar elementos ao container
      controles.appendChild(titulo)
      controles.appendChild(btnDownload)
      controles.appendChild(btnFechar)

      // Adicionar ao documento
      novaJanela.document.body.appendChild(controles)

      // CSS para esconder na impressão
      const estiloPrint = novaJanela.document.createElement('style')
      estiloPrint.textContent = `
        @media print {
          #controles-pdf {
            display: none !important;
          }
        }
      `
      novaJanela.document.head.appendChild(estiloPrint)

      console.log('✅ Controles de download adicionados')
    },

    async enviarParaAnaliseAdministrativa(processo) {
      // Configurar dados do modal de confirmação
      this.dadosConfirmacaoTramitacao = {
        icone: '🚀',
        titulo: 'Enviar para Análise e Aprovação',
        numeroProcesso: processo.numero_processo,
        statusAtual: 'Criado pela CPM',
        proximoStatus: 'Aguardando Aprovação',
        placeholderObservacoes: 'Ex: Processo revisado e aprovado pela equipe técnica...',
        consequencia1: 'O processo será encaminhado para o órgão administrativo',
        consequencia2: 'Você receberá uma notificação por email sobre o andamento',
        consequencia3: 'O status será alterado para "Aguardando Aprovação"',
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

    async abrirModalVincularEdital(processo) {
      this.processoSelecionado = processo
      this.editaisSelecionados = []
      await this.carregarEditaisDisponiveis()
      this.mostrarModalVincularEditaisSelecionados = true
    },

    async carregarEditaisDisponiveis() {
      try {
        this.carregandoEditais = true
        console.log('🔍 Carregando editais publicados disponíveis...')

        const { data, error } = await supabase
          .from('editais')
          .select(`
            id,
            numero,
            descricao,
            status,
            data_publicacao,
            pdf_convertido_url,
            pdf_convertido_nome,
            url_documento,
            tenant_id,
            criado_em
          `)
          .eq('tenant_id', await ProcessosAdministrativosService.getTenantId())
          .eq('status', 'PUBLICADO')
          .order('data_publicacao', { ascending: false })

        if (error) throw error

        this.editaisDisponiveis = data || []
        console.log('✅ Editais carregados:', this.editaisDisponiveis.length)

      } catch (error) {
        console.error('❌ Erro ao carregar editais:', error)
        this.$swal?.fire({
          title: 'Erro',
          text: 'Erro ao carregar editais disponíveis',
          icon: 'error'
        })
      } finally {
        this.carregandoEditais = false
      }
    },

    fecharModalVincularEditais() {
      this.mostrarModalVincularEditaisSelecionados = false
      this.editaisDisponiveis = []
      this.editaisSelecionados = []
      this.processoSelecionado = null
    },

    async confirmarVinculacaoEditais() {
      try {
        if (this.editaisSelecionados.length === 0) {
          this.$swal?.fire({
            title: 'Atenção',
            text: 'Selecione pelo menos um edital para vincular',
            icon: 'warning'
          })
          return
        }

        // Confirmar ação
        const resultado = await this.$swal?.fire({
          title: 'Confirmar Vinculação',
          text: `Vincular ${this.editaisSelecionados.length} edital${this.editaisSelecionados.length !== 1 ? 's' : ''} ao processo ${this.processoSelecionado?.numero_processo}?`,
          icon: 'question',
          showCancelButton: true,
          confirmButtonText: 'Sim, vincular',
          cancelButtonText: 'Cancelar'
        })

        if (!resultado?.isConfirmed) return

        console.log('🔗 Vinculando editais ao processo:', {
          processoId: this.processoSelecionado.id,
          editaisSelecionados: this.editaisSelecionados
        })

        // Salvar vinculação no banco
        await this.salvarVinculacaoEditais(this.processoSelecionado.id, this.editaisSelecionados)

        // Fechar modal
        this.fecharModalVincularEditais()

        // Mostrar sucesso
        this.$swal?.fire({
          title: 'Sucesso!',
          text: `${this.editaisSelecionados.length} edital${this.editaisSelecionados.length !== 1 ? 's' : ''} vinculado${this.editaisSelecionados.length !== 1 ? 's' : ''} com sucesso!`,
          icon: 'success',
          timer: 3000
        })

        // Recarregar dados do processo
        await this.carregarProcessos()

      } catch (error) {
        console.error('❌ Erro ao vincular editais:', error)
        this.$swal?.fire({
          title: 'Erro',
          text: error.message || 'Erro ao vincular editais ao processo',
          icon: 'error'
        })
      }
    },

    async salvarVinculacaoEditais(processoId, editaisIds) {
      try {
        // Criar registros de vinculação na tabela processo_editais
        const tenantId = await ProcessosAdministrativosService.getTenantId()
        const vinculacoes = editaisIds.map(editalId => ({
          processo_id: processoId,
          edital_id: editalId,
          tenant_id: tenantId,
          data_vinculacao: new Date().toISOString()
        }))

        const { error } = await supabase
          .from('processo_editais')
          .insert(vinculacoes)

        if (error) throw error

        console.log('✅ Vinculações salvas com sucesso')

      } catch (error) {
        console.error('❌ Erro ao salvar vinculações:', error)
        throw error
      }
    },

    formatarData(data) {
      if (!data) return 'Não informada'
      return new Date(data).toLocaleDateString('pt-BR')
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
    
    
    // =====================================================
    // GESTÃO DE TRAMITAÇÃO DE PROCESSOS
    // =====================================================
    
    async carregarAcoesDisponiveis() {
      try {
        console.log('🔄 DEBUG - Carregando ações disponíveis para', this.processos.length, 'processos')
        const acoes = {}
        for (const processo of this.processos) {
          const acoesProcesso = await TramitacaoProcessosService.obterAcoesDisponiveis(processo)
          acoes[processo.id] = acoesProcesso
          console.log(`🔍 DEBUG - Processo ${processo.numero_processo} (${processo.status}):`, acoesProcesso)
          
          // Log específico para status submetido_autoridade
          if (processo.status === 'submetido_autoridade') {
            console.log(`🚨 ATENÇÃO - Processo ${processo.numero_processo} com status "submetido_autoridade" tem ${acoesProcesso.length} ações`)
            acoesProcesso.forEach((acao, index) => {
              console.log(`  Ação ${index + 1}:`, acao)
            })
          }
        }
        this.acoesDisponiveis = acoes
        console.log('🔄 DEBUG - Ações disponíveis carregadas:', acoes)
        
        // Forçar atualização da reatividade Vue
        this.$forceUpdate()
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
        } else if (acao.tipo === 'ENVIAR_FLEXIVEL') {
          observacoes = prompt(`Observações para ${acao.descricao}:`) || ''
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
          case 'ENVIAR_FLEXIVEL':
            resultado = await TramitacaoProcessosService.enviarProcessoFlexivel(
              processo.id, 
              acao.statusDestino, 
              acao.tipoFlexivel, 
              observacoes
            )
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
            
            // Definir tipo do documento
            const tipoDocumento = this.isOrgaoAdministrativo() ? 'ASSINADO' : this.tipoDocumentoSelecionado
            
            // Obter próxima numeração sequencial usando o serviço
            // Para documentos ASSINADOS, usar numeração especial para garantir que fiquem no final
            let numero, folha
            if (tipoDocumento === 'ASSINADO') {
              // Documentos assinados recebem numeração alta para ficarem no final
              const timestamp = Date.now()
              numero = 9000 + (timestamp % 1000) // Número alto mas único
              folha = `AS-${String(timestamp % 100).padStart(2, '0')}` // Folha especial
              console.log(`🖊️ Documento ASSINADO - Numeração especial: ${folha} (número ${numero})`)
            } else {
              const result = await NumeracaoDocumentosService.obterProximoNumero(this.processoSelecionado.id)
              numero = result.numero
              folha = result.folha
              console.log(`📋 Numeração normal gerada: ${folha} (número ${numero})`)
            }
            
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
    
    // Métodos para o modal de assinatura digital
    abrirModalAssinatura(processo, callback) {
      console.log('✍️ Abrindo modal de assinatura para processo:', processo.numero_processo)
      
      // Obter informações do usuário atual
      const usuarioAtual = this.$store.state.user || {}
      const nomeUsuario = usuarioAtual.user_metadata?.nome_completo || usuarioAtual.user_metadata?.nome || usuarioAtual.email || ''
      
      // Determinar cargo baseado no perfil do usuário
      let cargoDefault = ''
      const perfilUsuario = this.perfilUsuario?.toLowerCase() || ''
      switch (perfilUsuario) {
        case 'orgao_administrativo':
          cargoDefault = 'Procurador do Estado'
          break
        case 'cpm':
          cargoDefault = 'Coordenador CPM'
          break
        case 'ccl':
          cargoDefault = 'Membro CCL'
          break
        case 'assessoria_juridica':
          cargoDefault = 'Advogado Autárquico'
          break
        default:
          cargoDefault = 'Responsável'
      }
      
      this.dadosAssinatura = {
        numeroProcesso: processo.numero_processo,
        tipoDocumento: this.obterTipoDocumento(processo),
        statusAtual: this.obterNomeStatus(processo.status),
        proximoStatus: this.obterNomeStatus(this.obterProximoStatus(processo)),
        nomeSignatario: nomeUsuario,
        cargoSignatario: cargoDefault
      }
      
      this.callbackAssinatura = callback
      this.mostrarModalAssinatura = true
    },
    
    fecharModalAssinatura() {
      this.mostrarModalAssinatura = false
      this.dadosAssinatura = {}
      this.processandoAssinatura = false
      this.callbackAssinatura = null
    },
    
    async confirmarAssinatura() {
      if (!this.callbackAssinatura) return
      
      // Validações
      if (!this.dadosAssinatura.nomeSignatario.trim()) {
        this.$swal({
          title: '❌ Nome obrigatório',
          text: 'Por favor, informe seu nome completo.',
          icon: 'error'
        })
        return
      }
      
      if (!this.dadosAssinatura.cargoSignatario.trim()) {
        this.$swal({
          title: '❌ Cargo obrigatório',
          text: 'Por favor, informe seu cargo ou função.',
          icon: 'error'
        })
        return
      }
      
      
      this.processandoAssinatura = true
      
      try {
        // Preparar dados da assinatura
        const dadosAssinatura = {
          nomeSignatario: this.dadosAssinatura.nomeSignatario.trim(),
          cargoSignatario: this.dadosAssinatura.cargoSignatario.trim(),
          observacoes: '', // Sem observações por enquanto
          dataAssinatura: new Date().toISOString(),
          hashValidacao: this.gerarHashAssinatura()
        }
        
        // Executar callback com dados da assinatura
        await this.callbackAssinatura(dadosAssinatura)
        
        this.fecharModalAssinatura()
        
        this.$swal({
          title: '✅ Assinatura Confirmada',
          text: 'O documento foi assinado digitalmente com sucesso!',
          icon: 'success',
          timer: 2000
        })
        
      } catch (error) {
        console.error('Erro na assinatura:', error)
        
        let mensagemErro = 'Ocorreu um erro ao processar a assinatura.'
        if (error.message === 'Senha inválida') {
          mensagemErro = 'Senha incorreta. Verifique sua senha de login.'
        }
        
        this.$swal({
          title: '❌ Erro na Assinatura',
          text: mensagemErro,
          icon: 'error'
        })
        
        this.processandoAssinatura = false
      }
    },
    
    // Métodos auxiliares para assinatura
    
    gerarHashAssinatura() {
      // Gerar hash único para validação da assinatura
      const timestamp = new Date().getTime()
      const random = Math.random().toString(36).substr(2, 9)
      const userId = this.$store.state.user?.id || 'unknown'
      return `${timestamp}-${userId}-${random}`
    },
    
    obterTipoDocumento(processo) {
      const tipoProcesso = processo.tipo_processo === 'padronizacao' ? 'Padronização' : 'Despadronização'
      return `Processo Administrativo de ${tipoProcesso}`
    },
    
    obterProximoStatus(processo) {
      // Importar o serviço de tramitação para obter o próximo status
      return TramitacaoProcessosService.obterProximoStatus(processo.status, processo.tipo_processo)
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
    
    // Assinar documento apenas (sem tramitação automática)
    async assinarProcesso(processo) {
      console.log('✍️ Iniciando assinatura digital para:', processo.numero_processo)
      
      // Abrir modal de assinatura digital
      this.abrirModalAssinatura(processo, async (dadosAssinatura) => {
        console.log('✍️ Executando assinatura com dados:', dadosAssinatura)
        
        try {
          // Salvar assinatura no banco de dados
          await this.salvarAssinaturaProcesso(processo.id, dadosAssinatura)
          
          console.log('✅ Processo assinado com sucesso')
          
          // Mostrar mensagem de sucesso
          alert(
            `✅ Assinatura Digital Realizada com Sucesso!\n\n` +
            `Processo: ${processo.numero_processo}\n` +
            `Assinado por: ${dadosAssinatura.nomeSignatario}\n` +
            `Cargo: ${dadosAssinatura.cargoSignatario}\n\n` +
            `A assinatura foi salva no sistema. Use o botão "Enviar" quando estiver pronto para tramitar o processo.`
          )
          
          // Recarregar processos para mostrar a assinatura
          await this.carregarProcessos()
          
          // Atualizar processo no modal se ele estiver aberto
          if (this.processoSelecionado && this.processoSelecionado.id === processo.id) {
            // Buscar o processo atualizado
            const processoAtualizado = this.processos.find(p => p.id === processo.id)
            if (processoAtualizado) {
              this.processoSelecionado = processoAtualizado
            }
          }
          
        } catch (error) {
          console.error('❌ Erro na assinatura:', error)
          throw error
        }
      })
    },
    
    // Assinar documento e enviar para próxima etapa
    async assinarEEnviarProcesso(processo) {
      console.log('✍️ Iniciando processo de assinatura digital para:', processo.numero_processo)
      
      // Abrir modal de assinatura digital
      this.abrirModalAssinatura(processo, async (dadosAssinatura) => {
        console.log('✍️ Executando assinatura com dados:', dadosAssinatura)
        
        try {
          // 1. Salvar assinatura no banco de dados
          await this.salvarAssinaturaProcesso(processo.id, dadosAssinatura)
          
          // 2. Tramitar processo para próxima etapa
          const observacoes = `Documento assinado digitalmente por ${dadosAssinatura.nomeSignatario} (${dadosAssinatura.cargoSignatario}). ${dadosAssinatura.observacoes || ''}`
          
          const resultado = await TramitacaoProcessosService.enviarProcesso(
            processo.id,
            observacoes.trim()
          )
          
          if (resultado.sucesso) {
            console.log('✅ Processo assinado e tramitado com sucesso')
            
            // Recarregar processos
            await this.carregarProcessos()
            this.fecharVisualizacaoProcesso()
          }
          
        } catch (error) {
          console.error('❌ Erro no processo de assinatura:', error)
          throw error
        }
      })
    },
    
    // Salvar assinatura diretamente na coluna do processo
    async salvarAssinaturaProcesso(processoId, dadosAssinatura) {
      try {
        console.log('💾 Salvando assinatura diretamente no processo:', dadosAssinatura)
        
        const user = this.$store.state.user
        
        // Obter o processo completo para saber o status atual
        const processoCompleto = await ProcessosAdministrativosService.obterProcesso(processoId)
        
        if (!processoCompleto) {
          throw new Error('Processo não encontrado')
        }

        // Preparar objeto da assinatura incluindo o status atual
        const novaAssinatura = {
          id: this.gerarHashAssinatura(), // Usar como ID único
          usuario_id: user?.id,
          nome_signatario: dadosAssinatura.nomeSignatario,
          cargo_signatario: dadosAssinatura.cargoSignatario,
          observacoes: dadosAssinatura.observacoes || '',
          data_assinatura: dadosAssinatura.dataAssinatura,
          hash_validacao: dadosAssinatura.hashValidacao,
          ip_assinatura: await this.obterIpUsuario() || '127.0.0.1',
          status_processo: processoCompleto.status // Adicionar o status atual do processo
        }
        
        console.log('📝 Nova assinatura preparada:', novaAssinatura)
        
        // Pegar array de assinaturas existentes ou criar novo
        const assinaturasExistentes = processoCompleto.assinaturas || []
        console.log('📋 Assinaturas existentes:', assinaturasExistentes)
        
        // Adicionar nova assinatura ao array
        const todasAssinaturas = [...assinaturasExistentes, novaAssinatura]
        console.log('📋 Todas as assinaturas após adicionar:', todasAssinaturas)
        
        // Atualizar processo usando o serviço
        await ProcessosAdministrativosService.atualizarProcesso(processoId, {
          assinaturas: todasAssinaturas
        })
        
        console.log('✅ Assinatura salva com sucesso no processo!')
        
      } catch (error) {
        console.error('❌ Erro ao salvar assinatura:', error)
        throw error // Propagar erro para mostrar ao usuário
      }
    },
    
    // Método auxiliar para obter IP (opcional)
    async obterIpUsuario() {
      try {
        const response = await fetch('https://api.ipify.org?format=json')
        const data = await response.json()
        return data.ip || 'unknown'
      } catch (error) {
        return 'unknown'
      }
    },
    
    // Carregar assinaturas digitais do processo
    
    // Inserir assinaturas digitais no PDF gerado
    inserirAssinaturasNoPDF(janelaPDF, assinaturas) {
      try {
        if (!janelaPDF || janelaPDF.closed) {
          console.warn('⚠️ Janela do PDF não está disponível')
          return
        }
        
        const documento = janelaPDF.document
        const containerAssinaturas = documento.getElementById('lista-assinaturas-digitais')
        
        if (!containerAssinaturas) {
          console.warn('⚠️ Container de assinaturas não encontrado no PDF')
          return
        }
        
        // Limpar mensagem de carregamento
        containerAssinaturas.innerHTML = ''
        
        if (!assinaturas || assinaturas.length === 0) {
          containerAssinaturas.innerHTML = ''
          return
        }
        
        // Gerar HTML simplificado das assinaturas
        let htmlAssinaturas = `
          <div class="assinaturas-simples" style="border-top: 1px solid #000; border-bottom: 1px solid #000; padding: 1cm 0;">
            ${assinaturas.map((assinatura, index) => {
              const dataAssinatura = new Date(assinatura.data_assinatura)
              const dataFormatada = dataAssinatura.toLocaleDateString('pt-BR')
              const horaFormatada = dataAssinatura.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
              
              return `
              <div style="margin-bottom: 1cm; padding: 0.5cm 0; border-bottom: ${index < assinaturas.length - 1 ? '1px solid #ccc' : 'none'};">
                <p style="font-size: 11pt; line-height: 1.4; margin: 0; text-align: justify;">
                  Documento assinado eletronicamente por <strong>${assinatura.nome_signatario}</strong>, 
                  <strong>${assinatura.cargo_signatario}</strong>, em <strong>${dataFormatada}</strong>, 
                  às <strong>${horaFormatada}</strong>, conforme horário oficial de Brasília, 
                  com fundamento no art. 6º, § 1º, do Decreto nº 47.222, de 26 de julho de 2025.
                </p>
              </div>`
            }).join('')}
          </div>
        `
        
        // Inserir HTML no container
        containerAssinaturas.innerHTML = htmlAssinaturas
        
        console.log(`✅ ${assinaturas.length} assinaturas inseridas no PDF`)
        
      } catch (error) {
        console.error('❌ Erro ao inserir assinaturas no PDF:', error)
      }
    },
    
    // =====================================================
    // MÉTODOS UTILITÁRIOS
    // =====================================================
    
    // Obter nome legível do status
    obterNomeStatus(status) {
      const nomes = {
        'rascunho': 'Rascunho',
        'aguardando_aprovacao': 'Aguardando Aprovação',
        'criado_cpm': 'Criado pela CPM',
        'criado_cpm_desp': 'Criado pela CPM',
        'aguardando_assinatura_orgao': 'Aguardando Aprovação do Órgão',
        'aguardando_assinatura_orgao_desp': 'Aguardando Aprovação do Órgão',
        'assinado_admin': 'Assinado pelo Órgão Administrativo',
        'julgamento_ccl': 'Em Julgamento pela CCL',
        'aprovado_ccl': 'Aprovado pela CCL',
        'aprovado_juridico': 'Aprovado pela Assessoria Jurídica',
        'edital_publicado': 'Edital Publicado',
        'homologado': 'Processo Homologado',
        'homologado_desp': 'Processo Homologado',
        'finalizado': 'Processo Finalizado',
        'abertura_autorizada_desp': 'Abertura Autorizada',
        'aviso_publicado': 'Aviso Publicado',
        'com_recurso_desp': 'Com Recurso Administrativo',
        'excluindo_marcas': 'Excluindo Marcas',
        
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

.action-btn-signature {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  color: white;
  border: 2px solid #8b5cf6;
}

.action-btn-signature:hover {
  background: linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%);
  border-color: #7c3aed;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(139, 92, 246, 0.3);
}

.action-btn-edital {
  background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
  color: white;
  border: 2px solid #0ea5e9;
}

.action-btn-edital:hover {
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  border-color: #0284c7;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(14, 165, 233, 0.3);
}

.action-btn-signature .btn-icon {
  font-size: 1.2rem;
  animation: signature-pulse 2s infinite;
}

@keyframes signature-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
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

/* ===== MODAL DE ASSINATURA DIGITAL ===== */
.modal-assinatura-digital {
  background: white;
  border-radius: 16px;
  width: 700px;
  max-width: 95vw;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
  animation: slideInUp 0.3s ease-out;
}

.modal-header-assinatura {
  display: flex;
  align-items: center;
  padding: 2rem 2rem 1rem 2rem;
  border-bottom: 1px solid #e2e8f0;
}

.modal-header-assinatura .header-icon {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 1rem;
}

.assinatura-icon {
  font-size: 3rem;
  animation: bounce 2s infinite;
}

.modal-header-assinatura .header-content {
  flex: 1;
}

.modal-header-assinatura h3 {
  margin: 0 0 0.5rem 0;
  color: #2d3748;
  font-size: 1.5rem;
  font-weight: 600;
}

.btn-close-assinatura {
  background: none;
  border: none;
  font-size: 2rem;
  color: #a0aec0;
  cursor: pointer;
  padding: 0.5rem;
  line-height: 1;
  width: 40px;
  height: 40px;
  border-radius: 50%;
}

.btn-close-assinatura:hover {
  color: #e53e3e;
  background: #fed7d7;
}

.modal-body-assinatura {
  padding: 2rem;
}

.documento-info {
  background: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.documento-info h4 {
  margin: 0 0 0.5rem 0;
  color: #2d3748;
  font-size: 1.1rem;
  font-weight: 600;
}

.documento-info p {
  margin: 0.25rem 0;
  color: #4a5568;
  font-size: 0.95rem;
}

.status-info {
  font-weight: 600;
  color: #3182ce !important;
  margin-top: 0.5rem !important;
}

.signatario-section, .cargo-section, .validacao-section, .observacoes-assinatura-section {
  margin-bottom: 1.5rem;
}

.signatario-label, .cargo-label, .senha-label, .obs-assinatura-label {
  display: block;
  margin-bottom: 0.5rem;
  color: #2d3748;
  font-weight: 600;
  font-size: 0.95rem;
}

.signatario-input, .cargo-input, .senha-input {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.2s ease;
  background: white;
}

.signatario-input:focus, .cargo-input:focus, .senha-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.signatario-input:disabled, .cargo-input:disabled, .senha-input:disabled {
  background: #f7fafc;
  color: #a0aec0;
}

.obs-assinatura-textarea {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: all 0.2s ease;
  background: white;
  resize: vertical;
  min-height: 80px;
}

.obs-assinatura-textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.obs-assinatura-textarea:disabled {
  background: #f7fafc;
  color: #a0aec0;
}

.assinatura-aviso {
  display: flex;
  align-items: flex-start;
  padding: 1.5rem;
  background: #fff5f5;
  border: 1px solid #fed7d7;
  border-radius: 12px;
  margin-top: 1.5rem;
}

.assinatura-aviso .aviso-icon {
  font-size: 1.5rem;
  margin-right: 1rem;
  flex-shrink: 0;
}

.assinatura-aviso .aviso-texto {
  flex: 1;
}

.assinatura-aviso .aviso-texto p {
  margin: 0 0 0.5rem 0;
  color: #c53030;
  font-weight: 600;
  font-size: 0.95rem;
}

.assinatura-aviso .aviso-texto ul {
  margin: 0;
  padding-left: 1rem;
  color: #744210;
}

.assinatura-aviso .aviso-texto li {
  margin-bottom: 0.25rem;
  font-size: 0.9rem;
  line-height: 1.5;
}

.modal-footer-assinatura {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  padding: 1.5rem 2rem 2rem 2rem;
  border-top: 1px solid #e2e8f0;
}

.btn-assinar {
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  color: white;
  border: none;
  padding: 0.75rem 2rem;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-width: 180px;
  justify-content: center;
}

.btn-assinar:hover:not(:disabled) {
  background: linear-gradient(135deg, #38a169 0%, #2f855a 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(72, 187, 120, 0.4);
}

.btn-assinar:disabled {
  background: #a0aec0;
  cursor: not-allowed;
  transform: none;
}

/* Responsividade para o modal de assinatura */
@media (max-width: 768px) {
  .modal-assinatura-digital {
    width: 95%;
    margin: 1rem;
  }
  
  .modal-header-assinatura {
    padding: 1.5rem;
    flex-direction: column;
    text-align: center;
  }
  
  .modal-header-assinatura .header-icon {
    margin-right: 0;
    margin-bottom: 1rem;
  }
  
  .modal-header-assinatura h3 {
    font-size: 1.3rem;
    margin: 0.5rem 0;
  }
  
  .modal-footer-assinatura {
    flex-direction: column;
  }
  
  .btn-cancelar, .btn-assinar {
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

.gerar-assinatura-section {
  margin-top: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #dee2e6;
}

.gerar-assinatura-section h5 {
  margin: 0 0 0.5rem 0;
  color: #495057;
  font-size: 1rem;
  font-weight: 600;
}

.gerar-assinatura-section p {
  margin: 0 0 1rem 0;
  color: #6c757d;
  font-size: 0.9rem;
}

.btn-gerar-assinatura {
  background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(40, 167, 69, 0.3);
  display: block;
  margin-bottom: 0.5rem;
}

.btn-gerar-assinatura:hover {
  background: linear-gradient(135deg, #218838 0%, #1e7e34 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(40, 167, 69, 0.4);
}

.btn-gerar-assinatura:active {
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(40, 167, 69, 0.3);
}

.gerar-assinatura-section small {
  color: #6c757d;
  font-size: 0.8rem;
  font-style: italic;
}

/* Lembrete visual para tramitação CCL */
.tramitar-reminder {
  background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%);
  border: 2px solid #f39c12;
  border-radius: 8px;
  padding: 12px;
  margin-top: 12px;
  box-shadow: 0 3px 6px rgba(243, 156, 18, 0.2);
  animation: pulse-reminder 2.5s infinite;
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  max-width: 280px;
}

.reminder-icon {
  font-size: 1.5rem;
  color: #D35400;
  flex-shrink: 0;
}

.reminder-text {
  font-size: 0.9rem;
  color: #8B4513;
  line-height: 1.4;
  flex: 1;
}

.reminder-text strong {
  color: #D35400;
  font-size: 1rem;
  display: block;
  margin-bottom: 2px;
}

.reminder-text small {
  color: #A0522D;
  font-size: 0.8rem;
  font-style: italic;
}

@keyframes pulse-reminder {
  0% {
    transform: scale(1);
    box-shadow: 0 3px 6px rgba(243, 156, 18, 0.2);
  }
  50% {
    transform: scale(1.02);
    box-shadow: 0 5px 12px rgba(243, 156, 18, 0.35);
  }
  100% {
    transform: scale(1);
    box-shadow: 0 3px 6px rgba(243, 156, 18, 0.2);
  }
}

/* Ajustar layout das ações para acomodar o lembrete */
.processo-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  justify-content: flex-start;
  margin-top: 1rem;
  align-items: flex-start;
}

/* Fazer o lembrete ocupar toda a largura quando presente */
.processo-actions .tramitar-reminder {
  flex-basis: 100%;
  order: 10; /* Coloca o lembrete no final */
}

/* ========================================= */
/* MODAL DE VINCULAR EDITAIS SELECIONADOS */
/* ========================================= */

.modal-vincular-editais {
  background: white;
  border-radius: 12px;
  width: 95%;
  max-width: 800px;
  max-height: 90vh;
  overflow: hidden;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
  display: flex;
  flex-direction: column;
}

.modal-vincular-editais .modal-body {
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem;
  max-height: 60vh;
}

.loading-editais {
  text-align: center;
  padding: 3rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.loading-spinner {
  border: 4px solid #f3f4f6;
  border-top: 4px solid #3b82f6;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

.editais-info {
  background: #f8fafc;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
  border-left: 4px solid #3b82f6;
}

.editais-info p {
  margin: 0.25rem 0;
  color: #475569;
}

.sem-editais {
  text-align: center;
  padding: 3rem;
  color: #64748b;
}

.sem-editais-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.sem-editais h4 {
  margin: 0 0 1rem;
  color: #475569;
}

.editais-lista {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.edital-item {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 1.5rem;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  transition: all 0.2s ease;
  background: white;
}

.edital-item:hover {
  border-color: #3b82f6;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.1);
}

.edital-checkbox {
  position: relative;
  flex-shrink: 0;
}

.checkbox-edital {
  appearance: none;
  width: 20px;
  height: 20px;
  border: 2px solid #d1d5db;
  border-radius: 4px;
  background: white;
  cursor: pointer;
  transition: all 0.2s ease;
}

.checkbox-edital:checked {
  background: #3b82f6;
  border-color: #3b82f6;
}

.checkbox-edital:checked::after {
  content: '✓';
  position: absolute;
  top: 1px;
  left: 3px;
  color: white;
  font-size: 14px;
  font-weight: bold;
}

.checkbox-label {
  position: absolute;
  top: 0;
  left: 0;
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.edital-content {
  flex: 1;
}

.edital-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.edital-header h4 {
  margin: 0;
  color: #1f2937;
  font-size: 1.1rem;
}

.edital-status {
  background: #10b981;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 15px;
  font-size: 0.85rem;
  font-weight: 500;
}

.edital-info {
  color: #6b7280;
  font-size: 0.9rem;
}

.edital-info p {
  margin: 0.25rem 0;
}

.arquivo-disponivel {
  color: #10b981;
  font-weight: 500;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
  background: #f8fafc;
}

.btn-primary:disabled {
  background: #9ca3af;
  cursor: not-allowed;
  opacity: 0.6;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* ========================================= */
/* ESTILOS PARA EDITAIS ANEXADOS NO PDF */
/* ========================================= */

.edital-anexado-container {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.edital-header-info {
  background: #f8fafc;
  padding: 1rem;
  border-radius: 8px;
  border-left: 4px solid #0ea5e9;
  margin-bottom: 1rem;
}

.edital-header-info h3 {
  margin: 0 0 0.5rem;
  color: #1e40af;
  font-size: 1.2rem;
}

.edital-header-info p {
  margin: 0.25rem 0;
  color: #475569;
  font-size: 0.9rem;
}

.edital-header-info strong {
  color: #1e293b;
}

/* Ajustes específicos para editais em páginas completas */
.pdf-pagina-completa .edital-anexado-container {
  padding: 0;
  background: white;
}

.pdf-pagina-completa .edital-header-info {
  position: absolute;
  top: 0.5cm;
  left: 0.5cm;
  right: 0.5cm;
  z-index: 10;
  background: rgba(248, 250, 252, 0.95);
  backdrop-filter: blur(5px);
  border: 1px solid #e2e8f0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.pdf-pagina-completa .preview-pdf-pagina-completa {
  margin-top: 3cm;
  height: calc(100% - 3cm);
}

</style>