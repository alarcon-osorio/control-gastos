import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { MonedasService } from '../services/monedas.service';

@Component({
  selector: 'app-layout',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, FormsModule],
  templateUrl: './layout.html',
  styleUrl: './layout.css',
})
export class Layout {
  readonly auth = inject(AuthService);
  readonly monedas = inject(MonedasService);
  private readonly router = inject(Router);

  async cerrarSesion(): Promise<void> {
    await this.auth.logout();
    // Navegamos al login para salir del área protegida de inmediato.
    this.router.navigate(['/login']);
  }
}

