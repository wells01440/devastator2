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
    static let crosshairSpeed: CGFloat = 320 // scene points per second
    static let hitRadius: CGFloat = 18
    static let skimmerWeaveAmplitude: CGFloat = 48
    static let skimmerWeaveHz = 0.35

    // grey-box geometry, scene points
    static let skyBandHeight: CGFloat = 64
    static let trenchRimY: CGFloat = 296
    static let trenchBottomY: CGFloat = 64
    static let trenchWallInset: CGFloat = 72
    static let aimRestHeight: CGFloat = 40 // gravity's aim target above the U bottom
    static let crosshairRadius: CGFloat = 9
    static let podSize = CGSize(width: 28, height: 16)
    static let skimmerSize = CGSize(width: 24, height: 14)
    static let passRingRadius: CGFloat = 22
    static let obstacleOffsetX: CGFloat = 96
    static let obstacleSize = CGSize(width: 32, height: 40)
    static let obstacleClearance: CGFloat = 24
    static let respawnDelaySeconds = 0.6

    // grey-box chrome
    static let tracerFadeSeconds = 0.18
    static let killPopScale: CGFloat = 1.8
    static let passFlashAlpha: CGFloat = 0.7
    static let passFlashInSeconds = 0.05
    static let passFlashOutSeconds = 0.4
    static let strokeWidth: CGFloat = 1.5
    static let trackSampleStep: CGFloat = 4
    static let debugFontSize: CGFloat = 10
    static let debugInset: CGFloat = 8
    static let maxFrameDt = 0.05

    // grey-box palette, white levels
    static let skyGrey: CGFloat = 0.16
    static let rockGrey: CGFloat = 0.34
    static let edgeGrey: CGFloat = 0.55
    static let obstacleGrey: CGFloat = 0.48
    static let skimmerGrey: CGFloat = 0.72
    static let podGrey: CGFloat = 0.85
}
