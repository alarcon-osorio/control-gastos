/**
 * Mock de Supabase para tests (sin red).
 * Expone un cliente con la API encadenable usada por los servicios
 * (from().select().eq().order(), insert, update, delete) y el auth básico.
 */
export function crearSupabaseMock() {
  const store: Record<string, Record<string, unknown>[]> = {};
  const seq: Record<string, number> = {};
  let authCb: ((event: string, session: unknown) => void) | null = null;
  const usuarios: { id: string; email: string; password: string }[] = [];
  let contador = 0;

  const ok = <T>(data: T) => Promise.resolve({ data, error: null });
  const filas = (t: string) => (store[t] ??= []);
  const nextId = (t: string) => (seq[t] = (seq[t] ?? 0) + 1);

  const client = {
    from: (t: string) => {
      const b: Record<string, unknown> = {};
      b['select'] = () => b;
      b['eq'] = () => b;
      b['order'] = () => ok(filas(t).map((f) => ({ ...f })));
      b['insert'] = (fila: Record<string, unknown> | Record<string, unknown>[]) => {
        const items = Array.isArray(fila) ? fila : [fila];
        const creadas = items.map((f) => {
          const nueva = { id: nextId(t), ...f };
          filas(t).push(nueva);
          return { ...nueva };
        });
        return { select: () => ({ single: () => ok(creadas[0]) }) };
      };
      b['update'] = (cambios: Record<string, unknown>) => ({
        eq: (col: string, val: unknown) => {
          const f = filas(t).find((r) => r[col] === val);
          if (f) Object.assign(f, cambios);
          return ok(null);
        },
      });
      b['delete'] = () => ({
        eq: (col: string, val: unknown) => {
          const arr = filas(t);
          const i = arr.findIndex((r) => r[col] === val);
          if (i >= 0) arr.splice(i, 1);
          return ok(null);
        },
      });
      return b;
    },
    auth: {
      onAuthStateChange: (cb: (e: string, s: unknown) => void) => {
        authCb = cb;
        return { data: { subscription: { unsubscribe: () => {} } } };
      },
      getSession: () => ok({ session: null }),
      signUp: (opts: { email: string; password: string; options?: { data?: { nombre?: string } } }) => {
        contador += 1;
        const id = 'uuid-' + contador;
        usuarios.push({ id, email: opts.email, password: opts.password });
        const session = {
          user: {
            id,
            email: opts.email,
            created_at: '2026-01-01T00:00:00Z',
            user_metadata: { nombre: opts.options?.data?.['nombre'] },
          },
        };
        authCb?.('SIGNED_IN', session);
        return ok(session);
      },
      signInWithPassword: (opts: { email: string; password: string }) => {
        const u = usuarios.find((x) => x.email === opts.email && x.password === opts.password);
        if (!u) {
          return Promise.resolve({ data: { session: null }, error: { message: 'Invalid login' } });
        }
        const session = {
          user: { id: u.id, email: u.email, created_at: '2026-01-01T00:00:00Z', user_metadata: {} },
        };
        authCb?.('SIGNED_IN', session);
        return ok(session);
      },
      signOut: () => {
        authCb?.('SIGNED_OUT', null);
        return ok(null);
      },
    },
  };

  return { client, store, usuarios };
}
