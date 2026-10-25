import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { MultiSelect } from './multi-select';

@Component({
  template: `<app-multi-select
    [opciones]="opciones"
    [(value)]="seleccion"
  />`,
  imports: [MultiSelect],
})
class HostComponent {
  opciones = ['Masculino', 'Femenino', 'No binario', 'Otro'];
  seleccion = signal<string[]>([]);
}

describe('MultiSelect', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HostComponent],
    }).compileComponents();
  });

  it('should create', () => {
    const fixture = TestBed.createComponent(HostComponent);
    fixture.detectChanges();
    const ms = fixture.debugElement.children[0].componentInstance as MultiSelect;
    expect(ms).toBeTruthy();
  });

  it('debería alternar la selección de una opción', () => {
    const fixture = TestBed.createComponent(HostComponent);
    fixture.detectChanges();
    const host = fixture.componentInstance;
    const ms = fixture.debugElement.children[0].componentInstance as MultiSelect;

    ms.toggleOpcion('Femenino');
    expect(host.seleccion()).toEqual(['Femenino']);

    ms.toggleOpcion('No binario');
    expect(host.seleccion()).toEqual(['Femenino', 'No binario']);

    // Volver a pulsar la misma opción la quita.
    ms.toggleOpcion('Femenino');
    expect(host.seleccion()).toEqual(['No binario']);
  });

  it('debería reflejar el valor en la etiqueta', () => {
    const fixture = TestBed.createComponent(HostComponent);
    fixture.detectChanges();
    const host = fixture.componentInstance;
    const ms = fixture.debugElement.children[0].componentInstance as MultiSelect;

    expect(ms.etiqueta()).toBe('Selecciona...');
    host.seleccion.set(['Masculino', 'Otro']);
    fixture.detectChanges();
    expect(ms.etiqueta()).toBe('Masculino, Otro');
  });

  it('debería limpiar selecciones inválidas al cambiar las opciones', () => {
    const fixture = TestBed.createComponent(HostComponent);
    const host = fixture.componentInstance;
    host.seleccion.set(['Masculino', 'Inexistente']);
    fixture.detectChanges();

    expect(host.seleccion()).toEqual(['Masculino']);
  });
});
