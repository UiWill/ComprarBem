<template>
  <div class="debug-usuarios">
    <div class="card">
      <div class="card-header">
        <h3>🔍 Debug - Sistema de Usuários</h3>
        <p>Ferramenta para diagnosticar problemas de usuários órfãos</p>
      </div>
      
      <div class="card-body">
        <!-- Botões de Ação -->
        <div class="debug-actions">
          <button @click="verificarSistema" class="btn btn-primary" :disabled="carregando">
            <i class="fas fa-search"></i> Verificar Sistema
          </button>
          
          <button @click="limparUsuariosOrfaos" class="btn btn-warning" :disabled="carregando">
            <i class="fas fa-broom"></i> Limpar Órfãos
          </button>
          
          <button @click="limparTudo" class="btn btn-danger" :disabled="carregando">
            <i class="fas fa-trash"></i> Limpar Tudo
          </button>
        </div>

        <!-- Loading -->
        <div v-if="carregando" class="loading">
          <i class="fas fa-spinner fa-spin"></i> Carregando...
        </div>

        <!-- Resultados -->
        <div v-if="resultados" class="resultados">
          <h4>📊 Diagnóstico do Sistema</h4>
          
          <!-- Usuários na Tabela -->
          <div class="secao">
            <h5>👥 Usuários na Tabela ({{usuariosTabela.length}})</h5>
            <div v-if="usuariosTabela.length === 0" class="alert alert-success">
              ✅ Nenhum usuário encontrado - tabela limpa
            </div>
            <div v-else class="usuarios-lista">
              <div v-for="usuario in usuariosTabela" :key="usuario.id" class="usuario-item">
                <strong>{{usuario.email}}</strong> - {{usuario.nome}} 
                <span class="badge" :class="usuario.ativo ? 'badge-success' : 'badge-danger'">
                  {{usuario.ativo ? 'Ativo' : 'Inativo'}}
                </span>
                <span class="badge badge-info">{{usuario.tipo}}</span>
                <span class="badge badge-secondary">{{usuario.perfil_usuario}}</span>
              </div>
            </div>
          </div>

          <!-- Tenants -->
          <div class="secao">
            <h5>🏢 Tenants ({{tenants.length}})</h5>
            <div v-if="tenants.length === 0" class="alert alert-success">
              ✅ Nenhum tenant encontrado - tabela limpa
            </div>
            <div v-else class="tenants-lista">
              <div v-for="tenant in tenants" :key="tenant.id" class="tenant-item">
                <strong>{{tenant.nome}}</strong> - ID: {{tenant.id}}
                <span class="badge" :class="tenant.ativo ? 'badge-success' : 'badge-danger'">
                  {{tenant.ativo ? 'Ativo' : 'Inativo'}}
                </span>
              </div>
            </div>
          </div>

          <!-- Teste de Emails -->
          <div class="secao">
            <h5>📧 Teste de Emails</h5>
            <div class="email-teste">
              <input 
                type="email" 
                v-model="emailTeste" 
                placeholder="Digite um email para testar"
                class="form-control"
              >
              <button @click="testarEmail" class="btn btn-secondary">
                <i class="fas fa-check"></i> Testar
              </button>
            </div>
            <div v-if="resultadoEmailTeste" class="mt-2">
              {{resultadoEmailTeste}}
            </div>
          </div>
        </div>

        <!-- Mensagens -->
        <div v-if="mensagem" class="alert" :class="tipoMensagem">
          {{mensagem}}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import LimpezaUsuariosService from '@/services/limpezaUsuariosService'

export default {
  name: 'DebugUsuarios',
  data() {
    return {
      carregando: false,
      resultados: null,
      usuariosTabela: [],
      tenants: [],
      mensagem: '',
      tipoMensagem: '',
      emailTeste: 'teste@exemplo.com',
      resultadoEmailTeste: ''
    }
  },
  methods: {
    async verificarSistema() {
      try {
        this.carregando = true
        this.mensagem = ''
        
        console.log('🔍 Iniciando verificação do sistema...')
        
        // Buscar usuários
        this.usuariosTabela = await LimpezaUsuariosService.listarUsuariosTabela()
        
        // Buscar tenants
        const { data: tenants } = await supabase
          .from('tenants')
          .select('*')
          .order('criado_em', { ascending: false })
        
        this.tenants = tenants || []
        this.resultados = true
        
        this.mostrarMensagem('Sistema verificado com sucesso!', 'alert-success')
        
      } catch (error) {
        console.error('Erro na verificação:', error)
        this.mostrarMensagem(`Erro: ${error.message}`, 'alert-danger')
      } finally {
        this.carregando = false
      }
    },

    async limparUsuariosOrfaos() {
      try {
        this.carregando = true
        
        const emails = this.usuariosTabela.map(u => u.email)
        
        if (emails.length === 0) {
          this.mostrarMensagem('Nenhum usuário para limpar', 'alert-info')
          return
        }
        
        const confirmacao = confirm(`Deseja limpar ${emails.length} usuários órfãos?`)
        if (!confirmacao) return
        
        await LimpezaUsuariosService.limpezaCompleta(emails)
        
        this.mostrarMensagem('Limpeza concluída!', 'alert-success')
        await this.verificarSistema()
        
      } catch (error) {
        console.error('Erro na limpeza:', error)
        this.mostrarMensagem(`Erro: ${error.message}`, 'alert-danger')
      } finally {
        this.carregando = false
      }
    },

    async limparTudo() {
      try {
        const confirmacao = confirm('⚠️ ATENÇÃO: Isso irá deletar TODOS os usuários e tenants. Continuar?')
        if (!confirmacao) return
        
        const confirmacao2 = confirm('Tem certeza? Esta ação não pode ser desfeita!')
        if (!confirmacao2) return
        
        this.carregando = true
        
        // Deletar todos os usuários
        await supabase
          .from('usuarios')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000') // Condição que sempre é verdadeira
        
        // Deletar todos os tenants
        await supabase
          .from('tenants')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000')
        
        this.mostrarMensagem('Sistema completamente limpo!', 'alert-success')
        await this.verificarSistema()
        
      } catch (error) {
        console.error('Erro na limpeza completa:', error)
        this.mostrarMensagem(`Erro: ${error.message}`, 'alert-danger')
      } finally {
        this.carregando = false
      }
    },

    async testarEmail() {
      try {
        if (!this.emailTeste) return
        
        const disponivel = await LimpezaUsuariosService.emailEstaLivre(this.emailTeste)
        this.resultadoEmailTeste = disponivel 
          ? `✅ Email ${this.emailTeste} está LIVRE para uso`
          : `❌ Email ${this.emailTeste} JÁ EXISTE no sistema`
        
      } catch (error) {
        this.resultadoEmailTeste = `Erro: ${error.message}`
      }
    },

    mostrarMensagem(texto, tipo) {
      this.mensagem = texto
      this.tipoMensagem = tipo
      setTimeout(() => {
        this.mensagem = ''
      }, 5000)
    }
  },

  mounted() {
    // Verificar sistema automaticamente ao carregar
    this.verificarSistema()
  }
}
</script>

<style scoped>
.debug-usuarios {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.card {
  border: 1px solid #ddd;
  border-radius: 8px;
  overflow: hidden;
}

.card-header {
  background-color: #f8f9fa;
  padding: 20px;
  border-bottom: 1px solid #ddd;
}

.card-header h3 {
  margin: 0 0 10px 0;
  color: #333;
}

.card-body {
  padding: 20px;
}

.debug-actions {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.btn {
  padding: 10px 15px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background-color: #007bff;
  color: white;
}

.btn-warning {
  background-color: #ffc107;
  color: #212529;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
}

.btn-secondary {
  background-color: #6c757d;
  color: white;
}

.loading {
  text-align: center;
  padding: 20px;
  color: #666;
}

.resultados {
  margin-top: 20px;
}

.secao {
  margin-bottom: 30px;
  padding: 15px;
  border: 1px solid #eee;
  border-radius: 5px;
}

.secao h5 {
  margin: 0 0 15px 0;
  color: #333;
}

.usuarios-lista, .tenants-lista {
  max-height: 200px;
  overflow-y: auto;
}

.usuario-item, .tenant-item {
  padding: 8px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 5px;
}

.badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: bold;
}

.badge-success {
  background-color: #28a745;
  color: white;
}

.badge-danger {
  background-color: #dc3545;
  color: white;
}

.badge-info {
  background-color: #17a2b8;
  color: white;
}

.badge-secondary {
  background-color: #6c757d;
  color: white;
}

.email-teste {
  display: flex;
  gap: 10px;
  align-items: center;
}

.form-control {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.alert {
  padding: 12px;
  border-radius: 4px;
  margin-top: 15px;
}

.alert-success {
  background-color: #d4edda;
  border-color: #c3e6cb;
  color: #155724;
}

.alert-danger {
  background-color: #f8d7da;
  border-color: #f5c6cb;
  color: #721c24;
}

.alert-info {
  background-color: #d1ecf1;
  border-color: #bee5eb;
  color: #0c5460;
}
</style>