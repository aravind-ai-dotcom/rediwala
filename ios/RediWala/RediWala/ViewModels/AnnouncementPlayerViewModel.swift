import AVFoundation
import Combine
import Foundation

@MainActor
final class AnnouncementPlayerViewModel: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var loadErrorMessage: String?

    let sellerName: String
    let durationSeconds: Int
    let isSampleContent: Bool

    private var player: AVAudioPlayer?
    private var tickTask: Task<Void, Never>?
    private var resolvedDuration: Int

    init(
        sellerName: String,
        durationSeconds: Int,
        storagePath: String? = nil,
        isSampleContent: Bool = true
    ) {
        self.sellerName = sellerName
        self.durationSeconds = max(durationSeconds, 1)
        self.resolvedDuration = max(durationSeconds, 1)
        self.isSampleContent = isSampleContent && storagePath == nil

        if let storagePath {
            Task { await self.loadRemoteAudio(storagePath: storagePath) }
        }
    }

    var durationLabel: String {
        Self.format(seconds: resolvedDuration)
    }

    var elapsedLabel: String {
        Self.format(seconds: elapsedSeconds)
    }

    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        if let player {
            if !player.isPlaying {
                player.play()
                isPlaying = true
                startTickingUsingPlayer(player)
            }
            return
        }

        guard !isPlaying else { return }
        if elapsedSeconds >= resolvedDuration {
            elapsedSeconds = 0
            progress = 0
        }
        isPlaying = true
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            await self?.runMockPlaybackLoop()
        }
    }

    func pause() {
        isPlaying = false
        player?.pause()
        tickTask?.cancel()
        tickTask = nil
    }

    func stop() {
        pause()
        player?.stop()
        player = nil
        elapsedSeconds = 0
        progress = 0
    }

    private func loadRemoteAudio(storagePath: String) async {
        guard let url = await FirebaseStorageService.downloadURL(forStoragePath: storagePath) else {
            loadErrorMessage = "Announcement audio is unavailable right now."
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.allowBluetoothHFP, .allowAirPlay])
            try session.setActive(true)
            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.prepareToPlay()
            resolvedDuration = max(Int(audioPlayer.duration.rounded()), 1)
            player = audioPlayer
        } catch {
            loadErrorMessage = "Unable to load announcement audio."
        }
    }

    private func startTickingUsingPlayer(_ player: AVAudioPlayer) {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.isPlaying {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                self.elapsedSeconds = Int(player.currentTime.rounded())
                self.progress = min(1, player.currentTime / player.duration)
                if !player.isPlaying {
                    self.isPlaying = false
                    self.progress = 1
                    return
                }
            }
        }
    }

    private func runMockPlaybackLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled, isPlaying else { return }
            elapsedSeconds += 1
            progress = Double(elapsedSeconds) / Double(resolvedDuration)
            if elapsedSeconds >= resolvedDuration {
                isPlaying = false
                progress = 1
                return
            }
        }
    }

    private static func format(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
