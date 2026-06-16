import SwiftUI

/// One Lesson as a single page in a Track feed: a compact title header, the
/// step-by-step player (the diagram morphs, the caption crossfades, a haptic
/// fires per step), then a completion state hinting to swipe up for the next lesson.
struct LessonPage: View {
    let lesson: Lesson
    var hasNext: Bool = true

    enum Phase: Equatable { case playing, complete }
    @State private var phase: Phase = .playing
    @State private var stepIndex = 0

    private let palette: Palette = .standard
    private var steps: [Step] { lesson.steps }
    private var current: Step { steps[min(stepIndex, steps.count - 1)] }
    private var isLastStep: Bool { stepIndex == steps.count - 1 }

    var body: some View {
        VStack(spacing: 12) {
            header
            if phase == .playing { player } else { completion }
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: stepIndex)
        .sensoryFeedback(.success, trigger: phase == .complete)
    }

    private var header: some View {
        VStack(spacing: 10) {
            if let difficulty = lesson.difficulty { DifficultyBadge(difficulty: difficulty) }
            Text(lesson.title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            if let problem = lesson.problem {
                Text(problem)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let example = lesson.example {
                ExampleView(example: example)
            }
        }
        .padding(.horizontal, 20)
    }

    private var player: some View {
        VStack(spacing: 0) {
            ProgressDots(count: steps.count, current: stepIndex)

            Spacer(minLength: 16)

            // Keep the diagram and its instruction together as one centered group,
            // so the text sits with the visual it describes instead of drifting off.
            VStack(spacing: 22) {
                ArrayVisualView(visual: current.visual, palette: palette)
                    .frame(height: 220)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .onTapGesture { advance() }

                InstructionView(caption: current.caption)
                    .id(stepIndex)
                    .transition(.opacity)
            }

            Spacer(minLength: 16)

            controls
        }
        .frame(maxHeight: .infinity)
        // Horizontal swipe advances steps; the enclosing vertical feed owns up/down.
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -40 { advance() }
                    else if value.translation.width > 40 { back() }
                }
        )
    }

    private var controls: some View {
        HStack {
            Button { back() } label: { Label("Back", systemImage: "chevron.left") }
                .disabled(stepIndex == 0)
            Spacer()
            Text("\(stepIndex + 1) / \(steps.count)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            Button { advance() } label: {
                Label(isLastStep ? "Finish" : "Next", systemImage: isLastStep ? "checkmark" : "chevron.right")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var completion: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Complete").font(.title2.bold())
            Button { replay() } label: { Label("Replay", systemImage: "arrow.counterclockwise") }
                .buttonStyle(.bordered)
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: hasNext ? "chevron.up" : "checkmark.seal")
                Text(hasNext ? "Swipe up for the next lesson" : "You've finished this track")
                    .font(.footnote)
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private func advance() {
        if isLastStep {
            withAnimation(.easeInOut(duration: 0.3)) { phase = .complete }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { stepIndex += 1 }
        }
    }

    private func back() {
        guard stepIndex > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { stepIndex -= 1 }
    }

    private func replay() {
        withAnimation(.easeInOut(duration: 0.25)) {
            stepIndex = 0
            phase = .playing
        }
    }
}

private struct ExampleView: View {
    let example: ProblemExample

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Input", example.input)
            row("Output", example.output)
            if let note = example.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.gray.opacity(0.12)))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 54, alignment: .leading)
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// The per-Step instruction text. Renders each sentence on its own line so a
/// multi-sentence caption reads as distinct beats rather than one block of prose.
private struct InstructionView: View {
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(sentences.enumerated()), id: \.offset) { _, sentence in
                Text(sentence)
                    .font(.body)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    /// Split on sentence-ending punctuation followed by a space. Decimals such as
    /// "0.5" and "12.75" survive intact because there is no space after their dot.
    private var sentences: [String] {
        var result: [String] = []
        var current = ""
        let chars = Array(caption)
        for (i, ch) in chars.enumerated() {
            current.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                let next = i + 1 < chars.count ? chars[i + 1] : " "
                if next == " " {
                    let trimmed = current.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { result.append(trimmed) }
                    current = ""
                }
            }
        }
        let tail = current.trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty { result.append(tail) }
        return result.isEmpty ? [caption] : result
    }
}

private struct ProgressDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: i == current ? 18 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.3), value: current)
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty

    private var color: Color {
        switch difficulty {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        }
    }

    var body: some View {
        Text(difficulty.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.18)))
            .foregroundStyle(color)
    }
}
