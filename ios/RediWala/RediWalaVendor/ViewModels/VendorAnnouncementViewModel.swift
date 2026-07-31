import AVFoundation
import Combine
import Foundation

@MainActor
final class VendorAnnouncementViewModel: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isPlaying = false
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var peakLevel: Float = 0
    @Published var permissionDenied = false
    @Published var errorMessage: String?
    @Published var localFileURL: URL?

    let maxDurationSeconds = 60

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meterTask: Task<Void, Never>?

    func requestPermissionIfNeeded() async -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return true
            case .denied:
                permissionDenied = true
                return false
            case .undetermined:
                let granted = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                permissionDenied = !granted
                return granted
            @unknown default:
                return false
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                return true
            case .denied:
                permissionDenied = true
                return false
            case .undetermined:
                let granted = await withCheckedContinuation { continuation in
                    session.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                permissionDenied = !granted
                return granted
            @unknown default:
                return false
            }
        }
    }

    func startRecording(vendorID: String) async {
        guard !isRecording else { return }
        guard await requestPermissionIfNeeded() else { return }
        errorMessage = nil
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowAirPlay])
            try session.setActive(true)

            let url = recordingURL(vendorID: vendorID)
            localFileURL = url
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.prepareToRecord()
            recorder?.record(forDuration: TimeInterval(maxDurationSeconds))
            isRecording = true
            elapsedSeconds = 0
            meterTask?.cancel()
            meterTask = Task { [weak self] in
                guard let self else { return }
                while !Task.isCancelled, self.isRecording {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    self.recorder?.updateMeters()
                    self.peakLevel = self.recorder?.peakPower(forChannel: 0) ?? -160
                    self.elapsedSeconds += 1
                    if self.elapsedSeconds >= self.maxDurationSeconds {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            errorMessage = "Failed to start recording. Please try again."
            isRecording = false
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        recorder?.stop()
        isRecording = false
        meterTask?.cancel()
        meterTask = nil
    }

    func playPreview() {
        guard let localFileURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.allowBluetoothHFP, .allowAirPlay])
            try session.setActive(true)
            player = try AVAudioPlayer(contentsOf: localFileURL)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            errorMessage = "Unable to play recording."
        }
    }

    func stopPlayback() {
        player?.stop()
        isPlaying = false
    }

    func clearRecording() {
        stopPlayback()
        stopRecording()
        if let localFileURL {
            try? FileManager.default.removeItem(at: localFileURL)
        }
        self.localFileURL = nil
        elapsedSeconds = 0
    }

    func makeDraft(vendorID: String, liveSessionID: String?) -> VendorAnnouncementDraft? {
        guard let localFileURL else { return nil }
        return VendorAnnouncementDraft(
            id: UUID().uuidString,
            vendorId: vendorID,
            liveSessionId: liveSessionID,
            localFilePath: localFileURL.path,
            storagePath: nil,
            durationSeconds: elapsedSeconds,
            recordedAt: Date(),
            language: "ta",
            transcriptPlaceholder: "Transcript pending",
            isActive: true,
            activeWhileLive: true,
            customerPlaybackEnabled: true,
            vendorBroadcastEnabled: true,
            playbackIntervalMinutes: nil
        )
    }

    private func recordingURL(vendorID: String) -> URL {
        VendorAnnouncementStore.audioURL(for: vendorID)
    }
}

extension VendorAnnouncementViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
