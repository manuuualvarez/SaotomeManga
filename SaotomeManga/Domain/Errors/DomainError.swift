/// Errores tipados del dominio (FR-008).
enum DomainError: Error, Equatable {
    /// El email no tiene un formato válido.
    case invalidEmail
    /// La contraseña no alcanza la longitud mínima de la política.
    case weakPassword(minimumLength: Int)
    /// El recurso solicitado no existe.
    case notFound
    /// Un valor del wire-format no pudo mapearse a dominio.
    case mapping(field: String)
}
