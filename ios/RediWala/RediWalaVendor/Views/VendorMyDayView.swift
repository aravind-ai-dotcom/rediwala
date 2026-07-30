import SwiftUI

struct VendorMyDayView: View {
    @ObservedObject var liveSession: VendorLiveSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newStopTitle = ""
    @State private var newStopArea: ChennaiArea = .tNagar

    var body: some View {
        NavigationStack {
            List {
                Section("route.today.title") {
                    row("route.current_time", value: Self.timeFormatter.string(from: Date()))
                    row("route.neighborhood", value: liveSession.selectedOperatingArea.localizedName)
                    row("route.live_duration", value: liveSession.liveDurationText)
                }

                Section("route.stops") {
                    ForEach(liveSession.routeStops) { stop in
                        stopRow(stop)
                    }
                    .onMove(perform: liveSession.reorderStops)
                    .onDelete { offsets in
                        offsets.map { liveSession.routeStops[$0].id }.forEach(liveSession.deleteStop)
                    }
                }

                Section("route.add_stop") {
                    TextField("route.place_name", text: $newStopTitle)
                    Picker("route.area", selection: $newStopArea) {
                        ForEach(ChennaiArea.allCases) { area in
                            Text(area.localizedName).tag(area)
                        }
                    }
                    Button("route.add") {
                        guard !newStopTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        liveSession.addWaypoint(title: newStopTitle, near: newStopArea)
                        newStopTitle = ""
                    }
                    .disabled(newStopTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("route.today.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("route.plan") {
                        liveSession.planMyRoute()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            newStopArea = liveSession.selectedOperatingArea
        }
    }

    private func stopRow(_ stop: VendorRouteStopPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.title).font(.headline)
                    Text(stop.landmark)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                statusBadge(stop)
            }
            HStack {
                Text("\(Self.timeFormatter.string(from: stop.arrivalTime)) – \(Self.timeFormatter.string(from: stop.departureTime))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                if stop.estimatedInterest > 0 {
                    Text("\(stop.estimatedInterest) interested")
                        .font(.caption.weight(.semibold))
                }
            }
            if let notes = stop.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            HStack(spacing: 8) {
                if !stop.isCompleted {
                    Button("route.done") { liveSession.markStopCompleted(stop.id) }
                        .buttonStyle(.borderedProminent)
                    Button("route.skip", role: .destructive) { liveSession.skipStop(stop.id) }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func row(_ key: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value).foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func statusBadge(_ stop: VendorRouteStopPlan) -> some View {
        let (text, color): (String, Color) = {
            if stop.isCompleted { return ("Done", .gray) }
            if stop.isCurrent { return ("Current", AppTheme.primary) }
            return ("Next", AppTheme.info)
        }()
        return Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
