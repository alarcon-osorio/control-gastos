import SwiftUI

struct ParametrosView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var service = ParametrosService()
    @State private var nuevoNombre = ""
    @State private var tipoSeleccionado = "categoria"
    @State private var parametroEditar: Parametro?
    @State private var nombreEdicion = ""
    @State private var mensaje = ""
    @State private var mensajeEsError = false

    private var categorias: [Parametro] {
        service.parametros.filter { $0.tipo == "categoria" }
    }
    private var metodos: [Parametro] {
        service.parametros.filter { $0.tipo == "metodoPago" }
    }
    private var puedeAgregar: Bool {
        !nuevoNombre.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            FondoGradiente()

            ScrollView {
                VStack(spacing: 18) {
                    EncabezadoPantalla(
                        titulo: "Parámetros",
                        subtitulo: "Categorías y métodos de pago",
                        icono: "slider.horizontal.3"
                    )

                    tarjetaParametros(
                        titulo: "Categorías",
                        icono: "tag.fill",
                        color: Tema.naranja,
                        items: categorias
                    )

                    tarjetaParametros(
                        titulo: "Métodos de pago",
                        icono: "creditcard.fill",
                        color: Tema.azul,
                        items: metodos
                    )

                    tarjetaAgregar
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if let id = auth.usuario?.id { await service.cargar(usuarioId: id) }
            }
            .sheet(item: $parametroEditar, onDismiss: {
                Task { if let id = auth.usuario?.id { await service.cargar(usuarioId: id) } }
            }) { p in
                hojaEdicion(p)
            }
        }
    }

    private func tarjetaParametros(titulo: String, icono: String, color: Color, items: [Parametro]) -> some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SeccionTitulo(titulo: titulo, icono: icono)
                    Spacer()
                    Text("\(items.count)")
                        .font(.caption.bold())
                        .foregroundStyle(Tema.textoSecundario)
                }

                if items.isEmpty {
                    Text("Todavía no hay registros")
                        .font(.subheadline)
                        .foregroundStyle(Tema.textoSuave)
                        .padding(.vertical, 6)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, p in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.20))
                                    .frame(width: 34, height: 34)
                                Image(systemName: icono)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(color)
                            }

                            Text(p.nombre)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                nombreEdicion = p.nombre
                                parametroEditar = p
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Tema.textoSecundario)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.white.opacity(0.10)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 5)

                        if index < items.count - 1 { Divisor() }
                    }
                }
            }
        }
    }

    private var tarjetaAgregar: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                SeccionTitulo(titulo: "Agregar parámetro", icono: "plus.circle.fill")

                HStack(spacing: 8) {
                    chipTipo("Categoría", valor: "categoria")
                    chipTipo("Método de pago", valor: "metodoPago")
                }

                CampoTexto(
                    titulo: "Nombre del parámetro",
                    icono: "textformat",
                    texto: $nuevoNombre,
                    capitalizacion: .words
                )

                if !mensaje.isEmpty {
                    AvisoGlass(
                        texto: mensaje,
                        icono: mensajeEsError ? "exclamationmark.circle.fill" : "checkmark.circle.fill",
                        color: mensajeEsError ? Tema.rojo : Tema.verde
                    )
                }

                BotonPrincipal(
                    titulo: "Agregar",
                    icono: "plus",
                    deshabilitado: !puedeAgregar
                ) {
                    agregar()
                }
            }
        }
    }

    private func chipTipo(_ titulo: String, valor: String) -> some View {
        let activo = tipoSeleccionado == valor
        return Button {
            tipoSeleccionado = valor
            mensaje = ""
        } label: {
            Text(titulo)
                .font(.caption.weight(.semibold))
                .foregroundStyle(activo ? .white : Tema.textoSecundario)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(activo ? 0.22 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(activo ? 0.4 : 0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func agregar() {
        guard let id = auth.usuario?.id else { return }
        let nombre = nuevoNombre
        Task {
            let resultado = await service.agregar(usuarioId: id, tipo: tipoSeleccionado, nombre: nombre)
            mensaje = resultado.mensaje
            mensajeEsError = !resultado.ok
            if resultado.ok { nuevoNombre = "" }
        }
    }

    private func hojaEdicion(_ p: Parametro) -> some View {
        NavigationStack {
            ZStack {
                FondoGradiente()

                ScrollView {
                    VStack(spacing: 18) {
                        Tarjeta {
                            VStack(alignment: .leading, spacing: 16) {
                                SeccionTitulo(titulo: "Editar parámetro", icono: "pencil")
                                VStack(alignment: .leading, spacing: 8) {
                                    EtiquetaCampo(titulo: "Nombre")
                                    CampoTexto(
                                        titulo: "Nombre",
                                        icono: "textformat",
                                        texto: $nombreEdicion,
                                        capitalizacion: .words
                                    )
                                }
                            }
                        }

                        Button(role: .destructive) {
                            Task {
                                await service.eliminar(id: p.id)
                                parametroEditar = nil
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Eliminar parámetro")
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

                        BotonPrincipal(titulo: "Guardar cambios", icono: "checkmark.circle.fill") {
                            Task {
                                _ = await service.actualizar(id: p.id, nombre: nombreEdicion)
                                parametroEditar = nil
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Editar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
