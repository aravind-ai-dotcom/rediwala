import SwiftUI

struct NeighborhoodSelectionView: View {
    @ObservedObject private var neighborhoodStore = CustomerNeighborhoodStore.shared
    let onContinue: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("onboarding.neighborhood.title")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("onboarding.neighborhood.subtitle")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(CustomerNeighborhoodStore.onboardingChoices) { hood in
                        Button {
                            neighborhoodStore.select(hood)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey(hood.nameKey))
                                        .font(.headline.weight(.bold))
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)

                                if neighborhoodStore.homeNeighborhood == hood {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(neighborhoodStore.homeNeighborhood == hood ? AppTheme.primary.opacity(0.12) : AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(LocalizedStringKey(hood.nameKey)))
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 140)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(titleKey: "onboarding.neighborhood.continue", systemImage: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.95))
        }
    }
}

#Preview("English") {
    NeighborhoodSelectionView(onContinue: {})
        .environment(\.locale, Locale(identifier: "en"))
}

