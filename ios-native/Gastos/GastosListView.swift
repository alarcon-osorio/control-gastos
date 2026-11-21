import SwiftUI

struct GastosListView: View {
    @EnvironmentObject var auth: AuthService
    @Binding var showNewGasto: Bool
    @StateObject private var service = GastosService()
    @State private var monedasService = MonedasService(tasasService: TasasService())
    @State private var cargando = false
    @State private var mesSeleccionado = GastosListView.mesActual()
    @State private var categoriaSeleccionada = "Todas"
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
    private var gastosDelMes: [Gasto] {
        let base = service.gastosPorUsuario(usuarioId)
        if mesSeleccionado == "Todos" { return base }
        return base.filter { $0.fecha.prefix(7) == mesSeleccionado }
    }
    private var categoriasDisponibles: [String] {
        Array(Set(gastosDelMes.map { $0.categoria }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    private var gastosFiltrados: [Gasto] {
        if categoriaSeleccionada == "Todas" { return gastosDelMes }
        return gastosDelMes.filter { $0.categoria == categoriaSeleccionada }
    }
    private var totalFiltrado: Double { gastosFiltrados.reduce(0) { $0 + $1.monto } }
    private var tituloTotal: String {
        if categoriaSeleccionada != "Todas" { return "Total \(categoriaSeleccionada)" }
        return mesSeleccionado == "Todos" ? "Total histórico" : "Total del mes"
    }
    private var mensajeVacio: String {
        if categoriaSeleccionada != "Todas" { return "No hay gastos de \(categoriaSeleccionada) en este período" }
        return "No hay gastos en este período"
    }

    private func nombreMesCorto(_ mes: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        guard let date = f.date(from: mes) else { return mes }
        let out = DateFormatter()
        out.dateFormat = "MMM yyyy"
        out.locale = Locale(identifier: "es_ES")
        return out.string(from: date).capitalized
    }

    private func fechaCorta(_ s: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: s) else { return s }
        let out = DateFormatter()
        out.dateFormat = "d MMM yyyy"
        out.locale = Locale(identifier: "es_ES")
        return out.string(from: date)
    }

    var body: some View {
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    encabezado
                    resumen
                    filtros
                    movimientos
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
            .onChange(of: mesSeleccionado) { _ in
                categoriaSeleccionada = "Todas"
            }
            .onChange(of: categoriasDisponibles) { _ in
                guard categoriaSeleccionada != "Todas" else { return }
                if !categoriasDisponibles.contains(categoriaSeleccionada) {
                    categoriaSeleccionada = "Todas"
                }
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
            .sheet(isPresented: $showNewGasto, onDismiss: {
                Task {
                    if let id = auth.usuario?.id { await service.cargar(usuarioId: id) }
                }
            }) {
                NavigationStack { GastoFormView() }
            }
        }
    }

    private var encabezado: some View {
        HStack(alignment: .center, spacing: 14) {
            EncabezadoPantalla(
                titulo: "Gastos",
                subtitulo: "Todos tus movimientos",
                icono: "list.bullet.rectangle.fill"
            )

            NavigationLink {
                GastoFormView()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.16))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var resumen: some View {
        Tarjeta {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    EtiquetaCampo(titulo: tituloTotal)
                    Text(monedasService.formatearDesdeCOP(totalFiltrado))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("\(gastosFiltrados.count) movimiento\(gastosFiltrados.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Tema.textoSuave)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 52, height: 52)
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var filtros: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("Todos", activo: mesSeleccionado == "Todos") {
                        mesSeleccionado = "Todos"
                    }
                    ForEach(mesesDisponibles, id: \.self) { mes in
                        chip(nombreMesCorto(mes), activo: mesSeleccionado == mes) {
                            mesSeleccionado = mes
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            if !categoriasDisponibles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("Todas", activo: categoriaSeleccionada == "Todas", icono: "square.grid.2x2") {
                            categoriaSeleccionada = "Todas"
                        }
                        ForEach(categoriasDisponibles, id: \.self) { categoria in
                            chip(categoria, activo: categoriaSeleccionada == categoria, icono: IconoCategoria.icono(categoria)) {
                                categoriaSeleccionada = categoria
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func chip(_ titulo: String, activo: Bool, icono: String? = nil, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            HStack(spacing: 6) {
                if let icono = icono {
                    Image(systemName: icono)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(titulo)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(activo ? .white : Tema.textoSecundario)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(Color.white.opacity(activo ? 0.24 : 0.10))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(activo ? 0.45 : 0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var movimientos: some View {
        Tarjeta {
            VStack(spacing: 4) {
                HStack {
                    SeccionTitulo(titulo: "Movimientos", icono: "clock.arrow.circlepath")
                    Spacer()
                    Text("\(gastosFiltrados.count)")
                        .font(.caption.bold())
                        .foregroundStyle(Tema.textoSecundario)
                }
                .padding(.bottom, 4)

                if gastosFiltrados.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Tema.textoSuave)
                        Text(mensajeVacio)
                            .font(.subheadline)
                            .foregroundStyle(Tema.textoSuave)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                } else {
                    ForEach(Array(gastosFiltrados.enumerated()), id: \.element.id) { index, gasto in
                        fila(gasto)
                        if index < gastosFiltrados.count - 1 { Divisor() }
                    }
                }
            }
        }
    }

    private func fila(_ gasto: Gasto) -> some View {
        NavigationLink {
            GastoFormView(gasto: gasto)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(IconoCategoria.color(gasto.categoria).opacity(0.22))
                        .frame(width: 42, height: 42)
                    Image(systemName: IconoCategoria.icono(gasto.categoria))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(IconoCategoria.color(gasto.categoria))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(gasto.descripcion.isEmpty ? gasto.categoria : gasto.descripcion)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(gasto.categoria) · \(gasto.metodoPago)")
                        .font(.caption2)
                        .foregroundStyle(Tema.textoSuave)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(monedasService.formatearDesdeCOP(gasto.monto))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(fechaCorta(gasto.fecha))
                        .font(.caption2)
                        .foregroundStyle(Tema.textoSuave)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Tema.textoSuave)
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task { try? await service.eliminar(id: gasto.id) }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}
