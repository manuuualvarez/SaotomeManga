import Foundation

/// Wire-format de un manga (contrato: MangaDTO del OpenAPI).
/// `sypnosis` y `synopsis` se decodifican por separado porque el backend usa la
/// clave anómala en sus respuestas y la canónica en el esquema (anomalía documentada).
struct MangaDTO: Decodable {
    let id: Int
    let title: String
    let titleJapanese: String?
    let titleEnglish: String?
    let status: String
    let mainPicture: String?
    let sypnosis: String?
    let synopsis: String?
    let background: String?
    let startDate: Date?
    let endDate: Date?
    let score: Double
    let volumes: Int?
    let chapters: Int?
    let url: String?
    let authors: [AuthorDTO]
    let genres: [GenreDTO]
    let themes: [ThemeDTO]
    let demographics: [DemographicDTO]
}

extension MangaDTO {
    /// Mapea a dominio saneando las anomalías del contrato (FR-007).
    func toDomain() throws(DomainError) -> Manga {
        try Manga(
            id: id,
            title: title,
            titleJapanese: titleJapanese,
            titleEnglish: titleEnglish,
            status: Self.mangaStatus(fromWire: status),
            mainPicture: Self.url(fromWire: mainPicture),
            synopsis: sypnosis ?? synopsis,
            background: background,
            startDate: startDate,
            endDate: endDate,
            score: score,
            volumes: volumes,
            chapters: chapters,
            url: Self.url(fromWire: url),
            authors: authors.map { $0.toDomain() },
            genres: genres.map { $0.toDomain() },
            themes: themes.map { $0.toDomain() },
            demographics: demographics.map { $0.toDomain() },
        )
    }

    /// Sanea la anomalía documentada: comillas escapadas envolviendo la URL
    /// (`"\"https://…\""` → `https://…`).
    private static func url(fromWire raw: String?) -> URL? {
        guard let raw else { return nil }
        return URL(string: raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
    }

    private static func mangaStatus(fromWire raw: String) throws(DomainError) -> MangaStatus {
        switch raw {
        case "discontinued": return .discontinued
        case "on_hiatus": return .onHiatus
        case "currently_publishing": return .currentlyPublishing
        case "finished": return .finished
        case "none": return MangaStatus.none
        default: throw .mapping(field: "status")
        }
    }
}
