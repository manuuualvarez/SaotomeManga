import Foundation

/// Perfil del usuario autenticado (contrato: UserResponse).
struct UserProfile: Equatable, Identifiable {
    let id: UUID
    let email: String
    let role: String
    let isActive: Bool
    let isAdmin: Bool
}
