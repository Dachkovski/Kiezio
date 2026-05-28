import Foundation

protocol TrustService {
    var currentTrust: LocalUserTrust { get }
    mutating func recordHelpfulAction()
    mutating func recordNegativeSignal()
}

struct LocalTrustService: TrustService {
    private(set) var currentTrust = LocalUserTrust.demo

    init(currentTrust: LocalUserTrust = .demo) {
        self.currentTrust = currentTrust
    }

    mutating func recordHelpfulAction() {
        currentTrust.helpfulActions += 1
        currentTrust.score = min(1, currentTrust.score + 0.03)
    }

    mutating func recordNegativeSignal() {
        currentTrust.negativeSignals += 1
        currentTrust.score = max(0.1, currentTrust.score - 0.08)
    }
}
