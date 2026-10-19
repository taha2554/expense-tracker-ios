import Foundation

public enum ExpenseCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case food
    case transport
    case shopping
    case bills
    case health
    case entertainment
    case other

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .food: "Food & drinks"
        case .transport: "Transport"
        case .shopping: "Shopping"
        case .bills: "Bills"
        case .health: "Health"
        case .entertainment: "Fun"
        case .other: "Other"
        }
    }

    /// SF Symbol name used in the UI.
    public var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "bus"
        case .shopping: "bag"
        case .bills: "doc.text"
        case .health: "cross.case"
        case .entertainment: "gamecontroller"
        case .other: "square.grid.2x2"
        }
    }
}
