# KKBB - KeyKeyBoardBoard

macOS Native Virtual Midi Keyboard that uses the computer keyboard to send MIDI data through the available MIDI devices.

## Features

* macOS native desktop app
* Virtual MIDI Keyboard
* Uses the computer keyboard to send MIDI data through the available MIDI devices
* Minimalistic UI, some settings at the top (see below), a piano roll at the bottom
* One-octave and 2-octave modes

## UI

* A minimal bar at the top for settings and status information:
* * Modes (dropdown): 1-octave, 2-octave
* * Output (dropdown): List of available MIDI devices
* * Channel (dropdown): 1-16
* * Octave (slider): 0 to 6 (the default octave is 3, as in C3 is the lowest note on the piano roll)
* * Velocity (slider): 1-127 (default: 100)
* * Zoom (slider): 0.5 to 4.0 in 0.25 increments (the default is 1.0)
* Piano Roll at the bottom. White and Black keys according to a regular piano layout
* * In 1-octave mode, the piano roll shows one octave
* * In 2-octave mode, the piano roll shows two octaves
* * When a key is pressed, the corresponding key in the piano roll is highlighted
* * When a key is released, the corresponding key in the piano roll is unhighlighted
* * The highlight color should be light, faded color (if possible, pick the current OS's highlight color, otherwise yellow)
* * The highlight color should be the same for all keys
* * The highlight color should not be too bright, so it doesn't hurt the eyes when looking at the piano roll for a long time
* * White keys (A, C, D, E, F, G, A, B) should be colored in `NSColor.systemGray` (macOS equivalent of `UIColor.systemGray3`) or appropriate light gray
* * Black keys should be colored in `NSColor.darkGray` (macOS equivalent of `UIColor.systemGray`) or system dark gray
* * No scroll is needed. In one-octave mode the entire octave must fit in the visible view, in 2-octave mode, the entire two octaves must fit in the visible view with an additional key for the next C note.

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
* `4` - Send note F# (octave 2)
* `t` - Send note G (octave 2)
* `5` - Send note G# (octave 2)
* `y` - Send note A (octave 2)
* `6` - Send note A# (octave 2)
* `u` - Send note B (octave 2)
* `i` - Send note C (octave 3)

## Additional notes, may change later

* A local git repository is created and initialized on branch `main` with `.gitignore` excluding Xcode/build/system artifacts.
* Currently there's no remote repository created for this project. I'll create one once the project is in usable state
* The Agent should discuss questionable features/solutions with the Architect (the User of the Agent), challenge them if necessary
* Although a nicely laid out UI is preferred, functionality is the most important part of the app. If there's a trade-off to be made between the two, functionality wins.
