# Chord Notebook — Phase 1

A native SwiftUI notebook for piano players. This milestone implements the song library with local SwiftData persistence. Piano selection and chord editing remain for Phases 2–4.

## Open and run

1. Open `Dekhenge.xcodeproj` in Xcode (the existing project and scheme retain the starter name).
2. Select the **Dekhenge** scheme and an iPhone or iPad simulator.
3. Choose **Product > Run** (Command-R). The app appears as **Chord Notebook**.
4. For a physical device, select the app target's **Signing & Capabilities**, choose your development team, and replace the placeholder bundle identifier with your own unique identifier.

The project targets iOS/iPadOS 17.0 and later, with both device families enabled. iPhone supports portrait and landscape; iPad supports all orientations. The starter uses Xcode's `project.xcproj` format; development was verified with Xcode 27.2. There are no packages, network services, iCloud capabilities, or accounts to configure.

## Repository layout

Open the project from the repository root. `Dekhenge.xcodeproj`, `Dekhenge/` (app source), `Tests/`, and this README sit alongside each other. The repository root owns the Git history; the app source is not a separate repository. Local Xcode state, build output, and Finder metadata are ignored. The previous nested Git metadata and leftover nested workspace were preserved in `.folder-backups/before-flattening/`, which is excluded from version control.

## Source organization

```text
Dekhenge/
  App/
    ChordNotebookApp.swift   # Entry point, storage loading/error UI
    NotebookStore.swift      # Local-only container shared by views
  Models/
    Song.swift               # Song identity, title, timestamps, cascade relationship
    Chord.swift              # Future chord identity, label, MIDI notes, position, parent
  Views/
    SongLibraryView.swift    # Query, navigation, create/rename/delete and explicit saves
    SongTitleEditor.swift    # Temporary title draft, validation, cancel, save errors
    SongDetailView.swift     # Empty song page for this milestone
  Assets.xcassets/
Tests/
  PersistenceChecks.swift
  run-persistence-checks.sh
```

SwiftData is the single source of truth for saved songs. `@Query` observes the library, and `@State` holds temporary form text and presentation state. There is no separate view-model or service layer. New Swift source files in the app's synchronized folder are automatically included in its target.

`Song` stores a unique UUID, title, creation date, modification date, and chords. `Chord` stores a unique UUID, optional label, normalized `[Int]` MIDI notes, integer position, and parent song. The relationship has an explicit inverse and cascade deletion. Chords are sorted by position when read; SwiftData relationship array order is not treated as persistent ordering. Notes are deduplicated, sorted, and limited to MIDI 48–71. The chord model is established now without adding chord UI before its scheduled phase.

Each mutation explicitly saves. Failed saves roll back and show an error; failed renames also restore observed title/date values because the installed SwiftData runtime leaves these values stale after rollback. Cancel never edits a persisted model. Blank or whitespace-only titles cannot be saved. Duplicate song titles are allowed because songs have separate IDs.

The store is on disk in the application's sandbox, with CloudKit explicitly disabled. Failure to open storage shows a retry screen rather than replacing the database. Removing the app also removes its local notebook; no backup/export feature is included in this milestone.

## Verification

From this project directory, run:

```sh
bash Tests/run-persistence-checks.sh
```

This compiles the actual models and container configuration using the macOS SwiftData SDK, writes an isolated temporary database, and checks creation, reopening, title trimming, saved renames/timestamps, persisted rollback state, MIDI normalization, positions, inverse relationships, cascade deletion, and preservation of an unrelated song. It removes only its own temporary files. It is a standalone integration check, not an Xcode test target or UI test.

Verified during implementation:

- Simulator build for arm64 and x86_64 with iOS 17.0 as the deployment target.
- The persistence integration checks above.
- Installation and launch on the iPhone 18 Pro simulator running iOS 27.2; visual inspection of the library empty state.

Still to verify by hand:

1. Create **My First Song**, save, and open its empty page.
2. Return to the library, swipe left on its row, and choose **Rename**. Save a new title.
3. Start another rename, change the draft, and cancel; confirm the saved title stays intact.
4. Create a second song. Force quit and relaunch; confirm both are present.
5. Swipe a row and choose **Delete**. Cancel once, then confirm deletion. Verify the other song remains.
6. Repeat on iPad portrait and landscape, with dark appearance and larger text. Check VoiceOver access to creation and row actions.
7. Run on an iOS 17 device or simulator. Only iOS 27.2 simulator runtimes were available during implementation.

Save-error alerts and startup-error retry UI compile, but have not been tested through injected storage failures. Device signing, app icon artwork, App Store setup, and deployment remain future work.
