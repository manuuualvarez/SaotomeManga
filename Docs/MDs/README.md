# Mis Mangas — Especificación por fases (Spec-Kit / Spec-Driven Development)

Especificación completa, **sin código**, para construir la app nativa **"Mis Mangas"** en su versión
**Deluxe + extras propios** con Claude Code siguiendo **Spec-Driven Development (Spec-Kit)** y **TDD**.

- **Stack:** SwiftUI · Swift 6.2 (modo lenguaje 6, **Strict Concurrency = Complete**, **Approachable Concurrency = YES**, `nonisolated` por defecto) · SwiftData · Swift Testing.
- **Plataformas:** iOS + iPadOS (obligatorio) · **visionOS** (2º dispositivo Deluxe) · **Widget** (Deluxe).
- **Auth:** sesión dual (access ~1h + refresh ~30 días; refresh en Keychain).
- **Idioma de la doc:** prosa en español; identificadores/IDs (`FR-###`, `US-###`, `T###`) en inglés.
- **API:** `https://mymanga-acacademy-5607149ebe3d.herokuapp.com` · OpenAPI en `/openapi/openapi.json`.

---

## Cómo está organizado

```
MisMangas-SpecKit/
├── README.md                         ← este índice
├── memory/
│   └── constitution.md               ← principios no negociables (Spec-Kit /constitution)
└── specs/
    ├── 000-roadmap.md                ← roadmap maestro: fases, dependencias, gates, estrategia de contexto
    ├── PHASE-01-project-setup.md
    ├── PHASE-02-domain-core.md
    ├── PHASE-03-networking.md
    ├── PHASE-04-security-session.md
    ├── PHASE-05-auth-flow.md
    ├── PHASE-06-persistence.md
    ├── PHASE-07-catalog.md
    ├── PHASE-08-search-filters.md
    ├── PHASE-09-collection-sync.md
    ├── PHASE-10-extras.md
    ├── PHASE-11-widget.md
    ├── PHASE-12-visionos.md
    └── PHASE-13-hardening-release.md
```

Cada `PHASE-XX-*.md` es autocontenido y tiene tres bloques alineados con Spec-Kit:
**SPEC** (qué/por qué: `US-###`, `FR-###`, `NFR-###`), **PLAN** (cómo, técnico) y **TASKS**
(lista ordenada `T###` con, para cada tarea: **prerrequisito · estrategia de contexto · test-first · tarea · criterios de aprobación/DoD**),
más su **Gate de validación** y sus **Riesgos**.

---

## Las 13 fases de un vistazo

| # | Fase | Versión | Depende de |
|---|---|---|---|
| 01 | Setup de proyecto y tooling | infra | 00 |
| 02 | Núcleo de dominio y contratos | infra | 01 |
| 03 | Capa de red / API client | básica | 02 |
| 04 | Seguridad y sesión dual (Keychain) | avanzada | 02, 03 |
| 05 | Autenticación de usuario | avanzada | 04 |
| 06 | Persistencia SwiftData | básica | 02 |
| 07 | Catálogo: listado, grid, detalle, portadas | básica/media | 03, 06 |
| 08 | Filtros y búsqueda | media | 03, 07 |
| 09 | Colección + sincronización nube | avanzada | 05, 06, 07 |
| 10 | Extras (stats, recomendaciones, notifs, App Intents) | extras | 09 |
| 11 | Widget de lectura (SwiftData compartido + deep-link) | deluxe | 06, 09 |
| 12 | Target visionOS | deluxe | 07, 08, 09 |
| 13 | Hardening, a11y, localización, release | release | 07–12 |

**Camino crítico:** `01 → 02 → 03 → 06 → 07` (demo básica) → `04 → 05 → 09` (avanzada) → `10 ∥ 11 ∥ 12` (deluxe/extras) → `13` (release).
Ver `specs/000-roadmap.md` para el grafo de dependencias completo y las ramas paralelizables.

---

## Cómo ejecutarlo con Claude Code + Spec-Kit

1. **Inicializa Spec-Kit** en el repo de la app (`specify init …`) y coloca `memory/constitution.md` como constitución del proyecto.
2. **Fija la constitución:** `/speckit.constitution` a partir de `memory/constitution.md`.
3. **Por cada fase, en orden del roadmap:**
   1. `/speckit.specify` ← bloque **SPEC** de la fase.
   2. `/speckit.clarify` ← resuelve los `[NEEDS CLARIFICATION]` marcados.
   3. `/speckit.plan` ← bloque **PLAN**.
   4. `/speckit.tasks` ← bloque **TASKS** (las `T###` ya vienen ordenadas y con DoD).
   5. `/speckit.analyze` ← coherencia spec/plan/tasks ↔ constitución.
   6. `/speckit.implement` ← ejecución **TDD** tarea a tarea (Red → Green → Refactor).
4. **No cierres una fase** hasta pasar su **Gate de validación**. No arranques la siguiente hasta que la anterior esté en verde (salvo ramas marcadas como paralelizables).

> Cada tarea indica su **estrategia de contexto**: 🧹 `CLEAN` (sesión nueva, cargar solo constitución + artefacto de la fase + contratos) o 🪆 `NESTED` (continuar en la sesión anterior). Respetarla mantiene el contexto enfocado y barato.

---

## Reglas de oro (resumen de la constitución)

- **TDD real:** ningún trozo de lógica sin test que falle primero. Cobertura Domain+Application ≥ 85% por fase (gate).
- **Concurrencia estricta:** 0 warnings; `nonisolated` por defecto; `MainActor` solo en UI; `actor` para estado compartido.
- **Capas puras:** Domain sin frameworks de IO/UI; acceso externo siempre por protocolo con doble implementación (real + test).
- **Seguridad:** refresh token y credenciales solo en Keychain; nunca en logs/UserDefaults/SwiftData.
- **Contrato:** el OpenAPI es la fuente única; golden files congelados por fase para contract tests.
- **Núcleo compartido:** carpetas `Domain`/`Application`/`Infrastructure` con target membership en iOS/iPadOS, visionOS y Widget; **sin Swift Packages** (constitución v1.1.0); cero lógica duplicada.

---

## Trazabilidad versión del enunciado → fases

- **Básica:** 01–03, 06, 07 (+ colección local de 09).
- **Media:** 07, 08.
- **Avanzada:** 04, 05, 09.
- **Deluxe:** 11 (widget) + 12 (visionOS).
- **Extras propios:** 10.

---

_Generado como paquete de especificación para revisión y ejecución con Claude Code. Ajusta los `[NEEDS CLARIFICATION]`
antes de `/speckit.plan` en cada fase._
