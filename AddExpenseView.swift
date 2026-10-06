import SwiftUI
import UIKit

/// Fenster "Neue Ausgabe" – öffnet sich auch über die Aktionstaste.
struct AddExpenseView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss

    /// Wenn gesetzt, wird eine bestehende Ausgabe bearbeitet.
    var editing: Expense? = nil

    @State private var title = ""
    @State private var amountText = ""
    @State private var categoryID: UUID?
    @State private var date = Date()
    @State private var didLoad = false
    @State private var userPickedCategory = false
    @FocusState private var focus: Field?

    enum Field { case title, amount }

    private var amount: Double? {
        guard let value = parseAmount(amountText), value > 0 else { return nil }
        return value
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && amount != nil
    }

    /// Frühere Einkäufe als Schnellauswahl.
    private var suggestions: [String] {
        guard editing == nil else { return [] }
        let query = trimmedTitle.lowercased()
        var seen = Set<String>()
        var result: [String] = []
        for e in store.data.expenses.sorted(by: { $0.date > $1.date }) {
            let key = e.title.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            if query.isEmpty || (key.hasPrefix(query) && key != query) {
                result.append(e.title)
            }
            if result.count >= 6 { break }
        }
        return result
    }

    /// Was der Kauf für das Monatsziel bedeutet.
    private var impact: (text: String, isWarning: Bool)? {
        guard let amount, let category = store.category(for: categoryID), category.monthlyGoal > 0 else {
            return nil
        }
        var spentBefore = store.spent(categoryID: category.id, inMonthOf: date)
        if let editing,
           editing.categoryID == category.id,
           Calendar.current.isDate(editing.date, equalTo: date, toGranularity: .month) {
            spentBefore -= editing.amount
        }
        let left = category.monthlyGoal - (spentBefore + amount)
        if left >= 0 {
            return ("Danach bleiben dir diesen Monat noch \(left.euro) für \(category.name).", false)
        }
        return ("Damit liegst du \((-left).euro) über deinem Ziel von \(category.monthlyGoal.euro) für \(category.name).", true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Was hast du gekauft?", text: $title)
                        .focused($focus, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focus = .amount }
                        .onChange(of: title) { _, newValue in
                            autoSelectCategory(for: newValue)
                        }
                    HStack {
                        TextField("Betrag", text: $amountText)
                            .keyboardType(.decimalPad)
                            .focused($focus, equals: .amount)
                        Text("€")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        title = suggestion
                                        focus = .amount
                                    }
                                    .font(.subheadline)
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }

                Section {
                    ForEach(store.data.categories) { category in
                        Button {
                            categoryID = categoryID == category.id ? nil : category.id
                            userPickedCategory = true
                        } label: {
                            HStack(spacing: 12) {
                                CategoryIcon(symbol: category.symbol, color: category.color)
                                Text(category.name)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if categoryID == category.id {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                } header: {
                    Text("Kategorie")
                } footer: {
                    if let impact {
                        Text(impact.text)
                            .foregroundStyle(impact.isWarning ? Color.red : Color.secondary)
                    }
                }

                Section {
                    DatePicker("Datum", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                if let editing {
                    Section {
                        Button("Ausgabe löschen", role: .destructive) {
                            store.deleteExpense(editing)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(editing == nil ? "Neue Ausgabe" : "Ausgabe bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Hinzufügen" : "Fertig", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func autoSelectCategory(for newTitle: String) {
        guard editing == nil, !userPickedCategory else { return }
        if let id = store.lastCategoryID(forTitle: newTitle), store.category(for: id) != nil {
            categoryID = id
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let editing {
            title = editing.title
            amountText = formatInput(editing.amount)
            categoryID = editing.categoryID
            date = editing.date
            userPickedCategory = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                focus = .title
            }
        }
    }

    private func save() {
        guard let amount, !trimmedTitle.isEmpty else { return }
        if let editing {
            store.updateExpense(editing, title: trimmedTitle, amount: amount, categoryID: categoryID, date: date)
        } else {
            store.addExpense(title: trimmedTitle, amount: amount, categoryID: categoryID, date: date)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
