# FASE 04 — Seguridad y sesión dual (Keychain)

- **Versión objetivo:** Avanzada (habilitador) · **Depende de:** Fase 02, 03
- **Rama sugerida:** `004-security-session`
- **Estado:** ☐ Pendiente

> Objetivo: implementar el almacenamiento seguro (Keychain) y la **gestión de sesión dual** (access token
> corto en memoria + refresh token de larga duración en Keychain), incluyendo el interceptor de autenticación
> que adjunta el token, refresca el access de forma segura y maneja expiraciones/401. **No** incluye aún la UI
> de login (Fase 05); aquí está el motor de sesión, probado end-to-end con transporte simulado.

---

## SPEC — Qué y por qué

### Historias de usuario
- **US-008** — Como usuario, quiero permanecer con sesión iniciada de forma segura durante ~30 días sin volver a
  introducir credenciales, para una buena experiencia.
- **US-009** — Como app, quiero renovar automáticamente el access token cuando caduque, y reintentar la petición,
  para que las llamadas autenticadas no fallen por expiración.
- **US-010** — Como usuario, quiero que mis credenciales/refresh token nunca se guarden fuera del Keychain.

### Requisitos funcionales
- **FR-016** — `SecureStore` (protocolo) sobre Keychain: `save/read/delete` de items sensibles, con implementación de test en memoria.
- **FR-017** — `SessionManager` (`actor`) que mantiene: `refreshToken` (persistido en Keychain), `accessToken` (memoria) y su expiración.
- **FR-018** — Flujo de tokens contra la API: `POST /users/session/login` (Basic → refresh+access),
  `GET /users/session/access` (refresh → access corto, `expiresIn 3600`), y compat `/users/jwt/*` si se requiere.
- **FR-019** — `AuthInterceptor` que: adjunta `Authorization: Bearer <access>`; si falta/expira, obtiene uno nuevo vía refresh **una sola vez** (coalescing de refresh concurrentes); ante 401 tras refresh válido → cierra sesión.
- **FR-020** — `restoreSession()` al arranque: si hay refresh en Keychain, intenta obtener access; si el refresh caducó, marca sesión expirada.
- **FR-021** — `logout()` borra refresh de Keychain y limpia memoria.

### Requisitos no funcionales / seguridad
- **NFR-007** — Tokens/credenciales nunca en logs, `UserDefaults` ni SwiftData. Solo Keychain (refresh) y memoria (access).
- **NFR-008** — El refresh concurrente se **coalesce** (un solo refresh en vuelo; el resto espera el resultado) — sin _thundering herd_.
- **NFR-009** — `SessionManager` es un `actor`; el estado de sesión es aislado y `Sendable` hacia fuera.

### Fuera de alcance
UI de registro/login (Fase 05), sincronización de colección (Fase 09).

---

## PLAN — Cómo (técnico)

- **`SecureStore`** envuelve `SecItemAdd/Copy/Update/Delete` con accesibilidad `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- **`SessionManager` (actor):** guarda estado `SessionState` (`.signedOut`, `.active(access, expiry)`, `.expired`).
  Métodos: `currentAccessToken()` (refresca si hace falta, con coalescing), `signIn(refresh:access:)`, `restore()`, `signOut()`.
- **Coalescing:** una propiedad `inFlightRefresh: Task<Token, Error>?` dentro del actor; peticiones simultáneas reutilizan la misma `Task`.
- **`AuthInterceptor`:** decora al `APIClient` de la Fase 03 para endpoints autenticados; en 401 con access presumiblemente válido, invalida y reintenta una vez.
- **Reloj inyectable:** proveedor de fecha para poder testear expiraciones sin esperar (sin `Date()` directo).

### Decisiones abiertas
- `[NEEDS CLARIFICATION]`: usar `/users/session/*` (dual) como principal — confirmado. `/users/jwt/*` queda como fallback documentado.

---

## TASKS — Ejecución (TDD)

### ☐ 04-T001 — `SecureStore` sobre Keychain
- **Prerrequisito:** Fase 02 aprobada.
- **Contexto:** 🧹 `CLEAN` — componente de infraestructura aislado.
- **Test-first:** contra `InMemorySecureStore`: `save`→`read` devuelve lo guardado; `delete` elimina; sobrescritura actualiza; leer inexistente → nil. (El backend real de Keychain se valida en un test de integración de dispositivo, marcado.)
- **Tarea:** protocolo `SecureStore`, `KeychainSecureStore`, `InMemorySecureStore` (test).
- **DoD:** ☐ CRUD correcto en fake · ☐ API sin exponer detalles de Keychain al dominio · ☐ nada sensible en logs.

### ☐ 04-T002 — `SessionManager` (actor) con reloj inyectable
- **Prerrequisito:** 04-T001.
- **Contexto:** 🪆 `NESTED` — usa `SecureStore` recién creado.
- **Test-first:** `signIn` persiste refresh en store y expone access; con reloj avanzado más allá de la expiración, `currentAccessToken()` dispara refresh; `signOut` limpia store y estado.
- **Tarea:** `SessionManager` con `SessionState`, persistencia de refresh, expiración por reloj inyectado.
- **DoD:** ☐ transiciones de estado correctas · ☐ expiración detectada por reloj simulado · ☐ actor sin data races.

### ☐ 04-T003 — Flujo de tokens contra API (session login / access)
- **Prerrequisito:** 04-T002, Fase 03.
- **Contexto:** 🪆 `NESTED`.
- **Test-first:** con `StubTransport`: `sessionLogin(basic)` devuelve refresh+access y los guarda; `exchangeAccess(refresh)` devuelve access `expiresIn 3600`; refresh inválido → error de sesión expirada.
- **Tarea:** métodos de red `sessionLogin`, `exchangeAccess` (y `jwtLogin/refresh` de compat).
- **DoD:** ☐ Basic auth (base64) correcto · ☐ Bearer del refresh correcto · ☐ respuestas mapeadas a `SessionState`.

### ☐ 04-T004 — `AuthInterceptor` con coalescing y manejo de 401
- **Prerrequisito:** 04-T003.
- **Contexto:** 🪆 `NESTED` — depende del `SessionManager` y del cliente.
- **Test-first:** N peticiones concurrentes con access expirado disparan **un solo** refresh (contador en stub) y todas succeed; 401 tras refresh válido → `signOut` y error `.unauthorized`.
- **Tarea:** interceptor que adjunta Bearer, refresca (coalesced) y reintenta una vez.
- **DoD:** ☐ exactamente 1 refresh bajo concurrencia · ☐ reintento único tras refresh · ☐ logout en 401 persistente.

### ☐ 04-T005 — `restoreSession()` de arranque
- **Prerrequisito:** 04-T002, 04-T003.
- **Contexto:** 🧹 `CLEAN` — flujo de bootstrap, conviene aislarlo.
- **Test-first:** con refresh válido en store → estado `.active`; con refresh caducado → `.expired`; sin refresh → `.signedOut`.
- **Tarea:** `restore()` invocable al inicio de la app.
- **DoD:** ☐ los 3 escenarios cubiertos · ☐ no bloquea el MainActor.

---

## GATE DE VALIDACIÓN DE FASE 04
- ☐ Sesión dual operativa: refresh persistido en Keychain (fake en tests), access en memoria, expiración gestionada por reloj inyectado.
- ☐ Coalescing de refresh verificado bajo concurrencia (1 solo refresh); 401 persistente cierra sesión.
- ☐ Ningún secreto en logs/UserDefaults/SwiftData; `SessionManager` es `actor` sin data races.
- ☐ Cobertura de sesión/seguridad ≥ 85%; 0 warnings de concurrencia; `/speckit.analyze` OK.

## Riesgos / notas
- Añadir un test de integración de dispositivo (marcado, no CI) que valide Keychain real.
- Documentar política de expiración del refresh (30 días) y comportamiento offline (usar access en memoria mientras dure).
- **Nota (2026-07-18) — sin capability Keychain Sharing (deliberado):** el acceso básico a Keychain no
  requiere capability alguna (access group implícito del App ID); Keychain Sharing solo haría falta para
  compartir ítems entre targets, y este proyecto lo excluye por diseño: el widget no hace auth ni red
  (NFR-023 Fase 11) y ningún secreto sale del proceso de la app (NFR-024, constitución §6). Si alguna
  extensión futura necesitara llamadas autenticadas, sería un cambio de spec con decisión documentada,
  no un checkbox olvidado.
