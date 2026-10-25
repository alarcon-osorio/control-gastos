import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

/** Tasas de respaldo si la API falla (valores de referencia). */
export const TASAS_FALLBACK: Record<string, number> = {
  COP: 1,
  USD: 4000,
  EUR: 4300,
};

/** Endpoint público de divisas (base USD), no requiere API key. */
const API_URL = 'https://open.er-api.com/v6/latest/USD';

/**
 * Servicio de tasas de cambio.
 * Obtiene las tasas reales desde una API pública y las expone como signals.
 * Si la API no está disponible, usa tasas de referencia (fallback).
 */
@Injectable({
  providedIn: 'root',
})
export class TasasService {
  private readonly http = inject(HttpClient);

  /** Cuántos COP vale 1 unidad de cada moneda. */
  private readonly tasasSignal = signal<Record<string, number>>({
    ...TASAS_FALLBACK,
  });

  readonly tasas = this.tasasSignal.asReadonly();

  /** Indica si las tasas provienen de la API (reales) o del fallback. */
  readonly sonReales = signal(false);

  readonly cargando = signal(false);
  readonly error = signal('');

  /** Fecha de la última actualización (para mostrar en la UI). */
  readonly ultimaActualizacion = signal<Date | null>(null);

  /** Mensaje legible del origen de las tasas. */
  readonly origen = computed(() =>
    this.sonReales() ? 'Tasas actualizadas en línea' : 'Tasas de referencia',
  );

  constructor() {
    // Cargamos las tasas al iniciar el servicio.
    void this.actualizar();
  }

  /** Consulta la API y actualiza las tasas. */
  async actualizar(): Promise<void> {
    this.cargando.set(true);
    this.error.set('');
    try {
      const data = await firstValueFrom(
        this.http.get<{ rates?: Record<string, number> }>(API_URL),
      );
      const rates = data?.rates;
      if (rates && rates['COP'] && rates['EUR']) {
        // Base USD: 1 USD = rates.COP COP; 1 EUR = rates.EUR USD.
        this.tasasSignal.set({
          COP: 1,
          USD: rates['COP'],
          EUR: rates['EUR'] * rates['COP'],
        });
        this.sonReales.set(true);
        this.ultimaActualizacion.set(new Date());
      } else {
        this.usarFallback();
      }
    } catch {
      this.usarFallback();
      this.error.set('No se pudieron obtener tasas en línea. Usando referencia.');
    } finally {
      this.cargando.set(false);
    }
  }

  private usarFallback(): void {
    this.tasasSignal.set({ ...TASAS_FALLBACK });
    this.sonReales.set(false);
  }
}
