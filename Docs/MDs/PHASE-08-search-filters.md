# FASE 08 — Filtros y búsqueda

- **Versión objetivo:** Media · **Depende de:** Fase 03, 07
- **Rama sugerida:** `008-search-filters`
- **Estado:** ☐ Pendiente

> Objetivo: completar la versión **media** con el conjunto **completo de filtros** por todas las categorías
> (género, tema, demografía, autor) y las búsquedas (empieza por / contiene / autor / búsqueda avanzada
> multicriterio `POST /search/manga`). Reutiliza el catálogo y la paginación de la Fase 07.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-022** — Como usuario, quiero filtrar mangas por género, tema y demografía para encontrar lo que me gusta.
- **US-023** — Como usuario, quiero buscar por título (empieza por / contiene) y por autor.
- **US-024** — Como usuario, quiero una búsqueda avanzada combinando título, autor, y varios géneros/temas/demografías.
- **US-025** — Como usuario, quiero ver y limpiar los filtros activos, y que los resultados se paginen.

### Requisitos funcionales
- **FR-040** — Carga de catálogos de filtro (`genres`, `themes`, `demographics`, `authors`) con caché (Fase 06).
- **FR-041** — Filtrado por categoría única vía `mangaByGenre/Theme/Demographic/Author` (paginado).
- **FR-042** — Búsqueda por título: `mangasBeginsWith` y `mangasContains` (paginado), con _debounce_.
- **FR-043** — Búsqueda de autores `search/author/{q}` y navegación a mangas del autor.
- **FR-044** — **Búsqueda avanzada** `POST /search/manga` con `CustomSearch` (título, nombre/apellido autor, arrays de géneros/temas/demografías, `searchContains`), paginada.
- **FR-045** — UI de filtros: panel/hoja con selección múltiple, chips de filtros activos, botón limpiar; resultados en lista/grid reutilizando Fase 07.
- **FR-046** — Estados carga/vacío ("sin resultados")/error con reintento; conservar filtros al paginar.

### Requisitos no funcionales
- **NFR-016** — Debounce de búsqueda (p. ej. 300 ms) y cancelación de peticiones obsoletas al teclear.
- **NFR-017** — La combinación de filtros produce un único `CustomSearch` coherente (sin llamadas contradictorias).

### Fuera de alcance
Persistir "búsquedas guardadas" (posible extra en Fase 10); ordenaciones custom más allá de las que ofrece la API.

---

## PLAN — Cómo (técnico)

- **`SearchModel` (`@Observable @MainActor`):** mantiene criterios (`SearchCriteria`), decide qué endpoint usar
  (categoría única vs `customSearch` cuando hay múltiples criterios), y pagina resultados con `Paginator`.
- **Debounce/cancelación:** usar `Task` con `id` sobre el texto; cancelar la anterior al cambiar.
- **Mapping criterios→request:** función pura `SearchCriteria → (Endpoint | CustomSearch)` altamente testeable.
- **UI:** `FiltersSheet` (multiselección de géneros/temas/demografías + campos de texto), `activeFilterChips`, reutiliza `MangaListView/GridView`.
- **Catálogos de filtro:** cargar una vez y cachear; refrescar en background.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]` (menor): cuándo saltar de "categoría única" a `customSearch` — regla: 0/1 criterio simple ⇒ endpoint específico; ≥2 criterios o multiselección ⇒ `customSearch`. Confirmar.

---

## TASKS — Ejecución (TDD)

### ☐ 08-T001 — Catálogos de filtro con caché
- **Prerrequisito:** Fase 07 aprobada.
- **Contexto:** 🧹 `CLEAN`.
- **Test-first:** con `APIClient` fake + cache: primera carga descarga y cachea géneros/temas/demografías/autores; segunda usa caché; error → estado error con reintento.
- **Tarea:** carga+caché de catálogos de filtro.
- **DoD:** ☐ cache-first · ☐ estados carga/error · ☐ tests verdes.

### ☐ 08-T002 — Mapeo de criterios → endpoint/`CustomSearch`
- **Prerrequisito:** 08-T001.
- **Contexto:** 🪆 `NESTED`.
- **Test-first (parametrizado):** 1 género ⇒ `mangaByGenre`; texto "contiene" ⇒ `mangasContains`; título + 2 géneros + demografía ⇒ `CustomSearch` con `searchContains` correcto y arrays poblados; criterios vacíos ⇒ catálogo normal.
- **Tarea:** función pura de mapeo + selección de endpoint.
- **DoD:** ☐ todas las combinaciones mapean correcto · ☐ `CustomSearch` serializa bien.

### ☐ 08-T003 — `SearchModel` con debounce, paginación y cancelación
- **Prerrequisito:** 08-T002.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** teclear rápido dispara una sola búsqueda efectiva (debounce) y cancela obsoletas; resultados paginan conservando criterios; "sin resultados" → estado vacío.
- **Tarea:** `SearchModel` orquestando criterios→resultados con `Paginator`.
- **DoD:** ☐ debounce/cancelación verificados · ☐ paginación conserva filtros · ☐ estados completos.

### ☐ 08-T004 — UI de filtros y búsqueda
- **Prerrequisito:** 08-T003.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** UITest: aplicar 2 géneros + demografía muestra chips activos y resultados; limpiar filtros restablece; buscar por autor navega a sus mangas.
- **Tarea:** `FiltersSheet` (multiselección), chips activos, barra de búsqueda; reutiliza lista/grid de Fase 07.
- **DoD:** ☐ multiselección + chips + limpiar · ☐ búsqueda por autor navegable · ☐ accesible · ☐ estados carga/vacío/error.

---

## GATE DE VALIDACIÓN DE FASE 08
- ☐ Filtros completos por género/tema/demografía/autor y búsquedas (begins/contains/autor/avanzada) operativos y paginados.
- ☐ Mapeo criterios→request cubierto por tests parametrizados; debounce y cancelación verificados.
- ☐ UI de filtros con chips activos y limpiar; estados carga/vacío/error; reutiliza catálogo de Fase 07.
- ☐ Cobertura `SearchModel`/mapeo ≥ 85%; 0 warnings de concurrencia; `/speckit.analyze` OK.
- ☐ **Hito versión media completa** (listado + detalle + grid + filtros completos).

## Riesgos / notas
- Confirmar sensibilidad a mayúsculas/acentos del backend en búsquedas; añadir golden files si difiere de lo esperado.
