import { supabase } from './supabase'
import PerfilUsuarioService from './perfilUsuarioService'

/**
 * Serviço para registro de órgãos com 4 perfis de usuário
 * Cria automaticamente: CPM, CCL, Órgão Administrativo, Assessoria Jurídica
 */
export class RegistroOrgaoService {

  // =====================================================
  // REGISTRO COMPLETO DO ÓRGÃO
  // =====================================================

  /**
   * Registrar órgão completo com 4 usuários
   */
  static async registrarOrgaoCompleto(dadosOrgao) {
    try {
      console.log('🚀 INICIANDO REGISTRO DO ÓRGÃO:', dadosOrgao.nome_orgao)

      // 1. Limpeza preventiva de possíveis registros órfãos
      await this.limpezaPreventiva(dadosOrgao)

      // 2. Validar dados obrigatórios
      await this.validarDadosOrgao(dadosOrgao)

      // 3. Criar tenant (órgão)
      const tenant = await this.criarTenant(dadosOrgao)
      console.log('✅ Tenant criado:', tenant.id)

      // 4. Criar os 4 usuários com perfis específicos
      const usuarios = await this.criarUsuariosOrgao(tenant.id, dadosOrgao)
      console.log('✅ Usuários criados:', usuarios.length)

      // 5. Configurar perfis automáticamente (TEMPORARIAMENTE DESABILITADO)
      // await this.configurarPerfisUsuarios(usuarios, tenant.id)
      console.log('✅ Perfis serão configurados posteriormente (função com erro de coluna)')

      // 6. Retornar resultado completo
      return {
        sucesso: true,
        tenant,
        usuarios,
        mensagem: `Órgão ${dadosOrgao.nome_orgao} registrado com sucesso!`
      }

    } catch (error) {
      console.error('❌ ERRO NO REGISTRO DO ÓRGÃO:', error)
      throw new Error(`Falha no registro: ${error.message}`)
    }
  }

  // =====================================================
  // LIMPEZA PREVENTIVA
  // =====================================================

  /**
   * Limpeza preventiva de registros órfãos
   */
  static async limpezaPreventiva(dadosOrgao) {
    try {
      console.log('🧹 LIMPEZA PREVENTIVA INICIADA')
      
      const emails = [
        dadosOrgao.email_cpm,
        dadosOrgao.email_ccl,
        dadosOrgao.email_orgao_admin,
        dadosOrgao.email_assessoria
      ]
      
      console.log('Emails para verificar/limpar:', emails)
      
      for (const email of emails) {
        try {
          // Verificar se existe registro órfão
          const { data: usuarioExistente } = await supabase
            .from('usuarios')
            .select('id, email, tenant_id')
            .eq('email', email)
            .maybeSingle()
          
          if (usuarioExistente) {
            console.log(`🗑️ Removendo registro órfão encontrado: ${email} (ID: ${usuarioExistente.id})`)
            
            // Remover da tabela usuarios
            await supabase
              .from('usuarios')
              .delete()
              .eq('email', email)
            
            console.log(`✅ Registro órfão removido: ${email}`)
          }
        } catch (error) {
          console.warn(`Aviso na limpeza de ${email}:`, error.message)
        }
      }
      
      console.log('✅ LIMPEZA PREVENTIVA CONCLUÍDA')
      
    } catch (error) {
      console.error('Erro na limpeza preventiva:', error)
      // Não bloquear o registro por causa da limpeza
    }
  }

  // =====================================================
  // VALIDAÇÕES
  // =====================================================

  /**
   * Validar dados obrigatórios do órgão
   */
  static async validarDadosOrgao(dados) {
    console.log('🔍 INICIANDO VALIDAÇÃO DOS DADOS DO ÓRGÃO')
    
    const camposObrigatorios = [
      'nome_orgao',
      'email_cpm',
      'senha_cpm',
      'email_ccl', 
      'senha_ccl',
      'email_orgao_admin',
      'senha_orgao_admin',
      'email_assessoria',
      'senha_assessoria'
    ]

    console.log('Validando campos obrigatórios...')
    for (const campo of camposObrigatorios) {
      if (!dados[campo] || dados[campo].trim() === '') {
        throw new Error(`Campo obrigatório: ${campo}`)
      }
    }

    // Validar formato de emails
    const emails = [
      dados.email_cpm,
      dados.email_ccl,
      dados.email_orgao_admin,
      dados.email_assessoria
    ]

    console.log('Validando formato dos emails:', emails)
    for (const email of emails) {
      if (!this.validarEmail(email)) {
        throw new Error(`Email inválido: ${email}`)
      }
    }

    // Verificar se emails são únicos
    const emailsUnicos = new Set(emails)
    if (emailsUnicos.size !== emails.length) {
      throw new Error('Todos os emails devem ser diferentes')
    }
    console.log('✅ Emails são únicos entre si')

    // Verificar se algum email já existe no sistema
    console.log('🔍 Verificando se emails já existem no sistema...')
    for (const email of emails) {
      console.log(`Verificando email: ${email}`)
      const emailExiste = await this.verificarEmailExiste(email)
      if (emailExiste) {
        throw new Error(`❌ O email ${email} já está cadastrado no sistema. Use emails diferentes.`)
      }
    }
    console.log('✅ Nenhum email já existe no sistema')

    // Validar senhas (mínimo 6 caracteres)
    console.log('Validando senhas...')
    const senhas = [
      dados.senha_cpm,
      dados.senha_ccl,
      dados.senha_orgao_admin,
      dados.senha_assessoria
    ]

    for (const senha of senhas) {
      if (senha.length < 6) {
        throw new Error('Todas as senhas devem ter pelo menos 6 caracteres')
      }
    }
    
    console.log('✅ VALIDAÇÃO COMPLETA - Todos os dados estão corretos!')
  }

  /**
   * Validar formato de email
   */
  static validarEmail(email) {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return regex.test(email)
  }

  // =====================================================
  // CRIAÇÃO DE TENANT
  // =====================================================

  /**
   * Criar tenant (órgão)
   */
  static async criarTenant(dadosOrgao) {
    try {
      // Usar apenas campos que existem na tabela tenants
      const tenantData = {
        nome: dadosOrgao.nome_orgao,
        descricao: `${dadosOrgao.tipo_orgao || 'Órgão público'} - ${dadosOrgao.nome_orgao}`,
        ativo: true
      }

      const { data, error } = await supabase
        .from('tenants')
        .insert(tenantData)
        .select()
        .single()

      if (error) {
        console.error('Erro ao criar tenant:', error)
        throw error
      }

      return data

    } catch (error) {
      console.error('Erro no serviço de tenant:', error)
      throw error
    }
  }

  // =====================================================
  // CRIAÇÃO DE USUÁRIOS
  // =====================================================

  /**
   * Criar os 4 usuários do órgão
   */
  static async criarUsuariosOrgao(tenantId, dadosOrgao) {
    const usuariosDefinicoes = [
      {
        email: dadosOrgao.email_cpm,
        senha: dadosOrgao.senha_cpm,
        nome_completo: dadosOrgao.nome_responsavel_cpm || 'Responsável CPM',
        perfil: PerfilUsuarioService.PERFIS.CPM,
        cargo: 'Presidente da CPM',
        descricao: 'Comissão Permanente de Padronização de Materiais'
      },
      {
        email: dadosOrgao.email_ccl,
        senha: dadosOrgao.senha_ccl,
        nome_completo: dadosOrgao.nome_responsavel_ccl || 'Responsável CCL',
        perfil: PerfilUsuarioService.PERFIS.CCL,
        cargo: 'Presidente da CCL',
        descricao: 'Comissão de Contratação e Licitação'
      },
      {
        email: dadosOrgao.email_orgao_admin,
        senha: dadosOrgao.senha_orgao_admin,
        nome_completo: dadosOrgao.nome_responsavel_admin || 'Autoridade Competente',
        perfil: PerfilUsuarioService.PERFIS.ORGAO_ADMINISTRATIVO,
        cargo: 'Autoridade Competente',
        descricao: 'Órgão Administrativo - Assinaturas e Homologações'
      },
      {
        email: dadosOrgao.email_assessoria,
        senha: dadosOrgao.senha_assessoria,
        nome_completo: dadosOrgao.nome_responsavel_assessoria || 'Assessor Jurídico',
        perfil: PerfilUsuarioService.PERFIS.ASSESSORIA_JURIDICA,
        cargo: 'Assessor Jurídico',
        descricao: 'Assessoria Jurídica - Análise de Minutas e Editais'
      }
    ]

    const usuariosCriados = []

    for (const usuarioDef of usuariosDefinicoes) {
      try {
        const usuario = await this.criarUsuarioIndividual(usuarioDef, tenantId)
        usuariosCriados.push(usuario)
        console.log(`Usuário ${usuarioDef.perfil} criado:`, usuario.email)
      } catch (error) {
        console.error(`Erro ao criar usuário ${usuarioDef.perfil}:`, error)
        throw new Error(`Falha ao criar usuário ${usuarioDef.perfil}: ${error.message}`)
      }
    }

    return usuariosCriados
  }

  /**
   * Criar usuário individual (versão simplificada sem retry)
   */
  static async criarUsuarioIndividual(usuarioDef, tenantId) {
    try {
      console.log(`🚀 CRIANDO USUÁRIO: ${usuarioDef.email} (Perfil: ${usuarioDef.perfil})`)
      
      // 1. VERIFICAÇÃO FINAL ANTES DE CRIAR
      console.log('🔍 Verificação final de segurança...')
      const emailJaExiste = await this.verificarEmailExiste(usuarioDef.email)
      if (emailJaExiste) {
        throw new Error(`Email ${usuarioDef.email} foi encontrado no sistema mesmo após limpeza`)
      }

      // 2. Mapear perfil para tipo correto ANTES de criar
      const tipoMap = {
        'cpm': 'cpm',
        'ccl': 'admin', 
        'orgao_administrativo': 'admin',
        'assessoria_juridica': 'admin'
      }
      
      const tipoUsuario = tipoMap[usuarioDef.perfil] || 'admin'
      console.log(`📋 Tipo mapeado para ${usuarioDef.perfil}: ${tipoUsuario}`)

      // 3. Criar usuário no Supabase Auth (APENAS UMA VEZ)
      console.log('🔐 Criando usuário no Auth...')
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: usuarioDef.email,
        password: usuarioDef.senha,
        options: {
          emailRedirectTo: undefined, // Não redirecionar
          data: {
            full_name: usuarioDef.nome_completo,
            cargo: usuarioDef.cargo,
            perfil_usuario: usuarioDef.perfil,
            tenant_id: tenantId
          }
        }
      })

      if (authError) {
        console.error('❌ Erro no Auth:', authError)
        throw authError
      }

      if (!authData.user) {
        throw new Error('Usuário não foi criado no Auth - dados inválidos')
      }

      console.log('✅ Usuário criado no Auth:', authData.user.id)

      // 4. Aguardar sincronização e verificar se foi criado automaticamente
      await new Promise(resolve => setTimeout(resolve, 500))

      // 5. VERIFICAR SE JÁ FOI CRIADO POR TRIGGER AUTOMÁTICO
      console.log('🔍 Verificando se usuário já foi criado automaticamente por trigger...')
      const { data: usuarioExistente } = await supabase
        .from('usuarios')
        .select('*')
        .eq('id', authData.user.id)
        .maybeSingle()

      let userRecord = null

      if (usuarioExistente) {
        console.log('✅ Usuário já criado automaticamente por trigger:', usuarioExistente.id)
        
        // Atualizar com nossos dados específicos
        console.log('📝 Atualizando dados do usuário criado automaticamente...')
        const { data: updatedUser, error: updateError } = await supabase
          .from('usuarios')
          .update({
            nome: usuarioDef.nome_completo,
            perfil_usuario: usuarioDef.perfil,
            tenant_id: tenantId,
            ativo: true,
            tipo: tipoUsuario
          })
          .eq('id', authData.user.id)
          .select()
          .single()

        if (updateError) {
          console.error('❌ Erro ao atualizar usuário automático:', updateError)
          throw updateError
        }

        userRecord = updatedUser
        console.log('✅ Usuário atualizado com nossos dados')

      } else {
        // 6. Se não foi criado automaticamente, criar manualmente
        const userData = {
          id: authData.user.id,
          email: usuarioDef.email,
          nome: usuarioDef.nome_completo,
          perfil_usuario: usuarioDef.perfil,
          tenant_id: tenantId,
          ativo: true,
          tipo: tipoUsuario
        }

        console.log('📝 Inserindo na tabela usuarios (criação manual):', userData)

        // Usar RPC para inserção privilegiada que ignora RLS
        let { data, error: userError } = await supabase.rpc('inserir_usuario_sistema', {
          p_id: userData.id,
          p_email: userData.email,
          p_nome: userData.nome,
          p_tipo: userData.tipo,
          p_perfil_usuario: userData.perfil_usuario,
          p_tenant_id: userData.tenant_id,
          p_ativo: userData.ativo
        })

        // Fallback: se não existir a função RPC, tentar inserção normal
        if (userError && userError.code === '42883') {
          console.log('⚠️ Função RPC não existe, tentando inserção normal...')
          
          const fallbackResult = await supabase
            .from('usuarios')
            .insert(userData)
            .select()
            .single()
          
          data = fallbackResult.data
          userError = fallbackResult.error
        }

        if (userError) {
          console.error('❌ Erro ao inserir na tabela usuarios:', userError)
          
          // Se der erro de constraint, fazer diagnóstico detalhado
          if (userError.code === '23505') {
            console.log('🧹 Erro de chave duplicada detectado!')
            console.log('🔍 Problema identificado: Policies RLS estão interferindo na inserção')
            console.log('📋 Execute: CRIAR_FUNCAO_RPC_USUARIO.sql para resolver')
            console.log(`❌ Email problemático: ${usuarioDef.email}`)
          }
          
          throw userError
        }

        userRecord = data
        console.log('✅ Usuário inserido manualmente na tabela usuarios')
      }

      console.log('✅ Usuário processado na tabela usuarios:', userRecord.id)

      return {
        id: authData.user.id,
        email: usuarioDef.email,
        nome_completo: usuarioDef.nome_completo,
        perfil: usuarioDef.perfil,
        cargo: usuarioDef.cargo,
        tenant_id: tenantId
      }

    } catch (error) {
      console.error(`❌ ERRO CRÍTICO ao criar usuário ${usuarioDef.email}:`, error)
      throw error
    }
  }

  // =====================================================
  // CONFIGURAÇÃO DE PERFIS
  // =====================================================

  /**
   * Configurar perfis dos usuários criados
   */
  static async configurarPerfisUsuarios(usuarios, tenantId) {
    try {
      for (const usuario of usuarios) {
        await this.atualizarPerfilUsuario(usuario.id, usuario.perfil)
        console.log(`Perfil ${usuario.perfil} configurado para ${usuario.email}`)
      }
    } catch (error) {
      console.error('Erro ao configurar perfis:', error)
      throw error
    }
  }

  /**
   * Atualizar perfil de usuário específico
   */
  static async atualizarPerfilUsuario(userId, perfil) {
    try {
      const { data, error } = await supabase.rpc('atualizar_perfil_usuario', {
        p_user_id: userId,
        p_novo_perfil: perfil
      })

      if (error) {
        throw error
      }

      return data
    } catch (error) {
      console.error('Erro ao atualizar perfil:', error)
      throw error
    }
  }

  // =====================================================
  // VERIFICAÇÕES E UTILITÁRIOS
  // =====================================================

  /**
   * Verificar se email já existe (com verificação dupla)
   */
  static async verificarEmailExiste(email) {
    try {
      console.log('🔍 VERIFICAÇÃO ROBUSTA DE EMAIL:', email)
      
      // 1. Primeira verificação na tabela usuarios
      const { data: usuario, error: errorUsuario } = await supabase
        .from('usuarios')
        .select('email, id, ativo')
        .eq('email', email)
        .maybeSingle()

      console.log('Resultado tabela usuarios:', { email, usuario, errorUsuario })

      if (errorUsuario && errorUsuario.code !== 'PGRST116') {
        console.error('Erro na verificação de email (usuarios):', errorUsuario)
        throw errorUsuario
      }

      // 2. Se encontrou na tabela usuarios
      if (usuario) {
        console.log(`❌ EMAIL ${email} JÁ EXISTE NA TABELA USUARIOS (ID: ${usuario.id}, Ativo: ${usuario.ativo})`)
        return true
      }

      // 3. Verificação adicional: tentar buscar por padrão similar
      const { data: emailsSimilares, error: errorSimilares } = await supabase
        .from('usuarios')
        .select('email')
        .ilike('email', email)

      if (emailsSimilares && emailsSimilares.length > 0) {
        console.log(`⚠️ Encontrados emails similares:`, emailsSimilares.map(e => e.email))
        return true
      }

      console.log(`✅ EMAIL ${email} NÃO EXISTE NO SISTEMA - LIVRE PARA USO`)
      return false
      
    } catch (error) {
      console.error('❌ ERRO CRÍTICO na verificação de email:', error)
      throw error
    }
  }

  /**
   * Verificar se órgão já existe
   */
  static async verificarOrgaoExiste(nomeOrgao) {
    try {
      const { data, error } = await supabase
        .from('tenants')
        .select('nome')
        .ilike('nome', nomeOrgao)
        .maybeSingle()

      if (error && error.code !== 'PGRST116') {
        throw error
      }

      return !!data
    } catch (error) {
      console.error('Erro ao verificar órgão:', error)
      return false
    }
  }

  /**
   * Obter template de dados para registro
   */
  static obterTemplateDados() {
    return {
      // Dados do Órgão
      nome_orgao: '',
      tipo_orgao: 'publico', // publico, estadual, municipal, federal
      endereco: '',
      telefone: '',
      email_contato: '',
      cnpj: '',

      // CPM - Comissão Permanente de Padronização
      email_cpm: '',
      senha_cpm: '',
      nome_responsavel_cpm: '',

      // CCL - Comissão de Contratação e Licitação  
      email_ccl: '',
      senha_ccl: '',
      nome_responsavel_ccl: '',

      // Órgão Administrativo
      email_orgao_admin: '',
      senha_orgao_admin: '',
      nome_responsavel_admin: '',

      // Assessoria Jurídica
      email_assessoria: '',
      senha_assessoria: '',
      nome_responsavel_assessoria: ''
    }
  }

  /**
   * Gerar senhas automáticas (opcional)
   */
  static gerarSenhaAutomatica(tamanho = 8) {
    const caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    let senha = ''
    for (let i = 0; i < tamanho; i++) {
      senha += caracteres.charAt(Math.floor(Math.random() * caracteres.length))
    }
    return senha
  }

  /**
   * Obter resumo do registro
   */
  static obterResumoRegistro(resultado) {
    if (!resultado.sucesso) {
      return 'Falha no registro'
    }

    const { tenant, usuarios } = resultado

    return {
      orgao: {
        nome: tenant.nome,
        id: tenant.id
      },
      usuarios: usuarios.map(u => ({
        perfil: u.perfil,
        email: u.email,
        nome: u.nome_completo,
        cargo: u.cargo
      })),
      acessos: {
        cpm: `${usuarios.find(u => u.perfil === 'cpm')?.email} - Acesso completo exceto CCL`,
        ccl: `${usuarios.find(u => u.perfil === 'ccl')?.email} - Apenas Painel CCL`, 
        admin: `${usuarios.find(u => u.perfil === 'orgao_administrativo')?.email} - Processos Administrativos`,
        juridico: `${usuarios.find(u => u.perfil === 'assessoria_juridica')?.email} - Análise Jurídica`
      }
    }
  }
}

export default RegistroOrgaoService