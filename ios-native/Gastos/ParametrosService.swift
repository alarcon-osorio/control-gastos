import Foundation
import Supabase
import Combine

struct ParametroRow: Codable {
    let id: Int
    let usuario_id: String
    let tipo: String
    let nombre: String
}

@MainActor
final class ParametrosService: ObservableObject {
    @Published var parametros: [Parametro] = []

    private let valoresPorDefecto: [(tipo: String, nombre: String)] = [
        ("categoria", "Alimentación"), ("categoria", "Transporte"), ("categoria", "Vivienda"),
        ("categoria", "Salud"), ("categoria", "Ocio"), ("categoria", "Educación"), ("categoria", "Otros"),
        ("metodoPago", "Efectivo"), ("metodoPago", "Tarjeta de crédito"),
        ("metodoPago", "Tarjeta de débito"), ("metodoPago", "Transferencia"),
    ]

    func cargar(usuarioId: String) async {
        do {
            let rows: [ParametroRow] = try await supabase
                .from("parametros")
                .select()
                .eq("usuario_id", value: usuarioId)
                .order("id", ascending: true)
                .execute()
                .value
            if rows.isEmpty {
                await sembrar(usuarioId: usuarioId)
                let nuevos: [ParametroRow] = try await supabase
                    .from("parametros")
                    .select()
                    .eq("usuario_id", value: usuarioId)
                    .order("id", ascending: true)
                    .execute()
                    .value
                parametros = nuevos.map(mapear)
            } else {
                parametros = rows.map(mapear)
            }
        } catch {
            print("Error cargando parámetros: \(error)")
        }
    }

    func agregar(usuarioId: String, tipo: String, nombre: String) async -> (ok: Bool, mensaje: String) {
        let limpio = nombre.trimmingCharacters(in: .whitespaces)
        guard !limpio.isEmpty else { return (false, "El nombre no puede estar vacío.") }
        if parametros.contains(where: { $0.tipo == tipo && $0.nombre.lowercased() == limpio.lowercased() }) {
            return (false, "Ese valor ya existe.")
        }
        struct Payload: Encodable {
            let usuario_id: String
            let tipo: String
            let nombre: String
        }
        do {
            let row: ParametroRow = try await supabase
                .from("parametros")
                .insert(Payload(usuario_id: usuarioId, tipo: tipo, nombre: limpio))
                .select()
                .single()
                .execute()
                .value
            parametros.append(mapear(row))
            return (true, "Agregado correctamente.")
        } catch {
            return (false, "No se pudo agregar.")
        }
    }

    func actualizar(id: Int, nombre: String) async -> (ok: Bool, mensaje: String) {
        let limpio = nombre.trimmingCharacters(in: .whitespaces)
        guard !limpio.isEmpty else { return (false, "El nombre no puede estar vacío.") }
        guard let actual = parametros.first(where: { $0.id == id }) else { return (false, "No encontrado.") }
        if parametros.contains(where: { $0.id != id && $0.tipo == actual.tipo && $0.nombre.lowercased() == limpio.lowercased() }) {
            return (false, "Ese valor ya existe.")
        }
        do {
            try await supabase
                .from("parametros")
                .update(["nombre": limpio])
                .eq("id", value: id)
                .execute()
            if let index = parametros.firstIndex(where: { $0.id == id }) {
                parametros[index].nombre = limpio
            }
            return (true, "Actualizado correctamente.")
        } catch {
            return (false, "No se pudo actualizar.")
        }
    }

    func eliminar(id: Int) async {
        do {
            try await supabase.from("parametros").delete().eq("id", value: id).execute()
            parametros.removeAll { $0.id == id }
        } catch {
            print("Error eliminando parámetro: \(error)")
        }
    }

    func nombresPorTipo(_ tipo: String) -> [String] {
        parametros.filter { $0.tipo == tipo }.map { $0.nombre }
    }

    private func sembrar(usuarioId: String) async {
        struct Insert: Encodable {
            let usuario_id: String
            let tipo: String
            let nombre: String
        }
        let filas = valoresPorDefecto.map { Insert(usuario_id: usuarioId, tipo: $0.tipo, nombre: $0.nombre) }
        try? await supabase.from("parametros").insert(filas).execute()
    }

    private func mapear(_ r: ParametroRow) -> Parametro {
        Parametro(id: r.id, usuarioId: r.usuario_id, tipo: r.tipo, nombre: r.nombre)
    }
}