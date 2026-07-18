# FASE 10 — Extras propios (estadísticas, recomendaciones, notificaciones, App Intents)

- **Versión objetivo:** Extras propios (Deluxe+) · **Depende de:** Fase 09
- **Rama sugerida:** `010-extras`
- **Estado:** ☐ Pendiente

> Objetivo: diferenciar la app con funcionalidad **no exigida** por el enunciado, construida sobre la colección
> sincronizada: un **dashboard de estadísticas** de lectura, **recomendaciones** basadas en gustos, **recordatorios**
> con notificaciones locales, e integración con **App Intents / Spotlight / Shortcuts**. Cada extra es un
> incremento independiente y opcional (paralelizable con Fase 11/12).

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-031** — Como usuario, quiero un panel con estadísticas de mi colección (nº mangas, tomos poseídos, % leído, géneros/demografías favoritas).
- **US-032** — Como usuario, quiero recomendaciones de mangas afines a los géneros/temas/autores de mi colección.
- **US-033** — Como usuario, quiero recordatorios para seguir leyendo un manga que dejé a medias.
- **US-034** — Como usuario, quiero usar Siri/Atajos y Spotlight para abrir un manga o "qué estoy leyendo".

### Requisitos funcionales
- **FR-055** — `StatsEngine` (puro): calcula métricas agregadas de la colección (conteos, % leído global, top géneros/temas/demografías/autores, tomos totales poseídos/faltantes). Reutiliza el cálculo de progreso (Fase 09).
- **FR-056** — `StatsDashboardView`: tarjetas/gráficos accesibles con las métricas; estados vacío (colección vacía) y carga.
- **FR-057** — `RecommendationEngine`: a partir de los géneros/temas/autores dominantes en la colección, consulta la API (`mangaByGenre/Theme/Author`, `customSearch`) y propone mangas **no** presentes en la colección; explica el "por qué".
- **FR-058** — Notificaciones locales: permiso, programación de recordatorio por manga en lectura (frecuencia configurable), deep-link al detalle; respetar preferencias y no spamear.
- **FR-059** — App Intents: `OpenMangaIntent` (por id/título), `CurrentlyReadingIntent`; donación para Siri/Atajos; indexación en Spotlight (`CSSearchableItem`) de la colección para búsqueda del sistema.
- **FR-060** — Ajustes: pantalla de preferencias para activar/desactivar recordatorios y recomendaciones.

### Requisitos no funcionales
- **NFR-021** — Los cálculos de stats/recomendaciones son deterministas y testeables sin red (recomendaciones: mapeo criterios testeable; llamada real mockeable).
- **NFR-022** — Notificaciones y Spotlight no bloquean el MainActor; degradan con gracia si se deniega el permiso.

### Fuera de alcance
Recomendaciones con ML/servidor; analítica remota. Aquí, heurística local + endpoints existentes.

---

## PLAN — Cómo (técnico)

- **Stats:** `StatsEngine` puro sobre la colección de Domain; `StatsDashboardView` con gráficos accesibles (Swift Charts) y fallback textual para VoiceOver.
- **Recomendaciones:** derivar "perfil de gustos" (top-k géneros/temas/autores) → construir `CustomSearch`/consultas → filtrar los ya poseídos → ranking simple por afinidad. Todo el pipeline salvo la llamada es puro y testeable.
- **Notificaciones:** wrapper `NotificationScheduler` (protocolo, fake en tests) sobre `UNUserNotificationCenter`; deep-link mediante la ruta tipada de Fase 07.
- **App Intents/Spotlight:** `AppIntent`s en un módulo compartido; indexar colección al sincronizar (Fase 09) y desindexar al borrar.
- **Ajustes:** preferencias en almacenamiento no sensible (`UserDefaults`/AppStorage) — nunca tokens.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]`: alcance mínimo de extras a entregar (todos vs subconjunto). Recomendado priorizar **Stats + Recomendaciones**
  (mayor valor visible) y dejar Notificaciones/App Intents como sub-fases opcionales si el tiempo aprieta.

---

## TASKS — Ejecución (TDD)

### ☐ 10-T001 — `StatsEngine` (puro) + dashboard
- **Prerrequisito:** Fase 09 aprobada.
- **Contexto:** 🧹 `CLEAN`.
- **Test-first (parametrizado):** métricas correctas sobre colecciones de ejemplo (vacía, 1 manga, varios); top géneros/demografías; % leído global; tomos faltantes.
- **Tarea:** `StatsEngine` + `StatsDashboardView` (Swift Charts, accesible).
- **DoD:** ☐ métricas verificadas · ☐ estados vacío/carga · ☐ gráficos con alternativa VoiceOver.

### ☐ 10-T002 — `RecommendationEngine`
- **Prerrequisito:** 10-T001.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** perfil de gustos derivado correcto; el pipeline excluye mangas ya en colección; ranking por afinidad estable; llamada a API mockeada.
- **Tarea:** motor de recomendaciones + vista de "Para ti" con razón de recomendación.
- **DoD:** ☐ excluye poseídos · ☐ ranking testeado · ☐ explica el porqué · ☐ estados carga/vacío/error.

### ☐ 10-T003 — Notificaciones locales de lectura
- **Prerrequisito:** Fase 09.
- **Contexto:** 🧹 `CLEAN` — subsistema independiente.
- **Test-first:** con `NotificationScheduler` fake: programar recordatorio para un manga en lectura crea la solicitud esperada; desactivar en ajustes cancela; permiso denegado degrada sin crash.
- **Tarea:** `NotificationScheduler`, programación/cancelación, deep-link, permisos.
- **DoD:** ☐ programación/cancelación correctas · ☐ deep-link abre detalle · ☐ degradación con permiso denegado.

### ☐ 10-T004 — App Intents + Spotlight
- **Prerrequisito:** Fase 07, Fase 09.
- **Contexto:** 🧹 `CLEAN`.
- **Test-first:** `OpenMangaIntent` resuelve id/título a la ruta correcta (lógica testeable); indexación añade/elimina `CSSearchableItem` al añadir/borrar de colección (con índice fake).
- **Tarea:** `AppIntent`s, donaciones, indexación/desindexación Spotlight enganchada al sync.
- **DoD:** ☐ intents resuelven navegación · ☐ índice sincronizado con colección · ☐ sin bloquear MainActor.

### ☐ 10-T005 — Pantalla de ajustes/preferencias
- **Prerrequisito:** 10-T003.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** togglear preferencias persiste y afecta a scheduler/recomendaciones (verificado con fakes).
- **Tarea:** `SettingsView` con toggles de recordatorios/recomendaciones (AppStorage, nunca secretos).
- **DoD:** ☐ preferencias persistentes · ☐ efecto verificado · ☐ accesible.

---

## GATE DE VALIDACIÓN DE FASE 10
- ☐ Dashboard de estadísticas correcto y accesible; recomendaciones excluyendo poseídos con razón visible.
- ☐ Notificaciones de lectura programables/cancelables con deep-link; degradan con permiso denegado.
- ☐ App Intents/Spotlight operativos e indexación sincronizada con la colección.
- ☐ Cálculos puros con cobertura ≥ 85%; 0 warnings de concurrencia; `/speckit.analyze` OK.

## Riesgos / notas
- Priorizar por valor si el tiempo es limitado: Stats y Recomendaciones primero; Notificaciones y App Intents como sub-fases opcionales.
- Reutilizar el cálculo de progreso (09-T004) y el perfil de gustos también en el Widget (Fase 11) y visionOS (Fase 12).
