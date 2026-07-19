# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Mis Mangas" (Xcode project name: **SaotomeManga**) — a SwiftUI app for browsing a remote catalog of 64k+ mangas and managing a personal collection, with authenticated cloud sync. Targets iOS/iPadOS, visionOS, and a WidgetKit extension.

**Current state:** Phases 01 (project setup, tag `phase-01-project-setup`) and 02 (domain core + contracts, branch `002-domain-core`) are **CLOSED** — repo `manuuualvarez/SaotomeManga`, 68/68 tests green, 0 warnings. Domain models (`Domain/Models/`), typed errors (`Domain/Errors/`), validators (`Domain/Validation/`) and the DTO + mapping layer (`Infrastructure/DTO/`) exist with contract tests against golden files in `specs/002-domain-core/contracts/` (loaded via `#filePath`, not bundle resources — decisions D-011..D-019 in `Docs/MDs/PHASE-02-domain-core.md`). **The Swift 6.2 strict-concurrency configuration is complete and probe-verified: do NOT touch build settings or the pbxproj for it — ever.** The `MisMangasWidgetExtension` target already exists (created ahead of Phase 11; template placeholder only, Swift 6 strict + warnings-as-errors, shares Domain/Application/Infrastructure via per-file target membership — **new core files must also be given membership in the widget target when created**). Next up: Phase 03 (networking, `Docs/MDs/PHASE-03-networking.md`). The spec suite in `Docs/MDs/` drives all implementation, phase by phase via Spec-Driven Development:

- `Docs/MDs/memory/constitution.md` — **non-negotiable governance rules. Read it before implementing anything; on any conflict, the constitution wins.**
- `Docs/MDs/000-roadmap.md` — phase index, dependency graph, validation gates.
- `Docs/MDs/PHASE-XX-*.md` — one artifact per phase with SPEC / PLAN / TASKS sections and a validation gate. Work belongs to exactly one phase; a phase closes only when its gate checklist passes. Update the phase artifact (checkboxes, decisions) as you complete tasks.

Language convention: prose/docs in Spanish; identifiers, requirement IDs (`FR-###`, `US-###`, `T###`), and code in English. UI strings localized in Spanish (base) and English.

## Building & testing — Xcode MCP ONLY (hard rule)

**NEVER use `xcodebuild`, `swift build`/`swift test`, or any Xcode command-line tool for building, testing, running, or gathering compiler errors/warnings. No CLI compilation of any kind.** The only allowed path is the **`xcode` MCP server** (`BuildProject`, `RunAllTests`/`RunSomeTests`, `GetBuildLog`, `RunProject`, etc.). The single exception is a case the user explicitly authorizes.

- Follow the project skill `xcode-mcp` (`.claude/skills/xcode-mcp/SKILL.md`) for the full tool workflows (tabIdentifier, zero-warnings check, TDD cycle, destinations).
- If the MCP server is not connected or stops responding when you need it, **stop and ask the user to reconnect it** (`/mcp`) — do not fall back to CLI tools.
- Toolchain is Xcode Beta 27. Single scheme: `SaotomeManga`. Deployment targets are iOS 26+, so use an OS 26.5/27.0 destination (e.g. `iPhone 17 Pro (27.0)`, `iPad (A16) (26.5)`, `Apple Vision Pro (27.0)`).

**No local Swift Packages** (constitution v1.1.0): Xcode Beta 27 does not integrate the test targets of local packages referenced from an `.xcodeproj` (empty test plan, invisible in Edit Scheme), which breaks the TDD gate. The shared core lives as source folders in the app target and is shared with other targets (widget) via target membership.

## Hard rules (build gates, from the constitution)

- **NEVER touch `SaotomeManga.xcodeproj` directly** (`project.pbxproj`, `xcshareddata`, schemes, etc.) — no manual edits without the user's explicit authorization, and only in exceptional cases where you state exactly why it is needed and what will be changed before doing it. Project-structure changes go through the Xcode MCP tools (`XcodeWrite`/`XcodeRM`/`XcodeMV`, which update the project via Xcode itself) or through the user in the Xcode UI (build settings, targets, package/scheme management).

- **Warnings are errors.** Every phase must build with 0 warnings of any kind.
- **No third-party libraries.** Native implementations only; JSON exclusively via `Codable`.
- **No hardcoded UI strings.** Everything through the String Catalog (`.xcstrings`), Spanish base + English.
- **TDD is mandatory.** Red → Green → Refactor per task; no logic without a failing test first. Domain+Application coverage ≥ 85% per phase.
- **Swift Testing** (`@Test`, `#expect`, `#require`), not XCTest — except `XCUITest` for UI tests. Tests are deterministic: no real network, injected clock, fakes behind protocols.
- Secrets (`App-Token`, base URL) live in `.xcconfig`/Info.plist config, never hardcoded; refresh token and credentials only in Keychain; never log tokens/passwords/auth headers.

## Concurrency (Swift 6 strict mode — already configured in the project)

`SWIFT_VERSION = 6`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, and `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` are set in project.pbxproj. Consequences:

- Code is nonisolated by default; declare `@MainActor` explicitly and only where UI/UI-state requires it. Network/CPU work stays off the main actor.
- Do not mark `struct`/`enum` explicitly `Sendable` (value types infer it); use `actor` only for genuinely contended mutable state (caches, token store).
- `@unchecked Sendable`, `nonisolated(unsafe)`, and `@preconcurrency` are forbidden unless documented as an approved exception in the phase PLAN.

## Architecture

Strict layering with one-directional dependencies. Layers are folders inside the app target (`Presentation/`, `Application/`, `Domain/`, `Infrastructure/`) — no module boundaries enforce this, so discipline comes from convention and review. The committed folder map (which subfolder each phase creates) lives in the PLAN of `Docs/MDs/PHASE-01-project-setup.md`; create subfolders only when their phase arrives:

```
Presentation (SwiftUI views + @Observable state)
    → Application (use cases / stores / @Observable view models)
    → Domain (pure models, protocols, errors — imports no frameworks)
Infrastructure (URLSession, Keychain, SwiftData, widget bridge) implements Domain/Application protocols
```

- Domain never imports SwiftUI/SwiftData/URLSession/Security. Presentation never touches network/Keychain directly — always through a use case.
- Every external resource (API, Keychain, persistence, clock, notifications) is accessed via a protocol with two implementations: real + test fake (dependency inversion).
- UI state uses `@Observable` (Observation framework), injected via `@Environment` or initializers — not `ObservableObject`/`@Published`.

**Persistence (SwiftData):** `@Model` types live in Infrastructure only and are mapped to/from Domain models — never exposed to Presentation. One `ModelContainer` per app; writes off the MainActor go through a `ModelActor`. Migrations use `VersionedSchema` + `SchemaMigrationPlan` from v1. The store lives in an App Group container so the widget reads the same database. The cloud API is the source of truth for the user's collection; SwiftData is local cache/offline support.

**API:** base `https://mymanga-acacademy-5607149ebe3d.herokuapp.com`, contract at `/openapi/openapi.json` (single source of truth). User registration requires the `App-Token` header (config secret). Auth is a dual session: short-lived access token (~1h, in memory) + refresh token (~30 days, in Keychain), renewed via `/users/session/access`. Contract tests decode DTOs against golden-file JSON frozen per phase in `specs/<phase>/contracts/`.

**Platforms:** the project already supports `iphoneos iphonesimulator xros xrsimulator` (device families 1,2,7). Platform-specific UI is allowed; duplicated logic across targets is not.
