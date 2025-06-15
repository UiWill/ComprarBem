<template>
  <div class="analise-container">
    <div v-if="loading" class="loading">
      <p>Carregando...</p>
    </div>
    
    <div v-else-if="produto" class="produto-analise">
      <h2>Análise de Produto</h2>
      
      <div class="produto-info">
        <div class="produto-header">
          <h3>{{ produto.nome }}</h3>
          <div class="produto-actions">
            <button 
              v-if="produto.status === 'pendente'" 
              @click="solicitarDiligencia(produto.id)" 
              class="btn-diligencia"
            >
              🔍 Solicitar Diligência
            </button>
            <button 
              v-if="produto.status === 'diligencia'" 
              @click="visualizarDiligencias(produto.id)" 
              class="btn-ver-diligencias"
            >
              📋 Ver Diligências
            </button>
          </div>
        </div>
        
        <div class="info-grid">
          <div class="info-item">
            <strong>Marca:</strong> {{ produto.marca }}
          </div>
          <div class="info-item">
            <strong>Modelo:</strong> {{ produto.modelo }}
          </div>
          <div class="info-item">
            <strong>Fabricante:</strong> {{ produto.fabricante }}
          </div>
          <div class="info-item">
            <strong>CNPJ:</strong> {{ produto.cnpj }}
          </div>
          <div class="info-item">
            <strong>Origem:</strong> {{ produto.origem || 'Não informada' }}
          </div>
          <div class="info-item">
            <strong>Registro na Anvisa/MS:</strong> {{ produto.registro_anvisa || 'Não informado' }}
          </div>
          <div class="info-item">
            <strong>CBPF:</strong> {{ produto.cbpf || 'Não informado' }}
          </div>
          <div class="info-item">
            <strong>Código do Material:</strong> {{ produto.codigo_material || 'Não informado' }}
          </div>
          <div class="info-item full-width">
            <strong>Descrição:</strong> {{ produto.descricao || 'Não informada' }}
          </div>
          <div class="info-item">
            <strong>Status Atual:</strong> 
            <span class="status-pill" :class="getStatusClass(produto.status)">
              {{ produto.status }}
            </span>
          </div>
          <div class="info-item">
            <strong>Data de Cadastro:</strong> {{ formatDate(produto.criado_em) }}
          </div>
        </div>
      </div>
      
      <div class="documentos-section" v-if="documentos.length > 0">
        <h3>Documentos</h3>
        <div class="documentos-list">
          <div 
            v-for="doc in documentos" 
            :key="doc.id" 
            class="documento-item"
          >
            <div class="doc-icon">📄</div>
            <div class="doc-info">
              <p class="doc-name">{{ doc.nome }}</p>
              <p class="doc-type">{{ doc.tipo }}</p>
            </div>
            <a :href="doc.arquivo_url" target="_blank" class="doc-action">Visualizar</a>
          </div>
        </div>
      </div>
      
      <div class="analise-form">
        <h3>Parecer Técnico</h3>
        
        <form @submit.prevent="salvarAnalise">
          <div class="form-group">
            <label for="parecer">Observações / Parecer</label>
            <textarea 
              id="parecer" 
              v-model="analise.parecer" 
              rows="4" 
              required
            ></textarea>
          </div>
          
          <div class="form-group">
            <label>Decisão</label>
            <div class="radio-group">
              <label class="radio-label">
                <input 
                  type="radio" 
                  v-model="analise.status" 
                  value="aprovado"
                  required
                >
                Aprovar
              </label>
              <label class="radio-label">
                <input 
                  type="radio" 
                  v-model="analise.status" 
                  value="reprovado"
                  required
                >
                Reprovar
              </label>
            </div>
          </div>
          
          <div class="form-group" v-if="analise.status === 'reprovado'">
            <label for="motivacao">Motivação da Reprovação</label>
            <textarea 
              id="motivacao" 
              v-model="analise.motivacao" 
              rows="6" 
              placeholder="Descreva detalhadamente os motivos que levaram à reprovação deste produto"
              required
            ></textarea>
            <small class="helper-text">Este campo será exibido ao fornecedor para justificar a reprovação do produto</small>
          </div>
          
          <div class="form-actions">
            <button type="submit" class="btn-primary" :disabled="submitting">
              {{ submitting ? 'Salvando...' : 'Salvar Análise' }}
            </button>
            <button type="button" class="btn-secondary" @click="voltar">
              Voltar
            </button>
          </div>
        </form>
      </div>
      
      <div class="analises-anteriores" v-if="analisesAnteriores.length > 0">
        <h3>Análises Anteriores</h3>
        <div class="analise-historico" v-for="item in analisesAnteriores" :key="item.id">
          <div class="analise-header">
            <span class="status-pill" :class="getStatusClass(item.status)">{{ item.status }}</span>
            <span class="analise-data">{{ formatDate(item.criado_em) }}</span>
          </div>
          <div class="analise-conteudo">
            <p>{{ item.parecer }}</p>
            <div v-if="item.status === 'reprovado' && item.motivacao" class="motivacao-reprovacao">
              <h4>Motivação da Reprovação:</h4>
              <p>{{ item.motivacao }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div v-else class="not-found">
      <p>Produto não encontrado ou você não tem permissão para visualizá-lo.</p>
      <button class="btn-secondary" @click="voltar">Voltar</button>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { enviarEmailDiligencia } from '@/services/emailService'

export default {
  name: 'AnaliseProduto',
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      produto: null,
      documentos: [],
      analisesAnteriores: [],
      analise: {
        parecer: '',
        status: '',
        motivacao: ''
      },
      loading: true,
      submitting: false
    }
  },
  created() {
    this.carregarDados()
  },
  methods: {
    async carregarDados() {
      try {
        this.loading = true
        
        // Carregar produto
        const { data: produto, error: produtoError } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', this.id)
          .single()
        
        if (produtoError) throw produtoError
        
        this.produto = produto
        
        // Carregar documentos
        const { data: documentos, error: docsError } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', this.id)
        
        if (docsError) throw docsError
        
        this.documentos = documentos || []
        
        // Carregar análises anteriores
        const { data: analises, error: analisesError } = await supabase
          .from('analises')
          .select('*')
          .eq('produto_id', this.id)
          .order('criado_em', { ascending: false })
        
        if (analisesError) throw analisesError
        
        this.analisesAnteriores = analises || []
        
      } catch (error) {
        console.error('Erro ao carregar dados:', error)
        alert('Erro ao carregar dados do produto. Por favor, tente novamente.')
      } finally {
        this.loading = false
      }
    },
    async salvarAnalise() {
      try {
        this.submitting = true
        
        if (this.analise.status === 'reprovado' && !this.analise.motivacao) {
          this.$swal({
            icon: 'error',
            title: 'Campo obrigatório',
            text: 'É necessário preencher a motivação da reprovação'
          });
          this.submitting = false;
          return;
        }
        
        const { data: authData } = await supabase.auth.getSession()
        const authUser = authData?.session?.user
        
        let avaliadorId;
        
        if (authUser) {
          console.log('Usuário autenticado:', authUser.email)
          
          const { data: usuarioData, error: usuarioError } = await supabase
            .from('usuarios')
            .select('id')
            .eq('email', authUser.email)
            .maybeSingle()
          
          if (usuarioError) {
            console.error('Erro ao buscar ID do usuário:', usuarioError)
          }
          
          if (usuarioData?.id) {
            console.log('ID do usuário encontrado na tabela usuarios:', usuarioData.id)
            avaliadorId = usuarioData.id
          } else {
            console.warn('Usuário não encontrado na tabela, gerando UUID')
            avaliadorId = this.gerarUUID()
            
            const { error: insertError } = await supabase
              .from('usuarios')
              .insert({
                id: avaliadorId,
                email: authUser.email,
                nome: authUser.email.split('@')[0],
                tenant_id: this.produto.tenant_id,
                tipo: 'avaliador',
                ativo: true
              })
            
            if (insertError) {
              console.error('Erro ao criar usuário automaticamente:', insertError)
            }
          }
        } else {
          console.warn('Nenhum usuário autenticado, gerando UUID')
          avaliadorId = this.gerarUUID()
        }
        
        console.log('Salvando análise com avaliador_id:', avaliadorId)
        
        const dadosAnalise = {
          produto_id: this.id,
          tenant_id: this.produto.tenant_id,
          avaliador_id: avaliadorId,
          parecer: this.analise.parecer,
          status: this.analise.status
        };
        
        if (this.analise.status === 'reprovado') {
          dadosAnalise.motivacao = this.analise.motivacao;
        }
        
        const { error: analiseError } = await supabase
          .from('analises')
          .insert(dadosAnalise)
        
        if (analiseError) {
          console.error('Erro detalhado ao salvar análise:', analiseError)
          throw new Error(`Erro ao salvar análise: ${analiseError.message}`)
        }
        
        const { error: produtoError } = await supabase
          .from('produtos')
          .update({ status: this.analise.status })
          .eq('id', this.id)
        
        if (produtoError) throw produtoError
        
        this.$swal({
          icon: 'success',
          title: 'Análise salva com sucesso!',
          showConfirmButton: false,
          timer: 1500
        })
        
        await this.carregarDados()
        
        this.analise = {
          parecer: '',
          status: '',
          motivacao: ''
        }
        
      } catch (error) {
        console.error('Erro ao salvar análise:', error)
        
        let mensagemErro = 'Erro ao salvar análise.'
        
        if (error.message && error.message.includes('uuid')) {
          mensagemErro = 'Erro no formato de identificação. Este problema foi corrigido, tente novamente.'
        } else if (error.message) {
          mensagemErro = error.message
        }
        
        this.$swal({
          icon: 'error',
          title: 'Erro ao processar análise',
          text: mensagemErro
        })
      } finally {
        this.submitting = false
      }
    },
    formatDate(dateString) {
      if (!dateString) return ''
      const date = new Date(dateString)
      return date.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    getStatusClass(status) {
      switch (status) {
        case 'aprovado': return 'status-aprovado'
        case 'pendente': return 'status-pendente'
        case 'reprovado': return 'status-reprovado'
        default: return ''
      }
    },
    voltar() {
      this.$router.push('/dashboard')
    },
    gerarUUID() {
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0, 
              v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
      });
    },
    
    async solicitarDiligencia(produtoId) {
      try {
        const { value: diligenciaData } = await this.$swal({
          title: '🔍 Solicitar Diligência',
          html: `
            <div style="text-align: left; padding: 10px;">
              <div style="margin-bottom: 20px;">
                <label for="tipo_diligencia" style="display: block; font-weight: bold; margin-bottom: 8px; color: #2c3e50;">
                  📋 Tipo de Diligência:
                </label>
                <select id="tipo_diligencia" class="swal2-input" style="width: 100%; font-size: 14px;">
                  <option value="">Selecione o tipo</option>
                  <option value="DOCUMENTACAO_FALTANTE">📄 Documentação Faltante</option>
                  <option value="AMOSTRA_INADEQUADA">🔬 Amostra Inadequada</option>
                  <option value="ESPECIFICACAO_INCOMPLETA">📝 Especificação Incompleta</option>
                  <option value="CERTIFICACAO_PENDENTE">✅ Certificação Pendente</option>
                  <option value="ESCLARECIMENTO_TECNICO">🔧 Esclarecimento Técnico</option>
                  <option value="OUTRO">✏️ Outro (especificar)</option>
                </select>
                <div id="tipo_outro_container" style="display: none; margin-top: 10px;">
                  <input 
                    type="text" 
                    id="tipo_outro_texto" 
                    class="swal2-input" 
                    placeholder="Digite o tipo de diligência..."
                    style="width: 100%; font-size: 14px;"
                  >
                </div>
              </div>
              
              <div style="margin-bottom: 20px;">
                <label for="descricao_diligencia" style="display: block; font-weight: bold; margin-bottom: 8px; color: #2c3e50;">
                  ✍️ Descrição Detalhada:
                </label>
                <textarea 
                  id="descricao_diligencia" 
                  class="swal2-textarea" 
                  placeholder="Descreva detalhadamente o que precisa ser providenciado pelo fornecedor..."
                  style="width: 100%; min-height: 120px; font-size: 14px; line-height: 1.5;"
                ></textarea>
              </div>
              
              <div style="margin-bottom: 20px; padding: 15px; background: #e8f4fd; border-left: 4px solid #3498db; border-radius: 4px;">
                <div style="display: flex; align-items: center; margin-bottom: 8px;">
                  <span style="font-size: 18px; margin-right: 8px;">⏰</span>
                  <strong style="color: #2c3e50;">Prazo para Resposta:</strong>
                </div>
                <p style="margin: 0; color: #34495e; font-size: 14px;">
                  <strong>30 dias úteis</strong> (padrão do sistema)
                </p>
                <small style="color: #6c757d; font-size: 12px; margin-top: 5px; display: block;">
                  📅 A data limite será calculada automaticamente excluindo fins de semana
                </small>
              </div>
            </div>
          `,
          width: '600px',
          focusConfirm: false,
          showCancelButton: true,
          confirmButtonText: '📤 Enviar Diligência',
          cancelButtonText: '❌ Cancelar',
          confirmButtonColor: '#f39c12',
          cancelButtonColor: '#6c757d',
          didOpen: () => {
            // Configurar evento para mostrar/esconder campo "Outro"
            const select = document.getElementById('tipo_diligencia')
            const container = document.getElementById('tipo_outro_container')
            
            select.addEventListener('change', function() {
              if (this.value === 'OUTRO') {
                container.style.display = 'block'
                // Focar no campo de texto quando aparecer
                setTimeout(() => {
                  document.getElementById('tipo_outro_texto').focus()
                }, 100)
              } else {
                container.style.display = 'none'
              }
            })
          },
          preConfirm: () => {
            const tipoSelect = document.getElementById('tipo_diligencia').value
            const tipoOutroTexto = document.getElementById('tipo_outro_texto').value
            const descricao = document.getElementById('descricao_diligencia').value
            const prazo = 30 // FIXO EM 30 DIAS
            
            // Determinar o tipo final
            let tipo = tipoSelect
            if (tipoSelect === 'OUTRO') {
              if (!tipoOutroTexto || tipoOutroTexto.trim().length < 3) {
                this.$swal.showValidationMessage('⚠️ Por favor, especifique o tipo de diligência (mínimo 3 caracteres)')
                return false
              }
              tipo = tipoOutroTexto.trim()
            }
            
            if (!tipoSelect) {
              this.$swal.showValidationMessage('⚠️ Por favor, selecione o tipo de diligência')
              return false
            }
            
            if (!descricao || descricao.trim().length < 20) {
              this.$swal.showValidationMessage('⚠️ A descrição deve ter pelo menos 20 caracteres')
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
        // Verificar se o produto tem email do fornecedor
        if (!this.produto.email_fornecedor) {
          this.$swal({
            title: '⚠️ Email do Fornecedor Necessário',
            text: 'Para enviar a diligência, é necessário que o produto tenha o email do fornecedor cadastrado. Deseja continuar sem enviar email?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Continuar sem Email',
            cancelButtonText: 'Cancelar',
            confirmButtonColor: '#f39c12'
          }).then(async (result) => {
            if (result.isConfirmed) {
              await this.processarDiligencia(produtoId, diligenciaData, false)
            }
          })
          return
        }
        
        await this.processarDiligencia(produtoId, diligenciaData, true)
        
      } catch (error) {
        console.error('Erro ao salvar diligência:', error)
        this.$swal({
          title: '❌ Erro',
          text: 'Erro ao solicitar diligência',
          icon: 'error'
        })
      }
    },

    async processarDiligencia(produtoId, diligenciaData, enviarEmail = true) {
      try {
        // Calcular data limite (dias úteis)
        const dataLimite = this.calcularDataUtil(new Date(), diligenciaData.prazo)
        
        // Inserir diligência
        const { data: diligenciaInserida, error: diligenciaError } = await supabase
          .from('diligencias')
          .insert({
            produto_id: produtoId,
            tenant_id: this.produto.tenant_id,
            tipo: diligenciaData.tipo,
            descricao: diligenciaData.descricao,
            prazo_dias: diligenciaData.prazo,
            data_limite: dataLimite.toISOString(),
            status: 'PENDENTE',
            solicitado_por: 'CPM'
          })
          .select()
          .single()
        
        if (diligenciaError) throw diligenciaError
        
        // Atualizar status do produto para 'diligencia'
        const { error: produtoError } = await supabase
          .from('produtos')
          .update({ status: 'diligencia' })
          .eq('id', produtoId)
        
        if (produtoError) throw produtoError
        
        // 📧 ENVIAR EMAIL DE DILIGÊNCIA
        let emailEnviado = false
        if (enviarEmail && this.produto.email_fornecedor) {
          try {
            const resultadoEmail = await enviarEmailDiligencia({
              destinatario: this.produto.email_fornecedor,
              produto: this.produto,
              diligencia: {
                ...diligenciaInserida,
                data_limite: dataLimite
              }
            })
            
            emailEnviado = resultadoEmail.success
            
            if (!resultadoEmail.success) {
              console.error('Erro no envio do email:', resultadoEmail.message)
            }
          } catch (emailError) {
            console.error('Erro ao enviar email:', emailError)
          }
        }
        
        // Mensagem de sucesso
        const mensagemEmail = enviarEmail && emailEnviado 
          ? ' O fornecedor foi notificado por email.' 
          : enviarEmail && !emailEnviado 
            ? ' ⚠️ A diligência foi salva, mas houve erro no envio do email.'
            : ' (Sem notificação por email)'
        
        this.$swal({
          title: '✅ Sucesso!',
          text: `Diligência solicitada com sucesso.${mensagemEmail}`,
          icon: emailEnviado || !enviarEmail ? 'success' : 'warning',
          confirmButtonColor: '#28a745'
        })
        
        // Recarregar dados
        await this.carregarDados()
        
      } catch (error) {
        console.error('Erro ao processar diligência:', error)
        this.$swal({
          title: '❌ Erro',
          text: 'Erro ao processar diligência',
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
        
        let html = '<div style="text-align: left; padding: 10px;">'
        
        if (data && data.length > 0) {
          html += '<h4 style="color: #2c3e50; margin-bottom: 20px;">📋 Histórico de Diligências:</h4>'
          data.forEach((diligencia, index) => {
            const statusColor = diligencia.status === 'PENDENTE' ? '#f39c12' : 
                               diligencia.status === 'ATENDIDA' ? '#28a745' : '#dc3545'
            const statusIcon = diligencia.status === 'PENDENTE' ? '⏳' : 
                              diligencia.status === 'ATENDIDA' ? '✅' : '❌'
            
            html += `
              <div style="border: 1px solid #e9ecef; border-radius: 8px; padding: 15px; margin: 15px 0; background: ${diligencia.status === 'PENDENTE' ? '#fff3cd' : diligencia.status === 'ATENDIDA' ? '#d4edda' : '#f8d7da'};">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                  <strong style="color: #2c3e50;">Diligência #${index + 1}</strong>
                  <span style="color: ${statusColor}; font-weight: bold;">
                    ${statusIcon} ${diligencia.status}
                  </span>
                </div>
                
                <div style="margin-bottom: 8px;">
                  <strong style="color: #495057;">Tipo:</strong> 
                  <span style="color: #6c757d;">${diligencia.tipo.replace(/_/g, ' ')}</span>
                </div>
                
                <div style="margin-bottom: 8px;">
                  <strong style="color: #495057;">Descrição:</strong>
                  <div style="background: white; padding: 10px; border-radius: 4px; margin-top: 5px; border-left: 4px solid ${statusColor};">
                    ${diligencia.descricao}
                  </div>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-top: 10px; font-size: 12px; color: #6c757d;">
                  <div>📅 <strong>Prazo:</strong> ${this.formatDate(diligencia.data_limite)}</div>
                  <div>🕐 <strong>Solicitado:</strong> ${this.formatDate(diligencia.criado_em)}</div>
                </div>
              </div>
            `
          })
        } else {
          html += `
            <div style="text-align: center; padding: 40px; color: #6c757d;">
              <div style="font-size: 48px; margin-bottom: 15px;">📭</div>
              <p>Nenhuma diligência encontrada para este produto.</p>
            </div>
          `
        }
        
        html += '</div>'
        
        this.$swal({
          title: '📋 Diligências do Produto',
          html: html,
          width: '700px',
          confirmButtonColor: '#007bff'
        })
        
      } catch (error) {
        console.error('Erro ao carregar diligências:', error)
        this.$swal({
          title: '❌ Erro',
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
    }
  }
}
</script>

<style scoped>
.analise-container {
  padding: 20px;
  max-width: 900px;
  margin: 0 auto;
}

.loading, .not-found {
  text-align: center;
  padding: 40px;
}

.produto-analise {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 20px;
}

h2, h3 {
  margin-top: 0;
}

.produto-info {
  margin-bottom: 30px;
}

.produto-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 2px solid #f8f9fa;
}

.produto-header h3 {
  margin: 0;
  color: #2c3e50;
}

.produto-actions {
  display: flex;
  gap: 10px;
}

.btn-diligencia {
  background: linear-gradient(135deg, #f39c12, #e67e22);
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(243, 156, 18, 0.3);
}

.btn-diligencia:hover {
  background: linear-gradient(135deg, #e67e22, #d35400);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(243, 156, 18, 0.4);
}

.btn-ver-diligencias {
  background: linear-gradient(135deg, #17a2b8, #138496);
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(23, 162, 184, 0.3);
}

.btn-ver-diligencias:hover {
  background: linear-gradient(135deg, #138496, #117a8b);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(23, 162, 184, 0.4);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

.info-item {
  padding: 10px;
  background: #f9f9f9;
  border-radius: 4px;
}

.info-item.full-width {
  grid-column: span 2;
}

.status-pill {
  display: inline-block;
  padding: 5px 10px;
  border-radius: 20px;
  font-size: 12px;
  text-transform: uppercase;
}

.status-aprovado {
  background-color: #2ecc71;
  color: white;
}

.status-pendente {
  background-color: #f39c12;
  color: white;
}

.status-reprovado {
  background-color: #e74c3c;
  color: white;
}

.documentos-section {
  margin-bottom: 30px;
}

.documentos-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 15px;
}

.documento-item {
  display: flex;
  align-items: center;
  background: #f9f9f9;
  padding: 10px;
  border-radius: 4px;
}

.doc-icon {
  font-size: 24px;
  margin-right: 10px;
}

.doc-info {
  flex: 1;
}

.doc-name {
  margin: 0;
  font-weight: bold;
}

.doc-type {
  margin: 0;
  font-size: 12px;
  color: #7f8c8d;
}

.doc-action {
  color: #3498db;
  text-decoration: none;
}

.analise-form {
  margin-bottom: 30px;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  resize: vertical;
}

.radio-group {
  display: flex;
  gap: 20px;
}

.radio-label {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.radio-label input {
  margin-right: 8px;
}

.form-actions {
  display: flex;
  gap: 10px;
}

.btn-primary, .btn-secondary {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary {
  background-color: #2c3e50;
  color: white;
}

.btn-primary:disabled {
  background-color: #95a5a6;
}

.btn-secondary {
  background-color: #ecf0f1;
  color: #2c3e50;
}

.analises-anteriores {
  margin-top: 30px;
}

.analise-historico {
  background: #f9f9f9;
  border-radius: 4px;
  padding: 15px;
  margin-bottom: 10px;
}

.analise-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.analise-data {
  color: #7f8c8d;
  font-size: 12px;
}

.analise-conteudo {
  font-style: italic;
}

.motivacao-reprovacao {
  margin-top: 15px;
  background-color: #ffecec;
  padding: 12px;
  border-radius: 4px;
  border-left: 4px solid #e74c3c;
}

.motivacao-reprovacao h4 {
  margin-top: 0;
  margin-bottom: 8px;
  color: #c0392b;
}

.helper-text {
  display: block;
  margin-top: 5px;
  color: #7f8c8d;
  font-size: 12px;
}
</style> 