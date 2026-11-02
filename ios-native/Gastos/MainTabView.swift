import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthService
    @State private var selectedTab = 0
    @State private var showNewGasto = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { DashboardView(selectedTab: $selectedTab, showNewGasto: $showNewGasto) }
                .tabItem { Label("Dashboard", systemImage: "chart.pie") }
                .tag(0)

            NavigationStack { GastosListView(showNewGasto: $showNewGasto) }
                .tabItem { Label("Gastos", systemImage: "list.bullet") }
                .tag(1)

            NavigationStack { ObligacionesView() }
                .tabItem { Label("Obligaciones", systemImage: "checklist") }
                .tag(2)

            NavigationStack { ParametrosView() }
                .tabItem { Label("Parámetros", systemImage: "gearshape") }
                .tag(3)

            NavigationStack { AjustesView() }
                .tabItem { Label("Ajustes", systemImage: "gear") }
                .tag(5)
        }
    }
}
