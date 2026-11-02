import Foundation
import Supabase
import Combine

struct GastoRow: Codable {
    let id: Int
    let usuario_id: String
    let monto: Double
    let categoria: String
    let metodo_pago: String
    let fecha: String
    let descripcion: String?
}

@MainActor
final class GastosService: ObservableObject {
    @Published var gastos: [Gasto] = []
    @Published var error: String = ""

    func cargar(usuarioId: String) async {
        error = ""
        do {
            let rows: [GastoRow] = try await supabase
                .from("gastos")
                .select()
                .eq("usuario_id", value: usuarioId)
                .order("fecha", ascending: false)
                .execute()
                .value
            gastos = rows.map(mapear)
            print("Gastos cargados: \(gastos.count) para \(usuarioId)")
        } catch {
            self.error = "Error cargando gastos: \(error.localizedDescription)"
            print(self.error)
        }
    }

    func agregar(_ input: Gasto) async throws -> Int {
        struct Payload: Encodable {
            let usuario_id: String
            let monto: Double
            let categoria: String
            let metodo_pago: String
            let fecha: String
            let descripcion: String
            let moneda: String = "COP"
        }
        let payload = Payload(
            usuario_id: input.usuarioId,
            monto: input.monto,
            categoria: input.categoria,
            metodo_pago: input.metodoPago,
            fecha: input.fecha,
            descripcion: input.descripcion
        )
        let row: GastoRow = try await supabase
            .from("gastos")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        let gasto = mapear(row)
        gastos.insert(gasto, at: 0)
        return gasto.id
    }

    func actualizar(id: Int, cambios: [String: Any]) async throws {
        // Supabase Swift espera un Encodable; usamos un diccionario tipado simple.
        var payload: [String: AnyCodable] = [:]
        if let monto = cambios["monto"] as? Double { payload["monto"] = AnyCodable(monto) }
        if let categoria = cambios["categoria"] as? String { payload["categoria"] = AnyCodable(categoria) }
        if let metodo = cambios["metodoPago"] as? String { payload["metodo_pago"] = AnyCodable(metodo) }
        if let fecha = cambios["fecha"] as? String { payload["fecha"] = AnyCodable(fecha) }
        if let descripcion = cambios["descripcion"] as? String { payload["descripcion"] = AnyCodable(descripcion) }

        try await supabase
            .from("gastos")
            .update(payload)
            .eq("id", value: id)
            .execute()

        if let index = gastos.firstIndex(where: { $0.id == id }) {
            var actual = gastos[index]
            if let monto = cambios["monto"] as? Double { actual.monto = monto }
            if let categoria = cambios["categoria"] as? String { actual.categoria = categoria }
            if let metodo = cambios["metodoPago"] as? String { actual.metodoPago = metodo }
            if let fecha = cambios["fecha"] as? String { actual.fecha = fecha }
            if let descripcion = cambios["descripcion"] as? String { actual.descripcion = descripcion }
            gastos[index] = actual
        }
    }

    func eliminar(id: Int) async throws {
        try await supabase
            .from("gastos")
            .delete()
            .eq("id", value: id)
            .execute()
        gastos.removeAll { $0.id == id }
    }

    func gastosPorUsuario(_ usuarioId: String) -> [Gasto] {
        gastos.filter { $0.usuarioId == usuarioId }.sorted { $0.fecha > $1.fecha }
    }

    func totalUsuario(_ usuarioId: String) -> Double {
        gastos.filter { $0.usuarioId == usuarioId }.reduce(0) { $0 + $1.monto }
    }

    func totalPorCategoria(_ usuarioId: String) -> [String: Double] {
        var mapa: [String: Double] = [:]
        for g in gastos where g.usuarioId == usuarioId {
            mapa[g.categoria, default: 0] += g.monto
        }
        return mapa
    }

    private func mapear(_ r: GastoRow) -> Gasto {
        Gasto(
            id: r.id,
            usuarioId: r.usuario_id,
            monto: r.monto,
            categoria: r.categoria,
            metodoPago: r.metodo_pago,
            fecha: r.fecha,
            descripcion: r.descripcion ?? ""
        )
    }
}

// Helper para enviar diccionarios dinámicos a Supabase.
struct AnyCodable: Encodable {
    let value: Any
    init(_ value: Any) { self.value = value }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let v = value as? Double { try container.encode(v) }
        else if let v = value as? String { try container.encode(v) }
        else if let v = value as? Int { try container.encode(v) }
        else if let v = value as? Bool { try container.encode(v) }
    }
}