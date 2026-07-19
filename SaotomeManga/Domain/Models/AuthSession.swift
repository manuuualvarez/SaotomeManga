/// Token de la sesión dual (contrato: DualSessionTokenResponse).
/// El access (~1 h) vive solo en memoria; el refresh (~30 d) va al Keychain (Fase 04).
struct AuthSession: Equatable {
    let token: String
    let expiresIn: Int
    let tokenUse: TokenUse
    let tokenType: String
}

/// Uso de un token dentro de la sesión dual (contrato: `tokenUse`).
enum TokenUse {
    case access
    case refresh
}
