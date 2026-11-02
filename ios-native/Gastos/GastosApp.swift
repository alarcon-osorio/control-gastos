import SwiftUI

@main
struct GastosApp: App {
    @StateObject private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.autenticado {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(auth)
            .task {
                await auth.restaurarSesion()
            }
        }
    }
}