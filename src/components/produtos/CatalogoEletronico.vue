<template>
  <div class="produtos-container">
    <div class="produtos-header">
      <h1>Catálogo Eletrônico</h1>
      <div class="filtros">
        <input type="text" v-model="filtroBusca" placeholder="Buscar produto">
        <select v-model="filtroCategoria">
          <option value="">Todas categorias</option>
          <option v-for="categoria in categorias" :key="categoria.id" :value="categoria.id">{{ categoria.nome }}</option>
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
              <p><strong>Categoria:</strong> {{ produto.categoria.nome }}</p>
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
import { supabase } from '../../lib/supabase';

export default {
  data() {
    return {
      produtos: [],
      categorias: [],
      statuses: [],
      filtroBusca: '',
      filtroCategoria: '',
      filtroStatus: '',
      isLoading: false
    };
  },
  methods: {
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
        
        console.log('Filtrando produtos por tenant_id:', tenantId);
        
        // Buscar produtos com filtragem
        let query = supabase.from('produtos').select('*');
        
        // Filtrar por tenant_id se disponível
        if (tenantId) {
          query = query.eq('tenant_id', tenantId);
        }
        
        if (this.filtroCategoria) {
          // Converter o ID da categoria para UUID se necessário
          const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
          let categoriaId = this.filtroCategoria;
          
          // Se não for um UUID e for um número, converter para UUID
          if (!uuidRegex.test(categoriaId) && !isNaN(parseInt(categoriaId))) {
            const categoryNumber = parseInt(categoriaId, 10);
            categoriaId = `00000000-0000-0000-0000-${categoryNumber.toString().padStart(12, '0')}`;
          }
          
          query = query.eq('categoria_id', categoriaId);
        }
        
        if (this.filtroStatus) {
          query = query.eq('status', this.filtroStatus);
        }
        
        if (this.filtroBusca) {
          query = query.ilike('nome', `%${this.filtroBusca}%`);
        }
        
        const { data: produtos, error } = await query;
        
        if (error) throw error;
        
        // Carregar informações de documentos
        if (produtos && produtos.length > 0) {
          // Buscar categorias para cada produto
          const categoriaIds = [...new Set(produtos.map(p => p.categoria_id))];
          
          const { data: categorias } = await supabase
            .from('categorias')
            .select('*')
            .in('id', categoriaIds);
            
          const categoriasMap = {};
          if (categorias) {
            categorias.forEach(cat => {
              categoriasMap[cat.id] = cat;
            });
          }
          
          // Associar categoria a cada produto
          produtos.forEach(produto => {
            produto.categoria = categoriasMap[produto.categoria_id] || { nome: 'Categoria Desconhecida' };
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

<style>
  /* Adicione estilos CSS aqui */
</style> 