# ADR-000 — Elección del stack técnico

- **Estado:** Aceptada · **Fecha:** 2026-07-18 · **Fase:** 01
- **Relacionado:** `Docs/MDs/memory/constitution.md` (v1.1.0), `Docs/MDs/PHASE-01-project-setup.md` (D-001..D-009)

## Contexto

"Mis Mangas" es la práctica final del Swift Developer Program: app multiplataforma (iOS/iPadOS +
visionOS + Widget) que consume una API REST de +64k mangas con colección personal sincronizada en la
nube. El enunciado deja libertad técnica; la constitución fija principios no negociables (capas,
TDD, 0 warnings, sin librerías de terceros).

## Decisión

1. **SwiftUI + Observation (`@Observable`)** para toda la UI. Un único target de app multiplataforma
   (iOS/iPadOS/visionOS, device families 1,2,7) en lugar de targets por plataforma: menos duplicación,
   la UI se adapta por plataforma dentro del mismo target.
2. **Swift 6.2 en modo lenguaje 6** con concurrencia estricta completa, **Approachable Concurrency**
   y **`nonisolated` por defecto** (`SWIFT_DEFAULT_ACTOR_ISOLATION`). Los errores de concurrencia se
   detectan en compilación; `@MainActor` solo explícito en UI. Warnings tratados como errores
   (`SWIFT_TREAT_WARNINGS_AS_ERRORS`) en los tres targets.
3. **SwiftData** como persistencia local (cache/offline; la API es la fuente de verdad), con
   `@Model` confinado a Infrastructure, `VersionedSchema` desde v1 y store en App Group para el widget.
4. **Swift Testing** (`@Test`/`#expect`) para unit/contract/integration; XCUITest solo para UI
   (excepción documentada). TDD Red → Green → Refactor por tarea; cobertura Domain+Application ≥ 85%.
5. **Cero dependencias de terceros en el producto**: JSON con `Codable`, red con `URLSession`,
   secretos con Keychain/Security. SwiftLint/SwiftFormat se usan solo como tooling de desarrollo
   (no enlazan con la app), corriendo en CI y pre-commit.
6. **Núcleo por capas como carpetas** (`Domain/`, `Application/`, `Infrastructure/`) dentro del
   target, compartidas por target membership — **sin Swift Packages locales**: Xcode Beta 27 no
   integra sus test targets desde un `.xcodeproj`, lo que rompe el TDD (ver D-006; constitución
   §7 v1.1.0). La disciplina de capas se sostiene por convención y revisión.
7. **Configuración por entorno con `.xcconfig`** (`API_BASE_URL`, `APP_TOKEN`) inyectada al
   Info.plist generado y leída por `AppConfiguration` (Infrastructure); el secreto real vive en
   `Config/Secrets.xcconfig`, fuera de git.
8. **Flujo de trabajo**: builds/tests locales exclusivamente vía el **servidor MCP de Xcode**
   (regla dura de `CLAUDE.md`); `xcodebuild` queda reservado para CI (GitHub Actions).

## Consecuencias

- (+) Un solo lenguaje de concurrencia en todo el código desde el día 1; los data races son errores de compilación.
- (+) Sin fronteras de módulo, el build es más simple y los tests ven todo con `@testable import`.
- (−) La separación por capas no la impone el compilador: exige revisión (subagente `swift-architect`).
- (−) El target único multiplataforma obliga a `#if os(...)`/vistas adaptativas en vez de targets dedicados.
- (~) Si Xcode corrige la integración de test targets de packages locales, la decisión 6 puede
  revisarse en una enmienda futura (la migración carpetas → package es mecánica).
