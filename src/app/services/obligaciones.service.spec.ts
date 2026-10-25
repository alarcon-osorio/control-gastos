import { TestBed } from '@angular/core/testing';
import { SUPABASE } from './supabase.client';
import { crearSupabaseMock } from '../../testing/supabase-mock';
import { GastosService } from './gastos.service';
import { ObligacionesService } from './obligaciones.service';

describe('ObligacionesService (Supabase mock)', () => {
  let service: ObligacionesService;
  let mock: ReturnType<typeof crearSupabaseMock>;

  beforeEach(() => {
    mock = crearSupabaseMock();
    TestBed.configureTestingModule({
      providers: [{ provide: SUPABASE, useValue: mock.client }],
    });
    service = TestBed.inject(ObligacionesService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('debería sembrar las obligaciones iniciales en la primera carga', async () => {
    await service.cargar('u1');
    // 15 obligaciones del iCloud.
    expect(service.obligaciones().length).toBe(15);
    expect(service.obligaciones().some((o) => o.nombre === 'Volleyball')).toBe(true);
  });

  it('debería agrupar por día 10, 25 y hormigas', async () => {
    await service.cargar('u1');
    const grupos = service.porGrupo();
    expect(grupos.dia10.length).toBe(7);
    expect(grupos.dia25.length).toBe(6);
    expect(grupos.hormigas.length).toBe(2);
  });

  it('debería calcular el total esperado del mes', async () => {
    await service.cargar('u1');
    // Suma de las 15 obligaciones sembradas.
    const total = 270000 + 600000 + 300000 + 1000000 + 80000 + 70000 + 220000 +
      2300000 + 1700000 + 22000 + 200000 + 600000 + 400000 + 20000 + 100000;
    expect(service.totalEsperadoMes()).toBe(total);
  });

  it('marcarPagada debería crear un gasto y registrar el pago', async () => {
    await service.cargar('u1');
    const gastos = TestBed.inject(GastosService);
    // Usa una obligación real del catálogo sembrado (Mercado del día 10).
    const mercado = service.obligaciones().find((o) => o.nombre === 'Mercado' && o.diaPago === 10)!;
    await service.marcarPagada(mercado, '2026-10');

    expect(service.estaPagada(mercado.id, '2026-10')).toBe(true);
    expect(gastos.gastos().length).toBe(1);
    expect(gastos.gastos()[0].monto).toBe(600000);
    expect(gastos.gastos()[0].descripcion).toBe('Mercado');
    expect(gastos.gastos()[0].fecha).toBe('2026-10-10');
    expect(service.totalPagadoMes()('2026-10')).toBe(600000);
  });

  it('desmarcar debería eliminar el pago y su gasto asociado', async () => {
    await service.cargar('u1');
    const gastos = TestBed.inject(GastosService);
    const mercado = service.obligaciones().find((o) => o.nombre === 'Mercado' && o.diaPago === 10)!;
    await service.marcarPagada(mercado, '2026-10');
    await service.desmarcar(mercado.id, '2026-10');

    expect(service.estaPagada(mercado.id, '2026-10')).toBe(false);
    expect(gastos.gastos().length).toBe(0);
    expect(service.totalPagadoMes()('2026-10')).toBe(0);
  });

  it('debería agregar una obligación al catálogo', async () => {
    await service.cargar('u1');
    const antes = service.obligaciones().length;
    await service.agregar({
      usuarioId: 'u1',
      nombre: 'Internet',
      monto: 90000,
      diaPago: 25,
      categoria: 'Servicios',
      activa: true,
    });
    expect(service.obligaciones().length).toBe(antes + 1);
    expect(service.porGrupo().dia25.some((o) => o.nombre === 'Internet')).toBe(true);
  });

  it('debería eliminar una obligación', async () => {
    await service.cargar('u1');
    const id = service.obligaciones()[0].id;
    const antes = service.obligaciones().length;
    await service.eliminar(id);
    expect(service.obligaciones().length).toBe(antes - 1);
  });
});