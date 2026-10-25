export type GrupoObligacion = 10 | 25 | null;

export interface Obligacion {
  id: number;
  /** uuid del usuario propietario de la obligación. */
  usuarioId: string;
  /** Nombre legible, ej. "Mercado". */
  nombre: string;
  /** Monto por defecto en COP (moneda base). */
  monto: number;
  /** Día sugerido de pago: 10, 25, o null para "hormigas". */
  diaPago: GrupoObligacion;
  /** Categoría asignada al gasto que se crea al pagar. */
  categoria: string;
  /** Si está activa aparece en el checklist mensual. */
  activa: boolean;
}

/** Datos para crear/actualizar una obligación (sin id). */
export type ObligacionInput = Omit<Obligacion, 'id'>;

/** Pago de una obligación dentro de un mes concreto. */
export interface PagoObligacion {
  id: number;
  usuarioId: string;
  obligacionId: number;
  /** Mes en formato YYYY-MM. */
  mes: string;
  /** Gasto real creado al marcar como pagada. */
  gastoId: number;
}
