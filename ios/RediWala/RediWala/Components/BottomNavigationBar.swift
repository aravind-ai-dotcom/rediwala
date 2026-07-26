import SwiftUI

enum CustomerTab: Hashable {
    case home
    case search
    case orders
    case profile
}

struct BottomNavigationBar: View {
    @Binding var selected: CustomerTab

    private let items: [(CustomerTab, String, String)] = [
        (.home, "Home", "house.fill"),
        (.search, "Search", "magnifyingglass"),
        (.orders, "Orders", "bag.fill"),
        (.profile, "Profile", "person.crop.circle.fill")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { tab, title, icon in
                Button {
                    selected = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                        Text(title)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(selected == tab ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppTheme.minTap)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
    BottomNavigationBar(selected: .constant(.home))
}
