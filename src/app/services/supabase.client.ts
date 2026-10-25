import { InjectionToken } from '@angular/core';
import { SupabaseClient, createClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';

/**
 * Token de inyección del cliente de Supabase.
 * Centraliza la conexión con el proyecto (URL + anon key) y permite
 * sustituirlo por un mock en los tests mediante TestBed.
 */
export const SUPABASE = new InjectionToken<SupabaseClient>('SUPABASE', {
  providedIn: 'root',
  factory: () =>
    createClient(environment.supabase.url, environment.supabase.anonKey),
});

