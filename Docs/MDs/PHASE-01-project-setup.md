# FASE 01 — Setup de proyecto y tooling

- **Versión objetivo:** Infraestructura · **Depende de:** Fase 00 (constitución)
- **Rama sugerida:** `001-project-setup`
- **Estado:** ✅ **Cerrada (2026-07-18)** — T001..T006 completas (T006 añadida a posteriori: mapa de carpetas + capa Presentation). Desviaciones documentadas: Widget diferido a Fase 11 (D-008); build de CI auto-desactivado hasta que los runners de GitHub traigan Xcode 27 (D-010).

> Objetivo: dejar el esqueleto compilando con Swift 6.2 en concurrencia estricta, el núcleo por capas
> compartido (carpetas, sin Swift Packages — constitución v1.1.0), el arnés de Swift Testing y la
> configuración/CI, de modo que todas las fases siguientes construyan sobre una base verificada.
> **Sin esta fase en verde no arranca ninguna otra.**

---

## SPEC — Qué y por qué

### Historias de usuario (de desarrollo)
- **US-001** — Como equipo, quiero un .xcodeproject multiplataforma (iOS/iPadOS/visionOS/Widget) con un
  núcleo por capas compartido vía target membership (sin Swift Packages), para no duplicar lógica entre targets.
- **US-002** — Como equipo, quiero que el proyecto imponga Swift 6 modo estricto + approachable concurrency,
  para detectar errores de concurrencia en compilación desde el día 1.
- **US-003** — Como equipo, quiero un arnés de Swift Testing y una CI que bloquee merges en rojo,
  para garantizar TDD real.

### Requisitos funcionales
- **FR-001** — Existen las **carpetas de capas** `Domain/`, `Application/`, `Infrastructure/` dentro del
  código de la app (crecerán en fases siguientes; aquí solo el esqueleto). **Sin Swift Packages**
  (constitución §7, v1.1.0); la capa se identifica por carpeta y se comparte por target membership.
- **FR-002** — Existen los targets: app multiplataforma `SaotomeManga` (iOS/iPadOS/visionOS, un único
  target con `SUPPORTED_PLATFORMS` y device families 1,2,7) y Widget extension (se crea en Xcode UI,
  a más tardar al abrir la Fase 11). Todos comparten el núcleo por target membership.
- **FR-003** — La configuración de build se define en `.xcconfig` por entorno (`Debug`, `Release`),
  incluyendo `API_BASE_URL` y `APP_TOKEN` como valores inyectables (no hardcodeados en Domain).
- **FR-004** — Un `@Test` "smoke" del núcleo compila y pasa en `SaotomeMangaTests` (`import Testing`).

### Requisitos no funcionales (heredados de la constitución)
- **NFR-001** — `SWIFT_VERSION` en modo lenguaje 6; **Strict Concurrency = Complete** en todos los targets.
- **NFR-002** — **Approachable Concurrency = YES** con las _upcoming features_ asociadas activadas.
- **NFR-003** — `nonisolated` por defecto (no `@MainActor` global implícito).
- **NFR-004** — CI ejecuta build + test en cada push; warnings de concurrencia = error.

### Fuera de alcance
Cualquier modelo de dominio real, red, persistencia o UI (se abordan en 02+). Aquí solo esqueleto y tooling.

---

## PLAN — Cómo (técnico)

- **Estructura de repositorio** (sin packages; capas como carpetas del target). **Mapa comprometido
  (01-T006):** las 4 capas de la constitución existen desde la Fase 01; los subfolders anotados con
  `F##` los crea esa fase al llegar — no se crean carpetas vacías por adelantado. Nota: Apple no
  publica una estructura oficial de carpetas; este mapa es el contrato del proyecto.
  ```
  SaotomeManga/                      (repo)
  ├── Docs/MDs/ · Docs/ADR/ · specs/<fase>/contracts/ (golden files, F02+)
  ├── Config/                        (xcconfig + App-Info.plist — 01-T004)
  ├── SaotomeManga/                  (target multiplataforma iOS/iPadOS/visionOS)
  │   ├── SaotomeMangaApp.swift      (entry point — raíz por convención)
  │   ├── Presentation/              (vistas SwiftUI + estado @Observable de UI)
  │   │   └── Auth/ F05 · Catalog/ F07 · Search/ F08 · Collection/ F09 · Shared/ F07+
  │   ├── Application/               (casos de uso, stores @Observable)
  │   │   └── UseCases/ F02+ · Stores/ F05+
  │   ├── Domain/                    (modelos puros, protocolos, errores — sin frameworks)
  │   │   └── Models/ F02 ✓ · Errors/ F02 ✓ · Validation/ F02 ✓ · Repositories/ F03
  │   ├── Infrastructure/            (implementaciones de protocolos)
  │   │   └── Configuration/ hoy · DTO/ F02 ✓ · Networking/ F03 · Security/ F04 · Persistence/ F06
  │   └── Assets.xcassets · Resources/ (String Catalog — F05/F07)
  ├── SaotomeMangaTests/             (Swift Testing; unit + contract + integration)
  ├── SaotomeMangaUITests/           (XCUITest)
  ├── MisMangasWidget/               (Widget extension — se crea a más tardar en Fase 11)
  ├── Scripts/git-hooks/ · .github/workflows/
  └── SaotomeManga.xcodeproj
  ```
  _Enmienda F02 (2026-07-18, D-017):_ se añaden `Domain/Validation/` (validadores puros) e
  `Infrastructure/DTO/` (wire-format + mapping); `Repositories/` se pospone de F02 a F03 — los
  protocolos de repositorio nacen con la capa de red. `✓` = subfolder ya creado por su fase.
- **Ajustes de compilación clave** (a fijar y verificar):
  `SWIFT_STRICT_CONCURRENCY = complete`, modo de lenguaje 6, `SWIFT_APPROACHABLE_CONCURRENCY = YES`,
  features experimentales/upcoming asociadas (`NonisolatedNonsendingByDefault`, `InferSendableFromCaptures`, etc.),
  `SWIFT_TREAT_WARNINGS_AS_ERRORS` en todos los targets.
- **Secretos/config:** `APP_TOKEN` y `API_BASE_URL` se leen de `Info.plist` (derivado de `.xcconfig`), expuestos
  vía un tipo `AppConfiguration` en Infrastructure. El valor real del `App-Token` no se comitea en claro (usar
  `.xcconfig` local ignorado en git + valor de ejemplo en `Shared.xcconfig`).
- **CI:** workflow (GitHub Actions o similar) que corre `xcodebuild build test` con destino simulador iOS;
  falla si hay warnings de concurrencia. (La CI es el único contexto donde se permite `xcodebuild`:
  el trabajo local va siempre por el MCP de Xcode — ver `CLAUDE.md`.)
- **Linter/format:** SwiftLint + SwiftFormat con reglas base; corren en CI y pre-commit.

### Decisiones abiertas
- Ninguna crítica. `[NEEDS CLARIFICATION]` opcional: proveedor de CI (GitHub Actions asumido).

### Registro de decisiones (2026-07-18)
- **D-001 — Compilación solo vía MCP de Xcode** (regla de proyecto en `CLAUDE.md`): `swift build`/`swift test`
  de CLI no se usan; el paquete se valida a través del esquema de Xcode una vez añadido al proyecto.
  El DoD de 01-T001 ("swift build/test OK") se satisface con `BuildProject`/`RunAllTests` del MCP.
- **D-002 — App target único multiplataforma**: el target `SaotomeManga` ya soporta iOS/iPadOS y visionOS
  (`SUPPORTED_PLATFORMS = iphoneos iphonesimulator xros xrsimulator`, device families 1,2,7). No se crean
  app targets separados salvo que una fase lo exija; el FR-002 queda cubierto por este target + el Widget
  (extensión pendiente de crear en Xcode UI, no es posible vía MCP).
- **D-003 — Limpieza de plantilla ejecutada** (parte de 01-T001): `Item.swift` eliminado;
  `SaotomeMangaApp`/`ContentView` reducidos a esqueleto sin SwiftData ni strings de UI; tests de plantilla
  sustituidos (unit vacío intencional; UI smoke de arranque). Build verde con 0 warnings (verificado vía MCP).
- ~~**D-004 — Paquete `MisMangasCore` creado**~~ **SUPERSEDIDA por D-006.**
- **D-006 (2026-07-18) — Abandono del Swift Package local.** Al integrar `Packages/MisMangasCore` como
  paquete local, Xcode Beta 27 no reconoce su test target: el esquema autogenerado del paquete tiene el
  test plan vacío, `MisMangasCoreTests` no aparece en Edit Scheme > Test > +, y un esquema compartido
  escrito a mano con la referencia es ignorado al construir. Sin tests ejecutables no hay TDD (P4), así
  que se pivota: **el núcleo vive como carpetas `Domain/`/`Application/`/`Infrastructure/` dentro del
  target de la app**, los smoke tests se mueven a `SaotomeMangaTests`, y la constitución se enmienda a
  **v1.1.0** (§7: prohibición de packages locales). El Widget compartirá el núcleo por target membership.
- **D-007 (2026-07-18) — Correcciones de configuración del proyecto** (ediciones quirúrgicas de
  `project.pbxproj`, verificadas con build+tests vía MCP): (a) bundle IDs malformados con punto doble
  (`cloud.manuelalvarez..X` → `cloud.manuelalvarez.X`) — impedían lanzar el host de unit tests en el
  simulador; (b) targets de test en `SWIFT_VERSION = 5.0` → `6.0` (NFR-001); (c) alta de
  `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` en todas las configuraciones (P7/gate). Resultado: 5/5 tests
  verdes, 0 warnings.
- **D-008 (2026-07-18) — Soporte visionOS en targets de test + Widget diferido.** Los targets de test
  no declaraban `SUPPORTED_PLATFORMS` (heredaban solo iOS) ni el device family 7, por lo que con destino
  visionOS no resolvían el módulo de la app. Con autorización del usuario se añadió
  `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator xros xrsimulator"` y `TARGETED_DEVICE_FAMILY = "1,2,7"`
  a las 4 configuraciones de test (edición de pbxproj autorizada). Verificado: 5/5 tests y 0 warnings en
  `Apple Vision Pro (27.0)`. La **Widget extension se difiere a la apertura de la Fase 11** (se creará en
  Xcode UI; el núcleo se compartirá por target membership).
- **D-009 (2026-07-18) — Cableado de configuración por entorno (edición de pbxproj autorizada).**
  `Config/{Shared,Debug,Release}.xcconfig` + `Secrets.xcconfig` (gitignored, App-Token real) +
  `Secrets.example.xcconfig` + `Config/App-Info.plist` parcial (claves `$(API_BASE_URL)`/`$(APP_TOKEN)`,
  fusionado con el Info.plist generado). En pbxproj: referencias de archivo + grupo `Config`,
  `baseConfigurationReference` en las configs Debug/Release del proyecto e
  `INFOPLIST_FILE = Config/App-Info.plist` en el target de app. Verificado en runtime vía snippet MCP.
- **Nota (2026-07-18):** el idioma base español (D-005) sigue pendiente; se abordará junto al String
  Catalog (primer string real de UI, fases 05/07 o 13). El proyecto ya conoce la región `es-419`.
- **D-010 (2026-07-18) — Build de CI en espera de Xcode 27 en runners.** Los runners `macos-26` de
  GitHub Actions traen como máximo Xcode 26.6, que no puede abrir el formato de proyecto de Xcode 27
  beta (objectVersion 110): "future Xcode project file format". El job de build detecta esta condición
  (`xcodebuild -list` falla) y se omite con un `::warning::`; **se reactiva solo** cuando el runner
  tenga Xcode 27. Mientras tanto: el lint es gate duro de CI (verificado en rojo con el PR #1) y el
  gate de build/tests/0-warnings corre localmente vía MCP. Repo: `manuuualvarez/SaotomeManga` (público);
  secreto `APP_TOKEN` inyectable vía GitHub Secrets si algún día CI necesita el valor real.
- **D-005 — Idioma base español pendiente**: `developmentRegion` del proyecto sigue en `en` y no hay
  String Catalog aún. Requiere cambio a nivel de proyecto (fuera del alcance del MCP) antes de crear
  `Localizable.xcstrings` con base `es` (necesario a más tardar en 01-T004/Fase 05).
- Crear `AGENTS.md` con los subagentes recomendados:
  - `swift-architect` (revisión de arquitectura).
  - `swift-testing-engineer` (cobertura y diseño de tests).
  - `swiftdata-specialist` (modelado y migraciones).
  - `swiftui-designer` (layout, HIG, a11y).


---

## TASKS — Ejecución (TDD, ordenada y verificable)

> Cada tarea: **Prerrequisito · Estrategia de contexto · Test-first · Tarea · Criterios de aprobación (DoD)**.

### ☑ 01-T001 — Adaptar Proyecto Xcode desde Plantilla + carpetas de núcleo + Preparación de Build ✅ 2026-07-18
- **Prerrequisito:** Fase 00 aprobada.
- **Contexto:** 🧹 `CLEAN` — arranque de repo, no hay contexto previo útil.
- **Test-first:** añadir `CoreSmokeTests` (en `SaotomeMangaTests`) con un `@Test func coreSkeletonBuilds()` que valide una constante de versión del núcleo (`CoreVersion.current`).
- **Tarea:** limpiar la plantilla de Xcode (Item/SwiftData/strings de UI) y crear las carpetas `Domain/`, `Application/`, `Infrastructure/` con su esqueleto dentro del target de la app.
- **DoD:** ☑ build OK vía MCP de Xcode · ☑ smoke tests verdes vía MCP (4/4 en `CoreSmokeTests`) · ☑ estructura de carpetas conforme al PLAN.

### ☑ 01-T002 — Fijar ajustes de concurrencia estricta (Swift 6.2) ✅ 2026-07-18
- **Prerrequisito:** 01-T001.
- **Contexto:** 🪆 `NESTED` — continúa sobre el esqueleto recién creado; iteración de build settings.
- **Test-first:** añadir un archivo `ConcurrencyProbe.swift` con un patrón que **solo compila** bajo `nonisolated` por defecto + Sendable inferido (prueba de humo de que los flags están activos); un `@Test` que ejercita un `actor` trivial y un salto a `@MainActor`.
- **Tarea:** verificar/aplicar `SWIFT_STRICT_CONCURRENCY = complete`, modo lenguaje 6, `Approachable Concurrency = YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` y `SWIFT_TREAT_WARNINGS_AS_ERRORS` en todos los targets.
- **DoD:** ☑ compila en modo estricto (v6 en los 3 targets) · ☑ 0 warnings (`GetBuildLog` severidad warning vacío, con `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`) · ☑ el probe confirma flags activos (`nonisolatedByDefaultProbe` + `actorRoundTripAndMainActorHop` verdes).

### ☑ 01-T003 — Verificar target multiplataforma (iOS/iPadOS, visionOS) y crear Widget ✅ 2026-07-18 (Widget diferido a Fase 11)
- **Prerrequisito:** 01-T002.
- **Contexto:** 🧹 `CLEAN` — configuración de targets es autocontenida.
- **Test-first:** los smoke tests de 01-T001 compilan y pasan con destino iOS y visionOS (mismo target); al crear el Widget, `@Test`/build que verifique que los archivos del núcleo tienen membership en la extensión.
- **Tarea:** verificar que el target `SaotomeManga` compila y arranca en simulador iOS y visionOS; crear la Widget extension en Xcode UI (acción de usuario; puede diferirse hasta abrir la Fase 11) y dar membership del núcleo a la extensión.
- **DoD:** ☑ app compila y arranca en iOS y visionOS (5/5 tests verdes en `iPhone 17 Pro (27.0)` y en `Apple Vision Pro (27.0)`, incl. UITest de arranque; 0 warnings en ambos) · ☑ Widget diferido explícitamente a Fase 11 (D-008) · ☑ deployment targets fijados (iOS 26+; visionOS por default del SDK 27).

### ☑ 01-T004 — Configuración por entorno (.xcconfig) y `AppConfiguration` ✅ 2026-07-18
- **Prerrequisito:** 01-T003.
- **Contexto:** 🪆 `NESTED` — depende de targets recién creados.
- **Test-first:** `@Test` que instancia `AppConfiguration` desde un `Bundle`/diccionario de prueba y verifica `apiBaseURL` y `appToken` no vacíos y con formato correcto (URL válida).
- **Tarea:** `Debug/Release/Shared.xcconfig`, claves `API_BASE_URL`/`APP_TOKEN` en Info.plist derivado, tipo `AppConfiguration` en Infrastructure que las lee; excluir `.xcconfig` con secreto real de git.
- **DoD:** ☑ config leída en runtime (snippet vía MCP: URL correcta, token presente longitud 42, valor jamás impreso) · ☑ secreto fuera de código y fuera de git (`git check-ignore` verde para `Config/Secrets.xcconfig`; plantilla `Secrets.example.xcconfig` comiteable) · ☑ tests verdes (5 de `AppConfigurationTests`, Red→Green documentado).

### ☑ 01-T005 — CI + linter + format ✅ 2026-07-18
- **Prerrequisito:** 01-T001..T004.
- **Contexto:** 🧹 `CLEAN` — tooling de repo, independiente del código de app.
- **Test-first:** (meta) el propio pipeline es la prueba: un PR de ejemplo con un warning de concurrencia debe fallar CI.
- **Tarea:** workflow de CI (build+test+lint), SwiftLint/SwiftFormat con config base, hook pre-commit.
- **DoD:** ☑ CI verde en `main` (run 29665952105; repo `manuuualvarez/SaotomeManga`) · ☑ CI roja ante
  violación (PR #1: job de lint FAIL, cerrado sin mergear; además el hook de pre-commit local bloqueó
  el commit de la violación — hizo falta `--no-verify` para subir la prueba) · ☑ lint sin errores
  (SwiftLint `--strict` + SwiftFormat `--lint` limpios en local y en CI). Nota: la vertiente
  "warning de concurrencia rompe CI" queda cubierta por el gate local vía MCP hasta D-010.

### ☑ 01-T006 — Mapa de carpetas del target + capa Presentation ✅ 2026-07-18 (añadida a posteriori)
- **Prerrequisito:** 01-T001. · **Contexto:** 🪆 `NESTED` — ajuste sobre la estructura recién creada.
- **Motivación:** la Fase 01 creó 3 de las 4 capas; `ContentView.swift` quedaba en la raíz sin carpeta
  `Presentation/`, y el mapa de carpetas futuro no estaba comprometido por escrito.
- **Tarea:** crear `Presentation/` y mover `ContentView.swift` (vía MCP `XcodeMakeDir`/`XcodeMV`);
  documentar el mapa completo de carpetas por fase en el PLAN (subfolders se crean al llegar su fase).
- **DoD:** ☑ 4 capas presentes como carpetas · ☑ mapa comprometido en el PLAN · ☑ 10/10 tests verdes
  tras el movimiento (incl. UITest de arranque) · ☑ 0 warnings.

---

## GATE DE VALIDACIÓN DE FASE 01 — ✅ SUPERADO (2026-07-18)
Cerrar la fase solo si:
- ☑ Xcodeproj (target multiplataforma) compila en Swift 6 modo estricto, **0 warnings** (verificado con `GetBuildLog` severidad warning vía MCP, en iOS 27.0 y visionOS 27.0).
- ☑ Tests smoke verdes vía MCP de Xcode (10/10 con `RunAllTests` en ambos destinos).
- ☑ Approachable Concurrency y `nonisolated` por defecto verificados por el probe (`IsolationProbe` + actor round-trip).
- ☑ Config por entorno operativa (verificada en runtime); secreto `App-Token` no comiteado (gitignored + `git check-ignore`).
- ☑ CI bloquea merges en rojo (PR #1 en rojo por lint); lint/format activos en CI y pre-commit. Build de CI diferido por D-010.
- ☑ Consistencia con la constitución revisada manualmente el 2026-07-18 (equivalente a `/speckit.analyze`: specs/plan/tasks reescritos y alineados con la constitución v1.1.0 en esta misma sesión; el tooling Spec-Kit no está instalado en el repo).
- **Criterios de aceptación:**
  - [x] `CLAUDE.md` presente, exhaustivo, sin ambigüedades.
  - [x] `AGENTS.md` describe los 4 subagentes con su scope.
  - [x] `Docs/ADR/ADR-000-stack.md` justifica la elección.

## Riesgos / notas
- Ajustar los nombres exactos de _upcoming features_ a la toolchain instalada (verificar con `swiftc -frontend -help`).
- Mantener el `App-Token` como config es deuda mínima; su endurecimiento (ofuscación/attestation) se revisa en Fase 13.
