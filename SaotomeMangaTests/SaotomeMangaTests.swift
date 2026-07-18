//
//  SaotomeMangaTests.swift
//  SaotomeMangaTests
//
//  Smoke tests de la Fase 01 (01-T001 / 01-T002).
//

@testable import SaotomeManga
import Testing

struct CoreSmokeTests {
    // 01-T001: el esqueleto del núcleo compila y expone su constante de versión.
    @Test func `core skeleton builds`() {
        #expect(CoreVersion.current == "0.1.0")
    }

    // 01-T001: las tres capas existen y compilan dentro del target.
    @Test func `layers exist`() {
        #expect(String(describing: ApplicationLayer.self) == "ApplicationLayer")
        #expect(String(describing: InfrastructureLayer.self) == "InfrastructureLayer")
    }

    // 01-T002: `nonisolated` por defecto — ver IsolationProbe; si el aislamiento
    // por defecto fuese @MainActor, el target no compilaría.
    @Test func `nonisolated by default probe`() {
        #expect(IsolationProbe.probe() == 42)
    }

    // 01-T002: actor trivial + salto explícito al MainActor.
    @Test func `actor round trip and main actor hop`() async {
        let counter = ProbeCounter()
        let first = await counter.increment()
        let second = await counter.increment()
        #expect(first == 1)
        #expect(second == 2)
        await MainActor.run {
            MainActor.assertIsolated()
        }
    }
}
