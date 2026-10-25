-- ============================================================
--  ESQUEMA DE BASE DE DATOS · App de Gestión de Gastos
--  Ejecuta este script en: Supabase → SQL Editor → New query
-- ============================================================

-- 1) TABLA: perfiles
--    Guarda información pública del usuario. Se enlaza al auth.users
--    de Supabase mediante el id (uuid).
create table if not exists public.perfiles (
  id uuid references auth.users on delete cascade primary key,
  nombre text not null,
  email text not null,
  creado_en timestamptz not null default now()
);

-- 2) TABLA: gastos
--    Cada gasto pertenece a un usuario. El monto se guarda en COP (base).
create table if not exists public.gastos (
  id bigint generated always as identity primary key,
  usuario_id uuid not null references auth.users on delete cascade,
  monto numeric not null check (monto >= 0),
  categoria text not null,
  metodo_pago text not null,
  fecha date not null,
  descripcion text not null default '',
  moneda text not null default 'COP',
  creado_en timestamptz not null default now()
);

-- 3) TABLA: parametros
--    Categorías y métodos de pago por usuario.
create table if not exists public.parametros (
  id bigint generated always as identity primary key,
  usuario_id uuid not null references auth.users on delete cascade,
  tipo text not null check (tipo in ('categoria', 'metodoPago')),
  nombre text not null
);

-- Índices para acelerar las consultas por usuario.
create index if not exists idx_gastos_usuario on public.gastos (usuario_id);
create index if not exists idx_parametros_usuario on public.parametros (usuario_id);

-- ============================================================
--  SEGURIDAD · Row Level Security (RLS)
--  Cada usuario SOLO puede ver y modificar sus propios datos.
-- ============================================================

alter table public.perfiles enable row level security;
alter table public.gastos enable row level security;
alter table public.parametros enable row level security;

-- Perfiles: el usuario ve y edita únicamente su perfil.
drop policy if exists "perfiles select propio" on public.perfiles;
create policy "perfiles select propio"
  on public.perfiles for select
  using (auth.uid() = id);

drop policy if exists "perfiles insert propio" on public.perfiles;
create policy "perfiles insert propio"
  on public.perfiles for insert
  with check (auth.uid() = id);

drop policy if exists "perfiles update propio" on public.perfiles;
create policy "perfiles update propio"
  on public.perfiles for update
  using (auth.uid() = id);

-- Gastos: CRUD solo sobre las filas del propio usuario.
drop policy if exists "gastos crud propio" on public.gastos;
create policy "gastos crud propio"
  on public.gastos for all
  using (auth.uid() = usuario_id)
  with check (auth.uid() = usuario_id);

-- Parámetros: CRUD solo sobre las filas del propio usuario.
drop policy if exists "parametros crud propio" on public.parametros;
create policy "parametros crud propio"
  on public.parametros for all
  using (auth.uid() = usuario_id)
  with check (auth.uid() = usuario_id);

-- ============================================================
--  TRIGGER: crea automáticamente un perfil al registrarse un usuario.
-- ============================================================
create or replace function public.crear_perfil_automatico()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.perfiles (id, nombre, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nombre', split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.crear_perfil_automatico();
