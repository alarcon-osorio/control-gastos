import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { MonedasService, MONEDA_BASE } from '../../services/monedas.service';
import { ParametrosService } from '../../services/parametros.service';
import { ObligacionesService } from '../../services/obligaciones.service';
import { GrupoObligacion, Obligacion } from '../../models/obligacion';

/** Devuelve el mes actual en YYYY-MM. */
function mesActual(): string {
  return new Date().toISOString().slice(0, 7);
}

@Component({
  selector: 'app-obligaciones',
  imports: [FormsModule],
  templateUrl: './obligaciones.html',
  styleUrl: './obligaciones.css',
})
export class Obligaciones {
  readonly obligacionesService = inject(ObligacionesService);
  readonly monedas = inject(MonedasService);
  private readonly auth = inject(AuthService);
  private readonly parametrosService = inject(ParametrosService);

  private readonly usuarioId = this.auth.usuario()!.id;

  readonly monedaBase = MONEDA_BASE;

  /** Mes visible en el checklist (YYYY-MM). */
  readonly mes = signal(mesActual());

  readonly cargando = signal(true);
  readonly error = signal('');

  // --- Formulario de nueva obligación ---
  readonly formAbierto = signal(false);
  readonly nuevoNombre = signal('');
  readonly nuevoMonto = signal('');
  readonly nuevoGrupo = signal<GrupoObligacion>(10);
  readonly nuevaCategoria = signal('Otros');

  /** Categorías disponibles (para el selector del formulario). */
  readonly categorias = computed(() =>
    this.parametrosService.nombresPorTipo('categoria'),
  );

  constructor() {
    Promise.all([
      this.obligacionesService.cargar(this.usuarioId),
      this.parametrosService.cargar(this.usuarioId),
    ])
      .catch((e) => this.error.set(this.mensajeError(e)))
      .finally(() => this.cargando.set(false));
  }

  // --- Navegación de mes ---
  cambiarMes(pasos: number): void {
    const [anio, m] = this.mes().split('-').map(Number);
    const fecha = new Date(anio, m - 1 + pasos, 1);
    this.mes.set(`${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}`);
  }

  get mesLegible(): string {
    const [anio, m] = this.mes().split('-').map(Number);
    return new Date(anio, m - 1, 1).toLocaleDateString('es-CO', {
      month: 'long',
      year: 'numeric',
    });
  }

  // --- Checklist ---
  pagadas = computed(() => {
    // Fuerza la reactividad al cambiar de mes.
    const mes = this.mes();
    return (obligacionId: number) =>
      this.obligacionesService.estaPagada(obligacionId, mes);
  });

  totalPagado = computed(() => this.obligacionesService.totalPagadoMes()(this.mes()));

  totalEsperado = computed(() => this.obligacionesService.totalEsperadoMes());

  progreso = computed(() => {
    const esperado = this.totalEsperado();
    return esperado > 0 ? Math.min(100, Math.round((this.totalPagado() / esperado) * 100)) : 0;
  });

  async alternar(obligacion: Obligacion): Promise<void> {
    this.error.set('');
    try {
      if (this.obligacionesService.estaPagada(obligacion.id, this.mes())) {
        await this.obligacionesService.desmarcar(obligacion.id, this.mes());
      } else {
        await this.obligacionesService.marcarPagada(obligacion, this.mes());
      }
    } catch (e) {
      this.error.set(this.mensajeError(e));
    }
  }

  // --- Alta de obligaciones ---
  abrirFormulario(): void {
    this.formAbierto.set(true);
    this.error.set('');
  }

  cerrarFormulario(): void {
    this.formAbierto.set(false);
    this.limpiarFormulario();
  }

  private limpiarFormulario(): void {
    this.nuevoNombre.set('');
    this.nuevoMonto.set('');
    this.nuevoGrupo.set(10);
    this.nuevaCategoria.set('Otros');
  }

  soloDigitos(valor: string): string {
    return valor.replace(/\D/g, '');
  }

  async guardarNueva(): Promise<void> {
    this.error.set('');
    const nombre = this.nuevoNombre().trim();
    const monto = Number(this.soloDigitos(this.nuevoMonto()));
    if (!nombre) {
      this.error.set('Escribe el nombre de la obligación.');
      return;
    }
    if (!Number.isFinite(monto) || monto <= 0) {
      this.error.set('Escribe un monto válido.');
      return;
    }
    try {
      await this.obligacionesService.agregar({
        usuarioId: this.usuarioId,
        nombre,
        monto,
        diaPago: this.nuevoGrupo(),
        categoria: this.nuevaCategoria(),
        activa: true,
      });
      this.cerrarFormulario();
    } catch (e) {
      this.error.set(this.mensajeError(e));
    }
  }

  async eliminar(obligacion: Obligacion): Promise<void> {
    this.error.set('');
    try {
      await this.obligacionesService.eliminar(obligacion.id);
    } catch (e) {
      this.error.set(this.mensajeError(e));
    }
  }

  formatear(monto: number): string {
    return this.monedas.formatearDesdeCOP(monto);
  }

  private mensajeError(e: unknown): string {
    return e instanceof Error ? e.message : 'Ocurrió un error. Intenta de nuevo.';
  }
}