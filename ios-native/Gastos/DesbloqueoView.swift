import SwiftUI

struct DesbloqueoView: View {
    @EnvironmentObject var auth: AuthService
    @State private var intentando = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.357, green: 0.525, blue: 0.898),
                    Color(red: 0.482, green: 0.184, blue: 0.969)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "faceid")
                    .font(.system(size: 88, weight: .light))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("Bienvenido de nuevo")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Usa Face ID para entrar en Gastos")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                if let mensaje = auth.mensaje {
                    Text(mensaje)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        auth.desbloqueoAutoSolicitado = true
                        await desbloquear()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if auth.cargando {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "faceid")
                            Text("Desbloquear con Face ID")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(auth.cargando)
                .padding(.horizontal, 32)

                Button("Usar contraseña") {
                    auth.usarPassword()
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            }
        }
        .task {
            guard !auth.desbloqueoAutoSolicitado else { return }
            auth.desbloqueoAutoSolicitado = true
            await desbloquear()
        }
    }

    private func desbloquear() async {
        guard !intentando, !auth.cargando else { return }
        intentando = true
        defer { intentando = false }
        _ = await auth.desbloquearConBiometria()
    }
}
