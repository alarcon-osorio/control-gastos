import { Injectable, computed, inject, signal } from '@angular/core';
import { TasasService } from './tasas.service';

export interface Moneda {
  codigo: string;
  simbolo: string;
  nombre: string;
  locale: string;
}

/** Monedas soportadas por la aplicación. */
export const MONEDAS: Moneda[] = [
  { codigo: 'COP', simbolo: '$', nombre: 'Peso colombiano', locale: 'es-CO' },
  { codigo: 'USD', simbolo: 'US$', nombre: 'Dólar estadounidense', locale: 'en-US' },
  { codigo: 'EUR', simbolo: '€', nombre: 'Euro', locale: 'es-ES' },
];

/** Moneda base en la que se almacenan todos los montos. */
export const MONEDA_BASE = 'COP';

/**
 * Servicio de multi-moneda.
 * Gestiona la moneda activa (COP por defecto) y la conversión entre divisas
 * tomando COP como base, usando las tasas del TasasService. El formateo es
 * reactivo y la preferencia de moneda se persiste en localStorage.
 */
@Injectable({
  providedIn: 'root',
})
export class MonedasService {
  private readonly tasas = inject(TasasService);
  private readonly storageKey = 'gastos:moneda';

  /** Código de la moneda activa. */
  private readonly codigoSignal = signal<string>(this.leerDeStorage());

  /** Moneda activa completa. */
  readonly moneda = computed<Moneda>(
    () => MONEDAS.find((m) => m.codigo === this.codigoSignal()) ?? MONEDAS[0],
  );

  /** Lista de monedas disponibles. */
  readonly disponibles = MONEDAS;

  /** Expone el servicio de tasas (para mostrar origen/actualización en la UI). */
  get servicioTasas(): TasasService {
    return this.tasas;
  }

  /** Cambia la moneda activa y la persiste. */
  setMoneda(codigo: string): void {
    if (MONEDAS.some((m) => m.codigo === codigo)) {
      this.codigoSignal.set(codigo);
      localStorage.setItem(this.storageKey, codigo);
    }
  }

  /** Convierte un monto desde una moneda cualquiera a COP (base). */
  aCOP(monto: number, desdeCodigo: string): number {
    const tasa = this.tasas.tasas()[desdeCodigo] ?? 1;
    return monto * tasa;
  }

  /** Convierte un monto en COP (base) a la moneda destino. */
  desdeCOP(montoCOP: number, haciaCodigo: string): number {
    const tasa = this.tasas.tasas()[haciaCodigo] ?? 1;
    return montoCOP / tasa;
  }

  /** Convierte un monto entre dos monedas cualquiera (vía COP). */
  convertir(monto: number, desdeCodigo: string, haciaCodigo: string): number {
    return this.desdeCOP(this.aCOP(monto, desdeCodigo), haciaCodigo);
  }

  /** Da formato a un valor en la moneda indicada. */
  formatearEn(valor: number, codigo: string): string {
    const moneda = MONEDAS.find((m) => m.codigo === codigo) ?? MONEDAS[0];
    return new Intl.NumberFormat(moneda.locale, {
      style: 'currency',
      currency: moneda.codigo,
      minimumFractionDigits: moneda.codigo === 'COP' ? 0 : 2,
      maximumFractionDigits: moneda.codigo === 'COP' ? 0 : 2,
    }).format(valor);
  }

  /** Da formato a un valor usando la moneda activa. */
  formatear(valor: number): string {
    return this.formatearEn(valor, this.moneda().codigo);
  }

  /**
   * Da formato a un monto almacenado en COP, convirtiéndolo primero
   * a la moneda activa.
   */
  formatearDesdeCOP(montoCOP: number): string {
    return this.formatear(this.desdeCOP(montoCOP, this.moneda().codigo));
  }

  /**
   * Devuelve el monto (en COP) formateado en todas las monedas,
   * útil para mostrar equivalencias (EUR, USD, etc.).
   */
  equivalentes(montoCOP: number): { codigo: string; texto: string }[] {
    return MONEDAS.map((m) => ({
      codigo: m.codigo,
      texto: this.formatearEn(this.desdeCOP(montoCOP, m.codigo), m.codigo),
    }));
  }

  private leerDeStorage(): string {
    const guardada = localStorage.getItem(this.storageKey);
    if (guardada && MONEDAS.some((m) => m.codigo === guardada)) {
      return guardada;
    }
    return 'COP';
  }
}

