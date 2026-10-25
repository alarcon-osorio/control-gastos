import { Injectable, computed, effect, inject, signal } from '@angular/core';
import { SUPABASE } from './supabase.client';
import { AuthService } from './auth.service';
import { GastosService } from './gastos.service';

/**
 * Servicio de presupuesto mensual.
 * Persiste en Supabase (tabla `presupuestos`) con respaldo en localStorage,
 * de modo que funcione aunque la tabla aún no exista en la nube.
 */
@Injectable({
  providedIn: 'root',
})
export class PresupuestoService {
  private readonly auth = inject(AuthService);
  private readonly gastosService = inject(GastosService);
  private readonly supabase = inject(SUPABASE);

  /** Presupuesto mensual en COP por usuario (persistido). */
  private readonly presupuestoSignal = signal<number>(0);

  readonly presupuesto = this.presupuestoSignal.asReadonly();

  /** Mes actual en formato YYYY-MM. */
  private readonly mesActual = new Date().toISOString().slice(0, 7);

  constructor() {
    // Recarga el presupuesto cuando cambia el usuario autenticado.
    effect(() => {
      const usuario = this.auth.usuario();
      if (usuario) {
        void this.cargar(usuario.id);
      } else {
        this.presupuestoSignal.set(0);
      }
    });
  }

  /** Gasto acumulado del mes actual en COP. */
  readonly gastoDelMes = computed(() => {
    const usuario = this.auth.usuario();
    if (!usuario) {
      return 0;
    }
    return this.gastosService
      .gastosPorUsuario(usuario.id)
      .filter((g) => g.fecha.slice(0, 7) === this.mesActual)
      .reduce((sum, g) => sum + Number(g.monto), 0);
  });

  /** Porcentaje consumido del presupuesto (0-100+). */
  readonly porcentaje = computed(() => {
    const p = this.presupuestoSignal();
    return p > 0 ? Math.round((this.gastoDelMes() / p) * 100) : 0;
  });

  /** Restante del presupuesto en COP (0 si ya se excedió). */
  readonly restante = computed(() =>
    Math.max(0, this.presupuestoSignal() - this.gastoDelMes()),
  );

  /** Estado de alerta. */
  readonly estado = computed<'sin-presupuesto' | 'ok' | 'cerca' | 'excedido'>(() => {
    if (this.presupuestoSignal() <= 0) {
      return 'sin-presupuesto';
    }
    const pct = this.porcentaje();
    if (pct >= 100) {
      return 'excedido';
    }
    if (pct >= 80) {
      return 'cerca';
    }
    return 'ok';
  });

  /** Define el presupuesto mensual (en COP). */
  setPresupuesto(monto: number): void {
    const valido = Number.isFinite(monto) && monto >= 0 ? monto : 0;
    this.presupuestoSignal.set(valido);
    this.persistirLocal(valido);
    const usuario = this.auth.usuario();
    if (usuario) {
      void this.persistirRemoto(usuario.id, valido);
    }
  }

  /** Carga el presupuesto (Supabase con respaldo localStorage). */
  private async cargar(usuarioId: string): Promise<void> {
    try {
      const { data, error } = await this.supabase
        .from('presupuestos')
        .select('monto')
        .eq('usuario_id', usuarioId)
        .maybeSingle();
      if (!error && data) {
        const monto = Number((data as { monto: number }).monto);
        if (Number.isFinite(monto) && monto >= 0) {
          this.presupuestoSignal.set(monto);
          this.persistirLocal(monto, usuarioId);
          return;
        }
      }
    } catch {
      // Tabla inexistente o sin red: seguimos con localStorage.
    }
    this.presupuestoSignal.set(this.leerDeStorage(usuarioId));
  }

  private async persistirRemoto(usuarioId: string, monto: number): Promise<void> {
    try {
      await this.supabase.from('presupuestos').upsert(
        {
          usuario_id: usuarioId,
          monto,
          actualizado_en: new Date().toISOString(),
        },
        { onConflict: 'usuario_id' },
      );
    } catch {
      // Silencioso: localStorage ya guardó el valor.
    }
  }

  private claveStorage(usuarioId?: string): string | null {
    const id = usuarioId ?? this.auth.usuario()?.id;
    return id ? `gastos:presupuesto:${id}` : null;
  }

  private leerDeStorage(usuarioId?: string): number {
    const clave = this.claveStorage(usuarioId);
    if (!clave) {
      return 0;
    }
    const data = localStorage.getItem(clave);
    const valor = data ? Number(data) : 0;
    return Number.isFinite(valor) && valor >= 0 ? valor : 0;
  }

  private persistirLocal(monto: number, usuarioId?: string): void {
    const clave = this.claveStorage(usuarioId);
    if (clave) {
      localStorage.setItem(clave, String(monto));
    }
  }
}
