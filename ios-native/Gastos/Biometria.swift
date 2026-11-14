import LocalAuthentication

/// Autenticación biométrica (Face ID / Touch ID).
enum Biometria {
    static func disponible() -> Bool {
        let contexto = LAContext()
        var error: NSError?
        return contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static func autenticar(motivo: String) async -> Bool {
        let contexto = LAContext()
        var error: NSError?
        guard contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            return try await contexto.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: motivo
            )
        } catch {
            return false
        }
    }
}
