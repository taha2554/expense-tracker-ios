import ExpenseCore
import SwiftData
import SwiftUI

struct ExpenseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var editing: Expense?
    @State private var showingAdd = false
    @State private var search = ""
    @State private var categoryFilter: ExpenseCategory?

    private var filtered: [Expense] {
        expenses.filter { expense in
            (categoryFilter == nil || expense.category == categoryFilter)
                && (search.isEmpty || expense.note.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(ExpenseMath.groupedByDay(filtered)) { group in
                    Section {
                        ForEach(group.items) { expense in
                            Button { editing = expense } label: { ExpenseRow(expense: expense) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            offsets.map { group.items[$0] }.forEach(context.delete)
                        }
                    } header: {
                        HStack {
                            Text(group.day, format: .dateTime.weekday(.wide).day().month())
                            Spacer()
                            Text(Money.format(group.total))
                        }
                    }
                }
            }
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView {
                        Label("No expenses yet", systemImage: "creditcard")
                    } description: {
                        Text("Tap + to add your first one.")
                    } actions: {
                        Button("Add sample data") { Expense.insertSampleData(into: context) }
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .searchable(text: $search, prompt: "Search notes")
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Category", selection: $categoryFilter) {
                            Text("All categories").tag(ExpenseCategory?.none)
                            ForEach(ExpenseCategory.allCases) { c in
                                Label(c.title, systemImage: c.symbol).tag(ExpenseCategory?.some(c))
                            }
                        }
                    } label: {
                        Image(systemName: categoryFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel("Filter by category")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add expense")
                }
            }
            .sheet(isPresented: $showingAdd) { ExpenseFormView(expense: nil) }
            .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.symbol)
                .frame(width: 36, height: 36)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.note.isEmpty ? expense.category.title : expense.note)
                    .lineLimit(1)
                Text(expense.category.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Money.format(expense.amount))
                .monospacedDigit()
                .fontWeight(.medium)
        }
        .contentShape(Rectangle())
    }
}
