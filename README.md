# KKBB — KeyKeyBoardBoard

A powerful, native macOS Virtual MIDI Keyboard and Performance Pad Controller that turns your Mac's computer keyboard into an expressive, ultra-low-latency MIDI instrument.

> **Note**: KKBB is currently a **"build for yourself"** project. Precompiled application binaries are not distributed at this time. Follow the simple [Building and Running](#building-and-running) instructions below to build and launch it locally on your Mac.

---

## Highlights

* **100% Native Swift & SwiftUI**: High performance, responsive layout, minimal resource footprint, designed specifically for Apple Silicon (`arm64`) Macs.
* **Instant CoreMIDI Virtual Source**: Publishes **"KKBB Virtual Output"** automatically. DAWs (Ableton Live, Logic Pro, Reaper, Bitwig Studio, FL Studio, GarageBand, etc.) detect it immediately without configuring IAC drivers.
* **Hardware MIDI Routing**: Direct output selection for external hardware synths, USB-MIDI interfaces, and software endpoints.
* **Polyphonic with OS Repeat Suppression**: Play chords fluidly while suppressing macOS key auto-repeat to avoid duplicate Note-On triggers.
* **Three Performance Modes**:
  * **1-Octave Piano Mode**: Fast, compact single-octave layout (C to C).
  * **2-Octave Piano Mode**: Two full octaves plus top C with natural dual-row physical key ergonomics.
  * **4x4 Pad Grid Mode**: MPC-style performance pad layout with 7 independent banks (112 total pads) and cross-bank triggering.
* **Expressive Chord Engine**:
  * **12-Pad Chord Strip**: Instant access to 14 standard chords and 20 Bitwig scales & modes with configurable hot-keys (F1–F12).
  * **Visual Root Distinction**: Pressed root notes glow in vivid accent blue with a centered white dot marker; harmonic chord extensions glow softly at dimmed opacity.
  * **Per-Key Chord Overrides**: Right-click any piano key to assign a distinct chord or scale with priority over the active chord pad.
* **Assignable Rotary Knobs**: 8 CC knobs with 270° sweep, vertical drag control, Shift for 4x fine precision, double-click reset, and right-click CC assignment presets or custom labels.
* **Performance Control Strip**: Dedicated VEL (Velocity 1–127), PTCH (14-bit Pitch Bend with spring-return to center), and MOD (CC #1 Modulation friction wheel).
* **One-Shot Trigger Mode**: 50 ms trigger pulse mode without sustain, ideal for samplers, drum machines, and grooveboxes.
* **Full Transport & MIDI CC Integration**: Assign pads to MIDI System Real-Time transport (`Start`, `Stop`, `Continue`), MMC SysEx, or arbitrary CC switches (Momentary, Toggle, Trigger).
* **Zero Audio Overhead**: Pure CoreMIDI engine. No audio synthesis, no DSP bloat, and zero latency.

---

## Interface Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│ Mode [2-Octave ▼]  Output [KKBB Virtual Output ▼]  Ch [1 ▼]  [✓] 1-Shot │
│ [PANIC]  [Settings ⌘,]                                                 │
├───────┬────────────────────────────────────────────────────────────────┤
│       │  [0]  [1]  [2]  [3]  [4]  [5]  [6]   (Octave / Bank Selector)  │
│ [VEL] ├────────────────────────────────────────────────────────────────┤
│       │  (O)  (O)  (O)  (O)  (O)  (O)  (O)  (O)  (8 Assignable Knobs) │
│ [PTCH]├────────────────────────────────────────────────────────────────┤
│       │  [ Piano Roll / 4x4 Performance Grid Area ]                    │
│ [MOD] ├────────────────────────────────────────────────────────────────┤
│       │  [1]   [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]  ...   [12] │
│       │  (12-Pad Quick Voicing & Bitwig Scale Strip)                   │
└───────┴────────────────────────────────────────────────────────────────┘
```

---

## Performance Modes

### 1. Piano Roll Modes (1-Octave & 2-Octave)
* **Visual Piano Keys**: Full white and black piano layout styled in macOS system grays.
* **Vertical Velocity Scaling**: Clicking/dragging with the mouse scales MIDI note velocity linearly from 1 (top of key) to 127 (bottom of key).
* **Glissando Drag**: Click and sweep across keys for smooth multi-note sweeps.
* **Polyphonic Chord Illumination**: When chords are played, the pressed root key is prominently lit with a centered white marker, while harmonic extension keys glow softly at a dimmer level.
* **Per-Key Chord Overrides**: Right-click any white or black key to assign a custom chord (e.g. `Min7` on `C4`). Keys with overrides display a subtle badge (e.g. `m7`).

### 2. 4x4 Pad Grid Mode
* **MPC-Style Performance Grid**: 16 tactile pads per bank with configurable hot-keys, root notes, octaves, voicings, commands, and CC triggers.
* **7 Independent Banks (112 Total Pads)**: The octave bar acts as Bank 0–6 selector.
* **Cross-Bank Playback**: All 112 pads remain actively triggerable by their assigned hot-keys regardless of which bank is currently displayed on screen.
* **Pad Assignments via Right-Click**:
  * **Hot-Key**: Interactive key recording sheet to assign any letter, number, or symbol.
  * **Root Note & Octave**: Note (C to B) and Octave (0 to 6).
  * **Chord Voicing**: No chord (single note), 14 chords, or 20 Bitwig scales.
  * **MIDI Transport Commands**:
    * **System Real-Time**: Start (`0xFA`), Stop (`0xFC`), Continue (`0xFB`).
    * **MMC SysEx**: Play, Stop, Pause, Record, Rewind, Fast Forward.
    * **Utilities**: All Notes Off (Panic).
  * **MIDI CC Buttons**:
    * **Presets**: Sustain Momentary, Sustain Toggle, Mod Wheel Max, Expression Max, Volume Max, Volume Mute, All Sound Off, Panic CC.
    * **Custom CC Sheet**: User-defined Controller # (0–127), Target/On Value (0–127), Off Value (0–127), and Mode (**Momentary**, **Toggle** with persistent visual lock, or **Trigger**).

---

## 12-Pad Chord Strip (Voicings & Scales)

Positioned directly below the piano roll, these 12 pads provide instant chord harmonizing transposed to whatever note you play:

* **Radio-Group Toggle**: Click an active pad to deactivate (return to single notes); click an inactive pad to activate.
* **Configurable Hot-Keys**: Defaulted to `F1`–`F12`; easily remapped in **Settings > Chord Pads** or via right-click context menu.
* **Voicing Choices**:
  * **Standard Chords**: Major, Minor, 5th (Power), Dom 7th, Maj 7th, Min 7th, Diminished, Augmented, Suspended 2, Suspended 4, 6th, Min 6th, 9th, Half-Diminished.
  * **Bitwig Scales & Modes**: Major (Ionian), Minor (Aeolian), Harmonic Minor, Melodic Minor, Pentatonic Major, Pentatonic Minor, Blues Major, Blues Minor, Dorian, Phrygian, Lydian, Mixolydian, Locrian, Whole Tone, Diminished (HW/WH), Spanish / Jewish, Hungarian Minor, Bebop Major, Bebop Minor.

---

## Default Key Bindings

### Navigation, Dynamics & Commands

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **Octave / Bank +1** | `*` or `↑` (Up Arrow) | Shifts octave up (+1) or bank up |
| **Octave / Bank -1** | `/` or `↓` (Down Arrow) | Shifts octave down (-1) or bank down |
| **Velocity -1** | `←` (Left Arrow) | Decreases fixed keyboard velocity by 1 |
| **Velocity -10** | `Shift` + `←` | Decreases fixed keyboard velocity by 10 |
| **Velocity +1** | `→` (Right Arrow) | Increases fixed keyboard velocity by 1 |
| **Velocity +10** | `Shift` + `→` | Increases fixed keyboard velocity by 10 |
| **Sustain Pedal** | `Space` *(piano modes)* | CC #64 Sustain momentary trigger (unless Space is assigned to a pad) |
| **Chord Pads 1–12** | `F1`–`F12` | Toggle Chord Voicing / Scale Pads 1–12 |
| **Settings** | `⌘` + `,` | Opens Settings & Profiles modal |
| **Panic** | `⌘` + `.` | All Notes Off & Sound Reset |

---

### One-Octave Piano Mode Key Mapping

| Key | Note | Type | Key | Note | Type |
| :---: | :---: | :---: | :---: | :---: | :---: |
| `a` | C | White | `y` | G# | Black |
| `w` | C# | Black | `h` | A | White |
| `s` | D | White | `u` | A# | Black |
| `e` | D# | Black | `j` | B | White |
| `d` | E | White | `k` | C *(+1)* | White |
| `f` | F | White | `o` | C# *(+1)* | Black |
| `t` | F# | Black | `l` | D *(+1)* | White |
| `g` | G | White | `p` | D# *(+1)* | Black |

---

### Two-Octave Piano Mode Key Mapping

#### Lower Octave
| Key | Note | Type | Key | Note | Type |
| :---: | :---: | :---: | :---: | :---: | :---: |
| `z` | C | White | `v` | F | White |
| `s` | C# | Black | `g` | F# | Black |
| `x` | D | White | `b` | G | White |
| `d` | D# | Black | `h` | G# | Black |
| `c` | E | White | `n` | A | White |
| `j` | A# | Black | `m` | B | White |
| `,` | C *(Oct 2)* | White | | | |

#### Upper Octave
| Key | Note | Type | Key | Note | Type |
| :---: | :---: | :---: | :---: | :---: | :---: |
| `q` | C *(Oct 2)* | White | `y` | A *(Oct 2)* | White |
| `2` | C# *(Oct 2)* | Black | `7` | A# *(Oct 2)* | Black |
| `w` | D *(Oct 2)* | White | `u` | B *(Oct 2)* | White |
| `3` | D# *(Oct 2)* | Black | `i` | C *(Oct 3)* | White |
| `e` | E *(Oct 2)* | White | `9` | C# *(Oct 3)* | Black |
| `r` | F *(Oct 2)* | White | `o` | D *(Oct 3)* | White |
| `5` | F# *(Oct 2)* | Black | `0` | D# *(Oct 3)* | Black |
| `t` | G *(Oct 2)* | White | `p` | E *(Oct 3)* | White |
| `6` | G# *(Oct 2)* | Black | | | |

---

## Building and Running

KKBB is built for Apple Silicon Macs running **macOS 14.0 (Sonoma)** or later.

### Requirements
* **macOS 14.0+**
* **Apple Silicon Mac** (M1, M2, M3, M4 or later)
* **Xcode 15.0+** (or Command Line Tools with Swift 5.9+)

### Build & Run from Xcode
1. Clone or download the repository:
   ```bash
   git clone https://github.com/Igazine/kkbb.git
   cd kkbb
   ```
2. Open the Xcode project:
   ```bash
   open KKBB.xcodeproj
   ```
3. Select the **KKBB** scheme and your Mac as the destination.
4. Press `Cmd + R` to build and run.

### Build & Run from Terminal
```bash
# Clone the repository
git clone https://github.com/Igazine/kkbb.git
cd kkbb

# Compile the macOS application
xcodebuild -scheme KKBB -destination 'platform=macOS,arch=arm64' build

# Launch the compiled app
open $(find ~/Library/Developer/Xcode/DerivedData -name "KKBB.app" 2>/dev/null | head -n 1)
```

---

## MIDI Architecture

KKBB features an intermediate pipeline separating note triggers and controllers from physical MIDI transmission:

```
[Physical Keyboard / Mouse Drag / Chord Pads]
                     │
                     ▼
             [KeyboardMonitor]
                     │ (Dispatches MIDIEvent)
                     ▼
              [MIDIPipeline] ◄── [Processors Chain: Scales, Transpose, Chords]
                     │
                     ▼ (Conforms to MIDIEventReceiver)
               [MIDIManager]
                     │
        ┌────────────┴──────────────────────────┐
        ▼                                       ▼
 [Virtual CoreMIDI Source]           [Hardware / DAW Endpoints]
   "KKBB Virtual Output"              (USB Synths, Interfaces, IAC)
```

* **CoreMIDI Virtual Source**: The `"KKBB Virtual Output"` port automatically appears in any DAW MIDI input list without manual configuration.
* **Clean State Transitions**: Switching modes, banks, or octave clears stuck notes, with an instant `Panic` button available via `Cmd + .` or top-bar control.

---

## Screenshots

![1-Octave Screen](screenshots/Screenshot%202026-09-17%20at%2019.20.46.png)
![2-Octave Screen](screenshots/Screenshot%202026-09-17%20at%2019.25.39.png)
![4x4 Grid/Pad Mode](screenshots/Screenshot%202026-09-17%20at%2019.26.37.png)

---

## License

This project is open-source software licensed under the [MIT License](LICENSE).
