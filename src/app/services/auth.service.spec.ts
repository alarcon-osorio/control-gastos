import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import { SUPABASE } from './supabase.client';
import { crearSupabaseMock } from '../../testing/supabase-mock';
import { AuthService } from './auth.service';

type Descriptor = PropertyDescriptor | undefined;

function definir(obj: object, prop: string, value: unknown): Descriptor {
  const original = Object.getOwnPropertyDescriptor(obj, prop);
  Object.defineProperty(obj, prop, { configurable: true, value });
  return original;
}

function restaurar(obj: object, prop: string, original: Descriptor): void {
  if (original) Object.defineProperty(obj, prop, original);
  else delete (obj as Record<string, unknown>)[prop];
}

function habilitarWebAuthn(): () => void {
  const secure = definir(window, 'isSecureContext', true);
  const credential = definir(globalThis, 'PublicKeyCredential', class {});
  const credentials = definir(navigator, 'credentials', {});
  return () => {
    restaurar(window, 'isSecureContext', secure);
    restaurar(globalThis, 'PublicKeyCredential', credential);
    restaurar(navigator, 'credentials', credentials);
  };
}

function sesionDe(nombre: string, email: string) {
  return {
    user: {
      id: 'uuid-passkey',
      email,
      created_at: '2026-01-01T00:00:00Z',
      user_metadata: { nombre },
    },
  };
}

describe('AuthService (Supabase mock)', () => {
  let service: AuthService;
  let mock: ReturnType<typeof crearSupabaseMock>;

  beforeEach(() => {
    mock = crearSupabaseMock();
    TestBed.configureTestingModule({
      providers: [{ provide: SUPABASE, useValue: mock.client }],
    });
    service = TestBed.inject(AuthService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('no debería estar autenticado al inicio', () => {
    expect(service.autenticado()).toBeFalsy();
  });

  it('debería registrar un usuario y autenticarlo', async () => {
    const res = await service.registrar({ nombre: 'Ana', email: 'ana@mail.com', password: 'secreto1' });
    expect(res.ok).toBeTruthy();
    expect(service.autenticado()).toBeTruthy();
    expect(service.usuario()?.nombre).toBe('Ana');
  });

  it('debería rechazar email inválido', async () => {
    const res = await service.registrar({ nombre: 'X', email: 'no-email', password: 'secreto1' });
    expect(res.ok).toBeFalsy();
  });

  it('debería rechazar contraseña corta', async () => {
    const res = await service.registrar({ nombre: 'X', email: 'x@mail.com', password: '123' });
    expect(res.ok).toBeFalsy();
  });

  it('debería iniciar sesión con credenciales correctas', async () => {
    await service.registrar({ nombre: 'Luis', email: 'luis@mail.com', password: 'secreto1' });
    await service.logout();
    expect(service.autenticado()).toBeFalsy();
    const res = await service.login({ email: 'luis@mail.com', password: 'secreto1' });
    expect(res.ok).toBeTruthy();
    expect(service.autenticado()).toBeTruthy();
  });

  it('debería rechazar credenciales incorrectas', async () => {
    await service.registrar({ nombre: 'Luis', email: 'luis@mail.com', password: 'secreto1' });
    await service.logout();
    const res = await service.login({ email: 'luis@mail.com', password: 'mal' });
    expect(res.ok).toBeFalsy();
    expect(service.autenticado()).toBeFalsy();
  });

  it('debería cerrar sesión', async () => {
    await service.registrar({ nombre: 'Ana', email: 'ana@mail.com', password: 'secreto1' });
    await service.logout();
    expect(service.autenticado()).toBeFalsy();
  });

  it('no permite Passkey sin HTTPS/WebAuthn', async () => {
    const original = Object.getOwnPropertyDescriptor(window, 'isSecureContext');
    Object.defineProperty(window, 'isSecureContext', { configurable: true, value: false });
    try {
      const login = await service.loginConPasskey();
      const registro = await service.registrarPasskey();
      expect(login.ok).toBeFalsy();
      expect(registro.ok).toBeFalsy();
      expect(login.mensaje).toContain('HTTPS');
    } finally {
      restaurar(window, 'isSecureContext', original);
    }
  });

  it('inicia sesión con Passkey y actualiza el usuario', async () => {
    const restore = habilitarWebAuthn();
    mock.client.auth.signInWithPasskey = vi.fn().mockResolvedValue({
      data: { session: sesionDe('Ana', 'ana@mail.com') },
      error: null,
    }) as typeof mock.client.auth.signInWithPasskey;
    try {
      const res = await service.loginConPasskey();
      expect(res.ok).toBeTruthy();
      expect(service.usuario()?.email).toBe('ana@mail.com');
    } finally {
      restore();
    }
  });

  it('traduce errores de Supabase al iniciar con Passkey', async () => {
    const restore = habilitarWebAuthn();
    mock.client.auth.signInWithPasskey = vi.fn().mockResolvedValue({
      data: { session: null },
      error: { message: 'passkey_disabled' },
    }) as typeof mock.client.auth.signInWithPasskey;
    try {
      expect((await service.loginConPasskey()).mensaje).toContain('no está habilitado');
    } finally {
      restore();
    }
  });

  it('no registra Passkey sin sesión activa', async () => {
    const restore = habilitarWebAuthn();
    try {
      const res = await service.registrarPasskey();
      expect(res.ok).toBeFalsy();
      expect(res.mensaje).toContain('sesión no está disponible');
      expect(service.autenticado()).toBeFalsy();
    } finally {
      restore();
    }
  });

  it('registra Passkey con la sesión activa', async () => {
    const restore = habilitarWebAuthn();
    await service.registrar({ nombre: 'Ana', email: 'ana@mail.com', password: 'secreto1' });
    try {
      const res = await service.registrarPasskey();
      expect(res.ok).toBeTruthy();
      expect(res.mensaje).toContain('registrada');
    } finally {
      restore();
    }
  });

  it('traduce errores al registrar Passkey', async () => {
    const restore = habilitarWebAuthn();
    await service.registrar({ nombre: 'Ana', email: 'ana@mail.com', password: 'secreto1' });
    mock.client.auth.registerPasskey = vi.fn().mockResolvedValue({
      data: null,
      error: { message: 'webauthn_credential_exists' },
    }) as typeof mock.client.auth.registerPasskey;
    try {
      expect((await service.registrarPasskey()).mensaje).toContain('Ya existe una Passkey');
    } finally {
      restore();
    }
  });

  it('devuelve mensaje predeterminado si registrar Passkey lanza error', async () => {
    const restore = habilitarWebAuthn();
    await service.registrar({ nombre: 'Ana', email: 'ana@mail.com', password: 'secreto1' });
    mock.client.auth.registerPasskey = vi.fn().mockRejectedValue(new Error('otro')) as typeof mock.client.auth.registerPasskey;
    try {
      expect((await service.registrarPasskey()).mensaje).toContain('No se pudo registrar');
    } finally {
      restore();
    }
  });

  it('explica errores lanzados por WebAuthn', async () => {
    const restore = habilitarWebAuthn();
    const casos = [
      [Object.assign(new Error('x'), { name: 'NotAllowedError' }), 'canceló'],
      [Object.assign(new Error('x'), { name: 'SecurityError' }), 'dominio'],
      [new Error('passkey_disabled'), 'no está habilitado'],
      [new Error('webauthn_credential_exists'), 'Ya existe una Passkey'],
      [new Error('webauthn_credential_not_found'), 'No hay una Passkey'],
      [new Error('webauthn_challenge_expired'), 'expiró'],
      [new Error('webauthn_verification_failed'), 'verificar'],
      [new Error('otro'), 'No se pudo validar'],
    ] as const;
    try {
      for (const [error, texto] of casos) {
        mock.client.auth.signInWithPasskey = vi.fn().mockRejectedValue(error) as typeof mock.client.auth.signInWithPasskey;
        const res = await service.loginConPasskey();
        expect(res.ok).toBeFalsy();
        expect(res.mensaje).toContain(texto);
      }
    } finally {
      restore();
    }
  });

  it('traduce mensajes concretos de Passkey devueltos por Supabase', async () => {
    const restore = habilitarWebAuthn();
    const casos = [
      ['already registered', 'Ya existe una cuenta'],
      ['rate limit', 'Demasiados intentos'],
      ['webauthn_credential_not_found', 'No hay una Passkey'],
      ['webauthn_challenge_expired', 'expiró'],
      ['webauthn_verification_failed', 'No se pudo verificar'],
      ['SecurityError', 'dominio'],
      ['otro', 'No se pudo completar'],
    ] as const;
    try {
      for (const [mensaje, texto] of casos) {
        mock.client.auth.signInWithPasskey = vi.fn().mockResolvedValue({
          data: { session: null },
          error: { message: mensaje },
        }) as typeof mock.client.auth.signInWithPasskey;
        expect((await service.loginConPasskey()).mensaje).toContain(texto);
      }
    } finally {
      restore();
    }
  });
});
