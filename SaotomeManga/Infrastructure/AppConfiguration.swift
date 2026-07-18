//
//  AppConfiguration.swift
//  SaotomeManga
//
//  01-T004 — configuración por entorno. Los valores viven en Config/*.xcconfig,
//  llegan al Info.plist generado y se leen aquí. El secreto real (APP_TOKEN)
//  vive en Config/Secrets.xcconfig, fuera de git.
//

import Foundation

enum AppConfigurationError: Error, Equatable {
    case missingKey(String)
    case invalidURL(String)
}

/// Configuración inyectable de la app (API_BASE_URL, APP_TOKEN).
/// Producción: `AppConfiguration.fromBundle()`. Tests: init con diccionario fake.
struct AppConfiguration {
    let apiBaseURL: URL
    let appToken: String

    init(infoDictionary: [String: Any]) throws {
        guard let rawURL = infoDictionary["API_BASE_URL"] as? String, !rawURL.isEmpty else {
            throw AppConfigurationError.missingKey("API_BASE_URL")
        }
        // La constitución (§6) exige comunicación solo HTTPS.
        guard let url = URL(string: rawURL), url.scheme == "https" else {
            throw AppConfigurationError.invalidURL(rawURL)
        }
        guard let token = infoDictionary["APP_TOKEN"] as? String, !token.isEmpty else {
            throw AppConfigurationError.missingKey("APP_TOKEN")
        }
        apiBaseURL = url
        appToken = token
    }

    static func fromBundle(_ bundle: Bundle = .main) throws -> AppConfiguration {
        try AppConfiguration(infoDictionary: bundle.infoDictionary ?? [:])
    }
}
