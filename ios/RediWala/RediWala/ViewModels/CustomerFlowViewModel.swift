import Combine
import Foundation
import SwiftUI

enum CustomerFlowPhase: Equatable {
    case splash
    case language
    case welcome
    case locationPermission
    case main
}

@MainActor
final class CustomerFlowViewModel: ObservableObject {
    @Published private(set) var phase: CustomerFlowPhase = .splash

    func finishSplash() {
        guard phase == .splash else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .language
        }
    }

    func completeLanguageSelection() {
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .welcome
        }
    }

    func completeWelcome() {
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .locationPermission
        }
    }

    func completeLocationPermission() {
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .main
        }
    }
}
