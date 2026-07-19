import Foundation

/// Autor o artista de un manga (contrato: AuthorDTO).
struct Author: Equatable, Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let role: AuthorRole
}

/// Rol de un autor. El contrato define "Story", "Art", "Story & Art" y "None";
/// `.unknown` protege frente a valores futuros del backend (decisión de la fase).
enum AuthorRole: Equatable {
    case story
    case art
    case storyAndArt
    case none
    case unknown(String)
}
