//
//  AppConfigurationTests.swift
//  SaotomeMangaTests
//
//  01-T004 — configuración por entorno leída de Info.plist (derivado de .xcconfig).
//

import Foundation
@testable import SaotomeManga
import Testing

struct AppConfigurationTests {
    @Test func `loads valid configuration`() throws {
        let config = try AppConfiguration(infoDictionary: [
            "API_BASE_URL": "https://example.com",
            "APP_TOKEN": "token-123",
        ])
        #expect(config.apiBaseURL.absoluteString == "https://example.com")
        #expect(config.appToken == "token-123")
    }

    @Test func `rejects missing base URL`() {
        #expect(throws: AppConfigurationError.missingKey("API_BASE_URL")) {
            _ = try AppConfiguration(infoDictionary: ["APP_TOKEN": "t"])
        }
    }

    @Test func `rejects empty base URL`() {
        #expect(throws: AppConfigurationError.missingKey("API_BASE_URL")) {
            _ = try AppConfiguration(infoDictionary: ["API_BASE_URL": "", "APP_TOKEN": "t"])
        }
    }

    /// La constitución exige comunicación solo HTTPS (§6).
    @Test func `rejects non HTTPS base URL`() {
        #expect(throws: AppConfigurationError.invalidURL("http://insecure.example")) {
            _ = try AppConfiguration(infoDictionary: [
                "API_BASE_URL": "http://insecure.example",
                "APP_TOKEN": "t",
            ])
        }
    }

    @Test func `rejects missing token`() {
        #expect(throws: AppConfigurationError.missingKey("APP_TOKEN")) {
            _ = try AppConfiguration(infoDictionary: ["API_BASE_URL": "https://example.com"])
        }
    }
}
