import { Injectable } from '@angular/core';
import { CapacitorUpdater } from '@capgo/capacitor-updater';

/**
 * Servicio de actualización OTA (Over-The-Air) para la app Capacitor.
 *
 * Flujo:
 * 1. Lee un manifest.json remoto con { version, url }.
 * 2. Compara con el bundle activo.
 * 3. Si hay una versión nueva, descarga el zip y lo marca como "next".
 *    Se aplicará al reiniciar/poner en segundo plano la app.
 */
@Injectable({ providedIn: 'root' })
export class OtaUpdateService {
  // Reemplaza por tu dominio real (Vercel/GitHub Pages/etc.)
  private readonly manifestUrl = 'https://control-gastos-seven-beige.vercel.app/updates/manifest.json';

  async checkForUpdate(): Promise<void> {
    try {
      const res = await fetch(this.manifestUrl, { cache: 'no-store' });
      if (!res.ok) return;

      const manifest = (await res.json()) as { version?: string; url?: string };
      if (!manifest.version || !manifest.url) return;

      const current = await CapacitorUpdater.current();
      const currentVersion = current?.bundle?.version ?? 'builtin';

      if (manifest.version === currentVersion) return;

      const bundle = await CapacitorUpdater.download({
        url: manifest.url,
        version: manifest.version,
      });

      await CapacitorUpdater.next({ id: bundle.id });
      // Opcional: aplicar inmediatamente (destruye el contexto JS):
      // await CapacitorUpdater.set({ id: bundle.id });
    } catch (error) {
      console.warn('[OTA] Update failed:', error);
    }
  }
}