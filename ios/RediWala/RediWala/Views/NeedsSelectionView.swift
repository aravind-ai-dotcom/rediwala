import SwiftUI

struct NeedsSelectionView: View {
    @ObservedObject private var needsStore = CustomerNeedsStore.shared
    let onDone: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("home.todays_needs")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("home.todays_needs.subtitle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                HStack(spacing: 10) {
                    Button {
                        needsStore.reuseYesterday()
                    } label: {
                        Text("needs.reuse_yesterday")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        needsStore.clearToday()
                    } label: {
                        Text("needs.clear_today")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(NeedCategoryGroup.allCases) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey(group.titleKey))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(group.needs) { need in
                                needTile(need)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 140)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(titleKey: "common.done", systemImage: "checkmark.circle.fill") {
                onDone()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
    }

    private func needTile(_ need: CustomerNeedItem) -> some View {
        let selected = needsStore.isSelected(need)
        let done = needsStore.isCompleted(need)
        return Button {
            needsStore.toggle(need)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: need.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(selected ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(width: 28, height: 28)

                Text(LocalizedStringKey(need.titleKey))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppTheme.primary : AppTheme.textSecondary.opacity(0.45))
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(selected ? AppTheme.primary.opacity(0.08) : AppTheme.card)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? AppTheme.primary.opacity(0.7) : Color.primary.opacity(0.08), lineWidth: selected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(done ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .contextMenu {
            if selected {
                Button("needs.mark_completed") {
                    needsStore.markCompleted(need)
                }
            }
        }
    }
}

#Preview("English") {
    NeedsSelectionView(onDone: {})
        .environment(\.locale, Locale(identifier: "en"))
}
