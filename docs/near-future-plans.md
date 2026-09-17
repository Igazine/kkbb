# Near-Future Plans: MIDI Clock Sync & Modular Device Rack

This document outlines the architecture, investigations, and technical roadmap for future time-synchronized MIDI features and bottom rack expansion in KKBB.

---

## 1. MIDI Clock & Synchronization

### Purpose
To drive time-synchronized effects, modulators, and playback devices (such as Arpeggiators, LFOs, Note Repeat, Step Sequencers, and MIDI Delays) locked to a project tempo.

### Synchronization Modes

1. **OFF / Free-running**:
   - Internal clock disabled or uncoupled from external tempo. Effects operate in free-running Hz or fixed-millisecond intervals.

2. **MIDI Clock (Slave - Recommended for DAW Integration)**:
   - **Protocol**: Standard MIDI 1.0 System Real-Time messages (single-byte status bytes sent across the virtual or hardware MIDI input):
     - `0xF8`: **Timing Clock** (sent exactly 24 times per quarter note / 24 PPQN).
     - `0xFA`: **Start** (resets song position to beat 1 tick 0 and begins playback).
     - `0xFB`: **Continue** (resumes playback from current position).
     - `0xFC`: **Stop** (pauses/halts playback).
     - `0xF2`: **Song Position Pointer** (optional 14-bit position in 1/16th note units).
   - **CoreMIDI Implementation**:
     - KKBB establishes a `MIDIInputPort` on its `MIDIClientRef`.
     - Subscribes to the selected MIDI device or a virtual input endpoint ("KKBB Virtual Input").
     - On incoming `0xF8` packet arrival, measures delta timestamps using macOS high-precision `mach_absolute_time()`.
     - Computes instantaneous and smoothed BPM:
       $$\text{BPM} = \frac{60}{\Delta t \times 24}$$
     - Maintains a running `clockTickCount` (`0...23` per quarter note). Every 6 ticks corresponds to a $1/16\text{th}$ note; every 12 ticks to an $1/8\text{th}$ note.

3. **Internal BPM (Master Mode)**:
   - KKBB generates its own clock ticks using a high-precision `DispatchSourceTimer` running on a dedicated audio-priority dispatch queue.
   - User adjusts BPM (e.g. 20.0 to 300.0 BPM) and tap tempo.
   - Generates and broadcasts `0xF8` packets to connected endpoints.

### Ableton Link Assessment
- **Status**: **Not recommended** for initial implementation.
- **Rationale**: Ableton Link is written in C++ (`linkkit` / Asio) and has no native Swift API. It requires C++ interop bridging, UDP multicast network configuration, and complex threading. CoreMIDI `0xF8` MIDI Clock is 100% native, lightweight, zero-latency, requires zero third-party dependencies, and is supported by every DAW on macOS (Logic Pro, Ableton Live, Reaper, Bitwig, Cubase, FL Studio).

---

## 2. Modular Bottom Device Rack (Effects & Modulators)

### Concept
The bottom section of the application (below the piano roll) will host an expandable modular rack for real-time MIDI processors.

### Planned Processors
1. **Arpeggiator**:
   - Time-synced note ordering: Up, Down, Up/Down, Random, Chord, As Played.
   - Rates: $1/4$, $1/8$, $1/16$, $1/32$ (including dotted and triplet rates locked to MIDI Clock ticks).
   - Octave range ($1$–$4$ octaves), gate length ($1\%$–$200\%$), and swing/shuffle.

2. **Chord Harmonizer**:
   - Single-key chord triggering (Triads, 7ths, 9ths, Suspended, Inversions) with scale quantization.

3. **MIDI LFO / Envelope Modulator**:
   - Low-frequency oscillators routable to assignable MIDI CCs (Filter Cutoff, Pan, Volume, etc.).
   - Waveforms: Sine, Triangle, Saw, Square, Sample & Hold (Random).
   - Tempo-synced rate (1/1, 1/2, 1/4, 1/8, 1/16) or free-running Hz.

4. **Quantizer & Velocity Humanizer / Randomizer**:
   - Real-time scale snapping (Major, Minor, Dorian, Pentatonic, Blues, etc.).
   - Subtle randomized velocity and timing shifts for natural performance feel.

### Pipeline Architecture
All devices will conform to the existing `MIDIProcessor` protocol in KKBB's `MIDIPipeline`:
```swift
public protocol MIDIProcessor: AnyObject {
    var isEnabled: Bool { get set }
    func process(event: MIDIEvent) -> [MIDIEvent]
}
```
Events flow from:
$$\text{Keyboard Input} \longrightarrow \text{Pipeline} \longrightarrow [\text{Device 1}] \longrightarrow [\text{Device 2}] \dots \longrightarrow \text{CoreMIDI Hardware/Virtual Output}$$
