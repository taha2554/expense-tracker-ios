import ExpenseCore
import Foundation
import SwiftData

@Model
final class Expense {
    var amount: Decimal
    var date: Date
    var categoryRaw: String
    var note: String
    var createdAt: Date

    init(amount: Decimal, date: Date = .now, category: ExpenseCategory, note: String = "") {
        self.amount = amount
        self.date = date
        self.categoryRaw = category.rawValue
        self.note = note
        self.createdAt = .now
    }
}

// The category is stored as its raw string so adding a new case later never breaks old data.
extension Expense: ExpenseLike {
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

extension Expense {
    @MainActor
    static func insertSampleData(into context: ModelContext) {
        let calendar = Calendar.current
        let samples: [(Int, String, ExpenseCategory, String)] = [
            (0, "185.50", .food, "Groceries"),
            (0, "42", .transport, "Metro card top-up"),
            (1, "320", .bills, "Internet"),
            (2, "95", .entertainment, "Cinema"),
            (3, "64.90", .food, "Lunch with team"),
            (5, "450", .shopping, "Running shoes (on sale)"),
            (6, "120", .health, "Pharmacy"),
        ]
        for (daysAgo, amount, category, note) in samples {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            context.insert(Expense(amount: Decimal(string: amount)!, date: date, category: category, note: note))
        }
    }
}
