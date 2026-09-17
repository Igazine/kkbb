import SwiftUI

struct KnobsStripView: View {
    @Bindable var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(appState.activeProfile.knobs.prefix(8).enumerated()), id: \.element.id) { index, knob in
                RotaryKnobView(
                    knob: knob,
                    onValueChange: { newValue in
                        appState.updateKnobValue(index: index, value: newValue)
                    },
                    onConfigChange: { label, controller, defaultValue in
                        appState.updateKnobConfig(
                            index: index,
                            label: label,
                            controller: controller,
                            defaultValue: defaultValue
                        )
                    }
                )
                .frame(maxWidth: .infinity)

                if index < 7 {
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 1, height: 32)
                }
            }
        }
        .frame(height: 54)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.18))
        .clipped()
        .focusable(false)
    }
}
