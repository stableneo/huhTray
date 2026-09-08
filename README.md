> This project is 100% vibecoded.

# huhTray

A tiny macOS menu-bar app with one job: every second, it has a configurable chance to play a sound. By default it plays a Minecraft villager "huh".

## Features

- Lives entirely in the menu bar — no Dock icon, no windows.
- **Left-click the icon** to open the controls popover; **right-click the icon** to play the sound instantly.
- **Enable checkbox** — master switch for the automatic per-second playing. When off, the chance section grays out (manual right-click still plays).
- **Chance slider** — sets how likely the sound is to play on each one-second tick, using `p = 1 / (slider × 100)`. The popover shows the resulting probability per second.
- **Volume slider** — controls playback volume from 0–100%.
- **Ultra Mode** — the ultimate villager experience. Tap the yellow flash button, confirm the prompt, and the chance unlocks up to a full 100% every second. Enabling starts the slider at 1%, disabling returns it to 50%. A yellow glow marks the button while it's active.
- **Debug-only "Try it" button** — plays the sound immediately (only compiled into `DEBUG` builds).

## Requirements

- macOS 26.5 or later
- Xcode 26 or later

## Build & run

1. Open `huhTray.xcodeproj` in Xcode.
2. Select the **huhTray** scheme and press **Run** (⌘R).
3. The die icon appears on the right side of the menu bar — left-click it to open the controls, or right-click to play instantly.

To preview the app exactly as published (without the debug "Try it" button), edit the scheme's Run action and set **Build Configuration** to **Release**.

## Installing a downloaded release

The `.dmg` builds attached to GitHub Releases are only ad-hoc signed — they are **not**
signed with an Apple Developer ID or notarized. So when you first open the app, macOS
will warn that it's from an unidentified developer and refuse to launch on a double-click.

To install anyway:

1. Open the `.dmg` and drag **huhTray** into your **Applications** folder.
2. **Right-click** (or Control-click) `huhTray.app` and choose **Open**, then confirm in the dialog. You only need to do this once.

If double-clicking is blocked, use System Settings instead (no Terminal needed):

1. Double-click `huhTray.app` once and dismiss the warning.
2. Open **System Settings → Privacy & Security** and scroll to the **Security** section.
3. Next to the message that huhTray was blocked, click **Open Anyway** and authenticate.

As a last resort, you can clear the quarantine flag from Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/huhTray.app
```

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

## A note on audio "pops"

Some Macs emit a faint click when the audio output device powers up or down (e.g. on
launch/quit, or after Ultra Mode's burst of playback ends). This is a hardware
transient, not a bug in the app or the audio file — it's the DAC energizing and
de-energizing, and most audio apps trigger it.