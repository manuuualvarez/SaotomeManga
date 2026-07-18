# FASE 03 — Capa de red / API client

- **Versión objetivo:** Básica (habilitador) · **Depende de:** Fase 02
- **Rama sugerida:** `003-networking`
- **Estado:** ☐ Pendiente

> Objetivo: un cliente HTTP `Sendable` y testeable que hable con la API de mangas (listados, búsquedas,
> detalle, catálogos) usando los DTOs de la Fase 02, con paginación, manejo de errores HTTP y `App-Token`,
> **sin** aún la lógica de tokens de usuario (eso es Fase 04). Todo probado con un transporte inyectable (sin red real).

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-006** — Como app, quiero obtener páginas de mangas y catálogos desde la API de forma fiable y cancelable,
  para alimentar el catálogo y los filtros.
- **US-007** — Como desarrollador, quiero un cliente 100% testeable sin tocar la red, para tener tests deterministas.

### Requisitos funcionales
- **FR-010** — Abstracción `HTTPTransport` (protocolo `Sendable`) sobre `URLSession`, inyectable; implementación de test que devuelve respuestas prefabricadas.
- **FR-011** — `APIClient` con métodos para endpoints públicos:
  `listMangas(page,per)`, `bestMangas(page,per)`, `mangasByGenre/Theme/Demographic/Author(...)`,
  `genres()/themes()/demographics()/authors()`, `mangaByID(_:)`, `mangasBeginsWith(_:)`, `mangasContains(_:page,per)`,
  `searchAuthors(_:)`, `customSearch(CustomSearch, page, per)`.
- **FR-012** — Modelo de **paginación** coherente: `per` fijo por sesión de paginación; helper que itera páginas.
- **FR-013** — `App-Token` se añade en el request builder desde `AppConfiguration` (para el endpoint que lo requiere).
- **FR-014** — Mapeo de errores HTTP → `NetworkError` tipado (offline, timeout, 4xx/5xx, decoding), con reintentos idempotentes configurables.
- **FR-015** — Cancelación cooperativa (`Task`/`async`), respetando `Task.isCancelled`.

### Requisitos no funcionales
- **NFR-005** — Todo el I/O ocurre `nonisolated` (fuera del MainActor). `APIClient` es `Sendable`.
- **NFR-006** — Sin estado mutable compartido salvo lo estrictamente necesario (config inmutable).

### Fuera de alcance
Tokens de usuario/refresh y endpoints autenticados (`/collection`, `/users/*`) → Fase 04/05/09.

---

## PLAN — Cómo (técnico)

- **Diseño:** `RequestBuilder` puro (construye `URLRequest` desde un `Endpoint` enum) + `APIClient` que ejecuta vía `HTTPTransport` y decodifica con el `JSONDecoder` de la Fase 02.
- **`Endpoint`** como enum con `path`, `method`, `queryItems`, `body`, `requiresAppToken`. Facilita tests de construcción de URL.
- **Paginación:** tipo `Paginator<T>` que, dado un fetch de página, expone `AsyncSequence`/`next()` reutilizando `per`.
- **Transporte de test:** `StubTransport` mapea `(method,path)`→respuesta (status + data), permitiendo simular 200/404/500/offline.
- **Reintentos:** política simple con backoff para errores transitorios (timeout/5xx) en peticiones idempotentes GET.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]` (menor): límite superior de `per` = 100 (según OpenAPI). Documentar y validar en cliente.

---

## TASKS — Ejecución (TDD)

### ☐ 03-T001 — Abstracción de transporte + `RequestBuilder`
- **Prerrequisito:** Fase 02 aprobada.
- **Contexto:** 🧹 `CLEAN` — nuevo módulo de red, autocontenido.
- **Test-first:** `@Test` parametrizado que construye `URLRequest` para varios `Endpoint` y afirma URL, método, query (`page`,`per`), y cabecera `App-Token` solo cuando `requiresAppToken`.
- **Tarea:** `HTTPTransport` (protocolo), `URLSessionTransport`, `Endpoint` enum, `RequestBuilder`.
- **DoD:** ☐ URLs y cabeceras correctas por test · ☐ `App-Token` solo donde toca · ☐ `Sendable`.

### ☐ 03-T002 — `APIClient`: listados y catálogos
- **Prerrequisito:** 03-T001.
- **Contexto:** 🪆 `NESTED` — usa builder y DTOs recién definidos.
- **Test-first:** con `StubTransport` sirviendo golden files (Fase 02): `listMangas` devuelve `Page<Manga>` con metadata; `genres()/themes()/demographics()` devuelven arrays; `authors()` lista.
- **Tarea:** implementar métodos de listado/catálogo.
- **DoD:** ☐ decodifica golden files vía cliente · ☐ metadata de paginación expuesta · ☐ tests verdes.

### ☐ 03-T003 — `APIClient`: detalle y búsquedas
- **Prerrequisito:** 03-T002.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** `mangaByID(42)` → `Manga` correcto; `mangasContains("ball")` paginado; `customSearch(...)` con body POST correcto (afirmar el JSON enviado con `searchContains`).
- **Tarea:** implementar detalle, `beginsWith/contains`, `searchAuthors`, `customSearch` (POST).
- **DoD:** ☐ body de `customSearch` serializado correcto · ☐ resultados decodificados · ☐ tests verdes.

### ☐ 03-T004 — Errores HTTP, offline y reintentos
- **Prerrequisito:** 03-T002.
- **Contexto:** 🧹 `CLEAN` — política transversal, conviene aislarla.
- **Test-first:** `StubTransport` devuelve 404→`.notFound`, 500→`.server`, error de red→`.offline`, cuerpo corrupto→`.decoding`; reintento de 500 GET reintenta N veces y luego falla.
- **Tarea:** mapeo `NetworkError`, política de reintentos/backoff, respeto de cancelación.
- **DoD:** ☐ cada código mapea a su error · ☐ reintentos solo en idempotentes · ☐ cancelación honrada.

### ☐ 03-T005 — Paginador reutilizable
- **Prerrequisito:** 03-T002.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** `Paginator` sobre stub multi-página afirma que mantiene `per`, avanza páginas y termina en `total`.
- **Tarea:** `Paginator<T>` (AsyncSequence).
- **DoD:** ☐ no duplica ni omite elementos entre páginas · ☐ coherencia de `per` · ☐ fin correcto.

---

## GATE DE VALIDACIÓN DE FASE 03
- ☐ Todos los endpoints públicos consumidos y probados con `StubTransport` (sin red real).
- ☐ Construcción de requests, `App-Token`, paginación, errores y cancelación cubiertos.
- ☐ `APIClient` `Sendable`, I/O `nonisolated`, 0 warnings de concurrencia.
- ☐ Cobertura de la capa de red ≥ 85%; `/speckit.analyze` OK.

## Riesgos / notas
- Reservar un pequeño set de tests de integración **opt-in** (marcados, no en CI por defecto) que golpeen la API real
  para detectar drift del contrato; se ejecutan manualmente antes de releases (ver Fase 13).
