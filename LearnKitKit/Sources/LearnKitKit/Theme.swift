import SwiftUI

/// Colors for the `array` Primitive. Centralized so theming (dark mode, accents)
/// can grow here without touching the renderer. See the open "theming" question.
struct Palette: Sendable {
    var cellText = Color.primary
    var pointerColor = Color.accentColor
    var linkColor = Color.secondary       // `next` arrows in the list primitive, tree/graph edges

    func fill(for state: HighlightState?) -> Color {
        switch state {
        case .compare:  return Color.blue.opacity(0.18)
        case .match:    return Color.green.opacity(0.20)
        case .mismatch: return Color.red.opacity(0.20)
        case .done:     return Color.green.opacity(0.30)
        case .active:   return Color.orange.opacity(0.20)
        case nil:       return Color.gray.opacity(0.12)
        }
    }

    func border(for state: HighlightState?) -> Color {
        switch state {
        case .compare:  return .blue
        case .match:    return .green
        case .mismatch: return .red
        case .done:     return .green
        case .active:   return .orange
        case nil:       return Color.gray.opacity(0.35)
        }
    }

    static let standard = Palette()
}
