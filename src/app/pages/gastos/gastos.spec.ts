import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { SUPABASE } from '../../services/supabase.client';
import { crearSupabaseMock } from '../../../testing/supabase-mock';
import { AuthService } from '../../services/auth.service';
import { Gastos } from './gastos';

describe('Gastos (filtro por mes)', () => {
  it('filtra por mes, año, número y nombre del mes', async () => {
    const mock = crearSupabaseMock();
    mock.store['gastos'] = [
      { id: 1, usuario_id: 'uuid-1', monto: 10, categoria: 'Comida', metodo_pago: 'Efectivo', fecha: '2026-01-15', descripcion: '' },
      { id: 2, usuario_id: 'uuid-1', monto: 20, categoria: 'Transporte', metodo_pago: 'Tarjeta', fecha: '2026-02-10', descripcion: '' },
    ];

    await TestBed.configureTestingModule({
      imports: [Gastos],
      providers: [provideRouter([]), { provide: SUPABASE, useValue: mock.client }],
    }).compileComponents();

    const auth = TestBed.inject(AuthService);
    await auth.registrar({ nombre: 'Test', email: 'test@mail.com', password: 'secreto1' });

    const fixture = TestBed.createComponent(Gastos);
    await fixture.whenStable();
    fixture.detectChanges();

    const comp = fixture.componentInstance;

    expect(comp.mesesDisponibles()).toEqual(['2026-02', '2026-01']);

    comp.filtroMes.set('2026-01');
    expect(comp.gastosFiltrados().length).toBe(1);
    expect(comp.hayFiltros()).toBe(true);

    comp.filtroMes.set('2026');
    expect(comp.gastosFiltrados().length).toBe(2);

    comp.filtroMes.set('2');
    expect(comp.gastosFiltrados().length).toBe(1);

    comp.filtroMes.set('febrero');
    expect(comp.gastosFiltrados().length).toBe(1);

    comp.limpiarFiltros();
    expect(comp.hayFiltros()).toBe(false);
    expect(comp.gastosFiltrados().length).toBe(2);
  });
});
