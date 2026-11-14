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
    private func nombreMes(_ mes: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        guard let date = f.date(from: mes) else { return mes }
        let out = DateFormatter()
        out.dateFormat = "MMMM yyyy"
        out.locale = Locale(identifier: "es_ES")
        return out.string(from: date).capitalized
    }
    private var recientes: [Gasto] { gastosUsuario.sorted { $0.fecha > $1.fecha }.prefix(5).map { $0 } }
    private var saludo: String {
        let hora = Calendar.current.component(.hour, from: Date())
        if hora < 12 { return "Buenos días" }
        if hora < 19 { return "Buenas tardes" }
        return "Buenas noches"
    }
    private func fmt(_ v: Double) -> String {
        if let ms = monedasService { return ms.formatearDesdeCOP(v) }
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "es_CO")
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: v)) ?? String(format: "%.0f", v)
    }
    private func fechaCorta(_ s: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: s) else { return s }
        let out = DateFormatter()
        out.dateFormat = "d MMM"
        out.locale = Locale(identifier: "es_ES")
        return out.string(from: date)
    }

    var body: some View {
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    encabezado

                    BotonPrincipal(titulo: "Nuevo gasto", icono: "plus.circle.fill") {
                        selectedTab = 1
                        showNewGasto = true
                    }

                    if !gastosService.error.isEmpty {
                        AvisoGlass(texto: gastosService.error, icono: "exclamationmark.triangle.fill", color: Tema.rojo)
                    }

                    tarjetaTotal

                    HStack(spacing: 12) {
                        StatCard(titulo: "Nº de gastos", valor: "\(numeroTodo)", icono: "list.bullet.clipboard.fill", color: Tema.azul)
                        StatCard(titulo: "Promedio por gasto", valor: fmt(promedioTodo), icono: "chart.bar.fill", color: Tema.naranja)
                    }

                    tarjetaCategorias
                    tarjetaMeses
                    tarjetaRecientes
                    tarjetaPresupuesto
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
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
            }
            .overlay {
                if cargando {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.15)
                            .padding(26)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private var encabezado: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: 62, height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(saludo)
                    .font(.subheadline)
                    .foregroundStyle(Tema.textoSecundario)
                Text(auth.usuario?.nombre.isEmpty == false ? (auth.usuario?.nombre ?? "Usuario") : "Usuario")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Resumen de tus gastos")
                    .font(.caption)
                    .foregroundStyle(Tema.textoSuave)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tarjetaTotal: some View {
        Tarjeta(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        EtiquetaCampo(titulo: "Gasto total")
                        Text(fmt(totalTodo))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.16))
                            .frame(width: 54, height: 54)
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                HStack(spacing: 8) {
                    Insignia(texto: "\(numeroTodo) gastos", color: Tema.verde)
                    Insignia(texto: "\(totalesPorMes.count) meses", color: Tema.azul)
                }
            }
        }
    }

    private var tarjetaCategorias: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SeccionTitulo(titulo: "Gastos por categoría", icono: "chart.pie.fill")
                    Spacer()
                    Text(anioActual)
                        .font(.caption)
                        .foregroundStyle(Tema.textoSuave)
                }

                if categoriasAnio.isEmpty {
                    mensajeVacio(icono: "chart.pie", texto: "Aún no hay gastos este año")
                } else {
                    ForEach(categoriasAnio.prefix(6), id: \.0) { cat, val in
                        VStack(spacing: 7) {
                            HStack(spacing: 8) {
                                Image(systemName: IconoCategoria.icono(cat))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(IconoCategoria.color(cat))
                                Text(cat)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                Text(fmt(val))
                                    .font(.caption.bold())
                                    .foregroundStyle(Tema.textoSecundario)
                            }
                            BarraProgreso(
                                valor: maxCategoria > 0 ? val / maxCategoria : 0,
                                colores: [IconoCategoria.color(cat), Tema.morado],
                                altura: 7
                            )
                        }
                    }
                }
            }
        }
    }

    private var tarjetaMeses: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                SeccionTitulo(titulo: "Gastos por mes", icono: "chart.bar.fill")

                if totalesPorMes.isEmpty {
                    mensajeVacio(icono: "chart.bar", texto: "Registra un gasto para ver la evolución")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 16) {
                            ForEach(totalesPorMes, id: \.0) { mes, val in
                                let ratio = maxMes > 0 ? val / maxMes : 0
                                VStack(spacing: 6) {
                                    Text("\(Int(ratio * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(Tema.textoSecundario)
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Tema.gradienteAcento)
                                        .frame(width: 36, height: max(8, ratio * 96))
                                    Text(abrevMes(mes))
                                        .font(.caption2)
                                        .foregroundStyle(Tema.textoSecundario)
                                }
                                .frame(width: 44, alignment: .bottom)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var tarjetaRecientes: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SeccionTitulo(titulo: "Gastos recientes", icono: "clock.fill")
                    Spacer()
                    Button {
                        selectedTab = 1
                    } label: {
                        HStack(spacing: 2) {
                            Text("Ver todos")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }

                if recientes.isEmpty {
                    mensajeVacio(icono: "tray", texto: "Todavía no tienes gastos")
                } else {
                    ForEach(Array(recientes.enumerated()), id: \.element.id) { index, gasto in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(IconoCategoria.color(gasto.categoria).opacity(0.22))
                                    .frame(width: 40, height: 40)
                                Image(systemName: IconoCategoria.icono(gasto.categoria))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(IconoCategoria.color(gasto.categoria))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(gasto.descripcion.isEmpty ? gasto.categoria : gasto.descripcion)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("\(gasto.categoria) · \(fechaCorta(gasto.fecha))")
                                    .font(.caption2)
                                    .foregroundStyle(Tema.textoSuave)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)

                            Text(fmt(gasto.monto))
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.vertical, 4)

                        if index < recientes.count - 1 { Divisor() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tarjetaPresupuesto: some View {
        if let ps = presupuestoService, let ms = monedasService {
            let color = EstadoPresupuesto.color(ps.estado)
            Tarjeta {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SeccionTitulo(titulo: "Presupuesto del mes", icono: "target")
                        Spacer()
                        Insignia(texto: EstadoPresupuesto.texto(ps.estado), color: color)
                    }

                    Text(nombreMes(mesActual))
                        .font(.caption)
                        .foregroundStyle(Tema.textoSuave)

                    HStack {
                        EtiquetaCampo(titulo: "Presupuesto")
                        Spacer()
                        Text(ms.formatearDesdeCOP(ps.presupuesto))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }

                    HStack {
                        EtiquetaCampo(titulo: "Gastado")
                        Spacer()
                        Text(ms.formatearDesdeCOP(ps.gastoDelMes))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }

                    BarraProgreso(
                        valor: min(Double(ps.porcentaje) / 100, 1),
                        colores: [color, color.opacity(0.6)],
                        altura: 10
                    )

                    HStack {
                        Text("\(ps.porcentaje)% usado")
                            .font(.caption)
                            .foregroundStyle(Tema.textoSecundario)
                        Spacer()
                        Text("Disponible \(ms.formatearDesdeCOP(ps.restante))")
                            .font(.caption)
                            .foregroundStyle(Tema.textoSecundario)
                    }
                }
            }
        }
    }

    private func mensajeVacio(icono: String, texto: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 16, weight: .semibold))
            Text(texto)
                .font(.subheadline)
        }
        .foregroundStyle(Tema.textoSuave)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}
