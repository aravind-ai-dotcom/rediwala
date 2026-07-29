import Combine
import Foundation
import SwiftUI

enum CustomerFlowPhase: Equatable {
    case splash
    case language
    case welcome
    case neighborhood
    case main
}

@MainActor
final class CustomerFlowViewModel: ObservableObject {
    @Published private(set) var phase: CustomerFlowPhase

    init() {
        self.phase = CustomerOnboardingStore.hasCompleted ? .main : .splash
    }

    func finishSplash() {
        guard phase == .splash else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            if CustomerOnboardingStore.hasChosenLanguage {
                phase = .welcome
            } else {
                phase = .language
            }
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
}
