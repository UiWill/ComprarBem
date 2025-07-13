-- Adicionar coluna sugestoes na tabela rdm_feedbacks
ALTER TABLE rdm_feedbacks ADD COLUMN sugestoes TEXT;

-- Adicionar comentário para documentação
COMMENT ON COLUMN rdm_feedbacks.sugestoes IS 'Sugestões do usuário para melhoria do produto avaliado';

-- Verificar se foi criada
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'rdm_feedbacks' 
AND column_name = 'sugestoes';