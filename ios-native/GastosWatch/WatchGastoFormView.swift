import SwiftUI
import WatchKit

struct WatchGastoFormView: View {
    @EnvironmentObject var auth: AuthService
    @ObservedObject var model: WatchModel
    @Environment(\.dismiss) private var dismiss

    @State private var montoTexto = ""
    @State private var categoria = "Otros"
    @State private var metodoPago = "Efectivo"
    @State private var descripcion = ""
    @State private var guardando = false
    @State private var guardado = false
    @State private var error = ""

    private var monto: Double? {
        let limpio = montoTexto
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
        guard !limpio.isEmpty else { return nil }

        var normalizado = limpio
        if limpio.contains(",") {
            normalizado = limpio
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        } else {
            let partes = limpio.split(separator: ".", omittingEmptySubsequences: false)
            if partes.count > 2 {
                normalizado = limpio.replacingOccurrences(of: ".", with: "")
            } else if partes.count == 2, let decimales = partes.last, decimales.count == 3 {
                normalizado = limpio.replacingOccurrences(of: ".", with: "")
            }
        }

        guard let valor = Double(normalizado), valor > 0 else { return nil }
        return valor
    }

    private var categorias: [String] {
        var lista = model.parametrosService.nombresPorTipo("categoria")
        if lista.isEmpty { lista = ["Otros"] }
        if !lista.contains(categoria) { lista.append(categoria) }
        return lista
    }

    private var metodos: [String] {
        var lista = model.parametrosService.nombresPorTipo("metodoPago")
        if lista.isEmpty { lista = ["Efectivo"] }
        if !lista.contains(metodoPago) { lista.append(metodoPago) }
        return lista
    }

    private var puedeGuardar: Bool {
        monto != nil && !categoria.isEmpty && !metodoPago.isEmpty && !guardando && !guardado
    }

    var body: some View {
        ZStack {
            WatchFondo()

            ScrollView {
                VStack(spacing: 9) {
                    WatchTarjeta {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MONTO EN COP")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(0.7)
                                .foregroundStyle(WatchTema.textoSuave)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(WatchTema.textoSecundario)

                                TextField("0", text: $montoTexto)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .tint(.white)
                            }
                        }
                    }

                    WatchTarjeta {
                        Picker("Categoría", selection: $categoria) {
                            ForEach(categorias, id: \.self) { valor in
                                Label(valor, systemImage: WatchIconoCategoria.icono(valor))
                                    .tag(valor)
                            }
                        }
                        .font(.caption)
                        .tint(.white)
                    }

                    WatchTarjeta {
                        Picker("Método", selection: $metodoPago) {
                            ForEach(metodos, id: \.self) { valor in
                                Text(valor).tag(valor)
                            }
                        }
                        .font(.caption)
                        .tint(.white)
                    }

                    WatchTarjeta {
                        TextField("Descripción (opcional)", text: $descripcion)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .tint(.white)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Hoy, \(fechaCorta)")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(WatchTema.textoSuave)

                    if !error.isEmpty {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(WatchTema.rojo)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if guardado {
                        Label("Gasto guardado", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WatchTema.verde)
                    }

                    WatchBotonPrincipal(
                        titulo: "Guardar gasto",
                        icono: "checkmark.circle.fill",
                        deshabilitado: !puedeGuardar,
                        cargando: guardando
                    ) {
                        guardar()
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 10)
            }
        }
        .navigationTitle("Nuevo gasto")
        .task {
            if let id = auth.usuario?.id {
                await model.cargarParametros(usuarioId: id)
            }
        }
    }

    private var fechaCorta: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "d MMM"
        return f.string(from: Date())
    }

    private func guardar() {
        guard !guardando, !guardado else { return }
        guard let usuario = auth.usuario, let monto, !categoria.isEmpty, !metodoPago.isEmpty else {
            error = "Completa el monto y la categoría."
            return
        }

        error = ""
        guardando = true

        Task {
            do {
                _ = try await model.gastosService.agregar(Gasto(
                    id: 0,
                    usuarioId: usuario.id,
                    monto: monto,
                    categoria: categoria,
                    metodoPago: metodoPago,
                    fecha: WatchFecha.hoy(),
                    descripcion: descripcion.trimmingCharacters(in: .whitespacesAndNewlines)
                ))
                WKInterfaceDevice.current().play(.success)
                guardando = false
                guardado = true
                try? await Task.sleep(nanoseconds: 550_000_000)
                dismiss()
            } catch {
                WKInterfaceDevice.current().play(.failure)
                self.error = "No se pudo guardar el gasto."
                guardando = false
            }
        }
    }
}
