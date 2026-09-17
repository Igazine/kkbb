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
            KeyboardMonitor.shared.allNotesOff()
            activeDrumPadIndices.removeAll()
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
            if mode == .drumGrid {
                KeyboardMonitor.shared.allNotesOff()
                activeDrumPadIndices.removeAll()
            }
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

    public var activeChordPadIndex: Int? = nil
    public var activeDrumPadIndices: Set<Int> = []

    public var activeChordType: ChordType? {
        guard let idx = activeChordPadIndex,
              idx >= 0 && idx < activeProfile.chordPads.count else {
            return nil
        }
        let pad = activeProfile.chordPads[idx]
        return pad.chordTypeID == "none" ? nil : ChordType.find(by: pad.chordTypeID)
    }

    /// Resolves the effective chord for a given root note:
    /// Key-specific assignments have strict precedence over the global Chord Pad voicing!
    public func effectiveChord(for note: UInt8) -> ChordType? {
        if let customID = activeProfile.customKeyChords[note], customID != "none" {
            return ChordType.find(by: customID)
        }
        return activeChordType
    }

    /// Returns the transposed note array for a played root note.
    public func notesForRoot(_ root: UInt8) -> [UInt8] {
        if let chord = effectiveChord(for: root) {
            return chord.intervals.compactMap { offset in
                let final = Int(root) + offset
                return (0...127).contains(final) ? UInt8(final) : nil
            }
        }
        return [root]
    }

    public func assignChord(to note: UInt8, chordTypeID: String?) {
        if let id = chordTypeID, id != "none" {
            activeProfile.customKeyChords[note] = id
        } else {
            activeProfile.customKeyChords.removeValue(forKey: note)
        }
        if !activeProfile.isDefault {
            updateActiveProfile()
        } else {
            saveDefaultCustomKeyChords()
        }
    }

    public func clearAllCustomKeyChords() {
        activeProfile.customKeyChords.removeAll()
        if !activeProfile.isDefault {
            updateActiveProfile()
        } else {
            defaults.removeObject(forKey: "kkbb.defaultCustomKeyChords")
        }
    }

    private func saveDefaultCustomKeyChords() {
        if let encoded = try? JSONEncoder().encode(activeProfile.customKeyChords) {
            defaults.set(encoded, forKey: "kkbb.defaultCustomKeyChords")
        }
    }

    // MARK: - Drum Pad Management
    public func drumPadConfig(bank: Int, padIndex: Int) -> DrumPadConfig? {
        let key = "\(bank)_\(padIndex)"
        return activeProfile.drumPads[key]
    }

    public func updateDrumPadConfig(_ config: DrumPadConfig) {
        let key = "\(config.bank)_\(config.padIndex)"
        activeProfile.drumPads[key] = config
        saveDrumPads()
    }

    public func clearDrumPad(bank: Int, padIndex: Int) {
        let key = "\(bank)_\(padIndex)"
        activeProfile.drumPads.removeValue(forKey: key)
        saveDrumPads()
    }

    private func saveDrumPads() {
        if !activeProfile.isDefault {
            updateActiveProfile()
        } else {
            if let encoded = try? JSONEncoder().encode(activeProfile.drumPads) {
                defaults.set(encoded, forKey: "kkbb.defaultDrumPads")
            }
        }
    }

    public func triggerDrumPadOn(bank: Int, padIndex: Int, velocityOverride: UInt8? = nil) {
        guard let config = drumPadConfig(bank: bank, padIndex: padIndex), config.isAssigned else { return }
        let notes = config.notesToSend
        guard !notes.isEmpty else { return }
        let vel = velocityOverride ?? UInt8(velocity)

        activeDrumPadIndices.insert(padIndex)

        for note in notes {
            MIDIPipeline.shared.sendNoteOn(
                note: note,
                velocity: vel,
                channel: channel,
                destinationUID: selectedDestinationUID
            )
        }

        if isOneShotMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.triggerDrumPadOff(bank: bank, padIndex: padIndex)
            }
        }
    }

    public func triggerDrumPadOff(bank: Int, padIndex: Int) {
        guard let config = drumPadConfig(bank: bank, padIndex: padIndex), config.isAssigned else {
            activeDrumPadIndices.remove(padIndex)
            return
        }
        let notes = config.notesToSend
        activeDrumPadIndices.remove(padIndex)

        for note in notes {
            MIDIPipeline.shared.sendNoteOff(
                note: note,
                velocity: 0,
                channel: channel,
                destinationUID: selectedDestinationUID
            )
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
            var defaultProf = KeyBindingProfile.defaultProfile
            if let padData = defaults.data(forKey: "kkbb.defaultChordPads"),
               let customPads = try? JSONDecoder().decode([ChordPadConfig].self, from: padData) {
                defaultProf.chordPads = customPads
            }
            if let knobData = defaults.data(forKey: "kkbb.defaultKnobs"),
               let customKnobs = try? JSONDecoder().decode([KnobConfig].self, from: knobData) {
                defaultProf.knobs = customKnobs
            }
            if let chordData = defaults.data(forKey: "kkbb.defaultCustomKeyChords"),
               let customChords = try? JSONDecoder().decode([UInt8: String].self, from: chordData) {
                defaultProf.customKeyChords = customChords
            }
            if let drumData = defaults.data(forKey: "kkbb.defaultDrumPads"),
               let customDrums = try? JSONDecoder().decode([String: DrumPadConfig].self, from: drumData) {
                defaultProf.drumPads = customDrums
            }
            self.activeProfile = defaultProf
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
            knobs: base.knobs,
            chordPads: base.chordPads,
            customKeyChords: base.customKeyChords
        )
        userProfiles.append(newProfile)
        selectProfile(newProfile)
        saveProfiles()
    }

    public func toggleChordPad(index: Int) {
        if activeChordPadIndex == index {
            activeChordPadIndex = nil
        } else {
            activeChordPadIndex = index
        }
    }

    public func updateChordPad(index: Int, chordTypeID: String) {
        guard index >= 0 && index < activeProfile.chordPads.count else { return }
        activeProfile.chordPads[index].chordTypeID = chordTypeID
        if !activeProfile.isDefault {
            updateActiveProfile()
        } else {
            saveDefaultChordPads()
        }
    }

    public func updateChordPadBinding(index: Int, keyTrigger: String, keyCode: UInt16?, modifierFlags: UInt?) {
        guard index >= 0 && index < activeProfile.chordPads.count else { return }
        activeProfile.chordPads[index].keyTrigger = keyTrigger
        activeProfile.chordPads[index].keyCode = keyCode
        activeProfile.chordPads[index].modifierFlags = modifierFlags
        if !activeProfile.isDefault {
            updateActiveProfile()
        } else {
            saveDefaultChordPads()
        }
    }

    public func updateChordPadTrigger(index: Int, keyTrigger: String) {
        guard index >= 0 && index < activeProfile.chordPads.count else { return }
        activeProfile.chordPads[index].keyTrigger = keyTrigger.trimmingCharacters(in: .whitespaces)
        activeProfile.chordPads[index].keyCode = nil
        activeProfile.chordPads[index].modifierFlags = nil
        if !activeProfile.isDefault {
            updateActiveProfile()
        } else {
            saveDefaultChordPads()
        }
    }

    public func resetChordPadsToDefault() {
        activeProfile.chordPads = ChordPadConfig.defaultPads
        if !activeProfile.isDefault {
            updateActiveProfile()
        } else {
            defaults.removeObject(forKey: "kkbb.defaultChordPads")
        }
    }

    private func saveDefaultChordPads() {
        if let encoded = try? JSONEncoder().encode(activeProfile.chordPads) {
            defaults.set(encoded, forKey: "kkbb.defaultChordPads")
        }
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
        } else {
            if let encoded = try? JSONEncoder().encode(activeProfile.knobs) {
                defaults.set(encoded, forKey: "kkbb.defaultKnobs")
            }
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
