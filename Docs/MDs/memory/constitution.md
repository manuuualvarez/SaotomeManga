# Constitution — Proyecto "Mis Mangas" (versión Premium / Deluxe+)

> Documento de gobernanza del proyecto conforme a **Spec-Kit** (`/speckit.constitution`).
> Es la **fuente de verdad** de principios no negociables. Toda `spec.md`, `plan.md` y `tasks.md`
> de cualquier fase debe ser consistente con este documento. Ante conflicto, **gana la constitución**.
>
> - **Versión:** 1.1.0
> - **Ratificada:** 2026-07-16
> - **Ámbito:** app nativa Apple multiplataforma (iOS, iPadOS, visionOS) + Widget.
> - **Idioma del proyecto:** prosa en español; identificadores, símbolos, requisitos (`FR-###`),
>   historias (`US-###`) y tareas (`T###`) en inglés.

---

## 0. Propósito

"Mis Mangas" permite explorar un catálogo remoto de +64.000 mangas y gestionar la colección
personal del usuario (tomos comprados, tomo en lectura, colección completa), con sincronización
en la nube autenticada, persistencia local y experiencias específicas por plataforma.

El objetivo de esta constitución es garantizar que el proyecto se construya de forma **incremental,
verificable y estable**, fase a fase, mediante **Spec-Driven Development (SDD)** apoyado en **TDD**.

---

## 1. Principios de arquitectura (no negociables)

### P1 — Separación estricta por capas
La app se organiza en capas con dependencias unidireccionales (de arriba hacia abajo):

```
Presentation (SwiftUI Views + Observable state)
        │
Application (Use cases / Stores / ViewModels @Observable)
        │
Domain (Modelos puros, protocolos, errores — sin dependencias de framework)
        │
Infrastructure (Networking, Keychain, SwiftData, Widget bridge)
```

- El **Domain** no importa `SwiftUI`, `SwiftData`, `URLSession` ni `Security`. Es puro y 100% testeable.
- La **Infrastructure** implementa protocolos definidos en Domain/Application (inversión de dependencias).
- La **Presentation** nunca llama a `URLSession`/`Keychain`/red directamente: siempre a través de un caso de uso.

### P2 — Inversión de dependencias por protocolo
Todo acceso a un recurso externo (API, Keychain, persistencia, reloj/fecha, notificaciones) se expone
mediante un **protocolo** definido en la capa que lo consume, con al menos dos implementaciones:
la real y una **de test (fake/mock/stub)**. Prohibido acoplar la lógica de negocio a un tipo concreto de framework.

### P3 — Estado observable moderno
El estado de UI se modela con `@Observable` (Observation framework) y se inyecta con `@Environment`
o inicializadores explícitos. No se usa `ObservableObject`/`@Published` salvo justificación documentada.

---

## 2. Concurrencia (Swift 6.2, obligatorio)

Estos ajustes son **requisitos de compilación** y se validan en la Fase 01:

- **Swift Language Mode 6** (`SWIFT_VERSION = 6.2`, modo de lenguaje 6).
- **Strict Concurrency Checking = Complete** (concurrencia estricta total, sin excepciones por target).
- **Approachable Concurrency = YES** (`SWIFT_APPROACHABLE_CONCURRENCY`), con las _upcoming/experimental features_
  asociadas activadas (p. ej. `NonisolatedNonsendingByDefault`, `InferSendableFromCaptures`).
- **`nonisolated` por defecto**: el código no pertenece al `@MainActor` salvo que lo necesite.
  El aislamiento al `MainActor` se declara **explícitamente** solo donde toca UI o estado de UI.
- Cero warnings en el build final de cada fase (warnings-as-errors en CI).

**Reglas prácticas**
- Los modelos de Domain son `Sendable` (idealmente `struct`/`enum` de valor), los `struct`/`enum`  son Sendable por naturaleza, no aplicarle explicitamente el : Sendable.
- Los `actor` se usan solo para estado mutable compartido con contención real (p. ej. caché, token store).
- Trabajo de red/CPU fuera del `MainActor`; solo el salto final a UI va en `@MainActor`.
- Prohibido `@unchecked Sendable`, `nonisolated(unsafe)` y `@preconcurrency` salvo excepción aprobada
  y documentada en el `plan.md` de la fase, con issue de seguimiento para eliminarla. En caso de uso, verificar en la documentación de apple de que realmente es thread safe, como por ejemplo el UserDefaults que esta documentado por Apple.

---

## 3. Persistencia (SwiftData, obligatorio)

- La persistencia local es **SwiftData** (`@Model`, `ModelContainer`, `ModelContext`).
- Los `@Model` viven en Infrastructure y **no** se exponen a Presentation; se mapean a/desde modelos de Domain.
- Un único `ModelContainer` por app; el acceso concurrente se realiza con `ModelActor` cuando se escribe fuera del `MainActor`.
- Las migraciones se gestionan con `VersionedSchema` + `SchemaMigrationPlan` desde el primer día
  (aunque el esquema v1 sea trivial), para no romper datos de usuario en fases posteriores.
- La nube (API) es la **fuente de verdad** de la colección del usuario (versión avanzada+); SwiftData es caché local
  y soporte offline. La política de resolución de conflictos se define en la Fase 09.

---

## 4. Testing y TDD (obligatorio)

### P4 — Test-first
Ninguna tarea de lógica se implementa sin un test que falle primero. El ciclo por tarea es **Red → Green → Refactor**:
1. **Red:** escribir el/los test(s) que expresen el criterio de aceptación; deben fallar (o no compilar por API inexistente).
2. **Green:** implementar lo mínimo para que pasen.
3. **Refactor:** limpiar manteniendo verde.

### P5 — Framework de test
- Se usa **Swift Testing** (`import Testing`, `@Test`, `@Suite`, `#expect`, `#require`, parametrización con `arguments:`).
- **No** se usa XCTest salvo para pruebas de UI (`XCUITest`) donde Swift Testing aún no aplica; esa excepción se documenta.
- Los tests son deterministas: sin red real (se usan protocolos + fakes), sin dependencia de reloj del sistema
  (se inyecta un `Clock`/proveedor de fecha), sin orden implícito.

### P6 — Pirámide y cobertura
- **Unit** (mayoría): Domain y Application con fakes.
- **Contract**: decodificación de cada DTO contra JSON de ejemplo capturado del OpenAPI real (golden files).
- **Integration**: repositorios + SwiftData en contenedor en memoria (`isStoredInMemoryOnly: true`).
- **UI/E2E** (mínimos, flujos críticos): login, añadir a colección, ver colección, widget.
- Umbral de cobertura de las capas Domain+Application: **≥ 85%** por fase. Es un **gate**, no un adorno.

### P7 — Definition of Done (DoD) global
Una tarea/fase solo está **"Done"** si: (a) todos los tests verdes; (b) `swift build`/compilación sin
warnings (DE NINGUN TIPO, CUALQUIER WARNING DEBE SER TRATADO COMO ERROR); (c) cobertura cumplida; (d) linter sin errores; (e) criterios de aprobación
específicos de la tarea cumplidos y verificables; (f) documentación/artefacto actualizado.

---

## 5. Contratos de API (fuente única)

- El contrato es el **OpenAPI** publicado por el backend:
  `https://mymanga-acacademy-5607149ebe3d.herokuapp.com/openapi/openapi.json`.
- Cada fase que consuma endpoints referencia el contrato y **congela** ejemplos JSON reales en
  `specs/<fase>/contracts/` como _golden files_ para los contract tests.
- Cabecera obligatoria para registro de usuario: `App-Token: sLGH38NhEJ0_anlIWwhsz1-LarClEohiAHQqayF0FY`
  (se trata como secreto de configuración, no hardcodeado en código de dominio; ver Fase 01/04).
- Autenticación del proyecto: **sesión dual** — `access token` corto (~1h) + `refresh token` (~30 días).
  El refresh se guarda en Keychain; el access se mantiene en memoria y se renueva vía `/users/session/access`.

---

## 6. Seguridad y privacidad

- Credenciales y `refresh token` **siempre** en **Keychain** (`kSecClass...`), nunca en `UserDefaults`,
  SwiftData ni logs.
- No se registran (log) tokens, contraseñas, emails completos ni cabeceras `Authorization`.
- Comunicación solo HTTPS. Validación de formato de email y longitud de password (≥ 8) en cliente antes de llamar.
- El `App-Token` y URLs base viven en configuración (`.xcconfig`/`Info.plist` derivado), separables por entorno.

---

## 7. Multiplataforma y compartición de código

- Núcleo compartido (Domain, Application, Infrastructure) como **carpetas de código dentro del proyecto**,
  compartidas por *target membership* entre los targets que lo necesiten: app multiplataforma
  (iOS/iPadOS/visionOS) y Widget extension. **Prohibido usar Swift Packages locales**: Xcode Beta 27 no
  integra los test targets de paquetes locales referenciados desde un `.xcodeproj` (test plan vacío,
  invisibles en Edit Scheme), lo que rompe el gate de TDD. La separación por capas se garantiza por
  convención de carpetas y revisión (P1), no por fronteras de módulo.
- La UI se adapta por plataforma pero comparte modelos y casos de uso. Nada de lógica duplicada por target.
- El Widget y la app comparten datos mediante el **almacén de SwiftData en un contenedor de App Group**: al activar el
  entitlement de App Group, el store se propaga automáticamente a los targets, por lo que el widget consulta la **misma
  base de datos** que la app (solo lectura) sin copiar snapshots — definido en Fase 11 (config del `ModelContainer` en Fase 06).

---

## 8. Accesibilidad, localización y calidad de experiencia

- Accesibilidad es requisito, no extra: VoiceOver, Dynamic Type, contraste, `accessibilityLabel` en imágenes de portada.
- Textos de UI localizables desde el inicio (`String Catalog` / `.xcstrings`), idioma base español, segundo lenguaje Ingles.
- Estados de carga, vacío y error son de primera clase en cada pantalla (no pantallas en blanco).
- Imágenes de portada: carga asíncrona, placeholder, caché y cancelación al hacer scroll.

---

## 9. Proceso Spec-Driven (cómo se ejecuta cada fase)

Cada **fase** del roadmap es una unidad entregable con su propio artefacto (`PHASE-XX-*.md`) que contiene
tres secciones alineadas con Spec-Kit: **SPEC** (qué y por qué), **PLAN** (cómo, técnico) y **TASKS**
(lista ordenada y verificable). El flujo por fase con Claude Code:

1. `/speckit.specify` ← sección SPEC de la fase.
2. `/speckit.clarify` ← resolver `[NEEDS CLARIFICATION]` si los hubiera.
3. `/speckit.plan` ← sección PLAN.
4. `/speckit.tasks` ← sección TASKS.
5. `/speckit.analyze` ← chequeo de coherencia entre spec/plan/tasks y contra esta constitución.
6. `/speckit.implement` ← ejecución TDD tarea a tarea.

**Gate de fase:** una fase no se cierra hasta pasar su _checklist de validación_ (ver artefacto de la fase y roadmap).
La siguiente fase no arranca hasta que la anterior esté en verde, salvo dependencias explícitamente marcadas como paralelizables.

---

## 10. Estrategia de contexto (limpio vs anidado)

Para ejecutar con Claude Code de forma eficiente, cada **sub-fase/tarea** declara su estrategia de contexto:

- **🧹 Contexto limpio (`CLEAN`)**: la tarea se aborda en una sesión nueva, cargando solo la constitución,
  el artefacto de su fase y los contratos necesarios. Se usa cuando la tarea es autocontenida y el contexto
  acumulado no aporta (reduce ruido, coste y riesgo de alucinación).
- **🪆 Contexto anidado (`NESTED`)**: la tarea continúa en la misma sesión que la anterior, reutilizando el
  contexto ya cargado. Se usa cuando la tarea depende fuertemente de decisiones/artefactos recién creados
  y volver a cargarlos sería ineficiente o ambiguo.

Cada tarea del roadmap lleva una etiqueta `CLEAN` o `NESTED` con su justificación. Regla general:
límites de módulo/capa ⇒ `CLEAN`; iteración fina dentro del mismo tipo/archivo ⇒ `NESTED`.

---

## 11. Enmiendas

Cambios a esta constitución requieren: (a) versión SemVer incrementada, (b) nota de cambio con fecha,
(c) revisión de impacto en fases abiertas. Cambios que relajen P2, P4 o el bloque de concurrencia (§2)
se consideran **mayores** (bump MAJOR).

### Historial
- **1.1.0 (2026-07-18):** enmienda de §7 — el núcleo compartido pasa de Swift Package local a carpetas de
  código con target membership; se prohíben los Swift Packages locales por incompatibilidad de sus test
  targets con Xcode Beta 27. Cambio MINOR (no relaja P2, P4 ni §2).
- **1.0.0 (2026-07-16):** ratificación inicial.
