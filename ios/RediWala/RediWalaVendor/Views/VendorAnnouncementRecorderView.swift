import SwiftUI

struct VendorAnnouncementRecorderView: View {
    let vendorID: String
    let liveSessionID: String?
    /// When true, Save button says "Save & Go Live".
    var proceedsToGoLive: Bool = false
    let onSave: (VendorAnnouncementDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VendorAnnouncementViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Tell customers what you are selling today.")
                        .font(.headline)
                    Text("இன்று நீங்கள் என்ன விற்கிறீர்கள் என்பதை வாடிக்கையாளர்களிடம் சொல்லுங்கள்.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    meterCard
                    controls

                    if viewModel.permissionDenied {
                        Text("Microphone access denied. Enable it in Settings to record.")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.danger)
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.danger)
                    }
                }
                .padding(20)
            }
            .navigationTitle(proceedsToGoLive ? "Record, Then Go Live" : "Record Today's Message")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(proceedsToGoLive ? "Save & Go Live" : "Save") {
                        if let draft = viewModel.makeDraft(vendorID: vendorID, liveSessionID: liveSessionID) {
                            onSave(draft)
                            dismiss()
                        }
                    }
                    .disabled(viewModel.localFileURL == nil)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vendorPlayAnnouncementNow)) { _ in
            if !viewModel.isRecording {
                viewModel.playPreview()
            }
        }
    }

    private var meterCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(viewModel.isRecording ? "Recording..." : "Ready")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(viewModel.isRecording ? AppTheme.danger : AppTheme.textPrimary)
                Spacer()
                Text("\(viewModel.elapsedSeconds)s / \(viewModel.maxDurationSeconds)s")
                    .font(.subheadline.weight(.semibold))
            }
            ProgressView(value: max(0, (viewModel.peakLevel + 160) / 160))
                .tint(viewModel.isRecording ? AppTheme.danger : AppTheme.primary)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if viewModel.isRecording {
                Button("Stop Recording") { viewModel.stopRecording() }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.danger)
            } else {
                Button("Start Recording") {
                    Task { await viewModel.startRecording(vendorID: vendorID) }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
            }

            HStack(spacing: 10) {
                Button(viewModel.isPlaying ? "Stop Preview" : "Play Preview") {
                    if viewModel.isPlaying {
                        viewModel.stopPlayback()
                    } else {
                        viewModel.playPreview()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.localFileURL == nil || viewModel.isRecording)

                Button("Delete") {
                    viewModel.clearRecording()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(AppTheme.danger)
                .disabled(viewModel.localFileURL == nil)

                AudioRoutePickerButton()
                    .frame(width: 44, height: 44)
            }
        }
    }
}
