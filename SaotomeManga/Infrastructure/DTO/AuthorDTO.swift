import Foundation

/// Wire-format de un autor (contrato: AuthorDTO).
struct AuthorDTO: Decodable {
    let id: UUID
    let firstName: String
    let lastName: String
    let role: String
}

extension AuthorDTO {
    /// Los roles del contrato son cerrados ("Story", "Art", "Story & Art", "None");
    /// cualquier otro valor cae en `.unknown` para no romper con datos futuros.
    func toDomain() -> Author {
        Author(id: id, firstName: firstName, lastName: lastName, role: Self.role(fromWire: role))
    }

    private static func role(fromWire raw: String) -> AuthorRole {
        switch raw {
        case "Story": .story
        case "Art": .art
        case "Story & Art": .storyAndArt
        case "None": AuthorRole.none
        default: .unknown(raw)
        }
    }
}
