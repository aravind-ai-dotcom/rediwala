import SwiftUI

struct RouteTimelineView: View {
    let stops: [RouteStop]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                HStack(alignment: .top, spacing: 14) {
                    // Fixed-height rail — avoid maxHeight: .infinity inside ScrollView.
                    VStack(spacing: 0) {
                        Circle()
                            .fill(dotColor(for: stop.status))
                            .frame(width: 14, height: 14)
                            .overlay {
                                if stop.status == .current {
                                    Circle()
                                        .stroke(AppTheme.primary.opacity(0.35), lineWidth: 4)
                                        .frame(width: 22, height: 22)
                                }
                            }

                        if index < stops.count - 1 {
                            Rectangle()
                                .fill(AppTheme.textSecondary.opacity(0.25))
                                .frame(width: 2, height: 56)
                        }
                    }
                    .frame(width: 22, alignment: .top)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(stop.timeLabel)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(stop.status == .current ? AppTheme.primary : AppTheme.textPrimary)

                        Text(LocalizedStringKey(stop.titleKey))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(LocalizedStringKey(stop.landmarkKey))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(LocalizedStringKey(statusKey(stop.status)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(dotColor(for: stop.status))
                    }
                    .padding(.bottom, index < stops.count - 1 ? 18 : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func dotColor(for status: RouteStopStatus) -> Color {
        switch status {
        case .completed: return AppTheme.textSecondary
        case .current: return AppTheme.primary
        case .upcoming: return AppTheme.info
        }
    }

    private func statusKey(_ status: RouteStopStatus) -> String {
        switch status {
        case .completed: return "route.status.completed"
        case .current: return "route.status.current"
        case .upcoming: return "route.status.upcoming"
        }
    }
}

#Preview("My Day") {
    ScrollView {
        RouteTimelineView(stops: SyntheticChennaiData.sellers[0].routeStops)
            .padding()
    }
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
