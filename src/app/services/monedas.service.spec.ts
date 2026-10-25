import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { MonedasService } from './monedas.service';
import { TasasService } from './tasas.service';

describe('MonedasService', () => {
  let service: MonedasService;

  // Mock de TasasService con tasas conocidas (sin HTTP).
  const tasasMock = {
    tasas: signal<Record<string, number>>({ COP: 1, USD: 4000, EUR: 4300 }),
    sonReales: signal(false),
    cargando: signal(false),
    error: signal(''),
    ultimaActualizacion: signal<Date | null>(null),
    origen: signal('Tasas de referencia'),
    actualizar: () => Promise.resolve(),
  };

  beforeEach(() => {
    localStorage.clear();
    // Reseteamos el mock de tasas a valores conocidos en cada test.
    tasasMock.tasas.set({ COP: 1, USD: 4000, EUR: 4300 });
    TestBed.configureTestingModule({
      providers: [{ provide: TasasService, useValue: tasasMock }],
    });
    service = TestBed.inject(MonedasService);
  });

  afterEach(() => localStorage.clear());

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('debería tener COP como moneda por defecto', () => {
    expect(service.moneda().codigo).toBe('COP');
  });

  it('debería ofrecer EUR, USD y COP', () => {
    const codigos = service.disponibles.map((m) => m.codigo);
    expect(codigos).toEqual(['COP', 'USD', 'EUR']);
  });

  it('debería cambiar la moneda y reflejarlo', () => {
    service.setMoneda('USD');
    expect(service.moneda().codigo).toBe('USD');
    service.setMoneda('EUR');
    expect(service.moneda().codigo).toBe('EUR');
  });

  it('debería ignorar códigos inválidos', () => {
    service.setMoneda('JPY');
    expect(service.moneda().codigo).toBe('COP');
  });

  it('debería persistir la moneda elegida', () => {
    service.setMoneda('EUR');
    // Un nuevo servicio (mismo TestBed) lee de localStorage.
    const otro = TestBed.inject(MonedasService);
    expect(otro.moneda().codigo).toBe('EUR');
  });

  it('debería formatear montos según la moneda', () => {
    service.setMoneda('COP');
    expect(service.formatear(1500)).not.toContain(',00');
    service.setMoneda('EUR');
    expect(service.formatear(1500)).toContain('€');
  });

  it('debería convertir de COP a otras monedas', () => {
    expect(service.desdeCOP(4000, 'USD')).toBe(1);
    expect(service.desdeCOP(4300, 'EUR')).toBe(1);
    expect(service.desdeCOP(8000, 'USD')).toBe(2);
  });

  it('debería convertir de otras monedas a COP', () => {
    expect(service.aCOP(1, 'USD')).toBe(4000);
    expect(service.aCOP(1, 'EUR')).toBe(4300);
    expect(service.aCOP(5, 'USD')).toBe(20000);
  });

  it('debería convertir entre dos monedas vía COP', () => {
    expect(service.convertir(1, 'USD', 'COP')).toBe(4000);
    const eur = service.convertir(4000, 'COP', 'EUR');
    expect(eur).toBeCloseTo(0.93, 2);
  });

  it('debería reaccionar a cambios en las tasas', () => {
    // Cambiamos la tasa USD a 5000 en el mock.
    tasasMock.tasas.set({ COP: 1, USD: 5000, EUR: 4300 });
    expect(service.desdeCOP(5000, 'USD')).toBe(1);
  });

  it('debería formatear desde COP en la moneda activa', () => {
    service.setMoneda('USD');
    expect(service.formatearDesdeCOP(8000)).toContain('2');
  });

  it('debería devolver equivalencias en las tres monedas', () => {
    const eqs = service.equivalentes(4300);
    expect(eqs.length).toBe(3);
    expect(eqs.map((e) => e.codigo)).toEqual(['COP', 'USD', 'EUR']);
  });
});

