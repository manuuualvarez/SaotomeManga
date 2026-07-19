//
//  DomainModelsTests.swift
//  SaotomeMangaTests
//
//  02-T002: modelos de dominio puros — igualdad por valor, identidad (Identifiable)
//  y paso entre fronteras de aislamiento (Sendable) sin frameworks de UI/IO.
//

import Foundation
@testable import SaotomeManga
import Testing

struct DomainModelsTests {
    private static let toriyamaID = UUID(uuidString: "998C1B16-E3DB-47D1-8157-8389B5345D03")!
    private static let actionID = UUID(uuidString: "72C8E862-334F-4F00-B8EC-E1E4125BB7CD")!
    private static let martialArtsID = UUID(uuidString: "ADC7CBC8-36B9-4E52-924A-4272B7B2CB2C")!
    private static let shounenID = UUID(uuidString: "5E05BBF1-A72E-4231-9487-71CFE508F9F9")!
    private static let entryID = UUID(uuidString: "0A5FBF57-A22B-47D9-AE9D-33ADFA04FD68")!

    /// Manga determinista basado en la fixture manga_42.json (Dragon Ball).
    private func makeManga(id: Int = 42, score: Double = 8.41) -> Manga {
        Manga(
            id: id,
            title: "Dragon Ball",
            titleJapanese: "ドラゴンボール",
            titleEnglish: "Dragon Ball",
            status: .finished,
            mainPicture: URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg"),
            synopsis: "Bulma, a headstrong 16-year-old girl…",
            background: nil,
            startDate: Date(timeIntervalSince1970: 469_756_800),
            endDate: Date(timeIntervalSince1970: 801_187_200),
            score: score,
            volumes: 42,
            chapters: 520,
            url: URL(string: "https://myanimelist.net/manga/42/Dragon_Ball"),
            authors: [Author(id: Self.toriyamaID, firstName: "Akira", lastName: "Toriyama", role: .storyAndArt)],
            genres: [Genre(id: Self.actionID, name: "Action")],
            themes: [Theme(id: Self.martialArtsID, name: "Martial Arts")],
            demographics: [Demographic(id: Self.shounenID, name: "Shounen")],
        )
    }

    // 02-T002: igualdad por valor e identidad estable.
    @Test func `manga equality and identity`() {
        let original = makeManga()
        let twin = makeManga()
        #expect(original == twin)
        #expect(original.id == 42)
        #expect(original != makeManga(score: 9.99))
    }

    // 02-T002: enum cerrado con fallback .unknown(String) — decisión de la fase.
    @Test func `author role keeps closed cases and unknown fallback`() {
        #expect(AuthorRole.storyAndArt != AuthorRole.story)
        #expect(AuthorRole.unknown("Editor") == AuthorRole.unknown("Editor"))
        #expect(AuthorRole.unknown("Editor") != AuthorRole.unknown("Inker"))
    }

    // 02-T002: Page<T> genérico con metadata de paginación (per → itemsPerPage).
    @Test func `page carries items and metadata`() {
        let metadata = PageMetadata(page: 1, itemsPerPage: 10, total: 64833)
        let page = Page(items: [makeManga()], metadata: metadata)
        #expect(page.items.count == 1)
        #expect(page.metadata.total == 64833)
        #expect(page == Page(items: [makeManga()], metadata: metadata))
    }

    @Test func `user collection item identity`() {
        let item = UserCollectionItem(
            id: Self.entryID,
            manga: makeManga(),
            volumesOwned: [1, 2, 3],
            readingVolume: 2,
            completeCollection: false,
        )
        #expect(item.id == Self.entryID)
        #expect(item.volumesOwned == [1, 2, 3])
        #expect(item == UserCollectionItem(
            id: Self.entryID,
            manga: makeManga(),
            volumesOwned: [1, 2, 3],
            readingVolume: 2,
            completeCollection: false,
        ))
    }

    // 02-T002: la sesión dual (access ~1 h / refresh ~30 d) y el perfil autenticado.
    @Test func `auth session and user profile model the dual session`() throws {
        let access = AuthSession(token: "token-en-memoria", expiresIn: 3600, tokenUse: .access, tokenType: "Bearer")
        let refresh = AuthSession(
            token: "token-en-keychain",
            expiresIn: 2_592_000,
            tokenUse: .refresh,
            tokenType: "Bearer",
        )
        #expect(access.tokenUse == .access)
        #expect(refresh.tokenUse == .refresh)
        #expect(access != refresh)

        let profile = try UserProfile(
            id: #require(UUID(uuidString: "550E8400-E29B-41D4-A716-446655440000")),
            email: "user@example.com",
            role: "user",
            isActive: true,
            isAdmin: false,
        )
        #expect(profile.email == "user@example.com")
        #expect(!profile.isAdmin)
    }

    // 02-T002: los modelos cruzan fronteras de aislamiento — si no fuesen Sendable,
    // la captura en Task.detached no compilaría (concurrencia estricta).
    @Test func `domain models cross actor boundaries`() async {
        let page = Page(items: [makeManga()], metadata: PageMetadata(page: 1, itemsPerPage: 10, total: 64833))
        let item = UserCollectionItem(
            id: Self.entryID,
            manga: makeManga(),
            volumesOwned: [1],
            readingVolume: nil,
            completeCollection: true,
        )
        let echoedPage = await Task.detached { page }.value
        let echoedItem = await Task.detached { item }.value
        #expect(echoedPage == page)
        #expect(echoedItem == item)
    }
}
