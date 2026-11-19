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
});
