-- ============================================================
--  PRESUPUESTO MENSUAL
--  Ejecuta este bloque en: Supabase → SQL Editor → New query
-- ============================================================

create table if not exists public.presupuestos (
  usuario_id uuid not null references auth.users on delete cascade primary key,
  monto numeric not null check (monto >= 0),
  actualizado_en timestamptz not null default now()
);

alter table public.presupuestos enable row level security;

drop policy if exists "presupuestos crud propio" on public.presupuestos;
create policy "presupuestos crud propio"
  on public.presupuestos for all
  using (auth.uid() = usuario_id)
  with check (auth.uid() = usuario_id);
