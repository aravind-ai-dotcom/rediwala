import SwiftUI

struct ProfileRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 44, height: 44)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 12) {
        ProfileRow(title: "Language", value: "Hindi", systemImage: "globe")
        ProfileRow(title: "Phone", value: "+91 98765 43210", systemImage: "phone.fill")
    }
    .padding()
    .background(AppTheme.background)
}
