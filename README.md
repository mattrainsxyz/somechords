# Dekhenge — Phase 2

A native SwiftUI notebook for piano players. The song library uses local SwiftData persistence. Phase 2 adds a reusable F2–B3 keyboard and temporary note selection. Saving, displaying, and editing song chords remain for Phase 3.

## Open and run

1. Open `Dekhenge.xcodeproj` in Xcode (the existing project and scheme retain the starter name).
2. Select the **Dekhenge** scheme and an iPhone or iPad simulator.
3. Choose **Product > Run** (Command-R). The app appears as **Dekhenge**.
4. For a physical device, select the app target's **Signing & Capabilities**, choose your development team, and replace the placeholder bundle identifier with your own unique identifier.

The project targets iOS/iPadOS 26.0 and later, with both device families enabled. iPhone and iPad declare portrait-only support; landscape orientations are disabled. The starter uses Xcode's `project.xcproj` format; development was verified with Xcode 27.2. There are no packages, network services, iCloud capabilities, or accounts to configure.

## Repository layout

Open the project from the repository root. `Dekhenge.xcodeproj`, `Dekhenge/` (app source), `Tests/`, and this README sit alongside each other. The repository root owns the Git history; the app source is not a separate repository. Local Xcode state, build output, and Finder metadata are ignored. The previous nested Git metadata and leftover nested workspace were preserved in `.folder-backups/before-flattening/`, which is excluded from version control.

## Source organization

```text
Dekhenge/
  App/
    DekhengeApp.swift        # Entry point, storage loading/error UI
    NotebookStore.swift      # Local-only container shared by views
  Models/
    Song.swift               # Song identity, title, timestamps, cascade relationship
    Chord.swift              # Future chord identity, label, MIDI notes, position, parent
  Views/
    SongLibraryView.swift    # Query, navigation, create/rename/delete and explicit saves
    SongTitleEditor.swift    # Temporary title draft, validation, cancel, save errors
    SongDetailView.swift     # Empty song page and keyboard entry point
    KeyboardSelectionView.swift # Temporary note selection screen
  Components/
    PianoKeyboardView.swift  # Interactive/read-only keyboard and accessible key controls
  Utilities/
    PianoNote.swift          # MIDI range, key color, note names, octave mapping
    PianoKeyboardLayout.swift # Key frames and adaptive touch sizing
  Assets.xcassets/
Tests/
  PersistenceChecks.swift
  run-persistence-checks.sh
  KeyboardChecks.swift
  run-keyboard-checks.sh
```

SwiftData is the single source of truth for saved songs. `@Query` observes the library, and `@State` holds temporary form text and presentation state. There is no separate view-model or service layer. New Swift source files in the app's synchronized folder are automatically included in its target.

`Song` stores a unique UUID, title, creation date, modification date, and chords. `Chord` stores a unique UUID, optional label, normalized `[Int]` MIDI notes, integer position, and parent song. The relationship has an explicit inverse and cascade deletion. Chords are sorted by position when read; SwiftData relationship array order is not treated as persistent ordering. Notes are deduplicated, sorted, and limited to MIDI 41–59. The chord model is established now without adding chord UI before its scheduled phase.

Each mutation explicitly saves. Failed saves roll back and show an error; failed renames also restore observed title/date values because the installed SwiftData runtime leaves these values stale after rollback. Cancel never edits a persisted model. Blank or whitespace-only titles cannot be saved. Duplicate song titles are allowed because songs have separate IDs.

The store is on disk in the application's sandbox, with CloudKit explicitly disabled. Failure to open storage shows a retry screen rather than replacing the database. Removing the app also removes its local notebook; no backup/export feature is included in this milestone.

## Try the Phase 2 keyboard

Create or open a song, then choose **Try the Keyboard**. The entire keyboard screen remains rotated 90 degrees clockwise within the portrait interface. Notes run from F2 at the top to B3 at the bottom. The screen contains the keyboard and a navigation bar with **Clear** and **Done**. There are no introductory or selected-note sections, and no horizontal or vertical scroll views.

Tap keys to toggle any combination of notes. **Clear** removes the selection; **Done** closes the screen. Selections are temporary and start empty when the screen is reopened. Saving song chords remains Phase 3 work.

The fixed range is F2–B3, MIDI 41–59: 11 white keys and 8 black keys. White keys display their letter only. Black keys display both enharmonic names on separate lines, such as F♯ and G♭. Octaves are retained in MIDI values and VoiceOver descriptions, allowing repeated notes to remain distinguishable without printed octave numbers.

`PianoNote` supplies the range shared by saved chord normalization and keyboard rendering. `PianoKeyboardLayout` calculates white/black frames independently of UI state. Black buttons have a higher stacking order and rectangular hit regions matching their visible frames. Every key scales to the available width and height; there is no minimum width that would force scrolling. On small phones this means narrower touch targets than the previous scrolling keyboard. Selected keys use deep indigo with a checkmark. Key labels scale to fit, while native navigation controls support Dynamic Type.

`PianoKeyboardView(selectedNotes: $notes)` edits a `Set<Int>` binding and fills the space proposed by its parent. Give it an explicit height when embedding it in content that does not constrain height. `PianoKeyboardView(selectedNotes: .constant(notes), isInteractive: false)` uses the same layout without tap controls and exposes a combined selection description. Compact saved diagrams will be integrated in Phase 3.

## Live UI iteration with SwiftUI Previews

1. Open `Dekhenge/Views/KeyboardSelectionView.swift` in Xcode.
2. Click **Show Canvas** in the editor toolbar, or choose **Editor > Canvas**.
3. Choose **Keyboard screen**, **Dark appearance**, or **Larger text**. If paused, refresh the canvas. Use Live mode to tap keys and try Clear.
4. Use the canvas's **Preview Device** menu to switch between iPhone and iPad. There is no landscape preview, matching the app's portrait configuration.
5. Leave the file and canvas open while editing. Xcode updates saved UI changes; the initial preview startup and structural changes may require a build.

For isolated styling, open `Dekhenge/Components/PianoKeyboardView.swift`. **Interactive keyboard** and **Black keys · Dark** start with sample selections; **Wide layout** checks the component at 1150 points of width; **Read only** checks display mode. These component previews use fixed layout sizes, not device emulation. Previews use temporary selection state and do not change your notebook. The standalone screen preview's Done button has no presenting sheet to dismiss; verify dismissal in the actual app.

Before the range correction, the keyboard rendered in the live iPhone preview without either removed section or scrolling. Coordinate taps verified black-key selection without selecting adjacent white keys, multiple selections, independent deselection, and Clear. Xcode's preview accessibility tree exposed note names including octaves and both sharp/flat names; full VoiceOver navigation has not been verified. The preview automatically reflected the source changes.

## Verification

From the repository root:

```sh
bash Tests/run-persistence-checks.sh
bash Tests/run-keyboard-checks.sh
```

The persistence checks use the real models and container configuration with an isolated temporary database. They verify creation, reopening, title trimming, saved renames/timestamps, persisted rollback state, normalization, positions, inverse relationships, cascade deletion, and preservation of unrelated songs. The expanded test chord includes MIDI 41 and 42 to confirm the range endpoints and low notes survive persistence.

The keyboard checks verify all 19 MIDI values, note names, the 11 white and 8 black keys, both sharp/flat spellings, labels without octave numbers, accessible octave information, black-key boundaries, E/F and B/C gaps, and fitting every key into phone/tablet bounds over multiple widths and heights. These are standalone checks rather than Xcode UI test targets, and remove only their own temporary files.

Verified:

- Simulator build for arm64 and x86_64, with iOS 26.0 as the minimum deployment target.
- Both automated suites above.
- Portrait-only orientation lists in the built app for both device families.
- Live iPhone preview rendering, selection/deselection, multi-selection, Clear, and automatic refresh.

Remaining hands-on checks:

1. Create **My First Song**, open it, rename it, and confirm canceling a title draft does not change saved data.
2. Create a second song, force quit, and relaunch. Delete one song with confirmation and verify the other remains.
3. In the keyboard, select F2 and F3 together and toggle only one off. Check the first F2 and last B3 remain fully visible, along with all black-key spellings.
4. Check iPad, the smallest supported iPhone, dark appearance, larger text, and VoiceOver. Verify key edges select only the intended note.
5. Rotate a device while the library and keyboard are open. Verify the portrait interface stays fixed and the keyboard keeps its clockwise orientation. Orientation capability changes require rebuilding/relaunching the app; a canvas refresh alone does not validate them.
6. Verify Done closes the keyboard and reopening clears temporary selections.
7. Test on an iOS 26 device or simulator. The installed simulator runtime used during development is iOS 27.2.

Storage-failure alerts, device signing, app icon artwork, App Store setup, and deployment remain unverified or future work.
