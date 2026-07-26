import SwiftUI

struct VendorPlaceholderTabView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    VendorPlaceholderTabView(title: "Inventory", systemImage: "basket.fill")
}
