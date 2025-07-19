-- ===========================================================
-- SCRIPT OTIMIZADO PARA O BANCO COMPRAR BEM
-- Baseado na análise completa da estrutura existente
-- ===========================================================

-- Criar tabela para controle de produtos vinculados a usuários RDM
CREATE TABLE IF NOT EXISTS usuarios_rdm_produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id),
    produto_id UUID NOT NULL REFERENCES produtos(id),
    data_vinculacao TIMESTAMPTZ DEFAULT NOW(),
    notificado_email BOOLEAN DEFAULT FALSE,
    data_notificacao TIMESTAMPTZ NULL,
    data_recebimento TIMESTAMPTZ NULL,
    avaliado BOOLEAN DEFAULT FALSE,
    data_avaliacao TIMESTAMPTZ NULL,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    
    -- Índices únicos
    CONSTRAINT uk_usuario_produto 
        UNIQUE (usuario_rdm_id, produto_id)
);

-- Criar tabela para controle de lembretes enviados
CREATE TABLE IF NOT EXISTS lembretes_enviados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    usuario_rdm_id UUID NOT NULL REFERENCES usuarios_rdm(id),
    rdm_id UUID NULL, -- Referência ao produto específico
    tipo_lembrete VARCHAR(20) NOT NULL, -- '10_DIAS', '20_DIAS', '30_DIAS'
    material_nome VARCHAR(500) NOT NULL,
    material_codigo VARCHAR(100) NOT NULL,
    email_enviado BOOLEAN DEFAULT FALSE,
    data_envio TIMESTAMPTZ NULL,
    erro_envio TEXT NULL,
    tentativas INTEGER DEFAULT 0,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    
    -- Índices únicos para evitar duplicatas
    CONSTRAINT uk_lembrete_usuario_material_tipo 
        UNIQUE (usuario_rdm_id, material_codigo, tipo_lembrete)
);

-- Adicionar colunas na tabela emails_enviados para melhor controle
ALTER TABLE emails_enviados 
ADD COLUMN IF NOT EXISTS usuario_rdm_id UUID REFERENCES usuarios_rdm(id),
ADD COLUMN IF NOT EXISTS produto_id UUID REFERENCES produtos(id),
ADD COLUMN IF NOT EXISTS criado_em TIMESTAMPTZ DEFAULT NOW();

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_usuarios_rdm_produtos_tenant ON usuarios_rdm_produtos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_rdm_produtos_usuario ON usuarios_rdm_produtos(usuario_rdm_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_rdm_produtos_produto ON usuarios_rdm_produtos(produto_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_rdm_produtos_notificado ON usuarios_rdm_produtos(notificado_email, data_vinculacao);
CREATE INDEX IF NOT EXISTS idx_lembretes_enviados_tenant ON lembretes_enviados(tenant_id);
CREATE INDEX IF NOT EXISTS idx_lembretes_enviados_usuario ON lembretes_enviados(usuario_rdm_id);
CREATE INDEX IF NOT EXISTS idx_lembretes_enviados_tipo ON lembretes_enviados(tipo_lembrete);

-- ===========================================================
-- FUNÇÃO PARA BUSCAR PRODUTOS PENDENTES DE NOTIFICAÇÃO
-- ===========================================================

CREATE OR REPLACE FUNCTION buscar_produtos_pendentes_notificacao()
RETURNS TABLE (
    produto_id UUID,
    usuario_rdm_id UUID,
    usuario_nome VARCHAR,
    usuario_email VARCHAR,
    nome_produto VARCHAR,
    codigo_produto VARCHAR,
    descricao_produto TEXT,
    categoria_produto VARCHAR,
    unidade_setor VARCHAR,
    data_vinculacao TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        urp.produto_id,
        urp.usuario_rdm_id,
        ur.nome_usuario as usuario_nome,
        ur.email as usuario_email,
        p.nome as nome_produto,
        p.codigo_material as codigo_produto,
        p.descricao as descricao_produto,
        COALESCE(c.nome, 'Categoria Geral') as categoria_produto,
        COALESCE(ur.unidade_setor, 'Não informado') as unidade_setor,
        urp.data_vinculacao
    FROM usuarios_rdm_produtos urp
    JOIN usuarios_rdm ur ON urp.usuario_rdm_id = ur.id
    JOIN produtos p ON urp.produto_id = p.id
    LEFT JOIN categorias c ON p.categoria_id = c.id
    WHERE urp.notificado_email = FALSE
    AND urp.data_vinculacao >= NOW() - INTERVAL '7 days'
    ORDER BY urp.data_vinculacao DESC;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================
-- FUNÇÃO PARA VERIFICAR RDMS QUE PRECISAM DE LEMBRETE
-- ===========================================================

CREATE OR REPLACE FUNCTION verificar_rdms_lembretes_avaliacao()
RETURNS TABLE (
    rdm_id UUID,
    tenant_id UUID,
    usuario_rdm_id UUID,
    tipo_lembrete_necessario VARCHAR,
    material_nome VARCHAR,
    material_codigo VARCHAR,
    dias_desde_aprovacao INTEGER,
    usuario_nome VARCHAR,
    usuario_email VARCHAR,
    unidade_setor VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    WITH rdm_data AS (
        SELECT 
            urp.id as rdm_id,
            urp.tenant_id,
            urp.usuario_rdm_id,
            urp.produto_id,
            ur.nome_usuario as usuario_nome,
            ur.email as usuario_email,
            COALESCE(ur.unidade_setor, 'Não informado') as unidade_setor,
            COALESCE(urp.data_recebimento, urp.data_vinculacao) as data_base,
            p.nome as material_nome,
            p.codigo_material as material_codigo,
            EXTRACT(DAY FROM NOW() - COALESCE(urp.data_recebimento, urp.data_vinculacao))::INTEGER as dias_desde_aprovacao,
            urp.avaliado
        FROM usuarios_rdm_produtos urp
        JOIN usuarios_rdm ur ON urp.usuario_rdm_id = ur.id
        JOIN produtos p ON urp.produto_id = p.id
        WHERE urp.avaliado = FALSE
        AND COALESCE(urp.data_recebimento, urp.data_vinculacao) <= NOW() - INTERVAL '10 days'
    )
    SELECT 
        rd.rdm_id,
        rd.tenant_id,
        rd.usuario_rdm_id,
        CASE 
            WHEN rd.dias_desde_aprovacao >= 30 THEN '30_DIAS'
            WHEN rd.dias_desde_aprovacao >= 20 THEN '20_DIAS'
            WHEN rd.dias_desde_aprovacao >= 10 THEN '10_DIAS'
            ELSE NULL
        END as tipo_lembrete_necessario,
        rd.material_nome,
        rd.material_codigo,
        rd.dias_desde_aprovacao,
        rd.usuario_nome,
        rd.usuario_email,
        rd.unidade_setor
    FROM rdm_data rd
    WHERE rd.dias_desde_aprovacao >= 10
    AND NOT EXISTS (
        SELECT 1 FROM lembretes_enviados le 
        WHERE le.usuario_rdm_id = rd.usuario_rdm_id 
        AND le.material_codigo = rd.material_codigo
        AND le.tipo_lembrete = CASE 
            WHEN rd.dias_desde_aprovacao >= 30 THEN '30_DIAS'
            WHEN rd.dias_desde_aprovacao >= 20 THEN '20_DIAS'
            WHEN rd.dias_desde_aprovacao >= 10 THEN '10_DIAS'
        END
        AND le.email_enviado = TRUE
    )
    ORDER BY rd.dias_desde_aprovacao DESC;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================
-- FUNÇÃO PARA REGISTRAR LEMBRETE ENVIADO
-- ===========================================================

CREATE OR REPLACE FUNCTION registrar_lembrete_enviado(
    p_rdm_id UUID,
    p_tenant_id UUID,
    p_usuario_rdm_id UUID,
    p_tipo_lembrete VARCHAR,
    p_sucesso BOOLEAN,
    p_erro TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    lembrete_id UUID;
    material_info RECORD;
BEGIN
    -- Buscar informações do material
    SELECT 
        p.nome as material_nome,
        p.codigo_material as material_codigo
    INTO material_info
    FROM usuarios_rdm_produtos urp
    JOIN produtos p ON urp.produto_id = p.id
    WHERE urp.id = p_rdm_id;
    
    -- Inserir ou atualizar lembrete
    INSERT INTO lembretes_enviados (
        tenant_id,
        usuario_rdm_id,
        rdm_id,
        tipo_lembrete,
        material_nome,
        material_codigo,
        email_enviado,
        data_envio,
        erro_envio,
        tentativas
    ) VALUES (
        p_tenant_id,
        p_usuario_rdm_id,
        p_rdm_id,
        p_tipo_lembrete,
        material_info.material_nome,
        material_info.material_codigo,
        p_sucesso,
        CASE WHEN p_sucesso THEN NOW() ELSE NULL END,
        p_erro,
        1
    )
    ON CONFLICT (usuario_rdm_id, material_codigo, tipo_lembrete)
    DO UPDATE SET
        email_enviado = p_sucesso,
        data_envio = CASE WHEN p_sucesso THEN NOW() ELSE lembretes_enviados.data_envio END,
        erro_envio = p_erro,
        tentativas = lembretes_enviados.tentativas + 1
    RETURNING id INTO lembrete_id;
    
    RETURN lembrete_id;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================
-- FUNÇÃO PARA ADICIONAR PRODUTO A USUÁRIO RDM
-- ===========================================================

CREATE OR REPLACE FUNCTION adicionar_produto_usuario_rdm(
    p_tenant_id UUID,
    p_usuario_rdm_id UUID,
    p_produto_id UUID,
    p_data_recebimento TIMESTAMPTZ DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    vinculo_id UUID;
BEGIN
    -- Inserir vinculo produto-usuário
    INSERT INTO usuarios_rdm_produtos (
        tenant_id,
        usuario_rdm_id,
        produto_id,
        data_recebimento
    ) VALUES (
        p_tenant_id,
        p_usuario_rdm_id,
        p_produto_id,
        p_data_recebimento
    )
    ON CONFLICT (usuario_rdm_id, produto_id)
    DO UPDATE SET
        data_recebimento = COALESCE(p_data_recebimento, usuarios_rdm_produtos.data_recebimento),
        atualizado_em = NOW()
    RETURNING id INTO vinculo_id;
    
    RETURN vinculo_id;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================
-- FUNÇÃO PARA MARCAR PRODUTO COMO AVALIADO
-- ===========================================================

CREATE OR REPLACE FUNCTION marcar_produto_avaliado(
    p_usuario_rdm_id UUID,
    p_produto_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE usuarios_rdm_produtos 
    SET 
        avaliado = TRUE,
        data_avaliacao = NOW(),
        atualizado_em = NOW()
    WHERE usuario_rdm_id = p_usuario_rdm_id 
    AND produto_id = p_produto_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================
-- TRIGGERS PARA ATUALIZAR TIMESTAMPS
-- ===========================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger na tabela usuarios_rdm_produtos
DROP TRIGGER IF EXISTS trigger_update_usuarios_rdm_produtos ON usuarios_rdm_produtos;
CREATE TRIGGER trigger_update_usuarios_rdm_produtos
    BEFORE UPDATE ON usuarios_rdm_produtos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================================
-- VIEWS PARA RELATÓRIOS
-- ===========================================================

-- View para relatório de avaliações pendentes
CREATE OR REPLACE VIEW vw_avaliacoes_pendentes AS
SELECT 
    urp.id,
    urp.tenant_id,
    ur.nome_usuario,
    ur.email,
    ur.unidade_setor,
    p.nome as material_nome,
    p.codigo_material as material_codigo,
    p.marca,
    p.modelo,
    urp.data_vinculacao,
    urp.data_recebimento,
    urp.notificado_email,
    urp.data_notificacao,
    urp.avaliado,
    urp.data_avaliacao,
    EXTRACT(DAY FROM NOW() - COALESCE(urp.data_recebimento, urp.data_vinculacao))::INTEGER as dias_desde_recebimento,
    CASE 
        WHEN urp.avaliado THEN 'Avaliado'
        WHEN EXTRACT(DAY FROM NOW() - COALESCE(urp.data_recebimento, urp.data_vinculacao)) >= 30 THEN 'Vencido'
        WHEN EXTRACT(DAY FROM NOW() - COALESCE(urp.data_recebimento, urp.data_vinculacao)) >= 20 THEN 'Urgente'
        WHEN EXTRACT(DAY FROM NOW() - COALESCE(urp.data_recebimento, urp.data_vinculacao)) >= 10 THEN 'Pendente'
        ELSE 'Aguardando'
    END as status_avaliacao
FROM usuarios_rdm_produtos urp
JOIN usuarios_rdm ur ON urp.usuario_rdm_id = ur.id
JOIN produtos p ON urp.produto_id = p.id
ORDER BY urp.data_vinculacao DESC;

-- View para relatório de lembretes enviados
CREATE OR REPLACE VIEW vw_lembretes_enviados AS
SELECT 
    le.id,
    le.tenant_id,
    ur.nome_usuario,
    ur.email,
    ur.unidade_setor,
    le.tipo_lembrete,
    le.material_nome,
    le.material_codigo,
    le.email_enviado,
    le.data_envio,
    le.erro_envio,
    le.tentativas,
    le.criado_em
FROM lembretes_enviados le
JOIN usuarios_rdm ur ON le.usuario_rdm_id = ur.id
ORDER BY le.criado_em DESC;

-- ===========================================================
-- INSERIR CONFIGURAÇÕES PADRÃO
-- ===========================================================

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('notificacoes_ativas', 'true', 'Sistema de notificações ativo'),
('intervalo_verificacao_horas', '2', 'Intervalo em horas para verificação automática'),
('prazo_avaliacao_dias', '30', 'Prazo em dias para avaliação de produtos'),
('lembrete_10_dias', 'true', 'Enviar lembrete aos 10 dias'),
('lembrete_20_dias', 'true', 'Enviar lembrete aos 20 dias'),
('lembrete_30_dias', 'true', 'Enviar lembrete aos 30 dias (último)')
ON CONFLICT DO NOTHING;

-- ===========================================================
-- MIGRAR DADOS EXISTENTES DOS MATERIAIS (JSONB)
-- ===========================================================

-- Migrar materiais da coluna JSONB para a nova estrutura
INSERT INTO usuarios_rdm_produtos (tenant_id, usuario_rdm_id, produto_id, data_vinculacao, notificado_email)
SELECT 
    ur.tenant_id,
    ur.id,
    (material->>'produto_id')::UUID,
    ur.criado_em,
    false
FROM usuarios_rdm ur,
     jsonb_array_elements(ur.materiais) as material
WHERE ur.materiais IS NOT NULL
AND jsonb_typeof(ur.materiais) = 'array'
AND material->>'produto_id' IS NOT NULL
ON CONFLICT (usuario_rdm_id, produto_id) DO NOTHING;

-- ===========================================================
-- FUNÇÃO AUXILIAR PARA SINCRONIZAR PRODUTOS COM USUÁRIOS
-- ===========================================================

CREATE OR REPLACE FUNCTION sincronizar_produto_com_usuarios(
    p_produto_id UUID,
    p_usuarios_rdm_ids UUID[]
) RETURNS JSON AS $$
DECLARE
    resultado JSON;
    usuario_id UUID;
    produto_info RECORD;
    sucessos INTEGER := 0;
    erros INTEGER := 0;
    tenant_id UUID;
BEGIN
    -- Buscar informações do produto
    SELECT p.*, t.id as tenant_id_produto
    INTO produto_info
    FROM produtos p
    JOIN tenants t ON p.tenant_id = t.id
    WHERE p.id = p_produto_id;
    
    IF produto_info IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Produto não encontrado',
            'sucessos', 0,
            'erros', 1
        );
    END IF;
    
    -- Sincronizar com cada usuário
    FOREACH usuario_id IN ARRAY p_usuarios_rdm_ids LOOP
        BEGIN
            -- Buscar tenant do usuário
            SELECT ur.tenant_id INTO tenant_id
            FROM usuarios_rdm ur
            WHERE ur.id = usuario_id;
            
            IF tenant_id IS NOT NULL THEN
                -- Adicionar produto ao usuário
                PERFORM adicionar_produto_usuario_rdm(
                    tenant_id,
                    usuario_id,
                    p_produto_id,
                    NOW()
                );
                
                sucessos := sucessos + 1;
            ELSE
                erros := erros + 1;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                erros := erros + 1;
        END;
    END LOOP;
    
    RETURN json_build_object(
        'success', sucessos > 0,
        'message', format('Produto sincronizado: %s sucessos, %s erros', sucessos, erros),
        'sucessos', sucessos,
        'erros', erros,
        'produto_nome', produto_info.nome
    );
END;
$$ LANGUAGE plpgsql;

-- ===========================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ===========================================================

COMMENT ON TABLE usuarios_rdm_produtos IS 'Controle de produtos vinculados a usuários RDM para avaliação';
COMMENT ON TABLE lembretes_enviados IS 'Log de lembretes enviados para avaliação de produtos';
COMMENT ON FUNCTION buscar_produtos_pendentes_notificacao() IS 'Retorna produtos que precisam de notificação por email';
COMMENT ON FUNCTION verificar_rdms_lembretes_avaliacao() IS 'Verifica RDMs que precisam de lembretes de avaliação (10, 20, 30 dias)';
COMMENT ON FUNCTION registrar_lembrete_enviado(UUID, UUID, UUID, VARCHAR, BOOLEAN, TEXT) IS 'Registra lembrete enviado no banco de dados';
COMMENT ON FUNCTION adicionar_produto_usuario_rdm(UUID, UUID, UUID, TIMESTAMPTZ) IS 'Adiciona produto para usuário RDM avaliar';
COMMENT ON FUNCTION marcar_produto_avaliado(UUID, UUID) IS 'Marca produto como avaliado pelo usuário';
COMMENT ON FUNCTION sincronizar_produto_com_usuarios(UUID, UUID[]) IS 'Sincroniza um produto com múltiplos usuários RDM';

-- ===========================================================
-- FINALIZAÇÃO
-- ===========================================================

-- Verificar se as tabelas foram criadas corretamente
SELECT 
    table_name,
    table_type,
    table_schema
FROM information_schema.tables 
WHERE table_name IN ('usuarios_rdm_produtos', 'lembretes_enviados')
ORDER BY table_name;

-- Script executado com sucesso!
SELECT 'Sistema de notificações otimizado criado com sucesso!' as status;