import { Injectable, computed, inject, signal } from '@angular/core';
import { Session, User, SupabaseClient } from '@supabase/supabase-js';
import { SUPABASE } from './supabase.client';
import { Credenciales, Usuario, UsuarioInput } from '../models/usuario';

/**
 * Servicio de autenticación con Supabase.
 * Gestiona registro, login, logout y mantiene la sesión del usuario
 * actual mediante signals, escuchando los cambios de auth de Supabase.
 */
@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly supabase = inject(SUPABASE);

  /** Usuario actualmente autenticado (null si no hay sesión). */
  private readonly usuarioActual = signal<Usuario | null>(null);

  /** Indica si hay una sesión activa. */
  readonly autenticado = computed(() => this.usuarioActual() !== null);

  /** Expone el usuario actual como signal de solo lectura. */
  readonly usuario = this.usuarioActual.asReadonly();

  /** Promise que se resuelve cuando la sesión inicial está lista. */
  private readonly sesionLista: Promise<void>;
  private resolverSesion!: () => void;

  constructor() {
    this.sesionLista = new Promise<void>((resolve) => {
      this.resolverSesion = resolve;
    });
    // Escucha cambios de auth. El primer evento (INITIAL_SESSION) llega
    // con la sesión persistida, permitiendo resolver la promesa de arranque.
    this.supabase.auth.onAuthStateChange((_event, session) => {
      this.actualizarDesdeSesion(session);
      this.resolverSesion();
    });
  }

  /** Espera a que la sesión inicial se haya resuelto (para APP_INITIALIZER). */
  listo(): Promise<void> {
    return this.sesionLista;
  }

  /** Registra un nuevo usuario en Supabase. */
  async registrar(input: UsuarioInput): Promise<{ ok: boolean; mensaje: string }> {
    const email = input.email.trim().toLowerCase();
    const nombre = input.nombre.trim();

    if (!nombre) {
      return { ok: false, mensaje: 'El nombre es obligatorio.' };
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return { ok: false, mensaje: 'Introduce un email válido.' };
    }
    if (input.password.length < 6) {
      return { ok: false, mensaje: 'La contraseña debe tener al menos 6 caracteres.' };
    }

    const { data, error } = await this.supabase.auth.signUp({
      email,
      password: input.password,
      options: { data: { nombre } },
    });

    if (error) {
      return { ok: false, mensaje: this.traducirError(error.message) };
    }
    // Si Supabase exige confirmación por email, data.session será null.
    if (!data.session) {
      return {
        ok: true,
        mensaje: 'Cuenta creada. Revisa tu correo para confirmar (si está activado).',
      };
    }
    return { ok: true, mensaje: 'Cuenta creada correctamente.' };
  }

  /** Inicia sesión con email y contraseña. */
  async login(credenciales: Credenciales): Promise<{ ok: boolean; mensaje: string }> {
    const { error } = await this.supabase.auth.signInWithPassword({
      email: credenciales.email.trim().toLowerCase(),
      password: credenciales.password,
    });
    if (error) {
      return { ok: false, mensaje: 'Email o contraseña incorrectos.' };
    }
    return { ok: true, mensaje: 'Bienvenido.' };
  }

  /** Cierra la sesión actual. */
  async logout(): Promise<void> {
    await this.supabase.auth.signOut();
    this.usuarioActual.set(null);
  }

  /** Envía un correo para restablecer la contraseña. */
  async recuperarPassword(email: string): Promise<{ ok: boolean; mensaje: string }> {
    const limpio = email.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(limpio)) {
      return { ok: false, mensaje: 'Introduce un email válido.' };
    }
    const { error } = await this.supabase.auth.resetPasswordForEmail(limpio, {
      redirectTo: `${window.location.origin}/login`,
    });
    if (error) {
      return { ok: false, mensaje: 'No se pudo enviar el correo. Inténtalo de nuevo.' };
    }
    return {
      ok: true,
      mensaje: 'Si el correo existe, te enviamos un enlace para restablecer tu contraseña.',
    };
  }

  /** Reenvía el correo de confirmación a un email recién registrado. */
  async reenviarConfirmacion(email: string): Promise<{ ok: boolean; mensaje: string }> {
    const limpio = email.trim().toLowerCase();
    const { error } = await this.supabase.auth.resend({
      type: 'signup',
      email: limpio,
    });
    if (error) {
      return { ok: false, mensaje: 'No se pudo reenviar el correo.' };
    }
    return { ok: true, mensaje: 'Te reenviamos el correo de confirmación.' };
  }

  private actualizarDesdeSesion(session: Session | null): void {
    const user: User | undefined = session?.user;
    if (!user) {
      this.usuarioActual.set(null);
      return;
    }
    this.usuarioActual.set({
      id: user.id,
      nombre:
        (user.user_metadata?.['nombre'] as string) ||
        user.email?.split('@')[0] ||
        'Usuario',
      email: user.email ?? '',
      fechaRegistro: user.created_at,
    });
  }

  private traducirError(mensaje: string): string {
    if (mensaje.toLowerCase().includes('already registered')) {
      return 'Ya existe una cuenta con ese email.';
    }
    if (mensaje.toLowerCase().includes('rate limit')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }
}

