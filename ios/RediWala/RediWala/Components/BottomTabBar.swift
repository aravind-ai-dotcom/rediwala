import SwiftUI

enum CustomerTab: Hashable, CaseIterable {
    case home
    case map
    case messages
    case watchlist
    case profile

    var title: String {
        switch self {
        case .home: return LocalizedText.resolve("tab.home", fallback: "Home")
        case .map: return LocalizedText.resolve("tab.map", fallback: "Map")
        case .messages: return LocalizedText.resolve("tab.messages", fallback: "Messages")
        case .watchlist: return LocalizedText.resolve("tab.watchlist", fallback: "Watch")
        case .profile: return LocalizedText.resolve("tab.profile", fallback: "Profile")
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .map: return "map.fill"
        case .messages: return "bubble.left.and.bubble.right.fill"
        case .watchlist: return "eye.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct BottomTabBar: View {
    @Binding var selected: CustomerTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CustomerTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .symbolEffect(.bounce, value: selected == tab)
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
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
        .padding(.horizontal, 4)
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
