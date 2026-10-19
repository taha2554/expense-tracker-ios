import SwiftData
import SwiftUI

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Expense.self)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ExpenseListView()
                .tabItem { Label("Expenses", systemImage: "list.bullet") }
            SummaryView()
                .tabItem { Label("Summary", systemImage: "chart.pie") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Expense.self, inMemory: true)
}
