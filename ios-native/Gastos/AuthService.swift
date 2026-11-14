import Foundation
import Supabase
import Combine

@MainActor
final class AuthService: ObservableObject {
    @Published var usuario: Usuario?
    @Published var autenticado: Bool = false
    @Published var cargando: Bool = false
    @Published var mensaje: String?
    @Published var inicializando: Bool = true
    @Published var mostrarBienvenida: Bool = false

    private let claveInicioSesion = "gastos:sesionInicio"
    private let duracionSesion: TimeInterval = 12 * 60 * 60

    func restaurarSesion() async {
        do {
            let session = try await supabase.auth.session
            actualizarDesdeSesion(session)
            if autenticado {
                if inicioSesion == nil { marcarInicioSesion() }
                await verificarSesionVigente()
            }
        } catch {
            usuario = nil
            autenticado = false
        }
        inicializando = false
    }

    // MARK: - Vigencia de la sesión (12 horas)

    private var inicioSesion: Date? {
        let valor = UserDefaults.standard.double(forKey: claveInicioSesion)
        return valor > 0 ? Date(timeIntervalSince1970: valor) : nil
    }

    var tiempoRestanteSesion: TimeInterval {
        guard let inicio = inicioSesion else { return duracionSesion }
        return max(0, duracionSesion - Date().timeIntervalSince(inicio))
    }

    func marcarInicioSesion() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: claveInicioSesion)
    }

    func verificarSesionVigente() async {
        guard autenticado else { return }
        guard let inicio = inicioSesion else {
            marcarInicioSesion()
            return
        }
        if Date().timeIntervalSince(inicio) >= duracionSesion {
            await cerrarPorExpiracion()
        }
    }

    func vigilarSesion() async {
        while !Task.isCancelled {
            guard autenticado else { return }
            let restante = tiempoRestanteSesion
            if restante <= 0 {
                await cerrarPorExpiracion()
                return
            }
            let espera = min(restante, 60)
            try? await Task.sleep(nanoseconds: UInt64(espera * 1_000_000_000))
        }
    }

    private func cerrarPorExpiracion() async {
        try? await supabase.auth.signOut()
        usuario = nil
        autenticado = false
        mostrarBienvenida = false
        mensaje = "Tu sesión se cerró automáticamente después de 12 horas."
        UserDefaults.standard.removeObject(forKey: claveInicioSesion)
    }

    func registrar(nombre: String, email: String, password: String) async -> Bool {
        guard !nombre.trimmingCharacters(in: .whitespaces).isEmpty else {
            mensaje = "El nombre es obligatorio."
            return false
        }
        guard email.contains("@") else {
            mensaje = "Introduce un email válido."
            return false
        }
        guard password.count >= 6 else {
            mensaje = "La contraseña debe tener al menos 6 caracteres."
            return false
        }
        cargando = true
        defer { cargando = false }
        do {
            let response = try await supabase.auth.signUp(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password,
                data: ["nombre": .string(nombre.trimmingCharacters(in: .whitespaces))]
            )
            if response.session == nil {
                mensaje = "Cuenta creada. Revisa tu correo para confirmar (si está activado)."
            } else {
                actualizarDesdeSesion(response.session)
                marcarInicioSesion()
                mensaje = "Cuenta creada correctamente."
            }
            return true
        } catch {
            mensaje = "No se pudo completar la operación. Inténtalo de nuevo."
            return false
        }
    }

    func login(email: String, password: String) async -> Bool {
        cargando = true
        defer { cargando = false }
        do {
            let session = try await supabase.auth.signIn(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password
            )
            actualizarDesdeSesion(session)
            marcarInicioSesion()
            mostrarBienvenida = true
            return true
        } catch {
            mensaje = "Email o contraseña incorrectos."
            return false
        }
    }

    func logout() async {
        try? await supabase.auth.signOut()
        usuario = nil
        autenticado = false
        mostrarBienvenida = false
        UserDefaults.standard.removeObject(forKey: claveInicioSesion)
    }

    private func actualizarDesdeSesion(_ session: Session?) {
        guard let user = session?.user else {
            usuario = nil
            autenticado = false
            return
        }
        usuario = Usuario(
            id: user.id.uuidString.lowercased(),
            nombre: user.userMetadata["nombre"]?.stringValue ?? user.email?.split(separator: "@").first.map(String.init) ?? "Usuario",
            email: user.email ?? "",
            fechaRegistro: user.createdAt.ISO8601Format()
        )
        autenticado = true
    }
}
