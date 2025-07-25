<template>
  <div class="processos-container">
    <div class="content-wrapper">
      <aside class="sidebar">
        <div class="filter-section">
          <h3>🔍 Filtros Avançados</h3>
          
          <div class="filter-group">
            <label>📁 Categoria</label>
            <select v-model="filtroCategoria" @change="filtrarDocumentos">
              <option value="">Todas as categorias</option>
              <option value="manual">📖 Manuais</option>
              <option value="template">📄 Templates</option>
              <option value="instrucao">📋 Instruções</option>
              <option value="normativa">⚖️ Normativas</option>
              <option value="formulario">📝 Formulários</option>
            </select>
          </div>

          <div class="filter-group">
            <label>🔎 Buscar Documentos</label>
            <input 
              type="text" 
              v-model="termoBusca" 
              @input="filtrarDocumentos"
              placeholder="Digite palavras-chave..."
              class="search-input"
            >
          </div>

          <div class="filter-group">
            <label>📅 Período</label>
            <select v-model="filtroPeriodo" @change="filtrarDocumentos">
              <option value="">Todos os períodos</option>
              <option value="ultima_semana">Última semana</option>
              <option value="ultimo_mes">Último mês</option>
              <option value="ultimos_3_meses">Últimos 3 meses</option>
              <option value="ultimo_ano">Último ano</option>
            </select>
          </div>

          <div class="filter-group">
            <label>📊 Ordenar por</label>
            <select v-model="ordenacao" @change="filtrarDocumentos">
              <option value="data_desc">Mais recentes</option>
              <option value="data_asc">Mais antigos</option>
              <option value="titulo_asc">A-Z (Título)</option>
              <option value="titulo_desc">Z-A (Título)</option>
              <option value="categoria">Por categoria</option>
            </select>
          </div>

          <div class="stats-section">
            <h4>📈 Estatísticas</h4>
            <div class="stats-item">
              <span class="stats-label">Total:</span>
              <span class="stats-value">{{ documentos.length }}</span>
            </div>
            <div class="stats-item">
              <span class="stats-label">Filtrados:</span>
              <span class="stats-value">{{ documentosFiltrados.length }}</span>
            </div>
          </div>
        </div>

        <div class="upload-section" v-if="podeUpload">
          <h3>Adicionar Documento</h3>
          <button @click="abrirModalUpload" class="btn-upload">
            📄 Novo Documento
          </button>
        </div>
      </aside>

      <section class="documents-section">
        <div class="documents-header">
          <h3>Documentos ({{ documentosFiltrados.length }})</h3>
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
          <p>Carregando documentos...</p>
        </div>

        <div v-else-if="documentosFiltrados.length === 0" class="empty-state">
          <div class="empty-icon">📂</div>
          <h4>Nenhum documento encontrado</h4>
          <p>Tente ajustar os filtros ou adicione novos documentos</p>
        </div>

        <div v-else class="documents-container" :class="visualizacao">
          <div 
            v-for="documento in documentosFiltrados" 
            :key="documento.id"
            @click="visualizarDocumento(documento)"
            class="document-card"
          >
            <div class="document-icon">
              {{ getIconeCategoria(documento.categoria) }}
            </div>
            <div class="document-info">
              <h4>{{ documento.titulo }}</h4>
              <p class="document-desc">{{ documento.descricao }}</p>
              <div class="document-meta">
                <span class="categoria">{{ getNomeCategoria(documento.categoria) }}</span>
                <span class="data">{{ formatarData(documento.criado_em) }}</span>
              </div>
            </div>
            <div class="document-actions">
              <button @click.stop="baixarDocumento(documento)" class="btn-action">
                ⬇️
              </button>
              <button v-if="podeEditar" @click.stop="editarDocumento(documento)" class="btn-action">
                ✏️
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>

    <!-- Modal de Upload -->
    <div v-if="modalUploadAberto" class="modal-overlay" @click="fecharModalUpload">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>Adicionar Documento</h3>
          <button @click="fecharModalUpload" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="uploadDocumento">
            <div class="form-group">
              <label>Título *</label>
              <input type="text" v-model="novoDocumento.titulo" required>
            </div>
            
            <div class="form-group">
              <label>Descrição</label>
              <textarea v-model="novoDocumento.descricao" rows="3"></textarea>
            </div>
            
            <div class="form-group">
              <label>Categoria *</label>
              <select v-model="novoDocumento.categoria" required>
                <option value="">Selecione uma categoria</option>
                <option value="manual">Manual</option>
                <option value="template">Template</option>
                <option value="instrucao">Instrução</option>
                <option value="normativa">Normativa</option>
                <option value="formulario">Formulário</option>
              </select>
            </div>
            
            <div class="form-group">
              <label>Arquivo *</label>
              <input 
                type="file" 
                @change="selecionarArquivo" 
                accept=".pdf,.doc,.docx,.xlsx,.xls"
                required
              >
              <small>Formatos aceitos: PDF, DOC, DOCX, XLS, XLSX</small>
            </div>
            
            <div class="form-actions">
              <button type="button" @click="fecharModalUpload" class="btn-secondary">
                Cancelar
              </button>
              <button type="submit" :disabled="enviandoUpload" class="btn-primary">
                {{ enviandoUpload ? 'Enviando...' : 'Salvar' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Modal de Visualização Expandido -->
    <div v-if="documentoSelecionado" class="modal-overlay" @click="fecharVisualizacao">
      <div class="modal modal-large" @click.stop>
        <div class="modal-header">
          <div class="document-title-section">
            <div class="document-icon-large">
              {{ getIconeCategoria(documentoSelecionado.categoria) }}
            </div>
            <div>
              <h3>{{ documentoSelecionado.titulo }}</h3>
              <span class="document-category-badge">{{ getNomeCategoria(documentoSelecionado.categoria) }}</span>
            </div>
          </div>
          <button @click="fecharVisualizacao" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <div class="document-viewer-container">
            <div class="document-details-panel">
              <h4>📋 Informações do Documento</h4>
              <div class="detail-item">
                <strong>📝 Descrição:</strong>
                <p>{{ documentoSelecionado.descricao || 'Sem descrição disponível' }}</p>
              </div>
              <div class="detail-item">
                <strong>📁 Categoria:</strong>
                <span class="category-pill">{{ getNomeCategoria(documentoSelecionado.categoria) }}</span>
              </div>
              <div class="detail-item">
                <strong>📅 Data de Criação:</strong>
                <span>{{ formatarData(documentoSelecionado.criado_em) }}</span>
              </div>
              <div class="detail-item" v-if="documentoSelecionado.tamanho_arquivo">
                <strong>💾 Tamanho:</strong>
                <span>{{ formatarTamanho(documentoSelecionado.tamanho_arquivo) }}</span>
              </div>
              <div class="detail-item" v-if="documentoSelecionado.tipo_mime">
                <strong>📄 Tipo:</strong>
                <span>{{ documentoSelecionado.tipo_mime }}</span>
              </div>
              
              <div class="document-actions-panel">
                <button @click="baixarDocumento(documentoSelecionado)" class="btn-primary btn-large">
                  ⬇️ Baixar Documento
                </button>
                <button v-if="podeEditar" @click="editarDocumento(documentoSelecionado)" class="btn-secondary">
                  ✏️ Editar Informações
                </button>
                <button @click="compartilharDocumento(documentoSelecionado)" class="btn-secondary">
                  🔗 Compartilhar
                </button>
              </div>
            </div>
            
            <div class="document-preview-panel">
              <h4>👁️ Visualização do Documento</h4>
              <div class="preview-container">
                <div v-if="documentoSelecionado.categoria === 'manual'" class="manual-preview">
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
                <div v-else-if="documentoSelecionado.categoria === 'normativa' && documentoSelecionado.titulo.includes('Lei 14.133')" class="lei-preview">
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
                <div v-else class="document-placeholder">
                  <div class="placeholder-icon">{{ getIconeCategoria(documentoSelecionado.categoria) }}</div>
                  <h5>{{ documentoSelecionado.titulo }}</h5>
                  <p>Visualização completa disponível após o download</p>
                  <small>Tipo: {{ documentoSelecionado.tipo_mime || 'Documento' }}</small>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import DocumentosAdministrativosService from '../../services/documentosAdministrativos'

export default {
  name: 'ProcessosAdministrativosComponent',
  data() {
    return {
      documentos: [],
      documentosFiltrados: [],
      carregando: true,
      
      filtroCategoria: '',
      termoBusca: '',
      filtroPeriodo: '',
      ordenacao: 'data_desc',
      visualizacao: 'grid',
      secaoAtiva: 0,
      secaoLeiAtiva: 0,
      leiSections: [
        { icone: '🎯', titulo: 'O que Mudou' },
        { icone: '📋', titulo: 'Modalidades' },
        { icone: '⏰', titulo: 'Prazos' },
        { icone: '🎯', titulo: 'Pré-qualificação' },
        { icone: '📊', titulo: 'Critérios' },
        { icone: '🔍', titulo: 'Transparência' }
      ],
      manuaisSections: [
        { icone: '🎯', titulo: 'O que é o Sistema' },
        { icone: '📊', titulo: 'Dashboard CPM' },
        { icone: '⚖️', titulo: 'Dashboard CCL' },
        { icone: '📝', titulo: 'DCB' },
        { icone: '📊', titulo: 'RDM' },
        { icone: '📚', titulo: 'Catálogo' }
      ],
      
      modalUploadAberto: false,
      enviandoUpload: false,
      documentoSelecionado: null,
      
      novoDocumento: {
        titulo: '',
        descricao: '',
        categoria: '',
        arquivo: null
      },
      
      podeUpload: true,
      podeEditar: true
    }
  },
  
  async mounted() {
    await this.carregarDocumentos()
  },
  
  methods: {
    async carregarDocumentos() {
      try {
        this.carregando = true
        this.documentos = await DocumentosAdministrativosService.listarDocumentos()
        this.filtrarDocumentos()
      } catch (error) {
        console.error('Erro ao carregar documentos:', error)
        this.documentos = []
        alert('Erro ao carregar documentos. Tente novamente.')
      } finally {
        this.carregando = false
      }
    },
    
    async filtrarDocumentos() {
      try {
        const filtros = {}
        if (this.filtroCategoria) {
          filtros.categoria = this.filtroCategoria
        }
        if (this.termoBusca) {
          filtros.busca = this.termoBusca
        }
        
        this.documentosFiltrados = await DocumentosAdministrativosService.buscarDocumentos(
          this.termoBusca, 
          filtros
        )
      } catch (error) {
        console.error('Erro ao filtrar documentos:', error)
        // Fallback para filtro local
        let filtrados = [...this.documentos]
        
        if (this.filtroCategoria) {
          filtrados = filtrados.filter(doc => doc.categoria === this.filtroCategoria)
        }
        
        if (this.termoBusca) {
          const termo = this.termoBusca.toLowerCase()
          filtrados = filtrados.filter(doc => 
            doc.titulo.toLowerCase().includes(termo) ||
            (doc.descricao && doc.descricao.toLowerCase().includes(termo))
          )
        }
        
        this.documentosFiltrados = filtrados
      }
    },
    
    getIconeCategoria(categoria) {
      return DocumentosAdministrativosService.obterIconeCategoria(categoria)
    },
    
    getNomeCategoria(categoria) {
      return DocumentosAdministrativosService.obterNomeCategoria(categoria)
    },
    
    formatarData(data) {
      return new Date(data).toLocaleDateString('pt-BR')
    },
    
    abrirModalUpload() {
      this.modalUploadAberto = true
      this.novoDocumento = {
        titulo: '',
        descricao: '',
        categoria: '',
        arquivo: null
      }
    },
    
    fecharModalUpload() {
      this.modalUploadAberto = false
    },
    
    selecionarArquivo(event) {
      const arquivo = event.target.files[0]
      if (arquivo) {
        try {
          DocumentosAdministrativosService.validarArquivo(arquivo)
          this.novoDocumento.arquivo = arquivo
        } catch (error) {
          alert(error.message)
          event.target.value = ''
        }
      }
    },
    
    async uploadDocumento() {
      if (!this.novoDocumento.arquivo) {
        alert('Selecione um arquivo para fazer upload')
        return
      }
      
      try {
        this.enviandoUpload = true
        
        // Validar arquivo
        DocumentosAdministrativosService.validarArquivo(this.novoDocumento.arquivo)
        
        // Upload do arquivo
        const resultadoUpload = await DocumentosAdministrativosService.uploadArquivo(
          this.novoDocumento.arquivo
        )
        
        // Criar documento com metadados
        await DocumentosAdministrativosService.criarDocumento({
          titulo: this.novoDocumento.titulo,
          descricao: this.novoDocumento.descricao,
          categoria: this.novoDocumento.categoria,
          nome_arquivo: resultadoUpload.nome_original,
          tamanho_arquivo: resultadoUpload.tamanho,
          tipo_mime: resultadoUpload.tipo_mime,
          url_arquivo: resultadoUpload.url
        })
        
        await this.carregarDocumentos()
        this.fecharModalUpload()
        alert('Documento enviado com sucesso!')
        
      } catch (error) {
        console.error('Erro no upload:', error)
        alert(`Erro ao fazer upload: ${error.message}`)
      } finally {
        this.enviandoUpload = false
      }
    },
    
    visualizarDocumento(documento) {
      this.documentoSelecionado = documento
    },
    
    fecharVisualizacao() {
      this.documentoSelecionado = null
    },
    
    async baixarDocumento(documento) {
      try {
        if (!documento.url_arquivo) {
          alert('URL do arquivo não disponível')
          return
        }
        
        const blob = await DocumentosAdministrativosService.baixarArquivo(documento.url_arquivo)
        
        // Criar link temporário para download
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.style.display = 'none'
        a.href = url
        a.download = documento.nome_arquivo || 'documento'
        document.body.appendChild(a)
        a.click()
        window.URL.revokeObjectURL(url)
        document.body.removeChild(a)
        
      } catch (error) {
        console.error('Erro no download:', error)
        alert(`Erro ao baixar arquivo: ${error.message}`)
      }
    },
    
    async editarDocumento(documento) {
      // Por enquanto, permitir apenas edição de título e descrição
      const novoTitulo = prompt('Novo título:', documento.titulo)
      if (novoTitulo && novoTitulo !== documento.titulo) {
        try {
          await DocumentosAdministrativosService.atualizarDocumento(documento.id, {
            titulo: novoTitulo
          })
          await this.carregarDocumentos()
          alert('Documento atualizado com sucesso!')
        } catch (error) {
          console.error('Erro ao editar:', error)
          alert(`Erro ao editar documento: ${error.message}`)
        }
      }
    },
    
    formatarTamanho(bytes) {
      if (!bytes) return 'N/A'
      const sizes = ['Bytes', 'KB', 'MB', 'GB']
      if (bytes === 0) return '0 Bytes'
      const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)))
      return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i]
    },
    
    compartilharDocumento(documento) {
      const url = `${window.location.origin}/processos-administrativos?doc=${documento.id}`
      navigator.clipboard.writeText(url).then(() => {
        alert('Link copiado para a área de transferência!')
      }).catch(() => {
        prompt('Link para compartilhar:', url)
      })
    },
    
    visualizarDocumento(documento) {
      this.documentoSelecionado = documento
      this.secaoAtiva = 0 // Reset para a primeira seção quando abrir um novo documento
      this.secaoLeiAtiva = 0 // Reset para a primeira seção da lei
    }
  }
}
</script>

<style scoped>
.processos-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}


.content-wrapper {
  display: grid;
  grid-template-columns: 350px 1fr;
  gap: 0;
  height: 100vh;
  overflow: hidden;
}

.sidebar {
  background: white;
  padding: 1.5rem;
  border-right: 1px solid #e2e8f0;
  height: 100vh;
  overflow-y: auto;
}

.filter-section h3,
.upload-section h3 {
  margin-bottom: 1rem;
  color: #2d3748;
  font-size: 1.1rem;
}

.filter-group {
  margin-bottom: 1rem;
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

.documents-section {
  background: white;
  padding: 1.5rem;
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.documents-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.documents-header h3 {
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

.documents-container {
  flex: 1;
  overflow-y: auto;
  padding-right: 0.5rem;
}

.documents-container.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

.documents-container.list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.document-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.document-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.document-icon {
  font-size: 2rem;
  flex-shrink: 0;
}

.document-info {
  flex: 1;
}

.document-info h4 {
  margin: 0 0 0.5rem;
  color: #2d3748;
  font-size: 1rem;
}

.document-desc {
  margin: 0 0 0.75rem;
  color: #718096;
  font-size: 0.9rem;
  line-height: 1.4;
}

.document-meta {
  display: flex;
  gap: 1rem;
  font-size: 0.8rem;
}

.categoria {
  background: #e2e8f0;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  color: #4a5568;
}

.data {
  color: #a0aec0;
}

.document-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.btn-action {
  width: 2rem;
  height: 2rem;
  border: none;
  background: #f7fafc;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.btn-action:hover {
  background: #e2e8f0;
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

.document-details {
  margin-bottom: 1.5rem;
}

.document-details p {
  margin-bottom: 0.75rem;
  line-height: 1.5;
}

.document-title-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.document-icon-large {
  font-size: 2.5rem;
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f7fafc;
  border-radius: 12px;
}

.document-category-badge {
  background: #e2e8f0;
  color: #4a5568;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.document-viewer-container {
  display: grid;
  grid-template-columns: 350px 1fr;
  gap: 2rem;
  height: 100%;
}

.document-details-panel {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1.5rem;
  height: fit-content;
}

.document-details-panel h4 {
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

.document-actions-panel {
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

.document-preview-panel {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
  overflow-y: auto;
}

.document-preview-panel h4 {
  margin: 0 0 1.5rem 0;
  color: #2d3748;
  font-size: 1.1rem;
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

.document-placeholder {
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
</style>