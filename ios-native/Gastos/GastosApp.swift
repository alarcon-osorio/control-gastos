import SwiftUI

@main
struct GastosApp: App {
    @StateObject private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.inicializando {
                    SplashView()
                } else if auth.mostrarBienvenida {
                    BienvenidaView()
                } else if auth.autenticado {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(auth)
            .animation(.easeInOut(duration: 0.25), value: auth.inicializando)
            .animation(.easeInOut(duration: 0.25), value: auth.autenticado)
            .animation(.easeInOut(duration: 0.25), value: auth.mostrarBienvenida)
            .task {
                await auth.restaurarSesion()
            }
        }
    }
}

/// Pantalla de carga inicial que evita el "flash" del login
/// mientras se restaura la sesión de Supabase.
struct SplashView: View {
    @State private var animar = false

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

            VStack(spacing: 20) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(animar ? 1.0 : 0.85)
                    .opacity(animar ? 1.0 : 0.6)

                Text("Gastos")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                animar = true
            }
        }
    }
}

/// Pantalla de preload que se muestra después del login
/// hasta que el dashboard está listo.
struct BienvenidaView: View {
    @EnvironmentObject var auth: AuthService
    @State private var animar = false
    @State private var progreso: CGFloat = 0

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
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(animar ? 1.0 : 0.7)
                    .opacity(animar ? 1.0 : 0.5)

                VStack(spacing: 8) {
                    Text("¡Bienvenido!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if let nombre = auth.usuario?.nombre, !nombre.isEmpty {
                        Text(nombre)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.3)

                Text("Preparando tu dashboard…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animar = true
            }
            // Simula un breve preload mientras se preparan los datos
            Task {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                auth.mostrarBienvenida = false
            }
        }
    }
}
