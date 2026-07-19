# FASE 02 — Núcleo de dominio y contratos

- **Versión objetivo:** Infraestructura · **Depende de:** Fase 01
- **Rama sugerida:** `002-domain-core`
- **Estado:** ✅ **Cerrada (2026-07-18)** — T001..T004 completas (T004 ejecutada antes que T003, ver D-018). 68/68 tests verdes, 0 warnings, cobertura mapping 99,2 %.

> Objetivo: modelar el dominio puro (Manga, Author, Genre, Theme, Demographic, Collection, paginación,
> errores, sesión) como tipos `Sendable` sin dependencias de framework, con su decodificación validada
> contra JSON real del OpenAPI (contract tests con _golden files_). Es la base que consumen red, persistencia y UI.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-004** — Como desarrollador, quiero modelos de dominio inmutables y `Sendable` que representen fielmente
  las entidades de la API, para pasarlos con seguridad entre actores y capas.
- **US-005** — Como desarrollador, quiero decodificar sin fallos el JSON real (incluyendo sus rarezas:
  comillas escapadas en `mainPicture`/`url`, `sypnosis`/`synopsis`, fechas ISO-8601, campos opcionales),
  para no romper en runtime con datos reales.

### Requisitos funcionales
- **FR-005** — Modelos de Domain: `Manga`, `Author` (+`AuthorRole`), `Genre`, `Theme`, `Demographic`,
  `MangaStatus`, `Page<T>` (+`PageMetadata`), `UserCollectionItem`, `AuthSession`/`UserProfile`.
- **FR-006** — Todos son `struct`/`enum` `Sendable`, `Equatable`, `Identifiable` donde aplique; sin `import` de UIKit/SwiftUI/SwiftData/URLSession.
- **FR-007** — Capa de **DTO + mapping**: DTOs `Codable` que reflejan el wire-format del OpenAPI, más funciones
  puras de mapeo DTO→Domain que **sanean** anomalías conocidas (des-escapar comillas en URLs, normalizar sinónimo `synopsis`).
- **FR-008** — `enum MangaError`/`DomainError` de errores tipados (validación, no encontrado, decodificación, etc.).
- **FR-009** — Validadores puros: `EmailValidator`, `PasswordPolicy` (≥ 8), usados en fases de auth.

### Anomalías del contrato a manejar (documentadas)
- `mainPicture` y `url` llegan con comillas dobles **dentro** de la cadena (`"\"https://…\""`) → el mapper las limpia.
  **Verificado 2026-07-18:** el backend actual responde **limpio** en todos los endpoints muestreados; el saneador
  se mantiene igualmente y se fija con una fixture de regresión sintetizada (ver D-013).
- El campo de sinopsis aparece como `sypnosis` en ejemplos y `synopsis` en el esquema → el DTO acepta ambos.
  **Verificado:** el backend real usa `sypnosis` (esquema y respuestas).
- `readingVolume` es opcional; `volumesOwned` es lista de enteros; IDs de manga son enteros, IDs de catálogo son UUID.
- **Descubierta en T001 (D-015):** `list/genres`, `list/themes` y `list/demographics` devuelven **`[String]` plano**;
  los DTO con UUID (`GenreDTO`/`ThemeDTO`/`DemographicDTO`) solo existen **anidados** dentro de `MangaDTO`.

### Fuera de alcance
Llamadas de red (Fase 03), `@Model` de SwiftData (Fase 06), UI. Aquí solo tipos puros + mapping + validación.

---

## PLAN — Cómo (técnico)

- Ubicar todo en el módulo `Domain` (modelos, errores, validadores) y un submódulo `DTO` en `Infrastructure`
  o en `Domain/Contracts` según se prefiera; el **mapping** vive junto a los DTOs, devolviendo tipos de Domain.
  → **Resuelto (D-017):** DTOs + mapping en `Infrastructure/DTO/`; validadores en `Domain/Validation/`.
- Estrategia de decodificación de fechas: `JSONDecoder` con `.iso8601` (con fallback para fracciones si aparecen).
  → Implementado como `JSONDecoder.mangaContract` (estrategia `.custom` con doble intento; instancia nueva por
  llamada porque `JSONDecoder` no es `Sendable`).
- `Page<T: Sendable & Decodable>` genérico para `MangaPageDTO`/`AuthorPageDTO`.
- **Golden files:** capturar respuestas reales (o del OpenAPI examples) en `specs/002-domain-core/contracts/`:
  `manga_42.json`, `list_mangas_p1.json`, `authors.json`, `genres.json`, `collection_item.json`, etc.
- Los contract tests decodifican cada golden file y afirman campos concretos (incluidas las anomalías saneadas).

### Decisiones abiertas
- `[NEEDS CLARIFICATION]` (menor): ¿mantener `AuthorRole` como enum cerrado (`.story`, `.art`, `.storyAndArt`, `.none`)
  con fallback `.unknown(String)` para robustez? → **Resuelto (D-011): sí** — enum cerrado + `.unknown(String)`.

### Decisiones tomadas en ejecución
- **D-011** — `AuthorRole` cerrado (`.story`, `.art`, `.storyAndArt`, `.none`) + fallback `.unknown(String)`.
  En contraste, `MangaStatus` es estricto: valor desconocido ⇒ `DomainError.mapping(field: "status")`
  (el enum del contrato es cerrado y un estado inventado sí es corrupción de datos).
- **D-012** — Los golden files viven en `specs/002-domain-core/contracts/` (raíz del repo) y los tests los
  localizan vía `#filePath` (`ContractFixtures`). Evita recursos de bundle y target membership ⇒ no se toca
  el pbxproj. Funciona en simulador y en CI (misma máquina de build y test).
- **D-013** — La anomalía de comillas escapadas **no aparece hoy** en el backend (muestreados `search/manga/42`,
  `list/mangas`, `list/bestMangas`, ejemplos del OpenAPI). El saneador de FR-007 se implementa igualmente
  (trim de `"` envolventes) y se fija con `manga_quotes_anomaly.json`, fixture **sintetizada** desde
  `manga_42.json` con la forma anómala documentada en el enunciado.
- **D-014** — `list/authors` real pesa 2,6 MB; se congela truncado a los **primeros 100 autores**
  (`authors.json`, vía `jq '.[0:100]'`). Se añade `authors_paged_p1.json` capturado íntegro del endpoint
  paginado real (`list/authorsPaged?page=1&per=10`, total 25 719 autores) para cubrir `AuthorPageDTO`.
- **D-015** — Los endpoints de listado de catálogo (`list/genres|themes|demographics`) devuelven `[String]`
  plano (21 géneros, 52 temáticas, 5 demografías); no requieren DTO. Los DTO con UUID solo existen anidados
  en `MangaDTO`. Los contract tests fijan ambas formas.
- **D-016** — Formas de auth congeladas desde `components.examples` del OpenAPI (tokens dummy;
  **nunca se congelan tokens reales** — constitución §6). El contrato confirma la **sesión dual** de la
  constitución §5: `DualSessionTokenResponse` con `expiresIn` refresh = 2 592 000 s (~30 d) y
  access = 3 600 s (~1 h) vía `/users/session/access`; `/users/renew` (48 h) queda como legacy que la app
  no usa. `users_jwt_login.json` se congela solo como forma legacy documentada.
- **D-017** — Ubicación de carpetas: DTOs + mapping en `Infrastructure/DTO/` (el wire-format es asunto de
  Infrastructure; opción A del PLAN); validadores en `Domain/Validation/`. Enmienda del mapa de carpetas
  de la Fase 01 (además, `Repositories/` se pospone a F03: los protocolos de repositorio nacen con la red).
- **D-018** — Orden de ejecución: **T004 antes que T003** (ambas dependían solo de T002) para que el mapping
  pudiera lanzar `DomainError` tipado (typed throws) desde el primer test, sin errores provisionales.
- **D-019** — En funciones `throws(DomainError)` el mapeo de colecciones usa bucle explícito en lugar de
  `map` (`PageDTO<MangaDTO>.toDomain()`): el `map` `rethrows` borra el tipo de error a `any Error` y no
  compila con typed throws.

---

## TASKS — Ejecución (TDD)

### ✅ 02-T001 — Capturar golden files del contrato
- **Prerrequisito:** Fase 01 aprobada.
- **Contexto:** 🧹 `CLEAN` — tarea de datos, autocontenida.
- **Test-first:** un `@Test` que verifica que cada golden file existe y es JSON válido (guard de la propia fixture).
  → `ContractFixturesTests` (Red: 12/12 fallando por fixtures ausentes → Green tras la captura).
- **Tarea:** guardar en `contracts/` las respuestas reales de: `search/manga/42`, `list/mangas?page=1`, `list/authors`, `list/genres`, `list/demographics`, `list/themes`, `collection/manga` (ejemplo), `users/jwt/login` (forma), `users/session/*` (forma).
  → 13 fixtures congeladas: 8 capturas reales (`manga_42`, `list_mangas_p1`, `authors` truncado,
  `authors_paged_p1`, `genres`, `demographics`, `themes` + `manga_quotes_anomaly` sintetizada) y 5 formas
  del OpenAPI examples (`collection_item`, `collection_mangas`, `users_jwt_login`, `users_session_token`, `user_me`).
- **DoD:** ✅ golden files presentes y válidos · ✅ cubren las anomalías (comillas escapadas vía fixture de regresión D-013, `sypnosis` real).

### ✅ 02-T002 — Modelos de dominio `Sendable`
- **Prerrequisito:** 02-T001.
- **Contexto:** 🪆 `NESTED` — se apoya en los golden files recién capturados para acertar campos.
- **Test-first:** `@Test` de igualdad/identidad y de que los tipos son `Sendable` (uso en contexto concurrente) para `Manga`, `Author`, `Page`, `UserCollectionItem`.
  → `DomainModelsTests` (Red: no compila por API inexistente → Green). La prueba de `Sendable` captura los
  modelos en `Task.detached` (con concurrencia estricta, no compilaría si no fuesen `Sendable`).
- **Tarea:** definir todos los modelos de FR-005/FR-006 con sus propiedades y enums.
  → 10 archivos en `Domain/Models/`: `Manga`, `MangaStatus`, `Author`(+`AuthorRole`), `Genre`, `Theme`,
  `Demographic`, `Page`(+`PageMetadata`), `UserCollectionItem`, `AuthSession`(+`TokenUse`), `UserProfile`.
  Solo `import Foundation` (URL/Date/UUID); `Sendable` inferido, nunca explícito (constitución §2).
- **DoD:** ✅ compilan sin `import` de frameworks de UI/IO · ✅ `Sendable`/`Equatable` · ✅ tests verdes.

### ✅ 02-T003 — DTOs `Codable` + mapping DTO→Domain
- **Prerrequisito:** 02-T002 (y 02-T004 por D-018: usa `DomainError` tipado).
- **Contexto:** 🪆 `NESTED` — mapping depende directamente de modelos y golden files en memoria.
- **Test-first (contract tests):** por cada golden file, decodificar el DTO y mapear a Domain, afirmando:
  URL de portada **sin** comillas escapadas, sinopsis presente venga como `sypnosis` o `synopsis`, fechas parseadas,
  colecciones anidadas (authors/genres/themes/demographics) completas, `metadata` de paginación correcta.
  → `ContractMappingTests` (14 tests): además, rol de autor desconocido ⇒ `.unknown`, estado desconocido ⇒
  `DomainError.mapping`, fecha con fracciones ⇒ fallback del decoder, fecha malformada ⇒ `DecodingError`.
- **Tarea:** DTOs + `JSONDecoder` configurado + funciones puras de mapeo con saneado de anomalías.
  → 9 archivos en `Infrastructure/DTO/`: `ContractJSONDecoder` (`JSONDecoder.mangaContract`), `MangaDTO`,
  `AuthorDTO`, `GenreDTO`, `ThemeDTO`, `DemographicDTO`, `PageDTO`(+`PageMetadataDTO`, typealiases
  `MangaPageDTO`/`AuthorPageDTO`), `UserMangaCollectionDTO`, `AuthResponseDTOs` (dual session, JWT legacy, user).
  Mapping con typed throws `throws(DomainError)`.
- **DoD:** ✅ todos los golden files decodifican y mapean · ✅ anomalías saneadas verificadas · ✅ cobertura del mapping ≥ 90 % (99,2 %: 130/131 líneas; única línea sin cubrir: rama interna del decoder de fechas).

### ✅ 02-T004 — Errores de dominio y validadores
- **Prerrequisito:** 02-T002. (Ejecutada antes que T003 — D-018.)
- **Contexto:** 🧹 `CLEAN` — pieza independiente, reutilizable por varias fases.
- **Test-first:** parametrizado (`arguments:`) — `EmailValidator` con casos válidos/ inválidos; `PasswordPolicy` (7 chars falla, 8 pasa); `DomainError` mapea causas esperadas.
  → `EmailValidatorTests` (13 casos parametrizados), `PasswordPolicyTests` (7 casos), `DomainErrorTests`.
- **Tarea:** `DomainError`, `EmailValidator`, `PasswordPolicy`.
  → `Domain/Errors/DomainError.swift` (`invalidEmail`, `weakPassword(minimumLength:)`, `notFound`,
  `mapping(field:)`) y `Domain/Validation/` (`EmailValidator` con Swift Regex nativo, `PasswordPolicy`
  con `minimumLength = 8`). Variantes `validate` con typed throws `throws(DomainError)`.
- **DoD:** ✅ tests parametrizados verdes · ✅ sin dependencias externas.

---

## GATE DE VALIDACIÓN DE FASE 02
- ✅ Todos los modelos son puros y `Sendable`; el módulo `Domain` no importa frameworks de IO/UI (solo Foundation: URL/Date/UUID).
- ✅ Cada golden file decodifica y mapea correctamente (contract tests verdes), incluidas anomalías del wire-format.
- ✅ Validadores y errores cubiertos con tests parametrizados.
- ✅ Cobertura Domain+mapping ≥ 85 % (mapping ≥ 90 %): Domain 100 % de líneas ejecutables; mapping 99,2 %; target app 97,27 %. (Medida con `xccov` sobre el xcresult de `RunAllTests` en DerivedData; los bundles del MCP quedan sin finalizar.)
- ✅ 0 warnings de concurrencia (`GetBuildLog severity: warning` vacío en todos los builds); análisis de coherencia spec/plan/tasks/constitución OK (manual — no hay comando `/speckit.analyze` instalado; verificado: FR-005..009 implementados, P1/P2/P4 y §2/§5/§6 respetados).

## Riesgos / notas
- Si aparecen más anomalías del backend en fases posteriores, se añaden golden files aquí y se re-valida (esta fase es el "muro de contención" del contrato).
- La anomalía de comillas escapadas hoy no se emite (D-013); si el enunciado la reactivase en otro despliegue, el saneador ya la cubre y la fixture de regresión la fija.
- Suite completa al cierre: **68 tests, 68 pass** (fixtures guard 14 + modelos 6 + contract mapping 14 + validadores/errores 23 + smoke F01 9 + UI 1 + config 5 — recuento por parametrización de Swift Testing).
