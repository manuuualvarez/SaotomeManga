/// Sonda de la Fase 01 (01-T002): este archivo solo compila si el aislamiento
/// por defecto del target es `nonisolated` (sin @MainActor global implícito).
enum IsolationProbe {
    /// Sin anotar: bajo un default de @MainActor esta función quedaría aislada al main actor.
    private static func unannotated() -> Int {
        42
    }

    /// `nonisolated` explícito llamando síncronamente a la función sin anotar:
    /// esta llamada no compilaría si `unannotated()` fuese @MainActor por defecto.
    nonisolated static func probe() -> Int {
        unannotated()
    }
}

/// Actor trivial para ejercitar aislamiento real en el smoke test (01-T002).
actor ProbeCounter {
    private var value = 0

    func increment() -> Int {
        value += 1
        return value
    }
}
