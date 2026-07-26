import Combine
import Foundation

/// Mock announcement player for sample/synthetic audio UI.
@MainActor
final class AnnouncementPlayerViewModel: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsedSeconds: Int = 0

    let sellerName: String
    let durationSeconds: Int
    let isSampleContent: Bool

    private var tickTask: Task<Void, Never>?

    init(sellerName: String, durationSeconds: Int, isSampleContent: Bool = true) {
        self.sellerName = sellerName
        self.durationSeconds = max(durationSeconds, 1)
        self.isSampleContent = isSampleContent
    }

    var durationLabel: String {
        Self.format(seconds: durationSeconds)
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
        guard !isPlaying else { return }
        if elapsedSeconds >= durationSeconds {
            elapsedSeconds = 0
            progress = 0
        }
        isPlaying = true
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            await self?.runPlaybackLoop()
        }
    }

    func pause() {
        isPlaying = false
        tickTask?.cancel()
        tickTask = nil
    }

    func stop() {
        pause()
        elapsedSeconds = 0
        progress = 0
    }

    private func runPlaybackLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled, isPlaying else { return }
            elapsedSeconds += 1
            progress = Double(elapsedSeconds) / Double(durationSeconds)
            if elapsedSeconds >= durationSeconds {
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
