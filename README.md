# KKBB — KeyKeyBoardBoard

A native macOS Virtual MIDI Keyboard that transforms your Mac computer keyboard into a responsive, polyphonic MIDI controller with zero latency, an adaptive piano roll, and direct DAW integration.

---

## Features

* **Native macOS App**: Built purely with Swift and SwiftUI targeting modern Apple Silicon (`arm64`) Macs.
* **CoreMIDI Virtual Source**: Publishes its own virtual MIDI source (**"KKBB Virtual Output"**). DAWs (Logic Pro, Ableton Live, Reaper, GarageBand, FL Studio, etc.) detect it immediately without manual IAC driver configuration.
* **Hardware Output Routing**: Supports routing MIDI output simultaneously to external hardware synthesizers, USB MIDI interfaces, or other system endpoints.
* **Polyphonic & Repeat-Suppressed**: Handles multi-key chords simultaneously while suppressing macOS keyboard auto-repeat to prevent unwanted Note-On re-triggering.
* **Two Keyboard Modes**:
  * **1-Octave Mode**: Compact 13-key layout (C to C).
  * **2-Octave Mode**: Extended 25-key dual-row layout with physical key alignment.
* **Adaptive Piano Roll**:
  * White keys in system gray (`NSColor.systemGray`) and black keys in dark gray (`NSColor.darkGray`).
  * Non-fatiguing accent highlighting for active notes.
  * Dynamically scales to fill any window size without horizontal scrolling.
  * Click and drag (glissando) support for mouse/trackpad play.
* **Decoupled MIDI Processing Pipeline**: Built-in abstract pipeline layer (`MIDIPipeline`, `MIDIProcessor`) allowing future effects (arpeggiators, chord harmonizers, MIDI echo/delay) without altering hardware output logic.
* **Pure CoreMIDI**: Zero audio synthesis or 3rd-party audio engines.

---

## Key Bindings

### Navigation & Dynamics

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **Octave Up** | `↑` (Up Arrow) or `*` | Shifts base octave up (+1) |
| **Octave Down** | `↓` (Down Arrow) or `/` | Shifts base octave down (-1) |
| **Velocity -1** | `←` (Left Arrow) | Decreases MIDI note velocity by 1 |
| **Velocity -10** | `Shift` + `←` | Decreases MIDI note velocity by 10 |
| **Velocity +1** | `→` (Right Arrow) | Increases MIDI note velocity by 1 |
| **Velocity +10** | `Shift` + `→` | Increases MIDI note velocity by 10 |
| **Panic** | `Cmd` + `.` | All Notes Off / All Sound Off |

---

### One-Octave Mode

| Key | Note | Type |
| :--- | :--- | :--- |
| `a` | C | White |
| `w` | C# | Black |
| `s` | D | White |
| `e` | D# | Black |
| `d` | E | White |
| `f` | F | White |
| `t` | F# | Black |
| `g` | G | White |
| `y` | G# | Black |
| `h` | A | White |
| `u` | A# | Black |
| `j` | B | White |
| `k` | C *(next octave)* | White |

---

### Two-Octave Mode

#### Lower Octave
| Key | Note | Type |
| :--- | :--- | :--- |
| `z` | C | White |
| `s` | C# | Black |
| `x` | D | White |
| `d` | D# | Black |
| `c` | E | White |
| `v` | F | White |
| `g` | F# | Black |
| `b` | G | White |
| `h` | G# | Black |
| `n` | A | White |
| `j` | A# | Black |
| `m` | B | White |
| `,` | C *(octave 2)* | White |

#### Upper Octave
| Key | Note | Type |
| :--- | :--- | :--- |
| `q` | C *(octave 2)* | White |
| `2` | C# | Black |
| `w` | D | White |
| `3` | D# | Black |
| `e` | E | White |
| `r` | F | White |
| `5` | F# | Black |
| `t` | G | White |
| `6` | G# | Black |
| `y` | A | White |
| `7` | A# | Black |
| `u` | B | White |
| `i` | C *(top octave 3)* | White |

---

## Building and Running

### Requirements
* macOS 14.0 or later
* Apple Silicon Mac (M1/M2/M3/M4)
* Xcode 15 or later

### From Xcode
```bash
open KKBB.xcodeproj
```
Select the **KKBB** scheme and press **Cmd + R** to run.

### From Command Line
```bash
# Build Debug binary
xcodebuild -scheme KKBB -destination 'platform=macOS,arch=arm64' build

# Launch application
open $(find ~/Library/Developer/Xcode/DerivedData -name "KKBB.app" 2>/dev/null | head -n 1)
```

---

## Architecture

```
[Key Events / Mouse Gestures]
             │
             ▼
      [KeyboardMonitor]
             │  (Dispatches MIDIEvent)
             ▼
       [MIDIPipeline] ◄─── Processors Chain (Arpeggiator, Chords, etc.)
             │
             ▼  (Conforms to MIDIEventReceiver)
       [MIDIManager]
             │
      ┌──────┴──────────────────────┐
      ▼                             ▼
[Virtual Source: KKBB Virtual Output]  [Hardware MIDI Destination]
```

---

## License

This project is open-source software licensed under the [MIT License](LICENSE).
