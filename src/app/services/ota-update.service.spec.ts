import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import { OtaUpdateService } from './ota-update.service';

vi.mock('@capgo/capacitor-updater', () => ({
  CapacitorUpdater: {
    current: vi.fn(),
    download: vi.fn(),
    next: vi.fn(),
  },
}));

describe('OtaUpdateService', () => {
  let service: OtaUpdateService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [OtaUpdateService],
    });
    service = TestBed.inject(OtaUpdateService);
    vi.clearAllMocks();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('no descarga si la versión es la misma', async () => {
    const { CapacitorUpdater } = await import('@capgo/capacitor-updater');
    (CapacitorUpdater.current as ReturnType<typeof vi.fn>).mockResolvedValue({
      bundle: { version: '1.0.0' },
    });
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ version: '1.0.0', url: 'https://x/bundle.zip' }),
    }) as unknown as typeof fetch;

    await service.checkForUpdate();

    expect(CapacitorUpdater.download).not.toHaveBeenCalled();
    expect(CapacitorUpdater.next).not.toHaveBeenCalled();
  });

  it('descarga y marca como next si hay versión nueva', async () => {
    const { CapacitorUpdater } = await import('@capgo/capacitor-updater');
    (CapacitorUpdater.current as ReturnType<typeof vi.fn>).mockResolvedValue({
      bundle: { version: '1.0.0' },
    });
    (CapacitorUpdater.download as ReturnType<typeof vi.fn>).mockResolvedValue({
      id: 'bundle-1',
    });
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ version: '1.0.1', url: 'https://x/bundle.zip' }),
    }) as unknown as typeof fetch;

    await service.checkForUpdate();

    expect(CapacitorUpdater.download).toHaveBeenCalledWith({
      url: 'https://x/bundle.zip',
      version: '1.0.1',
    });
    expect(CapacitorUpdater.next).toHaveBeenCalledWith({ id: 'bundle-1' });
  });

  it('no falla si el manifest no responde', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: false,
    }) as unknown as typeof fetch;

    await expect(service.checkForUpdate()).resolves.toBeUndefined();
  });

  it('no falla si fetch lanza error', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new Error('network')) as unknown as typeof fetch;

    await expect(service.checkForUpdate()).resolves.toBeUndefined();
  });
});