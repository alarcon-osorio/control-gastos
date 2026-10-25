import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { GastosService } from '../../services/gastos.service';
import { ParametrosService } from '../../services/parametros.service';
import { MonedasService } from '../../services/monedas.service';

@Component({
  selector: 'app-gasto-form',
  imports: [FormsModule, RouterLink],
  templateUrl: './gasto-form.html',
  styleUrl: './gasto-form.css',
})
export class GastoForm {
  private readonly auth = inject(AuthService);
  private readonly gastosService = inject(GastosService);
  private readonly parametros = inject(ParametrosService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  readonly monedas = inject(MonedasService);

  readonly categorias = this.parametros.nombresPorTipo('categoria');
  readonly metodos = this.parametros.nombresPorTipo('metodoPago');

  /** id del gasto que se edita (null si es nuevo). */
  private editandoId: number | null = null;
  readonly esEdicion = signal(false);

  /** Monto que ve el usuario, expresado en la moneda activa. */
  monto = signal<number | null>(null);
  categoria = signal('');
  metodoPago = signal('');
  fecha = signal(this.hoyISO());
  descripcion = signal('');

  readonly error = signal('');

  constructor() {
    const idParam = this.route.snapshot.paramMap.get('id');
    const usuario = this.auth.usuario();
    if (idParam && usuario) {
      const id = Number(idParam);
      // Cargamos los gastos del usuario y luego localizamos el que editamos.
      void this.gastosService.cargar(usuario.id).then(() => {
        const gasto = this.gastosService
          .gastos()
          .find((g) => g.id === id);
        if (gasto) {
          this.editandoId = id;
          this.esEdicion.set(true);
          // El monto se guarda en COP; lo mostramos en la moneda activa.
          this.monto.set(
            this.redondear(
              this.monedas.desdeCOP(gasto.monto, this.monedas.moneda().codigo),
            ),
          );
          this.categoria.set(gasto.categoria);
          this.metodoPago.set(gasto.metodoPago);
          this.fecha.set(gasto.fecha);
          this.descripcion.set(gasto.descripcion);
        }
      });
    }
  }

  /** Equivalencias del monto escrito, para previsualizar la conversión. */
  get previsualizacion(): { codigo: string; texto: string }[] {
    const valor = this.monto();
    if (valor === null || Number.isNaN(valor) || valor <= 0) {
      return [];
    }
    // Convertimos lo escrito (moneda activa) a COP y de ahí a las demás.
    const enCOP = this.monedas.aCOP(valor, this.monedas.moneda().codigo);
    return this.monedas.equivalentes(enCOP);
  }

  readonly guardando = signal(false);

  async guardar(): Promise<void> {
    const montoActivo = this.monto();
    const categoria = this.categoria();
    const metodoPago = this.metodoPago();

    if (montoActivo === null || Number.isNaN(montoActivo) || montoActivo <= 0) {
      this.error.set('Introduce un monto mayor que 0.');
      return;
    }
    if (!categoria) {
      this.error.set('Selecciona una categoría.');
      return;
    }
    if (!metodoPago) {
      this.error.set('Selecciona un método de pago.');
      return;
    }
    if (!this.fecha()) {
      this.error.set('Indica la fecha del gasto.');
      return;
    }

    // Convertimos el monto de la moneda activa a COP (base) antes de guardar.
    const montoCOP = this.redondear(
      this.monedas.aCOP(montoActivo, this.monedas.moneda().codigo),
    );

    const datos = {
      monto: montoCOP,
      categoria,
      metodoPago,
      fecha: this.fecha(),
      descripcion: this.descripcion().trim(),
    };

    this.guardando.set(true);
    this.error.set('');
    try {
      if (this.editandoId !== null) {
        await this.gastosService.actualizar(this.editandoId, datos);
      } else {
        await this.gastosService.agregar({
          usuarioId: this.auth.usuario()!.id,
          ...datos,
        });
      }
      this.router.navigate(['/gastos']);
    } catch {
      this.error.set('No se pudo guardar el gasto. Inténtalo de nuevo.');
    } finally {
      this.guardando.set(false);
    }
  }

  private redondear(valor: number): number {
    return Math.round(valor * 100) / 100;
  }

  private hoyISO(): string {
    return new Date().toISOString().slice(0, 10);
  }
}
