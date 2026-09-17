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

    public func sendNoteOn(note: UInt8, velocity: UInt8, channel: Int, destinationUID: Int32?) {
        sendMIDIMessage(status: 0x90, note: note, velocity: velocity, channel: channel, destinationUID: destinationUID)
    }

    public func sendNoteOff(note: UInt8, velocity: UInt8 = 0, channel: Int, destinationUID: Int32?) {
        sendMIDIMessage(status: 0x80, note: note, velocity: velocity, channel: channel, destinationUID: destinationUID)
    }

    public func allNotesOff(channel: Int, destinationUID: Int32?) {
        // Control Change 123 (All Notes Off)
        sendCC(controller: 123, value: 0, channel: channel, destinationUID: destinationUID)
        // Control Change 120 (All Sound Off)
        sendCC(controller: 120, value: 0, channel: channel, destinationUID: destinationUID)
    }

    private func sendCC(controller: UInt8, value: UInt8, channel: Int, destinationUID: Int32?) {
        let ch = UInt8(Swift.max(0, Swift.min(15, channel - 1)))
        let statusByte = 0xB0 | ch
        sendRawBytes([statusByte, controller, value], destinationUID: destinationUID)
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

public extension Notification.Name {
    static let midiDestinationsChanged = Notification.Name("com.digigun.kkbb.midiDestinationsChanged")
}
