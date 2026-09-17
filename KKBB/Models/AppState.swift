import Foundation
import Observation
import CoreMIDI

public struct MIDIEndpointInfo: Identifiable, Hashable {
    public let id: Int32
    public let name: String
    public let endpointRef: MIDIEndpointRef

    public init(id: Int32, name: String, endpointRef: MIDIEndpointRef) {
        self.id = id
        self.name = name
        self.endpointRef = endpointRef
    }
}

@Observable
public final class AppState {
    private let defaults = UserDefaults.standard

    public var mode: KeyboardMode {
        didSet {
            defaults.set(mode.rawValue, forKey: "kkbb.mode")
        }
    }

    public var selectedDestinationUID: Int32? {
        didSet {
            if let selectedDestinationUID {
                defaults.set(selectedDestinationUID, forKey: "kkbb.destinationUID")
            } else {
                defaults.removeObject(forKey: "kkbb.destinationUID")
            }
        }
    }

    public var channel: Int {
        didSet {
            defaults.set(channel, forKey: "kkbb.channel")
        }
    }

    public var octave: Int {
        didSet {
            defaults.set(octave, forKey: "kkbb.octave")
        }
    }

    public var velocity: Int {
        didSet {
            defaults.set(velocity, forKey: "kkbb.velocity")
        }
    }

    public var zoom: Double {
        didSet {
            let rounded = (zoom * 4.0).rounded() / 4.0
            defaults.set(rounded, forKey: "kkbb.zoom")
        }
    }

    public var activeNotes: Set<UInt8> = []
    public var availableDestinations: [MIDIEndpointInfo] = []

    public init() {
        if let savedMode = defaults.string(forKey: "kkbb.mode"),
           let parsedMode = KeyboardMode(rawValue: savedMode) {
            self.mode = parsedMode
        } else {
            self.mode = .oneOctave
        }

        if defaults.object(forKey: "kkbb.destinationUID") != nil {
            self.selectedDestinationUID = Int32(defaults.integer(forKey: "kkbb.destinationUID"))
        } else {
            self.selectedDestinationUID = nil
        }

        let savedChannel = defaults.integer(forKey: "kkbb.channel")
        self.channel = (1...16).contains(savedChannel) ? savedChannel : 1

        let savedOctave = defaults.integer(forKey: "kkbb.octave")
        self.octave = (0...6).contains(savedOctave) ? savedOctave : 3

        let savedVelocity = defaults.integer(forKey: "kkbb.velocity")
        self.velocity = (1...127).contains(savedVelocity) ? savedVelocity : 100

        let savedZoom = defaults.double(forKey: "kkbb.zoom")
        self.zoom = (savedZoom >= 0.5 && savedZoom <= 4.0) ? savedZoom : 1.0
    }
}
