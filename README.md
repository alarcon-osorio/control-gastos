# Gestión de Gastos

Aplicación Angular 22 para control de gastos, con autenticación y datos en Supabase.

## Acceso con Passkeys (Face ID / Touch ID)

El login incorpora Passkeys mediante WebAuthn y Supabase Auth. En dispositivos Apple compatibles, el navegador puede solicitar Face ID o Touch ID; según el dispositivo y el gestor de credenciales también puede solicitar el código de desbloqueo o una llave de seguridad. La aplicación no captura ni almacena datos biométricos.

### Configuración obligatoria en Supabase

1. Abre **Supabase Dashboard → Authentication → Passkeys**.
2. Activa **Enable Passkey authentication**.
3. Configura:
   - **Relying Party Display Name:** Gestión de Gastos.
   - **Relying Party ID:** dominio base de producción, sin protocolo, ruta ni puerto.
   - **Relying Party Origins:** origen HTTPS exacto, por ejemplo `https://app.tudominio.com`.
4. Guarda los cambios. El dominio RP debe mantenerse estable; cambiarlo invalida las Passkeys registradas.
5. En Vercel, confirma que el dominio de producción usa HTTPS y coincide con el origen permitido en Supabase.

No configures un dominio temporal de Preview como RP definitivo si después vas a usar un dominio propio.

### Flujo de usuario

1. El usuario inicia sesión con correo y contraseña.
2. La aplicación ofrece registrar una Passkey en ese dispositivo.
3. En siguientes visitas puede seleccionar **Entrar con Face ID / Passkey**.
4. Supabase Auth valida el desafío WebAuthn y crea la sesión normal de Supabase.
5. El acceso tradicional con contraseña sigue disponible.

Supabase Auth gestiona desafíos, credenciales y verificación. No se crea una tabla propia de biometría ni se requiere una Edge Function personalizada para este flujo.

**Nota:** Passkeys en supabase-js es una función experimental y su API puede cambiar. El proyecto ya usa una versión del SDK que cumple el requisito mínimo documentado (v2.105.0 o posterior). Consulta la guía oficial antes de actualizar el SDK: https://supabase.com/docs/guides/auth/passkeys

## Desarrollo

```bash
npm install
ng serve
```

## Build y pruebas

```bash
npm run build
npm test
```
