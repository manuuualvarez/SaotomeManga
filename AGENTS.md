# AGENTS.md — Subagentes recomendados (Fase 01, PLAN)

Cuatro subagentes especializados para trabajar este repo con Claude Code. Cada uno respeta la
constitución (`Docs/MDs/memory/constitution.md`) y las reglas de `CLAUDE.md` (MCP de Xcode
obligatorio, sin ediciones manuales del `.xcodeproj`, TDD, 0 warnings).

## swift-architect
- **Scope:** revisión de arquitectura. Vigila la separación por capas (Presentation → Application →
  Domain; Infrastructure implementa protocolos), la inversión de dependencias (P2) y que Domain no
  importe frameworks. Revisa PRs/fases contra la constitución y los artefactos SPEC/PLAN/TASKS.
- **Cuándo usarlo:** antes de cerrar cada fase (gate) y ante cualquier decisión estructural nueva.

## swift-testing-engineer
- **Scope:** diseño de tests y cobertura. Swift Testing (`@Test`, `#expect`, `#require`,
  parametrización), fakes por protocolo, tests deterministas (sin red real, reloj inyectado),
  pirámide unit/contract/integration/UI y el umbral ≥ 85% en Domain+Application.
- **Cuándo usarlo:** en el "Red" de cada tarea (diseñar el test que falla) y al auditar cobertura
  antes del gate.

## swiftdata-specialist
- **Scope:** modelado y migraciones SwiftData. `@Model` solo en Infrastructure con mapping a Domain,
  `ModelContainer` único (App Group para el widget), `ModelActor` fuera del MainActor,
  `VersionedSchema` + `SchemaMigrationPlan` desde v1.
- **Cuándo usarlo:** Fase 06 (persistencia), Fase 09 (sync/conflictos) y Fase 11 (widget/App Group).

## swiftui-designer
- **Scope:** layout, HIG y accesibilidad. Adaptación iPhone/iPad/visionOS, estados de carga/vacío/
  error de primera clase, Dynamic Type, VoiceOver, `accessibilityLabel` en portadas, String Catalog
  (es base + en) sin strings hardcodeados.
- **Cuándo usarlo:** Fases 05, 07, 08, 12 (UI) y Fase 13 (hardening de a11y/localización).
