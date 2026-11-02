import SwiftUI

struct AjustesView: View {
    @EnvironmentObject var auth: AuthService
    @State private var tasasService = TasasService()
    @State private var monedasService: MonedasService?
    @State private var mostrarPresupuesto = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Presupuesto") {
                    NavigationLink("Configurar presupuesto") {
                        PresupuestoConfigView()
                    }
                }

                if let ms = monedasService {
                    Section("Moneda activa") {
                        Picker("Moneda", selection: Binding(
                            get: { ms.codigo },
                            set: { ms.setMoneda($0) }
                        )) {
                            ForEach(ms.disponibles) { m in
                                Text("\(m.codigo) - \(m.nombre)").tag(m.codigo)
                            }
                        }
                    }
                    Section("Tasas") {
                        Text(ms.tasasService.origen)
                        if let fecha = ms.tasasService.ultimaActualizacion {
                            Text("Actualizado: \(fecha.formatted())")
                        }
                        Button("Actualizar tasas") {
                            Task { await ms.tasasService.actualizar() }
                        }
                    }
                } else {
                    ProgressView()
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        Task { await auth.logout() }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .task {
                let ts = tasasService
                await ts.actualizar()
                monedasService = MonedasService(tasasService: ts)
            }
        }
    }
}
