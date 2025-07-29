const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://xttxydaxjlgjnrxhkjdk.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0dHh5ZGF4amxnam5yeGhramRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NjIyOTMsImV4cCI6MjA0ODAzODI5M30.7Sz7P9I0A3aJKnKiRKKJt7fTjlJ9CkzgwsQO4-H4GU8';
const supabase = createClient(supabaseUrl, supabaseKey);

async function testarHomologacoes() {
  try {
    console.log('=== TESTANDO ESTRUTURA DA TABELA HOMOLOGACOES ===');
    
    // Verificar se tabela existe e qual a estrutura
    const { data: colunas, error: errorColunas } = await supabase
      .from('homologacoes')
      .select('*')
      .limit(1);
    
    if (errorColunas) {
      console.log('Erro ao acessar tabela homologacoes:', errorColunas.message);
      return;
    }
    
    console.log('✅ Tabela homologacoes existe e está acessível');
    
    // Contar homologações existentes
    const { count, error: errorCount } = await supabase
      .from('homologacoes')
      .select('*', { count: 'exact', head: true })
      .eq('tenant_id', 'dcfe1030-27dd-4964-8e22-08a9c3fab790');
    
    console.log('📊 Total de homologações no banco:', count);
    
    // Mostrar últimas homologações
    const { data: homologacoes, error: errorHome } = await supabase
      .from('homologacoes')
      .select('*')
      .eq('tenant_id', 'dcfe1030-27dd-4964-8e22-08a9c3fab790')
      .order('criado_em', { ascending: false })
      .limit(3);
    
    if (homologacoes && homologacoes.length > 0) {
      console.log('📋 Últimas homologações:');
      homologacoes.forEach(h => {
        console.log(`- ${h.numero_ata} (${h.tipo_homologacao}) - ${h.data_homologacao}`);
      });
    } else {
      console.log('📋 Nenhuma homologação encontrada');
    }
    
    // Verificar atas pendentes
    const { data: atasPendentes, error: errorAtas } = await supabase
      .from('atas_julgamento')
      .select('id, numero, status_ata')
      .eq('tenant_id', 'dcfe1030-27dd-4964-8e22-08a9c3fab790')
      .in('status_ata', ['EM PRAZO', 'PUBLICADA', 'PUBLICADA_EM_PRAZO', 'PUBLICADA_ENCERRADA']);
    
    console.log('📋 Atas que deveriam aparecer para homologação:', atasPendentes?.length || 0);
    if (atasPendentes && atasPendentes.length > 0) {
      atasPendentes.forEach(ata => {
        console.log(`- ${ata.numero} (${ata.status_ata})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Erro no teste:', error.message);
  }
}

testarHomologacoes();