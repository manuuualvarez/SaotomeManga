//
//  SaotomeMangaUITests.swift
//  SaotomeMangaUITests
//
//  XCUITest (excepción documentada en la constitución §P5).
//  Solo smoke de arranque; los flujos E2E reales llegan en fases 05/07/09.
//

import XCTest

final class SaotomeMangaUITests: XCTestCase {
    @MainActor
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
