import { Injectable, computed, inject, signal } from '@angular/core';
import { SupabaseClient } from '@supabase/supabase-js';
import { SUPABASE } from './supabase.client';
import { Gasto, GastoInput } from '../models/gasto';

/** Fila tal como la devuelve Supabase (columnas en snake_case). */
interface GastoRow {
  id: number;
  usuario_id: string;
  monto: number;
  categoria: string;
  metodo_pago: string;
  fecha: string;
  descripcion: string | null;
}

/**
 * Servicio de gastos con Supabase.
 * Mantiene una copia local en memoria (signal) que se sincroniza con la
 * tabla `gastos`. Cada operación escribe en la nube y actualiza la signal.
 */
@Injectable({
  providedIn: 'root',
})
export class GastosService {
  private readonly supabase = inject(SUPABASE);
  private readonly gastosSignal = signal<Gasto[]>([]);

  /** Todos los gastos cargados en memoria. */
  readonly gastos = this.gastosSignal.asReadonly();

  /** Carga los gastos de un usuario desde Supabase. */
  async cargar(usuarioId: string): Promise<void> {
    const { data, error } = await this.supabase
      .from('gastos')
      .select('*')
      .eq('usuario_id', usuarioId)
      .order('fecha', { ascending: false });
    if (error) {
      throw error;
    }
    this.gastosSignal.set((data as GastoRow[]).map((r) => this.mapear(r)));
  }

  /** Crea un nuevo gasto en Supabase y devuelve su id. */
  async agregar(input: GastoInput): Promise<number> {
    const { data, error } = await this.supabase
      .from('gastos')
      .insert({
        usuario_id: input.usuarioId,
        monto: input.monto,
        categoria: input.categoria,
        metodo_pago: input.metodoPago,
        fecha: input.fecha,
        descripcion: input.descripcion,
        moneda: 'COP',
      })
      .select()
      .single();
    if (error) {
      throw error;
    }
    const gasto = this.mapear(data as GastoRow);
    this.gastosSignal.update((lista) => [gasto, ...lista]);
    return gasto.id;
  }

  /** Actualiza un gasto existente en Supabase. */
  async actualizar(id: number, cambios: Partial<GastoInput>): Promise<void> {
    const payload: Record<string, unknown> = {};
    if (cambios.monto !== undefined) payload['monto'] = cambios.monto;
    if (cambios.categoria !== undefined) payload['categoria'] = cambios.categoria;
    if (cambios.metodoPago !== undefined)
      payload['metodo_pago'] = cambios.metodoPago;
    if (cambios.fecha !== undefined) payload['fecha'] = cambios.fecha;
    if (cambios.descripcion !== undefined)
      payload['descripcion'] = cambios.descripcion;

    const { error } = await this.supabase.from('gastos').update(payload).eq('id', id);
    if (error) {
      throw error;
    }
    this.gastosSignal.update((lista) =>
      lista.map((g) => (g.id === id ? { ...g, ...cambios } : g)),
    );
  }

  /** Elimina un gasto por id en Supabase. */
  async eliminar(id: number): Promise<void> {
    const { error } = await this.supabase.from('gastos').delete().eq('id', id);
    if (error) {
      throw error;
    }
    this.gastosSignal.update((lista) => lista.filter((g) => g.id !== id));
  }

  /** Devuelve los gastos de un usuario (ordenados por fecha desc). */
  gastosPorUsuario(usuarioId: string): Gasto[] {
    return this.gastosSignal()
      .filter((g) => g.usuarioId === usuarioId)
      .sort((a, b) => (a.fecha < b.fecha ? 1 : -1));
  }

  /** Total gastado por un usuario (signal computada). */
  totalUsuario(usuarioId: string) {
    return computed(() =>
      this.gastosSignal()
        .filter((g) => g.usuarioId === usuarioId)
        .reduce((sum, g) => sum + Number(g.monto), 0),
    );
  }

  /** Total por categoría para un usuario (signal computada). */
  totalPorCategoria(usuarioId: string) {
    return computed(() => {
      const mapa = new Map<string, number>();
      for (const g of this.gastosSignal()) {
        if (g.usuarioId !== usuarioId) {
          continue;
        }
        mapa.set(g.categoria, (mapa.get(g.categoria) ?? 0) + Number(g.monto));
      }
      return mapa;
    });
  }

  /** Convierte una fila de Supabase al modelo de la app. */
  private mapear(r: GastoRow): Gasto {
    return {
      id: r.id,
      usuarioId: r.usuario_id,
      monto: Number(r.monto),
      categoria: r.categoria,
      metodoPago: r.metodo_pago,
      fecha: r.fecha,
      descripcion: r.descripcion ?? '',
    };
  }
}

