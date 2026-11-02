import Foundation
import Combine

struct Moneda: Identifiable, Hashable {
    let codigo: String
    let simbodo: String
    let nombre: String
    let locale: String
    var id: String { codigo }
}

let MONEDAS: [Moneda] = [
    Moneda(codigo: "COP", simbodo: "$", nombre: "Peso colombiano", locale: "es_CO"),
    Moneda(codigo: "USD", simbodo: "US$", nombre: "Dólar estadounidense", locale: "en_US"),
    Moneda(codigo: "EUR", simbodo: "€", nombre: "Euro", locale: "es_ES"),
]
let MONEDA_BASE = "COP"

@MainActor
final class TasasService: ObservableObject {
    @Published var tasas: [String: Double] = ["COP": 1, "USD": 4000, "EUR": 4300]
    @Published var sonReales = false
    @Published var cargando = false
    @Published var error = ""
    @Published var ultimaActualizacion: Date?
    var origen: String {
        sonReales ? "Tasas actualizadas en línea" : "Tasas de referencia"
    }

    private let url = URL(string: "https://open.er-api.com/v6/latest/USD")!

    func actualizar() async {
        cargando = true
        error = ""
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct Resp: Decodable { let rates: [String: Double]? }
            let resp = try JSONDecoder().decode(Resp.self, from: data)
            if let rates = resp.rates, let cop = rates["COP"], let eur = rates["EUR"] {
                tasas = ["COP": 1, "USD": cop, "EUR": eur * cop]
                sonReales = true
                ultimaActualizacion = Date()
            } else {
                usarFallback()
            }
        } catch {
            usarFallback()
            self.error = "No se pudieron obtener tasas en línea. Usando referencia."
        }
        cargando = false
    }

    private func usarFallback() {
        tasas = ["COP": 1, "USD": 4000, "EUR": 4300]
        sonReales = false
    }
}

@MainActor
final class MonedasService: ObservableObject {
    @Published var codigo: String
    let tasasService: TasasService
    private let storageKey = "gastos:moneda"

    init(tasasService: TasasService) {
        self.tasasService = tasasService
        self.codigo = UserDefaults.standard.string(forKey: storageKey) ?? "COP"
        if !MONEDAS.contains(where: { $0.codigo == codigo }) { self.codigo = "COP" }
    }

    var moneda: Moneda { MONEDAS.first { $0.codigo == codigo } ?? MONEDAS[0] }
    var disponibles: [Moneda] { MONEDAS }

    func setMoneda(_ codigo: String) {
        if MONEDAS.contains(where: { $0.codigo == codigo }) {
            self.codigo = codigo
            UserDefaults.standard.set(codigo, forKey: storageKey)
        }
    }

    func aCOP(_ monto: Double, desde codigoOrigen: String) -> Double {
        let tasa = tasasService.tasas[codigoOrigen] ?? 1
        return monto * tasa
    }
    func desdeCOP(_ montoCOP: Double, hacia codigoDestino: String) -> Double {
        let tasa = tasasService.tasas[codigoDestino] ?? 1
        return montoCOP / tasa
    }
    func convertir(_ monto: Double, desde: String, hacia: String) -> Double {
        desdeCOP(aCOP(monto, desde: desde), hacia: hacia)
    }

    func formatearDesdeCOP(_ montoCOP: Double) -> String {
        formatear(desdeCOP(montoCOP, hacia: codigo))
    }

    func formatear(_ valor: Double, codigo: String? = nil) -> String {
        let c = codigo ?? self.codigo
        let m = MONEDAS.first { $0.codigo == c } ?? MONEDAS[0]
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = m.codigo
        nf.locale = Locale(identifier: m.locale)
        nf.minimumFractionDigits = m.codigo == "COP" ? 0 : 2
        nf.maximumFractionDigits = m.codigo == "COP" ? 0 : 2
        return nf.string(from: NSNumber(value: valor)) ?? "\(valor)"
    }
}