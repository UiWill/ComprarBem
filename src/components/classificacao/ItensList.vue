<template>
  <div class="itens-list">
    <div class="header">
      <h3>Gerenciamento de Itens</h3>
      <button @click="mostrarFormulario = true" class="btn-add">
        Adicionar Item
      </button>
    </div>

    <div v-if="loading" class="loading">
      <p>Carregando itens...</p>
    </div>

    <div v-else-if="itens.length === 0" class="empty-state">
      <p>Nenhum item cadastrado.</p>
    </div>

    <div v-else class="itens-table">
      <table>
        <thead>
          <tr>
            <th>Código do Item</th>
            <th>Nome</th>
            <th>Classe</th>
            <th>Grupo</th>
            <th>Marca/Modelo de Referência</th>
            <th>Descrição</th>
            <th>Data de Criação</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in itens" :key="item.id">
            <td>{{ item.codigo || item.id.slice(0, 8) }}</td>
            <td>{{ item.nome }}</td>
            <td>{{ getNomeClasse(item.classe_id) }}</td>
            <td>{{ getNomeGrupo(item.grupo_id) }}</td>
            <td>{{ item.marca_modelo_referencia || '-' }}</td>
            <td>{{ item.descricao || '-' }}</td>
            <td>{{ formatarData(item.created_at) }}</td>
            <td class="actions">
              <button @click="editarItem(item)" class="btn-edit">Editar</button>
              <button @click="confirmarExclusao(item)" class="btn-delete">Excluir</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal de formulário -->
    <div v-if="mostrarFormulario" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ modoEdicao ? 'Editar' : 'Adicionar' }} Item</h3>
          <button @click="fecharFormulario" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="salvarItem">
            <div class="form-group">
              <label for="grupo">Grupo*</label>
              <select 
                id="grupo" 
                v-model="itemAtual.grupo_id" 
                @change="carregarClassesPorGrupo"
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
                <p>É necessário cadastrar pelo menos um grupo antes de adicionar itens.</p>
              </div>
            </div>
            
            <div class="form-group">
              <label for="classe">Classe*</label>
              <select 
                id="classe" 
                v-model="itemAtual.classe_id" 
                required
                :disabled="!itemAtual.grupo_id"
              >
                <option value="">Selecione primeiro o grupo...</option>
                <option 
                  v-for="classe in classesFiltradas" 
                  :key="classe.id" 
                  :value="classe.id"
                >
                  {{ classe.nome }}
                </option>
              </select>
            </div>
            
            <div class="form-group">
              <label for="codigo">Código do Item</label>
              <input 
                id="codigo" 
                v-model="itemAtual.codigo" 
                type="text" 
                placeholder="Ex: ITM001"
              >
              <small>Se não informado, será gerado automaticamente</small>
            </div>
            
            <div class="form-group">
              <label for="nome">Nome do Item*</label>
              <input 
                id="nome" 
                v-model="itemAtual.nome" 
                type="text" 
                required
              >
            </div>
            
            <div class="form-group">
              <label for="marca_modelo">Marca/Modelo de Referência</label>
              <input 
                id="marca_modelo" 
                v-model="itemAtual.marca_modelo_referencia" 
                type="text" 
                placeholder="Ex: Samsung Galaxy S21, Dell Inspiron 15"
              >
            </div>
            
            <div class="form-group">
              <label for="descricao">Descrição</label>
              <textarea 
                id="descricao" 
                v-model="itemAtual.descricao" 
                rows="3"
                placeholder="Descrição detalhada do item..."
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
  name: 'ItensList',
  setup() {
    const itens = ref([]);
    const grupos = ref([]);
    const classes = ref([]);
    const classesFiltradas = ref([]);
    const loading = ref(true);
    const salvando = ref(false);
    const mostrarFormulario = ref(false);
    const modoEdicao = ref(false);
    const itemAtual = reactive({
      id: null,
      grupo_id: '',
      classe_id: '',
      codigo: '',
      nome: '',
      marca_modelo_referencia: '',
      descricao: ''
    });

    // Carregar dados ao iniciar o componente
    onMounted(async () => {
      await Promise.all([
        carregarGrupos(),
        carregarClasses(),
        carregarItens()
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
        const { data, error } = await supabase
          .from('classes')
          .select('*')
          .order('nome');

        if (error) throw error;
        classes.value = data || [];
      } catch (error) {
        console.error('Erro ao carregar classes:', error);
        alert('Erro ao carregar classes. Por favor, tente novamente.');
      }
    };

    const carregarItens = async () => {
      try {
        loading.value = true;
        const { data, error } = await supabase
          .from('itens_materiais')
          .select('*')
          .order('nome');

        if (error) throw error;
        itens.value = data || [];
      } catch (error) {
        console.error('Erro ao carregar itens:', error);
        alert('Erro ao carregar itens. Por favor, tente novamente.');
      } finally {
        loading.value = false;
      }
    };

    const carregarClassesPorGrupo = () => {
      if (itemAtual.grupo_id) {
        classesFiltradas.value = classes.value.filter(classe => classe.grupo_id === itemAtual.grupo_id);
        itemAtual.classe_id = ''; // Resetar classe quando grupo mudar
      } else {
        classesFiltradas.value = [];
      }
    };

    const getNomeGrupo = (grupoId) => {
      const grupo = grupos.value.find(g => g.id === grupoId);
      return grupo ? grupo.nome : 'Grupo não encontrado';
    };

    const getNomeClasse = (classeId) => {
      const classe = classes.value.find(c => c.id === classeId);
      return classe ? classe.nome : 'Classe não encontrada';
    };

    const formatarData = (dataString) => {
      if (!dataString) return '-';
      const data = new Date(dataString);
      return data.toLocaleDateString('pt-BR');
    };

    const editarItem = (item) => {
      modoEdicao.value = true;
      itemAtual.id = item.id;
      itemAtual.grupo_id = item.grupo_id;
      itemAtual.classe_id = item.classe_id;
      itemAtual.codigo = item.codigo || '';
      itemAtual.nome = item.nome;
      itemAtual.marca_modelo_referencia = item.marca_modelo_referencia || '';
      itemAtual.descricao = item.descricao || '';
      
      // Carregar classes do grupo
      carregarClassesPorGrupo();
      mostrarFormulario.value = true;
    };

    const fecharFormulario = () => {
      mostrarFormulario.value = false;
      modoEdicao.value = false;
      // Limpar formulário
      itemAtual.id = null;
      itemAtual.grupo_id = '';
      itemAtual.classe_id = '';
      itemAtual.codigo = '';
      itemAtual.nome = '';
      itemAtual.marca_modelo_referencia = '';
      itemAtual.descricao = '';
      classesFiltradas.value = [];
    };

    const salvarItem = async () => {
      try {
        salvando.value = true;
        
        if (modoEdicao.value) {
          // Atualizar item existente
          const { error } = await supabase
            .from('itens_materiais')
            .update({
              grupo_id: itemAtual.grupo_id,
              classe_id: itemAtual.classe_id,
              codigo: itemAtual.codigo,
              nome: itemAtual.nome,
              marca_modelo_referencia: itemAtual.marca_modelo_referencia,
              descricao: itemAtual.descricao
            })
            .eq('id', itemAtual.id);
            
          if (error) throw error;
          alert('Item atualizado com sucesso!');
        } else {
          // Gerar código automaticamente se não fornecido
          let codigo = itemAtual.codigo;
          if (!codigo) {
            const { data: ultimoItem } = await supabase
              .from('itens_materiais')
              .select('codigo')
              .order('created_at', { ascending: false })
              .limit(1);
            
            const ultimoNumero = ultimoItem && ultimoItem[0] && ultimoItem[0].codigo 
              ? parseInt(ultimoItem[0].codigo.replace(/\D/g, '')) || 0 
              : 0;
            codigo = `ITM${String(ultimoNumero + 1).padStart(3, '0')}`;
          }
          
          // Criar novo item
          const { error } = await supabase
            .from('itens_materiais')
            .insert({
              grupo_id: itemAtual.grupo_id,
              classe_id: itemAtual.classe_id,
              codigo: codigo,
              nome: itemAtual.nome,
              marca_modelo_referencia: itemAtual.marca_modelo_referencia,
              descricao: itemAtual.descricao
            });
            
          if (error) throw error;
          alert('Item adicionado com sucesso!');
        }
        
        // Recarregar lista e fechar formulário
        await carregarItens();
        fecharFormulario();
      } catch (error) {
        console.error('Erro ao salvar item:', error);
        alert(`Erro ao ${modoEdicao.value ? 'atualizar' : 'adicionar'} item: ${error.message}`);
      } finally {
        salvando.value = false;
      }
    };

    const confirmarExclusao = (item) => {
      if (confirm(`Deseja realmente excluir o item "${item.nome}"?`)) {
        excluirItem(item.id);
      }
    };

    const excluirItem = async (id) => {
      try {
        loading.value = true;
        
        // Realizar a exclusão
        const { error } = await supabase
          .from('itens_materiais')
          .delete()
          .eq('id', id);
          
        if (error) throw error;
        
        alert('Item excluído com sucesso!');
        await carregarItens();
      } catch (error) {
        console.error('Erro ao excluir item:', error);
        alert(`Erro ao excluir item: ${error.message}`);
      } finally {
        loading.value = false;
      }
    };

    return {
      itens,
      grupos,
      classes,
      classesFiltradas,
      loading,
      salvando,
      mostrarFormulario,
      modoEdicao,
      itemAtual,
      carregarItens,
      carregarGrupos,
      carregarClasses,
      carregarClassesPorGrupo,
      getNomeGrupo,
      getNomeClasse,
      formatarData,
      editarItem,
      fecharFormulario,
      salvarItem,
      confirmarExclusao
    };
  }
};
</script>

<style scoped>
.itens-list {
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

.itens-table {
  width: 100%;
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  min-width: 1000px;
}

th, td {
  padding: 12px 8px;
  text-align: left;
  border-bottom: 1px solid #ddd;
  font-size: 14px;
}

th {
  background-color: #f2f2f2;
  font-weight: bold;
  position: sticky;
  top: 0;
}

.actions {
  display: flex;
  gap: 8px;
  min-width: 120px;
}

.btn-edit, .btn-delete {
  padding: 4px 8px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
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
  width: 600px;
  max-width: 95%;
  max-height: 90vh;
  overflow-y: auto;
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

.form-group small {
  display: block;
  margin-top: 4px;
  color: #666;
  font-size: 12px;
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