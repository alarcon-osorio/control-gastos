import SwiftUI

struct WatchObligacionesView: View {
    @EnvironmentObject var auth: AuthService
    @ObservedObject var model: WatchModel
    @State private var mes = WatchFecha.mesActual()
    @State private var actualizandoId: Int?

    private var service: ObligacionesService { model.obligacionesService }

    var body: some View {
        ZStack {
            WatchFondo()

            ScrollView {
                VStack(spacing: 10) {
                    navegadorMes
                    tarjetaProgreso

                    grupoCard(
                        titulo: "Día 10",
                        icono: "calendar.badge.clock",
                        grupo: service.porGrupo.dia10
                    )
                    grupoCard(
                        titulo: "Día 25",
                        icono: "calendar.badge.clock",
                        grupo: service.porGrupo.dia25
                    )
                    grupoCard(
                        titulo: "Hormigas",
                        icono: "ant.fill",
                        grupo: service.porGrupo.hormigas
                    )

                    if !service.error.isEmpty {
                        Text(service.error)
                            .font(.caption2)
                            .foregroundStyle(WatchTema.rojo)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if service.obligaciones.filter({ $0.activa }).isEmpty && !model.cargando {
                        Text("No hay obligaciones activas")
                            .font(.caption2)
                            .foregroundStyle(WatchTema.textoSuave)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 10)
            }
            .refreshable {
                if let id = auth.usuario?.id {
                    await model.cargar(usuarioId: id)
                }
            }
        }
        .navigationTitle("Obligaciones")
        .task {
            if let id = auth.usuario?.id, service.obligaciones.isEmpty {
                await model.cargar(usuarioId: id)
            }
        }
    }

    private var navegadorMes: some View {
        WatchTarjeta {
            HStack(spacing: 8) {
                WatchBotonIcono(icono: "chevron.left") {
                    mes = WatchFecha.cambiarMes(mes, delta: -1)
                }

                Spacer()

                VStack(spacing: 1) {
                    Text(WatchFecha.nombreMes(mes))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Mes de cobro")
                        .font(.system(size: 9))
                        .foregroundStyle(WatchTema.textoSuave)
                }

                Spacer()

                WatchBotonIcono(icono: "chevron.right") {
                    mes = WatchFecha.cambiarMes(mes, delta: 1)
                }
            }
        }
    }

    private var tarjetaProgreso: some View {
        let esperado = service.totalEsperadoMes
        let pagado = service.totalPagadoMes(mes)
        let porcentaje = esperado > 0 ? min(100, Int((pagado / esperado * 100).rounded())) : 0
        let activas = service.obligaciones.filter { $0.activa }
        let pagadas = activas.filter { service.estaPagada(obligacionId: $0.id, mes: mes) }.count

        return WatchTarjeta {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Pagado")
                        .font(.caption2)
                        .foregroundStyle(WatchTema.textoSecundario)
                    Spacer()
                    Text("\(porcentaje)%")
                        .font(.caption2.bold())
                        .foregroundStyle(porcentaje >= 100 ? WatchTema.verde : WatchTema.azul)
                }

                Text(model.monedasService.formatearDesdeCOP(pagado))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("de \(model.monedasService.formatearDesdeCOP(esperado))")
                    .font(.system(size: 10))
                    .foregroundStyle(WatchTema.textoSuave)

                WatchBarraProgreso(valor: Double(porcentaje) / 100)

                Text("\(pagadas) de \(activas.count) pagadas")
                    .font(.system(size: 9))
                    .foregroundStyle(WatchTema.textoSuave)
            }
        }
    }

    @ViewBuilder
    private func grupoCard(titulo: String, icono: String, grupo: [Obligacion]) -> some View {
        if !grupo.isEmpty {
            let total = grupo.reduce(0) { $0 + service.montoPara($1, mes: mes) }
            WatchTarjeta {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Image(systemName: icono)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(WatchTema.textoSecundario)
                        Text(titulo)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(model.monedasService.formatearDesdeCOP(total))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(WatchTema.textoSecundario)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    ForEach(grupo) { obligacion in
                        fila(obligacion)
                    }
                }
            }
        }
    }

    private func fila(_ obligacion: Obligacion) -> some View {
        let pagada = service.estaPagada(obligacionId: obligacion.id, mes: mes)
        let actualizando = actualizandoId == obligacion.id

        return Button {
            guard actualizandoId == nil else { return }
            Task {
                service.error = ""
                actualizandoId = obligacion.id
                if pagada {
                    await service.desmarcar(obligacionId: obligacion.id, mes: mes)
                } else {
                    await service.marcarPagada(obligacion, mes: mes)
                }
                actualizandoId = nil
            }
        } label: {
            HStack(spacing: 7) {
                if actualizando {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.7)
                        .frame(width: 17, height: 17)
                } else {
                    Image(systemName: pagada ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(pagada ? WatchTema.verde : WatchTema.textoSecundario)
                        .frame(width: 17, height: 17)
                }

                Image(systemName: WatchIconoCategoria.icono(obligacion.categoria))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WatchIconoCategoria.color(obligacion.categoria))
                    .frame(width: 12)

                Text(obligacion.nombre)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .strikethrough(pagada)
                    .opacity(pagada ? 0.55 : 1)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Text(service.montoFormateado(obligacion, mes: mes))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(pagada ? 0.55 : 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(actualizandoId != nil)
    }
}
