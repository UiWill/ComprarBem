-- =====================================================
-- ADICIONAR FOREIGN KEY PARA PROCESSO_EDITAIS
-- =====================================================
--
-- Este script adiciona as foreign keys necessárias para que
-- o Supabase consiga fazer JOINs automáticos
--

-- Adicionar foreign key para editais
ALTER TABLE processo_editais
ADD CONSTRAINT fk_processo_editais_edital
FOREIGN KEY (edital_id) REFERENCES editais(id) ON DELETE CASCADE;

-- Adicionar foreign key para processos_administrativos (opcional)
-- ALTER TABLE processo_editais
-- ADD CONSTRAINT fk_processo_editais_processo
-- FOREIGN KEY (processo_id) REFERENCES processos_administrativos(id) ON DELETE CASCADE;

-- Verificar se as foreign keys foram criadas
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'processo_editais';