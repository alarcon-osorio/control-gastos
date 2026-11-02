import SwiftUI
struct ObligacionFormView: View {
    @EnvironmentObject var auth: AuthService
    var obligacion: Obligacion? = nil
    var mes: String = ""
    @State private var gastosService = GastosService()
    @State private var obligacionesService: ObligacionesService?
    @StateObject private var parametrosService = ParametrosService()
    @State private var nombre = ""
    @State private var montoTexto = ""
    @State private var diaPago: Int? = 10
    @State private var categoria = ""
    @State private var activa = true
    @State private var guardando = false
    @Environment(\.dismiss) private var dismiss
    private var categorias: [String] { parametrosService.nombresPorTipo("categoria") }
    private var mesActual: String {
        if !mes.isEmpty { return mes }
        let now = Date()
        let y = Calendar.current.component(.year, from: now)
        let m = Calendar.current.component(.month, from: now)
        return String(format: "%04d-%02d", y, m)
    }
    var body: some View {
        Form {
            Section("Nombre") { TextField("Nombre", text: $nombre) }
            Section("Monto") { TextField("Monto", text: $montoTexto).keyboardType(.decimalPad) }
            Section("Día de pago") {
                Picker("Día", selection: $diaPago) {
                    Text("10").tag(Optional(10))
                    Text("25").tag(Optional(25))
                    Text("Hormiga").tag(Optional<Int>(nil))
                }
            }
            Section("Categoría") {
                Picker("Categoría", selection: $categoria) {
                    ForEach(categorias, id: \.self) { Text($0) }
                }
            }
            Section { Toggle("Activa", isOn: $activa) }
            Section {
                Button("Eliminar obligación", role: .destructive) {
                    guard let o = obligacion, let os = obligacionesService else { return }
                    guardando = true
                    Task {
                        await os.eliminar(id: o.id)
                        guardando = false
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(obligacion == nil ? "Nueva obligación" : "Editar obligación")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    guard let usuario = auth.usuario, let monto = Double(montoTexto), !nombre.isEmpty, !categoria.isEmpty else { return }
                    guardando = true
                    Task {
                        if let os = obligacionesService {
                            if let o = obligacion {
                                await os.actualizar(id: o.id, nombre: nombre, monto: o.monto, diaPago: diaPago, categoria: categoria, activa: activa)
                                await os.establecerMonto(o, mes: mesActual, monto: monto)
                            } else {
                                await os.agregar(Obligacion(id: 0, usuarioId: usuario.id, nombre: nombre, monto: monto, diaPago: diaPago, categoria: categoria, activa: activa))
                            }
                        }
                        guardando = false
                        dismiss()
                    }
                }
                .disabled(guardando)
            }
        }
        .task {
            if let id = auth.usuario?.id {
                await parametrosService.cargar(usuarioId: id)
                if categoria.isEmpty { categoria = categorias.first ?? "" }
            }
            let tasasService = TasasService()
            let monedasService = MonedasService(tasasService: tasasService)
            let os = ObligacionesService(gastosService: gastosService, tasasService: tasasService, monedasService: monedasService)
            if let id = auth.usuario?.id { await os.cargar(usuarioId: id) }
            obligacionesService = os
            if let o = obligacion {
                nombre = o.nombre
                montoTexto = String(format: "%.0f", o.monto)
                diaPago = o.diaPago
                categoria = o.categoria
                activa = o.activa
            }
        }
    }
}