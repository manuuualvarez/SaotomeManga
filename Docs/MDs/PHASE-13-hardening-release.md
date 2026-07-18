# FASE 13 — Hardening, accesibilidad, localización y release

- **Versión objetivo:** Release · **Depende de:** Fases 07–12
- **Rama sugerida:** `013-hardening-release`
- **Estado:** ☐ Pendiente

> Objetivo: llevar la app de "funciona" a "entregable": endurecer seguridad y rendimiento, cerrar accesibilidad
> y localización, ejecutar la batería E2E completa y el chequeo de contrato contra la API real, y preparar el
> material y la configuración de publicación en App Store para todas las plataformas.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-040** — Como usuario, quiero una app fluida, accesible y localizada, que no pierda mis datos y que gestione bien los fallos.
- **US-041** — Como equipo, quiero validar que seguimos siendo compatibles con la API real antes de publicar.
- **US-042** — Como equipo, quiero material y configuración listos para subir a App Store en iOS/iPadOS/visionOS + widget.

### Requisitos funcionales
- **FR-075** — **Suite E2E** de los flujos críticos en todas las plataformas: registro→login→catálogo→añadir a colección→ver colección→logout; offline→online sync; widget; deep-links.
- **FR-076** — **Contract check** contra la API real (tests de integración opt-in) para detectar drift; actualizar golden files si el contrato cambió (revalidando Fase 02/03).
- **FR-077** — **Accesibilidad** auditada: VoiceOver en todas las pantallas, Dynamic Type XXL, contraste, foco, etiquetas de portada; corrección de hallazgos.
- **FR-078** — **Localización** completa (String Catalog), base español + al menos otro idioma de referencia; sin cadenas hardcodeadas.
- **FR-079** — **Rendimiento**: perfilar scroll/grid/imágenes con Instruments; objetivos de arranque y consumo de memoria; corregir cuellos.
- **FR-080** — **Seguridad**: revisión final (nada sensible en logs/UserDefaults/SwiftData; HTTPS; endurecer manejo del `App-Token`; ATS estricto).
- **FR-081** — **Resiliencia de datos**: verificar migración SwiftData desde una versión previa simulada sin pérdida.
- **FR-082** — **Release**: iconos, capturas, metadatos, privacidad (nutrition labels), configuración de firma/entitlements (App Group, notificaciones) por target; build de distribución.

### Requisitos no funcionales
- **NFR-028** — Cobertura global de Domain+Application se mantiene ≥ 85%; CI verde y warnings de concurrencia = 0.
- **NFR-029** — Presupuestos de rendimiento definidos y cumplidos (documentados).

### Fuera de alcance
Nuevas funcionalidades (esta fase estabiliza y publica lo existente).

---

## PLAN — Cómo (técnico)

- **E2E:** consolidar y ampliar los UITests por plataforma; matriz iPhone/iPad/visionOS; escenarios offline con red simulada.
- **Contract check:** job manual/programado que golpea la API real con un set reducido y compara estructura; alerta ante cambios.
- **Accesibilidad/Localización:** auditoría con Accessibility Inspector; extraer todas las cadenas al String Catalog; pseudo-localización.
- **Rendimiento:** Instruments (Time Profiler, Allocations, SwiftUI); presupuestos; ajustes de caché de imágenes/prefetch.
- **Seguridad:** repaso de logging, ATS, entitlements, secreto de app; checklist OWASP-mobile pertinente.
- **Release:** fastlane opcional; capturas por dispositivo; App Store Connect config.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]`: segundo idioma de localización de referencia (recomendado inglés). Confirmar.

---

## TASKS — Ejecución (TDD / verificación)

### ☐ 13-T001 — Suite E2E multiplataforma
- **Prerrequisito:** Fases 07–12 aprobadas.
- **Contexto:** 🧹 `CLEAN` — pasada de verificación transversal.
- **Test-first:** definir los escenarios E2E como specs ejecutables antes de completarlos; deben cubrir los flujos de FR-075.
- **Tarea:** implementar/ampliar UITests en iPhone/iPad/visionOS + escenarios offline.
- **DoD:** ☐ todos los flujos críticos verdes en las 3 plataformas · ☐ escenarios offline→online cubiertos.

### ☐ 13-T002 — Contract check contra API real
- **Prerrequisito:** Fase 02/03.
- **Contexto:** 🧹 `CLEAN`.
- **Test-first:** tests de integración opt-in que validan estructura de respuestas reales vs golden files.
- **Tarea:** job de contract check; si hay drift, actualizar golden files y revalidar mapping.
- **DoD:** ☐ estructura de API confirmada · ☐ golden files al día · ☐ mapping revalidado.

### ☐ 13-T003 — Accesibilidad y localización
- **Prerrequisito:** Fases de UI (07–12).
- **Contexto:** 🧹 `CLEAN`.
- **Test-first:** checklist de accesibilidad como criterios verificables; test de que no quedan cadenas sin localizar (script/lint).
- **Tarea:** correcciones de VoiceOver/Dynamic Type/contraste; extracción completa a String Catalog + 2º idioma.
- **DoD:** ☐ auditoría a11y sin bloqueantes · ☐ 0 cadenas hardcodeadas · ☐ 2 idiomas.

### ☐ 13-T004 — Rendimiento y resiliencia de datos
- **Prerrequisito:** 13-T001.
- **Contexto:** 🧹 `CLEAN`.
- **Test-first:** presupuestos de rendimiento como asserts donde sea posible; test de migración SwiftData v1→v(sig) simulada sin pérdida.
- **Tarea:** perfilar y corregir cuellos (scroll/imágenes/arranque); validar migración.
- **DoD:** ☐ presupuestos cumplidos y documentados · ☐ migración sin pérdida de datos.

### ☐ 13-T005 — Seguridad final
- **Prerrequisito:** todas las fases.
- **Contexto:** 🧹 `CLEAN`.
- **Test-first:** tests/lint que fallan si aparecen tokens/credenciales en logs o almacenamiento no seguro; verificación ATS.
- **Tarea:** repaso de logging, ATS estricto, entitlements, endurecimiento del `App-Token`.
- **DoD:** ☐ nada sensible fuera de Keychain/memoria · ☐ HTTPS/ATS estricto · ☐ entitlements correctos por target.

### ☐ 13-T006 — Preparación de release
- **Prerrequisito:** 13-T001..T005.
- **Contexto:** 🧹 `CLEAN`.
- **Test-first:** checklist de release como gate (firma, iconos, capturas, privacidad, builds de distribución por target).
- **Tarea:** assets, metadatos, App Store Connect, builds de distribución iOS/iPadOS/visionOS + widget.
- **DoD:** ☐ builds de distribución generados · ☐ material y privacidad completos · ☐ checklist de release en verde.

---

## GATE DE VALIDACIÓN DE FASE 13 (y del proyecto)
- ☐ E2E verde en iPhone/iPad/visionOS + widget; offline→online robusto.
- ☐ Contrato con la API real confirmado; golden files al día.
- ☐ Accesibilidad y localización cerradas; rendimiento dentro de presupuesto; migración de datos sin pérdida.
- ☐ Seguridad final verificada; builds de distribución listos por plataforma.
- ☐ Cobertura global ≥ 85%; CI verde; 0 warnings de concurrencia; `/speckit.analyze` global OK.
- ☐ **Proyecto Deluxe + extras listo para entrega/publicación.**

## Riesgos / notas
- El contract check puede revelar cambios del backend de terceros: reservar holgura para revalidar Fase 02/03 antes de publicar.
- Mantener este artefacto como checklist viva de release para futuras actualizaciones.
