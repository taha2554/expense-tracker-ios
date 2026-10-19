import Foundation

/// The minimal shape the calculations need. The app's SwiftData model conforms to this,
/// which keeps the logic testable without a database.
public protocol ExpenseLike {
    var amount: Decimal { get }
    var date: Date { get }
    var category: ExpenseCategory { get }
    var note: String { get }
}

public struct CategoryTotal: Equatable, Identifiable, Sendable {
    public let category: ExpenseCategory
    public let total: Decimal
    public let share: Double
    public var id: ExpenseCategory { category }
}

public struct DayGroup<E: ExpenseLike>: Identifiable {
    public let day: Date
    public let items: [E]
    public var id: Date { day }
    public var total: Decimal { items.reduce(Decimal.zero) { $0 + $1.amount } }
}

public struct MonthSummary: Equatable, Sendable {
    public let month: DateInterval
    public let total: Decimal
    public let byCategory: [CategoryTotal]
    public let dailyAverage: Decimal
    /// nil when no budget is set
    public let budgetUsed: Double?
    /// Spending projected to the end of the month at the current pace.
    public let projected: Decimal
}

public enum ExpenseMath {
    public static func monthInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)!
    }

    public static func summary<E: ExpenseLike>(
        _ expenses: [E],
        month date: Date,
        budget: Decimal?,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> MonthSummary {
        let month = monthInterval(containing: date, calendar: calendar)
        let inMonth = expenses.filter { month.contains($0.date) && $0.date < month.end }
        let total = inMonth.reduce(Decimal.zero) { $0 + $1.amount }

        var totals: [ExpenseCategory: Decimal] = [:]
        for expense in inMonth {
            totals[expense.category, default: 0] += expense.amount
        }
        var byCategory: [CategoryTotal] = []
        for (category, value) in totals {
            let share: Double = total > 0 ? (value / total).doubleValue : 0
            byCategory.append(CategoryTotal(category: category, total: value, share: share))
        }
        byCategory.sort { (a: CategoryTotal, b: CategoryTotal) -> Bool in
            if a.total == b.total { return a.category.rawValue < b.category.rawValue }
            return a.total > b.total
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: month.start)!.count
        // For the current month only the days so far count; past months use all days.
        let daysElapsed: Int
        if month.contains(today) {
            daysElapsed = calendar.component(.day, from: today)
        } else if today < month.start {
            daysElapsed = 0
        } else {
            daysElapsed = daysInMonth
        }

        let dailyAverage = daysElapsed > 0 ? (total / Decimal(daysElapsed)).rounded(2) : 0
        let projected = daysElapsed > 0 ? (dailyAverage * Decimal(daysInMonth)).rounded(2) : total

        var budgetUsed: Double?
        if let budget, budget > 0 {
            budgetUsed = (total / budget).doubleValue
        }

        return MonthSummary(
            month: month,
            total: total,
            byCategory: byCategory,
            dailyAverage: dailyAverage,
            budgetUsed: budgetUsed,
            projected: projected
        )
    }

    /// Groups expenses by calendar day, newest day first – used for the list sections.
    public static func groupedByDay<E: ExpenseLike>(_ expenses: [E], calendar: Calendar = .current) -> [DayGroup<E>] {
        Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
            .map { DayGroup(day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    /// Parses user input like "12,50" or "12.50" or "1.234,56".
    public static func parseAmount(_ text: String, locale: Locale = .current) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        if let number = formatter.number(from: trimmed) as? NSDecimalNumber {
            let value = number.decimalValue
            return value > 0 ? value.rounded(2) : nil
        }
        // Fallback: accept either separator as the decimal point
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")), value > 0 else {
            return nil
        }
        return value.rounded(2)
    }
}

public enum CSVExporter {
    public static func csv<E: ExpenseLike>(_ expenses: [E], timeZone: TimeZone = .current) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = timeZone
        var lines = ["date,category,amount,note"]
        for e in expenses.sorted(by: { $0.date < $1.date }) {
            lines.append([formatter.string(from: e.date), e.category.rawValue, "\(e.amount)", escape(e.note)].joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

extension Decimal {
    func rounded(_ scale: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .bankers)
        return result
    }

    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
