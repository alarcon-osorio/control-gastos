import { InjectionToken } from '@angular/core';
import { SupabaseClient, createClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';

/**
 * Token de inyección del cliente de Supabase.
 * Passkeys (WebAuthn) está habilitado en el SDK; también debe activarse
 * y configurarse el dominio RP desde Authentication > Passkeys en Supabase.
 */
export const SUPABASE = new InjectionToken<SupabaseClient>('SUPABASE', {
  providedIn: 'root',
  factory: () =>
    createClient(environment.supabase.url, environment.supabase.anonKey, {
      auth: {
        experimental: { passkey: true },
      },
    }),
});
