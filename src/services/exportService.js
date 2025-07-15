/**
 * Serviço para exportação de dados em diferentes formatos
 */

// Função para exportar dados para CSV
export function exportToCSV(data, filename = 'export.csv', headers = null) {
  if (!data || data.length === 0) {
    throw new Error('Nenhum dado para exportar')
  }

  // Se não foram fornecidos headers, usar as chaves do primeiro objeto
  const csvHeaders = headers || Object.keys(data[0])
  
  // Criar cabeçalho CSV
  let csvContent = csvHeaders.join(';') + '\n'
  
  // Adicionar dados
  data.forEach(row => {
    const values = csvHeaders.map(header => {
      let value = row[header] || ''
      
      // Tratar valores especiais
      if (typeof value === 'string') {
        // Escapar aspas duplas e quebras de linha
        value = value.replace(/"/g, '""')
        // Se contém vírgula, ponto e vírgula ou quebra de linha, envolver em aspas
        if (value.includes(';') || value.includes(',') || value.includes('\n') || value.includes('"')) {
          value = `"${value}"`
        }
      } else if (value instanceof Date) {
        value = value.toLocaleDateString('pt-BR')
      } else if (typeof value === 'number') {
        // Formatar números com vírgula decimal para padrão brasileiro
        value = value.toLocaleString('pt-BR')
      }
      
      return value
    })
    csvContent += values.join(';') + '\n'
  })
  
  // Criar e baixar arquivo
  downloadFile(csvContent, filename, 'text/csv;charset=utf-8;')
}

// Função para exportar dados para Excel (formato CSV que o Excel entende)
export function exportToExcel(data, filename = 'export.xlsx', headers = null) {
  if (!data || data.length === 0) {
    throw new Error('Nenhum dado para exportar')
  }

  // Preparar dados para Excel
  const excelHeaders = headers || Object.keys(data[0])
  
  // Criar conteúdo Excel (CSV com separador correto)
  let excelContent = '\uFEFF' // BOM para UTF-8
  excelContent += excelHeaders.join('\t') + '\n'
  
  data.forEach(row => {
    const values = excelHeaders.map(header => {
      let value = row[header] || ''
      
      if (typeof value === 'string') {
        // Limpar quebras de linha para Excel
        value = value.replace(/\n/g, ' ')
      } else if (value instanceof Date) {
        value = value.toLocaleDateString('pt-BR')
      } else if (typeof value === 'number') {
        // Manter números como estão para o Excel processar corretamente
        value = value.toString().replace('.', ',')
      }
      
      return value
    })
    excelContent += values.join('\t') + '\n'
  })
  
  // Baixar como arquivo Excel
  downloadFile(excelContent, filename.replace('.xlsx', '.xls'), 'application/vnd.ms-excel;charset=utf-8;')
}

// Função para criar e baixar arquivo
function downloadFile(content, filename, mimeType) {
  const blob = new Blob([content], { type: mimeType })
  const url = window.URL.createObjectURL(blob)
  
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.style.display = 'none'
  
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  // Limpar URL objeto
  setTimeout(() => {
    window.URL.revokeObjectURL(url)
  }, 100)
}

// Função específica para exportar cotações
export function exportCotacoes(cotacoes, formato = 'excel') {
  if (!cotacoes || cotacoes.length === 0) {
    throw new Error('Nenhuma cotação para exportar')
  }

  // Headers customizados para cotações
  const headers = [
    'produto_nome',
    'produto_descricao', 
    'fornecedor_nome',
    'fornecedor_cnpj',
    'fornecedor_contato',
    'quantidade',
    'unidade_medida',
    'preco_unitario',
    'preco_total',
    'prazo_entrega',
    'data_validade',
    'observacoes',
    'status',
    'created_at'
  ]

  // Headers legíveis para exportação
  const headersLegiveis = [
    'Produto',
    'Descrição do Produto',
    'Fornecedor', 
    'CNPJ',
    'Contato',
    'Quantidade',
    'Unidade',
    'Preço Unitário (R$)',
    'Preço Total (R$)',
    'Prazo Entrega (dias)',
    'Data Validade',
    'Observações',
    'Status',
    'Data Criação'
  ]

  // Preparar dados formatados
  const dadosFormatados = cotacoes.map(cotacao => {
    return {
      'Produto': cotacao.produto_nome || '',
      'Descrição do Produto': cotacao.produto_descricao || '',
      'Fornecedor': cotacao.fornecedor_nome || '',
      'CNPJ': formatCNPJ(cotacao.fornecedor_cnpj) || '',
      'Contato': cotacao.fornecedor_contato || '',
      'Quantidade': cotacao.quantidade || '',
      'Unidade': cotacao.unidade_medida || '',
      'Preço Unitário (R$)': formatCurrency(cotacao.preco_unitario) || '',
      'Preço Total (R$)': formatCurrency(cotacao.preco_total) || '',
      'Prazo Entrega (dias)': cotacao.prazo_entrega || '',
      'Data Validade': formatDate(cotacao.data_validade) || '',
      'Observações': cotacao.observacoes || '',
      'Status': getStatusLabel(cotacao.status) || '',
      'Data Criação': formatDate(cotacao.created_at) || ''
    }
  })

  // Gerar nome do arquivo com data atual
  const agora = new Date()
  const dataFormatada = agora.toISOString().split('T')[0] // YYYY-MM-DD
  const horaFormatada = agora.toTimeString().split(' ')[0].replace(/:/g, '-') // HH-MM-SS
  
  if (formato === 'excel') {
    const filename = `cotacoes_${dataFormatada}_${horaFormatada}.xlsx`
    exportToExcel(dadosFormatados, filename, headersLegiveis)
  } else {
    const filename = `cotacoes_${dataFormatada}_${horaFormatada}.csv`
    exportToCSV(dadosFormatados, filename, headersLegiveis)
  }
}

// Funções auxiliares de formatação
function formatCurrency(value) {
  if (!value) return ''
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value)
}

function formatCNPJ(cnpj) {
  if (!cnpj) return ''
  return cnpj.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5')
}

function formatDate(date) {
  if (!date) return ''
  return new Date(date).toLocaleDateString('pt-BR')
}

function getStatusLabel(status) {
  const statusLabels = {
    pendente: 'Pendente',
    enviada: 'Enviada',
    respondida: 'Respondida',
    aceita: 'Aceita',
    rejeitada: 'Rejeitada',
    expirada: 'Expirada'
  }
  return statusLabels[status] || status
}

// Função específica para exportar comparativos
export function exportComparativos(comparativos, formato = 'excel') {
  if (!comparativos || comparativos.length === 0) {
    throw new Error('Nenhum comparativo para exportar')
  }

  // Preparar dados formatados para comparativos
  const dadosFormatados = comparativos.map(comp => {
    return {
      'Título': comp.titulo || '',
      'Descrição': comp.descricao || '',
      'Categoria': comp.categoria || '',
      'Status': getStatusLabel(comp.status) || '',
      'Total de Itens': comp.total_itens || 0,
      'Pontuação Máxima': comp.pontuacao_maxima || 0,
      'Fornecedor Vencedor': comp.fornecedor_vencedor || '',
      'Economia Estimada (R$)': formatCurrency(comp.economia_estimada) || '',
      'Data Criação': formatDate(comp.created_at) || '',
      'Última Atualização': formatDate(comp.updated_at) || ''
    }
  })

  const agora = new Date()
  const dataFormatada = agora.toISOString().split('T')[0]
  const horaFormatada = agora.toTimeString().split(' ')[0].replace(/:/g, '-')
  
  if (formato === 'excel') {
    const filename = `comparativos_${dataFormatada}_${horaFormatada}.xlsx`
    exportToExcel(dadosFormatados, filename)
  } else {
    const filename = `comparativos_${dataFormatada}_${horaFormatada}.csv`
    exportToCSV(dadosFormatados, filename)
  }
}

// Função específica para exportar análises de preços
export function exportAnalises(analises, formato = 'excel') {
  if (!analises || analises.length === 0) {
    throw new Error('Nenhuma análise para exportar')
  }

  // Preparar dados formatados para análises
  const dadosFormatados = analises.map(analise => {
    return {
      'Título': analise.titulo || '',
      'Categoria': analise.categoria || '',
      'Status': getStatusLabel(analise.status) || '',
      'Produtos Analisados': analise.produtos_analisados || 0,
      'Preço Médio (R$)': formatCurrency(analise.preco_medio) || '',
      'Menor Preço (R$)': formatCurrency(analise.preco_minimo) || '',
      'Maior Preço (R$)': formatCurrency(analise.preco_maximo) || '',
      'Desvio Padrão': analise.desvio_padrao || '',
      'Outliers Detectados': analise.outliers_detectados || 0,
      'Recomendação': analise.recomendacao || '',
      'Data Criação': formatDate(analise.created_at) || '',
      'Última Atualização': formatDate(analise.updated_at) || ''
    }
  })

  const agora = new Date()
  const dataFormatada = agora.toISOString().split('T')[0]
  const horaFormatada = agora.toTimeString().split(' ')[0].replace(/:/g, '-')
  
  if (formato === 'excel') {
    const filename = `analises_precos_${dataFormatada}_${horaFormatada}.xlsx`
    exportToExcel(dadosFormatados, filename)
  } else {
    const filename = `analises_precos_${dataFormatada}_${horaFormatada}.csv`
    exportToCSV(dadosFormatados, filename)
  }
}