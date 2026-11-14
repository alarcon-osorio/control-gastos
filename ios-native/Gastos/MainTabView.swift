import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject var auth: AuthService
    @State private var selectedTab = 0
    @State private var showNewGasto = false

    init() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        nav.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = .white

        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)

        let aspecto = tab.stackedLayoutAppearance
        aspecto.normal.iconColor = UIColor.white.withAlphaComponent(0.55)
        aspecto.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.55)]
        aspecto.selected.iconColor = .white
        aspecto.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        tab.inlineLayoutAppearance = aspecto
        tab.compactInlineLayoutAppearance = aspecto

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = .white
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { DashboardView(selectedTab: $selectedTab, showNewGasto: $showNewGasto) }
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }
                .tag(0)

            NavigationStack { GastosListView(showNewGasto: $showNewGasto) }
                .tabItem { Label("Gastos", systemImage: "list.bullet") }
                .tag(1)

            NavigationStack { ObligacionesView() }
                .tabItem { Label("Obligaciones", systemImage: "checklist") }
                .tag(2)

            NavigationStack { ParametrosView() }
                .tabItem { Label("Parámetros", systemImage: "slider.horizontal.3") }
                .tag(3)

            NavigationStack { AjustesView() }
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
        .task {
            await auth.vigilarSesion()
        }
    }
}
