//
//  ContractFixturesTests.swift
//  SaotomeMangaTests
//
//  02-T001: guard de las fixtures del contrato (golden files).
//  Los golden files viven en specs/002-domain-core/contracts/ (raíz del repo)
//  y se localizan vía #filePath para no depender de recursos del bundle de tests.
//

import Foundation
import Testing

/// Acceso a las fixtures congeladas del contrato OpenAPI (Fase 02).
enum ContractFixtures {
    /// Carpeta specs/002-domain-core/contracts/ resuelta desde la ruta de este archivo.
    static var contractsDirectory: URL {
        URL(fileURLWithPath: #filePath) // .../SaotomeMangaTests/ContractFixturesTests.swift
            .deletingLastPathComponent() // .../SaotomeMangaTests
            .deletingLastPathComponent() // raíz del repo
            .appending(path: "specs/002-domain-core/contracts")
    }

    static func data(for fixture: String) throws -> Data {
        try Data(contentsOf: contractsDirectory.appending(path: fixture))
    }

    /// Todas las fixtures que la Fase 02 congela del contrato.
    static let all: [String] = [
        "manga_42.json",
        "manga_quotes_anomaly.json",
        "list_mangas_p1.json",
        "authors.json",
        "authors_paged_p1.json",
        "genres.json",
        "demographics.json",
        "themes.json",
        "collection_item.json",
        "collection_mangas.json",
        "users_jwt_login.json",
        "users_session_token.json",
        "user_me.json",
    ]
}

struct ContractFixturesTests {
    // 02-T001: cada golden file existe y es JSON válido (guard de la propia fixture).
    @Test(arguments: ContractFixtures.all)
    func `golden file exists and is valid JSON`(fixture: String) throws {
        let data = try ContractFixtures.data(for: fixture)
        #expect(!data.isEmpty)
        _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    // 02-T001: el wire-format real usa la clave `sypnosis` (anomalía documentada).
    @Test func `manga fixture keeps sypnosis key`() throws {
        let raw = try #require(String(data: ContractFixtures.data(for: "manga_42.json"), encoding: .utf8))
        #expect(raw.contains("sypnosis"))
    }

    // 02-T001: fixture de regresión con comillas escapadas DENTRO de mainPicture/url
    // (anomalía documentada en el enunciado; hoy el backend responde limpio, pero el
    // mapper debe sanearla igualmente — FR-007).
    @Test func `quotes anomaly fixture wraps urls in escaped quotes`() throws {
        let raw = try #require(String(data: ContractFixtures.data(for: "manga_quotes_anomaly.json"), encoding: .utf8))
        #expect(raw.contains(#""\"https"#))
    }
}
