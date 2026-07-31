import SwiftUI

#if DEBUG
struct DemoAccountPickerSheet: View {
    let accounts: [DemoAuthCatalog.Account]
    let onSelect: (DemoAuthCatalog.Account) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image("BrandMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Text("RediWala")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(AppTheme.primary)
                    Text("One tap launches a complete demo context")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)

                List(accounts) { account in
                    Button {
                        onSelect(account)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.12))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Text(String(account.shortLabel.prefix(1)))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.primary)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.shortLabel)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(account.displayName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(LocalizedText.resolve("auth.demo_accounts", fallback: "Demo Personas"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedText.resolve("common.done", fallback: "Done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
#endif
