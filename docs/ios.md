# App iOS (IPA) con Capacitor

La app web Angular se empaqueta como app iOS nativa con Capacitor. El mismo codigo sirve para la web y para iOS; no se publica en la App Store, se instala localmente.

## Requisitos

- macOS con Xcode instalado (App Store, gratis). Solo las Command Line Tools no bastan.
- CocoaPods (ya instalado via Homebrew: brew install cocoapods).
- Node.js + npm (ya presentes).
- Cuenta Apple ID (gratis) para firmar y probar en tu iPhone; para un IPA compartible y durable se necesita cuenta de desarrollador de pago (99 USD/ano).
## Estructura anadida

- capacitor.config.ts - config de Capacitor (appId: com.alarconosorio.gastos, webDir: dist/crud-usuarios/browser).
- ios/ - proyecto Xcode generado (SPM).
- Scripts npm: cap:sync (build + sync) y cap:ios (build + sync + abrir Xcode).

## Flujo de desarrollo

1. Hacer cambios en la app web (Angular).
2. Construir y sincronizar:
   npm run cap:sync
3. Abrir en Xcode:
   npm run cap:ios

## Probar en tu iPhone (gratis, sin IPA)

1. Instala Xcode desde la App Store y abrelo una vez para que instale componentes.
2. Conecta el iPhone por cable y confia en el equipo.
3. En Xcode: selecciona el target App -> Signing & Capabilities -> Team: elige tu Apple ID personal.
4. Selecciona tu iPhone como destino y pulsa Run.
5. En el iPhone: Ajustes -> General -> Gestion de VPN y dispositivo / Perfiles -> confia en el desarrollador.
6. La app se instala y ejecuta. Con cuenta gratuita caduca a los 7 dias; vuelve a ejecutar para re-firmar.


## Generar un IPA (archivo instalable)

### Opcion A - Gratis (7 dias, con AltStore/Sideloadly)

1. En Xcode: Product -> Archive.
2. En el Organizer: Distribute App -> Development -> exporta el .ipa.
3. Instala el IPA en el iPhone con AltStore o Sideloadly usando tu Apple ID. Re-firma cada 7 dias.

### Opcion B - Cuenta de desarrollador de pago (recomendada para IPA durable)

1. Registra los UDID de los dispositivos en el portal de desarrollador.
2. Crea un perfil de aprovisionamiento Ad Hoc.
3. En Xcode: Product -> Archive -> Distribute App -> Ad Hoc -> exporta el .ipa.
4. Instala el IPA con Apple Configurator, Finder o MDM. Valido 1 ano, hasta 100 dispositivos.

### Opcion C - TestFlight (interno)

Requiere cuenta de pago. Sube el archive a App Store Connect y anade testers internos (hasta 100) mediante TestFlight.


## Notas

- La web sigue funcionando igual: npm start / ng build no se ven afectados.
- Supabase usa localStorage; el WebView de Capacitor lo soporta.
- Deep links/OAuth no se usan (login con email y contrasena), por lo que no hace falta configurar esquemas de URL.
- El warning de dashboard.css (8.55 kB vs 8 kB) no afecta a la app iOS.

## Solucion de problemas

- Xcode requires a developer team: anade tu Apple ID en Xcode -> Settings -> Accounts.
- Unable to install untrusted developer: confia en el desarrollador en Ajustes del iPhone.
- Pantalla en blanco: asegurate de haber ejecutado npm run cap:sync tras el ultimo build; revisa la consola de Xcode.
