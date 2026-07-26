import SwiftUI

struct WorkingHoursView: View {
    @ObservedObject var viewModel: VendorOnboardingViewModel
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                SectionHeader(
                    titleKey: "onboarding.hours.title",
                    subtitleKey: "onboarding.hours.subtitle"
                )

                areaPicker

                timePicker(
                    titleKey: "onboarding.hours.start",
                    minutes: Binding(
                        get: { viewModel.workingHours.startMinutes },
                        set: { viewModel.workingHours.startMinutes = $0 }
                    )
                )

                timePicker(
                    titleKey: "onboarding.hours.end",
                    minutes: Binding(
                        get: { viewModel.workingHours.endMinutes },
                        set: { viewModel.workingHours.endMinutes = $0 }
                    )
                )
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(titleKey: "onboarding.hours.finish", systemImage: "checkmark") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var areaPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("onboarding.area.title")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(ChennaiArea.allCases) { area in
                Button {
                    viewModel.selectedArea = area
                } label: {
                    HStack {
                        Text(LocalizedStringKey(area.labelKey))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        Spacer()
                        if viewModel.selectedArea == area {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                    .padding(16)
                    .frame(minHeight: AppTheme.minTap)
                    .background(AppTheme.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                            .stroke(viewModel.selectedArea == area ? AppTheme.primary : Color.clear, lineWidth: 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func timePicker(titleKey: String, minutes: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(titleKey))
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            DatePicker(
                "",
                selection: Binding(
                    get: { date(from: minutes.wrappedValue) },
                    set: { minutes.wrappedValue = minutesFromDate($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        }
    }

    private func date(from minutes: Int) -> Date {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private func minutesFromDate(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

#Preview {
    WorkingHoursView(viewModel: VendorOnboardingViewModel(), onContinue: {})
        .environment(\.locale, Locale(identifier: "en"))
}
