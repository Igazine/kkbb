import SwiftUI
import AppKit

struct RotaryKnobView: View {
    let knob: KnobConfig
    let onValueChange: (UInt8) -> Void
    let onConfigChange: (String, UInt8, UInt8) -> Void

    @State private var dragStartY: CGFloat? = nil
    @State private var dragStartValue: Int = 0
    @State private var isHovering: Bool = false
    @State private var showingCustomSheet: Bool = false
    @State private var customLabel: String = ""
    @State private var customController: Int = 1
    @State private var customDefaultValue: Int = 0

    private var fraction: Double {
        Double(knob.value) / 127.0
    }

    var body: some View {
        VStack(spacing: 3) {
            // Parameter Label
            Text(knob.label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .default))
                .foregroundStyle(isHovering ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            // Rotary Dial
            ZStack {
                // Background Track Arc (270 degrees, 135° to 405°)
                CircleArc(startAngle: .degrees(135), endAngle: .degrees(405))
                    .stroke(
                        Color(nsColor: .separatorColor).opacity(0.4),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )

                // Active Value Arc
                CircleArc(startAngle: .degrees(135), endAngle: .degrees(135 + (fraction * 270)))
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )

                // Knob Body
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(nsColor: .controlBackgroundColor),
                                Color(nsColor: .windowBackgroundColor)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.35), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 1.5, x: 0, y: 1)
                    .padding(5)

                // Rotary Pointer Tick
                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
                    let angleDeg = 135.0 + (fraction * 270.0)
                    let angleRad = angleDeg * .pi / 180.0
                    let innerRadius = (geo.size.width / 2.0) - 10.5
                    let outerRadius = (geo.size.width / 2.0) - 5.5

                    let start = CGPoint(
                        x: center.x + CGFloat(cos(angleRad)) * innerRadius,
                        y: center.y + CGFloat(sin(angleRad)) * innerRadius
                    )
                    let end = CGPoint(
                        x: center.x + CGFloat(cos(angleRad)) * outerRadius,
                        y: center.y + CGFloat(sin(angleRad)) * outerRadius
                    )

                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
            .frame(width: 34, height: 34)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        NSApp.keyWindow?.makeFirstResponder(nil)
                        if dragStartY == nil {
                            dragStartY = value.startLocation.y
                            dragStartValue = Int(knob.value)
                        }
                        let deltaY = (dragStartY! - value.location.y)
                        let isShift = NSEvent.modifierFlags.contains(.shift)
                        let factor: CGFloat = isShift ? 0.25 : 1.0
                        let deltaUnits = Int(deltaY * factor)
                        let newVal = UInt8(Swift.max(0, Swift.min(127, dragStartValue + deltaUnits)))
                        if newVal != knob.value {
                            onValueChange(newVal)
                        }
                    }
                    .onEnded { _ in
                        dragStartY = nil
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    onValueChange(knob.defaultValue)
                }
            )

            // Numerical Value / CC Readout
            Text("\(knob.value)")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(dragStartY != nil ? Color.accentColor : .secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color(nsColor: .controlAccentColor).opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            contextMenuItems
        }
        .sheet(isPresented: $showingCustomSheet) {
            customAssignmentSheet
        }
        .focusable(false)
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Section("Preset CC Assignments") {
            Button("CC 1: Modulation") {
                onConfigChange("MOD", 1, 0)
            }
            Button("CC 2: Breath Controller") {
                onConfigChange("BREATH", 2, 0)
            }
            Button("CC 4: Foot Controller") {
                onConfigChange("FOOT", 4, 0)
            }
            Button("CC 7: Channel Volume") {
                onConfigChange("VOL", 7, 100)
            }
            Button("CC 8: Balance") {
                onConfigChange("BAL", 8, 64)
            }
            Button("CC 10: Pan (Center 64)") {
                onConfigChange("PAN", 10, 64)
            }
            Button("CC 11: Expression") {
                onConfigChange("EXPR", 11, 127)
            }
            Button("CC 64: Sustain Pedal") {
                onConfigChange("SUST", 64, 0)
            }
            Button("CC 71: Resonance / Timbre") {
                onConfigChange("RESO", 71, 64)
            }
            Button("CC 72: Release Time") {
                onConfigChange("REL", 72, 64)
            }
            Button("CC 73: Attack Time") {
                onConfigChange("ATK", 73, 64)
            }
            Button("CC 74: Cutoff / Brightness") {
                onConfigChange("CUTOFF", 74, 64)
            }
            Button("CC 91: Reverb Level") {
                onConfigChange("REVERB", 91, 0)
            }
            Button("CC 93: Chorus Level") {
                onConfigChange("CHORUS", 93, 0)
            }
        }

        Divider()

        Button("Custom CC Assignment…") {
            customLabel = knob.label
            customController = Int(knob.controller)
            customDefaultValue = Int(knob.defaultValue)
            showingCustomSheet = true
        }

        Divider()

        Button("Reset to Default (\(knob.defaultValue))") {
            onValueChange(knob.defaultValue)
        }
    }

    private var customAssignmentSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Knob Assignment")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Label:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("e.g. FILTER", text: $customLabel)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }

                HStack {
                    Text("CC Number:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("0-127", value: $customController, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("(0–127)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Default Value:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("0-127", value: $customDefaultValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("(0–127)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    showingCustomSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    let cleanedLabel = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalLabel = cleanedLabel.isEmpty ? "CC\(customController)" : cleanedLabel
                    let clampedCC = UInt8(Swift.max(0, Swift.min(127, customController)))
                    let clampedDef = UInt8(Swift.max(0, Swift.min(127, customDefaultValue)))
                    onConfigChange(finalLabel, clampedCC, clampedDef)
                    showingCustomSheet = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 320)
    }
}

// Helper Shape for Circular Arc
private struct CircleArc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (min(rect.width, rect.height) / 2.0) - 2.0
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
