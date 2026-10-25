import { Injectable, computed, inject, signal } from '@angular/core';
import { SUPABASE } from './supabase.client';
import { GastosService } from './gastos.service';
import { OBLIGACIONES_SEMILLA } from '../models/obligaciones-semilla';
import {
  GrupoObligacion,
  Obligacion,
  ObligacionInput,
  PagoObligacion,
} from '../models/obligacion';

interface ObligacionRow {
  id: number;
  usuario_id: string;
  nombre: string;
  monto: number;
  dia_pago: number | null;
  categoria: string;
  activa: boolean;
}

interface PagoRow {
  id: number;
  usuario_id: string;
  obligacion_id: number;
  mes: string;
  gasto_id: number | null;
}

const METODO_OBLIGACION = 'Obligación';

/**
 * Servicio de obligaciones recurrentes con Supabase.
 * Marcar como pagada crea un gasto real (vía GastosService) y registra
 * el pago en `pagos_obligaciones` para poder desmarcarlo luego.
 */
@Injectable({ providedIn: 'root' })
export class ObligacionesService {
  private readonly supabase = inject(SUPABASE);
  private readonly gastosService = inject(GastosService);

  private readonly obligacionesSignal = signal<Obligacion[]>([]);
  private readonly pagosSignal = signal<PagoObligacion[]>([]);

  readonly obligaciones = this.obligacionesSignal.asReadonly();
  readonly pagos = this.pagosSignal.asReadonly();

  /** Carga el catálogo y los pagos del usuario. */
  async cargar(usuarioId: string): Promise<void> {
    const [obligaciones, pagos] = await Promise.all([
      this.supabase
        .from('obligaciones')
        .select('*')
        .eq('usuario_id', usuarioId)
        .order('id', { ascending: true }),
      this.supabase
        .from('pagos_obligaciones')
        .select('*')
        .eq('usuario_id', usuarioId)
        .order('mes', { ascending: false }),
    ]);
    if (obligaciones.error) throw obligaciones.error;
    if (pagos.error) throw pagos.error;

    let filas = (obligaciones.data ?? []) as ObligacionRow[];
    // Primera vez: siembra las obligaciones iniciales.
    if (filas.length === 0) {
      await this.sembrar(usuarioId);
      const { data: nuevos } = await this.supabase
        .from('obligaciones')
        .select('*')
        .eq('usuario_id', usuarioId)
        .order('id', { ascending: true });
      filas = (nuevos ?? []) as ObligacionRow[];
    }

    this.obligacionesSignal.set(filas.map((r) => this.mapear(r)));
    this.pagosSignal.set(
      ((pagos.data ?? []) as PagoRow[]).map((r) => this.mapearPago(r)),
    );
  }

  /** Inserta las obligaciones iniciales para un usuario nuevo. */
  private async sembrar(usuarioId: string): Promise<void> {
    const filas = OBLIGACIONES_SEMILLA.map((o) => ({
      usuario_id: usuarioId,
      nombre: o.nombre,
      monto: o.monto,
      dia_pago: o.diaPago,
      categoria: o.categoria,
      activa: true,
    }));
    await this.supabase.from('obligaciones').insert(filas);
  }

  /** Crea una obligación en el catálogo. */
  async agregar(input: ObligacionInput): Promise<void> {
    const { data, error } = await this.supabase
      .from('obligaciones')
      .insert({
        usuario_id: input.usuarioId,
        nombre: input.nombre.trim(),
        monto: input.monto,
        dia_pago: input.diaPago,
        categoria: input.categoria,
        activa: input.activa,
      })
      .select()
      .single();
    if (error) throw error;
    this.obligacionesSignal.update((lista) => [
      ...lista,
      this.mapear(data as ObligacionRow),
    ]);
  }

  /** Actualiza una obligación del catálogo. */
  async actualizar(id: number, cambios: Partial<ObligacionInput>): Promise<void> {
    const payload: Record<string, unknown> = {};
    if (cambios.nombre !== undefined) payload['nombre'] = cambios.nombre.trim();
    if (cambios.monto !== undefined) payload['monto'] = cambios.monto;
    if (cambios.diaPago !== undefined) payload['dia_pago'] = cambios.diaPago;
    if (cambios.categoria !== undefined) payload['categoria'] = cambios.categoria;
    if (cambios.activa !== undefined) payload['activa'] = cambios.activa;

    const { error } = await this.supabase.from('obligaciones').update(payload).eq('id', id);
    if (error) throw error;
    this.obligacionesSignal.update((lista) =>
      lista.map((o) => (o.id === id ? { ...o, ...cambios } : o)),
    );
  }

  /** Elimina una obligación y sus pagos (cascade en la DB). */
  async eliminar(id: number): Promise<void> {
    const { error } = await this.supabase.from('obligaciones').delete().eq('id', id);
    if (error) throw error;
    this.obligacionesSignal.update((lista) => lista.filter((o) => o.id !== id));
    this.pagosSignal.update((lista) => lista.filter((p) => p.obligacionId !== id));
  }

  /** ¿Está pagada una obligación en un mes (YYYY-MM)? */
  estaPagada(obligacionId: number, mes: string): boolean {
    return this.pagosSignal().some(
      (p) => p.obligacionId === obligacionId && p.mes === mes,
    );
  }

  /**
   * Marca una obligación como pagada en un mes.
   * Crea un gasto real (fecha = día de pago del mes) y el registro de pago.
   */
  async marcarPagada(obligacion: Obligacion, mes: string): Promise<void> {
    if (this.estaPagada(obligacion.id, mes)) return;

    const fecha = `${mes}-${String(obligacion.diaPago ?? 1).padStart(2, '0')}`;

    const gastoId = await this.gastosService.agregar({
      usuarioId: obligacion.usuarioId,
      monto: obligacion.monto,
      categoria: obligacion.categoria,
      metodoPago: METODO_OBLIGACION,
      fecha,
      descripcion: obligacion.nombre,
    });

    const { data, error } = await this.supabase
      .from('pagos_obligaciones')
      .insert({
        usuario_id: obligacion.usuarioId,
        obligacion_id: obligacion.id,
        mes,
        gasto_id: gastoId,
      })
      .select()
      .single();
    if (error) throw error;
    this.pagosSignal.update((lista) => [
      this.mapearPago(data as PagoRow),
      ...lista,
    ]);
  }

  /** Desmarca una obligación del mes: borra el pago y su gasto asociado. */
  async desmarcar(obligacionId: number, mes: string): Promise<void> {
    const pago = this.pagosSignal().find(
      (p) => p.obligacionId === obligacionId && p.mes === mes,
    );
    if (!pago) return;

    const { error } = await this.supabase
      .from('pagos_obligaciones')
      .delete()
      .eq('id', pago.id);
    if (error) throw error;

    if (pago.gastoId != null) {
      await this.gastosService.eliminar(pago.gastoId);
    }
    this.pagosSignal.update((lista) => lista.filter((p) => p.id !== pago.id));
  }

  /** Obligaciones activas agrupadas por su día de pago. */
  readonly porGrupo = computed(() => {
    const activas = this.obligacionesSignal().filter((o) => o.activa);
    return {
      dia10: activas.filter((o) => o.diaPago === 10),
      dia25: activas.filter((o) => o.diaPago === 25),
      hormigas: activas.filter((o) => o.diaPago === null),
    };
  });

  /** Total pagado en un mes según el catálogo. */
  readonly totalPagadoMes = computed(() => {
    const pagos = this.pagosSignal();
    const obligaciones = this.obligacionesSignal();
    return (mes: string): number =>
      pagos
        .filter((p) => p.mes === mes)
        .reduce((sum, p) => {
          const o = obligaciones.find((ob) => ob.id === p.obligacionId);
          return sum + (o ? o.monto : 0);
        }, 0);
  });

  /** Total mensual esperado (catálogo activo). */
  readonly totalEsperadoMes = computed(() =>
    this.obligacionesSignal()
      .filter((o) => o.activa)
      .reduce((sum, o) => sum + o.monto, 0),
  );

  private mapear(r: ObligacionRow): Obligacion {
    return {
      id: r.id,
      usuarioId: r.usuario_id,
      nombre: r.nombre,
      monto: Number(r.monto),
      diaPago: (r.dia_pago as GrupoObligacion) ?? null,
      categoria: r.categoria,
      activa: r.activa,
    };
  }

  private mapearPago(r: PagoRow): PagoObligacion {
    return {
      id: r.id,
      usuarioId: r.usuario_id,
      obligacionId: r.obligacion_id,
      mes: r.mes,
      gastoId: r.gasto_id ?? 0,
    };
  }
}