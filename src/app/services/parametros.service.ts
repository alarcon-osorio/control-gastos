import { Injectable, inject, signal } from '@angular/core';
import { SupabaseClient } from '@supabase/supabase-js';
import { SUPABASE } from './supabase.client';
import { Parametro, ParametroInput, TipoParametro } from '../models/parametro';

/** Fila tal como la devuelve Supabase. */
interface ParametroRow {
  id: number;
  usuario_id: string;
  tipo: TipoParametro;
  nombre: string;
}

/** Valores que se crean automáticamente para un usuario nuevo. */
const VALORES_POR_DEFECTO: { tipo: TipoParametro; nombre: string }[] = [
  { tipo: 'categoria', nombre: 'Alimentación' },
  { tipo: 'categoria', nombre: 'Transporte' },
  { tipo: 'categoria', nombre: 'Vivienda' },
  { tipo: 'categoria', nombre: 'Salud' },
  { tipo: 'categoria', nombre: 'Ocio' },
  { tipo: 'categoria', nombre: 'Educación' },
  { tipo: 'categoria', nombre: 'Otros' },
  { tipo: 'metodoPago', nombre: 'Efectivo' },
  { tipo: 'metodoPago', nombre: 'Tarjeta de crédito' },
  { tipo: 'metodoPago', nombre: 'Tarjeta de débito' },
  { tipo: 'metodoPago', nombre: 'Transferencia' },
];

/**
 * Servicio de parámetros con Supabase.
 * Gestiona las categorías y métodos de pago de cada usuario.
 * Si el usuario no tiene parámetros, se le crean los valores por defecto.
 */
@Injectable({
  providedIn: 'root',
})
export class ParametrosService {
  private readonly supabase = inject(SUPABASE);
  private readonly parametrosSignal = signal<Parametro[]>([]);

  /** Todos los parámetros del usuario actual. */
  readonly parametros = this.parametrosSignal.asReadonly();

  /** Carga los parámetros del usuario; si no tiene, siembra los defectos. */
  async cargar(usuarioId: string): Promise<void> {
    const { data, error } = await this.supabase
      .from('parametros')
      .select('*')
      .eq('usuario_id', usuarioId)
      .order('id', { ascending: true });
    if (error) {
      throw error;
    }
    let filas = (data ?? []) as ParametroRow[];
    if (filas.length === 0) {
      await this.sembrar(usuarioId);
      const { data: nuevos } = await this.supabase
        .from('parametros')
        .select('*')
        .eq('usuario_id', usuarioId)
        .order('id', { ascending: true });
      filas = (nuevos ?? []) as ParametroRow[];
    }
    this.parametrosSignal.set(filas.map((r) => this.mapear(r)));
  }

  /** Crea un nuevo parámetro. */
  async agregar(
    input: ParametroInput,
  ): Promise<{ ok: boolean; mensaje: string }> {
    const nombre = input.nombre.trim();
    if (!nombre) {
      return { ok: false, mensaje: 'El nombre no puede estar vacío.' };
    }
    const existe = this.parametrosSignal().some(
      (p) =>
        p.tipo === input.tipo &&
        p.nombre.toLowerCase() === nombre.toLowerCase(),
    );
    if (existe) {
      return { ok: false, mensaje: 'Ese valor ya existe.' };
    }
    const { data, error } = await this.supabase
      .from('parametros')
      .insert({
        usuario_id: input.usuarioId,
        tipo: input.tipo,
        nombre,
      })
      .select()
      .single();
    if (error) {
      throw error;
    }
    this.parametrosSignal.update((lista) => [
      ...lista,
      this.mapear(data as ParametroRow),
    ]);
    return { ok: true, mensaje: 'Agregado correctamente.' };
  }

  /** Actualiza el nombre de un parámetro. */
  async actualizar(
    id: number,
    nombre: string,
  ): Promise<{ ok: boolean; mensaje: string }> {
    const limpio = nombre.trim();
    if (!limpio) {
      return { ok: false, mensaje: 'El nombre no puede estar vacío.' };
    }
    const actual = this.parametrosSignal().find((p) => p.id === id);
    if (
      actual &&
      this.parametrosSignal().some(
        (p) =>
          p.id !== id &&
          p.tipo === actual.tipo &&
          p.nombre.toLowerCase() === limpio.toLowerCase(),
      )
    ) {
      return { ok: false, mensaje: 'Ese valor ya existe.' };
    }
    const { error } = await this.supabase
      .from('parametros')
      .update({ nombre: limpio })
      .eq('id', id);
    if (error) {
      throw error;
    }
    this.parametrosSignal.update((lista) =>
      lista.map((p) => (p.id === id ? { ...p, nombre: limpio } : p)),
    );
    return { ok: true, mensaje: 'Actualizado correctamente.' };
  }

  /** Elimina un parámetro por id. */
  async eliminar(id: number): Promise<void> {
    const { error } = await this.supabase.from('parametros').delete().eq('id', id);
    if (error) {
      throw error;
    }
    this.parametrosSignal.update((lista) => lista.filter((p) => p.id !== id));
  }

  /** Devuelve los nombres de los parámetros de un tipo concreto. */
  nombresPorTipo(tipo: TipoParametro): string[] {
    return this.parametrosSignal()
      .filter((p) => p.tipo === tipo)
      .map((p) => p.nombre);
  }

  /** Inserta los valores por defecto para un usuario nuevo. */
  private async sembrar(usuarioId: string): Promise<void> {
    const filas = VALORES_POR_DEFECTO.map((v) => ({
      usuario_id: usuarioId,
      tipo: v.tipo,
      nombre: v.nombre,
    }));
    await this.supabase.from('parametros').insert(filas);
  }

  private mapear(r: ParametroRow): Parametro {
    return {
      id: r.id,
      usuarioId: r.usuario_id,
      tipo: r.tipo,
      nombre: r.nombre,
    };
  }
}

