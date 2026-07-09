import SwiftUI

enum KalirovaAnimation {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.86)
    static let gentle = Animation.easeInOut(duration: 0.22)

    @MainActor
    static func withAccessibleSpring(
        reduceMotion: Bool,
        _ changes: @escaping () -> Void
    ) {
        if reduceMotion {
            changes()
        } else {
            withAnimation(spring, changes)
        }
    }
}
