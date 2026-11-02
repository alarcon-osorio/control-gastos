import Foundation
import Supabase
import Combine

@MainActor
final class AuthService: ObservableObject {
    @Published var usuario: Usuario?
    @Published var autenticado: Bool = false
    @Published var cargando: Bool = false
    @Published var mensaje: String?

    func restaurarSesion() async {
        do {
            let session = try await supabase.auth.session
            actualizarDesdeSesion(session)
        } catch {
            usuario = nil
            autenticado = false
        }
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
            mensaje = "Bienvenido."
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