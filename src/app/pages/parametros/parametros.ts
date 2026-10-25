import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { ParametrosService } from '../../services/parametros.service';
import { Parametro, TipoParametro } from '../../models/parametro';

@Component({
  selector: 'app-parametros',
  imports: [FormsModule],
  templateUrl: './parametros.html',
  styleUrl: './parametros.css',
})
export class Parametros {
  private readonly parametrosService = inject(ParametrosService);
  private readonly auth = inject(AuthService);

  private readonly usuarioId = this.auth.usuario()!.id;

  /** Tipo de parámetro visible. */
  readonly tipo = signal<TipoParametro>('categoria');

  /** Campo para nuevo valor. */
  readonly nuevo = signal('');
  /** id del parámetro en edición. */
  readonly editandoId = signal<number | null>(null);
  /** Valor mientras se edita. */
  readonly editandoValor = signal('');

  readonly mensaje = signal('');
  readonly error = signal('');
  readonly cargando = signal(true);
  readonly guardando = signal(false);

  /** Lista reactiva filtrada por el tipo activo. */
  readonly lista = computed(() =>
    this.parametrosService
      .parametros()
      .filter((p) => p.tipo === this.tipo()),
  );

  constructor() {
    void this.parametrosService
      .cargar(this.usuarioId)
      .finally(() => this.cargando.set(false));
  }

  cambiarTipo(tipo: TipoParametro): void {
    this.tipo.set(tipo);
    this.cancelarEdicion();
    this.error.set('');
    this.mensaje.set('');
  }

  async agregar(): Promise<void> {
    this.error.set('');
    this.mensaje.set('');
    this.guardando.set(true);
    try {
      const res = await this.parametrosService.agregar({
        usuarioId: this.usuarioId,
        tipo: this.tipo(),
        nombre: this.nuevo(),
      });
      if (!res.ok) {
        this.error.set(res.mensaje);
        return;
      }
      this.nuevo.set('');
      this.mensaje.set(res.mensaje);
    } finally {
      this.guardando.set(false);
    }
  }

  empezarEdicion(param: Parametro): void {
    this.editandoId.set(param.id);
    this.editandoValor.set(param.nombre);
    this.error.set('');
    this.mensaje.set('');
  }

  async guardarEdicion(): Promise<void> {
    const id = this.editandoId();
    if (id === null) {
      return;
    }
    this.guardando.set(true);
    try {
      const res = await this.parametrosService.actualizar(
        id,
        this.editandoValor(),
      );
      if (!res.ok) {
        this.error.set(res.mensaje);
        return;
      }
      this.mensaje.set(res.mensaje);
      this.cancelarEdicion();
    } finally {
      this.guardando.set(false);
    }
  }

  async eliminar(param: Parametro): Promise<void> {
    await this.parametrosService.eliminar(param.id);
    this.mensaje.set('Eliminado correctamente.');
  }

  cancelarEdicion(): void {
    this.editandoId.set(null);
    this.editandoValor.set('');
  }
}
