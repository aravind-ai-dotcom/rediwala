import SwiftUI

struct BottomTabBar: View {
    @Binding var selected: VendorTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(VendorTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 22, weight: .semibold))
                        Text(LocalizedStringKey(tab.titleKey))
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selected == tab ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppTheme.minTap)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringKey(tab.titleKey)))
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
        BottomTabBar(selected: .constant(.home))
    }
    .background(AppTheme.background)
    .environment(\.locale, Locale(identifier: "en"))
}
