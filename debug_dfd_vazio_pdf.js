// Script para debugar por que DFD aparece vazio no PDF
// Execute no console do navegador

async function debugDFDVazioPDF() {
  console.log('🔍 DEBUGANDO DFD VAZIO NO PDF...')

  try {
    const dfdId = 'f3b0006a-41f6-4552-abf5-3b16f41164f4'

    // 1. Buscar o DFD no banco
    console.log('\n📊 1. BUSCANDO DFD NO BANCO:')
    const { data: dfd, error } = await supabase
      .from('dfd_processo')
      .select('*')
      .eq('id', dfdId)
      .single()

    if (error) {
      console.error('❌ Erro ao buscar DFD:', error)
      return
    }

    console.log('✅ DFD encontrado no banco:', {
      id: dfd.id,
      justificativa: dfd.justificativa || '[VAZIO]',
      necessidade_descricao: dfd.necessidade_descricao || '[VAZIO]',
      conteudo_html_length: dfd.conteudo_html?.length || 0,
      conteudo_html_preview: dfd.conteudo_html?.substring(0, 200) || '[VAZIO]'
    })

    // 2. Simular a geração de HTML
    console.log('\n🛠️ 2. SIMULANDO GERAÇÃO DE HTML:')

    function gerarHTMLDFDSimples(dadosDFD) {
      const html = `
        <div class="documento-dfd" style="font-family: Arial, sans-serif; line-height: 1.6;">
          <h1 style="text-align: center; margin-bottom: 1cm;">DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${dadosDFD.modelo_usado?.toUpperCase() || 'MODELO_1'}</h1>

          <div style="margin-bottom: 1cm;">
            <h2>1. JUSTIFICATIVA</h2>
            <p style="text-align: justify;">${dadosDFD.justificativa || 'Justificativa não preenchida.'}</p>
          </div>

          <div style="margin-bottom: 1cm;">
            <h2>2. DESCRIÇÃO DA NECESSIDADE</h2>
            <p style="text-align: justify;">${dadosDFD.necessidade_descricao || 'Descrição da necessidade não preenchida.'}</p>
          </div>

          <div style="margin-top: 2cm; text-align: center;">
            <p>Data: ${new Date().toLocaleDateString('pt-BR')}</p>
            <br><br>
            <p>_________________________________________</p>
            <p>Presidente da CPPM</p>
          </div>
        </div>
      `
      return html
    }

    const htmlSimulado = gerarHTMLDFDSimples(dfd)
    console.log('📝 HTML simulado gerado:', {
      tamanho: htmlSimulado.length,
      temJustificativa: htmlSimulado.includes(dfd.justificativa || 'não preenchida'),
      temNecessidade: htmlSimulado.includes(dfd.necessidade_descricao || 'não preenchida'),
      preview: htmlSimulado.substring(0, 300) + '...'
    })

    // 3. Verificar se os campos têm conteúdo real
    console.log('\n📋 3. ANÁLISE DOS CAMPOS:')
    console.log('Justificativa:', {
      existe: !!dfd.justificativa,
      tamanho: dfd.justificativa?.length || 0,
      conteudo: dfd.justificativa || '[VAZIO]'
    })

    console.log('Necessidade Descrição:', {
      existe: !!dfd.necessidade_descricao,
      tamanho: dfd.necessidade_descricao?.length || 0,
      conteudo: dfd.necessidade_descricao || '[VAZIO]'
    })

    // 4. Teste manual: atualizar com HTML correto
    console.log('\n🔧 4. ATUALIZANDO COM HTML CORRETO:')

    const htmlCorreto = gerarHTMLDFDSimples(dfd)

    const { data: dfdAtualizado, error: errorUpdate } = await supabase
      .from('dfd_processo')
      .update({
        conteudo_html: htmlCorreto,
        updated_at: new Date().toISOString()
      })
      .eq('id', dfdId)
      .select()
      .single()

    if (errorUpdate) {
      console.error('❌ Erro ao atualizar:', errorUpdate)
      return
    }

    console.log('✅ DFD atualizado com sucesso!')
    console.log('📊 Novo conteudo_html:', {
      tamanho: dfdAtualizado.conteudo_html.length,
      preview: dfdAtualizado.conteudo_html.substring(0, 200) + '...'
    })

    console.log('\n🎯 RESULTADO:')
    console.log('Agora gere o PDF novamente e verifique se aparece o conteúdo!')

  } catch (error) {
    console.error('❌ Erro geral:', error)
  }
}

// Executar debug
debugDFDVazioPDF()