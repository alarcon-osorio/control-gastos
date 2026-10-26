import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { GastosService } from '../../services/gastos.service';
import { ParametrosService } from '../../services/parametros.service';
import { MonedasService } from '../../services/monedas.service';
import { Gasto } from '../../models/gasto';

@Component({
  selector: 'app-gastos',
  imports: [RouterLink, FormsModule],
  templateUrl: './gastos.html',
  styleUrl: './gastos.css',
})
export class Gastos {
  private readonly auth = inject(AuthService);
  private readonly gastosService = inject(GastosService);
  private readonly parametros = inject(ParametrosService);
  readonly monedas = inject(MonedasService);

  private readonly usuarioId = this.auth.usuario()!.id;

  /** Filtros. */
  readonly filtroCategoria = signal('');
  readonly filtroMetodo = signal('');
  readonly filtroMes = signal('');
  /** Alias para compatibilidad con distintos nombres de filtro por fecha/mes. */
  readonly filtroFecha = this.filtroMes;
  readonly filtroMesAnio = this.filtroMes;
  readonly mesFiltro = this.filtroMes;
  readonly fechaFiltro = this.filtroMes;

  /** Listas reactivas (se llenan al cargar los parámetros). */
  readonly categorias = computed(() =>
    this.parametros.nombresPorTipo('categoria'),
  );
  readonly metodos = computed(() =>
    this.parametros.nombresPorTipo('metodoPago'),
  );

  /** Indica si los datos aún se están cargando. */
  readonly cargando = signal(true);

  constructor() {
    // Cargamos gastos y parámetros del usuario autenticado.
    void Promise.all([
      this.gastosService.cargar(this.usuarioId),
      this.parametros.cargar(this.usuarioId),
    ]).finally(() => this.cargando.set(false));
  }

  /** Todos los gastos del usuario. */
  private readonly todos = computed(() =>
    this.gastosService.gastosPorUsuario(this.usuarioId),
  );

  /** Meses (YYYY-MM) disponibles en los gastos del usuario. */
  readonly mesesDisponibles = computed(() => {
    const meses = new Set(this.todos().map((g) => g.fecha.slice(0, 7)));
    return [...meses].sort().reverse();
  });
  /** Alias para compatibilidad. */
  readonly meses = this.mesesDisponibles;
  readonly mesesFiltro = this.mesesDisponibles;

  /** Gastos filtrados. */
  readonly gastosFiltrados = computed(() => {
    const cat = this.filtroCategoria();
    const met = this.filtroMetodo();
    const mes = this.filtroMes().trim().toLowerCase();
    return this.todos().filter((g) => {
      if (cat && g.categoria !== cat) return false;
      if (met && g.metodoPago !== met) return false;
      if (mes) {
        const fechaMes = g.fecha.slice(0, 7).toLowerCase();
        const mesNum = g.fecha.slice(5, 7);
        if (/^\d{4}$/.test(mes)) {
          if (!g.fecha.startsWith(mes)) return false;
        } else if (mes.includes('-')) {
          const [anio, mesSel] = mes.split('-');
          const normalizado = `${anio}-${String(Number(mesSel)).padStart(2, '0')}`;
          if (fechaMes !== normalizado) return false;
        } else if (/^\d{1,2}$/.test(mes)) {
          if (Number(mesNum) !== Number(mes)) return false;
        } else {
          const nombres = [
            'enero',
            'febrero',
            'marzo',
            'abril',
            'mayo',
            'junio',
            'julio',
            'agosto',
            'septiembre',
            'octubre',
            'noviembre',
            'diciembre',
          ];
          const idx = nombres.findIndex(
            (n) => n === mes || n.startsWith(mes),
          );
          if (idx < 0 || Number(mesNum) !== idx + 1) return false;
        }
      }
      return true;
    });
  });

  readonly totalFiltrado = computed(() =>
    this.gastosFiltrados().reduce((sum, g) => sum + Number(g.monto), 0),
  );

  readonly hayFiltros = computed(
    () =>
      this.filtroCategoria() !== '' ||
      this.filtroMetodo() !== '' ||
      this.filtroMes() !== '',
  );

  async eliminar(gasto: Gasto): Promise<void> {
    await this.gastosService.eliminar(gasto.id);
  }

  limpiarFiltros(): void {
    this.filtroCategoria.set('');
    this.filtroMetodo.set('');
    this.filtroMes.set('');
  }

  formatearMoneda(montoCOP: number): string {
    return this.monedas.formatearDesdeCOP(montoCOP);
  }
}
