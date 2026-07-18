# FASE 02 — Núcleo de dominio y contratos

- **Versión objetivo:** Infraestructura · **Depende de:** Fase 01
- **Rama sugerida:** `002-domain-core`
- **Estado:** ☐ Pendiente

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
- El campo de sinopsis aparece como `sypnosis` en ejemplos y `synopsis` en el esquema → el DTO acepta ambos.
- `readingVolume` es opcional; `volumesOwned` es lista de enteros; IDs de manga son enteros, IDs de catálogo son UUID.

### Fuera de alcance
Llamadas de red (Fase 03), `@Model` de SwiftData (Fase 06), UI. Aquí solo tipos puros + mapping + validación.

---

## PLAN — Cómo (técnico)

- Ubicar todo en el módulo `Domain` (modelos, errores, validadores) y un submódulo `DTO` en `Infrastructure`
  o en `Domain/Contracts` según se prefiera; el **mapping** vive junto a los DTOs, devolviendo tipos de Domain.
- Estrategia de decodificación de fechas: `JSONDecoder` con `.iso8601` (con fallback para fracciones si aparecen).
- `Page<T: Sendable & Decodable>` genérico para `MangaPageDTO`/`AuthorPageDTO`.
- **Golden files:** capturar respuestas reales (o del OpenAPI examples) en `specs/002-domain-core/contracts/`:
  `manga_42.json`, `list_mangas_p1.json`, `authors.json`, `genres.json`, `collection_item.json`, etc.
- Los contract tests decodifican cada golden file y afirman campos concretos (incluidas las anomalías saneadas).

### Decisiones abiertas
- `[NEEDS CLARIFICATION]` (menor): ¿mantener `AuthorRole` como enum cerrado (`.story`, `.art`, `.storyAndArt`, `.none`)
  con fallback `.unknown(String)` para robustez? → Recomendado sí (enum con caso desconocido).

---

## TASKS — Ejecución (TDD)

### ☐ 02-T001 — Capturar golden files del contrato
- **Prerrequisito:** Fase 01 aprobada.
- **Contexto:** 🧹 `CLEAN` — tarea de datos, autocontenida.
- **Test-first:** un `@Test` que verifica que cada golden file existe y es JSON válido (guard de la propia fixture).
- **Tarea:** guardar en `contracts/` las respuestas reales de: `search/manga/42`, `list/mangas?page=1`, `list/authors`, `list/genres`, `list/demographics`, `list/themes`, `collection/manga` (ejemplo), `users/jwt/login` (forma), `users/session/*` (forma).
- **DoD:** ☐ golden files presentes y válidos · ☐ cubren las anomalías (comillas escapadas, `sypnosis`).

### ☐ 02-T002 — Modelos de dominio `Sendable`
- **Prerrequisito:** 02-T001.
- **Contexto:** 🪆 `NESTED` — se apoya en los golden files recién capturados para acertar campos.
- **Test-first:** `@Test` de igualdad/identidad y de que los tipos son `Sendable` (uso en contexto concurrente) para `Manga`, `Author`, `Page`, `UserCollectionItem`.
- **Tarea:** definir todos los modelos de FR-005/FR-006 con sus propiedades y enums.
- **DoD:** ☐ compilan sin `import` de frameworks de UI/IO · ☐ `Sendable`/`Equatable` · ☐ tests verdes.

### ☐ 02-T003 — DTOs `Codable` + mapping DTO→Domain
- **Prerrequisito:** 02-T002.
- **Contexto:** 🪆 `NESTED` — mapping depende directamente de modelos y golden files en memoria.
- **Test-first (contract tests):** por cada golden file, decodificar el DTO y mapear a Domain, afirmando:
  URL de portada **sin** comillas escapadas, sinopsis presente venga como `sypnosis` o `synopsis`, fechas parseadas,
  colecciones anidadas (authors/genres/themes/demographics) completas, `metadata` de paginación correcta.
- **Tarea:** DTOs + `JSONDecoder` configurado + funciones puras de mapeo con saneado de anomalías.
- **DoD:** ☐ todos los golden files decodifican y mapean · ☐ anomalías saneadas verificadas · ☐ cobertura del mapping ≥ 90%.

### ☐ 02-T004 — Errores de dominio y validadores
- **Prerrequisito:** 02-T002.
- **Contexto:** 🧹 `CLEAN` — pieza independiente, reutilizable por varias fases.
- **Test-first:** parametrizado (`arguments:`) — `EmailValidator` con casos válidos/ inválidos; `PasswordPolicy` (7 chars falla, 8 pasa); `DomainError` mapea causas esperadas.
- **Tarea:** `DomainError`, `EmailValidator`, `PasswordPolicy`.
- **DoD:** ☐ tests parametrizados verdes · ☐ sin dependencias externas.

---

## GATE DE VALIDACIÓN DE FASE 02
- ☐ Todos los modelos son puros y `Sendable`; el módulo `Domain` no importa frameworks de IO/UI.
- ☐ Cada golden file decodifica y mapea correctamente (contract tests verdes), incluidas anomalías del wire-format.
- ☐ Validadores y errores cubiertos con tests parametrizados.
- ☐ Cobertura Domain+mapping ≥ 85% (mapping ≥ 90%).
- ☐ 0 warnings de concurrencia; `/speckit.analyze` OK.

## Riesgos / notas
- Si aparecen más anomalías del backend en fases posteriores, se añaden golden files aquí y se re-valida (esta fase es el "muro de contención" del contrato).
