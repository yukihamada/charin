import AVFoundation

class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?

    init() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    func play(_ name: String) {
        DispatchQueue.main.async { [weak self] in
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                print("[SoundPlayer] \(name).wav not found in bundle")
                return
            }
            do {
                #if os(iOS)
                try AVAudioSession.sharedInstance().setActive(true)
                #endif
                self?.player = try AVAudioPlayer(contentsOf: url)
                self?.player?.volume = 0.8
                self?.player?.prepareToPlay()
                self?.player?.play()
                print("[SoundPlayer] Playing \(name)")
            } catch {
                print("[SoundPlayer] Error: \(error)")
            }
        }
    }
}
