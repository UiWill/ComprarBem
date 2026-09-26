-- Tabela para guardar chaves de API fora do código-fonte
create table if not exists public.configuracoes_api (
  chave text primary key,
  valor text not null,
  atualizado_em timestamptz not null default now()
);

alter table public.configuracoes_api enable row level security;

-- Leitura publica (necessaria pois o QualiBot aparece tambem em paginas sem login)
create policy "Leitura publica de configuracoes de api"
on public.configuracoes_api
for select
to anon, authenticated
using (true);

-- Chave do Gemini usada pelo QualiBot e pela Pesquisa Tecnica
-- Substitua SUA_CHAVE_AQUI pela chave real antes de rodar (nao versionar a chave real neste arquivo)
insert into public.configuracoes_api (chave, valor)
values ('gemini_api_key', 'SUA_CHAVE_AQUI')
on conflict (chave) do update set valor = excluded.valor, atualizado_em = now();
