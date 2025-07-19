const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://ruagsbbczuwgfflgcaol.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function analisarEmailsEnviados() {
    console.log('📧 Analisando estrutura da tabela emails_enviados...\n')
    
    try {
        // Buscar um registro para ver a estrutura
        const { data: emails, error } = await supabase
            .from('emails_enviados')
            .select('*')
            .limit(1)
        
        if (error) {
            console.error('❌ Erro ao buscar emails_enviados:', error.message)
            return
        }
        
        if (emails && emails.length > 0) {
            console.log('✅ Estrutura da tabela emails_enviados:')
            const registro = emails[0]
            
            Object.keys(registro).forEach(coluna => {
                const valor = registro[coluna]
                const tipo = typeof valor
                console.log(`  • ${coluna}: ${tipo} = ${valor}`)
            })
        } else {
            console.log('⚠️ Tabela emails_enviados existe mas está vazia')
            
            // Tentar inserir um registro de teste para ver os campos obrigatórios
            const { data: insertTest, error: insertError } = await supabase
                .from('emails_enviados')
                .insert({
                    tipo: 'teste',
                    destinatario: 'teste@exemplo.com',
                    assunto: 'Teste de estrutura'
                })
                .select()
            
            if (insertError) {
                console.log('❌ Erro ao inserir teste:', insertError.message)
                console.log('💡 Detalhes do erro:', insertError.details)
            } else {
                console.log('✅ Registro de teste inserido com sucesso')
                console.log('🔍 Estrutura detectada:', Object.keys(insertTest[0]))
                
                // Remover o registro de teste
                await supabase
                    .from('emails_enviados')
                    .delete()
                    .eq('id', insertTest[0].id)
            }
        }
        
    } catch (error) {
        console.error('❌ Erro na análise:', error.message)
    }
}

analisarEmailsEnviados()