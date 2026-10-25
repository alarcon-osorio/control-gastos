// Credenciales de Supabase para PRODUCCIÓN.
// En un proyecto real, estos valores se inyectan en el pipeline de build
// (variables de entorno) y no se versionan. Aquí se dejan placeholders.
export const environment = {
  production: true,
  supabase: {
    url: 'PEGA_AQUI_TU_PROJECT_URL',
    anonKey: 'PEGA_AQUI_TU_ANON_PUBLIC_KEY',
  },
};
