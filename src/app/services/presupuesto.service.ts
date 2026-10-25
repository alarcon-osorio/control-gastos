import { Injectable, computed, inject, signal } from '@angular/core';
import { AuthService } from './auth.service';
import { GastosService } from './gastos.service';

/**
 * Servicio de presupuesto mensual.
 * Permite definir un límite de gasto mensual (en COP, moneda base) y
 * calcular el progreso y las alertas del mes en curso.
 */
@Injectable({
  providedIn: 'root',
})
export class PresupuestoService {
  private readonly auth = inject(AuthService);
  private readonly gastosService = inject(GastosService);

  /** Presupuesto mensual en COP por usuario (persistido). */
  private readonly presupuestoSignal = signal<number>(this.leerDeStorage());

  readonly presupuesto = this.presupuestoSignal.asReadonly();

  /** Mes actual en formato YYYY-MM. */
  private readonly mesActual = new Date().toISOString().slice(0, 7);

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

  /** Estado de alerta: 'ok' | 'cerca' (>=80%) | 'excedido' (>=100%). */
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
    this.persistir(valido);
  }

  private claveStorage(): string | null {
    const usuario = this.auth.usuario();
    return usuario ? `gastos:presupuesto:${usuario.id}` : null;
  }

  private leerDeStorage(): number {
    const clave = this.claveStorage();
    if (!clave) {
      return 0;
    }
    const data = localStorage.getItem(clave);
    const valor = data ? Number(data) : 0;
    return Number.isFinite(valor) && valor >= 0 ? valor : 0;
  }

  private persistir(monto: number): void {
    const clave = this.claveStorage();
    if (clave) {
      localStorage.setItem(clave, String(monto));
    }
  }
}
