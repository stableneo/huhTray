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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 240)
    }
}

/// Owns the audio playback and the once-per-second chance to play the sound.
@MainActor
@Observable
final class SoundEngine {
    /// Slider value that drives the per-second play chance: `p = 1 / (sliderValue * 100)`.
    var sliderValue: Double = 50

    /// Probability that the sound plays during any given one-second tick (clamped to 0...1).
    var probabilityPerSecond: Double {
        let denominator = sliderValue * 100
        guard denominator > 0 else { return 0 }
        return min(1, 1 / denominator)
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
                if Double.random(in: 0..<1) < self.probabilityPerSecond {
                    self.play()
                }
            }
        }
    }

    /// Plays the sound immediately, ignoring the probability.
    func play() {
        guard let url = Bundle.main.url(forResource: Self.resourceName, withExtension: Self.resourceExtension) else {
            print("huhTray: missing \(Self.resourceName).\(Self.resourceExtension) in app bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(volume)
            self.player = player
            player.play()
        } catch {
            print("huhTray: failed to play audio — \(error.localizedDescription)")
        }
    }
}
