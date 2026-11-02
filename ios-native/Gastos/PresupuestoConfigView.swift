import SwiftUI

struct PresupuestoConfigView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var gastosService = GastosService()
    @State private var presupuestoService: PresupuestoService?
    @State private var monedasService: MonedasService?
    @State private var montoTexto = ""
    @State private var guardando = false
    @State private var mostrarExito = false
    @State private var mesInicial: String = {
        let now = Date()
        let y = Calendar.current.component(.year, from: now)
        let m = Calendar.current.component(.month, from: now)
        return String(format: "%04d-%02d", y, m)
    }()
    @State private var cargando = false
    @State private var version = 0

    private var mesActual: String { presupuestoService?.mes ?? mesInicial }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Selector de mes
                HStack {
                    Button(action: mesAnterior) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    Spacer()
                    Text(nombreMes(mesActual))
                        .font(.title2.bold())
                    Spacer()
                    Button(action: mesSiguiente) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Configurar Presupuesto")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monto del presupuesto (COP)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("0", text: $montoTexto)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }

                    if let usuario = auth.usuario, let ps = presupuestoService, let ms = monedasService {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mes: \(mesActual)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("Presupuesto actual:")
                                Spacer()
                                Text(ms.formatear(ps.presupuesto))
                                    .font(.headline)
                            }

                            HStack {
                                Text("Gasto del mes:")
                                Spacer()
                                Text(ms.formatear(ps.gastoDelMes))
                                    .font(.subheadline)
                            }

                            if ps.presupuesto > 0 {
                                HStack {
                                    Text("Porcentaje usado:")
                                    Spacer()
                                    Text("\(ps.porcentaje)%")
                                        .font(.subheadline)
                                        .foregroundStyle(porcentajeColor(ps))
                                }

                                ProgressView(value: min(Double(ps.porcentaje), 100), total: 100)
                                    .padding(.vertical, 4)
                            }

                            Text("Estado: \(estadoTexto(ps))")
                                .font(.caption)
                                .foregroundStyle(estadoColor(ps))
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    }
                }
                .padding()

                Spacer()

                Button(action: guardarPresupuesto) {
                    Text(guardando ? "Guardando..." : "Guardar Presupuesto")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(guardarHabilitado ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!guardarHabilitado || guardando)
                .padding(.horizontal)

                if mostrarExito {
                    Text("¡Presupuesto guardado correctamente!")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .transition(.opacity)
                }
                if let ps = presupuestoService, !ps.error.isEmpty {
                    Text(ps.error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Presupuesto")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await cargarServicios()
            }
            .overlay { if cargando { ProgressView() } }
        }
    }

    private func cargarServicios() async {
        guard let id = auth.usuario?.id else { return }
        cargando = true
        let ts = TasasService()
        await ts.actualizar()
        monedasService = MonedasService(tasasService: ts)
        let ps = PresupuestoService(auth: auth, gastosService: gastosService, mes: mesInicial)
        await ps.cargar()
        presupuestoService = ps
        cargando = false
        version += 1
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

    private func mesAnterior() {
        guard let date = fechaDesdeMes(mesActual) else { return }
        let cal = Calendar.current
        if let nueva = cal.date(byAdding: .month, value: -1, to: date) {
            let y = cal.component(.year, from: nueva)
            let m = cal.component(.month, from: nueva)
            let nuevo = String(format: "%04d-%02d", y, m)
            Task {
                await presupuestoService?.cambiarMes(nuevo)
            }
        }
    }

    private func mesSiguiente() {
        guard let date = fechaDesdeMes(mesActual) else { return }
        let cal = Calendar.current
        if let nueva = cal.date(byAdding: .month, value: 1, to: date) {
            let y = cal.component(.year, from: nueva)
            let m = cal.component(.month, from: nueva)
            let nuevo = String(format: "%04d-%02d", y, m)
            Task {
                await presupuestoService?.cambiarMes(nuevo)
            }
        }
    }

    private func fechaDesdeMes(_ mes: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.date(from: mes)
    }

    private var monto: Double? {
        guard !montoTexto.isEmpty else { return nil }
        return Double(montoTexto) ?? 0
    }

    private var guardarHabilitado: Bool {
        guard let monto = monto, monto > 0 else { return false }
        guard !guardando else { return false }
        return true
    }

    private func porcentajeColor(_ ps: PresupuestoService) -> Color {
        if ps.porcentaje >= 100 { return .red }
        if ps.porcentaje >= 80 { return .orange }
        return .green
    }

    private func estadoTexto(_ ps: PresupuestoService) -> String {
        switch ps.estado {
        case "sin-presupuesto": return "Sin presupuesto establecido"
        case "ok": return "Dentro del presupuesto"
        case "cerca": return "Cerca del límite (80%)"
        case "excedido": return "Presupuesto excedido"
        default: return ""
        }
    }

    private func estadoColor(_ ps: PresupuestoService) -> Color {
        switch ps.estado {
        case "sin-presupuesto": return .gray
        case "ok": return .green
        case "cerca": return .orange
        case "excedido": return .red
        default: return .primary
        }
    }

    private func guardarPresupuesto() {
        guard let monto = monto, monto > 0, let ps = presupuestoService else { return }
        guardando = true

        Task {
            await ps.guardar(monto)
            montoTexto = ""
            mostrarExito = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.mostrarExito = false
            }
            guardando = false
        }
    }
}

#Preview {
    PresupuestoConfigView()
        .environmentObject(AuthService())
}
