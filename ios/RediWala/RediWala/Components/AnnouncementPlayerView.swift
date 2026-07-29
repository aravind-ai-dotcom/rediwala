import SwiftUI

struct AnnouncementPlayerView: View {
    @StateObject private var player: AnnouncementPlayerViewModel

    init(sellerName: String, durationSeconds: Int, storagePath: String? = nil) {
        _player = StateObject(
            wrappedValue: AnnouncementPlayerViewModel(
                sellerName: sellerName,
                durationSeconds: durationSeconds,
                storagePath: storagePath,
                isSampleContent: storagePath == nil
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(listenTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Button {
                    player.toggle()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(player.isPlaying ? "announcement.pause" : "announcement.play")
                )

                VStack(alignment: .leading, spacing: 8) {
                    waveform
                    HStack {
                        Text(player.elapsedLabel)
                        Spacer()
                        Text(player.durationLabel)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text("announcement.recorded_today")
                        if player.isSampleContent {
                            Text("·")
                            Text("announcement.sample")
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .onDisappear { player.stop() }
        .accessibilityElement(children: .contain)
    }

    private var listenTitle: String {
        let format = String(localized: String.LocalizationValue("announcement.listen"))
        return String(format: format, locale: .current, player.sellerName)
    }

    private var waveform: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<18, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(barColor(for: index, width: geo.size.width))
                        .frame(width: 4, height: barHeight(for: index))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 28)
        .accessibilityHidden(true)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [10, 16, 22, 14, 26, 18, 12, 24, 15, 20, 28, 13, 19, 23, 11, 17, 25, 14]
        let base = pattern[index % pattern.count]
        if player.isPlaying {
            let pulse = 1 + 0.15 * sin(Double(index) + Double(player.elapsedSeconds))
            return base * pulse
        }
        return base
    }

    private func barColor(for index: Int, width: CGFloat) -> Color {
        let threshold = Int(Double(18) * player.progress)
        return index <= threshold ? AppTheme.primary : AppTheme.primary.opacity(0.25)
    }
}

#Preview {
    AnnouncementPlayerView(sellerName: "Murugan", durationSeconds: 18)
        .padding()
        .background(AppTheme.background)
        .environment(\.locale, Locale(identifier: "en"))
}
