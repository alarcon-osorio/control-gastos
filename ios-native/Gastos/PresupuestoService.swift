import Foundation
import Supabase
import Combine

@MainActor
final class PresupuestoService: ObservableObject {
    @Published var presupuesto: Double = 0
    @Published var error: String = ""
    private let auth: AuthService
    private let gastosService: GastosService
    private let mes: String
    private var mesActual: String { mes }

    init(auth: AuthService, gastosService: GastosService, mes: String? = nil) {
        self.auth = auth
        self.gastosService = gastosService
        if let mes { self.mes = mes } else {
            let now = Date()
            let y = Calendar.current.component(.year, from: now)
            let m = Calendar.current.component(.month, from: now)
            self.mes = String(format: "%04d-%02d", y, m)
        }
        Task { await auth.restaurarSesion() }
    }

    func cargar() async {
        guard let usuario = auth.usuario else { presupuesto = 0; return }
        do {
            struct Row: Decodable { let monto: Double }
            let row: Row? = try await supabase.from("presupuestos")
                .select("monto").eq("usuario_id", value: usuario.id).eq("mes", value: mes).maybeSingle().execute().value
            if let monto = row?.monto {
                presupuesto = monto
                return
            }
        } catch {}
        // respaldo localStorage
        if let s = UserDefaults.standard.string(forKey: "gastos:presupuesto:\(usuario.id)"), let v = Double(s) {
            presupuesto = v
        } else {
            presupuesto = 0
        }
    }

    func setPresupuesto(_ monto: Double) {
        let valido = monto.isFinite && monto >= 0 ? monto : 0
        presupuesto = valido
        if let usuario = auth.usuario {
            UserDefaults.standard.set(String(valido), forKey: "gastos:presupuesto:\(usuario.id)")
            Task { await persistirRemoto(usuarioId: usuario.id, monto: valido) }
        }
    }

    func guardar(_ monto: Double) async {
        let valido = monto.isFinite && monto >= 0 ? monto : 0
        presupuesto = valido
        error = ""
        if let usuario = auth.usuario {
            UserDefaults.standard.set(String(valido), forKey: "gastos:presupuesto:\(usuario.id)")
            await persistirRemoto(usuarioId: usuario.id, monto: valido)
        }
    }

    private func persistirRemoto(usuarioId: String, monto: Double) async {
        do {
            struct Row: Decodable { let monto: Double? }
            let existing: [Row] = try await supabase.from("presupuestos")
                .select("monto")
                .eq("usuario_id", value: usuarioId)
                .eq("mes", value: mes)
                .execute()
                .value
            if !existing.isEmpty {
                struct Update: Encodable {
                    let monto: Double
                    let actualizado_en: String
                }
                try await supabase.from("presupuestos").update(Update(monto: monto, actualizado_en: ISO8601DateFormatter().string(from: Date())))
                    .eq("usuario_id", value: usuarioId)
                    .eq("mes", value: mes)
                    .execute()
            } else {
                struct Insert: Encodable {
                    let usuario_id: String
                    let mes: String
                    let monto: Double
                    let actualizado_en: String
                }
                try await supabase.from("presupuestos").insert(Insert(
                    usuario_id: usuarioId,
                    mes: mes,
                    monto: monto,
                    actualizado_en: ISO8601DateFormatter().string(from: Date())
                )).execute()
            }
        } catch {
            self.error = "Error guardando presupuesto: \(error.localizedDescription)"
            print(error)
        }
    }

    var gastoDelMes: Double {
        guard let usuario = auth.usuario else { return 0 }
        return gastosService.gastosPorUsuario(usuario.id)
            .filter { $0.fecha.prefix(7) == mesActual }
            .reduce(0) { $0 + $1.monto }
    }

    var porcentaje: Int {
        presupuesto > 0 ? Int((gastoDelMes / presupuesto * 100).rounded()) : 0
    }

    var restante: Double { max(0, presupuesto - gastoDelMes) }

    var estado: String {
        if presupuesto <= 0 { return "sin-presupuesto" }
        if porcentaje >= 100 { return "excedido" }
        if porcentaje >= 80 { return "cerca" }
        return "ok"
    }
}