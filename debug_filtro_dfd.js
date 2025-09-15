// Script para testar o filtro de DFDs implementado
// Execute no console do navegador quando estiver na aplicação

async function testarFiltroDFD() {
  console.log('🧪 TESTANDO FILTRO DE DFD COM JUSTIFICATIVA...')

  try {
    // 1. Buscar todos os DFDs SEM filtro (como era antes)
    console.log('\n📊 1. BUSCANDO TODOS OS DFDs (SEM FILTRO):')

    const { data: todosDFDs, error: errorTodos } = await supabase
      .from('dfd_processo')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10)

    if (errorTodos) {
      console.error('❌ Erro ao buscar DFDs:', errorTodos)
      return
    }

    console.log(`📊 Total de DFDs no banco: ${todosDFDs.length}`)

    // 2. Aplicar o filtro manualmente (como implementado)
    console.log('\n🔍 2. APLICANDO FILTRO DE JUSTIFICATIVA:')

    const dfdsComJustificativa = todosDFDs.filter(dfd => {
      const temJustificativa = dfd.justificativa &&
                              typeof dfd.justificativa === 'string' &&
                              dfd.justificativa.trim().length > 0

      console.log(`DFD ${dfd.id}:`, {
        temJustificativa,
        justificativa: dfd.justificativa?.substring(0, 50) + '...',
        tipo: typeof dfd.justificativa,
        tamanho: dfd.justificativa?.length
      })

      return temJustificativa
    })

    console.log(`📊 Resultado do filtro: ${dfdsComJustificativa.length}/${todosDFDs.length} DFDs válidos`)

    // 3. Mostrar detalhes dos DFDs filtrados
    if (dfdsComJustificativa.length > 0) {
      console.log('\n✅ 3. DFDs QUE PASSARAM NO FILTRO:')
      dfdsComJustificativa.forEach((dfd, index) => {
        console.log(`\n📄 DFD ${index + 1} (ID: ${dfd.id}):`)
        console.log(`  Justificativa: "${dfd.justificativa.substring(0, 100)}..."`)
        console.log(`  Criado em: ${new Date(dfd.created_at).toLocaleString()}`)
        console.log(`  Processo ID: ${dfd.processo_id}`)
      })
    } else {
      console.log('\n❌ Nenhum DFD passou no filtro de justificativa')
    }

    // 4. Mostrar detalhes dos DFDs filtrados (removidos)
    const dfdsRemovidos = todosDFDs.filter(dfd => {
      const temJustificativa = dfd.justificativa &&
                              typeof dfd.justificativa === 'string' &&
                              dfd.justificativa.trim().length > 0
      return !temJustificativa
    })

    if (dfdsRemovidos.length > 0) {
      console.log('\n⚠️ 4. DFDs QUE FORAM FILTRADOS (REMOVIDOS):')
      dfdsRemovidos.forEach((dfd, index) => {
        console.log(`\n📄 DFD removido ${index + 1} (ID: ${dfd.id}):`)
        console.log(`  Justificativa: ${dfd.justificativa || 'NULL/UNDEFINED'}`)
        console.log(`  Tipo: ${typeof dfd.justificativa}`)
        console.log(`  Tamanho: ${dfd.justificativa?.length || 0}`)
        console.log(`  Processo ID: ${dfd.processo_id}`)
      })
    }

    // 5. Resumo final
    console.log('\n📈 5. RESUMO DO FILTRO:')
    console.log(`  Total de DFDs: ${todosDFDs.length}`)
    console.log(`  DFDs válidos (com justificativa): ${dfdsComJustificativa.length}`)
    console.log(`  DFDs filtrados (sem justificativa): ${dfdsRemovidos.length}`)
    console.log(`  Taxa de aprovação: ${((dfdsComJustificativa.length / todosDFDs.length) * 100).toFixed(1)}%`)

  } catch (error) {
    console.error('❌ Erro geral no teste:', error)
  }
}

// Executar o teste
testarFiltroDFD()