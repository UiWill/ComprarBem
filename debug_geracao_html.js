// Script para debugar por que o método gerarHTMLDFD não está sendo chamado
// Execute no console do navegador depois de gerar o relatório

async function debugGeracaoHTML() {
  console.log('🔍 DEBUGGING GERAÇÃO DE HTML DO DFD...')

  try {
    const processoId = 'c5bdccaf-c9fe-4d6c-8b96-f801c6561a40'
    const dfdId = 'f3b0006a-41f6-4552-abf5-3b16f41164f4'

    // 1. Buscar o DFD específico
    console.log('\n📊 1. BUSCANDO DFD ESPECÍFICO:')

    const { data: dfd, error } = await supabase
      .from('dfd_processo')
      .select('*')
      .eq('id', dfdId)
      .single()

    if (error) {
      console.error('❌ Erro ao buscar DFD:', error)
      return
    }

    console.log('📄 DFD encontrado:', {
      id: dfd.id,
      processo_id: dfd.processo_id,
      justificativa: dfd.justificativa?.substring(0, 50) + '...',
      necessidade_descricao: dfd.necessidade_descricao?.substring(0, 50) + '...',
      conteudo_html_size: dfd.conteudo_html?.length || 0,
      modelo_usado: dfd.modelo_usado
    })

    // 2. Simular o método gerarHTMLDFD do componente
    console.log('\n🧪 2. SIMULANDO MÉTODO DO COMPONENTE:')

    // Mock do processo (baseado nos logs)
    const processoMock = {
      id: processoId,
      nome_orgao: 'Órgão de Teste',
      numero_processo: 'PROC-2024-001',
      tipo_processo: 'padronizacao'
    }

    // Simular exatamente o método do componente
    function simularGerarHTMLDFD(processo, dadosDFD, produtos, numeroDFD = 1) {
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
      const tituloCompleto = `DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA${numeroDFD > 1 ? ` ${numeroDFD}` : ''} - ${modeloTipo}`

      let htmlConteudo = `
        <div class="documento-header" style="text-align: center; margin-bottom: 1cm;">
          <h1 style="font-size: 16pt; font-weight: bold; margin: 0.5cm 0; page-break-inside: avoid;">${processo.nome_orgao}</h1>
          <h2 style="font-size: 14pt; font-weight: bold; margin: 0.3cm 0; page-break-inside: avoid;">${tituloCompleto}</h2>
          <p style="font-size: 12pt; margin: 0.3cm 0;">Processo nº ${processo.numero_processo}</p>
        </div>

        <div class="documento-conteudo" style="text-align: justify; line-height: 1.7; font-size: 12pt;">
          <h3 style="margin: 0.8cm 0 0.4cm 0; font-size: 13pt; text-transform: uppercase;">1. JUSTIFICATIVA</h3>
          <p style="text-indent: 1.5cm; margin-bottom: 0.6cm;">${dadosDFD?.justificativa || 'Justificativa da necessidade conforme processo administrativo de ' + (processo.tipo_processo === 'padronizacao' ? 'padronização' : 'despadronização') + ' de produtos.'}</p>

          <h3 style="margin: 0.8cm 0 0.4cm 0; font-size: 13pt; text-transform: uppercase;">2. DESCRIÇÃO DA NECESSIDADE</h3>
          <p style="text-indent: 1.5cm; margin-bottom: 0.6cm;">${dadosDFD?.necessidade_descricao || 'Descrição detalhada da necessidade identificada para o processo de ' + (processo.tipo_processo === 'padronizacao' ? 'padronização' : 'despadronização') + ' dos produtos especificados.'}</p>

          <h3 style="margin: 0.8cm 0 0.4cm 0; font-size: 13pt; text-transform: uppercase;">3. CRITÉRIOS DE ACEITAÇÃO</h3>
          <p style="text-indent: 1.5cm; margin-bottom: 0.6cm;">${dadosDFD?.criterios_aceitacao || 'Critérios de aceitação conforme normas técnicas aplicáveis e especificações definidas para o processo.'}</p>

          <h2 style="margin: 1cm 0 0.5cm 0; font-size: 14pt; text-transform: uppercase;">OBSERVAÇÕES ESPECIAIS</h2>
          <p style="text-indent: 1.5cm; margin-bottom: 0.8cm;">${dadosDFD?.observacoes_especiais || 'Observações especiais do processo.'}</p>
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
    }

    const htmlGerado = simularGerarHTMLDFD(processoMock, dfd, [], 1)

    // 3. Verificar diferenças
    console.log('\n🔄 3. COMPARAÇÃO:')
    console.log(`HTML do banco: ${dfd.conteudo_html?.length || 0} chars`)
    console.log(`HTML simulado: ${htmlGerado.length} chars`)

    // Verificar se contém dados reais vs fallbacks
    const contemDadosReaisJustificativa = htmlGerado.includes(dfd.justificativa?.substring(0, 30))
    const contemDadosReaisNecessidade = htmlGerado.includes(dfd.necessidade_descricao?.substring(0, 30))

    console.log('Contém dados reais:')
    console.log(`  Justificativa: ${contemDadosReaisJustificativa ? '✅' : '❌'}`)
    console.log(`  Necessidade: ${contemDadosReaisNecessidade ? '✅' : '❌'}`)

    if (!contemDadosReaisJustificativa && !contemDadosReaisNecessidade) {
      console.log('⚠️ HTML contém apenas fallbacks - dados não estão sendo passados corretamente')
    }

    // 4. Verificar logs do navegador
    console.log('\n📝 4. VERIFIQUE OS LOGS:')
    console.log('Procure nos logs do console por:')
    console.log('  - "🔧 DEBUG gerarHTMLDFD (Component) - Dados recebidos"')
    console.log('  - "✅ DEBUG gerarHTMLDFD (Component) - HTML gerado"')
    console.log('')
    console.log('Se esses logs não aparecem, o método do componente não está sendo chamado.')

  } catch (error) {
    console.error('❌ Erro no debug:', error)
  }
}

// Executar debug
debugGeracaoHTML()