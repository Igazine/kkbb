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
