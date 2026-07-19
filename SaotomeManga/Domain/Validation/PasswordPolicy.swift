/// Política de contraseñas en cliente (constitución §6, FR-009: mínimo 8 caracteres).
enum PasswordPolicy {
    static let minimumLength = 8

    static func isValid(_ password: String) -> Bool {
        password.count >= minimumLength
    }

    static func validate(_ password: String) throws(DomainError) {
        guard isValid(password) else { throw .weakPassword(minimumLength: minimumLength) }
    }
}
