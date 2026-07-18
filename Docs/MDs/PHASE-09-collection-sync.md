# FASE 09 — Colección + sincronización nube

- **Versión objetivo:** Avanzada · **Depende de:** Fase 05 (auth), 06 (SwiftData), 07 (catálogo)
- **Rama sugerida:** `009-collection-sync`
- **Estado:** ☐ Pendiente

> Objetivo: el corazón funcional de la app — gestionar la colección del usuario (tomos comprados, tomo en lectura,
> colección completa) con la **nube como fuente de verdad** y SwiftData como caché offline, sincronización bidireccional,
> resolución de conflictos y una UX fluida (optimista con reconciliación). Completa la versión **avanzada**.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-026** — Como usuario autenticado, quiero añadir un manga a mi colección indicando tomos que poseo, tomo en lectura y si está completa.
- **US-027** — Como usuario, quiero editar y eliminar entradas de mi colección.
- **US-028** — Como usuario, quiero ver toda mi colección con su progreso, disponible offline.
- **US-029** — Como usuario, quiero que mis cambios se guarden en la nube y se reflejen en todos mis dispositivos.
- **US-030** — Como usuario, quiero que si edito offline, los cambios se sincronicen al recuperar conexión.

### Requisitos funcionales
- **FR-047** — Casos de uso: `AddOrUpdateCollectionItem` (`POST /collection/manga`), `RemoveCollectionItem` (`DELETE /collection/manga/{id}`), `FetchCollection` (`GET /collection/manga`, no paginado), `FetchCollectionItem` (`GET /collection/manga/{id}`). Todos autenticados (Fase 04 interceptor).
- **FR-048** — Datos de colección: `volumesOwned: [Int]`, `readingVolume: Int?`, `completeCollection: Bool` (según `UserMangaCollectionRequest`).
- **FR-049** — **Sync bidireccional:** al iniciar sesión/abrir, `FetchCollection` puebla SwiftData; los cambios locales se envían a la nube; la nube gana como fuente de verdad tras confirmación.
- **FR-050** — **Cola de operaciones offline:** cambios hechos sin red se encolan (persistidos) y se reintentan al reconectar; idempotencia por `mangaID`.
- **FR-051** — **UI optimista:** el cambio se refleja al instante en local y se reconcilia con la respuesta del servidor (revierte si falla).
- **FR-052** — Resolución de conflictos: política **last-write-wins basada en servidor** con marca temporal local; documentar y testear.
- **FR-053** — UI: pantalla "Mi Colección" (lista/grid con progreso de lectura), editor de entrada (selector de tomos poseídos, tomo en lectura, switch completa), acción "Añadir/Quitar" desde el detalle (Fase 07) y estado de "en mi colección".
- **FR-054** — Indicadores de progreso: % leído / tomo actual sobre total (`volumes`), y "faltan N tomos".

### Requisitos no funcionales
- **NFR-018** — La colección es usable offline (lectura siempre; escritura encolada).
- **NFR-019** — Ninguna operación duplica entradas; upsert idempotente por `mangaID` en local y remoto.
- **NFR-020** — La sincronización corre fuera del MainActor; la UI solo observa estado.

### Fuera de alcance
Estadísticas/recomendaciones (Fase 10); widget (Fase 11).

---

## PLAN — Cómo (técnico)

- **`CollectionRepository`:** fachada que combina `CollectionStore` (SwiftData, Fase 06) + endpoints autenticados (Fase 03/04).
- **`SyncEngine` (`actor`):** reconcilia local↔remoto; expone `syncNow()`, procesa la **cola de mutaciones** (`PendingMutationEntity` en SwiftData) con reintentos y backoff; last-write-wins por servidor.
- **Conectividad:** `NetworkMonitor` (NWPathMonitor) inyectable dispara flush de la cola al reconectar.
- **UI optimista:** los casos de uso aplican el cambio local inmediatamente, encolan la mutación y actualizan estado; en fallo definitivo, revierten y notifican.
- **Modelo de progreso:** funciones puras de cálculo de progreso (testeables) sobre `volumesOwned/readingVolume/volumes`.
- **Tests:** fakes de API + cache in-memory + monitor de red simulado para cubrir online, offline→online, conflicto, y revert.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]`: ¿merge de `volumesOwned` entre dispositivos o reemplazo? Recomendado **reemplazo last-write-wins**
  por simplicidad y coherencia con la API (que actualiza el registro completo). Confirmar en clarify.

---

## TASKS — Ejecución (TDD)

### ☐ 09-T001 — Casos de uso de colección (CRUD autenticado)
- **Prerrequisito:** Fase 05, Fase 06 aprobadas.
- **Contexto:** 🧹 `CLEAN` — lógica de aplicación, sin UI.
- **Test-first:** con `APIClient` fake autenticado + cache: `AddOrUpdate` envía `UserMangaCollectionRequest` correcto y persiste local; `Remove` borra local y remoto; `FetchCollection` puebla local; `FetchItem` inexistente → error manejado.
- **Tarea:** los cuatro casos de uso sobre `CollectionRepository`.
- **DoD:** ☐ payloads correctos · ☐ persistencia local coherente · ☐ errores manejados · ☐ upsert idempotente.

### ☐ 09-T002 — Cola de mutaciones offline + `SyncEngine`
- **Prerrequisito:** 09-T001.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** editar sin red encola la mutación (persistida); al "reconectar" (monitor simulado) se envía y se vacía la cola; fallo transitorio reintenta con backoff; conflicto → gana servidor.
- **Tarea:** `PendingMutationEntity`, `SyncEngine` (actor), integración con `NetworkMonitor`.
- **DoD:** ☐ persistencia de cola · ☐ flush al reconectar · ☐ reintentos/backoff · ☐ last-write-wins verificado.

### ☐ 09-T003 — Sincronización de arranque/login
- **Prerrequisito:** 09-T002.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** tras login, `syncNow()` trae la colección remota y la fusiona con local resolviendo conflictos; sin red, usa local y encola pendientes.
- **Tarea:** enganchar `syncNow()` al bootstrap de sesión (Fase 05) y al reconectar.
- **DoD:** ☐ colección remota reflejada tras login · ☐ funciona offline · ☐ sin duplicados.

### ☐ 09-T004 — Cálculo de progreso (puro)
- **Prerrequisito:** Fase 02.
- **Contexto:** 🧹 `CLEAN` — utilidad pura reutilizable (también por widget/stats).
- **Test-first (parametrizado):** progreso %, "faltan N tomos", flag completa a partir de `volumesOwned/readingVolume/volumes`; bordes (0 tomos, sin `volumes`, readingVolume > owned).
- **Tarea:** funciones puras de progreso.
- **DoD:** ☐ casos borde cubiertos · ☐ sin dependencias · ☐ reutilizable en Fase 10/11.

### ☐ 09-T005 — UI de colección y editor de entrada
- **Prerrequisito:** 09-T001, 09-T004.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** UITest: desde detalle (Fase 07) "Añadir a mi colección" abre editor; guardar refleja el manga en "Mi Colección" al instante (optimista); editar tomo en lectura persiste; eliminar lo quita. Test de revert ante fallo del servidor.
- **Tarea:** `CollectionView` (lista/grid con progreso), `CollectionItemEditor`, integración del gancho del detalle y estado "en colección".
- **DoD:** ☐ CRUD desde UI · ☐ optimista con revert · ☐ progreso visible · ☐ accesible · ☐ estados carga/vacío/error.

---

## GATE DE VALIDACIÓN DE FASE 09
- ☐ CRUD de colección contra la nube con caché local; colección usable offline; escritura encolada y sincronizada al reconectar.
- ☐ Sync bidireccional con last-write-wins (servidor) verificado; sin duplicados; upsert idempotente.
- ☐ UI optimista con revert ante fallo; progreso de lectura correcto; ganchos desde el detalle.
- ☐ Cobertura casos de uso + `SyncEngine` ≥ 85%; 0 warnings de concurrencia; `/speckit.analyze` OK.
- ☐ **Hito versión avanzada completa** (nube + auth + Keychain + colección sincronizada).

## Riesgos / notas
- La API actualiza el registro completo del manga en colección: la política de reemplazo simplifica el sync pero puede perder cambios concurrentes de otro dispositivo entre syncs; documentar y aceptar como trade-off, o añadir merge en una iteración posterior.
- Escenarios offline→online son los de mayor riesgo: reservar tiempo de test extra aquí.
