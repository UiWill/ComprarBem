// Script para gerar hash SHA-256 do código-fonte para registro INPI
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Diretórios e arquivos a incluir no hash
const DIRETORIOS_INCLUIR = [
  'src',
  'public'
];

const ARQUIVOS_RAIZ = [
  'package.json',
  'vue.config.js'
];

const EXTENSOES_INCLUIR = ['.js', '.vue', '.json', '.html', '.css'];
const IGNORAR = ['node_modules', 'dist', 'coverage', '.git', 'gerar_hash_inpi.js'];

function deveIncluir(caminho) {
  const nomeArquivo = path.basename(caminho);
  const extensao = path.extname(caminho);

  // Ignorar arquivos/pastas específicos
  if (IGNORAR.some(ignore => caminho.includes(ignore))) {
    return false;
  }

  // Incluir apenas extensões permitidas
  return EXTENSOES_INCLUIR.includes(extensao);
}

function obterArquivos(dir, arquivos = []) {
  const items = fs.readdirSync(dir);

  for (const item of items) {
    const caminhoCompleto = path.join(dir, item);

    if (IGNORAR.some(ignore => caminhoCompleto.includes(ignore))) {
      continue;
    }

    const stat = fs.statSync(caminhoCompleto);

    if (stat.isDirectory()) {
      obterArquivos(caminhoCompleto, arquivos);
    } else if (deveIncluir(caminhoCompleto)) {
      arquivos.push(caminhoCompleto);
    }
  }

  return arquivos;
}

function gerarHashProjeto() {
  console.log('🔍 Coletando arquivos do projeto...\n');

  let todosArquivos = [];

  // Adicionar arquivos da raiz
  for (const arquivo of ARQUIVOS_RAIZ) {
    const caminho = path.join(process.cwd(), arquivo);
    if (fs.existsSync(caminho)) {
      todosArquivos.push(caminho);
    }
  }

  // Adicionar arquivos dos diretórios
  for (const dir of DIRETORIOS_INCLUIR) {
    const caminho = path.join(process.cwd(), dir);
    if (fs.existsSync(caminho)) {
      todosArquivos = todosArquivos.concat(obterArquivos(caminho));
    }
  }

  // Ordenar para garantir consistência
  todosArquivos.sort();

  console.log(`📁 Total de arquivos encontrados: ${todosArquivos.length}\n`);
  console.log('📋 Arquivos incluídos:');
  todosArquivos.forEach(arquivo => {
    console.log(`   - ${path.relative(process.cwd(), arquivo)}`);
  });

  console.log('\n⏳ Gerando hash SHA-256...\n');

  // Criar hash combinado de todos os arquivos
  const hash = crypto.createHash('sha256');

  for (const arquivo of todosArquivos) {
    const conteudo = fs.readFileSync(arquivo);
    hash.update(conteudo);
  }

  const hashFinal = hash.digest('hex');

  // Resultados
  console.log('═══════════════════════════════════════════════════════════');
  console.log('📄 INFORMAÇÕES PARA REGISTRO NO INPI');
  console.log('═══════════════════════════════════════════════════════════\n');

  console.log('1️⃣  ALGORITMO HASH:');
  console.log('   SHA-256\n');

  console.log('2️⃣  RESUMO DIGITAL (HASH):');
  console.log(`   ${hashFinal}\n`);

  console.log('3️⃣  TIPO DE PROGRAMA:');
  console.log('   Aplicativo - Sistema de Gestão de Compras Públicas\n');

  console.log('4️⃣  INFORMAÇÕES ADICIONAIS:');
  console.log(`   - Total de arquivos: ${todosArquivos.length}`);
  console.log(`   - Tamanho total: ${calcularTamanhoTotal(todosArquivos)} KB`);
  console.log(`   - Data de geração: ${new Date().toLocaleString('pt-BR')}\n`);

  console.log('═══════════════════════════════════════════════════════════\n');

  // Salvar em arquivo
  const relatorio = `REGISTRO INPI - COMPRAR BEM
═══════════════════════════════════════════════════════════

INFORMAÇÕES PARA PREENCHIMENTO DO FORMULÁRIO INPI

1. ALGORITMO HASH:
   SHA-256

2. RESUMO DIGITAL (HASH):
   ${hashFinal}

3. TIPO DE PROGRAMA:
   Aplicativo - Sistema de Gestão de Compras Públicas

4. DESCRIÇÃO DO SOFTWARE:
   Sistema de gestão de compras e licitações públicas com funcionalidades de:
   - Pré-qualificação e padronização de produtos (DCB)
   - Catálogo eletrônico de produtos padronizados
   - Pesquisa de mercado e referência de preços
   - Gestão de processos administrativos
   - Avaliação de desempenho pós-compra (RDM)
   - Assistente de IA especializado em licitações (QualiBot 2.0)

5. TECNOLOGIAS UTILIZADAS:
   - Frontend: Vue.js 2.7.16
   - Backend: Supabase (PostgreSQL)
   - IA: Google Gemini API
   - Build: Vue CLI 5.0

6. INFORMAÇÕES DO HASH:
   - Total de arquivos analisados: ${todosArquivos.length}
   - Tamanho total: ${calcularTamanhoTotal(todosArquivos)} KB
   - Data de geração: ${new Date().toLocaleString('pt-BR')}

═══════════════════════════════════════════════════════════
`;

  fs.writeFileSync('HASH_INPI.txt', relatorio);
  console.log('✅ Relatório salvo em: HASH_INPI.txt\n');

  return hashFinal;
}

function calcularTamanhoTotal(arquivos) {
  let tamanhoTotal = 0;
  for (const arquivo of arquivos) {
    const stat = fs.statSync(arquivo);
    tamanhoTotal += stat.size;
  }
  return Math.round(tamanhoTotal / 1024);
}

// Executar
try {
  gerarHashProjeto();
} catch (error) {
  console.error('❌ Erro ao gerar hash:', error);
  process.exit(1);
}
