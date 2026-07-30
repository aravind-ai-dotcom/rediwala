import SwiftUI

#if DEBUG
struct DemoControlView: View {
    @StateObject private var controller = DemoScenarioController.shared

    var body: some View {
        List {
            Section("Scenarios") {
                button("Reset all demo scenarios") { await controller.resetAllScenarios() }
                button("Make Murugan Live") { await controller.makeMuruganLive() }
                button("Advance Murugan waypoint") { await controller.advanceMuruganWaypoint() }
                button("Expire Lakshmi Flowers") { await controller.expireLakshmiFlowers() }
                button("Confirm Siva is still present") { await controller.confirmSivaStillPresent() }
                button("Advance Babu apartment stop") { await controller.advanceBabuApartmentStop() }
                button("Start Kumar collection round") { await controller.startKumarRound() }
                button("End Kumar collection round") { await controller.endKumarRound() }
                button("Clear customer requests") { await controller.clearCustomerRequests() }
                Button("Restore default Today’s Needs") {
                    controller.restoreDefaultNeeds()
                }
            }

            if !controller.lastMessage.isEmpty {
                Section("Last result") {
                    Text(controller.lastMessage)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Demo Control")
        .disabled(controller.isBusy)
        .overlay {
            if controller.isBusy {
                ProgressView()
            }
        }
    }

    private func button(_ title: String, action: @escaping () async -> Void) -> some View {
        Button(title) {
            Task { await action() }
        }
    }
}
#endif
