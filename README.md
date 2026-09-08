# huhTray

A tiny macOS menu-bar app with one job: every second, it has a configurable chance to play a sound. By default it plays a Minecraft villager "huh".

## Features

- Lives entirely in the menu bar — no Dock icon, no windows.
- **Chance slider** — sets how likely the sound is to play on each one-second tick, using `p = 1 / (slider × 100)`. The popover shows the resulting probability per second.
- **Volume slider** — controls playback volume from 0–100%.
- **Debug-only "Try it" button** — plays the sound immediately (only compiled into `DEBUG` builds).

## Requirements

- macOS 26.5 or later
- Xcode 26 or later

## Build & run

1. Open `huhTray.xcodeproj` in Xcode.
2. Select the **huhTray** scheme and press **Run** (⌘R).
3. The die icon appears on the right side of the menu bar — click it to open the controls.

## Changing the sound

The app plays a bundled audio file. To use your own:

1. Drop your audio file into the `huhTray/` folder so it's bundled with the app.
2. Update the resource name/extension in `ContentView.swift`:

   ```swift
   private static let resourceName = "Villager_idle1"
   private static let resourceExtension = "mp3"
   ```

`AVAudioPlayer` supports common formats such as MP3, AAC/M4A, WAV, and AIFF.

## A note on the App Sandbox

`AVAudioPlayer` in a sandboxed app can hit a `PRECONDITION FAILURE` about a blocked
`com.apple.audioanalyticsd` Mach lookup. Since this app is distributed outside the
Mac App Store, the App Sandbox capability is disabled, which avoids the issue. If you
re-enable the sandbox (e.g. for a Mac App Store build), you'll need a corresponding
entitlement exception.

## License

MIT
