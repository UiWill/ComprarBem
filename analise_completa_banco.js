const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://ruagsbbczuwgfflgcaol.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Lista de tabelas para verificar
const tabelasParaVerificar = [
    'tenants', 'usuarios', 'usuarios_rdm', 'emails_enviados', 'rdm_feedbacks',
    'material_feedbacks', 'reclamacoes_usuarios', 'usuarios_rdm_produtos',
    'lembretes_enviados', 'configuracoes_sistema', 'produtos', 'categorias',
    'fornecedores', 'licitacoes', 'participantes', 'diligencias'
]

async function analisarBancoCompleto() {
    console.log('🔍 ANÁLISE COMPLETA DO BANCO DE DADOS - COMPRAR BEM')
    console.log('=' .repeat(80))
    
    const tabelasEncontradas = []
    const tabelasComErro = []
    
    // Verificar cada tabela
    for (const nomeTabela of tabelasParaVerificar) {
        try {
            console.log(`\n📊 Analisando tabela: ${nomeTabela}`)
            console.log('-'.repeat(50))
            
            const { data, error, count } = await supabase
                .from(nomeTabela)
                .select('*', { count: 'exact' })
                .limit(1)
            
            if (error) {
                console.log(`❌ Erro: ${error.message}`)
                tabelasComErro.push({ nome: nomeTabela, erro: error.message })
                continue
            }
            
            // Tabela existe
            tabelasEncontradas.push({
                nome: nomeTabela,
                totalRegistros: count || 0,
                colunas: data && data.length > 0 ? Object.keys(data[0]) : [],
                exemploRegistro: data && data.length > 0 ? data[0] : null
            })
            
            console.log(`✅ Tabela encontrada!`)
            console.log(`📈 Total de registros: ${count || 0}`)
            
            if (data && data.length > 0) {
                const colunas = Object.keys(data[0])
                console.log(`📋 Colunas (${colunas.length}):`)
                colunas.forEach(col => {
                    const valor = data[0][col]
                    const tipo = typeof valor
                    console.log(`   • ${col}: ${tipo} ${valor !== null ? `(ex: ${JSON.stringify(valor)})` : '(null)'}`)
                })
            } else {
                console.log(`⚠️  Tabela vazia`)
            }
            
        } catch (error) {
            console.log(`❌ Erro inesperado: ${error.message}`)
            tabelasComErro.push({ nome: nomeTabela, erro: error.message })
        }
    }
    
    // Resumo final
    console.log('\n' + '='.repeat(80))
    console.log('📊 RESUMO FINAL')
    console.log('='.repeat(80))
    
    console.log(`\n✅ TABELAS ENCONTRADAS (${tabelasEncontradas.length}):`)
    tabelasEncontradas.forEach(tabela => {
        console.log(`   • ${tabela.nome} (${tabela.totalRegistros} registros, ${tabela.colunas.length} colunas)`)
    })
    
    console.log(`\n❌ TABELAS COM ERRO (${tabelasComErro.length}):`)
    tabelasComErro.forEach(tabela => {
        console.log(`   • ${tabela.nome}: ${tabela.erro}`)
    })
    
    // Salvar análise em arquivo
    const analise = {
        dataAnalise: new Date().toISOString(),
        tabelasEncontradas,
        tabelasComErro,
        estatisticas: {
            totalTabelas: tabelasParaVerificar.length,
            tabelasExistentes: tabelasEncontradas.length,
            tabelasComErro: tabelasComErro.length,
            registrosTotais: tabelasEncontradas.reduce((total, t) => total + t.totalRegistros, 0)
        }
    }
    
    require('fs').writeFileSync('analise_banco_completa.json', JSON.stringify(analise, null, 2))
    console.log('\n💾 Análise salva em: analise_banco_completa.json')
    
    return analise
}

// Executar análise
analisarBancoCompleto().catch(console.error)