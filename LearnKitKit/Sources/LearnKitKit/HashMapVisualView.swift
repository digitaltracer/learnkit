import SwiftUI

/// Renders the `hashmap` Primitive: an optional lookup `probe` (with hit/miss),
/// then the map's key -> value rows in insertion order. Layout is a centered
/// stack — no geometry math needed.
struct HashMapVisualView: View {
    let visual: HashMapVisual
    var palette: Palette = .standard

    var body: some View {
        VStack(spacing: 14) {
            if let probe = visual.probe {
                ProbeView(probe: probe, palette: palette)
            }

            VStack(spacing: 6) {
                Text("map")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                if visual.entries.isEmpty {
                    Text("empty")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 120, height: 34)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.gray.opacity(0.10)))
                } else {
                    ForEach(Array(visual.entries.enumerated()), id: \.offset) { _, entry in
                        EntryRow(entry: entry, palette: palette)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ProbeView: View {
    let probe: HashProbe
    let palette: Palette

    var body: some View {
        HStack(spacing: 8) {
            Text("look up")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
            KeyChip(text: probe.key.display, palette: palette)
            if let found = probe.found {
                Image(systemName: found ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(found ? .green : .red)
                Text(found ? "hit" : "miss")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(found ? .green : .red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gray.opacity(0.10)))
    }
}

private struct EntryRow: View {
    let entry: HashEntry
    let palette: Palette

    var body: some View {
        HStack(spacing: 6) {
            KeyChip(text: entry.key.display, palette: palette, state: entry.state)
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            ValueChip(text: entry.value.display, palette: palette, state: entry.state)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(palette.fill(for: entry.state)))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(palette.border(for: entry.state), lineWidth: entry.state == nil ? 0 : 1.5)
        )
    }
}

private struct KeyChip: View {
    let text: String
    let palette: Palette
    var state: HighlightState? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(palette.cellText)
            .frame(minWidth: 30, minHeight: 28)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.gray.opacity(0.14)))
    }
}

private struct ValueChip: View {
    let text: String
    let palette: Palette
    var state: HighlightState? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(minWidth: 30, minHeight: 28)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.gray.opacity(0.08)))
    }
}
