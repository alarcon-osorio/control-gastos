# CI/CD, calidad y seguridad

## Workflows
- `.github/workflows/ci.yml`: se ejecuta en `push` y `pull_request` a `main`.
  - Job `ci`: instala dependencias (`npm ci`), ejecuta `npm audit` (informativo), tests (`npm run test -- --watch=false`) y build de producción.
  - Job `sonar`: análisis en SonarCloud con `SONAR_TOKEN` y Quality Gate bloqueante (`sonar.qualitygate.wait=true`).
- `.github/workflows/veracode.yml`: integración opcional, **desactivada por defecto** (solo `workflow_dispatch` y requiere secretos).

## Secretos y variables de GitHub (Settings → Secrets and variables → Actions)

Secrets:
- `SONAR_TOKEN`: token de SonarCloud (My Account → Security). **Pendiente de añadir en GitHub** (ya lo generaste en SonarCloud).
- `VERACODE_API_ID` / `VERACODE_API_KEY`: solo si tienes licencia Veracode.

Variables:
- `SONAR_ORGANIZATION` / `SONAR_PROJECT_KEY`: ya configuradas directamente en `sonar-project.properties` (`alarcon-osorio` / `alarcon-osorio_control-gastos`), por lo que no es necesario definirlas como variables de GitHub.

## Pasos en SonarCloud
1. Importa el repositorio de GitHub en SonarCloud (organization `alarcon-osorio`, project `alarcon-osorio_control-gastos`).
2. Los identificadores ya están en `sonar-project.properties`; no necesitas variables de GitHub.
3. Añade el `SONAR_TOKEN` que generaste como secreto en GitHub (Settings → Secrets → Actions).
4. Quality Gate: Project → Quality Gates → asigna "Sonar way" (o uno custom). El CI falla si no pasa.

## Pasos en Veracode (solo con licencia)
1. Crea credenciales API en Veracode.
2. Añádelas como secretos en GitHub.
3. Ejecuta el workflow manualmente desde Actions.

## Validación local
- `npm test` → 64/64 OK
- `npm run build` → OK (warning: `dashboard.css` 8.55 kB > 8 kB, no bloqueante)
- `npm audit` → 8 vulnerabilidades en dependencias de desarrollo (`fast-uri`, `undici`, `vite`, `zod`); corregibles con `npm audit fix` (pendiente de aprobación).

## Limitaciones del plan gratuito
- SonarCloud: gratis e ilimitado en repos públicos; en privados, límite de LOC (~50k) y funciones limitadas.
- GitHub Actions: 2000 min/mes en repos privados (públicos ilimitado).
- Veracode: requiere licencia comercial.
- `npm audit` es SCA básico, no SAST/DAST completo.

## Notas
- La anon key de Supabase se mantiene en `src/environments/*.ts` (es pública por diseño).
- No se despliega automáticamente; el despliegue requiere autorización manual.
