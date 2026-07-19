import Foundation

/// Wire-format de una demografía (contrato: DemographicDTO — clave `demographic`).
struct DemographicDTO: Decodable {
    let id: UUID
    let demographic: String
}

extension DemographicDTO {
    func toDomain() -> Demographic {
        Demographic(id: id, name: demographic)
    }
}
