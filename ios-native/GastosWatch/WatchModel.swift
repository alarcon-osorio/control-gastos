import Foundation
import Combine

@MainActor
final class WatchModel: ObservableObject {
    let gastosService = GastosService()
    let tasasService = TasasService()
    let monedasService: MonedasService
    let obligacionesService: ObligacionesService
    let parametrosService = ParametrosService()

    @Published var cargando = false
    @Published var error = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        let monedas = MonedasService(tasasService: tasasService)
        self.monedasService = monedas
        self.obligacionesService = ObligacionesService(
            gastosService: gastosService,
            tasasService: tasasService,
            monedasService: monedas
        )

        gastosService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        obligacionesService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        parametrosService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        monedasService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func cargar(usuarioId: String) async {
        cargando = true
        error = ""
        obligacionesService.error = ""
        await obligacionesService.cargar(usuarioId: usuarioId)
        await parametrosService.cargar(usuarioId: usuarioId)
        if !obligacionesService.error.isEmpty {
            error = obligacionesService.error
        }
        cargando = false
    }

    func cargarParametros(usuarioId: String) async {
        guard parametrosService.parametros.isEmpty else { return }
        await parametrosService.cargar(usuarioId: usuarioId)
    }
}

enum WatchFecha {
    static func mesActual() -> String {
        let ahora = Date()
        let anio = Calendar.current.component(.year, from: ahora)
        let mes = Calendar.current.component(.month, from: ahora)
        return String(format: "%04d-%02d", anio, mes)
    }

    static func hoy() -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    static func nombreMes(_ mes: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "yyyy-MM"
        guard let fecha = f.date(from: mes) else { return mes }
        let salida = DateFormatter()
        salida.locale = Locale(identifier: "es_ES")
        salida.dateFormat = "MMMM yyyy"
        return salida.string(from: fecha).capitalized
    }

    static func cambiarMes(_ mes: String, delta: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "yyyy-MM"
        guard let fecha = f.date(from: mes),
              let nueva = Calendar.current.date(byAdding: .month, value: delta, to: fecha) else {
            return mes
        }
        let anio = Calendar.current.component(.year, from: nueva)
        let numeroMes = Calendar.current.component(.month, from: nueva)
        return String(format: "%04d-%02d", anio, numeroMes)
    }
}
