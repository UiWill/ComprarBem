// Script para diagnosticar o problema do conteúdo HTML vazio no DFD
// Execute no console do navegador quando estiver na aplicação

async function diagnosticarDFDHTML() {
  console.log('🔍 DIAGNOSTICANDO PROBLEMA DO DFD NO RELATÓRIO PDF...')

  try {
    // 1. Buscar DFDs recentes para análise
    console.log('\n📊 1. BUSCANDO DFDs PARA ANÁLISE:')

    const { data: dfds, error } = await supabase
      .from('dfd_processo')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5)

    if (error) {
      console.error('❌ Erro ao buscar DFDs:', error)
      return
    }

    console.log(`📊 Total de DFDs encontrados: ${dfds.length}`)

    if (dfds.length === 0) {
      console.log('❌ Nenhum DFD encontrado para análise')
      return
    }

    // 2. Analisar cada DFD em detalhes
    dfds.forEach((dfd, index) => {
      console.log(`\n📄 ANÁLISE DFD ${index + 1} (ID: ${dfd.id}):`)

      // Verificar campos principais do formulário
      const camposFormulario = [
        'justificativa',
        'necessidade_descricao', // Este é o campo correto do formulário
        'criterios_aceitacao',
        'observacoes_especiais',
        'nome_presidente',
        'matricula_presidente',
        'email_presidente',
        'produtos_especificacao',
        'especificacoes_tecnicas',
        'ensaios_exigidos'
      ]

      console.log('  📝 Campos do formulário:')
      camposFormulario.forEach(campo => {
        const valor = dfd[campo]
        const temValor = valor && typeof valor === 'string' && valor.trim().length > 0
        console.log(`    ${campo}: ${temValor ? '✅' : '❌'} ${temValor ? `(${valor.length} chars)` : '(vazio)'}`)
        if (temValor && valor.length > 50) {
          console.log(`      Preview: "${valor.substring(0, 50)}..."`)
        }
      })

      // Verificar conteúdo HTML gerado
      console.log('\n  🌐 Análise do HTML gerado:')
      if (dfd.conteudo_html) {
        console.log(`    HTML presente: ✅ (${dfd.conteudo_html.length} caracteres)`)

        // Verificar se o HTML contém as seções principais
        const secoesPrincipais = [
          'JUSTIFICATIVA',
          'DESCRIÇÃO DA NECESSIDADE',
          'CRITÉRIOS DE ACEITAÇÃO',
          'DADOS DO DEMANDANTE'
        ]

        console.log('    Seções encontradas no HTML:')
        secoesPrincipais.forEach(secao => {
          const temSecao = dfd.conteudo_html.includes(secao)
          console.log(`      ${secao}: ${temSecao ? '✅' : '❌'}`)
        })

        // Mostrar preview do HTML
        console.log('    Preview do HTML:')
        const htmlLimpo = dfd.conteudo_html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
        console.log(`      "${htmlLimpo.substring(0, 200)}..."`)

      } else {
        console.log('    HTML presente: ❌ (null/undefined)')
      }

      console.log(`\n  🗓️ Metadados:`)
      console.log(`    Criado em: ${new Date(dfd.created_at).toLocaleString()}`)
      console.log(`    Processo ID: ${dfd.processo_id}`)
      console.log(`    Modelo usado: ${dfd.modelo_usado || 'N/A'}`)
      console.log(`    Folha número: ${dfd.folha_numero || 'N/A'}`)
    })

    // 3. Testar geração de HTML simulada
    console.log('\n🧪 3. TESTANDO GERAÇÃO DE HTML:')

    const dfdTeste = dfds[0] // Usar o primeiro DFD
    console.log(`Testando com DFD ${dfdTeste.id}`)

    // Simular o método gerarHTMLDFD
    function simularGeracaoHTML(dadosDFD) {
      return `
        <div class="documento-dfd">
          <h1>DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${dadosDFD.modelo_usado?.toUpperCase() || 'MODELO PADRÃO'}</h1>

          <div class="secao">
            <h2>JUSTIFICATIVA</h2>
            <p>${dadosDFD.justificativa || '[VAZIO]'}</p>
          </div>

          <div class="secao">
            <h2>DESCRIÇÃO DA NECESSIDADE</h2>
            <p>${dadosDFD.necessidade_descricao || '[VAZIO]'}</p>
          </div>

          ${dadosDFD.criterios_aceitacao ? `
          <div class="secao">
            <h2>CRITÉRIOS DE ACEITAÇÃO</h2>
            <p>${dadosDFD.criterios_aceitacao}</p>
          </div>
          ` : ''}

          ${dadosDFD.observacoes_especiais ? `
          <div class="secao">
            <h2>OBSERVAÇÕES ESPECIAIS</h2>
            <p>${dadosDFD.observacoes_especiais}</p>
          </div>
          ` : ''}
        </div>
      `
    }

    const htmlSimulado = simularGeracaoHTML(dfdTeste)
    console.log('HTML simulado gerado:')
    console.log(htmlSimulado.substring(0, 500) + '...')

    // 4. Comparar HTML salvo vs HTML simulado
    console.log('\n🔄 4. COMPARAÇÃO HTML SALVO vs SIMULADO:')
    if (dfdTeste.conteudo_html) {
      const htmlSalvo = dfdTeste.conteudo_html.length
      const htmlSimuladoLength = htmlSimulado.length

      console.log(`  HTML salvo no banco: ${htmlSalvo} caracteres`)
      console.log(`  HTML simulado: ${htmlSimuladoLength} caracteres`)
      console.log(`  Diferença: ${Math.abs(htmlSalvo - htmlSimuladoLength)} caracteres`)

      if (htmlSalvo < 100) {
        console.log('  ⚠️ HTML salvo muito pequeno - pode estar vazio ou incompleto')
      }
    }

  } catch (error) {
    console.error('❌ Erro geral no diagnóstico:', error)
  }
}

// Executar diagnóstico
diagnosticarDFDHTML()