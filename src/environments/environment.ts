// Credenciales de Supabase para DESARROLLO.
// Reemplaza los valores con los de tu proyecto (Settings → API).
// La "anon public key" es segura de exponer en el front; NUNCA uses la "service_role".
export const environment = {
  production: false,
  supabase: {
    url: 'https://yiftfshfetqtgscgvhbc.supabase.co',
    anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpZnRmc2hmZXRxdGdzY2d2aGJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5NDM1NTUsImV4cCI6MjEwNzUxOTU1NX0.jzOPCD_QcNxu5mdxkzQ7XXZsGBS6jqDj2dq0Vymf0q4',
  },
};
