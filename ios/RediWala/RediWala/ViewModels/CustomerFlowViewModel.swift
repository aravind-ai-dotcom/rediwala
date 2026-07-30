import Combine
import Foundation
import SwiftUI

enum CustomerFlowPhase: Equatable {
    case splash
    case login
    case language
    case welcome
    case neighborhood
    case main
}

@MainActor
final class CustomerFlowViewModel: ObservableObject {
    @Published private(set) var phase: CustomerFlowPhase = .splash

    func finishSplash(isSignedIn: Bool, profileCompleted: Bool) {
        guard phase == .splash else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            if isSignedIn {
                phase = destinationAfterAuth(profileCompleted: profileCompleted)
            } else {
                phase = .login
            }
        }
    }

    func didSignIn(profileCompleted: Bool) {
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = destinationAfterAuth(profileCompleted: profileCompleted)
        }
    }

    func didSignOut() {
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .login
        }
    }

    func completeLanguageSelection() {
        withAnimation(.easeInOut(duration: 0.35)) {
            CustomerOnboardingStore.markLanguageChosen()
            phase = .welcome
        }
    }

    func completeWelcome() {
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .neighborhood
        }
    }

    func completeNeighborhoodSelection() {
        withAnimation(.easeInOut(duration: 0.35)) {
            CustomerOnboardingStore.markCompleted()
            phase = .main
        }
    }

    private func destinationAfterAuth(profileCompleted: Bool) -> CustomerFlowPhase {
        if profileCompleted || CustomerOnboardingStore.hasCompleted {
            return .main
        }
        if CustomerOnboardingStore.hasChosenLanguage {
            return .welcome
        }
        return .language
    }
}
