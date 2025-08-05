<template>
  <div class="folha-rosto">
    <!-- Formato EXATO conforme INSTRUÇÃO PROCESSUAL (1).pdf -->
    <div class="folha-rosto-simples">
      <div class="caixa-bordered">
        
        <div class="numero-processo">
          <strong>PROCESSO ADMINISTRATIVO Nº {{ numeroProcesso || '[não definido]' }}</strong>
        </div>
        
        <div class="campo">
          <strong>NOME DO ÓRGÃO:</strong> {{ dadosOrgao.nome }}
        </div>
        
        <div class="campo">
          <strong>INTERESSADO(A):</strong> {{ dadosOrgao.departamento || dadosOrgao.unidade_interessada }}
        </div>
        
        <div class="campo">
          <strong>DATA DE AUTUAÇÃO:</strong> {{ dataInicio }}
        </div>
        
        <div class="campo objeto">
          <strong>OBJETO:</strong> {{ objetoTexto }}
        </div>
        
      </div>
      
      <!-- Número da folha -->
      <div class="folha-numero">
        <p>Fl. 001</p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FolhaRosto',
  props: {
    numeroProcesso: {
      type: String,
      default: ''
    },
    tipoProcesso: {
      type: String,
      required: true,
      validator: value => ['padronizacao', 'despadronizacao'].includes(value)
    },
    dadosOrgao: {
      type: Object,
      default: () => ({
        nome: '',
        departamento: '',
        unidade_interessada: ''
      })
    },
    dataInicio: {
      type: String,
      default: () => new Date().toLocaleDateString('pt-BR')
    }
  },
  
  computed: {
    objetoTexto() {
      if (this.tipoProcesso === 'padronizacao') {
        return `CHAMAMENTO PÚBLICO DESTINADO À REALIZAÇÃO DO PROCEDIMENTO AUXILIAR DE PRÉ-QUALIFICAÇÃO DE BENS PREVISTO NO ART. 80, INCISO II, DA LEI FEDERAL Nº 14.133/2021, OBJETIVANDO PROMOVER A SELEÇÃO TÉCNICA DE MARCAS E MODELOS DE PRODUTOS QUE POSSUAM OS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE, ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINAM, CONFORME AS CARACTERÍSTICAS E CONDIÇÕES CONSTANTES NO EDITAL E SEUS ANEXOS, PARA SEREM INCLUÍDOS NO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS, COM VISTAS ÀS AQUISIÇÕES EVENTUAIS E FUTURAS.`
      } else {
        return `DESPADRONIZAÇÃO DE MARCA(S) E MODELO(S) DE PRODUTO(S) QUE NÃO MAIS ATENDE(M) AOS PADRÕES MÍNIMOS DE QUALIDADE, ESTÉTICA, RENDIMENTO, DURABILIDADE E ADEQUAÇÃO AO USO E À FINALIDADE A QUE SE DESTINA(M), COM VISTAS À SUA RETIRADA DO CATÁLOGO ELETRÔNICO DE BENS PADRONIZADOS.`
      }
    }
  }
}
</script>

<style scoped>
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

/* Estilos para impressão */
@media print {
  .folha-rosto {
    box-shadow: none;
    margin: 0;
    padding: 1.5cm;
  }
}

/* Responsividade para telas menores */
@media (max-width: 21cm) {
  .folha-rosto {
    width: 100%;
    margin: 1cm;
    padding: 1cm;
  }
  
  .caixa-bordered {
    max-width: 100%;
    padding: 1cm;
  }
}
</style>