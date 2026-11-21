import Foundation
import LocalAuthentication

enum BiometriaError: LocalizedError {
    case noDisponible

    var errorDescription: String? {
        switch self {
        case .noDisponible:
            return "Face ID no está disponible en este dispositivo."
        }
    }
}

enum Biometria {
    static func disponible() -> Bool {
        let contexto = LAContext()
        var error: NSError?
        return contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    @discardableResult
    static func autenticar(motivo: String) async throws -> LAContext {
        let contexto = LAContext()
        var error: NSError?
        guard contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometriaError.noDisponible
        }
        try await contexto.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: motivo
        )
        return contexto
    }
}
