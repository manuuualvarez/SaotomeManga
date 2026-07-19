import Foundation

/// Entidad principal del catálogo (contrato: MangaDTO del OpenAPI).
struct Manga: Equatable, Identifiable {
    let id: Int
    let title: String
    let titleJapanese: String?
    let titleEnglish: String?
    let status: MangaStatus
    let mainPicture: URL?
    let synopsis: String?
    let background: String?
    let startDate: Date?
    let endDate: Date?
    let score: Double
    let volumes: Int?
    let chapters: Int?
    let url: URL?
    let authors: [Author]
    let genres: [Genre]
    let themes: [Theme]
    let demographics: [Demographic]
}
