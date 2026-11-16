-- Inscricao Inteligente UNIASSELVI
-- Banco centralizado inicial para Supabase PostgreSQL.
-- Execute no SQL Editor do projeto Supabase.

create extension if not exists pgcrypto;

create sequence if not exists public.inscricoes_protocolo_seq start 1;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.inscricoes (
  id uuid primary key default gen_random_uuid(),
  protocolo text unique not null default (
    'INS-' || to_char(now() at time zone 'UTC', 'YYYYMMDD') || '-' ||
    lpad(nextval('public.inscricoes_protocolo_seq')::text, 7, '0')
  ),
  nome text not null,
  cpf text not null,
  endereco text not null,
  numero text not null,
  cep text not null,
  celular text not null,
  email text not null,
  tipo_curso text not null,
  modalidade text not null,
  curso text not null,
  curso_origem text,
  status text not null default 'Inscrição recebida',
  resultado text,
  regra_versao text,
  origem_registro text not null default 'portal',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists inscricoes_created_at_idx on public.inscricoes (created_at desc);
create index if not exists inscricoes_cpf_idx on public.inscricoes (cpf);
create index if not exists inscricoes_protocolo_idx on public.inscricoes (protocolo);
create index if not exists inscricoes_tipo_idx on public.inscricoes (tipo_curso);
create index if not exists inscricoes_status_idx on public.inscricoes (status);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_inscricoes_updated_at on public.inscricoes;
create trigger trg_inscricoes_updated_at
before update on public.inscricoes
for each row execute function public.set_updated_at();

alter table public.admin_users enable row level security;
alter table public.inscricoes enable row level security;

-- Um administrador autenticado só consegue consultar seu próprio vínculo de acesso.
drop policy if exists "admin_users_select_self" on public.admin_users;
create policy "admin_users_select_self"
on public.admin_users for select
to authenticated
using (user_id = auth.uid());

-- O portal público pode cadastrar uma inscrição, mas não pode consultar inscrições.
drop policy if exists "public_insert_inscricoes" on public.inscricoes;
create policy "public_insert_inscricoes"
on public.inscricoes for insert
to anon, authenticated
with check (
  nome <> '' and cpf <> '' and email <> '' and
  tipo_curso <> '' and modalidade <> '' and curso <> ''
);

-- Somente usuários explicitamente cadastrados como administradores podem consultar.
drop policy if exists "admins_read_inscricoes" on public.inscricoes;
create policy "admins_read_inscricoes"
on public.inscricoes for select
to authenticated
using (
  exists (
    select 1 from public.admin_users au
    where au.user_id = auth.uid() and au.role = 'admin'
  )
);

drop policy if exists "admins_update_inscricoes" on public.inscricoes;
create policy "admins_update_inscricoes"
on public.inscricoes for update
to authenticated
using (
  exists (
    select 1 from public.admin_users au
    where au.user_id = auth.uid() and au.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.admin_users au
    where au.user_id = auth.uid() and au.role = 'admin'
  )
);

grant insert on public.inscricoes to anon, authenticated;
grant select, update on public.inscricoes to authenticated;
grant usage, select on sequence public.inscricoes_protocolo_seq to anon, authenticated;
grant select on public.admin_users to authenticated;

-- IMPORTANTE:
-- 1. Crie o usuário administrador em Authentication > Users.
-- 2. Copie o UUID desse usuário e execute:
-- insert into public.admin_users (user_id, role)
-- values ('UUID_DO_USUARIO', 'admin');
-- 3. Nunca coloque a service_role key no HTML ou JavaScript público.
-- 4. Não habilite leitura pública da tabela inscricoes.
