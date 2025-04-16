<template>
  <div class="cadastro-produto">
    <h2>Cadastro de Produto</h2>
    
    <form @submit.prevent="salvarProduto">
      <div class="form-row">
        <div class="form-group">
          <label for="nome">Nome do Produto*</label>
          <input 
            id="nome" 
            v-model="produto.nome" 
            type="text" 
            required
          >
        </div>
        
        <div class="form-group">
          <label for="grupo">Grupo*</label>
          <select 
            id="grupo" 
            v-model="produto.grupo_id" 
            required
            @change="onGrupoChange"
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
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="classe">Classe*</label>
          <select 
            id="classe" 
            v-model="produto.classe_id" 
            required
            :disabled="!produto.grupo_id || classes.length === 0"
          >
            <option value="">Selecione...</option>
            <option 
              v-for="classe in filteredClasses" 
              :key="classe.id" 
              :value="classe.id"
            >
              {{ classe.nome }}
            </option>
          </select>
          <div v-if="produto.grupo_id && filteredClasses.length === 0" class="info-text">
            Não há classes disponíveis para este grupo. Por favor, cadastre uma classe primeiro.
          </div>
        </div>
        
        <div class="form-group">
          <label for="marca">Marca*</label>
          <input 
            id="marca" 
            v-model="produto.marca" 
            type="text" 
            required
          >
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="modelo">Modelo*</label>
          <input 
            id="modelo" 
            v-model="produto.modelo" 
            type="text" 
            required
          >
        </div>
        
        <div class="form-group">
          <label for="fabricante">Fabricante*</label>
          <input 
            id="fabricante" 
            v-model="produto.fabricante" 
            type="text" 
            required
          >
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="cnpj">CNPJ*</label>
          <input 
            id="cnpj" 
            v-model="cnpjFormatado" 
            type="text" 
            required
            maxlength="18"
            @input="formatarCNPJ"
            placeholder="00.000.000/0000-00"
          >
          <small v-if="cnpjInvalido" class="error-text">CNPJ inválido. Formato: 00.000.000/0000-00</small>
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="origem">Origem</label>
          <input 
            id="origem" 
            v-model="produto.origem" 
            type="text" 
            placeholder="Nacional ou Importado"
          >
        </div>
        
        <div class="form-group">
          <label for="registro_anvisa">Registro na Anvisa/MS</label>
          <input 
            id="registro_anvisa" 
            v-model="produto.registro_anvisa" 
            type="text" 
            placeholder="Número do registro"
          >
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="cbpf">CBPF</label>
          <input 
            id="cbpf" 
            v-model="produto.cbpf" 
            type="text" 
            placeholder="Certificado de Boas Práticas de Fabricação"
          >
        </div>
        
        <div class="form-group">
          <label for="codigo_material">Código do Material</label>
          <input 
            id="codigo_material" 
            v-model="produto.codigo_material" 
            type="text" 
            placeholder="Código interno do material"
          >
        </div>
      </div>
      
      <div class="form-group">
        <label for="descricao">Descrição</label>
        <textarea 
          id="descricao" 
          v-model="produto.descricao" 
          rows="4"
        ></textarea>
      </div>
      
      <div class="form-group">
        <label>Documentos (apenas PDF)</label>
        <div class="file-upload">
          <input 
            type="file" 
            @change="onFileSelect" 
            multiple
            accept=".pdf"
          >
        </div>
        <small class="info-text">Apenas arquivos PDF são aceitos (máx. 10MB por arquivo)</small>
        <div class="selected-files" v-if="selectedFiles.length > 0">
          <p>Arquivos selecionados:</p>
          <ul>
            <li v-for="(file, index) in selectedFiles" :key="index" 
                :class="{ 'arquivo-invalido': !validarArquivoPDF(file) }">
              {{ file.name }} 
              <span v-if="!validarArquivoPDF(file)" class="error-text">(Formato inválido - apenas PDF permitido)</span>
            </li>
          </ul>
        </div>
        <div v-if="arquivosInvalidos.length > 0" class="error-text">
          <p>Os seguintes arquivos não serão enviados (apenas PDF permitido):</p>
          <ul>
            <li v-for="(arquivo, index) in arquivosInvalidos" :key="index">
              {{ arquivo.name }}
            </li>
          </ul>
        </div>
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
import { getTenantId } from '@/services/supabase'
import { ref, reactive, onMounted } from 'vue'
import { v4 as uuidv4 } from 'uuid'

export default {
  name: 'CadastroProduto',
  data() {
    return {
      produto: {
        nome: '',
        grupo_id: '',
        classe_id: '',
        marca: '',
        modelo: '',
        fabricante: '',
        cnpj: '',
        origem: '',
        registro_anvisa: '',
        cbpf: '',
        codigo_material: '',
        descricao: '',
        status: 'pendente'
      },
      cnpjFormatado: '',
      cnpjInvalido: false,
      grupos: [],
      classes: [],
      selectedFiles: [],
      arquivosInvalidos: [],
      loading: false,
      currentTenantId: null
    }
  },
  computed: {
    filteredClasses() {
      if (!this.produto.grupo_id) return [];
      return this.classes.filter(classe => classe.grupo_id === this.produto.grupo_id);
    }
  },
  async created() {
    this.carregarGrupos()
    await this.obterTenantId()
  },
  methods: {
    async obterTenantId() {
      try {
        // Tenta obter dados do usuário logado
        const { data: authData } = await supabase.auth.getSession()
        const user = authData?.session?.user
        
        if (!user) {
          throw new Error('Usuário não autenticado')
        }
        
        // Tenta obter tenant_id dos metadados primeiro
        if (user?.user_metadata?.tenant_id) {
          console.log('Obteve tenant_id dos metadados:', user.user_metadata.tenant_id)
          this.currentTenantId = user.user_metadata.tenant_id
          return
        }
        
        // Se não tiver nos metadados, busca na tabela 'usuarios'
        const { data: userData, error: userError } = await supabase
          .from('usuarios')
          .select('tenant_id')
          .eq('email', user.email)
          .single()
        
        console.log('Busca de tenant_id na tabela usuarios:', { userData, userError })
        
        if (userData && userData.tenant_id) {
          console.log('Obteve tenant_id da tabela usuarios:', userData.tenant_id)
          this.currentTenantId = userData.tenant_id
          
          // Atualiza também os metadados do usuário para futuras consultas
          const { error: updateError } = await supabase.auth.updateUser({
            data: { tenant_id: userData.tenant_id }
          })
          
          if (updateError) {
            console.error('Erro ao atualizar metadados do usuário:', updateError)
          } else {
            console.log('Metadados do usuário atualizados com sucesso')
          }
          
          return
        }
        
        // Se não encontrar em nenhum lugar, gera um UUID e salva nos metadados
        const newTenantId = uuidv4()
        console.log('Gerando novo tenant_id:', newTenantId)
        
        // Salva na tabela usuarios
        const { error: insertError } = await supabase
          .from('usuarios')
          .insert({
            id: uuidv4(),
            email: user.email,
            tenant_id: newTenantId,
            ativo: true
          })
        
        if (insertError) {
          console.error('Erro ao inserir novo tenant_id na tabela usuarios:', insertError)
        }
        
        // Atualiza metadados do usuário
        const { error: updateError } = await supabase.auth.updateUser({
          data: { tenant_id: newTenantId }
        })
        
        if (updateError) {
          console.error('Erro ao atualizar metadados do usuário:', updateError)
        } else {
          console.log('Metadados do usuário atualizados com novo tenant_id')
        }
        
        this.currentTenantId = newTenantId
      } catch (error) {
        console.error('Erro ao obter tenant_id:', error)
        alert('Erro ao obter identificação do tenant. Por favor, faça login novamente.')
        // Redireciona para login
        this.$router.push('/')
      }
    },
    async carregarGrupos() {
      try {
        // Tenta carregar do banco de dados primeiro
        const { data, error } = await supabase
          .from('grupos')
          .select('*')
          .order('nome')
        
        if (error) throw error
        
        // Se conseguir dados do banco, usa eles
        if (data && data.length > 0) {
          this.grupos = data
        } else {
          // Se não tiver dados ou der erro, usa grupos locais temporários
          this.grupos = [
            { id: 1, nome: 'Equipamentos Médicos' },
            { id: 2, nome: 'Equipamentos Odontológicos' },
            { id: 3, nome: 'Materiais Hospitalares' },
            { id: 4, nome: 'Materiais de Escritório' },
            { id: 5, nome: 'Equipamentos de Informática' },
            { id: 6, nome: 'Mobiliário' },
            { id: 7, nome: 'Medicamentos' },
            { id: 8, nome: 'Material de Laboratório' },
            { id: 9, nome: 'Equipamentos Administrativos' },
            { id: 10, nome: 'Outros' }
          ]
        }
      } catch (error) {
        console.error('Erro ao carregar grupos:', error)
        // Em caso de erro, usa grupos locais
        this.grupos = [
          { id: 1, nome: 'Equipamentos Médicos' },
          { id: 2, nome: 'Equipamentos Odontológicos' },
          { id: 3, nome: 'Materiais Hospitalares' },
          { id: 4, nome: 'Materiais de Escritório' },
          { id: 5, nome: 'Equipamentos de Informática' },
          { id: 6, nome: 'Mobiliário' },
          { id: 7, nome: 'Medicamentos' },
          { id: 8, nome: 'Material de Laboratório' },
          { id: 9, nome: 'Equipamentos Administrativos' },
          { id: 10, nome: 'Outros' }
        ]
      }
    },
    onGrupoChange() {
      this.carregarClasses()
    },
    async carregarClasses() {
      try {
        // Tenta carregar do banco de dados primeiro
        const { data, error } = await supabase
          .from('classes')
          .select('*')
          .eq('grupo_id', this.produto.grupo_id)
          .order('nome')
        
        if (error) throw error
        
        // Se conseguir dados do banco, usa eles
        if (data && data.length > 0) {
          this.classes = data
        } else {
          // Se não tiver dados ou der erro, usa classes locais temporárias
          this.classes = [
            { id: 1, nome: 'Equipamentos Médicos' },
            { id: 2, nome: 'Equipamentos Odontológicos' },
            { id: 3, nome: 'Materiais Hospitalares' },
            { id: 4, nome: 'Materiais de Escritório' },
            { id: 5, nome: 'Equipamentos de Informática' },
            { id: 6, nome: 'Mobiliário' },
            { id: 7, nome: 'Medicamentos' },
            { id: 8, nome: 'Material de Laboratório' },
            { id: 9, nome: 'Equipamentos Administrativos' },
            { id: 10, nome: 'Outros' }
          ]
        }
      } catch (error) {
        console.error('Erro ao carregar classes:', error)
        // Em caso de erro, usa classes locais
        this.classes = [
          { id: 1, nome: 'Equipamentos Médicos' },
          { id: 2, nome: 'Equipamentos Odontológicos' },
          { id: 3, nome: 'Materiais Hospitalares' },
          { id: 4, nome: 'Materiais de Escritório' },
          { id: 5, nome: 'Equipamentos de Informática' },
          { id: 6, nome: 'Mobiliário' },
          { id: 7, nome: 'Medicamentos' },
          { id: 8, nome: 'Material de Laboratório' },
          { id: 9, nome: 'Equipamentos Administrativos' },
          { id: 10, nome: 'Outros' }
        ]
      }
    },
    formatarCNPJ(event) {
      // Remover todos os caracteres que não são dígitos
      let valor = event.target.value.replace(/\D/g, '');
      
      // Limitar a 14 dígitos (CNPJ sem formatação)
      valor = valor.substring(0, 14);
      
      // Aplicar máscara no formato XX.XXX.XXX/XXXX-XX
      if (valor.length > 0) {
        valor = valor.replace(/^(\d{2})(\d)/, '$1.$2');
        valor = valor.replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3');
        valor = valor.replace(/\.(\d{3})(\d)/, '.$1/$2');
        valor = valor.replace(/(\d{4})(\d)/, '$1-$2');
      }
      
      this.cnpjFormatado = valor;
      
      // Atualizar o valor no objeto produto (apenas os dígitos)
      this.produto.cnpj = this.cnpjFormatado.replace(/\D/g, '');
      
      // Validar CNPJ
      this.validarCNPJ();
    },
    
    validarCNPJ() {
      const cnpj = this.produto.cnpj;
      
      // CNPJ precisa ter 14 dígitos
      if (cnpj.length !== 14) {
        this.cnpjInvalido = true;
        return false;
      }
      
      // Verificar se todos os dígitos são iguais (CNPJ inválido)
      if (/^(\d)\1+$/.test(cnpj)) {
        this.cnpjInvalido = true;
        return false;
      }
      
      // Para um MVP, consideramos válido se tiver 14 dígitos e não forem todos iguais
      // Em uma versão de produção, seria importante implementar o algoritmo completo de validação
      this.cnpjInvalido = false;
      return true;
    },
    
    onFileSelect(event) {
      const files = Array.from(event.target.files);
      this.arquivosInvalidos = [];
      
      // Filtrar apenas arquivos PDF válidos
      this.selectedFiles = files.filter(file => {
        const isPDF = this.validarArquivoPDF(file);
        if (!isPDF) {
          this.arquivosInvalidos.push(file);
        }
        return isPDF;
      });
    },
    
    validarArquivoPDF(file) {
      // Verificar extensão
      const extensao = file.name.split('.').pop().toLowerCase();
      const tipoMIME = file.type.toLowerCase();
      
      // Verificar se é PDF por extensão e tipo MIME
      return extensao === 'pdf' && tipoMIME === 'application/pdf';
    },
    
    // Função para sanitizar nomes de arquivos
    sanitizarNomeArquivo(nome) {
      // Remover acentos e caracteres especiais
      let nomeSeguro = nome.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
      
      // Substituir espaços e outros caracteres problemáticos por underscore
      nomeSeguro = nomeSeguro.replace(/[^a-zA-Z0-9_.]/g, '_');
      
      // Garantir que o nome não fique muito longo
      if (nomeSeguro.length > 100) {
        const extensao = nomeSeguro.split('.').pop();
        nomeSeguro = nomeSeguro.substring(0, 90) + '.' + extensao;
      }
      
      return nomeSeguro;
    },
    
    async salvarProduto() {
      if (!this.validarFormulario()) {
        return;
      }
      
      try {
        this.loading = true;
        
        // Verificar se temos um tenant_id
        if (!this.currentTenantId) {
          await this.obterTenantId();
        }
        
        console.log('Salvando produto com tenant_id:', this.currentTenantId);
        
        // Verificar novamente a validação do CNPJ
        if (!this.validarCNPJ()) {
          this.$swal({
            icon: 'error',
            title: 'CNPJ Inválido',
            text: 'Por favor, informe um CNPJ válido no formato 00.000.000/0000-00'
          });
          this.loading = false;
          return;
        }
        
        // Criar o objeto produto
        const produtoObjeto = {
          nome: this.produto.nome,
          descricao: this.produto.descricao,
          grupo_id: this.produto.grupo_id,
          classe_id: this.produto.classe_id,
          marca: this.produto.marca,
          modelo: this.produto.modelo,
          fabricante: this.produto.fabricante,
          cnpj: this.produto.cnpj, // CNPJ já tratado sem formatação
          origem: this.produto.origem,
          registro_anvisa: this.produto.registro_anvisa,
          cbpf: this.produto.cbpf,
          codigo_material: this.produto.codigo_material,
          status: 'pendente',
          tenant_id: this.currentTenantId
        };
        
        console.log('Objeto produto a ser inserido:', produtoObjeto);
        
        // Inserir produto no banco de dados
        const { data: produtoInserido, error: produtoError } = await supabase
          .from('produtos')
          .insert(produtoObjeto)
          .select()
          .single();
        
        if (produtoError) {
          console.error('Erro detalhado ao salvar produto:', produtoError);
          throw new Error(`Erro ao salvar produto: ${produtoError.message}`);
        }
        
        console.log('Produto inserido com sucesso:', produtoInserido);
        
        // Filtrar para garantir que apenas PDFs válidos sejam enviados
        const arquivosValidos = this.selectedFiles.filter(file => this.validarArquivoPDF(file));
        
        // Se houver arquivos válidos, fazer upload
        if (arquivosValidos.length > 0) {
          const produtoId = produtoInserido.id;
          
          for (const file of arquivosValidos) {
            const nomeOriginal = file.name;
            const nomeSanitizado = this.sanitizarNomeArquivo(file.name);
            const fileName = `${Date.now()}-${nomeSanitizado}`;
            
            console.log(`Upload de arquivo: Original "${nomeOriginal}" -> Sanitizado "${nomeSanitizado}"`);
            
            // Upload do arquivo
            const { data: storageData, error: storageError } = await supabase.storage
              .from('documentos')
              .upload(fileName, file);
            
            if (storageError) {
              console.error('Erro ao fazer upload do arquivo:', storageError);
              continue;
            }
            
            // Obter URL do arquivo
            const { data: publicURLData } = supabase.storage
              .from('documentos')
              .getPublicUrl(fileName);
            
            const arquivo_url = publicURLData?.publicUrl || '';
            
            // Registrar documento com o nome original para exibição
            const documentoObjeto = {
              tenant_id: this.currentTenantId,
              produto_id: produtoId,
              nome: nomeOriginal, // Manter o nome original para exibição
              tipo: file.type,
              arquivo_url: arquivo_url
            };
            
            const { error: documentoError } = await supabase
              .from('documentos')
              .insert(documentoObjeto);
            
            if (documentoError) {
              console.error('Erro ao registrar documento:', documentoError);
            }
          }
        }
        
        // Verificar se havia arquivos inválidos não enviados
        if (this.arquivosInvalidos.length > 0) {
          this.$swal({
            icon: 'warning',
            title: 'Produto salvo com ressalvas',
            text: `O produto foi salvo, mas ${this.arquivosInvalidos.length} arquivo(s) não foi(ram) enviado(s) por não serem PDFs válidos.`
          });
        } else {
          // Exibir mensagem de sucesso
          this.$swal({
            icon: 'success',
            title: 'Produto salvo com sucesso!',
            text: 'O produto foi cadastrado e está aguardando aprovação.'
          });
        }
        
        // Limpar formulário
        this.limparFormulario();
        
      } catch (error) {
        console.error('Erro no processo de salvamento:', error);
        this.$swal({
          icon: 'error',
          title: 'Erro ao salvar produto',
          text: error.message || 'Ocorreu um erro ao tentar salvar o produto.'
        });
      } finally {
        this.loading = false;
      }
    },
    limparFormulario() {
      this.produto = {
        nome: '',
        grupo_id: '',
        classe_id: '',
        marca: '',
        modelo: '',
        fabricante: '',
        cnpj: '',
        origem: '',
        registro_anvisa: '',
        cbpf: '',
        codigo_material: '',
        descricao: '',
        status: 'pendente'
      };
      this.cnpjFormatado = '';
      this.cnpjInvalido = false;
      this.selectedFiles = [];
      this.arquivosInvalidos = [];
    },
    validarFormulario() {
      // Validação básica do formulário
      if (!this.produto.nome || this.produto.nome.trim() === '') {
        this.$swal({
          icon: 'error',
          title: 'Erro de validação',
          text: 'O nome do produto é obrigatório'
        });
        return false;
      }
      
      if (!this.produto.grupo_id) {
        this.$swal({
          icon: 'error',
          title: 'Erro de validação',
          text: 'Selecione um grupo para o produto'
        });
        return false;
      }
      
      if (!this.produto.classe_id) {
        this.$swal({
          icon: 'error',
          title: 'Erro de validação',
          text: 'Selecione uma classe para o produto'
        });
        return false;
      }
      
      if (!this.produto.descricao || this.produto.descricao.trim() === '') {
        this.$swal({
          icon: 'error',
          title: 'Erro de validação',
          text: 'A descrição do produto é obrigatória'
        });
        return false;
      }
      
      // Validar CNPJ
      if (!this.validarCNPJ()) {
        this.$swal({
          icon: 'error',
          title: 'Erro de validação',
          text: 'O CNPJ informado é inválido'
        });
        return false;
      }
      
      // Verificar se há arquivos inválidos selecionados
      if (this.arquivosInvalidos.length > 0) {
        this.$swal({
          icon: 'error',
          title: 'Arquivos inválidos',
          text: 'Alguns arquivos selecionados não são PDFs válidos e não serão enviados.'
        });
      }
      
      return true;
    },
    convertToUUID(categoriaId) {
      // Converte um ID numérico para um formato UUID compatível com Supabase
      // Formato: 00000000-0000-0000-0000-xxxxxxxxxxxx onde x é o ID da categoria com padding
      if (!categoriaId) return null;
      
      // Se já for um UUID válido, retornar como está
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (uuidRegex.test(categoriaId)) {
        console.log('categoria_id já é um UUID válido:', categoriaId);
        return categoriaId;
      }
      
      // Tenta converter para número
      const categoryNumber = parseInt(categoriaId, 10);
      if (isNaN(categoryNumber)) {
        console.warn('categoria_id não é um número nem UUID válido:', categoriaId);
        // Em caso de falha, gera um novo UUID
        return uuidv4();
      }
      
      // Cria um UUID determinístico baseado no número da categoria
      const uuidFormatted = `00000000-0000-0000-0000-${categoryNumber.toString().padStart(12, '0')}`;
      console.log(`Converteu categoria_id ${categoriaId} para UUID: ${uuidFormatted}`);
      return uuidFormatted;
    }
  }
}
</script>

<style scoped>
.cadastro-produto {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
}

.form-row {
  display: flex;
  gap: 20px;
  margin-bottom: 15px;
}

.form-group {
  margin-bottom: 15px;
  flex: 1;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

input, select, textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

textarea {
  resize: vertical;
}

.file-upload {
  margin-bottom: 10px;
}

.selected-files {
  background-color: #f9f9f9;
  padding: 10px;
  border-radius: 4px;
  margin-bottom: 15px;
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

.error-text {
  color: #e74c3c;
  font-size: 12px;
  margin-top: 4px;
}

.info-text {
  color: #7f8c8d;
  font-size: 12px;
  margin-top: 4px;
}

.arquivo-invalido {
  color: #e74c3c;
}
</style> 