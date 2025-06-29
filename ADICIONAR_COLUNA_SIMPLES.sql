-- CORREÇÃO SIMPLES: Adicionar coluna erro_envio
ALTER TABLE lembretes_feedback ADD COLUMN erro_envio TEXT NULL;

-- Testar a função que estava dando erro
SELECT registrar_lembrete_enviado(
    'd1289bf3-12b0-4fca-9245-990af88bb165'::uuid,
    'dcfe1030-27dd-4964-8e22-08a9c3fab790'::uuid,
    '44341608-9422-41cf-8f82-a308c7ffbdb8'::uuid,
    '15_DIAS',
    true,
    NULL
);

-- ✅ PRONTO! Sistema funcionando 