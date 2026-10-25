import { TestBed } from '@angular/core/testing';
import { SUPABASE } from './supabase.client';
import { crearSupabaseMock } from '../../testing/supabase-mock';
import { GastosService } from './gastos.service';

describe('GastosService (Supabase mock)', () => {
  let service: GastosService;
  let mock: ReturnType<typeof crearSupabaseMock>;

  beforeEach(() => {
    mock = crearSupabaseMock();
    TestBed.configureTestingModule({
      providers: [{ provide: SUPABASE, useValue: mock.client }],
    });
    service = TestBed.inject(GastosService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('debería agregar un gasto y mapear snake_case', async () => {
    await service.agregar({
      usuarioId: 'uuid-1',
      monto: 50,
      categoria: 'Ocio',
      metodoPago: 'Efectivo',
      fecha: '2026-01-01',
      descripcion: 'Cine',
    });
    expect(service.gastos().length).toBe(1);
    const g = service.gastos()[0];
    expect(g.metodoPago).toBe('Efectivo');
    expect(g.usuarioId).toBe('uuid-1');
    expect(g.monto).toBe(50);
  });

  it('debería calcular el total por usuario', async () => {
    await service.agregar({ usuarioId: 'u1', monto: 30, categoria: 'A', metodoPago: 'E', fecha: '2026-01-01', descripcion: '' });
    await service.agregar({ usuarioId: 'u1', monto: 20, categoria: 'B', metodoPago: 'T', fecha: '2026-01-02', descripcion: '' });
    expect(service.totalUsuario('u1')()).toBe(50);
    expect(service.totalUsuario('otro')()).toBe(0);
  });

  it('debería calcular totales por categoría', async () => {
    await service.agregar({ usuarioId: 'u1', monto: 30, categoria: 'Ocio', metodoPago: 'E', fecha: '2026-01-01', descripcion: '' });
    await service.agregar({ usuarioId: 'u1', monto: 20, categoria: 'Ocio', metodoPago: 'E', fecha: '2026-01-02', descripcion: '' });
    expect(service.totalPorCategoria('u1')().get('Ocio')).toBe(50);
  });

  it('debería eliminar un gasto', async () => {
    await service.agregar({ usuarioId: 'u1', monto: 10, categoria: 'A', metodoPago: 'E', fecha: '2026-01-01', descripcion: '' });
    const id = service.gastos()[0].id;
    await service.eliminar(id);
    expect(service.gastos().length).toBe(0);
  });

  it('debería cargar gastos remotos y mapearlos', async () => {
    mock.store['gastos'] = [
      { id: 99, usuario_id: 'u1', monto: 15, categoria: 'Comida', metodo_pago: 'Tarjeta', fecha: '2026-02-02', descripcion: 'Almuerzo' },
    ];
    await service.cargar('u1');
    expect(service.gastos().length).toBe(1);
    expect(service.gastos()[0].metodoPago).toBe('Tarjeta');
  });
});
