import ExpenseCore
import SwiftData
import SwiftUI

/// Used for both adding (expense == nil) and editing.
struct ExpenseFormView: View {
    let expense: Expense?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var date = Date.now
    @State private var note = ""
    @FocusState private var amountFocused: Bool

    private var amount: Decimal? { ExpenseMath.parseAmount(amountText) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .focused($amountFocused)
                    if !amountText.isEmpty && amount == nil {
                        Text("Enter a positive amount").font(.caption).foregroundStyle(.red)
                    }
                } header: {
                    Text("Amount (\(Money.currencyCode))")
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { c in
                            Label(c.title, systemImage: c.symbol).tag(c)
                        }
                    }
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let expense {
                    Section {
                        Button("Delete expense", role: .destructive) {
                            context.delete(expense)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(expense == nil ? "New expense" : "Edit expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(amount == nil)
                }
            }
            .onAppear(perform: load)
        }
        .presentationDetents([.medium, .large])
    }

    private func load() {
        guard let expense else {
            amountFocused = true
            return
        }
        amountText = expense.amount.formatted(.number.precision(.fractionLength(0...2)))
        category = expense.category
        date = expense.date
        note = expense.note
    }

    private func save() {
        guard let amount else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let expense {
            expense.amount = amount
            expense.category = category
            expense.date = date
            expense.note = trimmedNote
        } else {
            context.insert(Expense(amount: amount, date: date, category: category, note: trimmedNote))
        }
        dismiss()
    }
}
