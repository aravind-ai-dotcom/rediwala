import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selected: VendorTab

    private let items: [(VendorTab, String, String)] = [
        (.home, "Home", "house.fill"),
        (.inventory, "Inventory", "basket.fill"),
        (.earnings, "Earnings", "indianrupeesign.circle.fill"),
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selected == tab ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppTheme.minTap)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityAddTraits(selected == tab ? .isSelected : [])
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
    VStack {
        Spacer()
        BottomNavigationBar(selected: .constant(.home))
    }
    .background(AppTheme.background)
}
