import {
  Component,
  ElementRef,
  HostBinding,
  HostListener,
  computed,
  effect,
  input,
  model,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';

/**
 * Componente de selección múltiple reutilizable.
 * Muestra un desplegable con checkboxes y permite seleccionar
 * varias opciones a la vez. Se integra con signals mediante
 * two-way binding: [(value)].
 */
@Component({
  selector: 'app-multi-select',
  imports: [FormsModule],
  templateUrl: './multi-select.html',
  styleUrl: './multi-select.css',
})
export class MultiSelect {
  /** Lista de opciones disponibles para elegir. */
  readonly opciones = input.required<string[]>();

  /** Texto que se muestra cuando no hay nada seleccionado. */
  readonly placeholder = input<string>('Selecciona...');

  /** Id del elemento que actúa como etiqueta accesible del control. */
  readonly ariaLabelledBy = input<string>();

  /** Expone aria-labelledby en el host para accesibilidad. */
  @HostBinding('attr.aria-labelledby')
  get hostAriaLabelledBy(): string | null {
    return this.ariaLabelledBy() ?? null;
  }

  /** Valor seleccionado (two-way binding con signals). */
  readonly value = model<string[]>([]);

  /** Controla si el panel desplegable está abierto. */
  private readonly abierto = signal(false);

  /** Etiqueta que resume la selección actual. */
  readonly etiqueta = computed(() => {
    const seleccion = this.value();
    if (seleccion.length === 0) {
      return this.placeholder();
    }
    return seleccion.join(', ');
  });

  constructor(private readonly elementRef: ElementRef<HTMLElement>) {
    // Si cambian las opciones, limpiamos selecciones que ya no existan.
    effect(() => {
      const opciones = this.opciones();
      const actual = this.value();
      const filtrado = actual.filter((v) => opciones.includes(v));
      if (filtrado.length !== actual.length) {
        this.value.set(filtrado);
      }
    });
  }

  /** Alterna la visibilidad del panel. */
  togglePanel(event: Event): void {
    event.stopPropagation();
    this.abierto.update((v) => !v);
  }

  /** Indica si una opción está seleccionada. */
  estaSeleccionada(opcion: string): boolean {
    return this.value().includes(opcion);
  }

  /** Agrega o quita una opción de la selección. */
  toggleOpcion(opcion: string): void {
    const actual = this.value();
    if (actual.includes(opcion)) {
      this.value.set(actual.filter((v) => v !== opcion));
    } else {
      this.value.set([...actual, opcion]);
    }
  }

  /** Elimina una opción concreta desde la etiqueta resumen. */
  eliminar(opcion: string, event: Event): void {
    event.stopPropagation();
    this.value.set(this.value().filter((v) => v !== opcion));
  }

  /** Cierra el panel si se hace clic fuera del componente. */
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: Event): void {
    if (!this.elementRef.nativeElement.contains(event.target as Node)) {
      this.abierto.set(false);
    }
  }
}
