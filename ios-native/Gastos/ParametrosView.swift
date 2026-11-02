import SwiftUI
struct ParametrosView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var service = ParametrosService()
    @State private var nuevoNombre = ""
    @State private var tipoSeleccionado = "categoria"
    @State private var parametroEditar: Parametro?
    @State private var nombreEdicion = ""
    var body: some View {
        NavigationStack {
            List {
                Section("Categorías") {
                    ForEach(service.parametros.filter { $0.tipo == "categoria" }) { p in
                        HStack {
                            Text(p.nombre)
                            Spacer()
                            Button { parametroEditar = p; nombreEdicion = p.nombre } label: { Image(systemName: "pencil") }.buttonStyle(.plain)
                        }
                    }
                }
                Section("Métodos de pago") {
                    ForEach(service.parametros.filter { $0.tipo == "metodoPago" }) { p in
                        HStack {
                            Text(p.nombre)
                            Spacer()
                            Button { parametroEditar = p; nombreEdicion = p.nombre } label: { Image(systemName: "pencil") }.buttonStyle(.plain)
                        }
                    }
                }
                Section("Agregar") {
                    Picker("Tipo", selection: $tipoSeleccionado) {
                        Text("Categoría").tag("categoria")
                        Text("Método de pago").tag("metodoPago")
                    }
                    TextField("Nombre", text: $nuevoNombre)
                    Button("Agregar") {
                        guard let id = auth.usuario?.id else { return }
                        Task {
                            _ = await service.agregar(usuarioId: id, tipo: tipoSeleccionado, nombre: nuevoNombre)
                            nuevoNombre = ""
                        }
                    }
                }
            }
            .navigationTitle("Parámetros")
            .task {
                if let id = auth.usuario?.id { await service.cargar(usuarioId: id) }
            }
            .sheet(item: $parametroEditar, onDismiss: {
                Task { if let id = auth.usuario?.id { await service.cargar(usuarioId: id) } }
            }) { p in
                NavigationStack {
                    Form {
                        Section("Nombre") {
                            TextField("Nombre", text: $nombreEdicion)
                        }
                        Section {
                            Button("Guardar") {
                                Task {
                                    _ = await service.actualizar(id: p.id, nombre: nombreEdicion)
                                    parametroEditar = nil
                                }
                            }
                            Button("Eliminar", role: .destructive) {
                                Task {
                                    await service.eliminar(id: p.id)
                                    parametroEditar = nil
                                }
                            }
                        }
                    }
                    .navigationTitle("Editar parámetro")
                }
            }
        }
    }
}