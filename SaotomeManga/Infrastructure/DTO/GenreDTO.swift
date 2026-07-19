import Foundation

/// Wire-format de un género (contrato: GenreDTO — clave `genre`).
struct GenreDTO: Decodable {
    let id: UUID
    let genre: String
}

extension GenreDTO {
    func toDomain() -> Genre {
        Genre(id: id, name: genre)
    }
}
