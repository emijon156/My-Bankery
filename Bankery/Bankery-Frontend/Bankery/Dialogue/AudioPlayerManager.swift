//
//  AudioPlayerManager.swift
//  Bankery
//

import AVFoundation

/// Plays the Eclair voice clip while dialogue text is typing out.
@Observable
class AudioPlayerManager {

    private var player: AVAudioPlayer?

    init() {
        prepare()
    }

    func play() {
        if player == nil { prepare() }
        player?.currentTime = 0
        player?.play()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    private func prepare() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioPlayerManager] AVAudioSession setup failed: \(error)")
        }

        guard let url = Bundle.main.url(forResource: "elevenlabsvoice", withExtension: "mp3") else {
            print("[AudioPlayerManager] elevenlabsvoice.mp3 not found. Bundle path: \(Bundle.main.bundlePath)")
            return
        }
        print("[AudioPlayerManager] Found elevenlabsvoice.mp3 at \(url)")

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 1.0
            player?.prepareToPlay()
        } catch {
            print("Failed to init player: \(error)")
        }
    }
}
