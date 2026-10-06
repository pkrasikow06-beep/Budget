import Foundation

/// Farben für Kategorien (iOS-Systemfarben).
enum CategoryColor: String, Codable, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray
    var id: String { rawValue }
}

/// Eine Kategorie (z. B. Essen) mit Monatsziel.
struct SpendCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var symbol: String
    var colorName: CategoryColor
    var monthlyGoal: Double
}

/// Eine einzelne Ausgabe.
struct Expense: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var categoryID: UUID?
    var date: Date
    /// Wurde der Betrag beim Eintragen vom Kontostand abgezogen?
    var deducted: Bool
}

/// Alle gespeicherten Daten der App.
struct AppData: Codable {
    var balance: Double
    var balanceSet: Bool
    var autoDeduct: Bool
    var categories: [SpendCategory]
    var expenses: [Expense]

    static let initial = AppData(
        balance: 0,
        balanceSet: false,
        autoDeduct: true,
        categories: [
            SpendCategory(name: "Essen & Lebensmittel", symbol: "fork.knife", colorName: .orange, monthlyGoal: 200),
            SpendCategory(name: "Freizeit & Ausgehen", symbol: "party.popper.fill", colorName: .purple, monthlyGoal: 100),
            SpendCategory(name: "Shopping & Kleidung", symbol: "bag.fill", colorName: .pink, monthlyGoal: 80),
            SpendCategory(name: "Transport & Abos", symbol: "tram.fill", colorName: .blue, monthlyGoal: 60),
            SpendCategory(name: "Sonstiges", symbol: "shippingbox.fill", colorName: .gray, monthlyGoal: 50)
        ],
        expenses: []
    )
}

/// Hält alle Daten, speichert sie automatisch als JSON-Datei auf dem iPhone.
final class ExpenseStore: ObservableObject {
    @Published private(set) var data: AppData {
        didSet { save() }
    }

    init() {
        if let loaded = ExpenseStore.loadFromDisk() {
            data = loaded
        } else {
            data = AppData.initial
        }
    }

    // MARK: Ausgaben

    func addExpense(title: String, amount: Double, categoryID: UUID?, date: Date) {
        var d = data
        let deduct = d.autoDeduct && d.balanceSet
        d.expenses.append(Expense(title: title, amount: amount, categoryID: categoryID, date: date, deducted: deduct))
        if deduct { d.balance -= amount }
        data = d
    }

    func updateExpense(_ expense: Expense, title: String, amount: Double, categoryID: UUID?, date: Date) {
        var d = data
        guard let index = d.expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        let old = d.expenses[index]
        if old.deducted { d.balance += old.amount - amount }
        d.expenses[index].title = title
        d.expenses[index].amount = amount
        d.expenses[index].categoryID = categoryID
        d.expenses[index].date = date
        data = d
    }

    func deleteExpense(_ expense: Expense) {
        var d = data
        guard let index = d.expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        let old = d.expenses[index]
        if old.deducted { d.balance += old.amount }
        d.expenses.remove(at: index)
        data = d
    }

    // MARK: Kontostand & Einstellungen

    func setBalance(_ value: Double) {
        var d = data
        d.balance = value
        d.balanceSet = true
        data = d
    }

    func setAutoDeduct(_ value: Bool) {
        var d = data
        d.autoDeduct = value
        data = d
    }

    // MARK: Kategorien

    func saveCategory(_ category: SpendCategory) {
        var d = data
        if let index = d.categories.firstIndex(where: { $0.id == category.id }) {
            d.categories[index] = category
        } else {
            d.categories.append(category)
        }
        data = d
    }

    func deleteCategory(_ id: UUID) {
        var d = data
        d.categories.removeAll { $0.id == id }
        for i in d.expenses.indices where d.expenses[i].categoryID == id {
            d.expenses[i].categoryID = nil
        }
        data = d
    }

    func deleteCategories(at offsets: IndexSet) {
        let ids = offsets.map { data.categories[$0].id }
        for id in ids { deleteCategory(id) }
    }

    // MARK: Auswertungen

    func category(for id: UUID?) -> SpendCategory? {
        guard let id else { return nil }
        return data.categories.first { $0.id == id }
    }

    func expenses(inMonthOf month: Date) -> [Expense] {
        data.expenses.filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    func spent(categoryID: UUID?, inMonthOf month: Date) -> Double {
        expenses(inMonthOf: month)
            .filter { $0.categoryID == categoryID }
            .reduce(0) { $0 + $1.amount }
    }

    func totalSpent(inMonthOf month: Date) -> Double {
        expenses(inMonthOf: month).reduce(0) { $0 + $1.amount }
    }

    var totalGoal: Double {
        data.categories.reduce(0) { $0 + $1.monthlyGoal }
    }

    /// Zuletzt verwendete Kategorie für einen Artikelnamen (für automatische Vorauswahl).
    func lastCategoryID(forTitle title: String) -> UUID? {
        let key = title.trimmingCharacters(in: .whitespaces).lowercased()
        guard !key.isEmpty else { return nil }
        return data.expenses
            .filter { $0.title.lowercased() == key }
            .max { $0.date < $1.date }?
            .categoryID
    }

    func csvExport() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        var lines = ["Datum;Was;Kategorie;Betrag (EUR)"]
        for e in data.expenses.sorted(by: { $0.date > $1.date }) {
            let cat = category(for: e.categoryID)?.name ?? "Ohne Kategorie"
            let title = e.title.replacingOccurrences(of: ";", with: ",")
            lines.append("\(formatter.string(from: e.date));\(title);\(cat);\(formatInput(e.amount))")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Speichern & Laden

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("budget-daten.json")
    }

    private static func loadFromDisk() -> AppData? {
        guard let raw = try? Data(contentsOf: fileURL) else { return nil }
        if let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            return decoded
        }
        // Datei beschädigt: Sicherheitskopie anlegen, damit nichts verloren geht.
        let backup = fileURL.deletingLastPathComponent().appendingPathComponent("budget-backup-\(Int(Date().timeIntervalSince1970)).json")
        try? raw.write(to: backup)
        return nil
    }

    private func save() {
        do {
            let raw = try JSONEncoder().encode(data)
            try raw.write(to: ExpenseStore.fileURL, options: .atomic)
        } catch {
            print("Speichern fehlgeschlagen: \(error)")
        }
    }
}
