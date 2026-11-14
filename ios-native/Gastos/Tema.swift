import SwiftUI

/// Tema compartido para toda la app, al estilo del login.
enum Tema {
    static let azul = Color(red: 0.357, green: 0.525, blue: 0.898)
    static let morado = Color(red: 0.482, green: 0.184, blue: 0.969)
    static let verde = Color(red: 0.235, green: 0.839, blue: 0.541)
    static let naranja = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let rojo = Color(red: 1.0, green: 0.353, blue: 0.408)
    static let amarillo = Color(red: 1.0, green: 0.792, blue: 0.157)

    static let texto = Color.white
    static let textoSecundario = Color.white.opacity(0.75)
    static let textoSuave = Color.white.opacity(0.55)
    static let borde = Color.white.opacity(0.22)
    static let campoFondo = Color.white.opacity(0.12)

    static var gradienteFondo: LinearGradient {
        LinearGradient(
            colors: [azul, morado],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var gradienteAcento: LinearGradient {
        LinearGradient(
            colors: [azul, morado],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var gradienteExito: LinearGradient {
        LinearGradient(
            colors: [verde, azul],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// Fondo con gradiente y burbujas decorativas, idéntico al login.
struct FondoGradiente: View {
    var body: some View {
        ZStack {
            Tema.gradienteFondo.ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 10)
                .offset(x: -140, y: -260)
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 260, height: 260)
                .blur(radius: 10)
                .offset(x: 160, y: 300)
            Circle()
                .fill(Tema.azul.opacity(0.35))
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: 130, y: -280)
        }
    }
}

/// Tarjeta glassmorphism reutilizable.
struct Tarjeta<Content: View>: View {
    var padding: CGFloat = 18
    var radio: CGFloat = 24
    @ViewBuilder var contenido: Content

    var body: some View {
        contenido
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radio, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radio, style: .continuous)
                            .fill(Color.black.opacity(0.10))
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: radio, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radio, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }
}

/// Encabezado con icono para las pantallas internas.
struct EncabezadoPantalla: View {
    var titulo: String
    var subtitulo: String
    var icono: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: icono)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitulo)
                    .font(.subheadline)
                    .foregroundStyle(Tema.textoSecundario)
            }
            Spacer()
        }
    }
}

/// Título de sección dentro de una tarjeta.
struct SeccionTitulo: View {
    var titulo: String
    var icono: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icono {
                Image(systemName: icono)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(titulo)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

/// Etiqueta pequeña para los formularios.
struct EtiquetaCampo: View {
    var titulo: String

    var body: some View {
        Text(titulo.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Tema.textoSuave)
    }
}

/// Botón principal con gradiente.
struct BotonPrincipal: View {
    var titulo: String
    var icono: String? = nil
    var deshabilitado: Bool = false
    var cargando: Bool = false
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            ZStack {
                if cargando {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        if let icono {
                            Image(systemName: icono)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(titulo)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Tema.gradienteAcento)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Tema.morado.opacity(0.35), radius: 14, y: 8)
            .opacity(deshabilitado ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(deshabilitado || cargando)
    }
}

/// Botón secundario translúcido.
struct BotonGlass: View {
    var titulo: String
    var icono: String? = nil
    var deshabilitado: Bool = false
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 8) {
                if let icono {
                    Image(systemName: icono)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(titulo)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Tema.campoFondo)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Tema.borde, lineWidth: 1)
            )
            .opacity(deshabilitado ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(deshabilitado)
    }
}

/// Botón cuadrado translúcido para iconos (toolbar, navegación de mes).
struct BotonIcono: View {
    var icono: String
    var tamano: CGFloat = 42
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Image(systemName: icono)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: tamano, height: tamano)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Tema.campoFondo)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Tema.borde, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Campo de texto moderno con icono, sobre el fondo gradiente.
struct CampoTexto: View {
    var titulo: String
    var icono: String
    @Binding var texto: String
    var teclado: UIKeyboardType = .default
    var esSeguro: Bool = false
    var contentType: UITextContentType? = nil
    var capitalizacion: TextInputAutocapitalization = .never

    @FocusState private var enfocado: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icono)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Tema.textoSecundario)
                .frame(width: 22)

            ZStack(alignment: .leading) {
                if texto.isEmpty {
                    Text(titulo)
                        .foregroundStyle(Tema.textoSuave)
                        .allowsHitTesting(false)
                }

                Group {
                    if esSeguro {
                        SecureField("", text: $texto)
                    } else {
                        TextField("", text: $texto)
                            .keyboardType(teclado)
                    }
                }
                .textContentType(contentType)
                .textInputAutocapitalization(capitalizacion)
                .autocorrectionDisabled()
                .focused($enfocado)
                .foregroundStyle(.white)
                .tint(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Tema.campoFondo)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(enfocado ? Color.white.opacity(0.75) : Tema.borde, lineWidth: 1.5)
        )
    }
}

/// Opción para los menús de selección.
struct OpcionSeleccion<T: Hashable>: Identifiable {
    let valor: T
    let titulo: String
    var id: T { valor }
}

/// Selector con estilo glass y menú desplegable.
struct CampoSeleccion<T: Hashable>: View {
    var titulo: String
    var icono: String
    @Binding var seleccion: T
    var opciones: [OpcionSeleccion<T>]

    private var tituloActual: String {
        opciones.first { $0.valor == seleccion }?.titulo ?? titulo
    }

    var body: some View {
        Menu {
            ForEach(opciones) { opcion in
                Button {
                    seleccion = opcion.valor
                } label: {
                    if opcion.valor == seleccion {
                        Label(opcion.titulo, systemImage: "checkmark")
                    } else {
                        Text(opcion.titulo)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icono)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Tema.textoSecundario)
                    .frame(width: 22)

                Text(tituloActual)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Tema.textoSecundario)
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
}

/// Barra de progreso con gradiente.
struct BarraProgreso: View {
    var valor: Double
    var colores: [Color] = [Tema.azul, Tema.morado]
    var altura: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.14))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: colores,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(1, valor)) * geo.size.width)
            }
        }
        .frame(height: altura)
    }
}

/// Insignia de estado.
struct Insignia: View {
    var texto: String
    var color: Color

    var body: some View {
        Text(texto)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.18)))
            .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
    }
}

/// Aviso translúcido para errores o confirmaciones.
struct AvisoGlass: View {
    var texto: String
    var icono: String
    var color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 15, weight: .semibold))
            Text(texto)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

/// Línea divisoria sutil.
struct Divisor: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 1)
    }
}

/// Iconos y colores asociados a las categorías de gasto.
enum IconoCategoria {
    static func icono(_ categoria: String) -> String {
        let c = categoria.lowercased()
        if coincide(c, ["aliment", "mercado", "comida", "restaurante", "cafe"]) { return "fork.knife" }
        if coincide(c, ["transport", "gasolina", "carro", "auto", "moto", "uber", "taxi"]) { return "car.fill" }
        if coincide(c, ["vivienda", "hipoteca", "administraci", "acueducto", "arriendo"]) { return "house.fill" }
        if coincide(c, ["servicio", "gas", "enel", "codensa", "movistar", "claro", "luz", "agua", "internet"]) { return "bolt.fill" }
        if coincide(c, ["deuda", "tarjeta", "credito", "crédito", "banco"]) { return "creditcard.fill" }
        if coincide(c, ["ocio", "música", "musica", "juego", "volley", "cine", "entretenimiento"]) { return "gamecontroller.fill" }
        if coincide(c, ["salud", "medic", "farmacia", "gimnasio"]) { return "cross.case.fill" }
        if coincide(c, ["educaci", "estudio", "curso", "libro"]) { return "book.fill" }
        if coincide(c, ["ropa", "compras", "shopping"]) { return "bag.fill" }
        return "tag.fill"
    }

    static func color(_ categoria: String) -> Color {
        let c = categoria.lowercased()
        if coincide(c, ["aliment", "mercado", "comida", "restaurante", "cafe"]) { return Tema.naranja }
        if coincide(c, ["transport", "gasolina", "carro", "auto", "moto", "uber", "taxi"]) { return Tema.azul }
        if coincide(c, ["vivienda", "hipoteca", "administraci", "acueducto", "arriendo"]) { return Tema.morado }
        if coincide(c, ["servicio", "gas", "enel", "codensa", "movistar", "claro", "luz", "agua", "internet"]) { return Tema.amarillo }
        if coincide(c, ["deuda", "tarjeta", "credito", "crédito", "banco"]) { return Tema.rojo }
        if coincide(c, ["ocio", "música", "musica", "juego", "volley", "cine", "entretenimiento"]) { return Tema.verde }
        if coincide(c, ["salud", "medic", "farmacia", "gimnasio"]) { return Tema.rojo }
        if coincide(c, ["educaci", "estudio", "curso", "libro"]) { return Tema.azul }
        if coincide(c, ["ropa", "compras", "shopping"]) { return Tema.naranja }
        return Tema.verde
    }

    private static func coincide(_ texto: String, _ claves: [String]) -> Bool {
        claves.contains { texto.contains($0) }
    }
}

/// Color de estado del presupuesto.
enum EstadoPresupuesto {
    static func color(_ estado: String) -> Color {
        switch estado {
        case "excedido": return Tema.rojo
        case "cerca": return Tema.naranja
        case "ok": return Tema.verde
        default: return Tema.textoSecundario
        }
    }

    static func texto(_ estado: String) -> String {
        switch estado {
        case "sin-presupuesto": return "Sin presupuesto"
        case "ok": return "Controlado"
        case "cerca": return "Cerca del límite"
        case "excedido": return "Excedido"
        default: return estado
        }
    }
}
