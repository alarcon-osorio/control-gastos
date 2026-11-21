import Foundation
import LocalAuthentication
import Security

struct DatosSesionLlavero: Codable {
    let accessToken: String
    let refreshToken: String
}

enum LlaveroSesion {
    private static let servicio = "com.alarconosorio.gastosnative.sesion"
    private static let cuenta = "usuario"

    private static var consultaBase: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: servicio,
            kSecAttrAccount: cuenta
        ]
    }

    @discardableResult
    static func guardar(accessToken: String, refreshToken: String) -> Bool {
        guard Biometria.disponible(),
              let datos = try? JSONEncoder().encode(
                  DatosSesionLlavero(accessToken: accessToken, refreshToken: refreshToken)
              ),
              let control = SecAccessControlCreateWithFlags(
                  nil,
                  kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                  [.biometryCurrentSet],
                  nil
              ) else { return false }

        eliminar()
        var consulta = consultaBase
        consulta[kSecValueData] = datos
        consulta[kSecAttrAccessControl] = control
        return SecItemAdd(consulta as CFDictionary, nil) == errSecSuccess
    }

    static func leer(contexto: LAContext) -> DatosSesionLlavero? {
        var consulta = consultaBase
        consulta[kSecReturnData] = true
        consulta[kSecMatchLimit] = kSecMatchLimitOne
        consulta[kSecUseAuthenticationContext] = contexto
        consulta[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip

        var resultado: CFTypeRef?
        guard SecItemCopyMatching(consulta as CFDictionary, &resultado) == errSecSuccess,
              let datos = resultado as? Data else { return nil }
        return try? JSONDecoder().decode(DatosSesionLlavero.self, from: datos)
    }

    static func eliminar() {
        SecItemDelete(consultaBase as CFDictionary)
    }
}
