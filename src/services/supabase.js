import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ruagsbbczuwgfflgcaol.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Função para obter tenant_id do usuário logado
export const getTenantId = async () => {
  const { data } = await supabase.auth.getSession()
  const user = data?.session?.user
  return user?.user_metadata?.tenant_id || null
}

export default supabase 