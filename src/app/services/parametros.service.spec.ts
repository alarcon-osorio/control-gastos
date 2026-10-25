import { TestBed } from '@angular/core/testing';
import { SUPABASE } from './supabase.client';
import { crearSupabaseMock } from '../../testing/supabase-mock';
import { ParametrosService } from './parametros.service';

describe('ParametrosService (Supabase mock)', () => {
  let service: ParametrosService;
  let mock: ReturnType<typeof crearSupabaseMock>;

  beforeEach(() => {
    mock = crearSupabaseMock();
    TestBed.configureTestingModule({
      providers: [{ provide: SUPABASE, useValue: mock.client }],
    });
    service = TestBed.inject(ParametrosService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('debería sembrar valores por defecto si no hay parámetros', async () => {
    await service.cargar('u1');
    expect(service.nombresPorTipo('categoria').length).toBeGreaterThan(0);
    expect(service.nombresPorTipo('metodoPago').length).toBeGreaterThan(0);
  });

  it('debería agregar un parámetro', async () => {
    await service.cargar('u1');
    const res = await service.agregar({ usuarioId: 'u1', tipo: 'categoria', nombre: 'Mascotas' });
    expect(res.ok).toBeTruthy();
    expect(service.nombresPorTipo('categoria')).toContain('Mascotas');
  });

  it('no debería permitir duplicados del mismo tipo', async () => {
    await service.cargar('u1');
    await service.agregar({ usuarioId: 'u1', tipo: 'categoria', nombre: 'Mascotas' });
    const res = await service.agregar({ usuarioId: 'u1', tipo: 'categoria', nombre: 'mascotas' });
    expect(res.ok).toBeFalsy();
  });

  it('debería actualizar un parámetro', async () => {
    await service.cargar('u1');
    const primero = service.parametros()[0];
    const res = await service.actualizar(primero.id, 'Renombrado');
    expect(res.ok).toBeTruthy();
    expect(service.parametros()[0].nombre).toBe('Renombrado');
  });

  it('debería eliminar un parámetro', async () => {
    await service.cargar('u1');
    const antes = service.parametros().length;
    const primero = service.parametros()[0];
    await service.eliminar(primero.id);
    expect(service.parametros().length).toBe(antes - 1);
  });
});
