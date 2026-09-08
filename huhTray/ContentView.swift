//
//  ContentView.swift
//  huhTray
//
//  Created by Neo Werling on 08.09.26.
//

import SwiftUI
import Observation
import AVFoundation

struct ContentView: View {
    @Bindable var engine: SoundEngine
    @State private var showUltraConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Play villager sounds", isOn: $engine.isEnabled)
                    .toggleStyle(.checkbox)

                Spacer()

                Button {
                    if engine.isUltraEnabled {
                        engine.disableUltra()
                    } else {
                        showUltraConfirmation.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.74, blue: 0.18))
                            .overlay(
                                Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                            )
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.55))
                    }
                    .frame(width: 14, height: 14)
                    .shadow(color: engine.isUltraEnabled ? .yellow : .clear,
                            radius: engine.isUltraEnabled ? 5 : 0)
                }
                .buttonStyle(.plain)
                .help(engine.isUltraEnabled ? "Turn off Ultra" : "Ultra")

                Button {
                    Task {
                        await engine.shutdown()
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.37, blue: 0.34))
                            .overlay(
                                Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                            )
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.55))
                    }
                    .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .help("Quit")
            }

            if engine.isUltraEnabled {
                Label("ULTRA MODE ON", systemImage: "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
            } else if showUltraConfirmation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("You are about to enable the ultimate villager experience. Are you ready?")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .font(.callout)
                    .foregroundStyle(.yellow)
                    HStack {
                        Button("No", role: .cancel) {
                            showUltraConfirmation = false
                        }
                        .frame(maxWidth: .infinity)
                        Button("Yes") {
                            engine.enableUltra()
                            showUltraConfirmation = false
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            Divider()

            Group {
                Text("Chance to play each second")
                    .font(.headline)

                HStack {
                    Slider(value: $engine.sliderValue, in: 1...100)
                    Text("\(Int(engine.sliderValue))")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                Text(String(format: "≈ %.3f%% every second", engine.probabilityPerSecond * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .disabled(!engine.isEnabled)

            Text("Volume")
                .font(.headline)

            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(value: $engine.volume, in: 0...1)
                Text("\(Int(engine.volume * 100))")
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }

            #if DEBUG
            Divider()
            Button {
                engine.play()
            } label: {
                Text("Try it (debug)")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            #endif
        }
        .padding()
        .frame(width: 240)
    }
}

/// Owns the audio playback and the once-per-second chance to play the sound.
@MainActor
@Observable
final class SoundEngine {
    /// Master switch for the automatic per-second playing. When off, the app stays
    /// quiet on its own (manual triggers like right-click still play).
    var isEnabled = true

    /// Slider value that drives the per-second play chance: `p = 1 / (sliderValue * 100)`.
    var sliderValue: Double = 50

    /// Whether Ultra Mode is enabled — the ultimate villager experience, which lets
    /// the chance reach a full 100% every second.
    var isUltraEnabled = false

    /// Probability that the sound plays during any given one-second tick (clamped to 0...1).
    var probabilityPerSecond: Double {
        if isUltraEnabled {
            // Ultra Mode: the slider maps straight to 0...100% per second.
            return min(1, sliderValue / 100)
        }
        let denominator = sliderValue * 100
        guard denominator > 0 else { return 0 }
        return min(1, 1 / denominator)
    }

    /// Enables Ultra Mode, starting the slider at 1%.
    func enableUltra() {
        isUltraEnabled = true
        sliderValue = 1
    }

    /// Disables Ultra Mode, returning to the calmer default chances at 50%.
    func disableUltra() {
        isUltraEnabled = false
        sliderValue = 50
        fadeOutCurrentSound()
    }

    /// Fades out and stops a sound that's currently playing, so leaving Ultra Mode
    /// doesn't let a lingering "huh" finish (and fades to avoid a click).
    private func fadeOutCurrentSound() {
        guard let player, player.isPlaying else { return }
        player.setVolume(0, fadeDuration: 0.08)
        Task {
            try? await Task.sleep(for: .milliseconds(90))
            player.stop()
            player.currentTime = 0
            player.volume = Float(volume)
        }
    }

    /// Playback volume for the sound, from 0 (silent) to 1 (full).
    var volume: Double = 1

    /// The bundled audio file to play.
    private static let resourceName = "Villager_idle1"
    private static let resourceExtension = "mp3"

    private var player: AVAudioPlayer?
    private var tickTask: Task<Void, Never>?

    init() {
        start()
    }

    /// Begins the once-per-second loop that rolls against `probabilityPerSecond`.
    private func start() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                guard self.isEnabled else { continue }
                if Double.random(in: 0..<1) < self.probabilityPerSecond {
                    self.play()
                }
            }
        }
    }

    /// Gracefully tears down audio before the app exits: fades out anything playing,
    /// releases the player, and lets CoreAudio settle so the device powers down less
    /// abruptly (reducing the pop on quit).
    func shutdown() async {
        tickTask?.cancel()
        tickTask = nil
        if let player, player.isPlaying {
            player.setVolume(0, fadeDuration: 0.05)
            try? await Task.sleep(for: .milliseconds(60))
        }
        player?.stop()
        player = nil
        try? await Task.sleep(for: .milliseconds(120))
    }

    /// Plays the sound immediately, ignoring the probability.
    func play() {
        guard let player = preparedPlayer() else { return }
        player.volume = Float(volume)
        player.currentTime = 0
        player.play()
    }

    /// Returns a single, reused, pre-prepared player so the audio pipeline stays
    /// warm — avoiding per-play allocation and mid-playback deallocation clicks.
    private func preparedPlayer() -> AVAudioPlayer? {
        if let player {
            return player
        }
        guard let url = Bundle.main.url(forResource: Self.resourceName, withExtension: Self.resourceExtension) else {
            print("huhTray: missing \(Self.resourceName).\(Self.resourceExtension) in app bundle")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            self.player = player
            return player
        } catch {
            print("huhTray: failed to load audio — \(error.localizedDescription)")
            return nil
        }
    }
}
