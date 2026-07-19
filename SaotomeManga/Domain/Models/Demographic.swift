import Foundation

/// Demografía objetivo de un manga (contrato: DemographicDTO — clave `demographic`).
struct Demographic: Equatable, Identifiable {
    let id: UUID
    let name: String
}
