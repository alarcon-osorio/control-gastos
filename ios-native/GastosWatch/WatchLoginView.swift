import SwiftUI

struct WatchLoginView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email = ""
    @State private var password = ""

    private var puedeEntrar: Bool {
        email.contains("@") && password.count >= 6 && !auth.cargando
    }

    var body: some View {
        ZStack {
            WatchFondo()

            ScrollView {
                VStack(spacing: 10) {
                    VStack(spacing: 4) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Gastos")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Tu control de gastos")
                            .font(.caption2)
                            .foregroundStyle(WatchTema.textoSecundario)
                    }
                    .padding(.bottom, 4)

                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(WatchTema.campoFondo)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(WatchTema.borde, lineWidth: 1)
                        )

                    SecureField("Contraseña", text: $password)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(WatchTema.campoFondo)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(WatchTema.borde, lineWidth: 1)
                        )

                    if let mensaje = auth.mensaje, !mensaje.isEmpty {
                        Text(mensaje)
                            .font(.caption2)
                            .foregroundStyle(WatchTema.rojo)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    WatchBotonPrincipal(
                        titulo: "Entrar",
                        icono: "arrow.right.circle.fill",
                        deshabilitado: !puedeEntrar,
                        cargando: auth.cargando
                    ) {
                        Task {
                            auth.mensaje = nil
                            let correo = email.trimmingCharacters(in: .whitespacesAndNewlines)
                            _ = await auth.login(email: correo, password: password)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 6)
            }
        }
    }
}
