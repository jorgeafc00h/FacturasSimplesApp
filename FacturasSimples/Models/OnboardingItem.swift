import Foundation

struct OnboardingItem: Identifiable {
    let id = UUID()
    let systemImageName: String
    let title: String
    let subtitle: String
}
