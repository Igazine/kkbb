# KKBB - KeyKeyBoardBoard

macOS Native Virtual Midi Keyboard that uses the computer keyboard to send MIDI data through the available MIDI devices.

## Features

* macOS native desktop app
* Virtual MIDI Keyboard
* Uses the computer keyboard to send MIDI data through the available MIDI devices
* Minimalistic UI, some settings at the top (see below), a piano roll at the bottom
* One-octave and 2-octave modes

## UI

* A minimal, uncluttered bar at the top for settings and status information (aligned along bottom baseline):
* * Modes (dropdown): 1-octave, 2-octave
* * Output (dropdown): List of available MIDI devices (including virtual output)
* * Channel (dropdown): 1-16
* * One-Shot (checkbox): 50 ms trigger pulse mode without sustain (ideal for drum computers and samplers)
* * Panic (button): All Notes Off
* * Settings (button / ⌘,): Modal dialog for configuring profiles, note mappings, MIDI CC triggers, and dynamics
* Left Control Strip:
* * VEL (fader): Velocity slider (1–127) for fixed computer keyboard velocity
* * PTCH (wheel): 14-bit Pitch Bend wheel (0...16383), spring-loaded to center (8192)
* * MOD (wheel): Standard CC #1 Modulation wheel (0...127), friction-loaded
* Octave Selector Bar:
* * 7 rounded blocks positioned directly above the piano keys representing Octaves 0 to 6
* * Clicking selects the octave; active octave is highlighted in accent blue
* Assignable Knobs Strip:
* * 8 rotary knobs positioned directly above the piano roll (below octave selector)
* * Controls arbitrary MIDI Continuous Controllers (CC 0–127)
* * 270° rotary sweep (value 0 at bottom-left, 127 at bottom-right) with circular active track and rotary indicator tick
* * Vertical mouse drag adjustment (drag up to increase, down to decrease); Shift key enables 4x fine-tuning precision
* * Double-click to snap back to default value
* * Right-click context menu to select common CC presets (Modulation, Breath, Volume, Pan, Expression, Resonance, Cutoff, Reverb, etc.), custom CC assignment with custom labels, or reset to default
* Piano Roll at the bottom. White and Black keys according to a regular piano layout
* * In 1-octave mode, the piano roll shows one octave
* * In 2-octave mode, the piano roll shows two octaves + top C
* * Key press highlights key; key release unhighlights key
* * Vertical Mouse Position Velocity Scaling: Clicking/dragging with mouse scales velocity linearly (1 at top to 127 at bottom)
* * White keys colored in system gray; black keys in system dark gray
* * Tab key navigation: cycles strictly through the top bar controls; performance area below is exempt from Tab focus
* * Clicking below top bar automatically clears keyboard focus from top bar controls
* * Per-Key Chord Overrides: Right-clicking any individual white or black key on the piano roll opens a context menu to assign a specific chord/scale to that key (e.g. Min7 to C4)
* * Precedence: Individual key chord assignments have precedence over the active Chord Pad selection (e.g. if Maj7 is selected on the chord pad, playing C4 triggers Min7 while all other keys trigger Maj7)
* * Visual Feedback: Keys with custom chord assignments display a subtle info badge in faded gray at the top of their existing key labels (e.g. "m7")
* Chord Pads Strip:
* * 12 equally distributed performance boxes at the very bottom of the UI (directly below the piano roll)
* * Configurable hot-keys (defaulting to F1–F12); editable via right-click context menu "Change Hot-Key…" sheet or Settings > Chord Pads tab
* * Radio-group behavior: clicking an active pad deactivates chord mode (returns to single-note mode); clicking an inactive pad activates it
* * Right-click context menu to choose voicing: "No Chord (Single Note)", 14 standard Chords (Major, Minor, 7th, Maj7, Min7, Half-Dim, etc.), or 20 Bitwig Scales & Modes (Pentatonic, Blues, Dorian, Mixolydian, Harmonic, etc.)
* * Transposition: playing any note key (or clicking a piano roll key) transmits all chord notes transposed to that root
* * Polyphonic illumination: piano roll illuminates all notes comprising the triggered chord; the pressed root key is prominently highlighted at full opacity with a centered white circle marker, while harmonic extension chord keys are displayed at a softer, dimmer opacity for instant visual distinction
* Alternate Layout (4x4 Drum / Pad Grid):
* * Selectable via Mode dropdown ("4x4 Grid"); replaces the piano roll and chord pads with an MPC-style 4x4 performance grid
* * 7 Banks navigation: the octave selector acts as Bank 0–6 selector (navigated via click or `*` / `/` shortcuts), offering 7 × 16 = 112 totally independent pads
* * Cross-Bank Playback: Switching banks changes the visible 16 pads, but all 112 pads across all 7 banks remain actively triggerable by their assigned hot-keys without being disabled
* * Fully customizable pads: right-click context menu assigns Hot-Key (interactive recording sheet), Root Note (C to B), Octave (0 to 6), Chord Voicing (No Chord, 14 standard chords, 20 Bitwig scales), MIDI Command (Transport & Utilities), or MIDI Control Change (CC)
* * MIDI Commands: Pads can be assigned to standardized System Real-Time transport (Start 0xFA, Stop 0xFC, Continue 0xFB), MMC SysEx transport (Play, Stop, Pause, Record, Rewind, Fast Forward), or All Notes Off (Panic); command pads trigger one-shot commands via virtual source and active destination endpoint with momentary pad flash
* * MIDI Control Change (CC) Buttons: Pads can be assigned to popular CC presets (Sustain Momentary, Sustain Toggle, Mod Wheel Full, Expression Full, Volume Full, Volume Mute, All Sound Off, Panic CC) or custom CC configurations with user-defined Controller # (0–127), On/Trigger value (0–127), Off value (0–127), Mode (Momentary, Toggle, Trigger), and custom labels (e.g. MUTE, FILTER, SUSTAIN)
* * Pad labels show assigned Key combination, Note + Octave (e.g. C1), Command Badge (e.g. ▶ PLAY, ■ STOP, ❚❚ PAUSE, ● REC), or CC Label (e.g. CC 64, SUSTAIN), along with sub-badge (e.g. m7, REALTIME, MMC, SYS, CC·MOM, CC·TOG, CC·TRG); unassigned pads display empty
* * Visual Feedback: Active pad glows in accent blue upon physical keyboard press, mouse trigger, or when locked in CC Toggle ON state
* * Mode Isolation: When in 4x4 Grid mode, piano roll keyboard triggers are bypassed; when in piano modes, drum grid triggers are bypassed
* * Unified Layout Save & Load: Save and load complete performance setups (including 4x4 Pad Grid setups across Banks 0–6, Computer Keyboard layouts, sub-layouts, and modifier layers) to and from unified local files (`.kkbb` / `.json`) via File menu commands (New `⌘N`, Open `⌘O`, Save `⌘S`, Save As `⇧⌘S`). Automatically restores mode and displays layout name in window subtitle.
* Alternate Layout (Computer Keyboard):
* * Selectable via Mode dropdown ("Computer Keyboard"); renders an interactive, 1:1 visual computer keyboard layout with assignable performance keys.
* * Sub-Layout Selector (Segmented Picker): "MacBook (75%)" and "Full 101-Key" (includes complete 6-key Navigation cluster with `Ins` (114) & `Del` (117), and full Numpad).
* * Modifier Layers: Performance keys support 3 independent layers—Base, Shift (`⇧`), and Option (`⌥`). Selected via top-bar segmented picker or live-previewed dynamically upon holding physical `Shift` or `Option` keys.
* * Proportionally Scalable Geometry: Dynamically scales key widths and heights to fit within the default window footprint (well under 1000×600 px) without scrollbars.
* * Passive Modifier Distinction: Non-configurable system modifiers (`Cmd`, `Ctrl`, `Opt`, `Fn`, `Caps Lock`) are dimmed in soft passive opacity (~18–40%), while configurable keys are rendered prominently with clear contrast.
* * Fully Customizable Performance Keys: Right-click context menu assigns Root Note (C to B), Octave (0 to 6), Chord Voicing (No Chord, 14 standard chords, 20 Bitwig scales), MIDI Command (Real-Time Transport, MMC SysEx, All Notes Off), or MIDI Control Change (CC presets & custom CC sheet) for the active layer. Includes "Copy from Base Layer" convenience.
* * Instant DragGesture Mouse Triggering: Mouse clicks on keycaps trigger Note-On/CC immediately on press, sustain while held, and release on mouse up.
* * Visual Feedback: Active key glows with solid blue fill when assigned; unassigned configurable keys display an accent blue border with blue glow and no MIDI output.
* * Profile Persistence: Computer keyboard key configurations across all layers are automatically persisted in the active `KeyBindingProfile` JSON structure under `computerKeyboardKeys`.
* Live MIDI Event Monitor & Status Strip:
* * Hardware-inspired status strip docked at the bottom of the window below the performance area.
* * 4 color-coded activity LEDs (Note-On in Green, Note-Off in Dim White, CC in Amber, Pitch/Sys/Transport in Cyan) with momentary physical glow pulses.
* * Monospaced rolling event ticker displaying timestamp (`HH:mm:ss.SSS`), channel, event type, data description, raw hexadecimal bytes, and destination.
* * Dual Display Modes: Collapsed 24px hardware status bar (default) or expanded 108px multi-row terminal log showing recent 60 events with newest on top.
* * Controls: Quick toggle button in TopBarView (`waveform.path.ecg`), View menu commands (`⌥⌘M`), clear log button, and collapsible drawer chevron.

## Tech Stack

* macOS Native
* XCode project, Swift programming language
* Should use the latest available versions of XCode and Swift, and support the latest version of macOS.
* Apple Silicon (Arm) only. No Intel version is needed (no Universal Binary either)
* Key press sends MIDI note to selected device/channel with the selected velocity
* Key release sends MIDI note off to selected device/channel with the selected velocity
* The selected device/channel are stored for future use.
* Since computer keyboard keys have no pressure sensitivity, the app always sends the selected note to MIDI with the given velocity
* Multiple piano keys can be pressed at once (as much as the current OS supports, probably 6 or 10 keys)
* OS key repeat suppression: repeated `keyDown` events when keys are held down must be filtered to prevent re-triggering Note-On
* CoreMIDI virtual source endpoint: KKBB publishes its own virtual MIDI source ("KKBB Virtual Output") so DAWs (Logic Pro, Ableton Live, Reaper, etc.) can directly detect and receive MIDI from KKBB without manual IAC driver configuration, while also allowing output to external MIDI destination endpoints
* Intermediate abstract MIDI processing pipeline (`MIDIPipeline`, `MIDIProcessor`): decoupled layer between note generation (key press/release) and physical CoreMIDI send, designed to host future MIDI processors/effects (arpeggiators, chord harmonizers, MIDI echo/delay) without altering hardware output logic.
* Absolutely no audio signal will be sent or received from and to KKBB. KKBB will only send MIDI data to other MIDI-capable apps or hardware. In other words: do not use any audio APIs,CoreAudio (it's allowed) or otherwise. Only CoreMIDI is allowed. No 3rd-party audio/MIDI engine will be used either (eg. VST, etc.)

## Key Bindings

### General

* `*` or `↑` (Up Arrow) - Octave +1
* `/` or `↓` (Down Arrow) - Octave -1
* `←` (Left Arrow) - Velocity -1 (or -10 with `Shift` + `←`)
* `→` (Right Arrow) - Velocity +1 (or +10 with `Shift` + `→`)
* `F1`–`F12` (default, configurable per pad) - Toggle Chord Pad 1–12 (Single Note / Major / Minor / 7th / Maj7 / Min7 / Half-Dim / Sus4 / MajPent / MinPent / BluesMinor / Dorian)

### One-octave mode

* `a` - Send note C to selected MIDI device/channel
* `w` - Send note C#
* `s` - Send note D
* `e` - Send note D#
* `d` - Send note E
* `f` - Send note F
* `t` - Send note F#
* `g` - Send note G
* `y` - Send note G#
* `h` - Send note A
* `u` - Send note A#
* `j` - Send note B
* `k` - Send note C (next octave)
* `o` - Send note C# (next octave)
* `l` - Send note D (next octave)
* `p` - Send note D# (next octave)

### Two-octave mode

* `z` - Send note C to selected MIDI device/channel
* `s` - Send note C#
* `x` - Send note D
* `d` - Send note D#
* `c` - Send note E
* `v` - Send note F
* `g` - Send note F#
* `b` - Send note G
* `h` - Send note G#
* `n` - Send note A
* `j` - Send note A#
* `m` - Send note B
* `,` - Send note C (octave 2)
* `q` - Send note C (octave 2)
* `2` - Send note C# (octave 2)
* `w` - Send note D (octave 2)
* `3` - Send note D# (octave 2)
* `e` - Send note E (octave 2)
* `r` - Send note F (octave 2)
* `5` - Send note F# (octave 2)
* `t` - Send note G (octave 2)
* `6` - Send note G# (octave 2)
* `y` - Send note A (octave 2)
* `7` - Send note A# (octave 2)
* `u` - Send note B (octave 2)
* `i` - Send note C (octave 3)
* `9` - Send note C# (octave 3)
* `o` - Send note D (octave 3)
* `0` - Send note D# (octave 3)
* `p` - Send note E (octave 3)

## Additional notes, may change later

* A local git repository is created and initialized on branch `main` with `.gitignore` excluding Xcode/build/system artifacts.
* Currently there's no remote repository created for this project. I'll create one once the project is in usable state
* The Agent should discuss questionable features/solutions with the Architect (the User of the Agent), challenge them if necessary
* Although a nicely laid out UI is preferred, functionality is the most important part of the app. If there's a trade-off to be made between the two, functionality wins.
