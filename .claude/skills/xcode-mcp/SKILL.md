---
name: xcode-mcp
description: Operar el proyecto SaotomeManga a través del servidor MCP de Xcode (Xcode Beta 27) — build, tests (Swift Testing), run + consola, lldb, previews, String Catalog, esquemas/destinos (iOS 26.5/27.0, visionOS), interacción con simulador y archivos del project navigator. Usar siempre que la tarea implique compilar, testear, ejecutar, depurar, localizar o verificar la app en Xcode.
---

# Xcode MCP — SaotomeManga (Xcode Beta 27)

Usage guide for the `xcode` MCP server in this project. The tools are **deferred**: load them with
`ToolSearch("select:mcp__xcode__<Tool1>,mcp__xcode__<Tool2>,...")` in **a single call** containing
every tool you expect to need.

**Hard rule (CLAUDE.md):** this MCP is the ONLY allowed way to build, test, run, or gather compiler
errors/warnings. Never fall back to `xcodebuild`, `swift build`/`swift test`, or any Xcode CLI tool —
if the MCP is unavailable, stop and ask the user to reconnect it (`/mcp`).

**Hard rule (CLAUDE.md):** NEVER edit `SaotomeManga.xcodeproj` by hand (`project.pbxproj`, schemes,
`xcshareddata`…). Only with the user's explicit authorization, in exceptional cases, explaining first
why it is needed and what will change. Project structure goes through `XcodeWrite`/`XcodeRM`/`XcodeMV`;
build settings, targets and scheme management go through the user in the Xcode UI.

## Golden rule: `tabIdentifier`

Almost every tool requires `tabIdentifier`. Get it **first** with `XcodeListWindows` (no parameters).
In this project it is usually `windowtab1` with workspace `.../SaotomeManga.xcodeproj`. If a tool fails
with an invalid tab, call `XcodeListWindows` again (the identifier changes if the user closes/reopens
windows). Requirement: the project must be **open in Xcode**; if there are no windows, ask the user to
open it.

## Project state (verified)

- Schemes: `SaotomeManga` (shared, the one with the test plan — **always work on this one**) and
  `MisMangasWidgetExtension` (widget target, no tests). Typical active destination: `iPhone 17 Pro (27.0)`.
  **Gotcha:** Xcode may silently activate another scheme (e.g. after creating a target); if `RunAllTests`
  reports an unexpected test plan or 0 tests, run `XcodeSwitchScheme { schemeName: "SaotomeManga" }`.
- Available simulators: iPhone 17 / Pro / Pro Max / 17e / Air and iPads on OS **26.5** and **27.0**,
  plus `Apple Vision Pro (27.0)` (visionOS).
- Test targets: `SaotomeMangaTests` (Swift Testing) and `SaotomeMangaUITests` (XCUITest).
- Target `MisMangasWidgetExtension` shares the core (Domain/Application/Infrastructure) via **per-file**
  membership exceptions: new core files must also be added to the widget target (File Inspector) —
  `XcodeWrite` alone registers them only in the folder's owning target.

## Workflows

### 1. Build + zero-warnings gate (constitution)
1. `BuildProject { tabIdentifier }` (add `buildForTesting: true` if you will run tests afterwards).
2. `GetBuildLog { severity: "warning" }` — **always with `severity: "warning"`, not the default `error`**:
   in this project warnings are errors (phase gate). The build is only "green" if it returns nothing.
3. Fine-grained diagnostics: `XcodeRefreshCodeIssuesInFile { filePath }` for a specific file;
   `XcodeListNavigatorIssues { severity: "warning" }` for what the Issue Navigator shows
   (includes package resolution and configuration problems, not just compilation).

### 2. Tests (TDD Red → Green → Refactor)
- `GetTestList` — lists tests from the active test plan (max 100 inline; the full list is written to
  `fullTestListPath`, grep-able by `TEST_TARGET` / `TEST_IDENTIFIER` / `TEST_FILE_PATH`).
- `RunSomeTests { tests: [{ targetName, testIdentifier }] }` — for the Red/Green cycle of a single task
  (identifiers come from `GetTestList`).
- `RunAllTests` — before closing a task or phase.
- New tests must exist and compile to appear in `GetTestList` (run `BuildProject` with
  `buildForTesting: true` first if the list comes back empty or stale).

### 3. Run the app and read its console
1. `RunProject { attachDebugger: true|false }` — equivalent to Cmd+R; returns once the app is running.
2. `GetConsoleOutput { pattern?, oslogSeverity?, tailLimit? }` — stdout/stderr + OSLog; use `pattern`
   (regex) and `contextLines` to avoid pulling 500 lines. Remember: the constitution forbids logging
   tokens; if they show up in the console, that is a bug to report.
3. `StopProject` when done.
- With `attachDebugger: true`, `InvokeDebuggerCommand { command }` runs real lldb (`bt`, `po x`,
  `breakpoint set -n ...`, `continue`) in the same session as the Xcode UI. Raise `timeout` for
  commands that resume execution.

### 4. Previews and snippets (quick UI/API verification)
- `RenderPreview { sourceFilePath }` — builds and returns a snapshot of the file's `#Preview`
  (`previewDefinitionIndexInFile` if there are several; `previewLocalizationOverride: "en"` to verify
  the English localization — the base is Spanish). Supports variants and timeline (widgets) via
  `supportedCanvasControlOverrides` from a previous invocation.
- `RunCodeSnippet { codeSnippet, sourceFilePath, purpose }` — runs a snippet with `print` in the
  context of a project file (sees down to `fileprivate`). Useful for exploring iOS 26/27 APIs or
  validating `Codable` decoding without creating a permanent test. Not a substitute for TDD.

### 5. Schemes and destinations (multiplatform)
- `XcodeListRunDestinations` / `XcodeSwitchRunDestination { displayTitle }` — use the exact
  `displayTitle`, e.g. `"iPhone 17 Pro (27.0)"`, `"iPad (A16) (26.5)"`, `"Apple Vision Pro (27.0)"`.
  To validate visionOS (phase 12) just switch the destination; the target already supports xros.
- `XcodeListSchemes` / `XcodeSwitchScheme { schemeName }` — `SaotomeManga` (tests) and
  `MisMangasWidgetExtension` (widget, created 2026-07-18) exist; keep `SaotomeManga` active for
  build/test. Local Swift Packages are banned (constitution v1.1.0): Xcode Beta 27
  does not integrate their test targets from an `.xcodeproj`, so never propose one.

### 6. Files: project navigator, not filesystem
`XcodeRead/Write/Update/Glob/Grep/LS/MV/RM/MakeDir` operate on the **Xcode project organization**
(e.g. `SaotomeManga/ContentView.swift`), not on absolute disk paths.
- **Create new Swift files with `XcodeWrite`**, not with filesystem Write: it registers them in the
  project/target automatically (with Write you would have to edit the pbxproj by hand).
- `XcodeRM` moves files to the Trash by default (`deleteFiles: true`) and removes them from the project.
- Output of `XcodeRead`/`XcodeGrep` comes JSON-escaped (`\n`, `\"`, `\\`); inputs of
  `XcodeWrite`/`XcodeUpdate` use literal characters.
- For docs (`Docs/`, `CLAUDE.md`) and anything that does not belong to a target, keep using the normal
  filesystem tools.

### 7. String Catalog and localization (es base + en, hard rule)
- **Before touching `StringCatalogRead`/`StringCatalogContext`/`StringCatalogEdit`/`LocalizationPlanner`
  you must activate the `xcode-integration:translation` skill (key read/edit) or
  `xcode-integration:translation-coordinator` (Read/Planner) — the tools require it.**
- Typical flow: `LocalizationPlanner { targetLocaleIdentifier: "en" }` → `StringCatalogRead` (keys by
  state) → `StringCatalogContext` (context + source value) → `StringCatalogEdit` (simple translation,
  with plurals/substitutions or per-device variations).
- Verify with `RenderPreview` + `previewLocalizationOverride`.

### 8. Simulator interaction (manual E2E verification)
1. `DeviceInteractionStartSession { sessionIdentifier: "Verify X Flow", deviceIdentifier? }` — call it
   **early** (booting the simulator takes time); it reuses the active destination if no device is passed.
2. `DeviceInteractionInstallAndRun` after every code or device change.
3. `DeviceInteractionSynthesize { interactionCommand }` — taps/swipes/typing; each call returns a
   screenshot + UI hierarchy. **Base coordinates on the latest hierarchy, never on the screenshot.**
4. **Always close** with `DeviceInteractionEndSession` — an open session is expensive and affects the
   user-facing UI.

### 9. Documentation and other diagnostics
- `DocumentationSearch { query, frameworks? }` — official Apple documentation (includes beta 26/27 SDK
  APIs, more reliable than trained knowledge for recent SwiftData/SwiftUI).
  Complements the `cupertino` MCP already available in this repo.
- `GetFileCompilerFlags` / `UpdateFileCompilerFlags` — per-file flags; almost never applicable in Swift
  (the compilation unit is the module): prefer target build settings. Never edit the pbxproj by hand.
- `GetTopCrashIssues` / `GetCrashIssueLogs` / `GetTopFieldPerformanceIssues` / `GetFieldPerformanceIssueLogs`
  — App Store Connect field data (App Store/TestFlight). **Not applicable yet**: this app is not
  published; relevant in phase 13 (release) or never during the evaluation.

## Project rules that shape MCP usage

- Zero-warnings gate ⇒ after every build, check `GetBuildLog` with `severity: "warning"`.
- Mandatory TDD ⇒ the order is: write test (XcodeWrite) → `RunSomeTests` red → implement →
  green → `RunAllTests`.
- No hardcoded strings ⇒ every new UI string goes through the String Catalog (section 7).
- Pure Presentation/Domain ⇒ `RunCodeSnippet` is for exploration, not for sneaking in untested logic.
