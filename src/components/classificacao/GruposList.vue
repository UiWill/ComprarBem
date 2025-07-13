<template>
  <div class="grupos-list">
    <div class="header">
      <h3>Gerenciamento de Grupos</h3>
      <button @click="mostrarFormulario = true" class="btn-add">
        Adicionar Grupo
      </button>
    </div>

    <div v-if="loading" class="loading">
      <p>Carregando grupos...</p>
    </div>

    <div v-else-if="grupos.length === 0" class="empty-state">
      <p>Nenhum grupo cadastrado.</p>
    </div>

    <div v-else class="grupos-table">
      <table>
        <thead>
          <tr>
            <th>Código do Grupo</th>
            <th>Nome</th>
            <th>Descrição</th>
            <th>Data de Criação</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="grupo in grupos" :key="grupo.id">
            <td>{{ grupo.codigo || grupo.id.slice(0, 8) }}</td>
            <td>{{ grupo.nome }}</td>
            <td>{{ grupo.descricao || '-' }}</td>
            <td>{{ formatarData(grupo.created_at) }}</td>
            <td class="actions">
              <button @click="editarGrupo(grupo)" class="btn-edit">Editar</button>
              <button @click="confirmarExclusao(grupo)" class="btn-delete">Excluir</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal de formulário -->
    <div v-if="mostrarFormulario" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ modoEdicao ? 'Editar' : 'Adicionar' }} Grupo</h3>
          <button @click="fecharFormulario" class="btn-close">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="salvarGrupo">
            <div class="form-group">
              <label for="codigo">Código do Grupo</label>
              <input 
                id="codigo" 
                v-model="grupoAtual.codigo" 
                type="text" 
                placeholder="Ex: GRP001"
              >
              <small>Se não informado, será gerado automaticamente</small>
            </div>
            <div class="form-group">
              <label for="nome">Nome do Grupo*</label>
              <input 
                id="nome" 
                v-model="grupoAtual.nome" 
                type="text" 
                required
              >
            </div>
            <div class="form-group">
              <label for="descricao">Descrição</label>
              <textarea 
                id="descricao" 
                v-model="grupoAtual.descricao" 
                rows="3"
              ></textarea>
            </div>
            <div class="form-actions">
              <button type="button" @click="fecharFormulario" class="btn-secondary">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="salvando">
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
  name: 'GruposList',
  setup() {
    const grupos = ref([]);
    const loading = ref(true);
    const salvando = ref(false);
    const mostrarFormulario = ref(false);
    const modoEdicao = ref(false);
    const grupoAtual = reactive({
      id: null,
      codigo: '',
      nome: '',
      descricao: ''
    });

    // Carregar grupos ao iniciar o componente
    onMounted(async () => {
      await carregarGrupos();
    });

    const carregarGrupos = async () => {
      try {
        loading.value = true;
        const { data, error } = await supabase
          .from('grupos')
          .select('*')
          .order('nome');

        if (error) throw error;
        grupos.value = data || [];
      } catch (error) {
        console.error('Erro ao carregar grupos:', error);
        alert('Erro ao carregar grupos. Por favor, tente novamente.');
      } finally {
        loading.value = false;
      }
    };

    const formatarData = (dataString) => {
      if (!dataString) return '-';
      const data = new Date(dataString);
      return data.toLocaleDateString('pt-BR');
    };

    const editarGrupo = (grupo) => {
      modoEdicao.value = true;
      grupoAtual.id = grupo.id;
      grupoAtual.codigo = grupo.codigo || '';
      grupoAtual.nome = grupo.nome;
      grupoAtual.descricao = grupo.descricao || '';
      mostrarFormulario.value = true;
    };

    const fecharFormulario = () => {
      mostrarFormulario.value = false;
      modoEdicao.value = false;
      // Limpar formulário
      grupoAtual.id = null;
      grupoAtual.codigo = '';
      grupoAtual.nome = '';
      grupoAtual.descricao = '';
    };

    const salvarGrupo = async () => {
      try {
        salvando.value = true;
        
        if (modoEdicao.value) {
          console.log('Atualizando grupo:', {
            id: grupoAtual.id,
            codigo: grupoAtual.codigo,
            nome: grupoAtual.nome,
            descricao: grupoAtual.descricao
          });
          
          // Primeiro, verificar se o grupo existe
          const { data: grupoExistente, error: errorBusca } = await supabase
            .from('grupos')
            .select('*')
            .eq('id', grupoAtual.id)
            .single();
            
          if (errorBusca) {
            console.error('Erro ao buscar grupo:', errorBusca);
            throw new Error(`Grupo não encontrado: ${errorBusca.message}`);
          }
          
          console.log('Grupo encontrado:', grupoExistente);
          
          // Atualizar grupo existente
          const updateData = {
            nome: grupoAtual.nome.trim()
          };
          
          if (grupoAtual.codigo && grupoAtual.codigo.trim()) {
            updateData.codigo = grupoAtual.codigo.trim();
          }
          
          if (grupoAtual.descricao && grupoAtual.descricao.trim()) {
            updateData.descricao = grupoAtual.descricao.trim();
          }
          
          console.log('Dados para atualização:', updateData);
          
          const { data, error } = await supabase
            .from('grupos')
            .update(updateData)
            .eq('id', grupoAtual.id)
            .select();
            
          if (error) {
            console.error('Erro na atualização:', error);
            throw new Error(`Erro ao atualizar: ${error.message}`);
          }
          
          console.log('Grupo atualizado com sucesso:', data);
          alert('Grupo atualizado com sucesso!');
        } else {
          // Gerar código automaticamente se não fornecido
          let codigo = grupoAtual.codigo;
          if (!codigo) {
            const { data: ultimoGrupo } = await supabase
              .from('grupos')
              .select('codigo')
              .order('created_at', { ascending: false })
              .limit(1);
            
            const ultimoNumero = ultimoGrupo && ultimoGrupo[0] && ultimoGrupo[0].codigo 
              ? parseInt(ultimoGrupo[0].codigo.replace(/\D/g, '')) || 0 
              : 0;
            codigo = `GRP${String(ultimoNumero + 1).padStart(3, '0')}`;
          }
          
          // Criar novo grupo
          const { error } = await supabase
            .from('grupos')
            .insert({
              codigo: codigo,
              nome: grupoAtual.nome,
              descricao: grupoAtual.descricao
            });
            
          if (error) throw error;
          alert('Grupo adicionado com sucesso!');
        }
        
        // Recarregar lista e fechar formulário
        await carregarGrupos();
        fecharFormulario();
      } catch (error) {
        console.error('Erro ao salvar grupo:', error);
        alert(`Erro ao ${modoEdicao.value ? 'atualizar' : 'adicionar'} grupo: ${error.message}`);
      } finally {
        salvando.value = false;
      }
    };

    const confirmarExclusao = (grupo) => {
      if (confirm(`Deseja realmente excluir o grupo "${grupo.nome}"?`)) {
        excluirGrupo(grupo.id);
      }
    };

    const excluirGrupo = async (id) => {
      try {
        loading.value = true;
        
        // Verificar se existem classes associadas a este grupo
        const { data: classes, error: classesError } = await supabase
          .from('classes')
          .select('id')
          .eq('grupo_id', id);
          
        if (classesError) throw classesError;
        
        // Se houver classes, não permitir a exclusão
        if (classes && classes.length > 0) {
          alert(`Não é possível excluir este grupo porque existem ${classes.length} classes associadas a ele.`);
          return;
        }
        
        // Verificar se existem produtos associados a este grupo
        const { data: produtos, error: produtosError } = await supabase
          .from('produtos')
          .select('id')
          .eq('grupo_id', id);
          
        if (produtosError) throw produtosError;
        
        // Se houver produtos, não permitir a exclusão
        if (produtos && produtos.length > 0) {
          alert(`Não é possível excluir este grupo porque existem ${produtos.length} produtos associados a ele.`);
          return;
        }
        
        // Realizar a exclusão
        const { error } = await supabase
          .from('grupos')
          .delete()
          .eq('id', id);
          
        if (error) throw error;
        
        alert('Grupo excluído com sucesso!');
        await carregarGrupos();
      } catch (error) {
        console.error('Erro ao excluir grupo:', error);
        alert(`Erro ao excluir grupo: ${error.message}`);
      } finally {
        loading.value = false;
      }
    };

    return {
      grupos,
      loading,
      salvando,
      mostrarFormulario,
      modoEdicao,
      grupoAtual,
      carregarGrupos,
      formatarData,
      editarGrupo,
      fecharFormulario,
      salvarGrupo,
      confirmarExclusao
    };
  }
};
</script>

<style scoped>
.grupos-list {
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

.grupos-table {
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
.form-group textarea {
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