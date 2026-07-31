import SwiftUI

struct CustomerLoginView: View {
    @ObservedObject var authService: FirebaseAuthService
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
                    Text("auth.welcome_back")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("auth.customer.subtitle")
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

                if case .failed(let message) = authService.state {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task {
                        _ = await authService.signIn(email: email, password: password)
                    }
                } label: {
                    HStack {
                        if authService.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("auth.sign_in")
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .disabled(email.isEmpty || password.isEmpty || authService.isAuthenticating)

                Button("auth.forgot_password") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .disabled(true)
                    .opacity(0.7)

                #if DEBUG
                Button(LocalizedText.resolve("auth.use_demo_account", fallback: "Use demo persona")) {
                    showDemoAccounts = true
                }
                .font(.subheadline.weight(.bold))
                .sheet(isPresented: $showDemoAccounts) {
                    DemoAccountPickerSheet(accounts: DemoAuthCatalog.customers) { account in
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
