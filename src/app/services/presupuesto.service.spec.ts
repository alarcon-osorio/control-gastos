import { TestBed } from '@angular/core/testing';
import { AuthService } from './auth.service';
import { GastosService } from './gastos.service';
import { PresupuestoService } from './presupuesto.service';

/** Devuelve 'YYYY-MM-DD' para el día dado dentro del mes actual. */
function fechaMesActual(dia: number): string {
  const hoy = new Date();
  return `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(dia).padStart(2, '0')}`;
}

describe('PresupuestoService', () => {
  let service: PresupuestoService;

  // Estado mutable que comparten el test y los mocks.
  let usuarioActual: { id: string; nombre: string; email: string } | null;
  let gastos: { usuarioId: string; fecha: string; monto: string }[];

  const authMock = {
    usuario: () => usuarioActual,
    autenticado: () => usuarioActual !== null,
  };

  const gastosMock = {
    gastosPorUsuario: (usuarioId: string) => gastos.filter((g) => g.usuarioId === usuarioId),
    totalPorCategoria: () => () => new Map<string, number>(),
  };

  beforeEach(() => {
    localStorage.clear();
    usuarioActual = { id: 'u-1', nombre: 'Test', email: 'test@test.com' };
    gastos = [
      { usuarioId: 'u-1', fecha: fechaMesActual(1), monto: '100000' },
      { usuarioId: 'u-1', fecha: fechaMesActual(10), monto: '50000' },
      { usuarioId: 'u-otro', fecha: fechaMesActual(5), monto: '9999999' }, // otro usuario
    ];

    TestBed.configureTestingModule({
      providers: [
        PresupuestoService,
        { provide: AuthService, useValue: authMock },
        { provide: GastosService, useValue: gastosMock },
      ],
    });
    service = TestBed.inject(PresupuestoService);
  });

  afterEach(() => {
    localStorage.clear();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('debería comenzar con presupuesto 0', () => {
    expect(service.presupuesto()).toBe(0);
  });

  it('debería aplicar un presupuesto y persistirlo en localStorage', () => {
    service.setPresupuesto(500000);
    expect(service.presupuesto()).toBe(500000);
    expect(localStorage.getItem('gastos:presupuesto:u-1')).toBe('500000');
  });

  it('debería calcular el gasto del mes actual solo del usuario', () => {
    service.setPresupuesto(1000000);
    // 100000 + 50000 del usuario u-1; se ignoran los de u-otro.
    expect(service.gastoDelMes()).toBe(150000);
  });

  it('debería calcular el porcentaje consumido', () => {
    service.setPresupuesto(500000);
    expect(service.porcentaje()).toBe(30); // 150000 / 500000 = 30%
  });

  it('debería reportar estado excedido al superar el 100%', () => {
    // Primero agregamos gasto, luego cambiamos el presupuesto para que
    // las computeds se recalculen con los datos frescos.
    gastos.push({ usuarioId: 'u-1', fecha: fechaMesActual(15), monto: '350000' });

    service.setPresupuesto(500000);
    // 150000 + 350000 = 500000 → 100%.
    expect(service.porcentaje()).toBe(100);
    expect(service.estado()).toBe('excedido');
  });

  it('debería reportar estado cerca con el presupuesto casi agotado', () => {
    service.setPresupuesto(160000);
    // 150000 / 160000 = 93% (>= 80%).
    expect(service.estado()).toBe('cerca');
  });

  it('debería reportar estado sin-presupuesto con valor 0', () => {
    expect(service.estado()).toBe('sin-presupuesto');
    expect(service.porcentaje()).toBe(0);
  });

  it('debería devolver 0 cuando no hay usuario autenticado', () => {
    service.setPresupuesto(500000);
    usuarioActual = null;
    expect(service.gastoDelMes()).toBe(0);
    expect(service.porcentaje()).toBe(0);
  });
});
