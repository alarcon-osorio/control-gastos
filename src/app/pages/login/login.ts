import { Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  /** 'login' o 'registro' según la pestaña activa. */
  readonly modo = signal<'login' | 'registro'>('login');

  /** Modelo del formulario con propiedades planas (compatible con ngModel). */
  form = {
    nombre: '',
    email: '',
    password: '',
  };

  readonly error = signal('');
  readonly mensaje = signal('');

  constructor(
    private readonly auth: AuthService,
    private readonly router: Router,
  ) {}

  cambiarModo(modo: 'login' | 'registro'): void {
    this.modo.set(modo);
    this.error.set('');
    this.mensaje.set('');
  }

  /** Vista activa: 'login' | 'registro' | 'recuperar'. */
  readonly vista = signal<'login' | 'registro' | 'recuperar'>('login');

  irARecuperar(): void {
    this.vista.set('recuperar');
    this.modo.set('login');
    this.error.set('');
    this.mensaje.set('');
  }

  volverALogin(): void {
    this.vista.set('login');
    this.error.set('');
    this.mensaje.set('');
  }

  readonly cargando = signal(false);

  async submit(): Promise<void> {
    this.error.set('');
    this.mensaje.set('');
    const { nombre, email, password } = this.form;
    this.cargando.set(true);

    try {
      // Vista de recuperación de contraseña.
      if (this.vista() === 'recuperar') {
        const res = await this.auth.recuperarPassword(email);
        if (!res.ok) {
          this.error.set(res.mensaje);
          return;
        }
        this.mensaje.set(res.mensaje);
        return;
      }

      if (this.modo() === 'registro') {
        const res = await this.auth.registrar({ nombre, email, password });
        if (!res.ok) {
          this.error.set(res.mensaje);
          return;
        }
        // Si hay sesión activa tras registrar, navegamos al dashboard.
        if (this.auth.autenticado()) {
          this.router.navigate(['/dashboard']);
        } else {
          // Registro ok pero requiere confirmación de email.
          this.mensaje.set(res.mensaje);
        }
        return;
      }

      const res = await this.auth.login({ email, password });
      if (!res.ok) {
        this.error.set(res.mensaje);
        return;
      }
      this.router.navigate(['/dashboard']);
    } finally {
      this.cargando.set(false);
    }
  }

  /** Reenvía el correo de confirmación al email del formulario. */
  async reenviar(): Promise<void> {
    this.error.set('');
    this.mensaje.set('');
    this.cargando.set(true);
    try {
      const res = await this.auth.reenviarConfirmacion(this.form.email);
      if (!res.ok) {
        this.error.set(res.mensaje);
        return;
      }
      this.mensaje.set(res.mensaje);
    } finally {
      this.cargando.set(false);
    }
  }
}


