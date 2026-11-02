import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var nombre = ""
    @State private var modoRegistro = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Gastos")
                    .font(.largeTitle.bold())
                if modoRegistro {
                    TextField("Nombre", text: $nombre)
                        .textFieldStyle(.roundedBorder)
                }
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                SecureField("Contraseña", text: $password)
                    .textFieldStyle(.roundedBorder)
                if let mensaje = auth.mensaje {
                    Text(mensaje)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                Button(modoRegistro ? "Crear cuenta" : "Iniciar sesión") {
                    Task {
                        if modoRegistro {
                            _ = await auth.registrar(nombre: nombre, email: email, password: password)
                        } else {
                            _ = await auth.login(email: email, password: password)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(auth.cargando)
                Button(modoRegistro ? "Ya tengo cuenta" : "Crear cuenta") {
                    modoRegistro.toggle()
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}