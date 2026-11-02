import SwiftUI
struct GastosListView: View {
    @EnvironmentObject var auth: AuthService
    @Binding var showNewGasto: Bool
    @StateObject private var service = GastosService()
    @State private var monedasService = MonedasService(tasasService: TasasService())
    @State private var cargando = false
    @State private var mesSeleccionado = GastosListView.mesActual()
    private var usuarioId: String { auth.usuario?.id ?? "" }
    private static func mesActual() -> String {
        let now = Date()
        let y = Calendar.current.component(.year, from: now)
        let m = Calendar.current.component(.month, from: now)
        return String(format: "%04d-%02d", y, m)
    }
    private var mesesDisponibles: [String] {
        let meses = Set(service.gastosPorUsuario(usuarioId).map { String($0.fecha.prefix(7)) })
        var lista = Array(meses)
        if !lista.contains(mesSeleccionado) && mesSeleccionado != "Todos" { lista.append(mesSeleccionado) }
        return lista.sorted(by: >)
    }
    private var gastosFiltrados: [Gasto] {
        let base = service.gastosPorUsuario(usuarioId)
        if mesSeleccionado == "Todos" { return base }
        return base.filter { $0.fecha.prefix(7) == mesSeleccionado }
    }
    private var totalFiltrado: Double { gastosFiltrados.reduce(0) { $0 + $1.monto } }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Mes", selection: $mesSeleccionado) {
                        Text("Todos los meses").tag("Todos")
                        ForEach(mesesDisponibles, id: \.self) { mes in Text(mes).tag(mes) }
                    }
                }
                Section { Text("Total: \(monedasService.formatearDesdeCOP(totalFiltrado))") }
                ForEach(gastosFiltrados) { gasto in
                    NavigationLink { GastoFormView(gasto: gasto) } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(gasto.descripcion.isEmpty ? gasto.categoria : gasto.descripcion).font(.headline)
                                Text("\(gasto.categoria) · \(gasto.metodoPago)").font(.subheadline).foregroundStyle(.secondary)
                                Text(gasto.fecha).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(monedasService.formatearDesdeCOP(gasto.monto))
                                .font(.subheadline.bold())
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { Task { try? await service.eliminar(id: gasto.id) } } label: { Label("Eliminar", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle("Gastos")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink("Nuevo") { GastoFormView() } } }
            .task {
                guard let id = auth.usuario?.id else { return }
                cargando = true
                await service.cargar(usuarioId: id)
                let ts = TasasService()
                await ts.actualizar()
                monedasService = MonedasService(tasasService: ts)
                cargando = false
            }
            .refreshable {
                guard let id = auth.usuario?.id else { return }
                await service.cargar(usuarioId: id)
            }
            .overlay { if cargando { ProgressView() } }
            .sheet(isPresented: $showNewGasto) {
                NavigationStack { GastoFormView() }
            }
        }
    }
}