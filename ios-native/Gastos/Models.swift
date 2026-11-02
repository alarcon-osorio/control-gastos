import Foundation

struct Usuario: Identifiable, Codable {
    let id: String
    var nombre: String
    var email: String
    var fechaRegistro: String?
}

struct Gasto: Identifiable, Codable {
    let id: Int
    var usuarioId: String
    var monto: Double
    var categoria: String
    var metodoPago: String
    var fecha: String
    var descripcion: String
}

import SwiftUI
import Foundation
import Combine

struct Obligacion: Identifiable, Codable {
    let id: Int
    var usuarioId: String
    var nombre: String
    var monto: Double
    var diaPago: Int?
    var categoria: String
    var activa: Bool
}

struct Parametro: Identifiable, Codable {
    let id: Int
    var usuarioId: String
    var tipo: String
    var nombre: String
}
struct PagoObligacion: Identifiable, Codable {
    let id: Int
    var usuarioId: String
    var obligacionId: Int
    var mes: String
    var gastoId: Int?
    var monto: Double?
}