import Foundation

extension JSONDecoder {
    /// Decoder del contrato OpenAPI: fechas ISO-8601 con fallback para fracciones
    /// de segundo (PLAN Fase 02). Devuelve una instancia nueva por llamada:
    /// JSONDecoder no es Sendable y no debe compartirse entre tareas.
    static var mangaContract: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = try? Date(raw, strategy: .iso8601) {
                return date
            }
            if let date = try? Date(raw, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Fecha ISO-8601 no reconocida: \(raw)",
            )
        }
        return decoder
    }
}
