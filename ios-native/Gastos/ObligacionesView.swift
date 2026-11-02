import SwiftUI
import Combine
final class ObligacionesContainer: ObservableObject {
    @Published var service: ObligacionesService?
    private var cancellable: AnyCancellable?
    func set(_ s: ObligacionesService) {
        service = s
        cancellable = s.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }
}
struct ObligacionesView: View {
    @EnvironmentObject var auth: AuthService
    @State private var gastosService = GastosService()
    @StateObject private var container = ObligacionesContainer()
    @State private var mesActual = ObligacionesView.mesActual()
    @State private var mostrarFormulario = false
    @State private var obligacionEditar: Obligacion?
    private var service: ObligacionesService? { container.service }
    private static func mesActual() -> String {
        let now = Date(); let y = Calendar.current.component(.year, from: now); let m = Calendar.current.component(.month, from: now)
        return String(format: "%04d-%02d", y, m)
    }
    private func nombreMes(_ mes: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        guard let date = f.date(from: mes) else { return mes }
        let out = DateFormatter(); out.dateFormat = "MMMM yyyy"; out.locale = Locale(identifier: "es_ES")
        return out.string(from: date).capitalized
    }
    private func cambiarMes(_ delta: Int) {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        guard let date = f.date(from: mesActual), let nueva = Calendar.current.date(byAdding: .month, value: delta, to: date) else { return }
        mesActual = String(format: "%04d-%02d", Calendar.current.component(.year, from: nueva), Calendar.current.component(.month, from: nueva))
    }
    private var inactivas: [Obligacion] {
        service?.obligaciones.filter { !$0.activa } ?? []
    }
    private func progreso(service: ObligacionesService) -> Int {
        let esperado = service.totalEsperadoMes
        let pagado = service.totalPagadoMes(mesActual)
        return esperado > 0 ? min(100, Int((pagado / esperado * 100).rounded())) : 0
    }
    private func totalGrupo(_ grupo: [Obligacion]) -> Double {
        guard let s = service else { return 0 }
        return grupo.reduce(0) { $0 + s.montoPara($1, mes: mesActual) }
    }
    @ViewBuilder
    private func obligacionRow(_ o: Obligacion, service: ObligacionesService) -> some View {
        HStack {
            Button {
                Task {
                    if service.estaPagada(obligacionId: o.id, mes: mesActual) {
                        await service.desmarcar(obligacionId: o.id, mes: mesActual)
                    } else {
                        await service.marcarPagada(o, mes: mesActual)
                    }
                }
            } label: {
                Image(systemName: service.estaPagada(obligacionId: o.id, mes: mesActual) ? "checkmark.circle.fill" : "circle")
            }.buttonStyle(.plain)
            Text(o.nombre)
                .strikethrough(service.estaPagada(obligacionId: o.id, mes: mesActual))
                .foregroundStyle(service.estaPagada(obligacionId: o.id, mes: mesActual) ? .secondary : .primary)
            Spacer()
            Text(service.montoFormateado(o, mes: mesActual))
            Button { obligacionEditar = o } label: { Image(systemName: "pencil") }.buttonStyle(.plain)
        }
    }


    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: { cambiarMes(-1) }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    Spacer()
                    Text(nombreMes(mesActual))
                        .font(.title2.bold())
                    Spacer()
                    Button(action: { cambiarMes(1) }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                if let service {
                    if !service.error.isEmpty { Text(service.error).foregroundStyle(.red).font(.footnote).padding() }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Pagado este mes").font(.subheadline)
                            Spacer()
                            Text("\(service.monedasService.formatear(service.totalPagadoMes(mesActual), codigo: service.monedasService.codigo)) / \(service.monedasService.formatear(service.totalEsperadoMes, codigo: service.monedasService.codigo))")
                                .font(.caption)
                        }
                        ProgressView(value: Double(progreso(service: service)), total: 100)
                        Text("\(progreso(service: service))%").font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    .padding(.horizontal, 20)
                    List {
                        Section {
                            ForEach(service.porGrupo.dia10) { o in obligacionRow(o, service: service) }
                        } header: { HStack { Text("Día 10") } }
                        Section {
                            ForEach(service.porGrupo.dia25) { o in obligacionRow(o, service: service) }
                        } header: { HStack { Text("Día 25") } }
                        Section {
                            ForEach(service.porGrupo.hormigas) { o in obligacionRow(o, service: service) }
                        } header: { HStack { Text("Hormigas") } }
                        if !inactivas.isEmpty {
                            Section("Inactivas") {
                                ForEach(inactivas) { o in
                                    HStack {
                                        Text(o.nombre).foregroundStyle(.secondary)
                                        Spacer()
                                        Text(service.montoFormateado(o, mes: mesActual))
                                        Button("Activar") {
                                            Task {
                                                await service.actualizar(id: o.id, nombre: o.nombre, monto: o.monto, diaPago: o.diaPago, categoria: o.categoria, activa: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else { ProgressView() }
            }
            .navigationTitle("Obligaciones")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Nueva") { mostrarFormulario = true } } }
            .sheet(isPresented: $mostrarFormulario, onDismiss: {
                Task { if let id = auth.usuario?.id, let s = service { await s.cargar(usuarioId: id) } }
            }) { NavigationStack { ObligacionFormView(mes: mesActual) } }
            .task {
                if let id = auth.usuario?.id {
                    let tasasService = TasasService()
                    let monedasService = MonedasService(tasasService: tasasService)
                    let s = ObligacionesService(gastosService: gastosService, tasasService: tasasService, monedasService: monedasService)
                    await s.cargar(usuarioId: id)
                    container.set(s)
                }
            }
            .sheet(item: $obligacionEditar, onDismiss: {
                Task { if let id = auth.usuario?.id, let s = service { await s.cargar(usuarioId: id) } }
            }) { o in NavigationStack { ObligacionFormView(obligacion: o, mes: mesActual) } }
        }
    }
}
