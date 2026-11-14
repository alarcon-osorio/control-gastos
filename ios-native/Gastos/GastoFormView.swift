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
    private var monto: Double? {
        let normalizado = montoTexto.replacingOccurrences(of: ",", with: ".")
        guard let valor = Double(normalizado), valor > 0 else { return nil }
        return valor
    }
    private var puedeGuardar: Bool {
        monto != nil && !categoria.isEmpty && !metodoPago.isEmpty && !guardando
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
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    Tarjeta {
                        VStack(alignment: .leading, spacing: 16) {
                            SeccionTitulo(titulo: "Datos del gasto", icono: "square.and.pencil")

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Monto en COP")
                                CampoTexto(
                                    titulo: "0",
                                    icono: "dollarsign.circle.fill",
                                    texto: $montoTexto,
                                    teclado: .decimalPad
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Categoría")
                                CampoSeleccion(
                                    titulo: "Selecciona una categoría",
                                    icono: "tag.fill",
                                    seleccion: $categoria,
                                    opciones: categorias.map { OpcionSeleccion(valor: $0, titulo: $0) }
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Método de pago")
                                CampoSeleccion(
                                    titulo: "Selecciona un método",
                                    icono: "creditcard.fill",
                                    seleccion: $metodoPago,
                                    opciones: metodos.map { OpcionSeleccion(valor: $0, titulo: $0) }
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Fecha")
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Tema.textoSecundario)
                                        .frame(width: 22)
                                    Text("Fecha del gasto")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    DatePicker("", selection: $fecha, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(.white)
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Tema.campoFondo)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Tema.borde, lineWidth: 1)
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Descripción")
                                CampoTexto(
                                    titulo: "¿En qué gastaste? (opcional)",
                                    icono: "text.alignleft",
                                    texto: $descripcion,
                                    capitalizacion: .sentences
                                )
                            }
                        }
                    }

                    BotonPrincipal(
                        titulo: "Guardar gasto",
                        icono: "checkmark.circle.fill",
                        deshabilitado: !puedeGuardar,
                        cargando: guardando
                    ) {
                        guardar()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(esEdicion ? "Editar gasto" : "Nuevo gasto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") { guardar() }
                    .fontWeight(.semibold)
                    .foregroundStyle(puedeGuardar ? .white : .white.opacity(0.4))
                    .disabled(!puedeGuardar)
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

    private func guardar() {
        guard let usuario = auth.usuario, let monto, !categoria.isEmpty, !metodoPago.isEmpty else { return }
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
}
