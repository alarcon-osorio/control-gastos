/** Tipo de parámetro administrable. */
export type TipoParametro = 'categoria' | 'metodoPago';

export interface Parametro {
  id: number;
  /** uuid del usuario propietario del parámetro. */
  usuarioId: string;
  tipo: TipoParametro;
  nombre: string;
}

/** Datos para crear un parámetro. */
export type ParametroInput = Omit<Parametro, 'id'>;

