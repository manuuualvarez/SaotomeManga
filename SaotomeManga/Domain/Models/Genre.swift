import Foundation

/// Género de un manga (contrato: GenreDTO — clave `genre`).
struct Genre: Equatable, Identifiable {
    let id: UUID
    let name: String
}
