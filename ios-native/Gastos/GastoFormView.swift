import SwiftUI

struct GastoFormView: View {
    @EnvironmentObject var auth: AuthService
    var gasto: Gasto? = nil
    @State private var gastosService = GastosService()
    @StateObject private var parametrosService = ParametrosService()
    @State private var montoTexto = ""
    @State private var categoria = ""
    @State private var metodoPago = ""
    @State private var fecha = Date()
    @State private var descripcion = ""
    @State private var guardando = false
    @Environment(\.dismiss) private var dismiss

    private var esEdicion: Bool { gasto != nil }
    private var categorias: [String] {
        var lista = parametrosService.nombresPorTipo("categoria")
        if let g = gasto, !lista.contains(g.categoria) { lista.append(g.categoria) }
        return lista
    }
    private var metodos: [String] {
        var lista = parametrosService.nombresPorTipo("metodoPago")
        if let g = gasto, !lista.contains(g.metodoPago) { lista.append(g.metodoPago) }
        return lista
    }

    private func fechaString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func parsearFecha(_ s: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s) ?? Date()
    }

    var body: some View {
        Form {
            Section("Monto") {
                TextField("Monto en COP", text: $montoTexto)
                    .keyboardType(.decimalPad)
            }
            Section("Categoría") {
                Picker("Categoría", selection: $categoria) {
                    ForEach(categorias, id: \.self) { Text($0) }
                }
            }
            Section("Método de pago") {
                Picker("Método", selection: $metodoPago) {
                    ForEach(metodos, id: \.self) { Text($0) }
                }
            }
            Section("Fecha") {
                DatePicker("Fecha", selection: $fecha, displayedComponents: .date)
            }
            Section("Descripción") {
                TextField("Descripción", text: $descripcion)
            }
        }
        .navigationTitle(esEdicion ? "Editar gasto" : "Nuevo gasto")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    guard let usuario = auth.usuario, let monto = Double(montoTexto) else { return }
                    guard !categoria.isEmpty, !metodoPago.isEmpty else { return }
                    guardando = true
                    Task {
                        if let g = gasto {
                            try? await gastosService.actualizar(id: g.id, cambios: [
                                "monto": monto,
                                "categoria": categoria,
                                "metodoPago": metodoPago,
                                "fecha": fechaString(fecha),
                                "descripcion": descripcion,
                            ])
                        } else {
                            _ = try? await gastosService.agregar(Gasto(
                                id: 0, usuarioId: usuario.id, monto: monto,
                                categoria: categoria, metodoPago: metodoPago,
                                fecha: fechaString(fecha), descripcion: descripcion))
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
                if !categorias.contains(categoria) { categoria = categorias.first ?? "" }
                if !metodos.contains(metodoPago) { metodoPago = metodos.first ?? "" }
            }
            if let g = gasto {
                montoTexto = String(format: "%.0f", g.monto)
                categoria = g.categoria
                metodoPago = g.metodoPago
                fecha = parsearFecha(g.fecha)
                descripcion = g.descripcion
            }
        }
    }
}