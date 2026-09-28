import CoreGraphics

// Every gameplay number lives here. DESIGN.md is the source of the values;
// the grey-box exists to find the ones marked feel.
enum Tuning {
    // presentation
    static let sceneSize = CGSize(width: 512, height: 384) // 2x DS internal resolution
    static let windowSize = CGSize(width: 1024, height: 768)

    // heritage rules
    static let passClockSeconds = 10.0
    static let baseKillScore = 10
    static let chainMax = 5
    static let opponentsPerLevel = 10
    static let levelsToCredits = 10
    static let earthShields = 3
    static let lightLagSeconds = 1.28 // moon to Earth at c

    // brink multiplier by pass-clock seconds remaining
    static let brinkTiers: [(secondsLeft: Double, multiplier: Int)] = [
        (0.5, 16), (1.0, 8), (2.0, 4), (3.0, 2),
    ]

    // feel: placeholders until the grey-box says otherwise
    static let aimFollowLag = 0.12
    static let gravityRecenterPerSecond = 0.8
    static let stunSeconds = 0.6
}
