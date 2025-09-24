import Foundation

/// Canonical categories for organizing receipts across dashboards and AI prompts.
enum ReceiptCategory: String, CaseIterable, Codable, Identifiable {
    case housing
    case utilities
    case groceries
    case dining
    case health
    case transportation
    case entertainment
    case education
    case insurance
    case debt
    case savings
    case travel
    case other

    var id: String { rawValue }

    /// Human readable title for dashboards and forms.
    var title: String {
        switch self {
        case .housing: return "Arriendo / Hipoteca"
        case .utilities: return "Servicios básicos"
        case .groceries: return "Supermercado"
        case .dining: return "Comida preparada"
        case .health: return "Salud"
        case .transportation: return "Transporte"
        case .entertainment: return "Ocio"
        case .education: return "Educación"
        case .insurance: return "Seguros"
        case .debt: return "Deudas"
        case .savings: return "Ahorro"
        case .travel: return "Viajes"
        case .other: return "Otros"
        }
    }

    /// Suggested SF Symbol names per category to deliver a consistent iconography.
    var systemImageName: String {
        switch self {
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .groceries: return "cart.fill"
        case .dining: return "fork.knife"
        case .health: return "cross.case.fill"
        case .transportation: return "car.fill"
        case .entertainment: return "theatermasks.fill"
        case .education: return "book.fill"
        case .insurance: return "shield.lefthalf.fill"
        case .debt: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .travel: return "airplane"
        case .other: return "tray.full"
        }
    }
}
