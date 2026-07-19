//
//  ContractMappingTests.swift
//  SaotomeMangaTests
//
//  02-T003: contract tests — cada golden file decodifica su DTO y mapea a Domain
//  saneando las anomalías del wire-format (FR-007): comillas escapadas en
//  mainPicture/url, sinopsis como `sypnosis`, fechas ISO-8601, IDs Int vs UUID.
//

import Foundation
@testable import SaotomeManga
import Testing

struct ContractMappingTests {
    private func decode<D: Decodable>(_: D.Type, from fixture: String) throws -> D {
        try JSONDecoder.mangaContract.decode(D.self, from: ContractFixtures.data(for: fixture))
    }

    /// JSON mínimo de un manga con los campos requeridos, para tests de robustez.
    private func minimalMangaJSON(status: String, startDate: String? = nil) -> Data {
        var fields = [
            #""id":1"#,
            #""title":"X""#,
            #""status":"\#(status)""#,
            #""score":1.0"#,
            #""authors":[]"#,
            #""genres":[]"#,
            #""themes":[]"#,
            #""demographics":[]"#,
        ]
        if let startDate {
            fields.append(#""startDate":"\#(startDate)""#)
        }
        return Data(("{" + fields.joined(separator: ",") + "}").utf8)
    }

    /// manga_42.json → MangaDTO → Manga con todos los campos y colecciones anidadas.
    @Test func `manga 42 decodes and maps completely`() throws {
        let manga = try decode(MangaDTO.self, from: "manga_42.json").toDomain()
        #expect(manga.id == 42)
        #expect(manga.title == "Dragon Ball")
        #expect(manga.titleJapanese == "ドラゴンボール")
        #expect(manga.titleEnglish == "Dragon Ball")
        #expect(manga.status == .finished)
        #expect(manga.score == 8.41)
        #expect(manga.volumes == 42)
        #expect(manga.chapters == 520)
        #expect(manga.mainPicture == URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg"))
        #expect(manga.url == URL(string: "https://myanimelist.net/manga/42/Dragon_Ball"))

        // La sinopsis llega con la clave anómala `sypnosis` y debe sobrevivir al mapping.
        let synopsis = try #require(manga.synopsis)
        #expect(synopsis.hasPrefix("Bulma"))
        #expect(manga.background?.isEmpty == false)

        #expect(manga.startDate == Date(timeIntervalSince1970: 469_756_800)) // 1984-11-20T00:00:00Z
        #expect(manga.endDate == Date(timeIntervalSince1970: 801_187_200)) // 1995-05-23T00:00:00Z

        #expect(try manga.authors == [Author(
            id: #require(UUID(uuidString: "998C1B16-E3DB-47D1-8157-8389B5345D03")),
            firstName: "Akira",
            lastName: "Toriyama",
            role: .storyAndArt,
        )])
        #expect(manga.genres.map(\.name) == ["Action", "Adventure", "Comedy", "Sci-Fi"])
        #expect(manga.themes.map(\.name) == ["Martial Arts", "Super Power"])
        #expect(manga.demographics.map(\.name) == ["Shounen"])
    }

    /// manga_quotes_anomaly.json → el mapper des-escapa las comillas envolventes.
    @Test func `quotes anomaly is sanitized to clean urls`() throws {
        let manga = try decode(MangaDTO.self, from: "manga_quotes_anomaly.json").toDomain()
        #expect(manga.mainPicture == URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg"))
        #expect(manga.url == URL(string: "https://myanimelist.net/manga/42/Dragon_Ball"))
        #expect(manga.mainPicture?.absoluteString.contains("\"") == false)
    }

    /// list_mangas_p1.json → MangaPageDTO → Page<Manga> con metadata correcta.
    @Test func `manga page decodes with metadata`() throws {
        let page = try decode(MangaPageDTO.self, from: "list_mangas_p1.json").toDomain()
        #expect(page.metadata == PageMetadata(page: 1, itemsPerPage: 10, total: 64833))
        #expect(page.items.count == 10)
        let first = try #require(page.items.first)
        #expect(first.id == 1)
        #expect(first.title == "Monster")
        #expect(first.status == .finished)
        #expect(first.authors.map(\.lastName) == ["Urasawa"])
    }

    /// authors.json → [AuthorDTO] → [Author] con los roles del contrato.
    @Test func `authors list decodes and maps roles`() throws {
        let authors = try decode([AuthorDTO].self, from: "authors.json").map { $0.toDomain() }
        #expect(authors.count == 100)
        let first = try #require(authors.first)
        #expect(first.firstName == "Kentarou")
        #expect(first.lastName == "Miura")
        #expect(first.role == .storyAndArt)
        #expect(authors[1].role == .art)
    }

    /// authors_paged_p1.json → AuthorPageDTO → Page<Author>.
    @Test func `author page decodes with metadata`() throws {
        let page = try decode(AuthorPageDTO.self, from: "authors_paged_p1.json").toDomain()
        #expect(page.metadata.page == 1)
        #expect(page.metadata.itemsPerPage == 10)
        #expect(page.metadata.total == 25719)
        #expect(page.items.count == 10)
        let first = try #require(page.items.first)
        #expect(first.lastName == "Toozaki")
        #expect(first.role == .story)
    }

    /// Los endpoints de listado de genres/themes/demographics devuelven [String] plano,
    /// a diferencia de los DTO anidados con UUID dentro de MangaDTO (nota del contrato).
    @Test func `catalog string lists decode`() throws {
        let genres = try decode([String].self, from: "genres.json")
        let demographics = try decode([String].self, from: "demographics.json")
        let themes = try decode([String].self, from: "themes.json")
        #expect(genres.count == 21)
        #expect(genres.contains("Action"))
        #expect(demographics == ["Seinen", "Shounen", "Shoujo", "Josei", "Kids"])
        #expect(themes.count == 52)
        #expect(themes.contains("Martial Arts"))
    }

    /// collection_item.json → UserMangaCollectionDTO → UserCollectionItem (ID de entrada
    /// UUID, ID de manga Int — la dualidad de identificadores del contrato).
    @Test func `collection item decodes and maps`() throws {
        let item = try decode(UserMangaCollectionDTO.self, from: "collection_item.json").toDomain()
        #expect(item.id == UUID(uuidString: "660E8400-E29B-41D4-A716-446655440000"))
        #expect(item.volumesOwned == [1, 2, 3, 4, 5])
        #expect(item.readingVolume == 3)
        #expect(!item.completeCollection)
        #expect(item.manga.id == 13)
        #expect(item.manga.title == "One Piece")
        #expect(item.manga.status == .currentlyPublishing)
    }

    @Test func `collection list decodes and maps`() throws {
        let items = try decode([UserMangaCollectionDTO].self, from: "collection_mangas.json")
            .map { try $0.toDomain() }
        #expect(items.map(\.manga.id) == [13])
    }

    /// users_session_token.json → DualSessionTokenResponseDTO → AuthSession (refresh ~30 d).
    @Test func `dual session token maps to auth session`() throws {
        let session = try decode(DualSessionTokenResponseDTO.self, from: "users_session_token.json").toDomain()
        #expect(session.tokenUse == .refresh)
        #expect(session.expiresIn == 2_592_000)
        #expect(session.tokenType == "Bearer")
        #expect(!session.token.isEmpty)
    }

    /// users_jwt_login.json — forma congelada del login JWT legacy (la app usa sesión dual).
    @Test func `jwt login shape decodes`() throws {
        let response = try decode(JWTTokenResponseDTO.self, from: "users_jwt_login.json")
        #expect(response.expiresIn == 86400)
        #expect(response.tokenType == "Bearer")
    }

    /// user_me.json → UserResponseDTO → UserProfile.
    @Test func `user response maps to profile`() throws {
        let profile = try decode(UserResponseDTO.self, from: "user_me.json").toDomain()
        #expect(profile.id == UUID(uuidString: "550E8400-E29B-41D4-A716-446655440000"))
        #expect(profile.email == "user@example.com")
        #expect(profile.role == "user")
        #expect(profile.isActive)
        #expect(!profile.isAdmin)
    }

    /// Robustez más allá de los golden files: rol desconocido cae en .unknown(String)
    /// y estado desconocido lanza DomainError.mapping (muro de contención del contrato).
    @Test func `unknown author role falls back and unknown status throws`() throws {
        let authorJSON = Data(
            #"{"id":"6F0B6948-08C4-4761-8BE1-192E68AB0A2F","firstName":"A","lastName":"B","role":"Editor"}"#.utf8,
        )
        let author = try JSONDecoder.mangaContract.decode(AuthorDTO.self, from: authorJSON).toDomain()
        #expect(author.role == .unknown("Editor"))

        let mangaJSON = minimalMangaJSON(status: "reprinting")
        #expect(throws: DomainError.mapping(field: "status")) {
            try JSONDecoder.mangaContract.decode(MangaDTO.self, from: mangaJSON).toDomain()
        }
    }

    /// Fechas con fracciones de segundo — fallback del decoder previsto en el PLAN.
    @Test func `decoder accepts fractional second dates`() throws {
        let json = minimalMangaJSON(status: "finished", startDate: "1984-11-20T00:00:00.000Z")
        let manga = try JSONDecoder.mangaContract.decode(MangaDTO.self, from: json).toDomain()
        #expect(manga.startDate == Date(timeIntervalSince1970: 469_756_800))
    }

    /// Una fecha no ISO-8601 debe fallar en decodificación, no colarse como basura.
    @Test func `decoder rejects malformed dates`() {
        let json = minimalMangaJSON(status: "finished", startDate: "20/11/1984")
        #expect(throws: DecodingError.self) {
            try JSONDecoder.mangaContract.decode(MangaDTO.self, from: json)
        }
    }
}
