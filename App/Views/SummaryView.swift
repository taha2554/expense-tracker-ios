import Charts
import ExpenseCore
import SwiftData
import SwiftUI

struct SummaryView: View {
    @Query private var expenses: [Expense]
    @AppStorage("monthlyBudget") private var budget: Double = 0
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "TRY"
    @State private var month = Date.now
    @State private var editingBudget = false
    @State private var budgetText = ""

    private var summary: MonthSummary {
        ExpenseMath.summary(expenses, month: month, budget: budget > 0 ? Decimal(budget) : nil)
    }

    private var csvFile: CSVFile {
        let interval = ExpenseMath.monthInterval(containing: month)
        return CSVFile(text: CSVExporter.csv(expenses.filter { interval.contains($0.date) }))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    monthPicker
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Money.format(summary.total))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("≈ \(Money.format(summary.dailyAverage)) per day · on track for \(Money.format(summary.projected))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    if let used = summary.budgetUsed {
                        VStack(alignment: .leading) {
                            ProgressView(value: min(used, 1))
                                .tint(used > 1 ? .red : used > 0.8 ? .orange : .green)
                            Text(used > 1
                                 ? "Over budget by \(Money.format(summary.total - Decimal(budget)))"
                                 : "\(Int(used * 100))% of \(Money.format(Decimal(budget))) budget")
                                .font(.footnote)
                                .foregroundStyle(used > 1 ? .red : .secondary)
                        }
                    }
                }

                if summary.byCategory.isEmpty {
                    Section { Text("No expenses this month.").foregroundStyle(.secondary) }
                } else {
                    Section("By category") {
                        Chart(summary.byCategory) { item in
                            SectorMark(angle: .value("Total", item.total.doubleValue), innerRadius: .ratio(0.6), angularInset: 1.5)
                                .foregroundStyle(by: .value("Category", item.category.title))
                                .cornerRadius(4)
                        }
                        .frame(height: 220)
                        .padding(.vertical, 8)

                        ForEach(summary.byCategory) { item in
                            HStack {
                                Label(item.category.title, systemImage: item.category.symbol)
                                Spacer()
                                Text(item.share, format: .percent.precision(.fractionLength(0)))
                                    .foregroundStyle(.secondary)
                                Text(Money.format(item.total))
                                    .monospacedDigit()
                                    .frame(minWidth: 90, alignment: .trailing)
                            }
                        }
                    }
                }

                Section("Settings") {
                    Button {
                        budgetText = budget > 0 ? String(format: "%.0f", budget) : ""
                        editingBudget = true
                    } label: {
                        LabeledContent("Monthly budget", value: budget > 0 ? Money.format(Decimal(budget)) : "Not set")
                    }
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(["TRY", "EUR", "USD", "GBP"], id: \.self) { Text($0) }
                    }
                    ShareLink(item: csvFile, preview: SharePreview("Expenses.csv")) {
                        Label("Export this month as CSV", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Summary")
            .alert("Monthly budget", isPresented: $editingBudget) {
                TextField("Amount", text: $budgetText)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    budget = ExpenseMath.parseAmount(budgetText).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Leave empty to remove the budget.")
            }
        }
    }

    private var monthPicker: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(month, format: .dateTime.month(.wide).year()).font(.headline)
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .disabled(Calendar.current.isDate(month, equalTo: .now, toGranularity: .month))
        }
        .buttonStyle(.borderless)
    }

    private func shiftMonth(_ value: Int) {
        month = Calendar.current.date(byAdding: .month, value: value, to: month) ?? month
    }
}

/// Lets ShareLink hand the CSV to other apps as a real .csv file.
struct CSVFile: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.text.utf8)
        }
        .suggestedFileName("expenses.csv")
    }
}

private extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
