export interface Gasto {
  id: number;
  /** uuid del usuario propietario del gasto. */
  usuarioId: string;
  /** Monto siempre almacenado en COP (moneda base). */
  monto: number;
  categoria: string;
  metodoPago: string;
  /** Fecha en formato ISO (YYYY-MM-DD). */
  fecha: string;
  descripcion: string;
}

/** Datos para crear/actualizar un gasto (sin id). */
export type GastoInput = Omit<Gasto, 'id'>;

