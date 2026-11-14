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
    private func pagadas(service: ObligacionesService) -> Int {
        service.obligaciones.filter { $0.activa && service.estaPagada(obligacionId: $0.id, mes: mesActual) }.count
    }
    private func totalActivas(service: ObligacionesService) -> Int {
        service.obligaciones.filter { $0.activa }.count
    }

    private func obligacionRow(_ o: Obligacion, service: ObligacionesService, ultima: Bool) -> some View {
        let pagada = service.estaPagada(obligacionId: o.id, mes: mesActual)
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    Task {
                        if pagada {
                            await service.desmarcar(obligacionId: o.id, mes: mesActual)
                        } else {
                            await service.marcarPagada(o, mes: mesActual)
                        }
                    }
                } label: {
                    Image(systemName: pagada ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(pagada ? Tema.verde : Tema.textoSecundario)
                }
                .buttonStyle(.plain)

                ZStack {
                    Circle()
                        .fill(IconoCategoria.color(o.categoria).opacity(0.22))
                        .frame(width: 38, height: 38)
                    Image(systemName: IconoCategoria.icono(o.categoria))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(IconoCategoria.color(o.categoria))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(o.nombre)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .strikethrough(pagada)
                        .opacity(pagada ? 0.55 : 1)
                        .lineLimit(1)
                    Text(o.categoria)
                        .font(.caption2)
                        .foregroundStyle(Tema.textoSuave)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                Text(service.montoFormateado(o, mes: mesActual))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .opacity(pagada ? 0.55 : 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Button {
                    obligacionEditar = o
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Tema.textoSecundario)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)

            if !ultima { Divisor() }
        }
    }

    private func grupoCard(titulo: String, icono: String, grupo: [Obligacion], service: ObligacionesService) -> some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SeccionTitulo(titulo: titulo, icono: icono)
                    Spacer()
                    Text(service.monedasService.formatearDesdeCOP(totalGrupo(grupo)))
                        .font(.caption.bold())
                        .foregroundStyle(Tema.textoSecundario)
                }

                if grupo.isEmpty {
                    Text("Sin obligaciones en este grupo")
                        .font(.subheadline)
                        .foregroundStyle(Tema.textoSuave)
                        .padding(.vertical, 6)
                } else {
                    ForEach(Array(grupo.enumerated()), id: \.element.id) { index, o in
                        obligacionRow(o, service: service, ultima: index == grupo.count - 1)
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    encabezado
                    navegadorMes

                    if let service {
                        if !service.error.isEmpty {
                            AvisoGlass(texto: service.error, icono: "exclamationmark.triangle.fill", color: Tema.rojo)
                        }

                        tarjetaProgreso(service)

                        grupoCard(
                            titulo: "Día 10",
                            icono: "calendar.badge.clock",
                            grupo: service.porGrupo.dia10,
                            service: service
                        )
                        grupoCard(
                            titulo: "Día 25",
                            icono: "calendar.badge.clock",
                            grupo: service.porGrupo.dia25,
                            service: service
                        )
                        grupoCard(
                            titulo: "Hormigas",
                            icono: "ant.fill",
                            grupo: service.porGrupo.hormigas,
                            service: service
                        )

                        if !inactivas.isEmpty {
                            Tarjeta {
                                VStack(alignment: .leading, spacing: 10) {
                                    SeccionTitulo(titulo: "Inactivas", icono: "pause.circle.fill")
                                    ForEach(Array(inactivas.enumerated()), id: \.element.id) { index, o in
                                        VStack(spacing: 0) {
                                            HStack(spacing: 12) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(o.nombre)
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundStyle(Tema.textoSecundario)
                                                        .lineLimit(1)
                                                    Text(o.categoria)
                                                        .font(.caption2)
                                                        .foregroundStyle(Tema.textoSuave)
                                                }
                                                Spacer()
                                                Button("Activar") {
                                                    Task {
                                                        await service.actualizar(
                                                            id: o.id,
                                                            nombre: o.nombre,
                                                            monto: o.monto,
                                                            diaPago: o.diaPago,
                                                            categoria: o.categoria,
                                                            activa: true
                                                        )
                                                    }
                                                }
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(Capsule().fill(Color.white.opacity(0.14)))
                                                .overlay(Capsule().stroke(Tema.borde, lineWidth: 1))
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.vertical, 6)
                                            if index < inactivas.count - 1 { Divisor() }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $mostrarFormulario, onDismiss: {
                Task { if let id = auth.usuario?.id, let s = service { await s.cargar(usuarioId: id) } }
            }) { NavigationStack { ObligacionFormView(mes: mesActual) } }
            .sheet(item: $obligacionEditar, onDismiss: {
                Task { if let id = auth.usuario?.id, let s = service { await s.cargar(usuarioId: id) } }
            }) { o in NavigationStack { ObligacionFormView(obligacion: o, mes: mesActual) } }
            .task {
                if let id = auth.usuario?.id {
                    let tasasService = TasasService()
                    let monedasService = MonedasService(tasasService: tasasService)
                    let s = ObligacionesService(gastosService: gastosService, tasasService: tasasService, monedasService: monedasService)
                    await s.cargar(usuarioId: id)
                    container.set(s)
                }
            }
        }
    }

    private var encabezado: some View {
        HStack {
            EncabezadoPantalla(
                titulo: "Obligaciones",
                subtitulo: "Tus pagos del mes",
                icono: "checklist"
            )
            BotonIcono(icono: "plus") { mostrarFormulario = true }
        }
    }

    private var navegadorMes: some View {
        Tarjeta {
            HStack {
                BotonIcono(icono: "chevron.left") { cambiarMes(-1) }
                Spacer()
                VStack(spacing: 2) {
                    Text(nombreMes(mesActual))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Mes de cobro")
                        .font(.caption2)
                        .foregroundStyle(Tema.textoSuave)
                }
                Spacer()
                BotonIcono(icono: "chevron.right") { cambiarMes(1) }
            }
        }
    }

    private func tarjetaProgreso(_ service: ObligacionesService) -> some View {
        let porcentaje = progreso(service: service)
        return Tarjeta {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SeccionTitulo(titulo: "Pagado este mes", icono: "checkmark.seal.fill")
                    Spacer()
                    Insignia(texto: "\(porcentaje)%", color: porcentaje >= 100 ? Tema.verde : Tema.azul)
                }

                Text("\(service.monedasService.formatear(service.totalPagadoMes(mesActual), codigo: service.monedasService.codigo)) / \(service.monedasService.formatear(service.totalEsperadoMes, codigo: service.monedasService.codigo))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                BarraProgreso(
                    valor: Double(porcentaje) / 100,
                    colores: [Tema.verde, Tema.azul],
                    altura: 10
                )

                Text("\(pagadas(service: service)) de \(totalActivas(service: service)) obligaciones pagadas")
                    .font(.caption)
                    .foregroundStyle(Tema.textoSuave)
            }
        }
    }
}
