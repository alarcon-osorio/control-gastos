import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PresupuestoService } from '../../services/presupuesto.service';
import { MonedasService, MONEDA_BASE } from '../../services/monedas.service';

@Component({
  selector: 'app-presupuesto-config',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './presupuesto-config.html',
  styleUrl: './presupuesto-config.css',
})
export class PresupuestoConfigComponent {
  readonly presupuestoService = inject(PresupuestoService);
  readonly monedas = inject(MonedasService);

  /** Moneda base en la que se guarda el presupuesto. */
  readonly monedaBase = MONEDA_BASE;

  readonly mes = new Date().toLocaleDateString('es-ES', { month: 'long', year: 'numeric' });

  /** Estado de alerta del presupuesto (expuesto para la plantilla). */
  readonly estadoPresupuesto = this.presupuestoService.estado;

  /** Signal para evitar dobles cambios y que el formulario reaccione. */
  readonly valorInput = signal(String(this.presupuestoService.presupuesto()));

  /** Limpia espacios y pasa solo números positivos. */
  limpiarValor(valor: string): string {
    return valor.replace(/\D/g, '');
  }

  /** Aplica el presupuesto. */
  aplicar(): void {
    const monto = Number(this.limpiarValor(this.valorInput()));
    this.presupuestoService.setPresupuesto(monto);
    this.valorInput.set(String(monto));
  }

  /** Resetea el presupuesto. */
  limpiar(): void {
    this.presupuestoService.setPresupuesto(0);
    this.valorInput.set('0');
  }

  /** Maneja el Enter: aplica sin clic. */
  onKeydown($event: KeyboardEvent): void {
    if ($event.key === 'Enter') {
      this.aplicar();
    }
  }
}

