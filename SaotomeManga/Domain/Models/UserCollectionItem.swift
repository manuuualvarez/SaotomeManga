import Foundation

/// Entrada de la colección personal del usuario (contrato: UserMangaCollectionDTO).
struct UserCollectionItem: Equatable, Identifiable {
    let id: UUID
    let manga: Manga
    let volumesOwned: [Int]
    let readingVolume: Int?
    let completeCollection: Bool
}
