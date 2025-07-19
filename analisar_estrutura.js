const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://ruagsbbczuwgfflgcaol.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function analisarEstrutura() {
    console.log('🔍 Analisando estrutura do banco de dados...\n')
    
    try {
        // Buscar informações das tabelas
        console.log('🔍 Testando conexão com Supabase...')
        
        // Tentar buscar tabelas diretamente
        const { data: emailsEnviados, error: errorEmails } = await supabase
            .from('emails_enviados')
            .select('*')
            .limit(1)
        
        console.log('📧 Tabela emails_enviados:', {
            existe: !errorEmails,
            erro: errorEmails?.message,
            colunas: emailsEnviados ? Object.keys(emailsEnviados[0] || {}) : []
        })
        
        const { data: usuariosRdm, error: errorUsuarios } = await supabase
            .from('usuarios_rdm')
            .select('*')
            .limit(1)
        
        console.log('👥 Tabela usuarios_rdm:', {
            existe: !errorUsuarios,
            erro: errorUsuarios?.message,
            colunas: usuariosRdm ? Object.keys(usuariosRdm[0] || {}) : []
        })
        
        const { data: tenants, error: errorTenants } = await supabase
            .from('tenants')
            .select('*')
            .limit(1)
        
        console.log('🏢 Tabela tenants:', {
            existe: !errorTenants,
            erro: errorTenants?.message,
            colunas: tenants ? Object.keys(tenants[0] || {}) : []
        })
        
        const { data: rdmFeedbacks, error: errorFeedbacks } = await supabase
            .from('rdm_feedbacks')
            .select('*')
            .limit(1)
        
        console.log('⭐ Tabela rdm_feedbacks:', {
            existe: !errorFeedbacks,
            erro: errorFeedbacks?.message,
            colunas: rdmFeedbacks ? Object.keys(rdmFeedbacks[0] || {}) : []
        })
        
        // Testar se as novas tabelas já existem
        const { data: usuariosRdmProdutos, error: errorProdutos } = await supabase
            .from('usuarios_rdm_produtos')
            .select('*')
            .limit(1)
        
        console.log('📦 Tabela usuarios_rdm_produtos:', {
            existe: !errorProdutos,
            erro: errorProdutos?.message,
            colunas: usuariosRdmProdutos ? Object.keys(usuariosRdmProdutos[0] || {}) : []
        })
        
        const { data: lembretesEnviados, error: errorLembretes } = await supabase
            .from('lembretes_enviados')
            .select('*')
            .limit(1)
        
        console.log('⏰ Tabela lembretes_enviados:', {
            existe: !errorLembretes,
            erro: errorLembretes?.message,
            colunas: lembretesEnviados ? Object.keys(lembretesEnviados[0] || {}) : []
        })
        
    } catch (error) {
        console.error('❌ Erro na análise:', error.message)
    }
}

analisarEstrutura()