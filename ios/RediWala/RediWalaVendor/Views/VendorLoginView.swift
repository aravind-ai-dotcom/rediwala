import SwiftUI

struct VendorLoginView: View {
    @ObservedObject var firebaseSession: VendorFirebaseSession
    @State private var email = ""
    @State private var password = ""
    #if DEBUG
    @State private var showDemoAccounts = false
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RediWala")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.primary)
                    Text(LocalizedText.resolve("auth.vendor.headline", fallback: "Reach your neighborhood."))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(LocalizedText.resolve("auth.vendor.subtitle", fallback: "Every street is an opportunity."))
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 24)

                VStack(spacing: 14) {
                    TextField(LocalizedText.resolve("auth.email", fallback: "Email"), text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    SecureField(LocalizedText.resolve("auth.password", fallback: "Password"), text: $password)
                        .textContentType(.password)
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if case .failed(let message) = firebaseSession.readiness {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task {
                        _ = await firebaseSession.signIn(email: email, password: password)
                    }
                } label: {
                    HStack {
                        if case .loading = firebaseSession.readiness {
                            ProgressView().tint(.white)
                        }
                        Text(LocalizedText.resolve("auth.sign_in", fallback: "Sign In"))
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .disabled(email.isEmpty || password.isEmpty)

                #if DEBUG
                Button(LocalizedText.resolve("auth.use_demo_account", fallback: "Use demo persona")) {
                    showDemoAccounts = true
                }
                .font(.subheadline.weight(.bold))
                .sheet(isPresented: $showDemoAccounts) {
                    VendorDemoAccountPickerSheet(accounts: DemoAuthCatalog.vendors) { account in
                        email = account.email
                        password = account.demoPassword
                        showDemoAccounts = false
                    }
                }
                #endif
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#if DEBUG
struct VendorDemoAccountPickerSheet: View {
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
                    Text("RediWala Vendor")
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
                                .fill(AppTheme.accent.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Text(String(account.shortLabel.prefix(1)))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.accent)
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
