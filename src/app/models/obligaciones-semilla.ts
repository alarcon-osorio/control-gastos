import { GrupoObligacion } from './obligacion';

/**
 * Obligaciones iniciales (importadas de las notas de iCloud).
 * Se siembran automáticamente la primera vez que un usuario abre la app.
 */
export interface ObligacionSemilla {
  nombre: string;
  monto: number;
  diaPago: GrupoObligacion;
  categoria: string;
}

export const OBLIGACIONES_SEMILLA: ObligacionSemilla[] = [
  // Día 10
  { nombre: 'Volleyball', monto: 270000, diaPago: 10, categoria: 'Ocio' },
  { nombre: 'Mercado', monto: 600000, diaPago: 10, categoria: 'Alimentación' },
  { nombre: 'Acueducto', monto: 300000, diaPago: 10, categoria: 'Vivienda' },
  { nombre: 'Hipoteca (Pago Total)', monto: 1000000, diaPago: 10, categoria: 'Vivienda' },
  { nombre: 'Gas Vanti', monto: 80000, diaPago: 10, categoria: 'Vivienda' },
  { nombre: 'Movistar Hogar', monto: 70000, diaPago: 10, categoria: 'Servicios' },
  { nombre: 'Enel Codensa', monto: 220000, diaPago: 10, categoria: 'Servicios' },
  // Día 25
  { nombre: 'Carro Davivienda', monto: 2300000, diaPago: 25, categoria: 'Transporte' },
  { nombre: 'Hipoteca', monto: 1700000, diaPago: 25, categoria: 'Vivienda' },
  { nombre: 'Claro celular mamá', monto: 22000, diaPago: 25, categoria: 'Servicios' },
  { nombre: 'TC Bancolombia', monto: 200000, diaPago: 25, categoria: 'Deudas' },
  { nombre: 'Mercado', monto: 600000, diaPago: 25, categoria: 'Alimentación' },
  { nombre: 'Administración', monto: 400000, diaPago: 25, categoria: 'Vivienda' },
  // Hormigas
  { nombre: 'Música', monto: 20000, diaPago: null, categoria: 'Ocio' },
  { nombre: 'Gasolina', monto: 100000, diaPago: null, categoria: 'Transporte' },
];