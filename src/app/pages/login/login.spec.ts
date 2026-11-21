import { TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { vi } from 'vitest';
import { SUPABASE } from '../../services/supabase.client';
import { crearSupabaseMock } from '../../../testing/supabase-mock';
import { AuthService } from '../../services/auth.service';
import { Login } from './login';

describe('Login (integración con Supabase mock)', () => {
  let auth: AuthService;
  let mock: ReturnType<typeof crearSupabaseMock>;

  beforeEach(async () => {
    mock = crearSupabaseMock();
    await TestBed.configureTestingModule({
      imports: [Login],
      providers: [provideRouter([]), { provide: SUPABASE, useValue: mock.client }],
    }).compileComponents();
    auth = TestBed.inject(AuthService);
  });

  it('alterna entre pestañas de login y registro', () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('#nombre')).toBeNull();
    const tabs = fixture.nativeElement.querySelectorAll('.tab');
    (tabs[1] as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(comp.modo()).toBe('registro');
    expect(fixture.nativeElement.querySelector('#nombre')).not.toBeNull();
  });

  it('registra un usuario y navega al dashboard', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const navSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    fixture.detectChanges();
    const tabs = fixture.nativeElement.querySelectorAll('.tab');
    (tabs[1] as HTMLButtonElement).click();
    fixture.detectChanges();
    comp.form = { nombre: 'Ana', email: 'ana@mail.com', password: 'secreto1' };
    await comp.submit();
    expect(auth.autenticado()).toBeTruthy();
    expect(navSpy).toHaveBeenCalledWith(['/dashboard']);
  });

  it('login con contraseña ofrece activar Passkey y mantiene sesión', async () => {
    await auth.registrar({ nombre: 'Luis', email: 'luis@mail.com', password: 'secreto1' });
    await auth.logout();
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    fixture.detectChanges();
    comp.form = { nombre: '', email: 'luis@mail.com', password: 'secreto1' };
    await comp.submit();
    fixture.detectChanges();
    expect(auth.autenticado()).toBeTruthy();
    expect(comp.ofrecerPasskey()).toBeTruthy();
    expect(fixture.nativeElement.textContent).toContain('Activar Face ID');
  });

  it('permite continuar sin registrar una Passkey', () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const navSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    comp.ofrecerPasskey.set(true);
    comp.continuarSinPasskey();
    expect(navSpy).toHaveBeenCalledWith(['/dashboard']);
  });

  it('muestra error con credenciales inválidas', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    fixture.detectChanges();
    comp.form = { nombre: '', email: 'noexiste@mail.com', password: 'xxxxxx' };
    await comp.submit();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.alert-error')?.textContent).toContain('incorrectos');
    expect(auth.autenticado()).toBeFalsy();
  });

  it('cambia a recuperación y vuelve al login', () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    comp.irARecuperar();
    expect(comp.vista()).toBe('recuperar');
    expect(comp.modo()).toBe('login');
    comp.volverALogin();
    expect(comp.vista()).toBe('login');
  });

  it('recupera contraseña desde el formulario', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const spy = vi.spyOn(auth, 'recuperarPassword').mockResolvedValue({ ok: true, mensaje: 'Revisa tu correo' });
    comp.form.email = 'ana@mail.com';
    comp.vista.set('recuperar');
    await comp.submit();
    expect(spy).toHaveBeenCalledWith('ana@mail.com');
    expect(comp.mensaje()).toContain('Revisa tu correo');
    expect(comp.cargando()).toBe(false);
  });

  it('muestra error al recuperar contraseña', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    vi.spyOn(auth, 'recuperarPassword').mockResolvedValue({ ok: false, mensaje: 'Email inválido' });
    comp.vista.set('recuperar');
    await comp.submit();
    expect(comp.error()).toBe('Email inválido');
    expect(comp.cargando()).toBe(false);
  });

  it('entra con Passkey y navega al dashboard', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const navSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    vi.spyOn(auth, 'loginConPasskey').mockResolvedValue({ ok: true, mensaje: 'Acceso seguro completado.' });
    await comp.entrarConPasskey();
    expect(navSpy).toHaveBeenCalledWith(['/dashboard']);
    expect(comp.cargando()).toBe(false);
  });

  it('muestra error si falla el acceso con Passkey', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const navSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    vi.spyOn(auth, 'loginConPasskey').mockResolvedValue({ ok: false, mensaje: 'Passkey no encontrada' });
    await comp.entrarConPasskey();
    expect(comp.error()).toBe('Passkey no encontrada');
    expect(navSpy).not.toHaveBeenCalled();
  });

  it('activa Passkey y navega al dashboard', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const navSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    vi.spyOn(auth, 'registrarPasskey').mockResolvedValue({ ok: true, mensaje: 'Passkey registrada' });
    await comp.activarPasskey();
    expect(comp.mensaje()).toBe('Passkey registrada');
    expect(navSpy).toHaveBeenCalledWith(['/dashboard']);
  });

  it('muestra error si falla activar Passkey', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const navSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    vi.spyOn(auth, 'registrarPasskey').mockResolvedValue({ ok: false, mensaje: 'Sin sesión' });
    await comp.activarPasskey();
    expect(comp.error()).toBe('Sin sesión');
    expect(navSpy).not.toHaveBeenCalled();
  });

  it('reenvía el correo de confirmación', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const spy = vi.spyOn(auth, 'reenviarConfirmacion').mockResolvedValue({ ok: true, mensaje: 'Correo reenviado' });
    comp.form.email = 'ana@mail.com';
    await comp.reenviar();
    expect(spy).toHaveBeenCalledWith('ana@mail.com');
    expect(comp.mensaje()).toBe('Correo reenviado');
  });

  it('muestra error si falla el reenvío', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    vi.spyOn(auth, 'reenviarConfirmacion').mockResolvedValue({ ok: false, mensaje: 'No se pudo reenviar' });
    await comp.reenviar();
    expect(comp.error()).toBe('No se pudo reenviar');
    expect(comp.cargando()).toBe(false);
  });
});
