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

  /** Gastos filtrados. */
  readonly gastosFiltrados = computed(() => {
    const cat = this.filtroCategoria();
    const met = this.filtroMetodo();
    return this.todos().filter(
      (g) =>
        (!cat || g.categoria === cat) && (!met || g.metodoPago === met),
    );
  });

  readonly totalFiltrado = computed(() =>
    this.gastosFiltrados().reduce((sum, g) => sum + Number(g.monto), 0),
  );

  readonly hayFiltros = computed(
    () => this.filtroCategoria() !== '' || this.filtroMetodo() !== '',
  );

  async eliminar(gasto: Gasto): Promise<void> {
    await this.gastosService.eliminar(gasto.id);
  }

  limpiarFiltros(): void {
    this.filtroCategoria.set('');
    this.filtroMetodo.set('');
  }

  formatearMoneda(montoCOP: number): string {
    return this.monedas.formatearDesdeCOP(montoCOP);
  }
}
