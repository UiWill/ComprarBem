// Script para executar no console do navegador para verificar DFDs
// Cole este código no console do navegador (F12) quando estiver na aplicação

async function verificarDFDs() {
  console.log('🔍 Verificando DFDs no banco de dados...');

  try {
    // Buscar todos os DFDs recentes
    const { data: dfds, error } = await supabase
      .from('dfd_processo')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10);

    if (error) {
      console.error('❌ Erro ao buscar DFDs:', error);
      return;
    }

    console.log(`📊 Total de DFDs encontrados: ${dfds.length}`);

    if (dfds.length > 0) {
      console.table(dfds.map(dfd => ({
        ID: dfd.id,
        ProcessoID: dfd.processo_id,
        Justificativa: dfd.justificativa?.substring(0, 50) + '...',
        Modelo: dfd.modelo_usado,
        Criado: new Date(dfd.created_at).toLocaleString()
      })));

      // Agrupar por processo_id
      const porProcesso = dfds.reduce((acc, dfd) => {
        if (!acc[dfd.processo_id]) acc[dfd.processo_id] = [];
        acc[dfd.processo_id].push(dfd);
        return acc;
      }, {});

      console.log('📋 DFDs agrupados por processo:');
      Object.entries(porProcesso).forEach(([processoId, dfdsDoProcesso]) => {
        console.log(`   Processo ${processoId}: ${dfdsDoProcesso.length} DFD(s)`);
      });

      // Verificar se há processos com múltiplos DFDs
      const processosComMultiplosDFDs = Object.entries(porProcesso)
        .filter(([_, dfdsDoProcesso]) => dfdsDoProcesso.length > 1);

      if (processosComMultiplosDFDs.length > 0) {
        console.log('✅ Processos com múltiplos DFDs encontrados:');
        processosComMultiplosDFDs.forEach(([processoId, dfdsDoProcesso]) => {
          console.log(`   📄 Processo ${processoId}: ${dfdsDoProcesso.length} DFDs`);
          dfdsDoProcesso.forEach((dfd, index) => {
            console.log(`      DFD ${index + 1}: ID ${dfd.id} - ${dfd.justificativa?.substring(0, 30)}...`);
          });
        });
      } else {
        console.log('⚠️ Nenhum processo com múltiplos DFDs encontrado');
      }
    } else {
      console.log('❌ Nenhum DFD encontrado no banco');
    }

  } catch (error) {
    console.error('❌ Erro geral:', error);
  }
}

// Executar a verificação
verificarDFDs();