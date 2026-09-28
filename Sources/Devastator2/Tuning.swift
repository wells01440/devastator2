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
    static let gravityGraceSeconds = 0.45 // idle time before gravity takes the aim
    static let stunSeconds = 0.6
    static let stunGravityMultiplier = 3.0
    static let crosshairSpeed: CGFloat = 320 // scene points per second
    static let hitRadius: CGFloat = 18
    static let skimmerWeaveAmplitude: CGFloat = 48
    static let skimmerWeaveHz = 0.35
    static let trackScrollPerSecond = 0.55 // stripe sweep, track lengths per second

    // the monorail: locked pod, free aim, slowed pass clock
    static let railClockScale = 0.5 // pass clock drain while railed
    static let railScrollScale = 2.0 // the speed-doubling read
    static let railSnapDistance: CGFloat = 12
    static let railBreakDistance: CGFloat = 110 // aim pull needed to leave
    static let railBreakSeconds = 0.35 // sustained pull needed to leave
    static let railJunkChance = 0.35 // junk that targets the rail lane

    // grey-box geometry, scene points
    static let skyBandHeight: CGFloat = 64
    static let trenchRimY: CGFloat = 296
    static let trenchBottomY: CGFloat = 64
    static let trenchWallInset: CGFloat = 72
    static let flatHalfWidth: CGFloat = 88 // flat floor half width; slopes rise beyond it
    static let aimRestHeight: CGFloat = 40 // gravity's aim target above the floor
    static let crosshairRadius: CGFloat = 9
    static let podSize = CGSize(width: 28, height: 16)
    static let skimmerSize = CGSize(width: 24, height: 14)
    static let passRingRadius: CGFloat = 22
    static let junkSize = CGSize(width: 22, height: 12)
    static let junkSpawnSeconds = 2.4
    static let junkTravelSeconds = 3.2
    static let respawnDelaySeconds = 0.6

    // grey-box chrome
    static let tracerFadeSeconds = 0.18
    static let killPopScale: CGFloat = 1.8
    static let passFlashAlpha: CGFloat = 0.7
    static let passFlashInSeconds = 0.05
    static let passFlashOutSeconds = 0.4
    static let stunFlickerSeconds = 0.1
    static let stunFlickerAlpha: CGFloat = 0.25
    static let junkFadeSeconds = 0.15
    static let stripeCount = 6
    static let stripeSampleStep: CGFloat = 8
    static let stripeAlphaBase: CGFloat = 0.12
    static let stripeAlphaGain: CGFloat = 0.28
    static let railLineWidth: CGFloat = 3
    static let railIdleAlpha: CGFloat = 0.4
    static let strokeWidth: CGFloat = 1.5
    static let trackSampleStep: CGFloat = 4
    static let debugFontSize: CGFloat = 10
    static let debugInset: CGFloat = 8
    static let maxFrameDt = 0.05

    // grey-box palette, white levels
    static let skyGrey: CGFloat = 0.16
    static let rockGrey: CGFloat = 0.34
    static let edgeGrey: CGFloat = 0.55
    static let junkGrey: CGFloat = 0.45
    static let skimmerGrey: CGFloat = 0.72
    static let podGrey: CGFloat = 0.85
    static let podRailGrey: CGFloat = 1.0
}
