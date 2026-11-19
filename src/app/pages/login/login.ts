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
  readonly modo = signal<'login' | 'registro'>('login');
  form = { nombre: '', email: '', password: '' };
  readonly error = signal('');
  readonly mensaje = signal('');
  readonly cargando = signal(false);
  readonly ofrecerPasskey = signal(false);
  readonly vista = signal<'login' | 'registro' | 'recuperar'>('login');

  constructor(private readonly auth: AuthService, private readonly router: Router) {}

  cambiarModo(modo: 'login' | 'registro'): void {
    this.modo.set(modo);
    this.ofrecerPasskey.set(false);
    this.error.set('');
    this.mensaje.set('');
  }

  irARecuperar(): void {
    this.vista.set('recuperar');
    this.modo.set('login');
    this.ofrecerPasskey.set(false);
    this.error.set('');
    this.mensaje.set('');
  }

  volverALogin(): void {
    this.vista.set('login');
    this.error.set('');
    this.mensaje.set('');
  }

  async submit(): Promise<void> {
    this.error.set('');
    this.mensaje.set('');
    const { nombre, email, password } = this.form;
    this.cargando.set(true);
    try {
      if (this.vista() === 'recuperar') {
        const res = await this.auth.recuperarPassword(email);
        if (!res.ok) { this.error.set(res.mensaje); return; }
        this.mensaje.set(res.mensaje);
        return;
      }
      if (this.modo() === 'registro') {
        const res = await this.auth.registrar({ nombre, email, password });
        if (!res.ok) { this.error.set(res.mensaje); return; }
        if (this.auth.autenticado()) await this.router.navigate(['/dashboard']);
        else this.mensaje.set(res.mensaje);
        return;
      }
      const res = await this.auth.login({ email, password });
      if (!res.ok) { this.error.set(res.mensaje); return; }
      this.ofrecerPasskey.set(true);
      this.mensaje.set('Sesión iniciada. Puedes activar el acceso con Face ID para la próxima vez.');
    } finally {
      this.cargando.set(false);
    }
  }

  async entrarConPasskey(): Promise<void> {
    this.error.set('');
    this.mensaje.set('');
    this.cargando.set(true);
    try {
      const res = await this.auth.loginConPasskey();
      if (!res.ok) { this.error.set(res.mensaje); return; }
      await this.router.navigate(['/dashboard']);
    } finally { this.cargando.set(false); }
  }

  async activarPasskey(): Promise<void> {
    this.error.set('');
    this.mensaje.set('');
    this.cargando.set(true);
    try {
      const res = await this.auth.registrarPasskey();
      if (!res.ok) { this.error.set(res.mensaje); return; }
      this.mensaje.set(res.mensaje);
      await this.router.navigate(['/dashboard']);
    } finally { this.cargando.set(false); }
  }

  continuarSinPasskey(): void { void this.router.navigate(['/dashboard']); }

  async reenviar(): Promise<void> {
    this.error.set('');
    this.mensaje.set('');
    this.cargando.set(true);
    try {
      const res = await this.auth.reenviarConfirmacion(this.form.email);
      if (!res.ok) { this.error.set(res.mensaje); return; }
      this.mensaje.set(res.mensaje);
    } finally { this.cargando.set(false); }
  }
}
