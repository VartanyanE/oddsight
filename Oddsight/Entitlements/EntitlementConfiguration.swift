import Foundation

enum SubscriptionTier: String, CaseIterable, Identifiable, Sendable {
    case free
    case pro
    case elite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        case .elite: "Elite"
        }
    }
}

struct PlanEntitlements: Equatable, Sendable {
    let alertLimit: Int?
    let scannerSignalLimit: Int?
    let supportsAdvancedScanner: Bool

    nonisolated func canCreateAlert(existingCount: Int) -> Bool {
        alertLimit.map { existingCount < $0 } ?? true
    }
}

struct EntitlementConfiguration: Sendable {
    let plans: [SubscriptionTier: PlanEntitlements]

    nonisolated func entitlements(for tier: SubscriptionTier) -> PlanEntitlements {
        plans[tier] ?? PlanEntitlements(alertLimit: 0, scannerSignalLimit: 0, supportsAdvancedScanner: false)
    }

    static let defaultPlans = EntitlementConfiguration(plans: [
        .free: PlanEntitlements(alertLimit: 3, scannerSignalLimit: 10, supportsAdvancedScanner: false),
        .pro: PlanEntitlements(alertLimit: 25, scannerSignalLimit: nil, supportsAdvancedScanner: true),
        .elite: PlanEntitlements(alertLimit: nil, scannerSignalLimit: nil, supportsAdvancedScanner: true)
    ])
}
