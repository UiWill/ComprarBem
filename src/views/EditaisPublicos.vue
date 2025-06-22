<template>
  <div class="editais-publicos">
    <div class="hero-section">
      <div class="container">
        <h1>📋 Editais de Pré-Qualificação</h1>
        <p>Consulte os editais públicos e participe dos processos de pré-qualificação técnica de bens.</p>
      </div>
    </div>

    <div class="container">
      <!-- Filtros -->
      <div class="filtros-section">
        <div class="filtros-grid">
          <div class="filtro-item">
            <label>🔍 Buscar:</label>
            <input 
              v-model="filtros.busca" 
              type="text" 
              placeholder="Número do edital, descrição..."
              @input="aplicarFiltros"
            >
          </div>
          <div class="filtro-item">
            <label>📅 Publicados em:</label>
            <input 
              v-model="filtros.dataPublicacao" 
              type="date" 
              @change="aplicarFiltros"
            >
          </div>
          <div class="filtro-item">
            <label>⏰ Status:</label>
            <select v-model="filtros.status" @change="aplicarFiltros">
              <option value="">Todos</option>
              <option value="ABERTO">Em andamento</option>
              <option value="PRAZO_FINAL">Prazo final</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="loading-section">
        <div class="spinner"></div>
        <p>Carregando editais...</p>
      </div>

      <!-- Lista de Editais -->
      <div v-else-if="editaisFiltrados.length > 0" class="editais-lista">
        <div 
          v-for="edital in editaisFiltrados" 
          :key="edital.id" 
          class="edital-card"
        >
          <div class="edital-header">
            <div class="edital-numero">
              <h3>{{ edital.numero }}</h3>
              <span class="status-badge" :class="getStatusClass(edital)">
                {{ getStatusText(edital) }}
              </span>
            </div>
            <div class="edital-datas">
              <p><strong>📅 Publicado:</strong> {{ formatDate(edital.data_publicacao) }}</p>
              <p v-if="edital.data_limite_impugnacao">
                <strong>⏰ Prazo:</strong> {{ formatDate(edital.data_limite_impugnacao) }}
                <span v-if="isPrazoFinal(edital)" class="prazo-final">⚠️ Últimos dias!</span>
              </p>
            </div>
          </div>

          <div class="edital-content">
            <h4>{{ edital.descricao }}</h4>
            <p v-if="edital.conteudo" class="edital-resumo">
              {{ edital.conteudo.substring(0, 200) }}{{ edital.conteudo.length > 200 ? '...' : '' }}
            </p>
          </div>

          <div class="edital-actions">
            <button 
              v-if="edital.url_documento" 
              @click="abrirDocumento(edital.url_documento)"
              class="btn-secondary"
            >
              📄 Ver Edital
            </button>
            <button 
              @click="abrirModalInscricao(edital)"
              class="btn-primary"
              :disabled="!podeParticipar(edital)"
            >
              {{ getTextoBotao(edital) }}
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="empty-state">
        <div class="empty-icon">📋</div>
        <h3>Nenhum edital encontrado</h3>
        <p v-if="filtros.busca || filtros.dataPublicacao || filtros.status">
          Nenhum edital corresponde aos filtros aplicados.
        </p>
        <p v-else>
          Não há editais públicos disponíveis no momento.
        </p>
      </div>
    </div>

    <!-- Modal de Inscrição -->
    <div v-if="modalInscricao" class="modal-overlay" @click="fecharModalInscricao">
      <div class="modal-content large" @click.stop>
        <div class="modal-header">
          <h3>📝 Inscrição no Edital {{ editalSelecionado.numero }}</h3>
          <button @click="fecharModalInscricao" class="btn-close">&times;</button>
        </div>
        
        <div class="modal-body">
          <div class="edital-info">
            <h4>{{ editalSelecionado.descricao }}</h4>
            <p><strong>Prazo para participação:</strong> {{ formatDate(editalSelecionado.data_limite_impugnacao) }}</p>
          </div>

          <form @submit.prevent="enviarInscricao">
            <h5>📋 Dados da Empresa</h5>
            
            <div class="form-row">
              <div class="form-group">
                <label for="razao_social">Razão Social*</label>
                <input 
                  id="razao_social" 
                  v-model="inscricao.razao_social" 
                  type="text" 
                  placeholder="Nome completo da empresa"
                  required
                >
              </div>
              <div class="form-group">
                <label for="cnpj">CNPJ*</label>
                <input 
                  id="cnpj" 
                  v-model="inscricao.cnpj" 
                  type="text" 
                  placeholder="00.000.000/0000-00"
                  maxlength="18"
                  @input="aplicarMascaraCNPJ"
                  @blur="validarCNPJ"
                  required
                >
                <small v-if="cnpjInvalido" class="text-danger">
                  ⚠️ CNPJ inválido. Verifique os números digitados.
                </small>
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="representante_legal">Representante Legal*</label>
                <input 
                  id="representante_legal" 
                  v-model="inscricao.representante_legal" 
                  type="text" 
                  placeholder="Nome do responsável"
                  required
                >
              </div>
              <div class="form-group">
                <label for="email">Email para Contato*</label>
                <input 
                  id="email" 
                  v-model="inscricao.email" 
                  type="email" 
                  placeholder="contato@empresa.com"
                  required
                >
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="telefone">Telefone*</label>
                <input 
                  id="telefone" 
                  v-model="inscricao.telefone" 
                  type="text" 
                  placeholder="(11) 99999-9999"
                  maxlength="15"
                  @input="aplicarMascaraTelefone"
                  required
                >
              </div>
              <div class="form-group">
                <label for="endereco">Endereço Completo*</label>
                <input 
                  id="endereco" 
                  v-model="inscricao.endereco" 
                  type="text" 
                  placeholder="Endereço da sede da empresa"
                  required
                >
              </div>
            </div>

            <div class="form-group">
              <label for="observacoes">Observações (Opcional)</label>
              <textarea 
                id="observacoes" 
                v-model="inscricao.observacoes" 
                rows="3"
                placeholder="Informações adicionais sobre sua participação..."
              ></textarea>
            </div>

            <div class="form-disclaimer">
              <div class="disclaimer-box">
                <h6>⚠️ Importante:</h6>
                <ul>
                  <li>Esta inscrição é apenas uma manifestação de interesse</li>
                  <li>Você deverá enviar a documentação técnica conforme especificado no edital</li>
                  <li>A análise será feita pela Comissão de Padronização de Materiais (CPM)</li>
                  <li>O resultado será comunicado pelo email informado</li>
                </ul>
              </div>
            </div>

            <div class="form-actions">
              <button type="button" @click="fecharModalInscricao" class="btn-secondary">
                Cancelar
              </button>
              <button type="submit" class="btn-primary" :disabled="enviandoInscricao">
                {{ enviandoInscricao ? 'Enviando...' : '📤 Confirmar Inscrição' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'

export default {
  name: 'EditaisPublicos',
  data() {
    return {
      editais: [],
      editaisFiltrados: [],
      loading: false,
      modalInscricao: false,
      enviandoInscricao: false,
      editalSelecionado: {},
      filtros: {
        busca: '',
        dataPublicacao: '',
        status: ''
      },
      inscricao: {
        razao_social: '',
        cnpj: '',
        representante_legal: '',
        email: '',
        telefone: '',
        endereco: '',
        observacoes: ''
      },
      cnpjInvalido: false
    }
  },
  async mounted() {
    await this.carregarEditais()
  },
  methods: {
    async carregarEditais() {
      try {
        this.loading = true
        
        const { data, error } = await supabase
          .from('editais')
          .select('*')
          .eq('status', 'PUBLICADO')
          .order('data_publicacao', { ascending: false })

        if (error) throw error

        this.editais = data || []
        this.aplicarFiltros()

      } catch (error) {
        console.error('Erro ao carregar editais:', error)
        this.$swal.fire({
          icon: 'error',
          title: 'Erro',
          text: 'Erro ao carregar editais públicos',
          zIndex: 10000
        })
      } finally {
        this.loading = false
      }
    },

    aplicarFiltros() {
      let filtrados = [...this.editais]

      if (this.filtros.busca) {
        const busca = this.filtros.busca.toLowerCase()
        filtrados = filtrados.filter(edital => 
          edital.numero.toLowerCase().includes(busca) ||
          edital.descricao.toLowerCase().includes(busca) ||
          (edital.conteudo && edital.conteudo.toLowerCase().includes(busca))
        )
      }

      if (this.filtros.dataPublicacao) {
        filtrados = filtrados.filter(edital => {
          const dataEdital = new Date(edital.data_publicacao).toISOString().split('T')[0]
          return dataEdital === this.filtros.dataPublicacao
        })
      }

      if (this.filtros.status === 'ABERTO') {
        filtrados = filtrados.filter(edital => this.podeParticipar(edital))
      } else if (this.filtros.status === 'PRAZO_FINAL') {
        filtrados = filtrados.filter(edital => this.isPrazoFinal(edital))
      }

      this.editaisFiltrados = filtrados
    },

    abrirModalInscricao(edital) {
      this.editalSelecionado = { ...edital }
      this.modalInscricao = true
      this.limparFormulario()
    },

    fecharModalInscricao() {
      this.modalInscricao = false
      this.editalSelecionado = {}
      this.limparFormulario()
    },

    limparFormulario() {
      this.inscricao = {
        razao_social: '',
        cnpj: '',
        representante_legal: '',
        email: '',
        telefone: '',
        endereco: '',
        observacoes: ''
      }
    },

    async enviarInscricao() {
      try {
        this.enviandoInscricao = true

        console.log('Iniciando inscrição...', {
          edital: this.editalSelecionado.numero,
          empresa: this.inscricao.razao_social
        })

        // Validar campos obrigatórios
        if (!this.inscricao.razao_social || !this.inscricao.cnpj || 
            !this.inscricao.representante_legal || !this.inscricao.email ||
            !this.inscricao.telefone || !this.inscricao.endereco) {
          this.$swal.fire({
            icon: 'error',
            title: 'Erro',
            text: 'Preencha todos os campos obrigatórios',
            zIndex: 10000
          })
          return
        }

        // Validar CNPJ
        if (!this.validarCNPJ()) {
          this.$swal.fire({
            icon: 'error',
            title: 'Erro',
            text: 'CNPJ inválido. Verifique os números digitados.',
            zIndex: 10000
          })
          return
        }

        // Validar telefone (mínimo 10 dígitos)
        const telefoneNumeros = this.inscricao.telefone.replace(/\D/g, '')
        if (telefoneNumeros.length < 10) {
          this.$swal.fire({
            icon: 'error',
            title: 'Erro',
            text: 'Telefone deve ter pelo menos 10 dígitos',
            zIndex: 10000
          })
          return
        }

        // Verificar se já está inscrito
        const cnpjLimpo = this.inscricao.cnpj.replace(/\D/g, '') // Salvar apenas números
        const { data: existente, error: erroConsulta } = await supabase
          .from('participantes_editais')
          .select('id')
          .eq('edital_id', this.editalSelecionado.id)
          .eq('cnpj', cnpjLimpo)
          .single()

        if (erroConsulta && erroConsulta.code !== 'PGRST116') {
          console.error('Erro ao consultar participantes:', erroConsulta)
          throw new Error('Erro ao verificar inscrição existente')
        }

        if (existente) {
          this.$swal.fire({
            icon: 'warning',
            title: 'Aviso',
            text: 'Esta empresa já está inscrita neste edital',
            zIndex: 10000
          })
          return
        }

        // Inserir participante
        const { error } = await supabase
          .from('participantes_editais')
          .insert({
            tenant_id: this.editalSelecionado.tenant_id,
            edital_id: this.editalSelecionado.id,
            razao_social: this.inscricao.razao_social,
            cnpj: cnpjLimpo, // Salvar apenas números
            representante_legal: this.inscricao.representante_legal,
            email: this.inscricao.email,
            telefone: this.inscricao.telefone,
            endereco: this.inscricao.endereco,
            status: 'INTERESSADO',
            observacoes: this.inscricao.observacoes,
            data_participacao: new Date().toISOString()
          })

        if (error) {
          console.error('Erro ao inserir participante:', error)
          throw error
        }

        console.log('Inscrição realizada com sucesso!')
        this.fecharModalInscricao()

        this.$swal.fire({
          icon: 'success',
          title: 'Inscrição realizada!',
          html: `
            <p>Sua empresa foi inscrita no edital <strong>${this.editalSelecionado.numero}</strong> com sucesso!</p>
            <br>
            <p><strong>Próximos passos:</strong></p>
            <ul style="text-align: left; margin: 10px 0;">
              <li>Prepare a documentação técnica conforme especificado no edital</li>
              <li>Envie os documentos no prazo estabelecido</li>
              <li>Aguarde o contato da CPM pelo email informado</li>
            </ul>
          `,
          confirmButtonText: 'Entendi',
          zIndex: 10000
        })

      } catch (error) {
        console.error('Erro ao enviar inscrição:', error)
        this.$swal.fire({
          icon: 'error',
          title: 'Erro ao enviar inscrição',
          text: error.message,
          zIndex: 10000
        })
      } finally {
        this.enviandoInscricao = false
      }
    },

    podeParticipar(edital) {
      if (!edital.data_limite_impugnacao) return true
      return new Date() <= new Date(edital.data_limite_impugnacao)
    },

    isPrazoFinal(edital) {
      if (!edital.data_limite_impugnacao) return false
      const agora = new Date()
      const prazo = new Date(edital.data_limite_impugnacao)
      const diasRestantes = (prazo - agora) / (1000 * 60 * 60 * 24)
      return diasRestantes <= 7 && diasRestantes > 0
    },

    getStatusClass(edital) {
      if (!this.podeParticipar(edital)) return 'status-encerrado'
      if (this.isPrazoFinal(edital)) return 'status-prazo-final'
      return 'status-aberto'
    },

    getStatusText(edital) {
      if (!this.podeParticipar(edital)) return '🔒 Encerrado'
      if (this.isPrazoFinal(edital)) return '⚠️ Prazo Final'
      return '✅ Aberto'
    },

    getTextoBotao(edital) {
      if (!this.podeParticipar(edital)) return '🔒 Prazo Encerrado'
      return '📝 Participar'
    },

    abrirDocumento(url) {
      if (url) {
        window.open(url, '_blank')
      }
    },

    formatDate(date) {
      if (!date) return 'N/A'
      return new Date(date).toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },

    aplicarMascaraCNPJ(event) {
      let valor = event.target.value.replace(/\D/g, '') // Remove tudo que não é número
      
      // Aplica a máscara
      valor = valor.replace(/^(\d{2})(\d)/, '$1.$2')
      valor = valor.replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
      valor = valor.replace(/\.(\d{3})(\d)/, '.$1/$2')
      valor = valor.replace(/(\d{4})(\d)/, '$1-$2')
      
      this.inscricao.cnpj = valor
      this.cnpjInvalido = false
    },

    validarCNPJ() {
      const cnpj = this.inscricao.cnpj.replace(/\D/g, '')
      
      if (cnpj.length !== 14) {
        this.cnpjInvalido = true
        return false
      }

      // Validação básica de CNPJ
      if (/^(\d)\1{13}$/.test(cnpj)) {
        this.cnpjInvalido = true
        return false
      }

      // Algoritmo de validação do CNPJ
      let tamanho = cnpj.length - 2
      let numeros = cnpj.substring(0, tamanho)
      const digitos = cnpj.substring(tamanho)
      let soma = 0
      let pos = tamanho - 7

      for (let i = tamanho; i >= 1; i--) {
        soma += numeros.charAt(tamanho - i) * pos--
        if (pos < 2) pos = 9
      }

      let resultado = soma % 11 < 2 ? 0 : 11 - soma % 11
      if (resultado != digitos.charAt(0)) {
        this.cnpjInvalido = true
        return false
      }

      tamanho = tamanho + 1
      numeros = cnpj.substring(0, tamanho)
      soma = 0
      pos = tamanho - 7

      for (let i = tamanho; i >= 1; i--) {
        soma += numeros.charAt(tamanho - i) * pos--
        if (pos < 2) pos = 9
      }

      resultado = soma % 11 < 2 ? 0 : 11 - soma % 11
      if (resultado != digitos.charAt(1)) {
        this.cnpjInvalido = true
        return false
      }

      this.cnpjInvalido = false
      return true
    },

    aplicarMascaraTelefone(event) {
      let valor = event.target.value.replace(/\D/g, '') // Remove tudo que não é número
      
      // Aplica a máscara para telefone
      if (valor.length <= 10) {
        // Telefone fixo: (11) 1234-5678
        valor = valor.replace(/^(\d{2})(\d)/, '($1) $2')
        valor = valor.replace(/(\d{4})(\d)/, '$1-$2')
      } else {
        // Celular: (11) 99999-9999
        valor = valor.replace(/^(\d{2})(\d)/, '($1) $2')
        valor = valor.replace(/(\d{5})(\d)/, '$1-$2')
      }
      
      this.inscricao.telefone = valor
    }
  }
}
</script>

<style scoped>
.editais-publicos {
  min-height: 100vh;
  background: #f8f9fa;
}

.hero-section {
  background: linear-gradient(135deg, #3498db, #2980b9);
  color: white;
  padding: 60px 0;
  text-align: center;
}

.hero-section h1 {
  margin: 0 0 15px 0;
  font-size: 2.5rem;
  font-weight: 700;
}

.hero-section p {
  margin: 0;
  font-size: 1.2rem;
  opacity: 0.9;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

/* Filtros */
.filtros-section {
  background: white;
  margin: -30px 20px 30px 20px;
  border-radius: 12px;
  padding: 25px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
}

.filtros-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.filtro-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.filtro-item label {
  font-weight: 600;
  color: #2c3e50;
  font-size: 14px;
}

.filtro-item input,
.filtro-item select {
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  transition: border-color 0.3s;
}

.filtro-item input:focus,
.filtro-item select:focus {
  outline: none;
  border-color: #3498db;
  box-shadow: 0 0 5px rgba(52, 152, 219, 0.3);
}

/* Loading */
.loading-section {
  text-align: center;
  padding: 60px 20px;
  color: #6c757d;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 5px solid #f3f3f3;
  border-top: 5px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Lista de Editais */
.editais-lista {
  display: grid;
  gap: 25px;
  padding: 0 20px 40px;
}

.edital-card {
  background: white;
  border-radius: 12px;
  padding: 25px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.08);
  transition: all 0.3s ease;
}

.edital-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

.edital-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.edital-numero h3 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1.4rem;
}

.edital-datas p {
  margin: 5px 0;
  color: #6c757d;
  font-size: 14px;
}

.edital-content h4 {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-size: 1.1rem;
  line-height: 1.4;
}

.edital-resumo {
  color: #6c757d;
  line-height: 1.6;
  margin-bottom: 20px;
}

.edital-actions {
  display: flex;
  gap: 15px;
  justify-content: flex-end;
}

/* Status badges */
.status-badge {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.status-aberto {
  background: #d4edda;
  color: #155724;
}

.status-prazo-final {
  background: #fff3cd;
  color: #856404;
}

.status-encerrado {
  background: #f8d7da;
  color: #721c24;
}

.prazo-final {
  color: #e74c3c;
  font-weight: bold;
  margin-left: 10px;
}

/* Botões */
.btn-primary,
.btn-secondary {
  padding: 12px 20px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.btn-primary {
  background: linear-gradient(135deg, #3498db, #2980b9);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.4);
}

.btn-primary:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
  transform: none;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #5a6268;
  transform: translateY(-2px);
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 30px rgba(0,0,0,0.3);
}

.modal-content.large {
  width: 90%;
  max-width: 700px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 25px;
  border-bottom: 1px solid #eee;
  background: #f8f9fa;
  border-radius: 12px 12px 0 0;
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
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s;
}

.btn-close:hover {
  background: #e9ecef;
}

.modal-body {
  padding: 25px;
}

.edital-info {
  background: #e3f2fd;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 25px;
  border-left: 4px solid #3498db;
}

.edital-info h4 {
  margin: 0 0 8px 0;
  color: #1565c0;
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
  margin-bottom: 8px;
  font-weight: 600;
  color: #2c3e50;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3498db;
  box-shadow: 0 0 5px rgba(52, 152, 219, 0.3);
}

.form-disclaimer {
  margin: 25px 0;
}

.disclaimer-box {
  background: #fff3cd;
  border: 1px solid #ffeaa7;
  border-radius: 8px;
  padding: 20px;
}

.disclaimer-box h6 {
  margin: 0 0 10px 0;
  color: #856404;
}

.disclaimer-box ul {
  margin: 0;
  padding-left: 20px;
  color: #856404;
}

.disclaimer-box li {
  margin-bottom: 5px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 15px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 80px 20px;
  color: #6c757d;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 20px;
}

.empty-state h3 {
  margin: 0 0 15px 0;
  color: #495057;
}

/* Responsividade */
@media (max-width: 768px) {
  .hero-section h1 {
    font-size: 2rem;
  }
  
  .hero-section p {
    font-size: 1rem;
  }
  
  .filtros-grid {
    grid-template-columns: 1fr;
  }
  
  .edital-header {
    flex-direction: column;
    gap: 15px;
  }
  
  .edital-actions {
    justify-content: stretch;
    flex-direction: column;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .form-actions {
    flex-direction: column;
  }
}

.text-danger {
  color: #dc3545;
  font-size: 12px;
  margin-top: 5px;
  display: block;
}
</style> 