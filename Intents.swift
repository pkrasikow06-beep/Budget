import AppIntents

/// "Ausgabe eintragen" – kann in den iPhone-Einstellungen auf die Aktionstaste gelegt werden.
struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Ausgabe eintragen"
    static var description = IntentDescription("Öffnet Budget und fragt, was du gekauft hast und wie viel es gekostet hat.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.showAddExpense = true
        return .result()
    }
}

/// Macht die Aktion automatisch in der Kurzbefehle-App und für die Aktionstaste verfügbar.
struct BudgetShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Ausgabe in \(.applicationName) eintragen",
                "Kauf in \(.applicationName) eintragen",
                "\(.applicationName) Ausgabe"
            ],
            shortTitle: "Ausgabe eintragen",
            systemImageName: "plus.circle.fill"
        )
    }
}
