import SwiftUI

struct StatCard: View {
    let titulo: String
    let valor: String
    var icono: String? = nil
    var color: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let icono {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.22))
                        .frame(width: 36, height: 36)
                    Image(systemName: icono)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(color)
                }
            }

            Text(valor)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)

            Text(titulo)
                .font(.caption2)
                .foregroundStyle(Tema.textoSecundario)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.10))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}
