import SwiftUI

struct AjustesView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var tasasService: TasasService
    @StateObject private var monedasService: MonedasService

    init() {
        let ts = TasasService()
        _tasasService = StateObject(wrappedValue: ts)
        _monedasService = StateObject(wrappedValue: MonedasService(tasasService: ts))
    }

    private var inicial: String {
        let nombre = auth.usuario?.nombre ?? ""
        return String(nombre.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    EncabezadoPantalla(
                        titulo: "Ajustes",
                        subtitulo: "Personaliza tu experiencia",
                        icono: "gearshape.fill"
                    )

                    tarjetaPerfil
                    tarjetaPreferencias
                    tarjetaTasas
                    botonCerrarSesion
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if tasasService.ultimaActualizacion == nil {
                    await tasasService.actualizar()
                }
            }
        }
    }

    private var tarjetaPerfil: some View {
        Tarjeta {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Tema.gradienteAcento)
                        .frame(width: 58, height: 58)
                    Text(inicial.isEmpty ? "U" : inicial)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(auth.usuario?.nombre ?? "Usuario")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(auth.usuario?.email ?? "")
                        .font(.caption)
                        .foregroundStyle(Tema.textoSecundario)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Insignia(texto: "Activo", color: Tema.verde)
            }
        }
    }

    private var tarjetaPreferencias: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                SeccionTitulo(titulo: "Preferencias", icono: "slider.horizontal.3")

                NavigationLink {
                    PresupuestoConfigView()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Tema.naranja.opacity(0.20))
                                .frame(width: 38, height: 38)
                            Image(systemName: "target")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Tema.naranja)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Presupuesto")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Configura el límite mensual")
                                .font(.caption2)
                                .foregroundStyle(Tema.textoSuave)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Tema.textoSuave)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divisor()

                VStack(alignment: .leading, spacing: 8) {
                    EtiquetaCampo(titulo: "Moneda activa")
                    CampoSeleccion(
                        titulo: "Selecciona una moneda",
                        icono: "dollarsign.circle.fill",
                        seleccion: Binding(
                            get: { monedasService.codigo },
                            set: { monedasService.setMoneda($0) }
                        ),
                        opciones: monedasService.disponibles.map {
                            OpcionSeleccion(valor: $0.codigo, titulo: "\($0.codigo) - \($0.nombre)")
                        }
                    )
                }
            }
        }
    }

    private var tarjetaTasas: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                SeccionTitulo(titulo: "Tasas de cambio", icono: "arrow.triangle.2.circlepath")

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tasasService.origen)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        if let fecha = tasasService.ultimaActualizacion {
                            Text("Actualizado: \(fecha.formatted())")
                                .font(.caption2)
                                .foregroundStyle(Tema.textoSuave)
                        }
                    }
                    Spacer()
                    Insignia(
                        texto: tasasService.sonReales ? "En línea" : "Referencia",
                        color: tasasService.sonReales ? Tema.verde : Tema.naranja
                    )
                }

                if !tasasService.error.isEmpty {
                    AvisoGlass(texto: tasasService.error, icono: "wifi.exclamationmark", color: Tema.naranja)
                }

                BotonGlass(titulo: tasasService.cargando ? "Actualizando..." : "Actualizar tasas", icono: "arrow.clockwise") {
                    Task { await tasasService.actualizar() }
                }
            }
        }
    }

    private var botonCerrarSesion: some View {
        Button(role: .destructive) {
            Task { await auth.logout() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Cerrar sesión")
            }
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(Tema.rojo)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Tema.rojo.opacity(0.16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Tema.rojo.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
