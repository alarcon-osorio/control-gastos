
-- ============================================================
--  OBLIGACIONES MENSUALES (checklist tipo iCloud)
--  Ejecuta también este bloque en: Supabase → SQL Editor
-- ============================================================

-- 4) TABLA: obligaciones
--    Catálogo parametrizable de obligaciones recurrentes.
--    dia_pago: 10 (quincena 1), 25 (quincena 2), null (hormigas / variables).
create table if not exists public.obligaciones (
  id bigint generated always as identity primary key,
  usuario_id uuid not null references auth.users on delete cascade,
  nombre text not null,
  monto numeric not null check (monto >= 0),
  dia_pago smallint check (dia_pago in (10, 25)),
  categoria text not null default 'Otros',
  activa boolean not null default true,
  creado_en timestamptz not null default now()
);

-- 5) TABLA: pagos_obligaciones
--    Registra qué obligación se pagó en qué mes y enlaza al gasto creado.
create table if not exists public.pagos_obligaciones (
  id bigint generated always as identity primary key,
  usuario_id uuid not null references auth.users on delete cascade,
  obligacion_id bigint not null references public.obligaciones on delete cascade,
  mes text not null, -- YYYY-MM
  gasto_id bigint references public.gastos on delete set null,
  creado_en timestamptz not null default now(),
  -- Evita marcar dos veces la misma obligación en el mismo mes.
  unique (obligacion_id, mes)
);

create index if not exists idx_obligaciones_usuario on public.obligaciones (usuario_id);
create index if not exists idx_pagos_oblig_usuario on public.pagos_obligaciones (usuario_id);
create index if not exists idx_pagos_oblig_mes on public.pagos_obligaciones (mes);

-- Seguridad RLS: cada usuario solo ve y edita sus obligaciones y pagos.
alter table public.obligaciones enable row level security;
alter table public.pagos_obligaciones enable row level security;

drop policy if exists "obligaciones crud propio" on public.obligaciones;
create policy "obligaciones crud propio"
  on public.obligaciones for all
  using (auth.uid() = usuario_id)
  with check (auth.uid() = usuario_id);

drop policy if exists "pagos obligaciones crud propio" on public.pagos_obligaciones;
create policy "pagos obligaciones crud propio"
  on public.pagos_obligaciones for all
  using (auth.uid() = usuario_id)
  with check (auth.uid() = usuario_id);