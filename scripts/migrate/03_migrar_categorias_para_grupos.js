/**
 * Script para importar categorias iniciais para o novo sistema de grupos e classes
 * Este script cria grupos e classes com base nas categorias padrão do sistema
 */

const { createClient } = require('@supabase/supabase-js');

// Configuração do Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://ruagsbbczuwgfflgcaol.supabase.co';
const supabaseKey = process.env.SUPABASE_KEY || 'seu_supabase_key'; // Substitua pela sua chave
const supabase = createClient(supabaseUrl, supabaseKey);

// Categorias iniciais para converter em grupos e classes
const categoriasIniciais = [
  { id: 1, nome: 'Equipamentos Médicos' },
  { id: 2, nome: 'Equipamentos Odontológicos' },
  { id: 3, nome: 'Materiais Hospitalares' },
  { id: 4, nome: 'Materiais de Escritório' },
  { id: 5, nome: 'Equipamentos de Informática' },
  { id: 6, nome: 'Mobiliário' },
  { id: 7, nome: 'Medicamentos' },
  { id: 8, nome: 'Material de Laboratório' },
  { id: 9, nome: 'Equipamentos Administrativos' },
  { id: 10, nome: 'Outros' }
];

// Classes para cada categoria
const classesPorCategoria = {
  1: [ // Equipamentos Médicos
    'Equipamentos de Diagnóstico',
    'Equipamentos de Monitoramento',
    'Equipamentos de Suporte à Vida',
    'Equipamentos Cirúrgicos',
    'Equipamentos de Reabilitação'
  ],
  2: [ // Equipamentos Odontológicos
    'Cadeiras Odontológicas',
    'Equipamentos de Raio-X',
    'Instrumentos Odontológicos',
    'Materiais de Consumo Odontológico'
  ],
  3: [ // Materiais Hospitalares
    'Materiais de Curativos',
    'Materiais Descartáveis',
    'Materiais de Proteção Individual',
    'Materiais de Esterilização'
  ],
  4: [ // Materiais de Escritório
    'Papelaria',
    'Material de Organização',
    'Suprimentos de Impressão',
    'Móveis de Escritório'
  ],
  5: [ // Equipamentos de Informática
    'Computadores e Notebooks',
    'Periféricos',
    'Equipamentos de Rede',
    'Software',
    'Suprimentos de Informática'
  ],
  6: [ // Mobiliário
    'Mobiliário Hospitalar',
    'Mobiliário de Escritório',
    'Mobiliário para Salas de Espera',
    'Armários e Estantes'
  ],
  7: [ // Medicamentos
    'Medicamentos Controlados',
    'Antibióticos',
    'Analgésicos',
    'Vacinas',
    'Outros Medicamentos'
  ],
  8: [ // Material de Laboratório
    'Equipamentos de Laboratório',
    'Vidraria',
    'Reagentes',
    'Consumíveis de Laboratório'
  ],
  9: [ // Equipamentos Administrativos
    'Equipamentos de Comunicação',
    'Equipamentos de Segurança',
    'Equipamentos de Controle de Acesso',
    'Equipamentos de Climatização'
  ],
  10: [ // Outros
    'Itens Diversos',
    'Peças de Reposição',
    'Materiais de Manutenção',
    'Outros Equipamentos'
  ]
};

async function migrarCategorias() {
  console.log('Iniciando migração de categorias para grupos e classes...');
  
  // Para cada categoria, criar um grupo
  for (const categoria of categoriasIniciais) {
    console.log(`Processando categoria: ${categoria.nome}`);
    
    // Criar um UUID determinístico para a categoria
    const grupoId = `00000000-0000-0000-0000-${categoria.id.toString().padStart(12, '0')}`;
    
    // Inserir no banco como grupo
    const { error: erroGrupo } = await supabase
      .from('grupos')
      .insert({
        id: grupoId,
        nome: categoria.nome,
        descricao: `Grupo migrado da categoria: ${categoria.nome}`
      })
      .single();
    
    if (erroGrupo) {
      console.error(`Erro ao criar grupo para ${categoria.nome}:`, erroGrupo);
      continue;
    }
    
    console.log(`Grupo criado: ${categoria.nome}`);
    
    // Criar classes para este grupo
    if (classesPorCategoria[categoria.id]) {
      for (const nomeClasse of classesPorCategoria[categoria.id]) {
        const { error: erroClasse } = await supabase
          .from('classes')
          .insert({
            grupo_id: grupoId,
            nome: nomeClasse,
            descricao: `Classe para ${categoria.nome}`
          })
          .single();
        
        if (erroClasse) {
          console.error(`Erro ao criar classe ${nomeClasse}:`, erroClasse);
        } else {
          console.log(`  Classe criada: ${nomeClasse}`);
        }
      }
    }
  }
  
  console.log('Migração concluída!');
}

// Executar a migração
migrarCategorias()
  .catch(error => {
    console.error('Erro durante a migração:', error);
  })
  .finally(() => {
    console.log('Processo de migração finalizado.');
  }); 