import Foundation

/// Wire-format de una temática (contrato: ThemeDTO — clave `theme`).
struct ThemeDTO: Decodable {
    let id: UUID
    let theme: String
}

extension ThemeDTO {
    func toDomain() -> Theme {
        Theme(id: id, name: theme)
    }
}
