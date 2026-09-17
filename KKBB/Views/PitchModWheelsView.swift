import SwiftUI

public struct PitchModWheelsView: View {
    @Bindable var appState: AppState

    @State private var isPitchActive: Bool = false

    private let wheelWidth: CGFloat = 22
    private let wheelCornerRadius: CGFloat = 4

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        GeometryReader { geometry in
            let wheelHeight = geometry.size.height
            let halfHeight = max(10, wheelHeight / 2.0)

            HStack(spacing: 6) {
                // MARK: - Velocity Slider (Friction-loaded, 1...127)
                VStack(spacing: 2) {
                    Text("VEL")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .bottom) {
                        // Base well
                        RoundedRectangle(cornerRadius: wheelCornerRadius)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: wheelCornerRadius)
                                    .stroke(Color.black.opacity(0.35), lineWidth: 0.5)
                            )

                        // Velocity fill bar
                        let velRatio = Double(appState.velocity - 1) / 126.0
                        let fillHeight = velRatio * Double(wheelHeight - 20)
                        RoundedRectangle(cornerRadius: wheelCornerRadius)
                            .fill(Color.accentColor.opacity(0.25))
                            .frame(height: max(0, fillHeight))

                        // Textured Thumb
                        let thumbYOffset = -(velRatio * Double(wheelHeight - 34))

                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(nsColor: .darkGray), Color(nsColor: .systemGray).opacity(0.5), Color(nsColor: .darkGray)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: wheelWidth - 4, height: 26)

                            // Grooves
                            VStack(spacing: 2) {
                                ForEach(0..<3) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: wheelWidth - 8, height: 1.5)
                                }
                            }
                        }
                        .offset(y: thumbYOffset)
                    }
                    .frame(width: wheelWidth)
                    .contentShape(Rectangle())
                    .help("Velocity: \(appState.velocity)")
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                NSApp.keyWindow?.makeFirstResponder(nil)
                                let usableHeight = max(10, wheelHeight - 34)
                                // Inverted Y: dragging up increases velocity
                                let clickYFromBottom = wheelHeight - value.location.y
                                let ratio = Swift.max(0.0, Swift.min(1.0, Double(clickYFromBottom / usableHeight)))
                                let newVel = Int(1.0 + (ratio * 126.0))
                                appState.velocity = Swift.max(1, Swift.min(127, newVel))
                            }
                    )
                }

                // MARK: - Pitch Bend Wheel (Spring-loaded to center)
                VStack(spacing: 2) {
                    Text("PTCH")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)

                    ZStack {
                        // Base well
                        RoundedRectangle(cornerRadius: wheelCornerRadius)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: wheelCornerRadius)
                                    .stroke(Color.black.opacity(0.35), lineWidth: 0.5)
                            )

                        // Center indicator line
                        Rectangle()
                            .fill(Color.primary.opacity(0.25))
                            .frame(height: 1)

                        // Textured Wheel Thumb
                        let currentNormPitch = Double(appState.pitchBend) / 16383.0 // 0.0 to 1.0 (0.5 is center)
                        let yOffset = (0.5 - currentNormPitch) * Double(halfHeight * 1.6)

                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(nsColor: .darkGray), Color(nsColor: .systemGray).opacity(0.5), Color(nsColor: .darkGray)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: wheelWidth - 4, height: halfHeight * 0.85)

                            // Grooves
                            VStack(spacing: 3) {
                                ForEach(0..<5) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: wheelWidth - 8, height: 1.5)
                                }
                            }

                            // Center notch on wheel
                            Rectangle()
                                .fill(isPitchActive ? Color.accentColor : Color.white.opacity(0.8))
                                .frame(width: wheelWidth - 6, height: 2)
                        }
                        .offset(y: yOffset)
                    }
                    .frame(width: wheelWidth)
                    .contentShape(Rectangle())
                    .help("Pitch Bend (Center: 8192)")
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                NSApp.keyWindow?.makeFirstResponder(nil)
                                isPitchActive = true
                                let deltaY = -value.translation.height
                                let travel = halfHeight * 0.8
                                let clampedRatio = Swift.max(-1.0, Swift.min(1.0, Double(deltaY / travel)))
                                // Map -1.0...1.0 to 0...16383
                                let newPitch = UInt16(clampedRatio >= 0
                                    ? 8192 + (clampedRatio * 8191.0)
                                    : 8192 + (clampedRatio * 8192.0))
                                appState.pitchBend = newPitch
                                MIDIPipeline.shared.sendPitchBend(
                                    value: newPitch,
                                    channel: appState.channel,
                                    destinationUID: appState.selectedDestinationUID
                                )
                            }
                            .onEnded { _ in
                                isPitchActive = false
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                                    appState.pitchBend = 8192
                                }
                                MIDIPipeline.shared.sendPitchBend(
                                    value: 8192,
                                    channel: appState.channel,
                                    destinationUID: appState.selectedDestinationUID
                                )
                            }
                    )
                }

                // MARK: - Modulation Wheel (Friction-loaded, CC #1)
                VStack(spacing: 2) {
                    Text("MOD")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .bottom) {
                        // Base well
                        RoundedRectangle(cornerRadius: wheelCornerRadius)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: wheelCornerRadius)
                                    .stroke(Color.black.opacity(0.35), lineWidth: 0.5)
                            )

                        // Mod level fill bar
                        let fillHeight = (Double(appState.modulation) / 127.0) * Double(wheelHeight - 20)
                        RoundedRectangle(cornerRadius: wheelCornerRadius)
                            .fill(Color.accentColor.opacity(0.25))
                            .frame(height: max(0, fillHeight))

                        // Textured Wheel Thumb
                        let currentNormMod = Double(appState.modulation) / 127.0
                        let modYOffset = -(currentNormMod * Double(wheelHeight - 34))

                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(nsColor: .darkGray), Color(nsColor: .systemGray).opacity(0.5), Color(nsColor: .darkGray)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: wheelWidth - 4, height: 26)

                            // Grooves
                            VStack(spacing: 2) {
                                ForEach(0..<3) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: wheelWidth - 8, height: 1.5)
                                }
                            }
                        }
                        .offset(y: modYOffset)
                    }
                    .frame(width: wheelWidth)
                    .contentShape(Rectangle())
                    .help("Modulation (CC #1: \(appState.modulation))")
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                NSApp.keyWindow?.makeFirstResponder(nil)
                                let usableHeight = max(10, wheelHeight - 34)
                                // Inverted Y: dragging up increases modulation
                                let clickYFromBottom = wheelHeight - value.location.y
                                let ratio = Swift.max(0.0, Swift.min(1.0, Double(clickYFromBottom / usableHeight)))
                                let newMod = UInt8(ratio * 127.0)
                                appState.modulation = newMod
                                MIDIPipeline.shared.sendModulation(
                                    value: newMod,
                                    channel: appState.channel,
                                    destinationUID: appState.selectedDestinationUID
                                )
                            }
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .focusable(false)
        .frame(width: 92)
    }
}
