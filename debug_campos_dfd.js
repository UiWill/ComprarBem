// Script para executar no console do navegador para ver os campos dos DFDs
// Cole este código no console (F12) quando estiver na aplicação

async function verificarCamposDFDs() {
  console.log('🔍 Verificando campos dos DFDs...');

  try {
    const { data: dfds, error } = await supabase
      .from('dfd_processo')
      .select('*')
      .eq('processo_id', '65f4ae51-3d7a-4cf8-8bd3-8192f5698e93')
      .order('created_at', { ascending: true });

    if (error) {
      console.error('❌ Erro:', error);
      return;
    }

    console.log(`📊 ${dfds.length} DFDs encontrados:`);

    dfds.forEach((dfd, index) => {
      console.log(`\n📄 DFD ${index + 1} (ID: ${dfd.id}):`);
      console.log('  Campos disponíveis:', Object.keys(dfd));

      // Verificar campos principais
      const campos = ['justificativa', 'descricao_necessidade', 'criterios_aceitacao', 'observacoes_especiais'];
      campos.forEach(campo => {
        const valor = dfd[campo];
        const tamanho = valor ? valor.length : 0;
        console.log(`  ${campo}: ${tamanho} chars - "${valor?.substring(0, 30)}..."`);
      });

      // Mostrar todos os campos não nulos
      console.log('  Campos preenchidos:');
      Object.entries(dfd).forEach(([key, value]) => {
        if (value && typeof value === 'string' && value.trim().length > 0) {
          console.log(`    ${key}: "${value.substring(0, 50)}..."`);
        }
      });
    });

  } catch (error) {
    console.error('❌ Erro geral:', error);
  }
}

verificarCamposDFDs();