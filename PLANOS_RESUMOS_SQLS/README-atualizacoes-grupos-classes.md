# Atualização do Sistema de Classificação de Produtos

Este documento detalha a implementação do novo sistema de classificação de produtos usando Grupos e Classes em substituição ao sistema anterior de Categorias.

## Visão Geral das Mudanças

1. **Estrutura do Banco de Dados:**
   - Novas tabelas `grupos` e `classes`, onde cada classe pertence a um grupo
   - Campos `grupo_id` e `classe_id` adicionados à tabela `produtos`
   - Mantido temporariamente o campo `categoria_id` para compatibilidade durante a migração

2. **Interface de Gerenciamento:**
   - Novos componentes para gerenciar grupos e classes
   - Interface com abas para alternar entre gerenciamento de grupos e classes
   - Nova view "Classificação" acessível pelo menu principal

3. **Formulário de Cadastro de Produtos:**
   - Seleção hierárquica: primeiro escolhe-se o grupo, depois as classes disponíveis para o grupo selecionado
   - Validação para garantir que ambos grupo e classe sejam selecionados

4. **Catálogo Eletrônico:**
   - Filtros atualizados para permitir busca por grupo e classe
   - Exibição de informações de grupo e classe nos cards de produtos

## Scripts de Migração

1. **01_criar_tabela_grupos_classes.js**
   - Cria as novas tabelas `grupos` e `classes`
   - Adiciona os campos `grupo_id` e `classe_id` à tabela `produtos`
   - Configura os triggers para atualizar automaticamente os timestamps

2. **02_migrar_dados.js**
   - Migra as categorias existentes para o novo sistema de grupos
   - Cria uma classe padrão para cada grupo
   - Atualiza os produtos existentes para usar os novos relacionamentos

3. **03_migrar_categorias_para_grupos.js**
   - Script opcional que popula o sistema com grupos e classes predefinidos
   - Cria uma estrutura hierárquica de classificação para diferentes tipos de produtos

## Passos para Implementação

1. **Preparação do Banco de Dados:**
   ```bash
   # Executar no Supabase SQL Editor:
   # Conteúdo do script 01_criar_tabela_grupos_classes.js
   ```

2. **Migração de Dados:**
   ```bash
   # Executar no Supabase SQL Editor:
   # Conteúdo do script 02_migrar_dados.js
   ```

3. **Deployment das Atualizações do Frontend:**
   ```bash
   # Atualizar o código-fonte com os novos componentes
   npm run build
   # Fazer o deploy dos arquivos gerados
   ```

4. **Opcional: Preenchimento com Dados Predefinidos:**
   ```bash
   # Configurar as variáveis de ambiente:
   export SUPABASE_URL=https://ruagsbbczuwgfflgcaol.supabase.co
   export SUPABASE_KEY=sua_chave_aqui
   
   # Executar o script:
   node scripts/migrate/03_migrar_categorias_para_grupos.js
   ```

## Principais Arquivos Atualizados/Criados

- `src/components/classificacao/Classificacao.vue` - Componente principal de classificação
- `src/components/classificacao/GruposList.vue` - Gerenciamento de grupos
- `src/components/classificacao/ClassesList.vue` - Gerenciamento de classes
- `src/views/Classificacao.vue` - Nova view para acessar o gerenciamento de classificação
- `src/components/produtos/CadastroProduto.vue` - Formulário atualizado para usar grupos e classes
- `src/components/produtos/CatalogoEletronico.vue` - Catálogo atualizado para exibir e filtrar por grupos e classes
- `src/router/index.js` - Adicionada nova rota para a view de classificação

## Próximos Passos

1. **Validação e Testes:**
   - Testar o cadastro de novos produtos com o sistema de grupos e classes
   - Verificar se os produtos existentes mantêm seus dados após a migração
   - Validar os filtros no catálogo eletrônico

2. **Ajustes Finais:**
   - Atualizar outros componentes que possam fazer referência a categorias
   - Após período de estabilização, remover o campo `categoria_id` da tabela `produtos`
   - Atualizar documentação do sistema

3. **Treinamento:**
   - Preparar documentação para usuários finais sobre o novo sistema de classificação
   - Realizar sessões de treinamento para demonstrar as novas funcionalidades

## Benefícios do Novo Sistema

- **Organização hierárquica:** Melhor organização dos produtos com dois níveis de classificação
- **Flexibilidade:** Fácil adição de novas classes dentro dos grupos existentes
- **Usabilidade:** Interface intuitiva para gerenciar a estrutura de classificação
- **Escalabilidade:** Sistema preparado para crescer e acomodar novos tipos de produtos

## Observações

Este novo sistema de classificação é um passo importante para melhorar a organização e a usabilidade do sistema de compras. A estrutura hierárquica permite uma categorização mais precisa dos produtos, facilitando a busca e o gerenciamento do catálogo eletrônico. 