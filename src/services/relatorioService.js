/**
 * Serviço para geração de relatórios consolidados
 */

// Função para gerar relatório consolidado de análise de preços
export function gerarRelatorioAnalisePrecos(analises, titulo = 'Relatório Consolidado de Análise de Preços') {
  if (!analises || analises.length === 0) {
    throw new Error('Nenhuma análise encontrada para gerar relatório')
  }

  // Calcular estatísticas consolidadas
  const estatisticas = calcularEstatisticasConsolidadas(analises)
  
  // Gerar HTML do relatório
  const htmlRelatorio = gerarHTMLRelatorioAnalise(analises, estatisticas, titulo)
  
  // Abrir relatório em nova janela
  const novaJanela = window.open('', '_blank')
  if (novaJanela) {
    novaJanela.document.write(htmlRelatorio)
    novaJanela.document.close()
    
    // Adicionar função de impressão
    setTimeout(() => {
      novaJanela.focus()
    }, 500)
  } else {
    // Se não conseguir abrir nova janela, baixar como HTML
    baixarHTML(htmlRelatorio, `relatorio_analise_precos_${new Date().toISOString().split('T')[0]}.html`)
  }
}

// Função para calcular estatísticas consolidadas
function calcularEstatisticasConsolidadas(analises) {
  const analisesCompletas = analises.filter(a => a.status === 'concluida')
  
  if (analisesCompletas.length === 0) {
    return {
      totalAnalises: analises.length,
      analisesCompletas: 0,
      precoMedioGeral: 0,
      menorPreco: 0,
      maiorPreco: 0,
      desvioMedio: 0,
      totalOutliers: 0,
      categorias: [],
      recomendacoesPrincipais: []
    }
  }

  const precos = analisesCompletas
    .filter(a => a.preco_medio)
    .map(a => a.preco_medio)
    
  const outliers = analisesCompletas
    .map(a => a.outliers_detectados || 0)
    .reduce((acc, curr) => acc + curr, 0)
    
  const desvios = analisesCompletas
    .filter(a => a.desvio_padrao)
    .map(a => a.desvio_padrao)

  // Contar categorias
  const categorias = {}
  analisesCompletas.forEach(analise => {
    if (analise.categoria) {
      categorias[analise.categoria] = (categorias[analise.categoria] || 0) + 1
    }
  })

  // Coletar recomendações principais
  const recomendacoes = analisesCompletas
    .filter(a => a.recomendacao)
    .map(a => a.recomendacao)
    .slice(0, 5) // Top 5 recomendações

  return {
    totalAnalises: analises.length,
    analisesCompletas: analisesCompletas.length,
    precoMedioGeral: precos.length > 0 ? precos.reduce((acc, curr) => acc + curr, 0) / precos.length : 0,
    menorPreco: precos.length > 0 ? Math.min(...precos) : 0,
    maiorPreco: precos.length > 0 ? Math.max(...precos) : 0,
    desvioMedio: desvios.length > 0 ? desvios.reduce((acc, curr) => acc + curr, 0) / desvios.length : 0,
    totalOutliers: outliers,
    categorias: Object.entries(categorias).map(([nome, count]) => ({ nome, count })),
    recomendacoesPrincipais: recomendacoes
  }
}

// Função para gerar HTML do relatório
function gerarHTMLRelatorioAnalise(analises, estatisticas, titulo) {
  const agora = new Date()
  const dataRelatorio = agora.toLocaleDateString('pt-BR')
  const horaRelatorio = agora.toLocaleTimeString('pt-BR')

  return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${titulo}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f8f9fa;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header .meta {
            opacity: 0.9;
            font-size: 14px;
        }
        
        .content {
            padding: 30px;
        }
        
        .section {
            margin-bottom: 40px;
        }
        
        .section h2 {
            color: #2c3e50;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e1e5e9;
            font-size: 20px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #495057;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 14px;
            color: #6c757d;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        
        .table th,
        .table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #dee2e6;
        }
        
        .table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #495057;
        }
        
        .table tr:hover {
            background: #f8f9fa;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 500;
            text-transform: uppercase;
        }
        
        .badge-success {
            background: #d4edda;
            color: #155724;
        }
        
        .badge-warning {
            background: #fff3cd;
            color: #856404;
        }
        
        .badge-danger {
            background: #f8d7da;
            color: #721c24;
        }
        
        .badge-secondary {
            background: #e2e3e5;
            color: #383d41;
        }
        
        .recommendations {
            background: #e7f3ff;
            border: 1px solid #b8daff;
            border-radius: 8px;
            padding: 20px;
        }
        
        .recommendations h3 {
            color: #004085;
            margin-bottom: 15px;
        }
        
        .recommendations ul {
            list-style: none;
            padding: 0;
        }
        
        .recommendations li {
            background: white;
            margin-bottom: 10px;
            padding: 10px;
            border-radius: 4px;
            border-left: 4px solid #007bff;
        }
        
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #6c757d;
            font-size: 14px;
            border-top: 1px solid #dee2e6;
        }
        
        .btn-print {
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            margin: 20px 0;
        }
        
        .btn-print:hover {
            background: #0056b3;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
                border-radius: 0;
            }
            
            .btn-print {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 ${titulo}</h1>
            <div class="meta">
                Gerado em ${dataRelatorio} às ${horaRelatorio}
            </div>
        </div>
        
        <div class="content">
            <button class="btn-print" onclick="window.print()">🖨️ Imprimir / Salvar PDF</button>
            
            <!-- Resumo Executivo -->
            <div class="section">
                <h2>📋 Resumo Executivo</h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-value">${estatisticas.totalAnalises}</div>
                        <div class="stat-label">Total de Análises</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">${estatisticas.analisesCompletas}</div>
                        <div class="stat-label">Análises Concluídas</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">${formatCurrency(estatisticas.precoMedioGeral)}</div>
                        <div class="stat-label">Preço Médio Geral</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">${estatisticas.totalOutliers}</div>
                        <div class="stat-label">Outliers Detectados</div>
                    </div>
                </div>
            </div>
            
            <!-- Análises Detalhadas -->
            <div class="section">
                <h2>📈 Análises Detalhadas</h2>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Título</th>
                            <th>Categoria</th>
                            <th>Status</th>
                            <th>Preço Médio</th>
                            <th>Outliers</th>
                            <th>Data</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${analises.map(analise => `
                            <tr>
                                <td>${analise.titulo || 'N/A'}</td>
                                <td>${analise.categoria || 'N/A'}</td>
                                <td>
                                    <span class="badge ${getStatusBadgeClass(analise.status)}">
                                        ${getStatusLabel(analise.status)}
                                    </span>
                                </td>
                                <td>${formatCurrency(analise.preco_medio)}</td>
                                <td>${analise.outliers_detectados || 0}</td>
                                <td>${formatDate(analise.created_at)}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
            
            <!-- Distribuição por Categoria -->
            ${estatisticas.categorias.length > 0 ? `
            <div class="section">
                <h2>📊 Distribuição por Categoria</h2>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Categoria</th>
                            <th>Quantidade</th>
                            <th>Percentual</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${estatisticas.categorias.map(cat => `
                            <tr>
                                <td>${cat.nome}</td>
                                <td>${cat.count}</td>
                                <td>${((cat.count / estatisticas.totalAnalises) * 100).toFixed(1)}%</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
            ` : ''}
            
            <!-- Recomendações -->
            ${estatisticas.recomendacoesPrincipais.length > 0 ? `
            <div class="section">
                <div class="recommendations">
                    <h3>💡 Principais Recomendações</h3>
                    <ul>
                        ${estatisticas.recomendacoesPrincipais.map(rec => `
                            <li>${rec}</li>
                        `).join('')}
                    </ul>
                </div>
            </div>
            ` : ''}
        </div>
        
        <div class="footer">
            <p>Relatório gerado automaticamente pelo Sistema CPM - Comprar Bem</p>
            <p>Dados baseados em ${estatisticas.analisesCompletas} análise(s) concluída(s) de um total de ${estatisticas.totalAnalises}</p>
        </div>
    </div>
</body>
</html>
  `
}

// Função para baixar HTML
function baixarHTML(conteudo, nomeArquivo) {
  const blob = new Blob([conteudo], { type: 'text/html;charset=utf-8' })
  const url = window.URL.createObjectURL(blob)
  
  const link = document.createElement('a')
  link.href = url
  link.download = nomeArquivo
  link.style.display = 'none'
  
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  setTimeout(() => {
    window.URL.revokeObjectURL(url)
  }, 100)
}

// Funções auxiliares de formatação
function formatCurrency(value) {
  if (!value) return 'R$ 0,00'
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value)
}

function formatDate(date) {
  if (!date) return 'N/A'
  return new Date(date).toLocaleDateString('pt-BR')
}

function getStatusLabel(status) {
  const labels = {
    pendente: 'Pendente',
    processando: 'Processando',
    concluida: 'Concluída',
    erro: 'Erro',
    cancelada: 'Cancelada'
  }
  return labels[status] || status
}

function getStatusBadgeClass(status) {
  const classes = {
    pendente: 'badge-warning',
    processando: 'badge-secondary',
    concluida: 'badge-success',
    erro: 'badge-danger',
    cancelada: 'badge-secondary'
  }
  return classes[status] || 'badge-secondary'
}