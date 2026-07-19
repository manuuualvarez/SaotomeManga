import Foundation

/// Respuesta de la sesión dual (contrato: DualSessionTokenResponse).
struct DualSessionTokenResponseDTO: Decodable {
    let token: String
    let expiresIn: Int
    let tokenUse: String
    let tokenType: String
}

extension DualSessionTokenResponseDTO {
    func toDomain() throws(DomainError) -> AuthSession {
        try AuthSession(
            token: token,
            expiresIn: expiresIn,
            tokenUse: Self.tokenUse(fromWire: tokenUse),
            tokenType: tokenType,
        )
    }

    private static func tokenUse(fromWire raw: String) throws(DomainError) -> TokenUse {
        switch raw {
        case "access": return .access
        case "refresh": return .refresh
        default: throw .mapping(field: "tokenUse")
        }
    }
}

/// Respuesta del login JWT legacy (contrato: JWTTokenResponse). Forma congelada
/// por completitud; la app usa la sesión dual (constitución §5).
struct JWTTokenResponseDTO: Decodable {
    let token: String
    let expiresIn: Int
    let tokenType: String
}

/// Usuario autenticado (contrato: UserResponse).
struct UserResponseDTO: Decodable {
    let id: UUID
    let email: String
    let role: String
    let isActive: Bool
    let isAdmin: Bool
}

extension UserResponseDTO {
    func toDomain() -> UserProfile {
        UserProfile(id: id, email: email, role: role, isActive: isActive, isAdmin: isAdmin)
    }
}
