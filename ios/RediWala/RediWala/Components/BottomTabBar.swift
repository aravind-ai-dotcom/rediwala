import SwiftUI

enum CustomerTab: Hashable {
    case home
    case favorites
    case profile
}

struct BottomTabBar: View {
    @Binding var selected: CustomerTab

    private let items: [(CustomerTab, LocalizedStringKey, String)] = [
        (.home, "tab.home", "house.fill"),
        (.favorites, "tab.favorites", "heart.fill"),
        (.profile, "tab.profile", "person.crop.circle.fill")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { tab, titleKey, icon in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .symbolEffect(.bounce, value: selected == tab)
                        Text(titleKey)
                            .font(.caption.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(selected == tab ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppTheme.minTap)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected == tab ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(AppTheme.card)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
        }
    }
}

#Preview {
    BottomTabBar(selected: .constant(.home))
        .environment(\.locale, Locale(identifier: "en"))
}
