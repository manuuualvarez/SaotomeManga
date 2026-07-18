# FASE 12 — Target visionOS (segundo dispositivo Deluxe)

- **Versión objetivo:** Deluxe · **Depende de:** Fase 07, 08, 09 — paralelizable con 10/11
- **Rama sugerida:** `012-visionos`
- **Estado:** ☐ Pendiente

> Objetivo: cumplir el requisito Deluxe de "al menos un dispositivo Apple más" con una app **nativa visionOS**
> que reutiliza todo el núcleo (Domain/Application/Infrastructure) y aporta una experiencia espacial idiomática
> (ventanas, ornaments, profundidad), no un simple _port_ del iPad.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-037** — Como usuario de Apple Vision Pro, quiero explorar el catálogo y mi colección en una experiencia espacial cómoda.
- **US-038** — Como usuario, quiero que mi sesión y mi colección estén sincronizadas igual que en iPhone/iPad.
- **US-039** — Como usuario, quiero navegar el detalle de un manga con la portada destacada aprovechando la profundidad.

### Requisitos funcionales
- **FR-069** — El soporte visionOS (mismo target multiplataforma `SaotomeManga`) reutiliza el núcleo compartido: casos de uso, sesión (Fase 04/05) y colección (Fase 09) **sin duplicar lógica**.
- **FR-070** — Navegación espacial idiomática: `WindowGroup` con `NavigationSplitView`, uso de ornaments para acciones/filtros y `.glassBackgroundEffect` donde aporte.
- **FR-071** — Detalle con portada destacada (profundidad/hover effects), respetando accesibilidad espacial.
- **FR-072** — Catálogo (Fase 07), filtros/búsqueda (Fase 08) y colección (Fase 09) disponibles y adaptados al layout de visionOS.
- **FR-073** — (Opcional) Un espacio volumétrico o vista destacada de "estoy leyendo" si aporta valor; si no, ventana estándar.
- **FR-074** — Widget/App Group compatible si aplica en la plataforma; si no, degradar sin romper.

### Requisitos no funcionales
- **NFR-026** — Reutilización máxima del núcleo; solo la capa de Presentation se especializa por plataforma.
- **NFR-027** — Cumplir directrices de interacción y accesibilidad de visionOS (targets de foco, tamaños, contraste).

### Fuera de alcance
Contenido inmersivo 3D complejo, `RealityKit` avanzado, multiusuario/SharePlay.

---

## PLAN — Cómo (técnico)

- **Composición:** el target visionOS instancia los mismos `@Observable` models y casos de uso; se crean vistas específicas
  (`Vision/…`) que reutilizan componentes compartibles (celdas, progreso) parametrizados por plataforma.
- **Adaptación:** revisar cada pantalla clave (catálogo, detalle, filtros, colección, stats) para el idiom espacial;
  ornaments para barra de filtros/acciones; hover effects en celdas y portada.
- **Compartición de assets/config:** mismos `.xcconfig`, App Group (si soportado), String Catalog.
- **Tests:** la lógica ya está cubierta por fases previas (mismos models); aquí, UITests de humo en el simulador visionOS
  para navegación catálogo→detalle, login y añadir a colección; snapshot de pantallas clave.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]`: ¿incluir un volumen/immersive space (FR-073) en el alcance de entrega o dejarlo como extra?
  Recomendado: ventana espacial pulida primero; volumen solo si sobra tiempo.

---

## TASKS — Ejecución (TDD)

### ☐ 12-T001 — Bootstrap del target visionOS con núcleo compartido
- **Prerrequisito:** Fase 09 aprobada (funcionalidad núcleo estable).
- **Contexto:** 🧹 `CLEAN` — nuevo target de plataforma.
- **Test-first:** UITest de humo: la app visionOS arranca, restaura sesión y muestra el catálogo (reutilizando models); un test verifica que reutiliza el núcleo compartido y no redefine lógica.
- **Tarea:** target (visionOS), entry `App`, inyección de dependencias reutilizando el núcleo.
- **DoD:** ☐ arranca en simulador visionOS · ☐ sesión/catálogo funcionan · ☐ cero lógica duplicada (solo Presentation).

### ☐ 12-T002 — Catálogo + filtros/búsqueda espaciales
- **Prerrequisito:** 12-T001, Fase 07/08.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** UITest: navegar catálogo (lista/grid), aplicar filtros vía ornament, abrir detalle; snapshot de layout.
- **Tarea:** vistas visionOS de catálogo/grid/filtros con ornaments y hover effects.
- **DoD:** ☐ catálogo y filtros operativos y adaptados · ☐ interacción espacial idiomática · ☐ accesibilidad.

### ☐ 12-T003 — Detalle espacial + colección
- **Prerrequisito:** 12-T002, Fase 09.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** UITest: abrir detalle con portada destacada; "añadir a colección" y verlo en "Mi Colección" (mismos casos de uso); sync coherente con iPhone/iPad (verificado por lógica compartida ya testeada).
- **Tarea:** `MangaDetailView` espacial (profundidad) + `CollectionView` visionOS.
- **DoD:** ☐ detalle y colección funcionales · ☐ progreso visible · ☐ paridad de datos con otras plataformas.

### ☐ 12-T004 — Pulido espacial y accesibilidad
- **Prerrequisito:** 12-T002, 12-T003.
- **Contexto:** 🧹 `CLEAN` — pasada transversal de calidad de la plataforma.
- **Test-first:** checklist de accesibilidad visionOS (foco, tamaños, contraste) verificada; snapshot final de pantallas clave.
- **Tarea:** ajustes de glass/ornaments/hover, Dynamic Type, foco; (opcional FR-073 si hay tiempo).
- **DoD:** ☐ directrices visionOS cumplidas · ☐ accesible · ☐ sin regresiones en otras plataformas.

---

## GATE DE VALIDACIÓN DE FASE 12
- ☐ App visionOS nativa que reutiliza el núcleo (0 lógica duplicada) con catálogo, filtros, detalle y colección adaptados al idiom espacial.
- ☐ Sesión y colección sincronizadas y a la par con iPhone/iPad; accesibilidad visionOS cumplida.
- ☐ UITests de humo verdes en simulador visionOS; 0 warnings de concurrencia; `/speckit.analyze` OK.
- ☐ **Hito Deluxe completo** junto con Fase 11 (segundo dispositivo + widget).

## Riesgos / notas
- Riesgo principal: tentación de duplicar lógica en la capa de vista. Mantener disciplina: solo Presentation cambia.
- El volumen/immersive space (FR-073) es opcional; no comprometer la entrega por él.
