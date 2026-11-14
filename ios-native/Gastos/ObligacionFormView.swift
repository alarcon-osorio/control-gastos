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
    private var monto: Double? {
        let normalizado = montoTexto.replacingOccurrences(of: ",", with: ".")
        guard let valor = Double(normalizado), valor > 0 else { return nil }
        return valor
    }
    private var puedeGuardar: Bool {
        monto != nil && !nombre.trimmingCharacters(in: .whitespaces).isEmpty && !categoria.isEmpty && !guardando
    }

    var body: some View {
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    Tarjeta {
                        VStack(alignment: .leading, spacing: 16) {
                            SeccionTitulo(titulo: "Datos de la obligación", icono: "doc.text.fill")

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Nombre")
                                CampoTexto(
                                    titulo: "Ej. Mercado",
                                    icono: "textformat",
                                    texto: $nombre,
                                    capitalizacion: .sentences
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Monto")
                                CampoTexto(
                                    titulo: "0",
                                    icono: "dollarsign.circle.fill",
                                    texto: $montoTexto,
                                    teclado: .decimalPad
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                EtiquetaCampo(titulo: "Día de pago")
                                CampoSeleccion(
                                    titulo: "Selecciona el día",
                                    icono: "calendar",
                                    seleccion: $diaPago,
                                    opciones: [
                                        OpcionSeleccion<Int?>(valor: Optional(10), titulo: "Día 10"),
                                        OpcionSeleccion<Int?>(valor: Optional(25), titulo: "Día 25"),
                                        OpcionSeleccion<Int?>(valor: nil, titulo: "Hormiga"),
                                    ]
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

                            HStack(spacing: 12) {
                                Image(systemName: "power")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Tema.textoSecundario)
                                    .frame(width: 22)
                                Text("Activa")
                                    .foregroundStyle(.white)
                                Spacer()
                                Toggle("", isOn: $activa)
                                    .labelsHidden()
                                    .tint(Tema.verde)
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
                    }

                    if obligacion != nil {
                        Button(role: .destructive) {
                            eliminar()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Eliminar obligación")
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
                        .disabled(guardando)
                    }

                    BotonPrincipal(
                        titulo: "Guardar obligación",
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
        .navigationTitle(obligacion == nil ? "Nueva obligación" : "Editar obligación")
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

    private func guardar() {
        guard let usuario = auth.usuario, let monto, !nombre.isEmpty, !categoria.isEmpty else { return }
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

    private func eliminar() {
        guard let o = obligacion, let os = obligacionesService else { return }
        guardando = true
        Task {
            await os.eliminar(id: o.id)
            guardando = false
            dismiss()
        }
    }
}
