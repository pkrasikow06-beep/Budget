import SwiftUI
import UIKit

extension CategoryColor {
    /// Systemfarbe von iOS (passt sich automatisch an Hell/Dunkel an).
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        }
    }
}

extension SpendCategory {
    var color: Color { colorName.color }
}

/// Auswahl an SF Symbols für Kategorien.
let categorySymbols: [String] = [
    "fork.knife", "cart.fill", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
    "party.popper.fill", "gamecontroller.fill", "film.fill", "music.note",
    "bag.fill", "tshirt.fill", "gift.fill", "sparkles",
    "tram.fill", "car.fill", "fuelpump.fill", "airplane",
    "house.fill", "bolt.fill", "iphone", "wifi",
    "heart.fill", "cross.case.fill", "dumbbell.fill", "pawprint.fill",
    "book.fill", "graduationcap.fill", "creditcard.fill", "shippingbox.fill"
]

extension Double {
    /// Formatiert als Euro-Betrag, z. B. "12,50 €".
    var euro: String {
        self.formatted(.currency(code: "EUR").locale(Locale(identifier: "de_DE")))
    }
}

/// Wandelt eine Eingabe wie "12,50" oder "1.234,56" in eine Zahl um.
func parseAmount(_ text: String) -> Double? {
    var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "€", with: "")
    if t.contains(",") {
        t = t.replacingOccurrences(of: ".", with: "")
        t = t.replacingOccurrences(of: ",", with: ".")
    }
    guard !t.isEmpty, let value = Double(t), value.isFinite else { return nil }
    return (value * 100).rounded() / 100
}

/// Zahl für ein Eingabefeld, z. B. 12.5 -> "12,50".
func formatInput(_ value: Double) -> String {
    String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
}

/// Symbol in einem farbigen, abgerundeten Quadrat – wie in den iPhone-Einstellungen.
struct CategoryIcon: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    }
}

/// Ein Abschnitt im gestapelten Balken.
struct BarSegment: Identifiable {
    let id: UUID
    let color: Color
    let value: Double
}

/// Gestapelter Balken wie bei "iPhone-Speicher" in den Einstellungen.
struct StackedBar: View {
    let segments: [BarSegment]
    let total: Double

    var body: some View {
        GeometryReader { geo in
            let visible = segments.filter { $0.value > 0 }
            let sum = visible.reduce(0) { $0 + $1.value }
            let denominator = max(total, sum, 0.01)
            let gaps = CGFloat(max(visible.count - 1, 0)) * 2
            let usable = max(geo.size.width - gaps, 0)
            HStack(spacing: 2) {
                ForEach(visible) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: usable * CGFloat(segment.value / denominator))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 14)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
