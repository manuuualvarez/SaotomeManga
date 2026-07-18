# Roadmap Maestro — "Mis Mangas" (Premium / Deluxe+)

> Índice y plan de fases para Spec-Driven Development con Claude Code + Spec-Kit.
> Léelo junto a `memory/constitution.md`. Cada fase tiene su propio artefacto `PHASE-XX-*.md`
> con secciones **SPEC / PLAN / TASKS** y su **gate de validación**.

- **Alcance del proyecto:** versión **Deluxe + extras propios** del enunciado.
- **Plataformas:** iOS + iPadOS (obligatorio), **visionOS** (segundo dispositivo Deluxe), **Widget** (Deluxe).
- **Auth:** sesión dual (access ~1h + refresh ~30 días, refresh en Keychain).
- **Stack:** SwiftUI, Swift 6.2 (modo 6, strict concurrency complete, approachable concurrency, `nonisolated` por defecto),
  SwiftData, Swift Testing, TDD.

---

## 1. Mapa de versiones del enunciado → fases

| Versión enunciado | Qué exige | Fases que la cubren |
|---|---|---|
| **Básica** | Consulta de mangas, ≥1 categorización, guardar en colección local, mostrar colección, portada, layout iPhone/iPad | 01–07 (+ parte de 09 local) |
| **Media** | Filtros completos por todas las categorías + listado + detalle + grid | 07, 08 |
| **Avanzada** | Colección en la nube + registro/login + Keychain | 04, 05, 09 |
| **Deluxe** | ≥1 dispositivo Apple extra (**visionOS**) + widget estático de lectura | 11, 12 |
| **Extras propios** | Estadísticas, recomendaciones, notificaciones, App Intents/Spotlight | 10 |

---

## 2. Índice de fases

| # | Fase | Artefacto | Versión | Depende de |
|---|---|---|---|---|
| 00 | Gobernanza (constitución) | `memory/constitution.md` | — | — |
| 01 | Setup de proyecto y tooling | `PHASE-01-project-setup.md` | infra | 00 |
| 02 | Núcleo de dominio y contratos | `PHASE-02-domain-core.md` | infra | 01 |
| 03 | Capa de red / API client | `PHASE-03-networking.md` | básica | 02 |
| 04 | Seguridad y sesión dual (Keychain) | `PHASE-04-security-session.md` | avanzada | 02, 03 |
| 05 | Autenticación de usuario (registro/login) | `PHASE-05-auth-flow.md` | avanzada | 04 |
| 06 | Persistencia SwiftData | `PHASE-06-persistence.md` | básica | 02 |
| 07 | Catálogo: listado, grid, detalle, portadas | `PHASE-07-catalog.md` | básica/media | 03, 06 |
| 08 | Filtros y búsqueda | `PHASE-08-search-filters.md` | media | 03, 07 |
| 09 | Colección + sincronización nube | `PHASE-09-collection-sync.md` | avanzada | 05, 06, 07 |
| 10 | Extras propios (stats, recomendaciones, notifs, App Intents) | `PHASE-10-extras.md` | extras | 09 |
| 11 | Widget de lectura (WidgetKit + SwiftData en App Group) | `PHASE-11-widget.md` | deluxe | 06, 09 |
| 12 | Target visionOS | `PHASE-12-visionos.md` | deluxe | 07, 08, 09 |
| 13 | Hardening, accesibilidad, localización, release | `PHASE-13-hardening-release.md` | release | 07–12 |

---

## 3. Grafo de dependencias

```
00 Constitución
        │
01 Setup ──► 02 Domain ──►┬─► 03 Networking ─┐
                          │                   ├─► 07 Catálogo ─► 08 Filtros/Búsqueda
                          ├─► 06 SwiftData ───┘        │
                          │                            │
                          └─► 04 Seguridad ─► 05 Auth ─┴─► 09 Colección+Sync
                                                                 │
                          ┌──────────────────────────────────────┤
                          ▼                ▼                      ▼
                      10 Extras       11 Widget              12 visionOS
                          └────────────────┴──────────────────────┘
                                           ▼
                                 13 Hardening & Release
```

**Paralelizable** (una vez cerrada la 02): las ramas **03 Networking**, **06 SwiftData** y **04 Seguridad**
pueden avanzar en paralelo por equipos/sesiones distintas. **10 / 11 / 12** también son paralelizables entre sí
tras cerrar la 09.

---

## 4. Leyenda de estrategia de contexto

| Etiqueta | Significado | Cuándo |
|---|---|---|
| 🧹 `CLEAN` | Sesión nueva; cargar solo constitución + artefacto de la fase + contratos necesarios | Tarea autocontenida, cruza límite de módulo/capa |
| 🪆 `NESTED` | Continuar en la sesión de la tarea anterior | Iteración fina sobre el mismo tipo/archivo/decisión recién tomada |

Cada tarea (`T###`) de cada fase declara su etiqueta y la justificación.

---

## 5. Gates de validación (resumen)

Una fase se cierra ("Done") solo si pasa **todos** los checks de su artefacto. Gates transversales mínimos por fase:

1. **Compilación** Swift 6 modo estricto, **0 warnings** .
2. **0 WARNINGS** LOS WARNINGS SON CONSIDERADOS ERRORES.
3. **Tests** Swift Testing en verde (unit + contract + integration según fase).
4. **Cobertura** Domain+Application ≥ 85%.
5. **DoD específica** de cada tarea marcada y verificable.
6. **`/speckit.analyze`** sin inconsistencias contra la constitución ni entre spec/plan/tasks.
7. **Artefacto actualizado** (checkboxes de TASKS marcados; decisiones nuevas reflejadas en PLAN).
8. **JSON Serialization** nunca usar librerias de terceros, siempre usar Codable/Decodable/Encodable.
9. **0 Librerias de terceros** todo debe tener su implementación nativa, sin herramientas de terceros.
10. **PROHIBICION DE STRING HARDCODEADOS** siempre se debe usar el catalog de Strings del proyecto, en Ingles y Español, y nunca usar strings hardcodeados.

---

## 6. Convenciones de identificadores

- **US-###** historia de usuario · **FR-###** requisito funcional · **NFR-###** requisito no funcional.
- **T###** tarea (numeración local por fase, prefijo de fase implícito: p. ej. `01-T003`).
- **Golden files** de contrato: `specs/<fase>/contracts/<endpoint>.json`.
- Ramas git sugeridas: `NNN-slug-de-fase` (alineado con Spec-Kit), p. ej. `003-networking`.

---

## 7. Orden de ejecución recomendado (camino crítico)

`00 → 01 → 02 → (03 ∥ 06 ∥ 04) → 05 → 07 → 08 → 09 → (10 ∥ 11 ∥ 12) → 13`

El camino crítico hacia una demo funcional temprana (básica) es **01 → 02 → 03 → 06 → 07**.
El camino hacia la avanzada añade **04 → 05 → 09**. El resto son incrementos Deluxe/extras.
