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
      const { data, error } = await this.supabase.auth.signInWithPasskey();
      if (error) return { ok: false, mensaje: this.traducirError(error.message) };
      if (data.session) this.actualizarDesdeSesion(data.session);
      return { ok: true, mensaje: 'Acceso seguro completado.' };
    } catch (error: unknown) {
      return { ok: false, mensaje: this.mensajeErrorPasskey(error, 'No se pudo validar la Passkey.') };
    }
  }

  /** Registra una Passkey para la cuenta que ya inició sesión con Supabase. */
  async registrarPasskey(): Promise<ResultadoAuth> {
    if (!this.autenticado()) return { ok: false, mensaje: 'Inicia sesión antes de configurar Face ID.' };
    if (!this.webAuthnDisponible()) {
      return { ok: false, mensaje: 'Este navegador no admite Passkeys o requiere una conexión HTTPS.' };
    }
    try {
      // La señal local puede actualizarse después del evento SIGNED_IN.
      // Consultamos la sesión real para evitar intentar registrar sin sesión activa.
      const { data: sessionData, error: sessionError } = await this.supabase.auth.getSession();
      if (sessionError || !sessionData.session) {
        this.usuarioActual.set(null);
        return { ok: false, mensaje: 'Tu sesión no está disponible. Inicia sesión nuevamente y vuelve a activar la Passkey.' };
      }
      this.actualizarDesdeSesion(sessionData.session);

      const { error } = await this.supabase.auth.registerPasskey();
      if (error) return { ok: false, mensaje: this.traducirError(error.message) };
      return { ok: true, mensaje: 'Passkey registrada correctamente en este dispositivo.' };
    } catch (error: unknown) {
      return { ok: false, mensaje: this.mensajeErrorPasskey(error, 'No se pudo registrar la Passkey.') };
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

  private mensajeErrorPasskey(error: unknown, mensajePredeterminado: string): string {
    const detalle = error instanceof Error ? error.message : String(error);
    const nombre = error instanceof Error ? error.name : '';
    const lower = `${nombre} ${detalle}`.toLowerCase();

    if (lower.includes('notallowederror') || lower.includes('cancelled') || lower.includes('canceled')) {
      return 'La solicitud de Passkey se canceló o no se encontró una credencial disponible. Inténtalo nuevamente.';
    }
    if (lower.includes('securityerror') || lower.includes('rp id') || lower.includes('origin')) {
      return 'El dominio de esta aplicación no coincide con la configuración WebAuthn de Supabase. Revisa el Relying Party ID y los orígenes permitidos.';
    }
    if (lower.includes('passkey_disabled')) {
      return 'El acceso con Passkeys no está habilitado en Supabase (Authentication → Passkeys).';
    }
    if (lower.includes('webauthn_credential_exists')) {
      return 'Ya existe una Passkey registrada para esta cuenta en este dispositivo.';
    }
    if (lower.includes('webauthn_credential_not_found')) {
      return 'No hay una Passkey registrada para esta cuenta. Inicia sesión con contraseña y regístrala primero.';
    }
    if (lower.includes('webauthn_challenge_expired')) {
      return 'La solicitud de Passkey expiró. Vuelve a intentarlo.';
    }
    if (lower.includes('webauthn_verification_failed')) {
      return 'Supabase no pudo verificar la Passkey. Comprueba el dominio configurado y vuelve a registrarla si cambió.';
    }
    return mensajePredeterminado;
  }

  private traducirError(mensaje: string): string {
    const lower = mensaje.toLowerCase();
    if (lower.includes('passkey_disabled')) return 'El acceso con Passkeys no está habilitado en Supabase (Authentication → Passkeys).';
    if (lower.includes('already registered')) return 'Ya existe una cuenta con ese email.';
    if (lower.includes('rate limit')) return 'Demasiados intentos. Espera un momento.';
    if (lower.includes('webauthn_credential_exists')) return 'Ya existe una Passkey registrada para este dispositivo.';
    if (lower.includes('webauthn_credential_not_found')) return 'No hay una Passkey registrada. Inicia sesión con contraseña y actívala primero.';
    if (lower.includes('webauthn_challenge_expired')) return 'La solicitud de Passkey expiró. Vuelve a intentarlo.';
    if (lower.includes('webauthn_verification_failed')) return 'No se pudo verificar la Passkey. Revisa el dominio permitido en Supabase.';
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }
}
