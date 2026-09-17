import SwiftUI

public struct OctaveBarView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0...6, id: \.self) { octaveIndex in
                let isSelected = appState.octave == octaveIndex
                Button {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    appState.octave = octaveIndex
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                isSelected
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.18)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        isSelected
                                            ? Color.white.opacity(0.2)
                                            : Color.black.opacity(0.2),
                                        lineWidth: 0.5
                                    )
                            )

                        Text(appState.mode == .drumGrid ? "Bank \(octaveIndex)" : "\(octaveIndex)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(isSelected ? Color.white : Color.secondary)
                    }
                    .frame(height: 20)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help(appState.mode == .drumGrid ? "Bank \(octaveIndex) (Pads 1–16)" : "Octave C\(octaveIndex)")
            }
        }
        .focusable(false)
        .padding(.horizontal, 4)
        .padding(.vertical, 5)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
    }
}
