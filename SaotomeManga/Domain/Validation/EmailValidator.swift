/// Validación de formato de email en cliente (constitución §6, FR-009).
enum EmailValidator {
    /// Formato pragmático: `local@dominio.tld` con TLD de al menos 2 letras.
    static func isValid(_ email: String) -> Bool {
        email.wholeMatch(of: /[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}/) != nil
    }

    static func validate(_ email: String) throws(DomainError) {
        guard isValid(email) else { throw .invalidEmail }
    }
}
