import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { GastosService } from '../../services/gastos.service';
import { MonedasService, MONEDA_BASE } from '../../services/monedas.service';
import { PresupuestoService } from '../../services/presupuesto.service';
import { HorizontalScrollDirective } from '../../directives/horizontal-scroll.directive';

@Component({
  selector: 'app-dashboard',
  imports: [RouterLink, HorizontalScrollDirective],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css',
})
export class Dashboard {
  private readonly auth = inject(AuthService);
  private readonly gastosService = inject(GastosService);
  private readonly presupuesto = inject(PresupuestoService);
  readonly monedas = inject(MonedasService);

  /** Moneda base en la que se almacena el presupuesto. */
  readonly monedaBase = MONEDA_BASE;

  /** Usuario actual (se asume existente por el guard). */
  private readonly usuarioId = this.auth.usuario()!.id;

  readonly nombreUsuario = this.auth.usuario()!.nombre;

  constructor() {
    // Cargamos los datos del usuario autenticado al entrar.
    const usuario = this.auth.usuario();
    if (usuario) {
      void this.gastosService.cargar(usuario.id);
    }
  }

  /** Total gastado por el usuario. */
  readonly total = this.gastosService.totalUsuario(this.usuarioId);

  /** Gastos del usuario (los 5 más recientes). */
  readonly gastos = computed(() =>
    this.gastosService.gastosPorUsuario(this.usuarioId),
  );

  readonly gastosRecientes = computed(() => this.gastos().slice(0, 5));

  readonly cantidadGastos = computed(() => this.gastos().length);

  /** Promedio por gasto. */
  readonly promedio = computed(() => {
    const total = this.total();
    const cantidad = this.cantidadGastos();
    return cantidad > 0 ? total / cantidad : 0;
  });

  /** Desglose por categoría como lista ordenada. */
  readonly porCategoria = computed(() => {
    const mapa = this.gastosService.totalPorCategoria(this.usuarioId)();
    return [...mapa.entries()]
      .map(([categoria, total]) => ({ categoria, total }))
      .sort((a, b) => b.total - a.total);
  });

  /** Gastos agrupados por mes (YYYY-MM), ordenados cronológicamente. */
  readonly porMes = computed(() => {
    const mapa = new Map<string, number>();
    for (const g of this.gastosService.gastosPorUsuario(this.usuarioId)) {
      const mes = g.fecha.slice(0, 7); // YYYY-MM
      mapa.set(mes, (mapa.get(mes) ?? 0) + Number(g.monto));
    }
    return [...mapa.entries()]
      .map(([mes, total]) => ({ mes, total }))
      .sort((a, b) => (a.mes < b.mes ? -1 : 1));
  });

  /** Mes con mayor gasto (para escalar las barras). */
  readonly maxMes = computed(() =>
    this.porMes().reduce((max, m) => Math.max(max, m.total), 0),
  );

  /** Convierte "2026-03" en "mar 2026". */
  etiquetaMes(mes: string): string {
    const [anio, m] = mes.split('-');
    const nombres = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    const idx = Number(m) - 1;
    return `${nombres[idx] ?? m} ${anio}`;
  }

  /** Altura relativa de la barra de un mes (0-100%). */
  alturaMes(total: number): number {
    const max = this.maxMes();
    return max > 0 ? Math.max(4, Math.round((total / max) * 100)) : 0;
  }

  /** Porcentaje de cada categoría respecto al total. */
  porcentaje(total: number): number {
    const totalGeneral = this.total();
    return totalGeneral > 0 ? Math.round((total / totalGeneral) * 100) : 0;
  }

  /** Da formato a un monto almacenado en COP, en la moneda activa. */
  formatearMoneda(montoCOP: number): string {
    return this.monedas.formatearDesdeCOP(montoCOP);
  }

  /** Equivalencias del total en las tres monedas. */
  get equivalencias(): { codigo: string; texto: string }[] {
    return this.monedas.equivalentes(this.total());
  }

  /** Estado de alerta del presupuesto: 'sin-presupuesto' | 'ok' | 'cerca' | 'excedido'. */
  readonly estadoPresupuesto = this.presupuesto.estado;

  /** Progreso en porcentaje (0-100). */
  readonly progresoPresupuesto = computed(() => Math.min(100, this.presupuesto.porcentaje()));

  /** Porcentaje de presupuesto consumido. */
  readonly porcentajePresupuesto = computed(() =>
    this.estadoPresupuesto() === 'sin-presupuesto' ? '—' : `${this.presupuesto.porcentaje()}%`,
  );

  /** Configuración del presupuesto del mes actual. */
  readonly presupuestoConfig = computed(() => {
    const presupuesto = this.presupuesto.presupuesto();
    const mes = new Date().toLocaleDateString('es-ES', { month: 'long', year: 'numeric' });
    return {
      activo: presupuesto > 0,
      mes,
      valor: presupuesto,
      restante: this.presupuesto.restante(),
    };
  });

  /** Presupuesto diario (prorrateo lineal sobre 30 días). */
  readonly presupuestoDiario = computed(() => {
    const p = this.presupuesto.presupuesto();
    return p > 0 ? Math.round(p / 30) : 0;
  });

  /** Acumulado esperado al día 10 (primera quincena). */
  readonly presupuestoDia10 = computed(() => {
    const p = this.presupuesto.presupuesto();
    return p > 0 ? Math.round((p * 10) / 30) : 0;
  });

  /** Acumulado esperado al día 25. */
  readonly presupuestoDia25 = computed(() => {
    const p = this.presupuesto.presupuesto();
    return p > 0 ? Math.round((p * 25) / 30) : 0;
  });

  /** Modal de presupuesto abierto desde el dashboard. */
  readonly presupuestoModalAbierto = signal(false);
  readonly valorPresupuestoInput = signal(String(this.presupuesto.presupuesto()));
  /** Mensaje temporal de confirmación tras aplicar el presupuesto. */
  readonly mensajePresupuesto = signal('');

  /** Mes del presupuesto en formato "marzo 2026". */
  readonly mesPresupuesto = computed(() =>
    new Date().toLocaleDateString('es-ES', { month: 'long', year: 'numeric' }),
  );

  /** Estado de alerta actual del presupuesto. */
  readonly estadoPresupuestoModal = computed(() => this.presupuesto.estado());

  /** Aplica el presupuesto desde el modal. */
  aplicarPresupuesto(event?: Event, inputEl?: HTMLInputElement): void {
    event?.preventDefault();
    const raw = (inputEl?.value ?? this.valorPresupuestoInput()).trim();
    if (!raw) {
      return;
    }
    const monto = Number(raw.replace(/\D/g, ''));
    if (!Number.isFinite(monto) || monto < 0) {
      return;
    }
    this.presupuesto.setPresupuesto(monto);
    this.valorPresupuestoInput.set(monto > 0 ? String(monto) : '');
    this.mensajePresupuesto.set(
      monto > 0 ? 'Presupuesto guardado correctamente.' : 'Presupuesto eliminado.',
    );
    this.cerrarPresupuesto();
    setTimeout(() => this.mensajePresupuesto.set(''), 3000);
  }

  /** Reinicia/quita el presupuesto. */
  reiniciarPresupuesto(): void {
    this.presupuesto.setPresupuesto(0);
    this.valorPresupuestoInput.set('');
    this.mensajePresupuesto.set('Presupuesto eliminado.');
    this.cerrarPresupuesto();
    setTimeout(() => this.mensajePresupuesto.set(''), 3000);
  }

  /** Abre el modal de presupuesto. */
  abrirPresupuesto(): void {
    const actual = this.presupuesto.presupuesto();
    this.valorPresupuestoInput.set(actual > 0 ? String(actual) : '');
    this.presupuestoModalAbierto.set(true);
  }

  /** Cierra el modal de presupuesto. */
  cerrarPresupuesto(): void {
    this.presupuestoModalAbierto.set(false);
  }
}
