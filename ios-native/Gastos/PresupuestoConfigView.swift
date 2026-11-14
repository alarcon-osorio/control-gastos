import SwiftUI

struct PresupuestoConfigView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var gastosService = GastosService()

    @State private var tasasService = TasasService()
    @State private var monedasService: MonedasService?
    @State private var presupuestoService: PresupuestoService?

    @State private var mes: String = {
        let now = Date()
        let y = Calendar.current.component(.year, from: now)
        let m = Calendar.current.component(.month, from: now)
        return String(format: "%04d-%02d", y, m)
    }()

    @State private var montoTexto = ""
    @State private var monedaCodigo = "COP"
    @State private var guardando = false
    @State private var cargando = false
    @State private var mostrarExito = false
    @State private var errorTexto = ""

    private var monto: Double? {
        let normalizado = montoTexto.replacingOccurrences(of: ",", with: ".")
        guard !normalizado.isEmpty else { return nil }
        guard let valor = Double(normalizado), valor > 0 else { return nil }
        return valor
    }

    private var guardarHabilitado: Bool {
        monto != nil && !guardando && presupuestoService != nil
    }

    var body: some View {
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    tarjetaMes
                    tarjetaMonto
                    if let ps = presupuestoService, let ms = monedasService {
                        tarjetaResumen(ps, ms)
                    }
                    tarjetaGuardar
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Presupuesto")
            .navigationBarTitleDisplayMode(.inline)
            .task { await cargarServicios() }
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

    private var tarjetaMes: some View {
        Tarjeta {
            HStack {
                BotonIcono(icono: "chevron.left") { cambiarMes(-1) }
                Spacer()
                VStack(spacing: 2) {
                    Text(nombreMes(mes))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Mes del presupuesto")
                        .font(.caption2)
                        .foregroundStyle(Tema.textoSuave)
                }
                Spacer()
                BotonIcono(icono: "chevron.right") { cambiarMes(1) }
            }
        }
    }

    private var tarjetaMonto: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 16) {
                SeccionTitulo(titulo: "Configuración", icono: "target")

                VStack(alignment: .leading, spacing: 8) {
                    EtiquetaCampo(titulo: "Moneda")
                    CampoSeleccion(
                        titulo: "Selecciona una moneda",
                        icono: "dollarsign.circle.fill",
                        seleccion: $monedaCodigo,
                        opciones: MONEDAS.map {
                            OpcionSeleccion(valor: $0.codigo, titulo: "\($0.codigo) - \($0.nombre)")
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    EtiquetaCampo(titulo: "Monto del presupuesto")
                    CampoTexto(
                        titulo: "0",
                        icono: "banknote.fill",
                        texto: $montoTexto,
                        teclado: .decimalPad
                    )
                }
            }
        }
    }

    private func tarjetaResumen(_ ps: PresupuestoService, _ ms: MonedasService) -> some View {
        let color = EstadoPresupuesto.color(ps.estado)
        return Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SeccionTitulo(titulo: "Resumen del mes", icono: "chart.pie.fill")
                    Spacer()
                    Insignia(texto: EstadoPresupuesto.texto(ps.estado), color: color)
                }

                HStack {
                    EtiquetaCampo(titulo: "Presupuesto actual")
                    Spacer()
                    Text(ms.formatear(ps.presupuesto))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }

                HStack {
                    EtiquetaCampo(titulo: "Gasto del mes")
                    Spacer()
                    Text(ms.formatear(ps.gastoDelMes))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }

                if ps.presupuesto > 0 {
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
                        Text("Disponible \(ms.formatear(ps.restante))")
                            .font(.caption)
                            .foregroundStyle(Tema.textoSecundario)
                    }
                }
            }
        }
    }

    private var tarjetaGuardar: some View {
        VStack(spacing: 12) {
            if mostrarExito {
                AvisoGlass(texto: "¡Presupuesto guardado correctamente!", icono: "checkmark.circle.fill", color: Tema.verde)
            }
            if !errorTexto.isEmpty {
                AvisoGlass(texto: errorTexto, icono: "exclamationmark.circle.fill", color: Tema.rojo)
            } else if let ps = presupuestoService, !ps.error.isEmpty {
                AvisoGlass(texto: ps.error, icono: "exclamationmark.circle.fill", color: Tema.rojo)
            }

            BotonPrincipal(
                titulo: "Guardar presupuesto",
                icono: "checkmark.circle.fill",
                deshabilitado: !guardarHabilitado,
                cargando: guardando
            ) {
                guardarPresupuesto()
            }
        }
    }

    private func cargarServicios() async {
        cargando = true
        if monedasService == nil {
            monedasService = MonedasService(tasasService: tasasService)
        }
        guard let usuario = auth.usuario else {
            errorTexto = "No hay sesión activa"
            cargando = false
            return
        }
        await gastosService.cargar(usuarioId: usuario.id)
        let ps = PresupuestoService(auth: auth, gastosService: gastosService, mes: mes)
        presupuestoService = ps
        monedaCodigo = monedasService?.codigo ?? "COP"
        await tasasService.actualizar()
        await ps.cambiarMes(mes)
        montoTexto = ps.presupuesto > 0 ? String(ps.presupuesto) : ""
        cargando = false
    }

    private func cambiarMes(_ delta: Int) {
        let partes = mes.split(separator: "-")
        guard partes.count == 2, let y = Int(partes[0]), let m = Int(partes[1]) else { return }
        var comps = DateComponents(); comps.year = y; comps.month = m
        guard let fecha = Calendar.current.date(from: comps),
              let nueva = Calendar.current.date(byAdding: .month, value: delta, to: fecha) else { return }
        let ny = Calendar.current.component(.year, from: nueva)
        let nm = Calendar.current.component(.month, from: nueva)
        mes = String(format: "%04d-%02d", ny, nm)
        Task {
            await presupuestoService?.cambiarMes(mes)
            if let ps = presupuestoService {
                montoTexto = ps.presupuesto > 0 ? String(ps.presupuesto) : ""
            }
        }
    }

    private func guardarPresupuesto() {
        guard let monto, let ps = presupuestoService else { return }
        guardando = true
        errorTexto = ""
        mostrarExito = false
        Task {
            await ps.guardar(monto, mes)
            guardando = false
            if ps.error.isEmpty {
                mostrarExito = true
                montoTexto = ps.presupuesto > 0 ? String(ps.presupuesto) : montoTexto
            } else {
                errorTexto = ps.error
            }
        }
    }

    private func nombreMes(_ ym: String) -> String {
        let partes = ym.split(separator: "-")
        guard partes.count == 2, let y = Int(partes[0]), let m = Int(partes[1]) else { return ym }
        var comps = DateComponents(); comps.year = y; comps.month = m
        guard let fecha = Calendar.current.date(from: comps) else { return ym }
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: fecha).capitalized
    }
}

#Preview {
    PresupuestoConfigView()
        .environmentObject(AuthService())
}
