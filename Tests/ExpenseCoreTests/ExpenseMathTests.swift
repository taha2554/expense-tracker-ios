import ExpenseCore
import XCTest

private struct Item: ExpenseLike {
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var note: String = ""
}

final class ExpenseMathTests: XCTestCase {
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func testSummaryTotalsAndCategoryShares() {
        let items = [
            Item(amount: 100, date: date(2026, 4, 2), category: .food),
            Item(amount: 50, date: date(2026, 4, 3), category: .transport),
            Item(amount: 50, date: date(2026, 4, 10), category: .food),
            Item(amount: 999, date: date(2026, 3, 31), category: .bills), // previous month
        ]
        let s = ExpenseMath.summary(items, month: date(2026, 4, 15), budget: 300, today: date(2026, 4, 10), calendar: calendar)

        XCTAssertEqual(s.total, 200)
        XCTAssertEqual(s.byCategory.map(\.category), [.food, .transport])
        XCTAssertEqual(s.byCategory[0].share, 0.75, accuracy: 0.0001)
        XCTAssertEqual(s.budgetUsed!, 2.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(s.dailyAverage, 20) // 200 over 10 days so far
        XCTAssertEqual(s.projected, 600) // April has 30 days
    }

    func testPastMonthUsesAllDays() {
        let items = [Item(amount: 310, date: date(2026, 1, 5), category: .other)]
        let s = ExpenseMath.summary(items, month: date(2026, 1, 1), budget: nil, today: date(2026, 3, 1), calendar: calendar)
        XCTAssertEqual(s.dailyAverage, 10)
        XCTAssertNil(s.budgetUsed)
    }

    func testExpenseAtMidnightBelongsToNewMonth() {
        let items = [Item(amount: 10, date: date(2026, 5, 1, 0), category: .food)]
        let april = ExpenseMath.summary(items, month: date(2026, 4, 20), budget: nil, today: date(2026, 5, 2), calendar: calendar)
        let may = ExpenseMath.summary(items, month: date(2026, 5, 20), budget: nil, today: date(2026, 5, 2), calendar: calendar)
        XCTAssertEqual(april.total, 0)
        XCTAssertEqual(may.total, 10)
    }

    func testGroupedByDayNewestFirst() {
        let items = [
            Item(amount: 1, date: date(2026, 4, 1, 9), category: .food),
            Item(amount: 2, date: date(2026, 4, 2, 9), category: .food),
            Item(amount: 3, date: date(2026, 4, 1, 18), category: .food),
        ]
        let groups = ExpenseMath.groupedByDay(items, calendar: calendar)
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].items.map(\.amount), [2])
        XCTAssertEqual(groups[1].items.map(\.amount), [3, 1])
        XCTAssertEqual(groups[1].total, 4)
    }

    func testParseAmount() {
        let tr = Locale(identifier: "tr_TR")
        XCTAssertEqual(ExpenseMath.parseAmount("12,50", locale: tr), Decimal(string: "12.5"))
        XCTAssertEqual(ExpenseMath.parseAmount("1.234,56", locale: tr), Decimal(string: "1234.56"))
        XCTAssertEqual(ExpenseMath.parseAmount("12.50", locale: Locale(identifier: "en_US")), Decimal(string: "12.5"))
        XCTAssertNil(ExpenseMath.parseAmount("", locale: tr))
        XCTAssertNil(ExpenseMath.parseAmount("abc", locale: tr))
        XCTAssertNil(ExpenseMath.parseAmount("-5", locale: tr))
    }

    func testCSVEscapesNotes() {
        let items = [Item(amount: Decimal(string: "12.5")!, date: date(2026, 4, 2), category: .food, note: "Lunch, with \"Ali\"")]
        let csv = CSVExporter.csv(items, timeZone: calendar.timeZone)
        XCTAssertEqual(csv, "date,category,amount,note\n2026-04-02,food,12.5,\"Lunch, with \"\"Ali\"\"\"\n")
    }
}
