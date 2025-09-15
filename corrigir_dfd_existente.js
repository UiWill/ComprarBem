// Script para corrigir o DFD existente que não tem conteudo_html
// Execute no console do navegador

async function corrigirDFDExistente() {
  console.log('🔧 CORRIGINDO DFD EXISTENTE SEM CONTEUDO_HTML...')

  try {
    const dfdId = 'f3b0006a-41f6-4552-abf5-3b16f41164f4'

    // 1. Buscar o DFD atual
    console.log('\n📊 1. BUSCANDO DFD ATUAL:')

    const { data: dfd, error: errorBuscar } = await supabase
      .from('dfd_processo')
      .select('*')
      .eq('id', dfdId)
      .single()

    if (errorBuscar) {
      console.error('❌ Erro ao buscar DFD:', errorBuscar)
      return
    }

    console.log('✅ DFD encontrado:', {
      id: dfd.id,
      justificativa: dfd.justificativa?.length || 0,
      necessidade_descricao: dfd.necessidade_descricao?.length || 0,
      conteudo_html_atual: dfd.conteudo_html?.length || 0
    })

    // 2. Gerar HTML manualmente usando a função corrigida
    console.log('\n🛠️ 2. GERANDO HTML CORRIGIDO:')

    function gerarHTMLDFDCorrigido(dadosDFD) {
      return `
        <div class="documento-dfd">
          <h1>DOCUMENTO DE FORMALIZAÇÃO DE DEMANDA - ${dadosDFD.modelo_usado?.toUpperCase() || 'MODELO PADRÃO'}</h1>

          ${dadosDFD.nome_presidente ? `
          <div class="secao">
            <h2>DADOS DO DEMANDANTE</h2>
            <p><strong>Nome do Presidente da CPPM:</strong> ${dadosDFD.nome_presidente}</p>
            ${dadosDFD.matricula_presidente ? `<p><strong>Matrícula:</strong> ${dadosDFD.matricula_presidente}</p>` : ''}
            ${dadosDFD.email_presidente ? `<p><strong>E-mail:</strong> ${dadosDFD.email_presidente}</p>` : ''}
            ${dadosDFD.telefone_presidente ? `<p><strong>Telefone:</strong> ${dadosDFD.telefone_presidente}</p>` : ''}
          </div>
          ` : ''}

          <div class="secao">
            <h2>JUSTIFICATIVA</h2>
            <p>${dadosDFD.justificativa || '[CAMPO VAZIO - JUSTIFICATIVA NÃO PREENCHIDA]'}</p>
          </div>

          <div class="secao">
            <h2>DESCRIÇÃO DA NECESSIDADE</h2>
            <p>${dadosDFD.necessidade_descricao || '[CAMPO VAZIO - DESCRIÇÃO NÃO PREENCHIDA]'}</p>
          </div>

          ${dadosDFD.produtos_especificacao ? `
          <div class="secao">
            <h2>PRODUTOS A SEREM PRÉ-QUALIFICADOS</h2>
            <p><strong>Especificação dos Produtos/Serviços:</strong> ${dadosDFD.produtos_especificacao}</p>
          </div>
          ` : ''}

          ${dadosDFD.criterios_aceitacao ? `
          <div class="secao">
            <h2>CRITÉRIOS DE ACEITAÇÃO</h2>
            <p><strong>Critérios de Aceitação:</strong> ${dadosDFD.criterios_aceitacao}</p>
          </div>
          ` : ''}

          ${dadosDFD.especificacoes_tecnicas ? `
          <div class="secao">
            <h2>ESPECIFICAÇÕES TÉCNICAS DETALHADAS</h2>
            <p><strong>Especificações Técnicas Obrigatórias:</strong> ${dadosDFD.especificacoes_tecnicas}</p>
          </div>
          ` : ''}

          ${dadosDFD.ensaios_exigidos ? `
          <div class="secao">
            <h2>ENSAIOS EXIGIDOS</h2>
            <p><strong>Ensaios e Testes Exigidos:</strong> ${dadosDFD.ensaios_exigidos}</p>
          </div>
          ` : ''}

          ${dadosDFD.observacoes_especiais ? `
          <div class="secao">
            <h2>OBSERVAÇÕES ESPECIAIS</h2>
            <p>${dadosDFD.observacoes_especiais}</p>
          </div>
          ` : ''}

          <div class="assinatura">
            <p>Data: ${new Date().toLocaleDateString('pt-BR')}</p>
            <br>
            <p>_________________________________________</p>
            <p>Presidente da CPPM</p>
          </div>
        </div>
      `
    }

    const htmlGerado = gerarHTMLDFDCorrigido(dfd)

    console.log('✅ HTML gerado:', {
      tamanho: htmlGerado.length,
      temJustificativa: htmlGerado.includes(dfd.justificativa?.substring(0, 20)),
      temNecessidade: htmlGerado.includes(dfd.necessidade_descricao?.substring(0, 20)),
      preview: htmlGerado.substring(0, 200) + '...'
    })

    // 3. Atualizar o DFD com o HTML gerado
    console.log('\n💾 3. ATUALIZANDO DFD NO BANCO:')

    const { data: dfdAtualizado, error: errorAtualizar } = await supabase
      .from('dfd_processo')
      .update({
        conteudo_html: htmlGerado,
        updated_at: new Date().toISOString()
      })
      .eq('id', dfdId)
      .select()
      .single()

    if (errorAtualizar) {
      console.error('❌ Erro ao atualizar DFD:', errorAtualizar)
      return
    }

    console.log('✅ DFD atualizado com sucesso!')
    console.log('📊 Novo tamanho do conteudo_html:', dfdAtualizado.conteudo_html.length, 'caracteres')

    // 4. Verificar resultado
    console.log('\n🎯 4. RESULTADO FINAL:')
    console.log('Agora gere o relatório PDF novamente para ver o DFD preenchido!')

  } catch (error) {
    console.error('❌ Erro geral:', error)
  }
}

// Executar correção
corrigirDFDExistente()