import Foundation
import Supabase
import Combine

struct ObligacionRow: Codable {
    let id: Int; let usuario_id: String; let nombre: String; let monto: Double
    let dia_pago: Int?; let categoria: String; let activa: Bool
}
struct PagoRow: Codable {
    let id: Int; let usuario_id: String; let obligacion_id: Int; let mes: String
    let gasto_id: Int?; let monto: Double?
}

@MainActor
final class ObligacionesService: ObservableObject {
    @Published var obligaciones: [Obligacion] = []
    @Published var pagos: [PagoObligacion] = []
    @Published var error: String = ""
    let gastosService: GastosService
    let tasasService: TasasService
    let monedasService: MonedasService
    init(gastosService: GastosService, tasasService: TasasService, monedasService: MonedasService) {
        self.gastosService = gastosService
        self.tasasService = tasasService
        self.monedasService = monedasService
    }
    func cargar(usuarioId: String) async {
        do {
            let obs: [ObligacionRow] = try await supabase.from("obligaciones").select()
                .eq("usuario_id", value: usuarioId).order("id", ascending: true).execute().value
            let ps: [PagoRow] = try await supabase.from("pagos_obligaciones").select()
                .eq("usuario_id", value: usuarioId).order("mes", ascending: false).execute().value
            var filas = obs
            if filas.isEmpty {
                await sembrar(usuarioId: usuarioId)
                let nuevos: [ObligacionRow] = try await supabase.from("obligaciones").select()
                    .eq("usuario_id", value: usuarioId).order("id", ascending: true).execute().value
                filas = nuevos
            }
            obligaciones = filas.map(mapear)
            pagos = ps.map(mapearPago)
        } catch { self.error = "Error obligaciones: \(error.localizedDescription)"; print(error) }
    }
    func agregar(_ input: Obligacion) async {
        struct Insert: Encodable {
            let usuario_id: String; let nombre: String; let monto: Double
            let dia_pago: Int?; let categoria: String; let activa: Bool
        }
        do {
            let row: ObligacionRow = try await supabase.from("obligaciones")
                .insert(Insert(usuario_id: input.usuarioId, nombre: input.nombre, monto: input.monto, dia_pago: input.diaPago, categoria: input.categoria, activa: input.activa))
                .select().single().execute().value
            obligaciones.append(mapear(row))
        } catch { self.error = "Error agregar obligacion: \(error.localizedDescription)"; print(error) }
    }
    private func sembrar(usuarioId: String) async {
        struct Insert: Encodable {
            let usuario_id: String; let nombre: String; let monto: Double
            let dia_pago: Int?; let categoria: String; let activa: Bool
        }
        let datos: [(String, Double, Int?, String)] = [
            ("Volleyball",270000,10,"Ocio"),("Mercado",600000,10,"Alimentacion"),
            ("Acueducto",300000,10,"Vivienda"),("Hipoteca (Pago Total)",1000000,10,"Vivienda"),
            ("Gas Vanti",80000,10,"Vivienda"),("Movistar Hogar",70000,10,"Servicios"),
            ("Enel Codensa",220000,10,"Servicios"),("Carro Davivienda",2300000,25,"Transporte"),
            ("Hipoteca",1700000,25,"Vivienda"),("Claro cellular mamá",22000,25,"Servicios"),
            ("TC Bancolombia",200000,25,"Deudas"),("Mercado",600000,25,"Alimentacion"),
            ("Administración",400000,25,"Vivienda"),("Música",20000,nil,"Ocio"),
            ("Gasolina",100000,nil,"Transporte")
        ]
        let filas = datos.map { Insert(usuario_id: usuarioId, nombre: $0.0, monto: $0.1, dia_pago: $0.2, categoria: $0.3, activa: true) }
        try? await supabase.from("obligaciones").insert(filas).execute()
    }
    func estaPagada(obligacionId: Int, mes: String) -> Bool {
        pagos.contains { $0.obligacionId == obligacionId && $0.mes == mes }
    }
    func montoPara(_ obligacion: Obligacion, mes: String) -> Double {
        if let p = pagos.first(where: { $0.obligacionId == obligacion.id && $0.mes == mes }) {
            return p.monto ?? obligacion.monto
        }
        return obligacion.monto
    }
    func montoFormateado(_ obligacion: Obligacion, mes: String) -> String {
        let monto = montoPara(obligacion, mes: mes)
        return monedasService.formatearDesdeCOP(monto)
    }
    func marcarPagada(_ obligacion: Obligacion, mes: String) async {
        guard !estaPagada(obligacionId: obligacion.id, mes: mes) else { return }
        let monto = montoPara(obligacion, mes: mes)
        let dia = obligacion.diaPago ?? 1
        let fecha = "\(mes)-\(String(dia).padding(toLength: 2, withPad: "0", startingAt: 0))"
        do {
            let gastoId = try await gastosService.agregar(Gasto(
                id: 0, usuarioId: obligacion.usuarioId, monto: monto,
                categoria: obligacion.categoria, metodoPago: "Obligacion",
                fecha: fecha, descripcion: obligacion.nombre))
            if let override = pagos.first(where: { $0.obligacionId == obligacion.id && $0.mes == mes && $0.gastoId == nil }) {
                struct Update: Encodable { let gasto_id: Int; let monto: Double }
                try await supabase.from("pagos_obligaciones").update(Update(gasto_id: gastoId, monto: monto)).eq("id", value: override.id).execute()
            } else {
                struct Payload: Encodable {
                    let usuario_id: String; let obligacion_id: Int; let mes: String; let gasto_id: Int; let monto: Double
                }
                let row: PagoRow = try await supabase.from("pagos_obligaciones")
                    .insert(Payload(usuario_id: obligacion.usuarioId, obligacion_id: obligacion.id, mes: mes, gasto_id: gastoId, monto: monto))
                    .select().single().execute().value
                pagos.insert(mapearPago(row), at: 0)
            }
        } catch { self.error = "Error marcarPagada: \(error.localizedDescription)"; print(error) }
    }
    func desmarcar(obligacionId: Int, mes: String) async {
        guard let pago = pagos.first(where: { $0.obligacionId == obligacionId && $0.mes == mes }) else { return }
        do {
            try await supabase.from("pagos_obligaciones").delete().eq("id", value: pago.id).execute()
            if let gastoId = pago.gastoId, gastoId != 0 { try? await gastosService.eliminar(id: gastoId) }
            pagos.removeAll { $0.id == pago.id }
        } catch { self.error = "Error desmarcar: \(error.localizedDescription)"; print(error) }
    }
    func establecerMonto(_ obligacion: Obligacion, mes: String, monto: Double) async {
        self.error = ""
        do {
            if let pago = pagos.first(where: { $0.obligacionId == obligacion.id && $0.mes == mes }) {
                if let gastoId = pago.gastoId, gastoId != 0 {
                    try? await gastosService.actualizar(id: gastoId, cambios: ["monto": monto])
                }
                try await supabase.from("pagos_obligaciones").update(["monto": monto]).eq("id", value: pago.id).execute()
                if let index = pagos.firstIndex(where: { $0.id == pago.id }) { pagos[index].monto = monto }
            } else {
                struct Payload: Encodable {
                    let usuario_id: String; let obligacion_id: Int; let mes: String
                    let gasto_id: Int?; let monto: Double
                }
                let row: PagoRow = try await supabase.from("pagos_obligaciones")
                    .insert(Payload(usuario_id: obligacion.usuarioId, obligacion_id: obligacion.id, mes: mes, gasto_id: nil, monto: monto))
                    .select().single().execute().value
                pagos.insert(mapearPago(row), at: 0)
            }
        } catch { self.error = "Error estableciendo monto: \(error.localizedDescription)"; print(error) }
    }
    func actualizar(id: Int, nombre: String, monto: Double, diaPago: Int?, categoria: String, activa: Bool) async {
        struct Update: Encodable {
            let nombre: String; let monto: Double; let dia_pago: Int?; let categoria: String; let activa: Bool
        }
        do {
            try await supabase.from("obligaciones").update(Update(nombre: nombre, monto: monto, dia_pago: diaPago, categoria: categoria, activa: activa)).eq("id", value: id).execute()
            if let index = obligaciones.firstIndex(where: { $0.id == id }) {
                obligaciones[index].nombre = nombre
                obligaciones[index].monto = monto
                obligaciones[index].diaPago = diaPago
                obligaciones[index].categoria = categoria
                obligaciones[index].activa = activa
            }
        } catch { self.error = "Error actualizar obligacion: \(error.localizedDescription)"; print(error) }
    }
    func eliminar(id: Int) async {
        do {
            try await supabase.from("obligaciones").delete().eq("id", value: id).execute()
            obligaciones.removeAll { $0.id == id }
        } catch { self.error = "Error eliminar obligacion: \(error.localizedDescription)"; print(error) }
    }
    var porGrupo: (dia10: [Obligacion], dia25: [Obligacion], hormigas: [Obligacion]) {
        let activas = obligaciones.filter { $0.activa }
        return (activas.filter { $0.diaPago == 10 }, activas.filter { $0.diaPago == 25 }, activas.filter { $0.diaPago == nil })
    }
    func totalPagadoMes(_ mes: String) -> Double {
        pagos.filter { $0.mes == mes && $0.gastoId != nil }.reduce(0) { sum, p in
            let o = obligaciones.first { $0.id == p.obligacionId }
            return sum + (p.monto ?? (o?.monto ?? 0))
        }
    }
    var totalEsperadoMes: Double { obligaciones.filter { $0.activa }.reduce(0) { $0 + $1.monto } }
    private func mapear(_ r: ObligacionRow) -> Obligacion {
        Obligacion(id: r.id, usuarioId: r.usuario_id, nombre: r.nombre, monto: r.monto, diaPago: r.dia_pago, categoria: r.categoria, activa: r.activa)
    }
    private func mapearPago(_ r: PagoRow) -> PagoObligacion {
        PagoObligacion(id: r.id, usuarioId: r.usuario_id, obligacionId: r.obligacion_id, mes: r.mes, gastoId: r.gasto_id, monto: r.monto)
    }
}
