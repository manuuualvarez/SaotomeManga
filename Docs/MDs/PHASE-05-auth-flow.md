# FASE 05 — Autenticación de usuario (registro / login / bootstrap)

- **Versión objetivo:** Avanzada · **Depende de:** Fase 04
- **Rama sugerida:** `005-auth-flow`
- **Estado:** ☐ Pendiente

> Objetivo: exponer el flujo de usuario de registro, login, logout y restauración de sesión al arranque,
> con sus pantallas SwiftUI, validación en cliente, estados de carga/error, y el enrutado raíz de la app
> (autenticado vs no autenticado). Usa el motor de sesión de la Fase 04.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-011** — Como visitante, quiero registrarme con email + contraseña para tener una cuenta.
- **US-012** — Como usuario registrado, quiero iniciar sesión y permanecer autenticado entre lanzamientos.
- **US-013** — Como usuario, quiero cerrar sesión y que se borren mis credenciales del dispositivo.
- **US-014** — Como usuario, al abrir la app quiero ir directo a mi contenido si mi sesión sigue válida.

### Requisitos funcionales
- **FR-022** — Caso de uso `RegisterUser`: valida email/password (Fase 02), llama `POST /users` con `App-Token`, maneja 201 y errores (email duplicado, validación).
- **FR-023** — Caso de uso `SignIn`: `POST /users/session/login` (Basic), guarda sesión (Fase 04), transiciona a autenticado.
- **FR-024** — Caso de uso `SignOut`: limpia sesión (Fase 04) y vuelve a pantalla de acceso.
- **FR-025** — `AppRootRouter`/estado raíz `@Observable` que decide `authenticating`/`signedIn`/`signedOut` a partir de `restore()`.
- **FR-026** — Pantallas: `RegisterView`, `LoginView`, `RootView` con estados de carga, error inline y validación en vivo; localizadas y accesibles.
- **FR-027** — Tras registro exitoso, opción de login inmediato (auto-login o navegación a login con email prellenado).

### Requisitos no funcionales
- **NFR-010** — Estado de UI en `@MainActor`; los casos de uso corren `nonisolated` y saltan a UI solo al final.
- **NFR-011** — Sin credenciales en logs; el campo password usa `SecureField`.

### Fuera de alcance
Contenido de catálogo/colección (fases 07/09); recuperación de contraseña (no soportada por la API → documentar como no disponible).

---

## PLAN — Cómo (técnico)

- **Casos de uso** en Application, dependiendo de protocolos (auth API + `SessionManager`), inyectados por `@Environment`.
- **Estado raíz:** `AppModel` `@Observable @MainActor` con `sessionPhase`. Al lanzar, invoca `restore()` (Fase 04).
- **Pantallas:** formularios con validación reactiva (deshabilitar botón hasta válido), spinner en envío, mapeo de `DomainError`/`NetworkError` a mensajes localizados.
- **Navegación:** `RootView` conmuta entre `AuthFlow` y `MainFlow` según fase de sesión.
- Tests de UI (XCUITest, excepción documentada) para el _happy path_ de registro→login→home y logout.

### Decisiones abiertas
- `[NEEDS CLARIFICATION]` (menor): ¿auto-login tras registro? Recomendado sí para reducir fricción; configurable.

---

## TASKS — Ejecución (TDD)

### ☐ 05-T001 — Casos de uso Register / SignIn / SignOut
- **Prerrequisito:** Fase 04 aprobada.
- **Contexto:** 🧹 `CLEAN` — lógica de aplicación, testeable sin UI.
- **Test-first:** `RegisterUser` rechaza email/password inválidos antes de red; con stub 201 → éxito; 409/400 → error mapeado. `SignIn` con credenciales OK guarda sesión; credenciales malas → error. `SignOut` limpia sesión.
- **Tarea:** implementar los tres casos de uso sobre protocolos.
- **DoD:** ☐ validación previa a red · ☐ mapeo de errores · ☐ efectos en `SessionManager` verificados con fake.

### ☐ 05-T002 — Estado raíz y bootstrap
- **Prerrequisito:** 05-T001.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** `AppModel` con `restore()` fake → fase `signedIn` si sesión activa, `signedOut` si no; transiciones tras signIn/signOut correctas.
- **Tarea:** `AppModel` `@Observable @MainActor` + `sessionPhase`.
- **DoD:** ☐ fases correctas · ☐ restore no bloquea UI · ☐ tests verdes.

### ☐ 05-T003 — Pantallas Register / Login (SwiftUI)
- **Prerrequisito:** 05-T001, 05-T002.
- **Contexto:** 🪆 `NESTED` — la UI depende de casos de uso y estado recién definidos.
- **Test-first:** tests de la lógica de formulario (`FormModel`): botón deshabilitado hasta validez, mensajes de error por campo, estado de envío. (+ un XCUITest happy-path).
- **Tarea:** `RegisterView`, `LoginView` con validación en vivo, `SecureField`, estados carga/error, localización.
- **DoD:** ☐ validación reactiva · ☐ estados carga/error/vacío · ☐ accesibilidad (labels, Dynamic Type) · ☐ XCUITest happy-path verde.

### ☐ 05-T004 — Enrutado raíz autenticado/no autenticado
- **Prerrequisito:** 05-T002, 05-T003.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** XCUITest: registro → (auto)login → home; logout → vuelve a login. Test de que 401 persistente (Fase 04) empuja a `signedOut`.
- **Tarea:** `RootView` conmutando flujos; reacción a expiración de sesión global.
- **DoD:** ☐ flujo completo E2E verde · ☐ expiración global redirige a login.

---

## GATE DE VALIDACIÓN DE FASE 05
- ☐ Registro, login, logout y restauración funcionan E2E (con transporte simulado) y por XCUITest happy-path.
- ☐ Validación en cliente previa a red; errores mapeados y localizados; password en `SecureField`, nunca en logs.
- ☐ Estado de UI en `@MainActor`, casos de uso `nonisolated`; 0 warnings de concurrencia.
- ☐ Cobertura Application (auth) ≥ 85%; `/speckit.analyze` OK.

## Riesgos / notas
- La API no ofrece recuperación de contraseña: mostrar copy honesto/soporte. Revisar en Fase 13.
- Considerar "Sign in with Apple" como extra futuro (no en alcance actual).
