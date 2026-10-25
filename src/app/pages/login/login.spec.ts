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
      providers: [
        provideRouter([]),
        { provide: SUPABASE, useValue: mock.client },
      ],
    }).compileComponents();
    auth = TestBed.inject(AuthService);
  });

  it('debería alternar entre pestañas de login y registro', () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    fixture.detectChanges();

    // En modo login no debe existir el campo nombre.
    expect(fixture.nativeElement.querySelector('#nombre')).toBeNull();

    const tabs = fixture.nativeElement.querySelectorAll('.tab');
    (tabs[1] as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(comp.modo()).toBe('registro');
    expect(fixture.nativeElement.querySelector('#nombre')).not.toBeNull();
  });

  it('debería registrar un usuario y navegar al dashboard', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const router = TestBed.inject(Router);
    const navSpy = vi.spyOn(router, 'navigate');
    fixture.detectChanges();

    const tabs = fixture.nativeElement.querySelectorAll('.tab');
    (tabs[1] as HTMLButtonElement).click();
    fixture.detectChanges();

    comp.form = { nombre: 'Ana', email: 'ana@mail.com', password: 'secreto1' };
    fixture.detectChanges();

    await comp.submit();
    fixture.detectChanges();

    expect(auth.autenticado()).toBeTruthy();
    expect(navSpy).toHaveBeenCalledWith(['/dashboard']);
  });

  it('debería iniciar sesión con credenciales válidas', async () => {
    // Pre-registramos un usuario.
    await auth.registrar({ nombre: 'Luis', email: 'luis@mail.com', password: 'secreto1' });
    await auth.logout();

    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    const router = TestBed.inject(Router);
    const navSpy = vi.spyOn(router, 'navigate');
    fixture.detectChanges();

    comp.form = { nombre: '', email: 'luis@mail.com', password: 'secreto1' };
    fixture.detectChanges();

    await comp.submit();
    fixture.detectChanges();

    expect(auth.autenticado()).toBeTruthy();
    expect(navSpy).toHaveBeenCalledWith(['/dashboard']);
  });

  it('debería mostrar error con credenciales inválidas', async () => {
    const fixture = TestBed.createComponent(Login);
    const comp = fixture.componentInstance;
    fixture.detectChanges();

    comp.form = { nombre: '', email: 'noexiste@mail.com', password: 'xxxxxx' };
    fixture.detectChanges();

    await comp.submit();
    fixture.detectChanges();

    const errorEl = fixture.nativeElement.querySelector('.alert-error');
    expect(errorEl?.textContent).toContain('incorrectos');
    expect(auth.autenticado()).toBeFalsy();
  });
});
