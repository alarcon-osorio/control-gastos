import { Injectable, computed, inject, signal } from '@angular/core';
import { Session, User, SupabaseClient } from '@supabase/supabase-js';
import { SUPABASE } from './supabase.client';
import { Credenciales, Usuario, UsuarioInput } from '../models/usuario';

type ResultadoAuth = { ok: boolean; mensaje: string };

/**
 * Servicio de autenticación con Supabase.
 * Gestiona email/contraseña y Passkeys (WebAuthn), manteniendo la sesión
 * real de Supabase en ambos flujos.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly supabase = inject(SUPABASE);
  private readonly usuarioActual = signal<Usuario | null>(null);
  readonly autenticado = computed(() => this.usuarioActual() !== null);
  readonly usuario = this.usuarioActual.asReadonly();

  private readonly sesionLista: Promise<void>;
  private resolverSesion!: () => void;

  constructor() {
    this.sesionLista = new Promise<void>((resolve) => { this.resolverSesion = resolve; });
    this.supabase.auth.onAuthStateChange((_event, session) => {
      this.actualizarDesdeSesion(session);
      this.resolverSesion();
    });
  }

  listo(): Promise<void> { return this.sesionLista; }

  async registrar(input: UsuarioInput): Promise<ResultadoAuth> {
    const email = input.email.trim().toLowerCase();
    const nombre = input.nombre.trim();
    if (!nombre) return { ok: false, mensaje: 'El nombre es obligatorio.' };
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return { ok: false, mensaje: 'Introduce un email válido.' };
    }
    if (input.password.length < 6) {
      return { ok: false, mensaje: 'La contraseña debe tener al menos 6 caracteres.' };
    }
    const { data, error } = await this.supabase.auth.signUp({
      email, password: input.password, options: { data: { nombre } },
    });
    if (error) return { ok: false, mensaje: this.traducirError(error.message) };
    if (!data.session) {
      return { ok: true, mensaje: 'Cuenta creada. Revisa tu correo para confirmar (si está activado).' };
    }
    return { ok: true, mensaje: 'Cuenta creada correctamente.' };
  }

  async login(credenciales: Credenciales): Promise<ResultadoAuth> {
    const { error } = await this.supabase.auth.signInWithPassword({
      email: credenciales.email.trim().toLowerCase(), password: credenciales.password,
    });
    if (error) return { ok: false, mensaje: 'Email o contraseña incorrectos.' };
    return { ok: true, mensaje: 'Bienvenido.' };
  }

  /** Supabase verifica WebAuthn y emite la sesión real del usuario. */
  async loginConPasskey(): Promise<ResultadoAuth> {
    if (!this.webAuthnDisponible()) {
      return { ok: false, mensaje: 'Este navegador no admite Passkeys o requiere una conexión HTTPS.' };
    }
    try {
      const { error } = await this.supabase.auth.signInWithPasskey();
      if (error) return { ok: false, mensaje: this.traducirError(error.message) };
      return { ok: true, mensaje: 'Acceso seguro completado.' };
    } catch {
      return { ok: false, mensaje: 'No se pudo validar la Passkey. Inténtalo de nuevo o usa tu contraseña.' };
    }
  }

  /** Registra una Passkey para la cuenta que ya inició sesión con Supabase. */
  async registrarPasskey(): Promise<ResultadoAuth> {
    if (!this.autenticado()) return { ok: false, mensaje: 'Inicia sesión antes de configurar Face ID.' };
    if (!this.webAuthnDisponible()) {
      return { ok: false, mensaje: 'Este navegador no admite Passkeys o requiere una conexión HTTPS.' };
    }
    try {
      const { error } = await this.supabase.auth.registerPasskey();
      if (error) return { ok: false, mensaje: this.traducirError(error.message) };
      return { ok: true, mensaje: 'Passkey registrada correctamente en este dispositivo.' };
    } catch {
      return { ok: false, mensaje: 'No se pudo registrar la Passkey. Puedes continuar con tu contraseña.' };
    }
  }

  async logout(): Promise<void> {
    await this.supabase.auth.signOut();
    this.usuarioActual.set(null);
  }

  async recuperarPassword(email: string): Promise<ResultadoAuth> {
    const limpio = email.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(limpio)) {
      return { ok: false, mensaje: 'Introduce un email válido.' };
    }
    const { error } = await this.supabase.auth.resetPasswordForEmail(limpio, {
      redirectTo: `${window.location.origin}/login`,
    });
    if (error) return { ok: false, mensaje: 'No se pudo enviar el correo. Inténtalo de nuevo.' };
    return { ok: true, mensaje: 'Si el correo existe, te enviamos un enlace para restablecer tu contraseña.' };
  }

  async reenviarConfirmacion(email: string): Promise<ResultadoAuth> {
    const limpio = email.trim().toLowerCase();
    const { error } = await this.supabase.auth.resend({ type: 'signup', email: limpio });
    if (error) return { ok: false, mensaje: 'No se pudo reenviar el correo.' };
    return { ok: true, mensaje: 'Te reenviamos el correo de confirmación.' };
  }

  private webAuthnDisponible(): boolean {
    return typeof window !== 'undefined' && window.isSecureContext &&
      typeof PublicKeyCredential !== 'undefined' && typeof navigator.credentials !== 'undefined';
  }

  private actualizarDesdeSesion(session: Session | null): void {
    const user: User | undefined = session?.user;
    if (!user) { this.usuarioActual.set(null); return; }
    this.usuarioActual.set({
      id: user.id,
      nombre: (user.user_metadata?.['nombre'] as string) || user.email?.split('@')[0] || 'Usuario',
      email: user.email ?? '',
      fechaRegistro: user.created_at,
    });
  }

  private traducirError(mensaje: string): string {
    const lower = mensaje.toLowerCase();
    if (lower.includes('passkey_disabled')) return 'El acceso con Passkeys aún no está habilitado en Supabase.';
    if (lower.includes('already registered')) return 'Ya existe una cuenta con ese email.';
    if (lower.includes('rate limit')) return 'Demasiados intentos. Espera un momento.';
    if (lower.includes('webauthn_credential_exists')) return 'Ya existe una Passkey registrada para este dispositivo.';
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }
}
