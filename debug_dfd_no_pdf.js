// Script para debugar especificamente o DFD no relatório PDF
// Execute no console depois de gerar o relatório

async function debugDFDNoPDF() {
  console.log('🔍 DEBUGANDO DFD NO RELATÓRIO PDF...')

  try {
    const processoId = 'c5bdccaf-c9fe-4d6c-8b96-f801c6561a40'

    // 1. Buscar o DFD específico que aparece nos logs
    console.log('\n📊 1. BUSCANDO DFD ESPECÍFICO:')

    const { data: dfd, error } = await supabase
      .from('dfd_processo')
      .select('*')
      .eq('id', 'f3b0006a-41f6-4552-abf5-3b16f41164f4')
      .single()

    if (error) {
      console.error('❌ Erro ao buscar DFD:', error)
      return
    }

    console.log('📄 DFD encontrado:', {
      id: dfd.id,
      processo_id: dfd.processo_id,
      justificativa_length: dfd.justificativa?.length || 0,
      necessidade_descricao_length: dfd.necessidade_descricao?.length || 0,
      conteudo_html_length: dfd.conteudo_html?.length || 0,
      modelo_usado: dfd.modelo_usado
    })

    // 2. Analisar o conteúdo HTML salvo
    console.log('\n🌐 2. ANÁLISE DO HTML SALVO:')

    if (dfd.conteudo_html) {
      console.log('✅ HTML presente no banco:', dfd.conteudo_html.length, 'caracteres')

      // Verificar se contém as seções principais
      const secoes = [
        'JUSTIFICATIVA',
        'DESCRIÇÃO DA NECESSIDADE',
        'DADOS DO DEMANDANTE',
        'OBSERVAÇÕES ESPECIAIS'
      ]

      console.log('Seções encontradas no HTML:')
      secoes.forEach(secao => {
        const presente = dfd.conteudo_html.includes(secao)
        console.log(`  ${secao}: ${presente ? '✅' : '❌'}`)
      })

      // Mostrar preview do HTML
      console.log('\nPreview do HTML salvo:')
      const htmlLimpo = dfd.conteudo_html
        .replace(/<[^>]*>/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
      console.log(`"${htmlLimpo.substring(0, 300)}..."`)

      // Verificar se há campos vazios no HTML
      const temCamposVazios = dfd.conteudo_html.includes('[CAMPO VAZIO')
      if (temCamposVazios) {
        console.log('⚠️ HTML contém marcadores de campos vazios!')
        const matches = dfd.conteudo_html.match(/\[CAMPO VAZIO[^\]]*\]/g)
        if (matches) {
          console.log('Campos vazios encontrados:', matches)
        }
      } else {
        console.log('✅ HTML não contém marcadores de campos vazios')
      }

    } else {
      console.log('❌ HTML não presente no banco')
    }

    // 3. Verificar campos individuais
    console.log('\n📝 3. CAMPOS INDIVIDUAIS DO DFD:')

    const campos = [
      'justificativa',
      'necessidade_descricao',
      'criterios_aceitacao',
      'observacoes_especiais',
      'nome_presidente',
      'matricula_presidente',
      'email_presidente'
    ]

    campos.forEach(campo => {
      const valor = dfd[campo]
      const temValor = valor && typeof valor === 'string' && valor.trim().length > 0
      console.log(`  ${campo}: ${temValor ? '✅' : '❌'} ${temValor ? `(${valor.length} chars)` : '(vazio)'}`)

      if (temValor && valor.length <= 100) {
        console.log(`    Valor: "${valor}"`)
      } else if (temValor) {
        console.log(`    Preview: "${valor.substring(0, 50)}..."`)
      }
    })

    // 4. Simular geração de HTML com dados reais
    console.log('\n🧪 4. SIMULANDO GERAÇÃO DE HTML:')

    function simularHTMLDFD(dadosDFD) {
      return `
        <div class="documento-dfd">
          <h1>DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${dadosDFD.modelo_usado?.toUpperCase() || 'MODELO PADRÃO'}</h1>

          <div class="secao">
            <h2>JUSTIFICATIVA</h2>
            <p>${dadosDFD.justificativa || '[CAMPO VAZIO - JUSTIFICATIVA NÃO PREENCHIDA]'}</p>
          </div>

          <div class="secao">
            <h2>DESCRIÇÃO DA NECESSIDADE</h2>
            <p>${dadosDFD.necessidade_descricao || '[CAMPO VAZIO - DESCRIÇÃO NÃO PREENCHIDA]'}</p>
          </div>

          ${dadosDFD.observacoes_especiais ? `
          <div class="secao">
            <h2>OBSERVAÇÕES ESPECIAIS</h2>
            <p>${dadosDFD.observacoes_especiais}</p>
          </div>
          ` : ''}
        </div>
      `
    }

    const htmlSimulado = simularHTMLDFD(dfd)
    console.log('HTML simulado:', htmlSimulado.length, 'caracteres')
    console.log('Preview:', htmlSimulado.substring(0, 200) + '...')

    // 5. Comparar HTML salvo vs simulado
    console.log('\n🔄 5. COMPARAÇÃO:')
    if (dfd.conteudo_html) {
      console.log(`HTML salvo: ${dfd.conteudo_html.length} chars`)
      console.log(`HTML simulado: ${htmlSimulado.length} chars`)

      if (dfd.conteudo_html.length < 200) {
        console.log('⚠️ HTML salvo muito pequeno - provavelmente está vazio')
      }

      // Verificar se são similares
      const salvoPrimeiros100 = dfd.conteudo_html.substring(0, 100)
      const simuladoPrimeiros100 = htmlSimulado.substring(0, 100)

      if (salvoPrimeiros100.includes('DOCUMENTO DE FORMALIZAÇÃO') &&
          simuladoPrimeiros100.includes('DOCUMENTO DE FORMALIZAÇÃO')) {
        console.log('✅ Ambos têm estrutura similar')
      } else {
        console.log('❌ Estruturas diferentes - pode haver problema na geração')
      }
    }

  } catch (error) {
    console.error('❌ Erro no debug:', error)
  }
}

// Executar debug
debugDFDNoPDF()