import SwiftUI

struct DayGroup: Identifiable {
    let day: Date
    let items: [Expense]
    var id: Date { day }
    var total: Double { items.reduce(0) { $0 + $1.amount } }
}

struct HistoryView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var search = ""
    @State private var editing: Expense?

    private var filtered: [Expense] {
        let all = store.data.expenses.sorted { $0.date > $1.date }
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return all }
        return all.filter { expense in
            if expense.title.localizedCaseInsensitiveContains(query) { return true }
            let categoryName = store.category(for: expense.categoryID)?.name ?? "Ohne Kategorie"
            return categoryName.localizedCaseInsensitiveContains(query)
        }
    }

    private var groups: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { expense in
            calendar.startOfDay(for: expense.date)
        }
        return grouped.keys.sorted(by: >).map { day in
            DayGroup(day: day, items: grouped[day] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { expense in
                            Button {
                                editing = expense
                            } label: {
                                ExpenseRow(expense: expense, category: store.category(for: expense.categoryID))
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { group.items[$0] }
                            for expense in toDelete {
                                store.deleteExpense(expense)
                            }
                        }
                    } header: {
                        HStack {
                            Text(dayTitle(group.day))
                            Spacer()
                            Text(group.total.euro)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if groups.isEmpty {
                    if search.isEmpty {
                        ContentUnavailableView(
                            "Keine Ausgaben",
                            systemImage: "list.bullet",
                            description: Text("Halte die Aktionstaste gedrückt oder tippe in der Übersicht auf +.")
                        )
                    } else {
                        ContentUnavailableView.search(text: search)
                    }
                }
            }
            .searchable(text: $search, prompt: "Suchen")
            .navigationTitle("Verlauf")
            .sheet(item: $editing) { expense in
                AddExpenseView(editing: expense)
                    .environmentObject(store)
            }
        }
    }

    private func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Heute" }
        if calendar.isDateInYesterday(day) { return "Gestern" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let category: SpendCategory?

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(symbol: category?.symbol ?? "questionmark",
                         color: category?.color ?? .gray)
            VStack(alignment: .leading, spacing: 1) {
                Text(expense.title)
                    .lineLimit(1)
                Text("\(category?.name ?? "Ohne Kategorie") · \(expense.date.formatted(date: .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(expense.amount.euro)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
    }
}
