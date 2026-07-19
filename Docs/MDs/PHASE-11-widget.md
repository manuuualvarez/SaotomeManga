# FASE 11 — Widget de lectura (WidgetKit + SwiftData compartido por App Group)

- **Versión objetivo:** Deluxe · **Depende de:** Fase 06 (SwiftData), Fase 09 (colección) — paralelizable con 10/12
- **Rama sugerida:** `011-widget`
- **Estado:** ☐ Pendiente

> **Nota previa (2026-07-18):** el target **`MisMangasWidgetExtension` ya existe** — se creó adelantado
> tras la Fase 02 por decisión del usuario (es configuración estructural; ver enmienda D-008 en
> `PHASE-01-project-setup.md`), con Swift 6 estricto + warnings-as-errors y el núcleo
> (Domain/Application/Infrastructure) compartido por target membership. Hoy contiene la **plantilla** de
> Xcode. Sigue siendo trabajo de ESTA fase: verificar el store compartido desde la extensión (el
> entitlement App Group se activa en la Fase 06 — FR-030b), provider, vistas, refresco y deep-link.
> Ojo: la membership quedó registrada **por archivo** — los archivos del núcleo creados en
> fases posteriores (p. ej. los `@Model` de la Fase 06) deben marcarse también para el widget.

> Objetivo: cumplir el requisito Deluxe de **widget estático** que muestra los mangas que el usuario está leyendo
> y por qué tomo va. El widget **consume SwiftData directamente**: al activar el **App Group** compartido entre app
> y widget, el sistema propaga automáticamente el almacén de SwiftData a ambos targets (Xcode 27), de modo que el
> widget lee la **misma base de datos** que la app sin copiar snapshots. Al **pulsar un manga del widget se navega
> directamente al detalle de ese manga** en la app.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-035** — Como usuario, quiero un widget en mi pantalla de inicio con los mangas que estoy leyendo y el tomo actual, para verlo de un vistazo.
- **US-036** — Como usuario, quiero **tocar un manga del widget y abrir directamente su detalle** en la app.

### Requisitos funcionales
- **FR-061** — **App Group compartido** entre el target de app (iOS/iPadOS), el widget (y visionOS si aplica): entitlement `com.apple.security.application-groups` con el mismo identificador `group.cloud.manuelalvarez.SaotomeManga` en todos. **Aclaración 2026-07-18:** la capability se **activa en la Fase 06** (FR-030b, al nacer el store en el contenedor compartido); aquí se **verifica** el acceso real desde la extensión.
- **FR-062** — **SwiftData en contenedor de App Group:** el `ModelContainer` (Fase 06) se configura con `ModelConfiguration(groupContainer: .identifier("group.<bundle>"))` para que el store viva en el contenedor compartido y **se propague automáticamente** al widget. La app y el widget abren el **mismo** almacén; el widget **no** copia ni serializa snapshots aparte.
- **FR-063** — El widget consulta SwiftData (los `@Model` compartidos del núcleo) para obtener los ítems "en lectura" (colección con `readingVolume != nil`), ordenados y limitados según el tamaño del widget. Acceso **solo lectura** desde la extensión.
- **FR-064** — `TimelineProvider` que lee de SwiftData y genera entradas; la app invoca `WidgetCenter.shared.reloadAllTimelines()` tras cambios en la colección/lectura (Fase 09) para refrescar (SwiftData no notifica a la extensión por sí solo).
- **FR-065** — Vistas del widget en `systemSmall`, `systemMedium` y `systemLarge`: portada + título + "Tomo X / Y" + progreso (reutiliza el cálculo puro de progreso 09-T004).
- **FR-066** — **Deep-link por manga:** cada elemento usa `.widgetURL(URL)` (p. ej. `mismangas://manga/<id>`); al pulsar, la app abre **directamente** el detalle de ese manga (ruta tipada de Fase 07). En `systemSmall` (un solo elemento) el deep-link cubre todo el widget.
- **FR-067** — **Portadas en el widget:** miniatura de portada disponible offline en la extensión. Se persiste una miniatura ligera en SwiftData (atributo `coverThumbnail: Data?` con `@Attribute(.externalStorage)` en la entidad de manga/colección), poblada por la app al añadir/sincronizar; así viaja por el mismo store compartido sin descargas en el provider.
- **FR-068** — Estados: sin sesión / colección vacía / sin ítems en lectura → vista de marcador; datos aún no disponibles → placeholder de WidgetKit.

### Requisitos no funcionales
- **NFR-023** — El widget **no** hace login ni llamadas autenticadas ni de red: solo lee el store SwiftData compartido (rendimiento y privacidad).
- **NFR-024** — El store compartido no contiene datos sensibles (ni tokens ni email); los secretos siguen solo en Keychain (Fase 04), nunca en SwiftData.
- **NFR-025** — El acceso a SwiftData desde el widget respeta la concurrencia estricta (contexto propio de la extensión; sin compartir `ModelContext` entre procesos, solo el fichero de store).

### Fuera de alcance
Widgets interactivos con App Intents de acción (posible extra futuro); Live Activities.

---

## PLAN — Cómo (técnico)

- **Entitlements:** el App Group llega **ya activo desde la Fase 06** (FR-030b) en app y widget con `group.cloud.manuelalvarez.SaotomeManga`; aquí se verifica el acceso desde la extensión y la firma de cada target (se cierra en Fase 13-T005/T006).
- **Configuración de SwiftData (ajuste en Fase 06):** el `ModelContainer` de producción usa `ModelConfiguration(groupContainer: .identifier("group.<bundle>"))`. Con esto el fichero del store se crea en el contenedor del App Group y el widget, al construir su propio `ModelContainer` con el **mismo esquema y misma configuración de grupo**, abre el mismo almacén. El esquema vive en `Infrastructure/` (núcleo compartido, Fase 06) y sus archivos tienen target membership en la extensión, por lo que el widget lo usa sin duplicar modelos.
- **Lectura en el widget:** el `ReadingTimelineProvider` crea un `ModelContainer` (o usa un `@ModelActor` de solo lectura) apuntando a la configuración de grupo y hace un `FetchDescriptor` de la colección con `readingVolume != nil`, orden por última actualización y `fetchLimit` según tamaño.
- **Refresco:** la app llama `WidgetCenter.shared.reloadAllTimelines()` al terminar `syncNow()`/editar el tomo en lectura (enganche en Fase 09). El provider también puede fijar una política de `.after(...)` conservadora como red de seguridad.
- **Miniaturas:** el `ImageLoader`/caché de la app (Fase 07) genera y guarda una miniatura reducida en el atributo `coverThumbnail` (external storage) del ítem al añadir/sincronizar; el widget la lee del store. No se descargan imágenes en el provider (límites de la extensión).
- **Deep-link:** esquema URL propio `mismangas://manga/<id>` (o App Link) mapeado a la ruta tipada de detalle (Fase 07/07-T005); manejo de apertura en el `App`/`onOpenURL`.
- **Tests:** el `FetchDescriptor` de "en lectura" (selección/orden/límite), el parseo del deep-link y el provider (dado un store en memoria de App Group → entradas) son testeables sin UI; snapshot tests de las vistas por tamaño; UITest de tap→detalle.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]` (menor): cuántos mangas por tamaño (small=1, medium=2–3, large=4–6). Confirmar.
- `[NEEDS CLARIFICATION]` (menor): tamaño/píxeles objetivo de la miniatura `coverThumbnail` para minimizar el peso del store compartido.

---

## TASKS — Ejecución (TDD)

### ☐ 11-T001 — SwiftData compartido por App Group (verificación desde la extensión)
- **Prerrequisito:** Fase 06 (entitlement ya activo y store en contenedor de grupo — FR-030b) y Fase 09 aprobadas.
- **Contexto:** 🪆 `NESTED` — ajusta la configuración del `ModelContainer` de la Fase 06; conviene el contexto de persistencia cargado.
- **Test-first:** test que construye el `ModelContainer` con `ModelConfiguration(groupContainer:)`, escribe una entidad y la lee desde una segunda instancia con la **misma** configuración de grupo (simula el acceso del widget al mismo store); verifica que el esquema es el compartido del núcleo.
- **Tarea:** verificar el entitlement activo en ambos targets y el acceso de la extensión al store compartido; confirmar que los `@Model` de la Fase 06 tienen membership en la extensión (la membership es por archivo).
- **DoD:** ☐ store en contenedor de App Group · ☐ dos `ModelContainer` con la misma config comparten datos · ☐ entitlement verificado en ambos targets · ☐ ningún dato sensible en el store.

### ☐ 11-T002 — Miniatura de portada en el store compartido
- **Prerrequisito:** 11-T001, Fase 07 (ImageLoader).
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** al añadir/sincronizar un ítem con portada, se genera y persiste `coverThumbnail` (external storage) en la entidad; el ítem recuperado desde otra instancia del store expone la miniatura; ausencia de portada → `nil` sin fallo.
- **Tarea:** atributo `coverThumbnail: Data?` (`.externalStorage`), generación de miniatura en el pipeline de caché de la app.
- **DoD:** ☐ miniatura persistida y legible desde el store compartido · ☐ tamaño acotado · ☐ degradación sin portada.

### ☐ 11-T003 — Selección "en lectura" + `ReadingTimelineProvider`
- **Prerrequisito:** 11-T001.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** `FetchDescriptor` de colección con `readingVolume != nil`, orden y `fetchLimit` por tamaño, verificado sobre un store en memoria de grupo; provider dado ese store produce las entradas esperadas; sin ítems en lectura → entrada de marcador.
- **Tarea:** consulta de "en lectura" y `ReadingTimelineProvider` (solo lectura de SwiftData; sin red).
- **DoD:** ☐ selección/orden/límite correctos · ☐ entradas por estado (datos / vacío) · ☐ sin acceso a red ni auth.

### ☐ 11-T004 — Vistas del widget (3 tamaños) con progreso
- **Prerrequisito:** 11-T003, 09-T004 (progreso).
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** snapshot tests de `systemSmall/Medium/Large` con datos y en estado vacío; el "Tomo X/Y" y el progreso usan el cálculo puro de 09-T004.
- **Tarea:** vistas por tamaño con portada (miniatura), título, "Tomo X / Y" y barra de progreso; vista de marcador.
- **DoD:** ☐ 3 tamaños renderizan · ☐ progreso correcto · ☐ estados vacío/marcador · ☐ accesibilidad (labels de portada, Dynamic Type).

### ☐ 11-T005 — Refresco del timeline desde la app
- **Prerrequisito:** 11-T003, Fase 09.
- **Contexto:** 🪆 `NESTED` — engancha con el `SyncEngine`/casos de uso de colección.
- **Test-first:** tras editar el tomo en lectura o sincronizar, se invoca `WidgetCenter.shared.reloadAllTimelines()` (mock de `WidgetCenter`); el store compartido ya refleja el cambio antes de la recarga.
- **Tarea:** enganchar la recarga de timelines a los puntos de mutación de la colección.
- **DoD:** ☐ recarga disparada tras cambios · ☐ el widget refleja el último tomo en lectura.

### ☐ 11-T006 — Deep-link del widget al detalle del manga
- **Prerrequisito:** 11-T004, Fase 07 (07-T005 rutas tipadas).
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** parseo unitario de `mismangas://manga/<id>` → ruta de detalle correcta (incluye id inválido → sin navegación/crash); UITest: pulsar un manga del widget abre la app **directamente** en su detalle; en `systemSmall` el tap en cualquier zona navega a ese manga.
- **Tarea:** `.widgetURL` por elemento, esquema URL, manejo `onOpenURL` → navegación a detalle reutilizando la ruta tipada.
- **DoD:** ☐ deep-link abre el detalle correcto por id · ☐ id inválido manejado · ☐ `systemSmall` navegable completo.

---

## GATE DE VALIDACIÓN DE FASE 11
- ☐ App Group activo en app y widget; **SwiftData en contenedor compartido**, propagado automáticamente; el widget lee el **mismo store** (sin snapshots ni copias).
- ☐ Widget muestra mangas en lectura con tomo actual/total y progreso en 3 tamaños; miniaturas offline vía store compartido; **sin red ni auth** en la extensión.
- ☐ La app refresca el timeline (`reloadAllTimelines`) al cambiar la colección; el store refleja el cambio antes de recargar.
- ☐ **Pulsar un manga del widget abre directamente su detalle** en la app (deep-link por id); id inválido manejado.
- ☐ Store compartido sin datos sensibles (tokens/credenciales solo en Keychain).
- ☐ Cobertura de selección/provider/deep-link ≥ 85%; 0 warnings de concurrencia; `/speckit.analyze` OK.

## Riesgos / notas
- **Entitlement App Group** debe estar en **todos** los targets que abran el store (app, widget, y visionOS si comparte); verificar firma/provisioning en Fase 13.
- La miniatura en el store compartido añade peso: mantenerla pequeña (`coverThumbnail` con external storage) y solo para ítems en lectura si hace falta acotar.
- SwiftData no notifica cambios entre procesos: la recarga explícita del timeline (11-T005) es imprescindible para que el widget no quede desactualizado.
- Coordinación de escritura: el widget accede **solo lectura**; toda escritura la hace la app para evitar contención sobre el store compartido.
