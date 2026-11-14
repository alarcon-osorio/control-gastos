import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var model = WatchModel()
    @State private var confirmarSalida = false

    private var mes: String { WatchFecha.mesActual() }

    var body: some View {
        NavigationStack {
            ZStack {
                WatchFondo()

                ScrollView {
                    VStack(spacing: 10) {
                        encabezado

                        if model.cargando && model.obligacionesService.obligaciones.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 24)
                        } else {
                            resumen
                            acciones
                        }

                        if !model.error.isEmpty {
                            Text(model.error)
                                .font(.caption2)
                                .foregroundStyle(WatchTema.rojo)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button("Cerrar sesión") {
                            confirmarSalida = true
                        }
                        .font(.caption2)
                        .foregroundStyle(WatchTema.textoSecundario)
                        .padding(.top, 4)
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
            .navigationTitle("Gastos")
            .task(id: auth.usuario?.id) {
                if let id = auth.usuario?.id {
                    await model.cargar(usuarioId: id)
                }
            }
            .task {
                await auth.vigilarSesion()
            }
            .alert("¿Cerrar sesión?", isPresented: $confirmarSalida) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) {
                    Task { await auth.logout() }
                }
            }
        }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(saludo)
                .font(.caption)
                .foregroundStyle(WatchTema.textoSecundario)
            Text(WatchFecha.nombreMes(mes))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    private var saludo: String {
        if let nombre = auth.usuario?.nombre, !nombre.isEmpty {
            return "Hola, \(nombre)"
        }
        return "Hola"
    }

    private var resumen: some View {
        let service = model.obligacionesService
        let esperado = service.totalEsperadoMes
        let pagado = service.totalPagadoMes(mes)
        let porcentaje = esperado > 0 ? min(100, Int((pagado / esperado * 100).rounded())) : 0
        let activas = service.obligaciones.filter { $0.activa }
        let pagadas = activas.filter { service.estaPagada(obligacionId: $0.id, mes: mes) }.count

        return WatchTarjeta {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pagado este mes")
                        .font(.caption2)
                        .foregroundStyle(WatchTema.textoSecundario)
                    Spacer()
                    Text("\(porcentaje)%")
                        .font(.caption2.bold())
                        .foregroundStyle(porcentaje >= 100 ? WatchTema.verde : WatchTema.azul)
                }

                Text(model.monedasService.formatearDesdeCOP(pagado))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("de \(model.monedasService.formatearDesdeCOP(esperado))")
                    .font(.caption2)
                    .foregroundStyle(WatchTema.textoSuave)

                WatchBarraProgreso(valor: Double(porcentaje) / 100)

                Text("\(pagadas) de \(activas.count) obligaciones pagadas")
                    .font(.caption2)
                    .foregroundStyle(WatchTema.textoSuave)
            }
        }
    }

    private var acciones: some View {
        VStack(spacing: 8) {
            NavigationLink {
                WatchObligacionesView(model: model)
            } label: {
                WatchAccionFila(
                    titulo: "Obligaciones",
                    subtitulo: "Marca tus pagos del mes",
                    icono: "checklist",
                    color: WatchTema.verde
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                WatchGastoFormView(model: model)
            } label: {
                WatchAccionFila(
                    titulo: "Agregar gasto",
                    subtitulo: "Registro rápido",
                    icono: "plus.circle.fill",
                    color: WatchTema.naranja
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct WatchAccionFila: View {
    var titulo: String
    var subtitulo: String
    var icono: String
    var color: Color

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.22))
                    .frame(width: 30, height: 30)
                Image(systemName: icono)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(titulo)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitulo)
                    .font(.caption2)
                    .foregroundStyle(WatchTema.textoSuave)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WatchTema.textoSuave)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.12))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(WatchTema.borde, lineWidth: 1)
        )
    }
}
