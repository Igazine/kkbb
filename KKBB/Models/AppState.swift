import Foundation
import Observation
import CoreMIDI
import AppKit

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

    public var activeNotes: Set<UInt8> = []
    public var availableDestinations: [MIDIEndpointInfo] = []
    public var pitchBend: UInt16 = 8192
    public var modulation: UInt8 = 0 {
        didSet {
            for i in 0..<activeProfile.knobs.count {
                if activeProfile.knobs[i].controller == 1 && activeProfile.knobs[i].value != modulation {
                    activeProfile.knobs[i].value = modulation
                }
            }
        }
    }
    public var isOneShotMode: Bool {
        didSet {
            defaults.set(isOneShotMode, forKey: "kkbb.isOneShotMode")
        }
    }
    public var isAlwaysOnTop: Bool {
        didSet {
            defaults.set(isAlwaysOnTop, forKey: "kkbb.isAlwaysOnTop")
            applyWindowLevel()
        }
    }

    public var activeProfile: KeyBindingProfile {
        didSet {
            saveProfiles()
        }
    }
    public var userProfiles: [KeyBindingProfile] {
        didSet {
            saveProfiles()
        }
    }

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

        self.isOneShotMode = defaults.bool(forKey: "kkbb.isOneShotMode")
        self.isAlwaysOnTop = defaults.bool(forKey: "kkbb.isAlwaysOnTop")

        // Load profiles
        var loadedProfiles: [KeyBindingProfile] = []
        if let data = defaults.data(forKey: "kkbb.userProfiles"),
           let decoded = try? JSONDecoder().decode([KeyBindingProfile].self, from: data) {
            loadedProfiles = decoded
        }
        self.userProfiles = loadedProfiles

        if let activeIDStr = defaults.string(forKey: "kkbb.activeProfileID"),
           let activeUUID = UUID(uuidString: activeIDStr),
           activeUUID != KeyBindingProfile.defaultProfile.id,
           let found = loadedProfiles.first(where: { $0.id == activeUUID }) {
            self.activeProfile = found
        } else {
            self.activeProfile = KeyBindingProfile.defaultProfile
        }

        if let modKnob = self.activeProfile.knobs.first(where: { $0.controller == 1 }) {
            self.modulation = modKnob.value
        }
    }

    public var allProfiles: [KeyBindingProfile] {
        [KeyBindingProfile.defaultProfile] + userProfiles
    }

    public func selectProfile(_ profile: KeyBindingProfile) {
        self.activeProfile = profile
        if let modKnob = profile.knobs.first(where: { $0.controller == 1 }) {
            self.modulation = modKnob.value
        }
        defaults.set(profile.id.uuidString, forKey: "kkbb.activeProfileID")
    }

    public func selectProfile(id: UUID) {
        if id == KeyBindingProfile.defaultProfile.id {
            selectProfile(KeyBindingProfile.defaultProfile)
        } else if let found = userProfiles.first(where: { $0.id == id }) {
            selectProfile(found)
        }
    }

    public func updateActiveProfile() {
        if let idx = userProfiles.firstIndex(where: { $0.id == activeProfile.id }) {
            userProfiles[idx] = activeProfile
        }
        saveProfiles()
    }

    public func createProfile(name: String, duplicateFrom: KeyBindingProfile? = nil) {
        let base = duplicateFrom ?? activeProfile
        let newProfile = KeyBindingProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            isReadOnly: false,
            oneOctaveNoteMap: base.oneOctaveNoteMap,
            twoOctaveNoteMap: base.twoOctaveNoteMap,
            ccBindings: base.ccBindings,
            mouseVerticalVelocityEnabled: base.mouseVerticalVelocityEnabled,
            knobs: base.knobs
        )
        userProfiles.append(newProfile)
        selectProfile(newProfile)
        saveProfiles()
    }

    public func updateKnobValue(index: Int, value: UInt8) {
        guard index >= 0 && index < activeProfile.knobs.count else { return }
        activeProfile.knobs[index].value = value
        let knob = activeProfile.knobs[index]
        if knob.controller == 1 && modulation != value {
            modulation = value
        }
        MIDIPipeline.shared.sendCC(
            controller: knob.controller,
            value: value,
            channel: channel,
            destinationUID: selectedDestinationUID
        )
        if !activeProfile.isDefault {
            updateActiveProfile()
        }
    }

    public func updateKnobConfig(index: Int, label: String, controller: UInt8, defaultValue: UInt8) {
        guard index >= 0 && index < activeProfile.knobs.count else { return }
        activeProfile.knobs[index].label = label
        activeProfile.knobs[index].controller = controller
        activeProfile.knobs[index].defaultValue = defaultValue
        if controller == 1 {
            activeProfile.knobs[index].value = modulation
        }
        if !activeProfile.isDefault {
            updateActiveProfile()
        }
    }

    public func deleteProfile(id: UUID) {
        userProfiles.removeAll { $0.id == id }
        if activeProfile.id == id {
            selectProfile(KeyBindingProfile.defaultProfile)
        }
        saveProfiles()
    }

    public func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(userProfiles) {
            defaults.set(encoded, forKey: "kkbb.userProfiles")
        }
        defaults.set(activeProfile.id.uuidString, forKey: "kkbb.activeProfileID")
    }

    public func applyWindowLevel() {
        DispatchQueue.main.async {
            for window in NSApp.windows where !window.isSheet {
                window.level = self.isAlwaysOnTop ? .floating : .normal
            }
        }
    }
}
