# Dekhenge — Phase 2

A native SwiftUI notebook for piano players. The song library uses local SwiftData persistence. Phase 2 adds a reusable two-octave keyboard and temporary note selection. Saving, displaying, and editing song chords remain for Phase 3.

## Open and run

1. Open `Dekhenge.xcodeproj` in Xcode (the existing project and scheme retain the starter name).
2. Select the **Dekhenge** scheme and an iPhone or iPad simulator.
3. Choose **Product > Run** (Command-R). The app appears as **Dekhenge**.
4. For a physical device, select the app target's **Signing & Capabilities**, choose your development team, and replace the placeholder bundle identifier with your own unique identifier.

The project targets iOS/iPadOS 26.0 and later, with both device families enabled. iPhone supports portrait and landscape; iPad supports all orientations. The starter uses Xcode's `project.xcproj` format; development was verified with Xcode 27.2. There are no packages, network services, iCloud capabilities, or accounts to configure.

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

`Song` stores a unique UUID, title, creation date, modification date, and chords. `Chord` stores a unique UUID, optional label, normalized `[Int]` MIDI notes, integer position, and parent song. The relationship has an explicit inverse and cascade deletion. Chords are sorted by position when read; SwiftData relationship array order is not treated as persistent ordering. Notes are deduplicated, sorted, and limited to MIDI 48–71. The chord model is established now without adding chord UI before its scheduled phase.

Each mutation explicitly saves. Failed saves roll back and show an error; failed renames also restore observed title/date values because the installed SwiftData runtime leaves these values stale after rollback. Cancel never edits a persisted model. Blank or whitespace-only titles cannot be saved. Duplicate song titles are allowed because songs have separate IDs.

The store is on disk in the application's sandbox, with CloudKit explicitly disabled. Failure to open storage shows a retry screen rather than replacing the database. Removing the app also removes its local notebook; no backup/export feature is included in this milestone.

## Try the Phase 2 keyboard

Create or open a song, then choose **Try the Keyboard**. Tap multiple white and black keys and read the selected names, including their octaves. Tap a selected key again to remove it; **Clear** removes the selection. **Done** closes the screen. Selections are temporary, are not attached to the song, and start empty each time this screen opens.

The keyboard covers C3–B4 (MIDI 48–71), with C4 at MIDI 60. `PianoNote` supplies the range used by both saved chord normalization and keyboard rendering. `PianoKeyboardLayout` calculates white/black key frames independently of SwiftUI state. Black buttons have a higher stacking order than white buttons, with rectangular hit regions matching their frames. White keys are at least 72 points wide; black keys are at least 44.64 points wide. Narrow screens scroll horizontally; wide screens expand the keys to fill the available width. The selection screen opens full screen and rotates its entire interface 90 degrees clockwise. Its layout dimensions are swapped before rotation so controls stay within the available area. In portrait, the notes run from top to bottom and the keyboard scrolls along that direction; keyboard taps and the Done/Clear controls rotate with the screen.

Selected keys use a deep indigo fill and a checkmark, with white note labels. Unselected piano keys retain their familiar black/white appearance in light and dark modes. VoiceOver labels include the note and octave, selection value, selected trait, and toggle hint. The keyboard's note order stays left to right in all interface languages. The surrounding descriptions and note summary support Dynamic Type; physical key labels use fixed-size text, with full note names exposed to VoiceOver and in the scalable summary.

`PianoKeyboardView(selectedNotes: $notes)` edits a `Set<Int>` binding. `PianoKeyboardView(selectedNotes: .constant(notes), isInteractive: false)` renders the same key layout without controls and exposes a combined selected-note accessibility description. Interactive and read-only Xcode previews are included. Compact saved diagrams will be integrated in Phase 3.

## Verification

From this project directory, run:

```sh
bash Tests/run-persistence-checks.sh
bash Tests/run-keyboard-checks.sh
```

This compiles the actual models and container configuration using the macOS SwiftData SDK, writes an isolated temporary database, and checks creation, reopening, title trimming, saved renames/timestamps, persisted rollback state, MIDI normalization, positions, inverse relationships, cascade deletion, and preservation of an unrelated song. It removes only its own temporary files. It is a standalone integration check, not an Xcode test target or UI test.

The keyboard checks compile the actual note/layout utilities and verify every note name, all 14 white and 10 black keys, black-key boundaries, the E/F and B/C gaps, octave preservation, valid range, and touch widths at phone and tablet viewport sizes. These checks do not simulate touches or VoiceOver.

Verified during implementation:

- Simulator build for arm64 and x86_64 with iOS 26.0 as the deployment target.
- The persistence integration checks above.
- The keyboard mapping and geometry checks above.
- During Phase 1: installation and launch on the iPhone 18 Pro simulator running iOS 27.2; visual inspection of the library empty state.
- Phase 2 interaction checks remain manual: the Device Hub interface connection timed out during verification.

Still to verify by hand:

1. Create **My First Song**, save, and open its empty page.
2. Return to the library, swipe left on its row, and choose **Rename**. Save a new title.
3. Start another rename, change the draft, and cancel; confirm the saved title stays intact.
4. Create a second song. Force quit and relaunch; confirm both are present.
5. Swipe a row and choose **Delete**. Cancel once, then confirm deletion. Verify the other song remains.
6. Repeat on iPad portrait and landscape, with dark appearance and larger text. Check VoiceOver access to creation and row actions.
7. Open **Try the Keyboard**. Select C3 and C4 together, then deselect C3 and confirm C4 remains selected. Select C♯3 at its center and edges; confirm neither C3 nor D3 toggles. Repeat with other black keys.
8. Scroll to the second octave and select C4, E4, and G4 (MIDI 60, 64, 67). Confirm the three highlights match the names. Select every key, toggle individual notes off, and try **Clear**. Scrolling should not toggle notes.
9. Close and reopen the keyboard: the temporary selection should be empty and the song should still have zero chords. Repeat on iPad in portrait and landscape, in dark appearance, at larger text sizes, and with VoiceOver. When the rotated keyboard has at least 1008 points of space along its note axis, both octaves should fit without scrolling. Check that Done and Clear remain accessible and black-key taps still select only the intended note after rotation.
10. In Xcode's **Read only** preview, confirm keys have no tap actions and the selected-note description is accessible.
11. Run on an iOS 26 device or simulator. Only iOS 27.2 simulator runtimes were available during implementation.

Save-error alerts and startup-error retry UI compile, but have not been tested through injected storage failures. Device signing, app icon artwork, App Store setup, and deployment remain future work.
