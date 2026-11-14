# Dekhenge — Phase 3

A native SwiftUI notebook for piano players. The song library uses local SwiftData persistence. Phase 3 adds saved chord sequences, optional labels, compact diagrams, editing, and deletion. The F2–B3 keyboard stays sideways, fitted to the screen, with no scrolling. Reordering remains Phase 4 work.

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
    Chord.swift              # Chord identity, label, MIDI notes, position, parent
    SongChordEditing.swift  # Validated, explicitly saved chord mutations
  Views/
    SongLibraryView.swift    # Query, navigation, create/rename/delete and explicit saves
    SongTitleEditor.swift    # Temporary title draft, validation, cancel, save errors
    SongDetailView.swift     # Ordered diagram list, add/edit/delete, in-memory previews
    ChordEditorView.swift    # Draft selection, optional label, cancel/save
  Components/
    PianoKeyboardView.swift  # Interactive/read-only keyboard and accessible key controls
    ChordDiagramView.swift   # Compact saved chord card
  Utilities/
    ChordDraft.swift         # Temporary editor value state and save validation
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

`Song` stores a unique UUID, title, creation date, modification date, and chords. `Chord` stores a unique UUID, optional label, normalized `[Int]` MIDI notes, integer position, and parent song. The relationship has an explicit inverse and cascade deletion. Chords are sorted by position when read; SwiftData relationship array order is not treated as persistent ordering. Notes are deduplicated, sorted, and limited to MIDI 41–59.

Each mutation explicitly saves. Failed saves roll back and show an error; failed renames also restore observed title/date values because the installed SwiftData runtime leaves these values stale after rollback. Cancel never edits a persisted model. Blank or whitespace-only titles cannot be saved. Duplicate song titles are allowed because songs have separate IDs.

The store is on disk in the application's sandbox, with CloudKit explicitly disabled. Failure to open storage shows a retry screen rather than replacing the database. Removing the app also removes its local notebook; no backup/export feature is included in this milestone.

## Create and edit chords

1. Create or open a song and tap **Add Chord** (the plus button, or the empty-page button).
2. Tap any combination of piano keys. **Save** stays disabled until at least one valid note is selected.
3. To name the chord, tap the **tag** icon, enter an optional label, and choose **Done**. This changes only the editor draft. An empty or whitespace-only label is stored as no label.
4. Tap **Save** to add the chord at the end of the song. The song page displays a compact read-only diagram with the saved highlights and optional label.
5. Tap a diagram to reopen its saved notes and label. Save keeps that chord's identity and position. **Cancel** discards all draft changes. **Clear** only clears the draft; it does not delete a saved chord.
6. Swipe left on a diagram, or touch and hold for its context menu, to choose **Delete**. Confirm to remove only that chord. The remaining cards keep their relative order.

The editor remains rotated 90 degrees clockwise inside the portrait interface, with no title, introductory text, selected-note section, checkmarks, or scrolling. Its controls are **Cancel**, **Clear**, **Chord Label**, and **Save**. The song page scrolls vertically to accommodate many diagrams.

Drafts are value state (`ChordDraft`), separate from SwiftData models. `Song.saveChord` validates a nonempty in-range selection, normalizes the optional label, updates the parent timestamp, and explicitly saves. New chords append after the highest saved position. Editing preserves the UUID and position. `Song.deleteChord` explicitly saves a single deletion. Both reject a chord belonging to another song, report save errors, and roll back failed changes. The standard confirmation alert retains its chord target independently of its open/closed state. Deletion explicitly updates the observed relationship so its card disappears immediately. Reordering and position compaction remain Phase 4 work; gaps in stored positions after deletion do not affect display order.

The fixed range is F2–B3, MIDI 41–59: 11 white keys and 8 black keys. White keys display their letter only. Black keys display both enharmonic names on separate lines, such as F♯ and G♭. Octaves are retained in MIDI values and VoiceOver descriptions, allowing repeated notes to remain distinguishable without printed octave numbers.

`PianoNote` supplies the range shared by saved chord normalization and keyboard rendering. `PianoKeyboardLayout` calculates white/black frames independently of UI state. Black buttons have a higher stacking order and rectangular hit regions matching their visible frames. Every key scales to the available width and height; there is no minimum width that would force scrolling. On small phones this means narrower touch targets than the previous scrolling keyboard. Selected keys use deep indigo without a checkmark; VoiceOver retains the selected state. Key labels scale to fit, while native navigation controls support Dynamic Type.

`PianoKeyboardView(selectedNotes: $notes)` edits a `Set<Int>` binding and fills the space proposed by its parent. Give it an explicit height when embedding it in content that does not constrain height. `PianoKeyboardView(selectedNotes: .constant(notes), isInteractive: false)` uses the same layout without tap controls and exposes a combined selection description. `ChordDiagramView` uses that read-only mode for saved cards; the surrounding button exposes its label, selected notes, edit action, and delete action to accessibility.

## Live UI iteration with SwiftUI Previews

1. Open `Dekhenge/Views/SongDetailView.swift` in Xcode and show the canvas. **Saved song** includes two sample chords; **Empty song** starts with none. Their SwiftData containers exist only in memory and never read or write your real notebook. Add/edit/delete actions in these previews use the same production mutation methods as the app.
2. Open `Dekhenge/Views/ChordEditorView.swift` for **New chord**, **Edit chord · Dark**, or **Larger text**. The old temporary `KeyboardSelectionView.swift` has been replaced by this editor. Standalone editor previews use a no-op save callback; test actual saves and dismissal in the song preview or full app.
3. For isolated styling, open `Dekhenge/Components/PianoKeyboardView.swift` (**Interactive keyboard**, **Black keys · Dark**, **Wide layout**, **Read only**) or `Dekhenge/Components/ChordDiagramView.swift` (**Saved diagram**).
4. Use Live mode to interact. The canvas's **Preview Device** menu switches between iPhone and iPad. There is no landscape preview, matching the app configuration.
5. Leave the file and canvas open while editing. Xcode updates saved UI changes; initial startup and structural changes may require a build. If a first SwiftData preview update times out, refresh the canvas after the initial build finishes.

In-memory preview data resets when Xcode recreates the preview. Use the full simulator to verify data surviving app termination and relaunch.

## Verification

From the repository root:

```sh
bash Tests/run-persistence-checks.sh
bash Tests/run-keyboard-checks.sh
```

The persistence checks use the real models and container configuration with an isolated temporary database. They verify creation, reopening, title trimming, saved renames/timestamps, persisted rollback state, normalization, positions, inverse relationships, cascade deletion, and preservation of unrelated songs. The test chords include MIDI 41 and 59 to cover both endpoints. Phase 3 checks also exercise the actual chord save/delete methods: draft cancellation, invalid/empty selection rejection, label trimming/removal, identity and position preservation during editing, appending after deletion, cross-song isolation, and reopening edited sequences.

The keyboard checks verify all 19 MIDI values, note names, the 11 white and 8 black keys, both sharp/flat spellings, labels without octave numbers, accessible octave information, black-key boundaries, E/F and B/C gaps, and fitting every key into phone/tablet bounds over multiple widths and heights. These are standalone checks rather than Xcode UI test targets, and remove only their own temporary files.

Verified:

- Simulator build for arm64 and x86_64, with iOS 26.0 as the minimum deployment target.
- Both automated suites above.
- Portrait-only orientation lists in the built app for both device families.
- Live iPhone preview rendering of compact diagrams and the sideways editor.
- Preview interaction: reopening saved selections, saving an edited diagram, creating a labeled chord at the end, disabled Save for an empty selection, clearing a draft and canceling without changing the saved chord.
- Preview deletion through the context menu and standard confirmation alert, removing only the chosen sample chord.
- Phase 2 keyboard interaction and automatic canvas refresh.

Remaining hands-on checks:

1. Create **My First Song**, open it, rename it, and confirm canceling a title draft does not change saved data.
2. Create a second song, force quit, and relaunch. Delete one song with confirmation and verify the other remains.
3. In the keyboard, select F2 and F3 together and toggle only one off. Check the first F2 and last B3 remain fully visible, along with all black-key spellings.
4. Check iPad, the smallest supported iPhone, dark appearance, larger text, and VoiceOver. Verify key edges select only the intended note.
5. Rotate a device while the library and keyboard are open. Verify the portrait interface stays fixed and the keyboard keeps its clockwise orientation. Orientation capability changes require rebuilding/relaunching the app; a canvas refresh alone does not validate them.
6. In the full app, add two chords, edit the first, cancel another edit, confirm a chord deletion, and relaunch to verify saved notes/labels/order. Check delete-cancel and empty-song states. Preview interactions do not substitute for this full app relaunch check.
7. Test on an iOS 26 device or simulator. The installed simulator runtime used during development is iOS 27.2.

Storage-failure alerts compile but have not been verified with injected failures. Device signing, app icon artwork, App Store setup, and deployment remain future work.
