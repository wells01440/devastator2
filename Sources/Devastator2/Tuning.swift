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
    static let laneShotTolerance: CGFloat = 12 // aim this close to your lane line = line blast
    static let trackScrollPerSecond = 0.3 // the pod's forward speed, track lengths per second
    static let farPointScale: CGFloat = 0.12 // size and spread of the world at the horizon
    static let depthExponent = 1.6 // approach curve; higher looms later

    // racers ride the same rails and run AWAY: the pass clock is the chase,
    // and the far distance is the kablammo
    static let skimmerSpawnDepth = 0.85 // how close ahead the quarry starts
    static let skimmerHopIntervalSeconds = 1.6
    static let skimmerHopJitterSeconds = 0.8
    static let skimmerHopSeconds = 0.25 // lateral slide to the next lane
    static let skimmerBrakeSeconds = 2.5 // chase clock handed back by a mercy brake
    static let mercyEscapeFraction = 0.7 // escape progress where mercy can trigger

    // the hop pair: double-up jumps junk, double-down locks in hard
    static let podHopSeconds = 0.45
    static let podHopHeight: CGFloat = 26
    static let brakeSeconds = 0.8 // the cost of a slam lock
    static let brakeScrollScale = 0.5 // forward speed while braking
    static let brakeEscapeScale = 1.5 // the quarry gains while you brake

    // the monorails: home base, three lanes. Notched in, controls are normal
    // and you go fast; off the rail you are slower and the controls go wonky.
    static let railOffsetsX: [CGFloat] = [-136, 0, 136] // wall centers and the floor
    static let railClockScale = 0.5 // pass clock drain while railed
    static let railScrollScale = 2.0 // the go-fast read
    static let railSnapDistance: CGFloat = 12 // pod over the bump notches in
    static let railAimSnapDistance: CGFloat = 40 // aim must be near center too
    static let railEdgeMargin: CGFloat = 24 // aim hard over = within this of a screen edge
    static let railDismountHoldSeconds = 0.3 // hard over held this long = clunk off
    static let railDoubleTapSeconds = 0.3 // double-tap down = clunk off in place
    static let wonkAimDrag: CGFloat = 0.25 // off-rail, pod yaw smears the aim

    // geometry, scene points
    static let trenchRimY: CGFloat = 296
    static let trenchBottomY: CGFloat = 64
    static let trenchWallInset: CGFloat = 72
    static let flatHalfWidth: CGFloat = 88 // flat floor half width; slopes rise beyond it
    static let railBumpHalfWidth: CGFloat = 14 // each rail is a bump on the floor
    static let railBumpHeight: CGFloat = 6
    static let aimRestHeight: CGFloat = 40 // gravity's aim target above the floor
    static let crosshairRadius: CGFloat = 9
    static let podSize = CGSize(width: 28, height: 16)
    static let skimmerSize = CGSize(width: 24, height: 14)
    static let passRingRadius: CGFloat = 22
    static let junkScaleMin: CGFloat = 0.7 // debris size spread around its art size
    static let junkScaleMax: CGFloat = 1.4
    static let junkSpawnSeconds = 2.4
    static let respawnDelaySeconds = 0.6

    // graphics chrome
    static let bevelDepth: CGFloat = 12 // lit bevel along floor and slopes
    static let starCount = 26
    static let starSize = CGSize(width: 2, height: 2)
    static let starMargin: CGFloat = 8
    static let starAlphas: [CGFloat] = [1, 0.7, 0.45]
    static let horizonGlowHeight: CGFloat = 3
    static let earthX: CGFloat = 150
    static let earthY: CGFloat = 340
    static let earthSize = CGSize(width: 72, height: 72)
    static let engineGlowSize = CGSize(width: 12, height: 4)
    static let railGlowWidth: CGFloat = 4
    static let tracerGlowWidth: CGFloat = 2
    static let fragmentCount = 6
    static let fragmentSize = CGSize(width: 4, height: 4)
    static let fragmentDistance: CGFloat = 40
    static let fragmentSeconds = 0.4

    static let tracerFadeSeconds = 0.18
    static let killPopScale: CGFloat = 1.8
    static let passFlashAlpha: CGFloat = 0.7
    static let passFlashInSeconds = 0.05
    static let passFlashOutSeconds = 0.4
    static let stunFlickerSeconds = 0.1
    static let stunFlickerAlpha: CGFloat = 0.25
    static let joltScaleY: CGFloat = 0.7
    static let joltInSeconds = 0.05
    static let joltOutSeconds = 0.08
    static let sparkRadius: CGFloat = 10
    static let junkFadeSeconds = 0.15
    static let stripeCount = 6
    static let stripeSampleStep: CGFloat = 8
    static let stripeAlphaBase: CGFloat = 0.12
    static let stripeAlphaGain: CGFloat = 0.28
    static let railLineWidth: CGFloat = 3
    static let railIdleAlpha: CGFloat = 0.4
    static let laneLineAlpha: CGFloat = 0.22
    static let passRingMinScale: CGFloat = 0.6
    static let strokeWidth: CGFloat = 1.5
    static let trackSampleStep: CGFloat = 4
    static let maxFrameDt = 0.05
}
