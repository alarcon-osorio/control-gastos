-- ============================================================
--  PRESUPUESTO MENSUAL (por mes)
--  Ejecuta este bloque en: Supabase → SQL Editor → New query
-- ============================================================

-- 1) Agregar columna mes si no existe (para tablas ya creadas)
alter table public.presupuestos
  add column if not exists mes text not null default to_char(now(), 'YYYY-MM');

-- 2) Rellenar mes en filas existentes que no lo tengan (por si acaso)
update public.presupuestos
  set mes = to_char(coalesce(actualizado_en, now()), 'YYYY-MM')
  where mes is null or mes = '';

-- 3) Cambiar la clave primaria de (usuario_id) a (usuario_id, mes)
--    para permitir un presupuesto distinto por mes.
alter table public.presupuestos drop constraint if exists presupuestos_pkey;
alter table public.presupuestos add primary key (usuario_id, mes);

-- 4) Crear tabla desde cero si no existía (idempotente)
create table if not exists public.presupuestos (
  usuario_id uuid not null references auth.users on delete cascade,
  mes text not null,
  monto numeric not null check (monto >= 0),
  actualizado_en timestamptz not null default now(),
  primary key (usuario_id, mes)
);

alter table public.presupuestos enable row level security;

drop policy if exists "presupuestos crud propio" on public.presupuestos;
create policy "presupuestos crud propio"
  on public.presupuestos for all
  using (auth.uid() = usuario_id)
  with check (auth.uid() = usuario_id);
