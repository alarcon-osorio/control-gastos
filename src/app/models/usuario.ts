export interface Usuario {
  /** uuid provisto por Supabase Auth. */
  id: string;
  nombre: string;
  email: string;
  fechaRegistro?: string;
}

/** Datos necesarios para registrar un usuario (incluye la contraseña). */
export interface UsuarioInput {
  nombre: string;
  email: string;
  password: string;
}

/** Credenciales para iniciar sesión. */
export interface Credenciales {
  email: string;
  password: string;
}

