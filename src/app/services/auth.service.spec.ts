import { TestBed } from '@angular/core/testing';
import { SUPABASE } from './supabase.client';
import { crearSupabaseMock } from '../../testing/supabase-mock';
import { AuthService } from './auth.service';

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
});
