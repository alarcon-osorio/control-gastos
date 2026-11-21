import SwiftUI

enum WatchTema {
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
}

struct WatchFondo: View {
    var body: some View {
        ZStack {
            WatchTema.gradienteFondo.ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 160, height: 160)
                .blur(radius: 8)
                .offset(x: -70, y: -120)

            Circle()
                .fill(WatchTema.azul.opacity(0.35))
                .frame(width: 140, height: 140)
                .blur(radius: 50)
                .offset(x: 90, y: 130)
        }
    }
}

struct WatchTarjeta<Content: View>: View {
    var padding: CGFloat = 10
    var radio: CGFloat = 14
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
                            .fill(Color.black.opacity(0.12))
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: radio, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radio, style: .continuous)
                    .stroke(WatchTema.borde, lineWidth: 1)
            )
    }
}

struct WatchBotonPrincipal: View {
    var titulo: String
    var icono: String? = nil
    var deshabilitado: Bool = false
    var cargando: Bool = false
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            ZStack {
                if cargando {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 6) {
                        if let icono {
                            Image(systemName: icono)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(titulo)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(WatchTema.gradienteAcento)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .opacity(deshabilitado ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(deshabilitado || cargando)
    }
}

struct WatchBotonIcono: View {
    var icono: String
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Image(systemName: icono)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(WatchTema.campoFondo)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(WatchTema.borde, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct WatchBarraProgreso: View {
    var valor: Double
    var colores: [Color] = [WatchTema.verde, WatchTema.azul]
    var altura: CGFloat = 6

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

enum WatchIconoCategoria {
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
        if coincide(c, ["aliment", "mercado", "comida", "restaurante", "cafe"]) { return WatchTema.naranja }
        if coincide(c, ["transport", "gasolina", "carro", "auto", "moto", "uber", "taxi"]) { return WatchTema.azul }
        if coincide(c, ["vivienda", "hipoteca", "administraci", "acueducto", "arriendo"]) { return WatchTema.morado }
        if coincide(c, ["servicio", "gas", "enel", "codensa", "movistar", "claro", "luz", "agua", "internet"]) { return WatchTema.amarillo }
        if coincide(c, ["deuda", "tarjeta", "credito", "crédito", "banco"]) { return WatchTema.rojo }
        if coincide(c, ["ocio", "música", "musica", "juego", "volley", "cine", "entretenimiento"]) { return WatchTema.verde }
        if coincide(c, ["salud", "medic", "farmacia", "gimnasio"]) { return WatchTema.rojo }
        if coincide(c, ["educaci", "estudio", "curso", "libro"]) { return WatchTema.azul }
        if coincide(c, ["ropa", "compras", "shopping"]) { return WatchTema.naranja }
        return WatchTema.verde
    }

    private static func coincide(_ texto: String, _ claves: [String]) -> Bool {
        claves.contains { texto.contains($0) }
    }
}
