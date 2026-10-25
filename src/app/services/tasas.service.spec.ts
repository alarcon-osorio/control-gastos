import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { TasasService, TASAS_FALLBACK } from './tasas.service';

describe('TasasService', () => {
  let service: TasasService;
  let httpMock: HttpTestingController;

  const URL = 'open.er-api.com';

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(TasasService);
    httpMock = TestBed.inject(HttpTestingController);
    // El constructor dispara una petición: la resolvemos y esperamos a que
    // se aplique (microtasks) para que los tests partan de un estado estable.
    const inicial = httpMock.expectOne((r) => r.url.includes(URL));
    inicial.flush({ rates: { COP: 4100, EUR: 0.92 } });
    await Promise.resolve();
    await Promise.resolve();
  });

  afterEach(() => {
    httpMock.match(() => true).forEach((r) => r.flush({ rates: { COP: 4000, EUR: 0.9 } }));
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('debería exponer tasas con la estructura esperada', () => {
    const tasas = service.tasas();
    expect(tasas['COP']).toBe(1);
    expect(tasas['USD']).toBeGreaterThan(0);
    expect(tasas['EUR']).toBeGreaterThan(0);
  });

  it('debería marcar las tasas como reales tras resolver la API', () => {
    expect(service.sonReales()).toBeTruthy();
    expect(service.tasas()['USD']).toBe(4100);
    expect(service.tasas()['EUR']).toBeCloseTo(0.92 * 4100, 0);
  });

  it('debería usar fallback si la API falla', async () => {
    const promesa = service.actualizar();
    const req = httpMock.expectOne((r) => r.url.includes(URL));
    req.error(new ProgressEvent('network error'));
    await promesa;

    expect(service.tasas()['USD']).toBe(TASAS_FALLBACK['USD']);
    expect(service.sonReales()).toBeFalsy();
    expect(service.error()).toContain('referencia');
  });
});


