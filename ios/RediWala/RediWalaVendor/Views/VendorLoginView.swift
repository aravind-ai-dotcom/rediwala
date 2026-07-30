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
                    Text("RediWala Vendor")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(AppTheme.primary)
                    Text("auth.vendor.headline")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("auth.vendor.subtitle")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 24)

                VStack(spacing: 14) {
                    TextField(String(localized: "auth.email"), text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    SecureField(String(localized: "auth.password"), text: $password)
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
                        Text("auth.sign_in")
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .disabled(email.isEmpty || password.isEmpty)

                Button("auth.forgot_password") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .disabled(true)
                    .opacity(0.7)

                #if DEBUG
                Button("auth.use_demo_account") {
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
            List(accounts) { account in
                Button {
                    onSelect(account)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.shortLabel)
                            .font(.headline)
                        Text(account.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("auth.demo_accounts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
#endif
