import SwiftUI

@main
struct GastosWatchApp: App {
    @StateObject private var auth = AuthService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
                .task {
                    await auth.restaurarSesion()
                }
                .onChange(of: scenePhase) { _, fase in
                    guard fase == .active else { return }
                    Task { await auth.verificarSesionVigente() }
                }
        }
    }
}

struct WatchRootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        Group {
            if auth.inicializando {
                WatchCargandoView(texto: "Cargando…")
            } else if auth.autenticado {
                WatchHomeView()
            } else {
                WatchLoginView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.autenticado)
        .animation(.easeInOut(duration: 0.2), value: auth.inicializando)
    }
}

struct WatchCargandoView: View {
    var texto: String

    var body: some View {
        ZStack {
            WatchFondo()

            VStack(spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)

                Text(texto)
                    .font(.footnote)
                    .foregroundStyle(WatchTema.textoSecundario)
            }
        }
    }
}
