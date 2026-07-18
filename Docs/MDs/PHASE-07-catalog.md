# FASE 07 — Catálogo: listado, grid, detalle y portadas

- **Versión objetivo:** Básica + Media (base) · **Depende de:** Fase 03, 06
- **Rama sugerida:** `007-catalog`
- **Estado:** ☐ Pendiente

> Objetivo: la primera experiencia visible — explorar el catálogo con **listado** y **grid** paginados,
> abrir un **detalle** completo, y cargar **portadas** de forma asíncrona con caché, placeholder y cancelación.
> Cumple el mínimo de la versión básica y sienta la base de la media (listado + detalle + grid).

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-018** — Como usuario, quiero navegar el catálogo de mangas en lista y en cuadrícula, con scroll infinito paginado.
- **US-019** — Como usuario, quiero ver la portada de cada manga, cargada eficientemente y sin bloquear el scroll.
- **US-020** — Como usuario, quiero abrir un manga y ver su ficha completa (títulos, sinopsis, autores, géneros, temas, demografías, puntuación, estado, tomos/capítulos, fechas).
- **US-021** — Como usuario, quiero ver "mejores mangas" (ordenados por puntuación).

### Requisitos funcionales
- **FR-034** — `CatalogModel` (`@Observable @MainActor`) que pagina `list/mangas` y `list/bestMangas` con scroll infinito (usa `Paginator`, Fase 03), con caché en SwiftData (Fase 06).
- **FR-035** — `MangaListView` (lista) y `MangaGridView` (grid adaptativo) conmutables, con celdas que muestran portada + título + puntuación.
- **FR-036** — `MangaDetailView` con todos los campos del `Manga`, secciones de autores/géneros/temas/demografías, sinopsis expandible y enlace externo.
- **FR-037** — `CoverImageView`: carga async, placeholder, caché en memoria+disco, cancelación al reciclar celda, `accessibilityLabel` con el título.
- **FR-038** — Estados de **carga / vacío / error** con reintento en cada pantalla; soporte offline (muestra caché si no hay red).
- **FR-039** — Layout adaptable iPhone/iPad (columnas del grid según `size class`); navegación con `NavigationStack`/split en iPad.

### Requisitos no funcionales
- **NFR-014** — La paginación no duplica ni pierde elementos; el scroll se mantiene fluido (prefetch antes del final).
- **NFR-015** — Descarga/decodificación de imágenes fuera del MainActor; solo el `Image` final en UI.

### Fuera de alcance
Filtros/búsqueda (Fase 08); acciones de colección (Fase 09) — aunque el detalle reserva el punto de entrada "Añadir a mi colección".

---

## PLAN — Cómo (técnico)

- **Datos:** `CatalogModel` orquesta `APIClient` + `MangaCache`. Estrategia: mostrar caché al instante si existe, refrescar en background, hacer upsert de páginas nuevas.
- **Imágenes:** `ImageLoader` (`actor`) con caché LRU en memoria + `URLCache`/disco; entrega `Data`/`Image` cancelable; `CoverImageView` usa `task(id:)` para cancelar al reciclar. Evaluar `AsyncImage` vs loader propio (recomendado loader propio por control de caché/cancelación).
- **UI:** `NavigationSplitView` en iPad, `NavigationStack` en iPhone; grid con `LazyVGrid` y columnas por `horizontalSizeClass`.
- **Prefetch:** disparar carga de la siguiente página cuando faltan N celdas para el final.
- **Tests:** lógica de paginación/estado en `CatalogModel` con `APIClient` fake + cache in-memory; snapshot/UITest ligero de lista/detalle.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]` (menor): tamaño de `per` para scroll (recomendado 20). Confirmar en clarify.

---

## TASKS — Ejecución (TDD)

### ☐ 07-T001 — `ImageLoader` + `CoverImageView`
- **Prerrequisito:** Fase 03 aprobada.
- **Contexto:** 🧹 `CLEAN` — componente reutilizable, aislado.
- **Test-first:** `ImageLoader` (con transporte fake) cachea por URL (segunda petición no vuelve a descargar), cancela tareas obsoletas, y falla a placeholder ante error. Test de que la descarga ocurre fuera del MainActor.
- **Tarea:** `ImageLoader` (actor, caché) + `CoverImageView` (placeholder, `task(id:)`, accessibilityLabel).
- **DoD:** ☐ caché hit verificado · ☐ cancelación al cambiar URL · ☐ placeholder en error · ☐ label accesible.

### ☐ 07-T002 — `CatalogModel` con paginación + caché
- **Prerrequisito:** Fase 03, Fase 06.
- **Contexto:** 🪆 `NESTED` — integra red + persistencia recién construidas.
- **Test-first:** con `APIClient` fake multipágina + cache in-memory: primera carga puebla y cachea; `loadMore` avanza sin duplicar; sin red → sirve caché y marca estado offline; error → estado error con reintento.
- **Tarea:** `CatalogModel` `@Observable @MainActor` para `mangas` y `bestMangas` (scroll infinito, prefetch, cache-first).
- **DoD:** ☐ paginación sin duplicados/pérdidas · ☐ cache-first + refresh · ☐ estados carga/vacío/error/offline.

### ☐ 07-T003 — `MangaListView` y `MangaGridView` (adaptativo)
- **Prerrequisito:** 07-T001, 07-T002.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** lógica de columnas por size class (función pura testeable); UITest ligero: la lista carga y hace scroll infinito; toggle lista/grid conserva posición razonable.
- **Tarea:** ambas vistas + toggle, celdas con portada/título/score, prefetch al acercarse al final.
- **DoD:** ☐ adaptación iPhone/iPad · ☐ scroll infinito operativo · ☐ estados carga/vacío/error visibles.

### ☐ 07-T004 — `MangaDetailView`
- **Prerrequisito:** 07-T002.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** UITest: abrir detalle desde lista muestra título, sinopsis, autores/géneros/temas/demografías, score, tomos/capítulos y fechas; enlace externo presente; botón "Añadir a mi colección" visible (deshabilitado si no autenticado, gancho para Fase 09).
- **Tarea:** `MangaDetailView` completa con secciones y sinopsis expandible.
- **DoD:** ☐ todos los campos del `Manga` presentes · ☐ accesible (Dynamic Type, VoiceOver) · ☐ gancho a colección listo.

### ☐ 07-T005 — Navegación adaptable (iPhone/iPad)
- **Prerrequisito:** 07-T003, 07-T004.
- **Contexto:** 🧹 `CLEAN` — capa de navegación transversal.
- **Test-first:** UITest en destino iPad (split) y iPhone (stack): navegación lista→detalle y volver; en iPad, selección en columna primaria actualiza detalle.
- **Tarea:** `NavigationSplitView`/`NavigationStack` según plataforma; rutas tipadas.
- **DoD:** ☐ navegación correcta en ambos idioms · ☐ deep-link a detalle por id (base para widget/Spotlight).

---

## GATE DE VALIDACIÓN DE FASE 07
- ☐ Catálogo navegable en lista y grid con scroll infinito paginado, sin duplicados/pérdidas.
- ☐ Portadas async con caché, placeholder, cancelación y label accesible; descarga fuera del MainActor.
- ☐ Detalle completo con todos los campos; navegación adaptable iPhone/iPad; estados carga/vacío/error/offline.
- ☐ Cobertura de `CatalogModel`/`ImageLoader` ≥ 85%; 0 warnings de concurrencia; `/speckit.analyze` OK.
- ☐ **Hito demo básica:** con las fases 01–03, 06, 07 la app ya consulta catálogo y muestra portadas/detalle.

## Riesgos / notas
- Rendimiento del grid con muchas celdas + imágenes: medir con Instruments en Fase 13; aquí, prefetch y caché acotada.
