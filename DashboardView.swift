import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var month = Date()
    @State private var showBalanceEditor = false

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month)
    }
    private var spent: Double { store.totalSpent(inMonthOf: month) }
    private var budget: Double { store.totalGoal }
    private var remaining: Double { budget - spent }

    private var daysLeft: Int {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: Date()) else { return 1 }
        let today = cal.component(.day, from: Date())
        return max(range.count - today + 1, 1)
    }

    private var summaryText: String {
        if budget <= 0 {
            return "Lege unter „Ziele“ fest, wie viel du pro Monat ausgeben willst."
        }
        if isCurrentMonth {
            if remaining >= 0 {
                let perDay = remaining / Double(daysLeft)
                let days = daysLeft == 1 ? "heute" : "die restlichen \(daysLeft) Tage"
                return "Noch \(remaining.euro) übrig. Das sind \(perDay.euro) pro Tag für \(days)."
            }
            return "\((-remaining).euro) über deinem Monatsbudget."
        }
        if remaining >= 0 {
            return "\(remaining.euro) unter deinem Budget geblieben."
        }
        return "\((-remaining).euro) über deinem Budget."
    }

    private var segments: [BarSegment] {
        var result = store.data.categories.map { category in
            BarSegment(id: category.id, color: category.color,
                       value: store.spent(categoryID: category.id, inMonthOf: month))
        }
        let uncategorized = store.spent(categoryID: nil, inMonthOf: month)
        if uncategorized > 0 {
            result.append(BarSegment(id: UUID(), color: .gray, value: uncategorized))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                balanceSection
                monthSection
                categorySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Übersicht")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppRouter.shared.showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Ausgabe eintragen")
                }
            }
            .sheet(isPresented: $showBalanceEditor) {
                BalanceEditView()
                    .environmentObject(store)
            }
        }
    }

    // MARK: Kontostand

    private var balanceSection: some View {
        Section {
            Button {
                showBalanceEditor = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kontostand")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if store.data.balanceSet {
                            Text(store.data.balance.euro)
                                .font(.system(size: 34, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(store.data.balance < 0 ? Color.red : Color.primary)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                        } else {
                            Text("Kontostand eingeben")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } footer: {
            if store.data.balanceSet && store.data.autoDeduct {
                Text("Wird bei jeder Ausgabe automatisch aktualisiert.")
            }
        }
    }

    // MARK: Monat

    private var monthSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(spent.euro)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(spent > budget && budget > 0 ? Color.red : Color.primary)
                    Text("von \(budget.euro)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                StackedBar(segments: segments, total: budget)
                Text(summaryText)
                    .font(.footnote)
                    .foregroundStyle(remaining < 0 && budget > 0 ? Color.red : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 6)
        } header: {
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                Spacer()
                HStack(spacing: 18) {
                    Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                    Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                        .disabled(isCurrentMonth)
                }
                .font(.body.weight(.semibold))
                .buttonStyle(.borderless)
            }
        }
        .headerProminence(.increased)
    }

    // MARK: Kategorien

    private var categorySection: some View {
        Section {
            ForEach(store.data.categories) { category in
                CategoryBudgetRow(
                    symbol: category.symbol,
                    color: category.color,
                    name: category.name,
                    spent: store.spent(categoryID: category.id, inMonthOf: month),
                    goal: category.monthlyGoal
                )
            }
            let uncategorized = store.spent(categoryID: nil, inMonthOf: month)
            if uncategorized > 0 {
                CategoryBudgetRow(symbol: "questionmark", color: .gray, name: "Ohne Kategorie",
                                  spent: uncategorized, goal: 0)
            }
            if store.data.categories.isEmpty {
                Text("Lege unter „Ziele“ Kategorien an.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Kategorien")
        }
        .headerProminence(.increased)
    }

    private func shiftMonth(_ delta: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: month) {
            month = newMonth
        }
    }
}

struct CategoryBudgetRow: View {
    let symbol: String
    let color: Color
    let name: String
    let spent: Double
    let goal: Double

    private var isOver: Bool { goal > 0 && spent > goal }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIcon(symbol: symbol, color: color)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(name)
                    Spacer()
                    Text(spent.euro)
                        .monospacedDigit()
                        .foregroundStyle(isOver ? Color.red : Color.secondary)
                }
                if goal > 0 {
                    ProgressView(value: min(spent / goal, 1))
                        .tint(isOver ? Color.red : color)
                    Text(isOver
                         ? "\((spent - goal).euro) über dem Ziel von \(goal.euro)"
                         : "Noch \((goal - spent).euro) von \(goal.euro)")
                        .font(.caption)
                        .foregroundStyle(isOver ? Color.red : Color.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BalanceEditView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("0,00", text: $text)
                            .keyboardType(.numbersAndPunctuation)
                            .font(.title2.weight(.semibold))
                            .focused($focused)
                        Text("€")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text(store.data.autoDeduct
                         ? "Jede neue Ausgabe wird automatisch abgezogen. Wenn Geld reinkommt, z. B. dein Gehalt, trag hier den neuen Stand ein."
                         : "Der Kontostand ändert sich nur, wenn du ihn hier anpasst.")
                }
            }
            .navigationTitle("Kontostand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        if let value = parseAmount(text) {
                            store.setBalance(value)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(parseAmount(text) == nil)
                }
            }
            .onAppear {
                if store.data.balanceSet {
                    text = formatInput(store.data.balance)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
