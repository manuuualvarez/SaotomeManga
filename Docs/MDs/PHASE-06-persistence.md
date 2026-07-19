# FASE 06 — Persistencia SwiftData

- **Versión objetivo:** Básica (habilitador) · **Depende de:** Fase 02 (paralelizable con 03/04)
- **Rama sugerida:** `006-persistence`
- **Estado:** ☐ Pendiente

> Objetivo: la capa de persistencia local con SwiftData — esquema versionado, `ModelContainer`, acceso
> concurrente seguro con `ModelActor`, repositorios que mapean `@Model`↔Domain y soporte de migraciones desde v1.
> Da soporte offline al catálogo (caché) y a la colección (Fase 09).

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-015** — Como usuario, quiero que mi colección y los mangas vistos estén disponibles sin conexión.
- **US-016** — Como desarrollador, quiero escribir en SwiftData fuera del MainActor sin data races.
- **US-017** — Como usuario, quiero que futuras actualizaciones de la app no borren mis datos (migraciones seguras).

### Requisitos funcionales
- **FR-028** — Modelos `@Model`: `MangaEntity` (con relaciones/valores para autores, géneros, temas, demografías embebidos o relacionados), `CollectionItemEntity`, `CachedPageEntity` (opcional para paginación offline), `UserProfileEntity` (mínimo).
- **FR-029** — `VersionedSchema` v1 + `SchemaMigrationPlan` (aunque v1 no migre nada, la infraestructura queda lista).
- **FR-030** — `ModelContainer` único configurable con tres modos: **producción en contenedor de App Group** (`ModelConfiguration(groupContainer: .identifier("group.cloud.manuelalvarez.SaotomeManga"))`, para que el store se propague automáticamente al widget — ver Fase 11), producción estándar (fallback) y **en memoria** para tests (`isStoredInMemoryOnly: true`). El esquema vive en `Infrastructure/` (núcleo compartido) con target membership en la app y en la extensión de widget.
- **FR-030b** — **Capability App Groups activada al abrir esta fase** (aclaración 2026-07-18): el usuario añade la capability en **Signing & Capabilities** de **ambos targets** — `SaotomeManga` y `MisMangasWidgetExtension` (ya existe, ver enmienda D-008 de la Fase 01) — con el **mismo** identificador `group.cloud.manuelalvarez.SaotomeManga`. El store nace directamente en el contenedor compartido (nunca hay que "mudarlo"); la Fase 11 **verifica** el acceso desde la extensión, no lo activa.
- **FR-031** — `PersistenceActor` (`@ModelActor`) para lecturas/escrituras fuera del MainActor.
- **FR-032** — Repositorios: `MangaCache` (upsert/fetch de mangas), `CollectionStore` (CRUD local de colección) con mapping `@Model`↔Domain.
- **FR-033** — Los `@Model` **no** salen de Infrastructure; Presentation solo ve tipos de Domain.

### Requisitos no funcionales
- **NFR-012** — Acceso concurrente seguro (ModelActor); nada de compartir `ModelContext` entre hilos.
- **NFR-013** — Operaciones de escritura idempotentes por `id` (upsert), sin duplicados.

### Fuera de alcance
La lógica de sincronización nube↔local (Fase 09); UI (Fase 07/09).

---

## PLAN — Cómo (técnico)

- **Esquema:** definir `SchemaV1` con los `@Model`. Relaciones de catálogo (autores/géneros/…): evaluar embeber como
  arrays de estructuras `Codable` vs entidades relacionadas; **recomendado** relacionar autores (compartidos entre mangas)
  y embeber géneros/temas/demografías simples. Documentar la decisión en PLAN.
- **Migración:** `SchemaMigrationPlan` con etapa vacía v1; convención para añadir `SchemaV2` en el futuro.
- **Concurrencia:** `@ModelActor PersistenceActor`; la app obtiene el `ModelContainer` una vez y crea el actor.
- **Mapping:** funciones `MangaEntity.init(from: Manga)` / `toDomain()` y equivalentes para colección.
- **Tests:** contenedor en memoria; verificar upsert sin duplicados, fetch por id, borrado, y round-trip Domain→Entity→Domain.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]`: ¿cachear páginas completas del catálogo o solo mangas individuales? Recomendado: cachear mangas
  individuales + índice ligero; evita invalidaciones complejas. Confirmar en clarify.

---

## TASKS — Ejecución (TDD)

### ☐ 06-T001 — Esquema v1 y `ModelContainer`
- **Prerrequisito:** Fase 02 aprobada. **Acción previa del usuario (FR-030b):** capability App Groups en ambos targets (Xcode UI).
- **Contexto:** 🧹 `CLEAN` — módulo de persistencia nuevo.
- **Test-first:** crear `ModelContainer` en memoria y afirmar que el esquema v1 se instancia; insertar y contar entidades básicas.
- **Tarea:** `@Model` de FR-028, `SchemaV1`, factoría de `ModelContainer` (App Group real e in-memory). Los `@Model` nuevos de `Infrastructure/` necesitan **membership también en el widget** (la membership es por archivo — nota de la Fase 11).
- **DoD:** ☐ contenedor en memoria operativo · ☐ modelos instanciables · ☐ entitlement App Group activo en app y widget · ☐ compila en estricto.

### ☐ 06-T002 — Migraciones versionadas (infra)
- **Prerrequisito:** 06-T001.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** test que carga el `SchemaMigrationPlan` y valida que v1 es la actual y que el plan es aplicable (sin datos que migrar).
- **Tarea:** `VersionedSchema`/`SchemaMigrationPlan` + convención documentada para v2.
- **DoD:** ☐ plan de migración presente y válido · ☐ documentación de cómo añadir versiones.

### ☐ 06-T003 — `PersistenceActor` (ModelActor)
- **Prerrequisito:** 06-T001.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** desde múltiples tareas concurrentes, escrituras vía el actor no producen duplicados ni crashes; lecturas devuelven lo escrito.
- **Tarea:** `@ModelActor PersistenceActor` con API de fetch/upsert/delete genérica.
- **DoD:** ☐ sin data races · ☐ acceso serializado por el actor · ☐ tests concurrentes verdes.

### ☐ 06-T004 — Repositorios `MangaCache` y `CollectionStore` + mapping
- **Prerrequisito:** 06-T003.
- **Contexto:** 🪆 `NESTED` — usa el actor recién creado.
- **Test-first:** upsert de un `Manga` dos veces → 1 sola entidad; `fetch(id)` round-trip Domain igual al original; `CollectionStore` CRUD (add/update/delete) coherente; `@Model` no expuesto (compila solo con Domain hacia fuera).
- **Tarea:** repositorios con mapping bidireccional; upsert idempotente por id.
- **DoD:** ☐ upsert idempotente · ☐ round-trip fiel · ☐ Presentation nunca ve `@Model` · ☐ cobertura ≥ 85%.

---

## GATE DE VALIDACIÓN DE FASE 06
- ☐ SwiftData operativo: esquema v1, migraciones listas, `ModelContainer` (App Group + real + in-memory).
- ☐ El esquema es accesible desde el target de widget (membership de los archivos de `Infrastructure/`); la config de producción usa el contenedor de App Group y la **capability está activa en ambos targets con el mismo identificador** (FR-030b).
- ☐ Acceso concurrente seguro por `ModelActor`, sin data races (tests concurrentes verdes).
- ☐ Repositorios con upsert idempotente y mapping fiel; `@Model` encapsulado en Infrastructure.
- ☐ Cobertura ≥ 85%; 0 warnings de concurrencia; `/speckit.analyze` OK.

## Riesgos / notas
- Decidir estrategia de relaciones vs embebido temprano evita migraciones dolorosas después.
- Volumen de datos: no persistir los 64k mangas; solo lo consultado/coleccionado (caché acotada, política de limpieza opcional).
- Al ubicar el store en el App Group (para el widget, Fase 11), toda escritura la realiza la app; el widget accede solo lectura para evitar contención entre procesos.
