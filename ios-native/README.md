# App nativa iOS (SwiftUI) - Gastos

Este folder contiene una base nativa en Swift para la app de gastos, reutilizando la misma base de datos Supabase de la app Angular.

## Paso 1: Crear el proyecto en Xcode
1. Abre Xcode → **Create New Project**.
2. Elige **App** (iOS) → Next.
3. Product Name: `Gastos`.
4. Interface: **SwiftUI**.
5. Language: **Swift**.
6. Minimum Deployment: iOS 16 (o superior).
7. Guarda el proyecto en `/Users/macbook/Documents/Desarrollos/Gastos/ios-native/`.

## Paso 2: Agregar dependencia de Supabase
1. En Xcode: **File → Add Package Dependencies...**
2. URL: `https://github.com/supabase/supabase-swift`
3. Agrega el paquete al target `Gastos`.

## Paso 3: Agregar los archivos Swift
1. Arrastra los archivos `.swift` de `ios-native/Gastos/` al grupo del proyecto en Xcode.
2. Asegúrate de marcar **"Copy items if needed"** y el target `Gastos`.

## Paso 4: Compilar y ejecutar
1. Selecciona un simulador (iPhone 15/16).
2. Presiona ▶ (Run).
3. Deberías ver la pantalla de Login. Prueba registro/inicio de sesión con tu usuario de Supabase.

## Siguientes pasos (roadmap)
1. **GastosService** (CRUD + listado) y vista de gastos.
2. **ParametrosService** (categorías/métodos).
3. **ObligacionesService** + checklist mensual.
4. **PresupuestoService** + configuración.
5. Dashboard con totales y gráficos.
6. Tasas/monedas (si aplica).

Los modelos y servicios se portarán desde `src/app/services/*.ts` y `src/app/models/*.ts`.

## Notas
- Las credenciales de Supabase ya están en `SupabaseClient.swift` (anon key, segura para cliente).
- La autenticación se restaura al abrir la app.
- Falta manejar cambios de sesión en tiempo real (onAuthStateChange) y cierre de sesión desde la UI.