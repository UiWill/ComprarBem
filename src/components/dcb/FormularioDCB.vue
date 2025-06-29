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
      </div>
    </div>
    
    <div v-if="loading" class="loading">
      <p>Carregando informações...</p>
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
              <strong>1.1.1. Origem:</strong> Edital de Pré-Qualificação de Bens nº {{ produtoDetalhes.numero_edital || 'XXX/YYYY' }}
            </div>
          </div>
          <div class="info-grid">
        <div class="info-item">
              <strong>Data de Emissão:</strong> {{ formatarData(produtoDetalhes.data_emissao) }}
        </div>
        <div class="info-item">
              <strong>Data de Validade:</strong> {{ formatarData(produtoDetalhes.data_validade) }}
        </div>
        </div>
        </div>
      </div>
      
      <div class="documentos" v-if="documentos.length > 0">
        <h3>Documentos Anexos</h3>
        <ul class="documentos-lista">
          <li v-for="doc in documentos" :key="doc.id" class="documento-item">
            <span class="doc-icon">📄</span>
            <span class="doc-nome">{{ doc.nome }}</span>
            <a :href="doc.arquivo_url" target="_blank" class="btn-download">Visualizar</a>
          </li>
        </ul>
      </div>
      
      <div class="dcb-actions">
        <div class="button-group">
          <button @click="visualizarDCB" class="btn-primary" :disabled="!produtoAprovado">
            👁️ Visualizar DCB
          </button>
          <button @click="baixarDCB" class="btn-secondary" :disabled="!produtoAprovado">
            📥 Baixar DCB (PDF)
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
      currentTenantId: null
    }
  },
  computed: {
    produtoAprovado() {
      return this.produtoDetalhes && this.produtoDetalhes.status === 'aprovado'
    }
  },
  created() {
    this.obterTenantId().then(() => {
      this.carregarProdutos()
    })
  },
  methods: {
    async obterTenantId() {
      try {
        const { data } = await supabase.auth.getSession()
        const user = data?.session?.user
        
        if (!user) {
          console.error('Usuário não está autenticado')
          return
        }
        
          if (user.user_metadata?.tenant_id) {
            this.currentTenantId = user.user_metadata.tenant_id
          return
        }
        
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
        }
      } catch (error) {
        console.error('Erro ao obter tenant_id:', error)
      }
    },
    
    async carregarProdutos() {
      try {
        if (!this.currentTenantId) {
          console.error('Tenant ID não disponível')
          return
        }
        
        const { data: produtos, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('tenant_id', this.currentTenantId)
          .eq('status', 'aprovado')
          .order('nome')
        
        if (error) throw error
        
        this.produtos = produtos || []
      } catch (error) {
        console.error('Erro ao carregar produtos:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível carregar os produtos.'
        })
      }
    },
    
    async carregarDetalhes() {
      if (!this.produtoSelecionado) {
        this.produtoDetalhes = null
        this.documentos = []
        return
      }
      
      try {
        this.loading = true
        
        // Carregar detalhes do produto
        const { data: produto, error: produtoError } = await supabase
          .from('produtos')
          .select('*')
          .eq('id', this.produtoSelecionado)
          .single()
        
        if (produtoError) throw produtoError
        
        console.log('Produto carregado:', produto)
        
        // Simular datas para DCB se não existirem
        if (!produto.data_emissao) {
          produto.data_emissao = new Date().toISOString().split('T')[0]
        }
        if (!produto.data_validade) {
          const dataValidade = new Date()
          dataValidade.setFullYear(dataValidade.getFullYear() + 1)
          produto.data_validade = dataValidade.toISOString().split('T')[0]
        }
        
        // Garantir que temos um número de edital
        if (!produto.numero_edital) {
          produto.numero_edital = `001/${new Date().getFullYear()}`
        }
        
        this.produtoDetalhes = produto
        console.log('Detalhes do produto definidos:', this.produtoDetalhes)
        
        // Carregar documentos
        const { data: docs, error: docsError } = await supabase
          .from('documentos')
          .select('*')
          .eq('produto_id', this.produtoSelecionado)
        
        if (docsError) throw docsError
        
        this.documentos = docs || []
      } catch (error) {
        console.error('Erro ao carregar detalhes do produto:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível carregar os detalhes do produto.'
        })
      } finally {
        this.loading = false
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
      
      try {
        // Criar PDF usando jsPDF
        const pdf = new jsPDF('p', 'mm', 'a4')
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
        pdf.text(`1.1. Nome: ${produto.nome || 'Não informado'}`, 25, y)
        y += 4
        pdf.text(`Marca: ${produto.marca || 'Não informada'}`, 25, y)
        y += 4
        pdf.text(`Modelo: ${produto.modelo || 'Não informado'}`, 25, y)
        y += 4
        pdf.text(`Fabricante: ${produto.fabricante || 'Não informado'}`, 25, y)
        y += 4
        pdf.text(`CNPJ do Fabricante: ${produto.cnpj || 'Não informado'}`, 25, y)
        
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
        pdf.text(`1.1.1. Origem: Edital de Pré-Qualificação de Bens nº ${produto.numero_edital || 'XXX/YYYY'}`, 30, y)
        
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
        this.$swal({
          icon: 'error',
          title: 'Erro ao gerar PDF',
          text: 'Ocorreu um erro ao gerar o arquivo PDF.'
        })
      }
    },
    
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

@media (max-width: 768px) {
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .dcb-container {
    padding: 10px;
  }
}
</style> 