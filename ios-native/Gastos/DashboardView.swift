import SwiftUI
struct DashboardView: View {
    @EnvironmentObject var auth: AuthService
    @Binding var selectedTab: Int
    @Binding var showNewGasto: Bool
    @StateObject private var gastosService = GastosService()
    @State private var presupuestoService: PresupuestoService?
    @State private var monedasService: MonedasService?
    @State private var cargando = false
    private var usuarioId: String { auth.usuario?.id ?? "" }
    private var mesActual: String {
        let now = Date(); let y = Calendar.current.component(.year, from: now); let m = Calendar.current.component(.month, from: now)
        return String(format: "%04d-%02d", y, m)
    }
    private var gastosUsuario: [Gasto] { gastosService.gastosPorUsuario(usuarioId) }
    private var totalTodo: Double { gastosUsuario.reduce(0) { $0 + $1.monto } }
    private var numeroTodo: Int { gastosUsuario.count }
    private var promedioTodo: Double { numeroTodo > 0 ? totalTodo / Double(numeroTodo) : 0 }
    private var anioActual: String { String(Calendar.current.component(.year, from: Date())) }
    private var gastosAnio: [Gasto] { gastosUsuario.filter { $0.fecha.prefix(4) == anioActual } }
    private var categoriasAnio: [(String, Double)] {
        var mapa: [String: Double] = [:]
        for g in gastosAnio { mapa[g.categoria, default: 0] += g.monto }
        return mapa.sorted { $0.value > $1.value }
    }
    private var maxCategoria: Double { categoriasAnio.map { $0.1 }.max() ?? 1 }
    private var totalesPorMes: [(String, Double)] {
        var mapa: [String: Double] = [:]
        for g in gastosUsuario { mapa[String(g.fecha.prefix(7)), default: 0] += g.monto }
        return mapa.sorted { $0.key < $1.key }
    }
    private var maxMes: Double { totalesPorMes.map { $0.1 }.max() ?? 1 }
    private func abrevMes(_ mes: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        guard let date = f.date(from: mes) else { return mes }
        let out = DateFormatter()
        out.dateFormat = "MMM"
        out.locale = Locale(identifier: "es_ES")
        return out.string(from: date).lowercased()
    }
    private var recientes: [Gasto] { gastosUsuario.sorted { $0.fecha > $1.fecha }.prefix(5).map { $0 } }
    private func fmt(_ v: Double) -> String {
        if let ms = monedasService { return ms.formatearDesdeCOP(v) }
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "es_CO")
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: v)) ?? String(format: "%.0f", v)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Hola, \(auth.usuario?.nombre ?? "Usuario") 👋")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Resumen de tus gastos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button { selectedTab = 1; showNewGasto = true } label: { Label("Nuevo gasto", systemImage: "plus.circle.fill").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent)
                    if !gastosService.error.isEmpty {
                        Text(gastosService.error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                    HStack(spacing: 12) {
                        StatCard(titulo: "Gasto total", valor: fmt(totalTodo))
                        StatCard(titulo: "Nº de Gastos", valor: "\(numeroTodo)")
                        StatCard(titulo: "Promedio", valor: fmt(promedioTodo))
                    }
                    Text("Gastos cargados: \(gastosUsuario.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gastos por categoría (año \(anioActual))").font(.headline)
                        ForEach(categoriasAnio, id: \.0) { cat, val in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(cat); Spacer(); Text(fmt(val)) }
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 4).fill(Color.accentColor).frame(width: geo.size.width * CGFloat(val / maxCategoria), height: 8)
                                }.frame(height: 8)
                            }
                        }
                    }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gastos por mes").font(.headline)
                        ScrollView(.horizontal, showsIndicators: true) {
                            let totalMesVal = totalesPorMes.reduce(0, { $0 + $1.1 })
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(totalesPorMes, id: \.0) { mes, val in
                                    let pct = maxMes > 0 ? Int(val / maxMes * 100) : 0
                                    VStack {
                                        Text("\(pct)%").font(.caption2)
                                        Rectangle().fill(Color.accentColor).frame(width: 40, height: CGFloat(val / maxMes) * 120)
                                        Text(abrevMes(mes)).font(.caption2)
                                    }
                                }
                            }
                        }
                    }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Gastos recientes").font(.headline)
                            Spacer()
                            Button("Ver gastos") { selectedTab = 1 }
                        }
                        ForEach(recientes) { g in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(g.descripcion.isEmpty ? g.categoria : g.descripcion)
                                    Text(g.fecha).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(fmt(g.monto))
                            }
                        }
                    }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    if let ps = presupuestoService, let ms = monedasService {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Presupuesto del mes (\(mesActual))").font(.headline)
                            HStack {
                                Text("Presupuesto:")
                                Spacer()
                                Text("\(ms.formatearDesdeCOP(ps.presupuesto))")
                            }
                            HStack {
                                Text("Gasto del mes:")
                                Spacer()
                                Text("\(ms.formatearDesdeCOP(ps.gastoDelMes))")
                            }
                            Text("Porcentaje: \(ps.porcentaje)%")
                            Text("Estado: \(ps.estado)")
                            ProgressView(value: min(Double(ps.porcentaje), 100), total: 100)
                        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    }
                }.padding()
            }.navigationTitle("")
            .task {
                guard let id = auth.usuario?.id else { return }
                cargando = true
                await gastosService.cargar(usuarioId: id)
                let ts = TasasService()
                await ts.actualizar()
                monedasService = MonedasService(tasasService: ts)
                let ps = PresupuestoService(auth: auth, gastosService: gastosService)
                await ps.cargar()
                presupuestoService = ps
                cargando = false
            }.overlay { if cargando { ProgressView() } }
        }
    }
}
