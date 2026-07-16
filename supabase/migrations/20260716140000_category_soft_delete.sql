-- Soft-delete para a tabela `category`.
--
-- Motivo: excluir uma categoria que tinha itens era impossível. A FK
-- `aircraft_items.category_id -> category(id)` é NO ACTION e a coluna é
-- NOT NULL, então mesmo soft-deletando os itens (deleted=true) eles seguem
-- referenciando a categoria e o hard-delete dela dispara 23503. Como
-- `category` não tinha coluna de soft-delete, não havia como "remover" a
-- categoria sem apagar itens usados em propostas (o que corromperia o
-- histórico: 7 itens já estão em `proposal_item`).
--
-- Solução: alinhar `category` ao padrão de `aircraft_items`/`aircrafts` com
-- uma coluna `deleted`. Excluir categoria passa a ser soft-delete (dela e dos
-- itens): some do painel e das propostas novas, preserva as antigas, e é
-- reversível.
--
-- Coluna aditiva, com default -> não quebra o app cliente nem writes existentes.
-- A policy de escrita `category_write_seller_or_admin` (FOR ALL) já cobre o
-- UPDATE de `deleted` por seller/admin; nenhuma policy nova é necessária.

alter table public.category
  add column if not exists deleted boolean not null default false;

comment on column public.category.deleted is
  'Soft-delete: categorias com deleted=true não aparecem no painel (o painel '
  'filtra deleted=false). Reversível.';

-- Rollback:
--   alter table public.category drop column if exists deleted;
