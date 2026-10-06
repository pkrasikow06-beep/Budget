import SwiftUI

@main
struct BudgetApp: App {
    @StateObject private var store = ExpenseStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

/// Steuert, ob das Fenster "Neue Ausgabe" offen ist
/// (wird auch von der Aktionstaste / dem Kurzbefehl benutzt).
final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    @Published var showAddExpense = false
}

struct ContentView: View {
    @EnvironmentObject var store: ExpenseStore
    @ObservedObject private var router = AppRouter.shared

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Übersicht", systemImage: "chart.pie.fill") }
            HistoryView()
                .tabItem { Label("Verlauf", systemImage: "list.bullet") }
            GoalsView()
                .tabItem { Label("Ziele", systemImage: "target") }
        }
        .sheet(isPresented: $router.showAddExpense) {
            AddExpenseView()
                .environmentObject(store)
        }
        .onOpenURL { url in
            // budget://add öffnet direkt "Neue Ausgabe"
            if url.host == "add" {
                router.showAddExpense = true
            }
        }
    }
}
