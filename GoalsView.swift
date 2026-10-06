import SwiftUI
import UIKit

struct GoalsView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var editingCategory: SpendCategory?
    @State private var showNewCategory = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.data.categories) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            HStack(spacing: 12) {
                                CategoryIcon(symbol: category.symbol, color: category.color)
                                Text(category.name)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text(category.monthlyGoal.euro)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .onDelete { offsets in
                        store.deleteCategories(at: offsets)
                    }
                    Button("Kategorie hinzufügen") {
                        showNewCategory = true
                    }
                } header: {
                    Text("Monatsziele")
                } footer: {
                    Text("Zusammen \(store.totalGoal.euro) pro Monat.")
                }

                Section {
                    Toggle("Vom Kontostand abziehen", isOn: Binding(
                        get: { store.data.autoDeduct },
                        set: { store.setAutoDeduct($0) }
                    ))
                } footer: {
                    Text("Jede Ausgabe wird automatisch von deinem Kontostand abgezogen.")
                }

                Section {
                    Label("Einstellungen öffnen", systemImage: "1.circle")
                    Label("Aktionstaste → Kurzbefehl", systemImage: "2.circle")
                    Label("Budget → Ausgabe eintragen", systemImage: "3.circle")
                } header: {
                    Text("Aktionstaste")
                } footer: {
                    Text("Danach reicht es, die Aktionstaste gedrückt zu halten, um eine Ausgabe einzutragen.")
                }

                Section {
                    ShareLink(item: store.csvExport()) {
                        Text("Ausgaben exportieren")
                    }
                } footer: {
                    Text("Deine Daten werden nur auf diesem iPhone gespeichert.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ziele")
            .sheet(item: $editingCategory) { category in
                CategoryEditView(category: category)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showNewCategory) {
                CategoryEditView(category: nil)
                    .environmentObject(store)
            }
        }
    }
}

/// Kategorie bearbeiten – aufgebaut wie "Neue Liste" in der Erinnerungen-App.
struct CategoryEditView: View {
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss

    let category: SpendCategory?

    @State private var name = ""
    @State private var symbol = "fork.knife"
    @State private var colorName: CategoryColor = .blue
    @State private var goalText = ""
    @State private var didLoad = false

    private var goal: Double? {
        guard let value = parseAmount(goalText), value >= 0 else { return nil }
        return value
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && goal != nil
    }

    private let gridColumns = [GridItem(.adaptive(minimum: 40), spacing: 12)]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        CategoryIcon(symbol: symbol, color: colorName.color, size: 88)
                            .shadow(color: colorName.color.opacity(0.35), radius: 10, y: 4)
                        TextField("Name", text: $name)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.tertiarySystemFill),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(CategoryColor.allCases) { option in
                            Button {
                                colorName = option
                            } label: {
                                Circle()
                                    .fill(option.color.gradient)
                                    .frame(width: 36, height: 36)
                                    .padding(3)
                                    .overlay(
                                        Circle().stroke(colorName == option ? Color.secondary : Color.clear, lineWidth: 2.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(categorySymbols, id: \.self) { option in
                            Button {
                                symbol = option
                            } label: {
                                Image(systemName: option)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(symbol == option ? Color.white : Color.secondary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle().fill(symbol == option ? colorName.color : Color(UIColor.tertiarySystemFill))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    HStack {
                        TextField("0", text: $goalText)
                            .keyboardType(.decimalPad)
                        Text("€ pro Monat")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Monatsziel")
                } footer: {
                    Text("So viel möchtest du höchstens pro Monat dafür ausgeben.")
                }

                if let category {
                    Section {
                        Button("Kategorie löschen", role: .destructive) {
                            store.deleteCategory(category.id)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                    } footer: {
                        Text("Bisherige Ausgaben bleiben erhalten und erscheinen als „Ohne Kategorie“.")
                    }
                }
            }
            .navigationTitle(category == nil ? "Neue Kategorie" : "Kategorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let category {
            name = category.name
            symbol = category.symbol
            colorName = category.colorName
            goalText = formatInput(category.monthlyGoal)
        }
    }

    private func save() {
        guard let goal, !trimmedName.isEmpty else { return }
        var updated = category ?? SpendCategory(name: trimmedName, symbol: symbol, colorName: colorName, monthlyGoal: goal)
        updated.name = trimmedName
        updated.symbol = symbol
        updated.colorName = colorName
        updated.monthlyGoal = goal
        store.saveCategory(updated)
        dismiss()
    }
}
