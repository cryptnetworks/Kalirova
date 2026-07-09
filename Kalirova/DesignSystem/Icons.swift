import SwiftUI

enum KalirovaIcon {
    static let dashboard = "dashboard"
    static let nutrition = "nutrition"
    static let workouts = "workouts"
    static let weight = "weight"
    static let sleep = "sleep"
    static let ai = "ai"
    static let progress = "progress"
    static let calendar = "calendar"
    static let heart = "heart"
    static let water = "water"
    static let settings = "settings"
    static let more = "more"

    static func image(_ name: String) -> Image {
        Image(name)
    }
}
