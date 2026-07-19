import Foundation

/// Wire-format de una entrada de la colección del usuario
/// (contrato: UserMangaCollectionDTO — ID de entrada UUID, ID de manga Int).
struct UserMangaCollectionDTO: Decodable {
    let id: UUID
    let manga: MangaDTO
    let volumesOwned: [Int]
    let readingVolume: Int?
    let completeCollection: Bool
}

extension UserMangaCollectionDTO {
    func toDomain() throws(DomainError) -> UserCollectionItem {
        try UserCollectionItem(
            id: id,
            manga: manga.toDomain(),
            volumesOwned: volumesOwned,
            readingVolume: readingVolume,
            completeCollection: completeCollection,
        )
    }
}
