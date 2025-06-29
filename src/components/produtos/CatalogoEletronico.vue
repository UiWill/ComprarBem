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
              <p><strong>Marca:</strong> {{ produto.marca || 'Não especificada' }}</p>
              <p><strong>Modelo:</strong> {{ produto.modelo || 'Não especificado' }}</p>
            </div>
            <div class="produto-footer">
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
      filtroBusca: '',
      filtroGrupo: '',
      filtroClasse: '',
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
        
        // Buscar apenas produtos aprovados (pré-qualificados e padronizados)
        let query = supabase
          .from('produtos')
          .select('*')
          .eq('status', 'aprovado'); // Apenas produtos aprovados
        
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
          
          // Adicionar informações de grupo e classe aos produtos
          this.produtos = produtos.map(produto => ({
            ...produto,
            grupo: gruposMap[produto.grupo_id] || null,
            classe: classesMap[produto.classe_id] || null,
            tem_documentos: produto.documentos_count > 0
          }));
        } else {
          this.produtos = [];
        }
        
      } catch (error) {
        console.error('Erro ao carregar produtos:', error);
        this.produtos = [];
      } finally {
        this.isLoading = false;
      }
    },
    verDetalhes(id) {
      this.$router.push(`/produto/${id}`);
    },
    verDocumentos(id) {
      // Implementar visualização de documentos se necessário
      console.log('Ver documentos do produto:', id);
    }
  }
}
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
  color: #2c3e50;
}

.filtros {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
  align-items: center;
}

.filtros input,
.filtros select {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.filtros input {
  flex: 1;
  min-width: 200px;
}

.filtros select {
  min-width: 150px;
}

.filtros button {
  padding: 10px 20px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  transition: background-color 0.3s;
}

.filtros button:hover {
  background-color: #2980b9;
}

.produtos-content {
  margin-top: 20px;
}

.produtos-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
}

.produto-item {
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.produto-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  border-color: #2c3e50;
}

.produto-header {
  padding: 20px;
  background: linear-gradient(135deg, #f8f9fa, #e9ecef);
  border-bottom: 1px solid #e0e0e0;
}

.produto-header h2 {
  margin: 0;
  font-size: 18px;
  color: #2c3e50;
  font-weight: 600;
}

.produto-body {
  padding: 20px;
}

.produto-info {
  margin-bottom: 20px;
}

.produto-info p {
  margin: 8px 0;
  color: #666;
  font-size: 14px;
}

.produto-footer {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.btn-detalhes,
.btn-documentos {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  transition: all 0.3s ease;
}

.btn-detalhes {
  background-color: #2c3e50;
  color: white;
}

.btn-detalhes:hover {
  background-color: #34495e;
}

.btn-documentos {
  background-color: #3498db;
  color: white;
}

.btn-documentos:hover {
  background-color: #2980b9;
}

.icon-document {
  margin-right: 5px;
}

@media (max-width: 768px) {
  .filtros {
    flex-direction: column;
    align-items: stretch;
  }
  
  .filtros input,
  .filtros select,
  .filtros button {
    width: 100%;
  }
  
  .produtos-list {
    grid-template-columns: 1fr;
  }
  
  .produto-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
  
  .produto-footer {
    justify-content: flex-start;
  }
}
</style> 