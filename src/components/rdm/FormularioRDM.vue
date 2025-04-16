<template>
  <div class="rdm-container">
    <h2>Relatório de Desempenho de Material (RDM)</h2>
    
    <form @submit.prevent="enviarFeedback">
      <div class="form-group">
        <label for="produto">Produto*</label>
        <select 
          id="produto" 
          v-model="feedback.produto_id" 
          required
        >
          <option value="">Selecione o produto...</option>
          <option 
            v-for="produto in produtos" 
            :key="produto.id" 
            :value="produto.id"
          >
            {{ produto.nome }} - {{ produto.marca }} - {{ produto.modelo }}
          </option>
        </select>
      </div>
      
      <div class="form-group">
        <label>Avaliação*</label>
        <div class="avaliacao">
          <div 
            v-for="n in 5" 
            :key="n" 
            class="estrela" 
            :class="{ ativa: feedback.avaliacao >= n }"
            @click="feedback.avaliacao = n"
          >
            ★
          </div>
        </div>
      </div>
      
      <div class="form-group">
        <label for="comentario">Justificativa da Avaliação*</label>
        <textarea 
          id="comentario" 
          v-model="feedback.comentario" 
          rows="4" 
          placeholder="Ex: Equipamento apresentou falha após 3 meses de uso..."
          required
        ></textarea>
      </div>
      
      <div class="form-actions">
        <button type="submit" class="btn-primary" :disabled="loading">
          {{ loading ? 'Salvando...' : 'Salvar' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { v4 as uuidv4 } from 'uuid'

export default {
  name: 'FormularioRDM',
  data() {
    return {
      feedback: {
        produto_id: '',
        avaliacao: 0,
        comentario: ''
      },
      produtos: [],
      loading: false,
      currentUser: null,
      currentTenantId: null
    }
  },
  created() {
    this.carregarProdutos()
    this.obterUsuarioAtual()
  },
  methods: {
    async obterUsuarioAtual() {
      try {
        // Obter dados da sessão atual
        const { data: authData } = await supabase.auth.getSession()
        const user = authData?.session?.user
        
        if (user) {
          this.currentUser = user
          
          // Tentar obter tenant_id dos metadados
          if (user.user_metadata?.tenant_id) {
            this.currentTenantId = user.user_metadata.tenant_id
          } else {
            // Gerar um UUID para o tenant se não existir
            this.currentTenantId = uuidv4()
          }
        } else {
          // Se não houver usuário logado, gerar UUIDs temporários
          this.currentTenantId = uuidv4()
        }
      } catch (error) {
        console.error('Erro ao obter dados do usuário:', error)
        // Em caso de erro, gerar UUIDs temporários
        this.currentTenantId = uuidv4()
      }
    },
    async carregarProdutos() {
      try {
        // Garantir que temos o tenant_id antes de carregar os produtos
        await this.obterUsuarioAtual();
        
        if (!this.currentTenantId) {
          console.error('Não foi possível identificar o tenant_id');
          this.produtos = [];
          return;
        }
        
        console.log('Carregando produtos para o tenant:', this.currentTenantId);
        
        const { data, error } = await supabase
          .from('produtos')
          .select('*')
          .eq('status', 'aprovado')
          .eq('tenant_id', this.currentTenantId) // Filtrar por tenant_id
          .order('nome');
        
        if (error) throw error;
        console.log('Produtos carregados:', data?.length || 0);
        this.produtos = data || [];
      } catch (error) {
        console.error('Erro ao carregar produtos:', error);
        alert('Erro ao carregar produtos. Por favor, tente novamente.');
      }
    },
    async enviarFeedback() {
      if (this.feedback.avaliacao === 0) {
        alert('Por favor, selecione uma avaliação de 1 a 5 estrelas.')
        return
      }
      
      try {
        this.loading = true
        
        // Garantir que temos IDs válidos
        if (!this.currentTenantId) {
          this.currentTenantId = uuidv4()
        }
        
        // Buscar o ID do usuário na tabela 'usuarios'
        let usuarioId;
        
        if (this.currentUser?.email) {
          console.log('Buscando ID do usuário na tabela usuarios pelo email:', this.currentUser.email);
          const { data: usuarioData, error: usuarioError } = await supabase
            .from('usuarios')
            .select('id')
            .eq('email', this.currentUser.email)
            .maybeSingle();
            
          if (usuarioError) {
            console.error('Erro ao buscar usuário:', usuarioError);
          }
          
          if (usuarioData?.id) {
            usuarioId = usuarioData.id;
            console.log('ID do usuário encontrado na tabela usuarios:', usuarioId);
          } else {
            console.warn('Usuário não encontrado na tabela usuarios, gerando ID temporário');
            usuarioId = uuidv4();
            
            // Tentar criar um usuário na tabela para futuras referências
            try {
              const { error: insertError } = await supabase
                .from('usuarios')
                .insert({
                  id: usuarioId,
                  email: this.currentUser.email,
                  nome: this.currentUser.email.split('@')[0],
                  tenant_id: this.currentTenantId,
                  tipo: 'cliente',
                  ativo: true
                });
                
              if (insertError) {
                console.error('Erro ao criar usuário na tabela:', insertError);
              }
            } catch (e) {
              console.error('Exceção ao criar usuário:', e);
            }
          }
        } else {
          console.warn('Usuário não está autenticado, gerando ID temporário');
          usuarioId = uuidv4();
        }
        
        console.log('Enviando feedback com:', {
          produto_id: this.feedback.produto_id,
          usuario_id: usuarioId,
          tenant_id: this.currentTenantId
        })
        
        const { error } = await supabase
          .from('rdm_feedbacks')
          .insert({
            produto_id: this.feedback.produto_id,
            usuario_id: usuarioId, // ID da tabela usuarios
            tenant_id: this.currentTenantId,
            avaliacao: this.feedback.avaliacao,
            comentario: this.feedback.comentario
          })
        
        if (error) throw error
        
        this.$swal({
          icon: 'success',
          title: 'Feedback enviado!',
          text: 'Seu feedback foi enviado com sucesso.'
        })
        
        this.limparFormulario()
      } catch (error) {
        console.error('Erro ao enviar feedback:', error)
        this.$swal({
          icon: 'error',
          title: 'Erro ao enviar feedback',
          text: 'Por favor, tente novamente.'
        })
      } finally {
        this.loading = false
      }
    },
    limparFormulario() {
      this.feedback = {
        produto_id: '',
        avaliacao: 0,
        comentario: ''
      }
    }
  }
}
</script>

<style scoped>
.rdm-container {
  padding: 20px;
  max-width: 600px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

select, textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

textarea {
  resize: vertical;
}

.avaliacao {
  display: flex;
  font-size: 30px;
  cursor: pointer;
}

.estrela {
  color: #ddd;
  margin-right: 5px;
}

.estrela.ativa {
  color: #f1c40f;
}

.form-actions {
  margin-top: 20px;
}

.btn-primary {
  padding: 10px 20px;
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary:disabled {
  background-color: #95a5a6;
}
</style> 