import Foundation
import CoreMIDI

public final class MIDIManager {
    public static let shared = MIDIManager()

    private var clientRef = MIDIClientRef()
    private var outputPortRef = MIDIPortRef()
    private var virtualSourceRef = MIDIEndpointRef()

    public init() {
        setupMIDI()
    }

    deinit {
        if virtualSourceRef != 0 {
            MIDIEndpointDispose(virtualSourceRef)
        }
        if outputPortRef != 0 {
            MIDIPortDispose(outputPortRef)
        }
        if clientRef != 0 {
            MIDIClientDispose(clientRef)
        }
    }

    private func setupMIDI() {
        var status = MIDIClientCreateWithBlock("com.digigun.kkbb.client" as CFString, &clientRef) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshDestinations()
            }
        }
        guard status == noErr else {
            print("Failed to create MIDI client: \(status)")
            return
        }

        status = MIDIOutputPortCreate(clientRef, "com.digigun.kkbb.outport" as CFString, &outputPortRef)
        guard status == noErr else {
            print("Failed to create MIDI output port: \(status)")
            return
        }

        status = MIDISourceCreate(clientRef, "KKBB Virtual Output" as CFString, &virtualSourceRef)
        if status == noErr {
            let name = "KKBB Virtual Output" as CFString
            let manufacturer = "Digigun" as CFString
            MIDIObjectSetStringProperty(virtualSourceRef, kMIDIPropertyName, name)
            MIDIObjectSetStringProperty(virtualSourceRef, kMIDIPropertyDisplayName, name)
            MIDIObjectSetStringProperty(virtualSourceRef, kMIDIPropertyManufacturer, manufacturer)
        } else {
            print("Failed to create Virtual MIDI Source: \(status)")
        }
    }

    public func getDestinations() -> [MIDIEndpointInfo] {
        var destinations: [MIDIEndpointInfo] = []
        let count = MIDIGetNumberOfDestinations()

        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            if endpoint != 0 {
                var uniqueID: Int32 = 0
                MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)

                var paramName: Unmanaged<CFString>?
                let nameStatus = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &paramName)
                let name: String
                if nameStatus == noErr, let paramName {
                    name = paramName.takeRetainedValue() as String
                } else {
                    var altName: Unmanaged<CFString>?
                    if MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &altName) == noErr, let altName {
                        name = altName.takeRetainedValue() as String
                    } else {
                        name = "Destination \(i + 1)"
                    }
                }
                destinations.append(MIDIEndpointInfo(id: uniqueID, name: name, endpointRef: endpoint))
            }
        }
        return destinations
    }

    public func refreshDestinations() {
        NotificationCenter.default.post(name: .midiDestinationsChanged, object: nil)
    }

    public func destinationName(for uid: Int32?) -> String {
        guard let uid else { return "KKBB Virtual Output" }
        let dests = getDestinations()
        if let match = dests.first(where: { $0.id == uid }) {
            return match.name
        }
        return "Endpoint (\(uid))"
    }

    public static func noteName(for note: UInt8) -> String {
        let semitone = Int(note) % 12
        let octave = (Int(note) / 12) - 1
        let name = DrumPadConfig.noteNames[semitone]
        return "\(name)\(octave)"
    }

    public static func ccName(for controller: UInt8) -> String {
        switch controller {
        case 1: return "Modulation"
        case 2: return "Breath"
        case 7: return "Volume"
        case 10: return "Pan"
        case 11: return "Expression"
        case 64: return "Sustain"
        case 71: return "Resonance"
        case 74: return "Cutoff"
        case 91: return "Reverb"
        case 120: return "All Sound Off"
        case 123: return "All Notes Off"
        default: return "CC \(controller)"
        }
    }

    public func sendNoteOn(note: UInt8, velocity: UInt8, channel: Int, destinationUID: Int32?) {
        sendMIDIMessage(status: 0x90, note: note, velocity: velocity, channel: channel, destinationUID: destinationUID)
        let ch = UInt8(Swift.max(0, Swift.min(15, channel - 1)))
        let statusByte = 0x90 | ch
        let hex = String(format: "%02X %02X %02X", statusByte, note, velocity)
        let dest = destinationName(for: destinationUID)
        let name = Self.noteName(for: note)
        if velocity > 0 {
            MIDIMonitorService.shared.log(type: .noteOn, channel: channel, detail: "\(name) (\(note))  Vel \(velocity)", hexBytes: hex, destination: dest)
        } else {
            MIDIMonitorService.shared.log(type: .noteOff, channel: channel, detail: "\(name) (\(note))  Vel 0", hexBytes: hex, destination: dest)
        }
    }

    public func sendNoteOff(note: UInt8, velocity: UInt8 = 0, channel: Int, destinationUID: Int32?) {
        sendMIDIMessage(status: 0x80, note: note, velocity: velocity, channel: channel, destinationUID: destinationUID)
        let ch = UInt8(Swift.max(0, Swift.min(15, channel - 1)))
        let statusByte = 0x80 | ch
        let hex = String(format: "%02X %02X %02X", statusByte, note, velocity)
        let dest = destinationName(for: destinationUID)
        let name = Self.noteName(for: note)
        MIDIMonitorService.shared.log(type: .noteOff, channel: channel, detail: "\(name) (\(note))  Vel \(velocity)", hexBytes: hex, destination: dest)
    }

    public func allNotesOff(channel: Int, destinationUID: Int32?) {
        let dest = destinationName(for: destinationUID)
        let ch = UInt8(Swift.max(0, Swift.min(15, channel - 1)))
        let hex = String(format: "%02X 7B 00 · %02X 78 00", 0xB0 | ch, 0xB0 | ch)
        MIDIMonitorService.shared.log(type: .allNotesOff, channel: channel, detail: "All Notes & Sound Off", hexBytes: hex, destination: dest)
        // Control Change 123 (All Notes Off)
        sendCC(controller: 123, value: 0, channel: channel, destinationUID: destinationUID, skipLog: true)
        // Control Change 120 (All Sound Off)
        sendCC(controller: 120, value: 0, channel: channel, destinationUID: destinationUID, skipLog: true)
    }

    public func sendCommand(_ command: MIDICommandType, channel: Int, destinationUID: Int32?) {
        switch command {
        case .allNotesOff:
            allNotesOff(channel: channel, destinationUID: destinationUID)
        default:
            sendRawBytes(command.rawBytes, destinationUID: destinationUID)
            let hex = command.rawBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
            let dest = destinationName(for: destinationUID)
            let logType: MIDILogEventType = (command.category == .realTime) ? .realTime : .mmc
            MIDIMonitorService.shared.log(type: logType, channel: nil, detail: command.displayName, hexBytes: hex, destination: dest)
        }
    }

    public func sendCC(controller: UInt8, value: UInt8, channel: Int, destinationUID: Int32?, skipLog: Bool = false) {
        let ch = UInt8(Swift.max(0, Swift.min(15, channel - 1)))
        let statusByte = 0xB0 | ch
        let clampedController = Swift.min(controller, 127)
        let clampedValue = Swift.min(value, 127)
        sendRawBytes([statusByte, clampedController, clampedValue], destinationUID: destinationUID)
        if !skipLog {
            let hex = String(format: "%02X %02X %02X", statusByte, clampedController, clampedValue)
            let dest = destinationName(for: destinationUID)
            let name = Self.ccName(for: clampedController)
            MIDIMonitorService.shared.log(type: .controlChange, channel: channel, detail: "\(name) (\(clampedController)) Val \(clampedValue)", hexBytes: hex, destination: dest)
        }
    }

    public func sendModulation(value: UInt8, channel: Int, destinationUID: Int32?) {
        sendCC(controller: 1, value: value, channel: channel, destinationUID: destinationUID)
    }

    public func sendPitchBend(value: UInt16, channel: Int, destinationUID: Int32?) {
        let ch = UInt8(Swift.max(0, Swift.min(15, channel - 1)))
        let statusByte = 0xE0 | ch
        let clamped = Swift.max(0, Swift.min(16383, Int(value)))
        let lsb = UInt8(clamped & 0x7F)
        let msb = UInt8((clamped >> 7) & 0x7F)
        sendRawBytes([statusByte, lsb, msb], destinationUID: destinationUID)
        let hex = String(format: "%02X %02X %02X", statusByte, lsb, msb)
        let dest = destinationName(for: destinationUID)
        let offset = Int(clamped) - 8192
        let sign = offset > 0 ? "+" : ""
        MIDIMonitorService.shared.log(type: .pitchBend, channel: channel, detail: "Bend \(sign)\(offset) (\(clamped))", hexBytes: hex, destination: dest)
    }

    private func sendMIDIMessage(status: UInt8, note: UInt8, velocity: UInt8, channel: Int, destinationUID: Int32?) {
        let clampedChannel = UInt8(Swift.max(0, Swift.min(15, channel - 1)))
        let statusByte = status | clampedChannel
        let clampedNote = Swift.min(note, 127)
        let clampedVelocity = Swift.min(velocity, 127)

        sendRawBytes([statusByte, clampedNote, clampedVelocity], destinationUID: destinationUID)
    }

    private func sendRawBytes(_ bytes: [UInt8], destinationUID: Int32?) {
        guard !bytes.isEmpty else { return }

        let bufferSize = 256
        var packetBuffer = [UInt8](repeating: 0, count: bufferSize)

        packetBuffer.withUnsafeMutableBytes { rawBuffer in
            guard let packetListPtr = rawBuffer.baseAddress?.assumingMemoryBound(to: MIDIPacketList.self) else { return }
            let curPacket = MIDIPacketListInit(packetListPtr)
            _ = MIDIPacketListAdd(packetListPtr, bufferSize, curPacket, 0, bytes.count, bytes)

            // 1. Emit through Virtual Source
            if virtualSourceRef != 0 {
                MIDIReceived(virtualSourceRef, packetListPtr)
            }

            // 2. Emit to selected destination endpoint if set
            if let destinationUID, outputPortRef != 0 {
                let count = MIDIGetNumberOfDestinations()
                for i in 0..<count {
                    let endpoint = MIDIGetDestination(i)
                    var uid: Int32 = 0
                    if MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uid) == noErr, uid == destinationUID {
                        MIDISend(outputPortRef, endpoint, packetListPtr)
                        break
                    }
                }
            }
        }
    }
}

extension MIDIManager: MIDIEventReceiver {
    public func receive(event: MIDIEvent, destinationUID: Int32?) {
        switch event {
        case .noteOn(let note, let velocity, let channel):
            sendNoteOn(note: note, velocity: velocity, channel: channel, destinationUID: destinationUID)
        case .noteOff(let note, let velocity, let channel):
            sendNoteOff(note: note, velocity: velocity, channel: channel, destinationUID: destinationUID)
        case .allNotesOff(let channel):
            allNotesOff(channel: channel, destinationUID: destinationUID)
        case .controlChange(let controller, let value, let channel):
            sendCC(controller: controller, value: value, channel: channel, destinationUID: destinationUID)
        case .pitchBend(let value, let channel):
            sendPitchBend(value: value, channel: channel, destinationUID: destinationUID)
        }
    }
}

public extension Notification.Name {
    static let midiDestinationsChanged = Notification.Name("com.digigun.kkbb.midiDestinationsChanged")
}
