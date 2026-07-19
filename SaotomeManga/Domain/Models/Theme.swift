import Foundation

/// Temática o ambientación de un manga (contrato: ThemeDTO — clave `theme`).
struct Theme: Equatable, Identifiable {
    let id: UUID
    let name: String
}
