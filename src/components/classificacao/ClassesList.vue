<template>
  <div class="classes-list">
    <div class="header">
      <h3>Gerenciamento de Classes</h3>
      <button @click="mostrarFormulario = true" class="btn-add">
        Adicionar Classe
      </button>
    </div>

    <div v-if="loading" class="loading">
      <p>Carregando classes...</p>
    </div>

    <div v-else-if="classes.length === 0" class="empty-state">
      <p>Nenhuma classe cadastrada.</p>
    </div>

    <div v-else class="classes-table">
      <table>
        <thead>
          <tr>
            <th>Nome</th>
            <th>Grupo</th>
            <th>Descrição</th>
            <th>Data de Criação</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="classe in classes" :key="classe.id">
            <td>{{ classe.nome }}</td>
            <td>{{ getNomeGrupo(classe.grupo_id) }}</td>
            <td>{{ classe.descricao || '-' }}</td>
            <td>{{ formatarData(classe.created_at) }}</td>
            <td class="actions">
              <button @click="editarClasse(classe)" class="btn-edit">Editar</button>
              <button @click="confirmarExclusao(classe)" class="btn-delete">Excluir</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal de formulário -->
    <div v-if="mostrarFormulario" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ modoEdicao ? 'Editar' : 'Adicionar' }} Classe</h3>
          <button @click="fecharFormulario" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="salvarClasse">
            <div class="form-group">
              <label for="grupo">Grupo*</label>
              <select 
                id="grupo" 
                v-model="classeAtual.grupo_id" 
                required
              >
                <option value="">Selecione...</option>
                <option 
                  v-for="grupo in grupos" 
                  :key="grupo.id" 
                  :value="grupo.id"
                >
                  {{ grupo.nome }}
                </option>
              </select>
              <div v-if="grupos.length === 0" class="error-text">
                <p>É necessário cadastrar pelo menos um grupo antes de adicionar classes.</p>
              </div>
            </div>
            <div class="form-group">
              <label for="nome">Nome da Classe*</label>
              <input 
                id="nome" 
                v-model="classeAtual.nome" 
                type="text" 
                required
              >
            </div>
            <div class="form-group">
              <label for="descricao">Descrição</label>
              <textarea 
                id="descricao" 
                v-model="classeAtual.descricao" 
                rows="3"
              ></textarea>
            </div>
            <div class="form-actions">
              <button type="button" @click="fecharFormulario" class="btn-secondary">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="salvando || grupos.length === 0">
                {{ salvando ? 'Salvando...' : 'Salvar' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '@/services/supabase'
import { ref, reactive, onMounted } from 'vue'

export default {
  name: 'ClassesList',
  setup() {
    const classes = ref([]);
    const grupos = ref([]);
    const loading = ref(true);
    const salvando = ref(false);
    const mostrarFormulario = ref(false);
    const modoEdicao = ref(false);
    const classeAtual = reactive({
      id: null,
      grupo_id: '',
      nome: '',
      descricao: ''
    });

    // Carregar dados ao iniciar o componente
    onMounted(async () => {
      await Promise.all([
        carregarGrupos(),
        carregarClasses()
      ]);
    });

    const carregarGrupos = async () => {
      try {
        const { data, error } = await supabase
          .from('grupos')
          .select('*')
          .order('nome');

        if (error) throw error;
        grupos.value = data || [];
      } catch (error) {
        console.error('Erro ao carregar grupos:', error);
        alert('Erro ao carregar grupos. Por favor, tente novamente.');
      }
    };

    const carregarClasses = async () => {
      try {
        loading.value = true;
        const { data, error } = await supabase
          .from('classes')
          .select('*')
          .order('nome');

        if (error) throw error;
        classes.value = data || [];
      } catch (error) {
        console.error('Erro ao carregar classes:', error);
        alert('Erro ao carregar classes. Por favor, tente novamente.');
      } finally {
        loading.value = false;
      }
    };

    const getNomeGrupo = (grupoId) => {
      const grupo = grupos.value.find(g => g.id === grupoId);
      return grupo ? grupo.nome : 'Grupo não encontrado';
    };

    const formatarData = (dataString) => {
      if (!dataString) return '-';
      const data = new Date(dataString);
      return data.toLocaleDateString('pt-BR');
    };

    const editarClasse = (classe) => {
      modoEdicao.value = true;
      classeAtual.id = classe.id;
      classeAtual.grupo_id = classe.grupo_id;
      classeAtual.nome = classe.nome;
      classeAtual.descricao = classe.descricao || '';
      mostrarFormulario.value = true;
    };

    const fecharFormulario = () => {
      mostrarFormulario.value = false;
      modoEdicao.value = false;
      // Limpar formulário
      classeAtual.id = null;
      classeAtual.grupo_id = '';
      classeAtual.nome = '';
      classeAtual.descricao = '';
    };

    const salvarClasse = async () => {
      try {
        salvando.value = true;
        
        if (modoEdicao.value) {
          // Atualizar classe existente
          const { error } = await supabase
            .from('classes')
            .update({
              grupo_id: classeAtual.grupo_id,
              nome: classeAtual.nome,
              descricao: classeAtual.descricao
            })
            .eq('id', classeAtual.id);
            
          if (error) throw error;
          alert('Classe atualizada com sucesso!');
        } else {
          // Criar nova classe
          const { error } = await supabase
            .from('classes')
            .insert({
              grupo_id: classeAtual.grupo_id,
              nome: classeAtual.nome,
              descricao: classeAtual.descricao
            });
            
          if (error) throw error;
          alert('Classe adicionada com sucesso!');
        }
        
        // Recarregar lista e fechar formulário
        await carregarClasses();
        fecharFormulario();
      } catch (error) {
        console.error('Erro ao salvar classe:', error);
        alert(`Erro ao ${modoEdicao.value ? 'atualizar' : 'adicionar'} classe: ${error.message}`);
      } finally {
        salvando.value = false;
      }
    };

    const confirmarExclusao = (classe) => {
      if (confirm(`Deseja realmente excluir a classe "${classe.nome}"?`)) {
        excluirClasse(classe.id);
      }
    };

    const excluirClasse = async (id) => {
      try {
        loading.value = true;
        
        // Verificar se existem produtos associados a esta classe
        const { data: produtos, error: produtosError } = await supabase
          .from('produtos')
          .select('id')
          .eq('classe_id', id);
          
        if (produtosError) throw produtosError;
        
        // Se houver produtos, não permitir a exclusão
        if (produtos && produtos.length > 0) {
          alert(`Não é possível excluir esta classe porque existem ${produtos.length} produtos associados a ela.`);
          return;
        }
        
        // Realizar a exclusão
        const { error } = await supabase
          .from('classes')
          .delete()
          .eq('id', id);
          
        if (error) throw error;
        
        alert('Classe excluída com sucesso!');
        await carregarClasses();
      } catch (error) {
        console.error('Erro ao excluir classe:', error);
        alert(`Erro ao excluir classe: ${error.message}`);
      } finally {
        loading.value = false;
      }
    };

    return {
      classes,
      grupos,
      loading,
      salvando,
      mostrarFormulario,
      modoEdicao,
      classeAtual,
      carregarClasses,
      carregarGrupos,
      getNomeGrupo,
      formatarData,
      editarClasse,
      fecharFormulario,
      salvarClasse,
      confirmarExclusao
    };
  }
};
</script>

<style scoped>
.classes-list {
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.btn-add {
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 8px 16px;
  cursor: pointer;
}

.loading, .empty-state {
  padding: 20px;
  text-align: center;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.classes-table {
  width: 100%;
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  padding: 12px 15px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

th {
  background-color: #f2f2f2;
  font-weight: bold;
}

.actions {
  display: flex;
  gap: 8px;
}

.btn-edit, .btn-delete {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-edit {
  background-color: #3498db;
  color: white;
}

.btn-delete {
  background-color: #e74c3c;
  color: white;
}

.error-text {
  color: #e74c3c;
  font-size: 14px;
  margin-top: 4px;
}

/* Modal styles */
.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background-color: white;
  border-radius: 8px;
  width: 500px;
  max-width: 90%;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid #eee;
}

.modal-header h3 {
  margin: 0;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
}

.modal-body {
  padding: 20px;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 20px;
}

.btn-secondary {
  background-color: #95a5a6;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 8px 16px;
  cursor: pointer;
}

.btn-primary {
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 8px 16px;
  cursor: pointer;
}

.btn-primary:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}
</style> 