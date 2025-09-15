// Script para investigar o problema de campos DFD não sendo salvos
// Execute no console do navegador quando estiver na aplicação

async function investigarProblemaCamposDFD() {
  console.log('🔍 INVESTIGANDO PROBLEMA DOS CAMPOS DFD...')

  try {
    // 1. Verificar se a tabela existe e sua estrutura
    console.log('\n📊 1. VERIFICANDO ESTRUTURA DA TABELA dfd_processo:')

    const { data: estrutura, error: errorEstrutura } = await supabase
      .from('dfd_processo')
      .select('*')
      .limit(1)

    if (errorEstrutura) {
      console.error('❌ Erro ao verificar estrutura:', errorEstrutura)
      return
    }

    if (estrutura && estrutura.length > 0) {
      console.log('✅ Campos disponíveis na tabela:', Object.keys(estrutura[0]))
    } else {
      console.log('⚠️ Tabela vazia ou não existe')
    }

    // 2. Buscar todos os DFDs recentes
    console.log('\n📋 2. ANALISANDO DFDs SALVOS:')

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

    if (dfds.length > 0) {
      // 3. Analisar cada DFD
      dfds.forEach((dfd, index) => {
        console.log(`\n📄 DFD ${index + 1} (ID: ${dfd.id}):`)

        // Campos esperados do DFD
        const camposEsperados = [
          'justificativa',
          'descricao_necessidade',
          'criterios_aceitacao',
          'observacoes_especiais',
          'especificacoes_tecnicas',
          'ensaios_exigidos',
          'quantidade_estimada',
          'local_entrega',
          'prazo_entrega',
          'nome_presidente',
          'matricula_presidente',
          'email_presidente',
          'telefone_presidente'
        ]

        const camposPreenchidos = []
        const camposVazios = []

        camposEsperados.forEach(campo => {
          const valor = dfd[campo]
          if (valor && typeof valor === 'string' && valor.trim().length > 0) {
            camposPreenchidos.push({
              campo,
              tamanho: valor.length,
              preview: valor.substring(0, 50)
            })
          } else {
            camposVazios.push(campo)
          }
        })

        console.log(`  ✅ Campos preenchidos (${camposPreenchidos.length}):`)
        camposPreenchidos.forEach(item => {
          console.log(`    ${item.campo}: ${item.tamanho} chars - "${item.preview}..."`)
        })

        console.log(`  ❌ Campos vazios (${camposVazios.length}):`)
        camposVazios.forEach(campo => {
          console.log(`    ${campo}: VAZIO`)
        })

        // Verificar todos os campos não nulos
        console.log('  📊 Todos os campos com dados:')
        Object.entries(dfd).forEach(([key, value]) => {
          if (value !== null && value !== undefined && value !== '') {
            const tipo = typeof value
            const preview = tipo === 'string' ? value.substring(0, 30) : value
            console.log(`    ${key} (${tipo}): ${preview}`)
          }
        })
      })

      // 4. Verificar se há problema de salvamento
      console.log('\n🔍 3. DIAGNÓSTICO DO PROBLEMA:')

      const dfdMaisRecente = dfds[0]
      const camposComDados = Object.keys(dfdMaisRecente).filter(key => {
        const valor = dfdMaisRecente[key]
        return valor !== null && valor !== undefined && valor !== '' && typeof valor === 'string' && valor.trim().length > 0
      })

      console.log(`  📊 DFD mais recente tem ${camposComDados.length} campos com dados:`)
      camposComDados.forEach(campo => {
        console.log(`    ✅ ${campo}`)
      })

      // Comparar com campos esperados
      const camposEsperados = ['justificativa', 'descricao_necessidade', 'criterios_aceitacao', 'observacoes_especiais']
      const camposFaltantes = camposEsperados.filter(campo => !camposComDados.includes(campo))

      if (camposFaltantes.length > 0) {
        console.log(`  ⚠️ Campos esperados que estão faltando (${camposFaltantes.length}):`)
        camposFaltantes.forEach(campo => {
          console.log(`    ❌ ${campo}`)
        })
      } else {
        console.log('  ✅ Todos os campos esperados estão presentes')
      }

    } else {
      console.log('❌ Nenhum DFD encontrado no banco')
    }

    // 5. Verificar processo de inserção
    console.log('\n🔧 4. VERIFICANDO PROCESSO DE INSERÇÃO:')
    console.log('Para testar a inserção, execute no console:')
    console.log(`
testeDFD = {
  processo_id: 'seu-processo-id-aqui',
  tenant_id: 'seu-tenant-id-aqui',
  justificativa: 'Teste de justificativa',
  descricao_necessidade: 'Teste de descrição',
  criterios_aceitacao: 'Teste de critérios',
  observacoes_especiais: 'Teste de observações'
}

const { data, error } = await supabase
  .from('dfd_processo')
  .insert([testeDFD])

console.log('Resultado do teste:', { data, error })
    `)

  } catch (error) {
    console.error('❌ Erro geral na investigação:', error)
  }
}

// Executar a investigação
investigarProblemaCamposDFD()