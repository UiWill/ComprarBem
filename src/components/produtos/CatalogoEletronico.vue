<template>
  <div class="produtos-container">
    <div class="produtos-header">
      <h1>Catálogo Eletrônico</h1>
      <div class="filtros">
        <input type="text" v-model="filtroBusca" placeholder="Buscar produto">
        <select v-model="filtroGrupo" @change="onGrupoChange">
          <option value="">Todos grupos</option>
          <option v-for="grupo in grupos" :key="grupo.id" :value="grupo.id">{{ grupo.nome }}</option>
        </select>
        <select v-model="filtroClasse" :disabled="!filtroGrupo">
          <option value="">Todas classes</option>
          <option v-for="classe in classesFiltradas" :key="classe.id" :value="classe.id">{{ classe.nome }}</option>
        </select>
        <select v-model="filtroStatus">
          <option value="">Todos status</option>
          <option v-for="status in statuses" :key="status.id" :value="status.id">{{ status.nome }}</option>
        </select>
        <button @click="carregarProdutos">Buscar</button>
      </div>
    </div>
    <div class="produtos-content">
      <div class="produtos-list">
        <div class="produto-item" v-for="produto in produtos" :key="produto.id">
          <div class="produto-header">
            <h2>{{ produto.nome }}</h2>
          </div>
          <div class="produto-body">
            <div class="produto-info">
              <p><strong>Grupo:</strong> {{ produto.grupo?.nome || 'Não especificado' }}</p>
              <p><strong>Classe:</strong> {{ produto.classe?.nome || 'Não especificada' }}</p>
              <p><strong>Status:</strong> {{ getStatusText(produto.status) }}</p>
            </div>
            <div class="produto-footer">
              <div class="produto-status" :class="'status-' + produto.status">
                {{ getStatusText(produto.status) }}
              </div>
              <button class="btn-detalhes" @click="verDetalhes(produto.id)">
                Ver Detalhes
              </button>
              <button class="btn-documentos" @click="verDocumentos(produto.id)" v-if="produto.tem_documentos">
                <i class="icon-document"></i> Ver Documentos
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../../services/supabase';

export default {
  data() {
    return {
      produtos: [],
      grupos: [],
      classes: [],
      statuses: [
        { id: 'pendente', nome: 'Pendente' },
        { id: 'aprovado', nome: 'Aprovado' },
        { id: 'reprovado', nome: 'Reprovado' }
      ],
      filtroBusca: '',
      filtroGrupo: '',
      filtroClasse: '',
      filtroStatus: '',
      isLoading: false
    };
  },
  computed: {
    classesFiltradas() {
      if (!this.filtroGrupo) return [];
      return this.classes.filter(classe => classe.grupo_id === this.filtroGrupo);
    }
  },
  created() {
    this.carregarGrupos();
    this.carregarProdutos();
  },
  methods: {
    async carregarGrupos() {
      try {
        const { data: grupos, error } = await supabase
          .from('grupos')
          .select('*')
          .order('nome');
          
        if (error) throw error;
        this.grupos = grupos || [];
      } catch (error) {
        console.error('Erro ao carregar grupos:', error);
      }
    },
    async carregarClasses() {
      try {
        let query = supabase.from('classes').select('*');
        
        if (this.filtroGrupo) {
          query = query.eq('grupo_id', this.filtroGrupo);
        }
        
        const { data: classes, error } = await query.order('nome');
        
        if (error) throw error;
        this.classes = classes || [];
      } catch (error) {
        console.error('Erro ao carregar classes:', error);
      }
    },
    onGrupoChange() {
      this.filtroClasse = '';
      this.carregarClasses();
    },
    getStatusText(status) {
      const statusMap = {
        pendente: 'Pendente',
        aprovado: 'Aprovado',
        reprovado: 'Reprovado'
      };
      return statusMap[status] || status;
    },
    async carregarProdutos() {
      try {
        this.isLoading = true;
        
        // Obter o tenant_id do usuário logado
        const { data: authData } = await supabase.auth.getSession();
        const user = authData?.session?.user;
        let tenantId = user?.user_metadata?.tenant_id;
        
        // Se não tiver nos metadados, buscar na tabela usuarios
        if (!tenantId && user) {
          const { data: userData } = await supabase
            .from('usuarios')
            .select('tenant_id')
            .eq('email', user.email)
            .single();
            
          tenantId = userData?.tenant_id;
        }
        
        // Buscar produtos com filtragem
        let query = supabase.from('produtos').select('*');
        
        // Filtrar por tenant_id se disponível
        if (tenantId) {
          query = query.eq('tenant_id', tenantId);
        }
        
        if (this.filtroGrupo) {
          query = query.eq('grupo_id', this.filtroGrupo);
        }
        
        if (this.filtroClasse) {
          query = query.eq('classe_id', this.filtroClasse);
        }
        
        if (this.filtroStatus) {
          query = query.eq('status', this.filtroStatus);
        }
        
        if (this.filtroBusca) {
          query = query.ilike('nome', `%${this.filtroBusca}%`);
        }
        
        const { data: produtos, error } = await query;
        
        if (error) throw error;
        
        // Carregar informações adicionais
        if (produtos && produtos.length > 0) {
          // Buscar grupos e classes para cada produto
          const grupoIds = [...new Set(produtos.map(p => p.grupo_id).filter(Boolean))];
          const classeIds = [...new Set(produtos.map(p => p.classe_id).filter(Boolean))];
          
          // Carregar grupos
          const { data: grupos } = await supabase
            .from('grupos')
            .select('*')
            .in('id', grupoIds);
            
          const gruposMap = {};
          if (grupos) {
            grupos.forEach(grupo => {
              gruposMap[grupo.id] = grupo;
            });
          }
          
          // Carregar classes
          const { data: classes } = await supabase
            .from('classes')
            .select('*')
            .in('id', classeIds);
            
          const classesMap = {};
          if (classes) {
            classes.forEach(classe => {
              classesMap[classe.id] = classe;
            });
          }
          
          // Associar grupo e classe a cada produto
          produtos.forEach(produto => {
            produto.grupo = gruposMap[produto.grupo_id] || null;
            produto.classe = classesMap[produto.classe_id] || null;
          });
          
          // Contar documentos por produto
          const produtosIds = produtos.map(p => p.id);
          const { data: documentos } = await supabase
            .from('documentos')
            .select('produto_id')
            .in('produto_id', produtosIds);
            
          // Contar documentos por produto
          const docsCount = {};
          if (documentos) {
            documentos.forEach(doc => {
              docsCount[doc.produto_id] = (docsCount[doc.produto_id] || 0) + 1;
            });
          }
          
          // Adicionar flag tem_documentos
          produtos.forEach(produto => {
            produto.tem_documentos = (docsCount[produto.id] || 0) > 0;
          });
        }
        
        this.produtos = produtos || [];
      } catch (error) {
        console.error('Erro ao carregar produtos:', error);
        this.$swal({
          icon: 'error',
          title: 'Erro',
          text: 'Não foi possível carregar os produtos.'
        });
      } finally {
        this.isLoading = false;
      }
    },
    verDetalhes(produtoId) {
      this.$router.push(`/produtos/${produtoId}`);
    },
    verDocumentos(produtoId) {
      this.$router.push(`/produtos/${produtoId}?tab=documentos`);
    }
  }
};
</script>

<style scoped>
.produtos-container {
  padding: 20px;
}

.produtos-header {
  margin-bottom: 20px;
}

.produtos-header h1 {
  margin-bottom: 15px;
}

.filtros {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filtros input,
.filtros select {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.filtros button {
  padding: 8px 15px;
  background-color: #2c3e50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.produtos-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.produto-item {
  border: 1px solid #ddd;
  border-radius: 4px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  background-color: white;
}

.produto-header {
  padding: 15px;
  background-color: #f8f9fa;
  border-bottom: 1px solid #ddd;
}

.produto-header h2 {
  margin: 0;
  font-size: 1.2rem;
}

.produto-body {
  padding: 15px;
}

.produto-info {
  margin-bottom: 15px;
}

.produto-info p {
  margin: 5px 0;
}

.produto-footer {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
  margin-top: 15px;
}

.produto-status {
  font-size: 0.8rem;
  padding: 4px 8px;
  border-radius: 4px;
  font-weight: bold;
}

.status-pendente {
  background-color: #f8d7da;
  color: #721c24;
}

.status-aprovado {
  background-color: #d4edda;
  color: #155724;
}

.status-reprovado {
  background-color: #f8d7da;
  color: #721c24;
}

.btn-detalhes,
.btn-documentos {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-detalhes {
  background-color: #2c3e50;
  color: white;
}

.btn-documentos {
  background-color: #3498db;
  color: white;
}
</style> 