import {
  APP_INITIALIZER,
  ApplicationConfig,
  Provider,
  provideBrowserGlobalErrorListeners,
  provideZoneChangeDetection,
} from '@angular/core';
import { provideRouter, withInMemoryScrolling } from '@angular/router';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { routes } from './app.routes';
import { AuthService } from './services/auth.service';
import { OtaUpdateService } from './services/ota-update.service';

/** Espera a que Supabase resuelva la sesión antes de renderizar la app. */
function initAuth(auth: AuthService): () => Promise<void> {
  return () => auth.listo();
}

/** Lanza la comprobación OTA en segundo plano (no bloquea el arranque). */
function initOta(ota: OtaUpdateService): () => void {
  return () => {
    void ota.checkForUpdate();
  };
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes, withInMemoryScrolling({ anchorScrolling: 'enabled' })),
    provideHttpClient(withFetch()),
    {
      provide: APP_INITIALIZER,
      useFactory: initAuth,
      deps: [AuthService],
      multi: true,
    } as Provider,
    {
      provide: APP_INITIALIZER,
      useFactory: initOta,
      deps: [OtaUpdateService],
      multi: true,
    } as Provider,
  ],
};

