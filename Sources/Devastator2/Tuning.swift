import CoreGraphics

// Every gameplay number lives here. DESIGN.md is the source of the values;
// the tube model (one-axis movement, five rails, hexagon bore) is the
// owner's revision of the grey-box outcome.
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

    // feel
    static let podPerimeterSpeed: CGFloat = 620 // points per second along the ring
    static let gravityRecenterPerSecond = 0.8 // idle slide toward the floor rail
    static let gravityGraceSeconds = 0.45 // idle time before gravity takes over
    static let stunSeconds = 0.6
    static let stunGravityMultiplier = 3.0
    static let laneHitWidth: CGFloat = 30 // a shot owns this much of the ring
    static let trackScrollPerSecond = 0.3 // the pod's forward speed, tube lengths per second
    static let farPointScale: CGFloat = 0.12 // size of the world at the far mouth
    static let depthExponent = 1.6 // approach curve; higher looms later

    // notches: railed is fast and steady, coasting is slow
    static let railClockScale = 0.5 // chase clock drain while railed
    static let railScrollScale = 2.0 // the go-fast read
    static let railSnapDistance: CGFloat = 18 // perimeter points; settle in and click
    static let railStickSeconds = 0.22 // held pull that pops a notch
    static let notchCooldownSeconds = 0.4 // no instant re-click after popping out
    static let railDoubleTapSeconds = 0.3

    // jumps: single up is the regular hop; a second tap mid-hop is the big
    // jump, a slo-mo leap to the opposite rail (straight up from the floor,
    // which faces the open roof). Hop clearance is the arc against the
    // wreck's height, so bigger junk needs the top of the jump; the big
    // jump clears everything.
    static let podHopSeconds = 0.45
    static let podHopHeight: CGFloat = 26
    static let junkClearanceFactor: CGFloat = 1.0
    static let bigJumpSeconds = 0.75
    static let bigJumpHeight: CGFloat = 52 // the vertical big jump off the floor
    static let bigJumpSloMo = 0.35 // world rate while airborne on a big jump

    // the quarry: rides the rails, runs for the far mouth, and shoots back
    static let skimmerSpawnDepth = 0.85 // how close ahead it starts
    static let skimmerHopIntervalSeconds = 1.6
    static let skimmerHopJitterSeconds = 0.8
    static let skimmerHopSeconds = 0.25 // slide to the next rail
    static let skimmerBrakeSeconds = 2.5 // chase clock handed back by a mercy brake
    static let mercyEscapeFraction = 0.7 // escape progress where mercy can trigger
    static let skimmerHitsToKill = 3
    static let skimmerHitKnockbackSeconds = 0.5 // a hit staggers the getaway
    static let skimmerShootIntervalSeconds = 2.8
    static let skimmerShootJitterSeconds = 1.4
    static let boltDepthPerSecond = 1.3 // rail-gun return fire closing speed

    // level-ups ride the lanes like junk; catch them on the ground
    static let pickupFirstSeconds = 5.0
    static let pickupIntervalSeconds = 12.0
    static let pickupSize = CGSize(width: 12, height: 12)
    static let gunLevelMax = 3 // damage per shot
    static let hullPickupCap = 5

    // the bore: a hexagonal transit tube. The roofline is the surface and
    // carries no rail; five rails sit at the five wall centers.
    static let hexWaistY: CGFloat = 175 // y of the left and right points
    static let hexTopY: CGFloat = 300 // the roofline, open to the surface
    static let hexBottomY: CGFloat = 40
    static let hexWaistHalf: CGFloat = 244
    static let hexEdgeHalf: CGFloat = 122 // half length of the roof and floor edges
    static let railCount = 5

    // actors, scene points
    static let podSize = CGSize(width: 28, height: 16)
    static let skimmerSize = CGSize(width: 44, height: 20)
    static let junkScaleMin: CGFloat = 0.8 // debris size spread around its art size
    static let junkScaleMax: CGFloat = 1.6
    static let junkSpawnSeconds = 2.4
    static let respawnDelaySeconds = 0.6

    // the hull: junk costs one pip; empty resets with a grace flash
    static let hullMax = 3
    static let invulnSeconds = 1.2

    // earthrise
    static let earthX: CGFloat = 256
    static let earthY: CGFloat = 334 // limb below the surface line: risen, still rising
    static let earthSize = CGSize(width: 96, height: 96)

    // terrain dressing: positions and shapes are art
    static let moundSpots: [(x: CGFloat, rx: CGFloat, ry: CGFloat)] = [
        (16, 10, 4), (40, 14, 5), (96, 9, 4), (120, 7, 3),
        (392, 9, 4), (430, 12, 5), (470, 10, 4), (486, 8, 3),
    ]
    static let craterSpots: [(x: CGFloat, rx: CGFloat, ry: CGFloat)] = [
        (70, 7, 2.5), (100, 5, 1.8), (420, 7, 2.2), (450, 6, 2.0),
    ]
    static let boulderSpots: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat)] = [
        (70, 270, 7, 4), (440, 265, 8, 5), (24, 255, 5, 3),
        (200, 18, 6, 4), (320, 15, 5, 3),
    ]
    static let craterDropY: CGFloat = 6
    static let speckleCount = 42
    static let speckleMargin: CGFloat = 10
    static let speckleSizes: [CGFloat] = [2, 3, 2, 4]
    static let skeletonSize = CGSize(width: 24, height: 20)
    static let skeletonAlpha: CGFloat = 0.55
    static let skeletonSpots: [CGPoint] = [
        CGPoint(x: 56, y: 240), CGPoint(x: 456, y: 240), CGPoint(x: 256, y: 16),
    ]

    // graphics chrome
    static let bevelDepth: CGFloat = 12 // lit bevel along each wall
    static let starCount = 26
    static let starSize = CGSize(width: 2, height: 2)
    static let starMargin: CGFloat = 8
    static let starAlphas: [CGFloat] = [1, 0.7, 0.45]
    static let horizonGlowHeight: CGFloat = 3
    static let engineGlowSize = CGSize(width: 12, height: 4)
    static let railGlowWidth: CGFloat = 4
    static let railGlowHalfLength: CGFloat = 20 // rail glow arc along its wall
    static let railIdleAlpha: CGFloat = 0.4
    static let junkFadeSeconds = 0.15
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
    static let strokeWidth: CGFloat = 1.5

    // grunge and grit
    static let grungeCount = 36
    static let grungeAlpha: CGFloat = 0.18
    static let earthHaloRadius: CGFloat = 52
    static let earthHaloWidth: CGFloat = 8
    static let earthHaloAlpha: CGFloat = 0.5
    static let glassSlashDepths: [Double] = [0.25, 0.45, 0.65, 0.85]
    static let glassSlashSpan = 0.15 // depth skew that angles each slash
    static let glassSlashAlpha: CGFloat = 0.12

    // scores and popups
    static let scoreFontSize: CGFloat = 11
    static let scoreInset: CGFloat = 10
    static let popupRise: CGFloat = 18
    static let popupSeconds = 0.7

    // the filled tube: flat-shaded panel bands falling into depth fog,
    // with light strips running the rails. Seam lines sweep past.
    static let tubeBandCount = 8
    static let fogStrength: CGFloat = 0.85
    static let lightBiasLeft: CGFloat = 1.12 // earthlight through the roof slot
    static let lightBiasRight: CGFloat = 0.92
    static let railStripHalfWidth: CGFloat = 8
    static let railStripAlphaIdle: CGFloat = 0.10
    static let railStripAlphaHot: CGFloat = 0.28
    static let mouthFillAlpha: CGFloat = 0.10
    static let stripeCount = 5
    static let stripeAlphaBase: CGFloat = 0.05
    static let stripeAlphaGain: CGFloat = 0.18

    // tunnel fixtures: bright light rings sweeping past, and station stops
    static let lightRingCount = 2
    static let lightRingWidth: CGFloat = 2.5
    static let lightRingAlphaBase: CGFloat = 0.2
    static let lightRingAlphaGain: CGFloat = 0.8
    static let stationFirstSeconds = 3.0
    static let stationIntervalSeconds = 9.0
    static let stationSlabSize = CGSize(width: 80, height: 10)
    static let stationWindowSize = CGSize(width: 64, height: 4)
    static let stationSignSize = CGSize(width: 12, height: 5)

    // the glass canopy over the roof slot, and the HUD projected on it
    static let glassBandHeight: CGFloat = 12
    static let glassAlpha: CGFloat = 0.08
    static let glassSheetAlpha: CGFloat = 0.05
    static let glintAlpha: CGFloat = 0.18
    static let hudFontSize: CGFloat = 11
    static let hudPipSize = CGSize(width: 8, height: 8)
    static let hudPipGap: CGFloat = 6
    static let hudUrgentSeconds = 3.0

    // the sight: your firing line down the tube, and the far mouth it ends at
    static let sightAlphaIdle: CGFloat = 0.12
    static let sightAlphaLock: CGFloat = 0.5
    static let farSightRadius: CGFloat = 5
    static let mouthPulseSeconds = 1.4
    static let mouthAlphaLo: CGFloat = 0.45
    static let mouthAlphaHi: CGFloat = 0.9

    // parallax streamers: the world pours out of the far mouth at forward
    // speed. Surface is nearest so it runs fastest; rail pulses are energy.
    static let surfaceStreamerCount = 8
    static let wallStreakCount = 6
    static let railPulseCount = 6
    static let streamRateSurface = 1.8
    static let streamRateWall = 1.2
    static let streamRatePulse = 3.0
    static let streamEdgePad: CGFloat = 10
    static let surfaceFeatureSize = CGSize(width: 16, height: 5)
    static let wallStreakSize = CGSize(width: 2, height: 10)
    static let railPulseSize = CGSize(width: 5, height: 4)
    static let streamAlphaBase: CGFloat = 0.2
    static let streamAlphaGain: CGFloat = 0.8

    // the rumble of riding a hot rail
    static let railShakeAmplitude: CGFloat = 1.2
    static let railShakeHz = 13.0
    static let engineFlickerHz = 24.0
    static let engineFlickerBase: CGFloat = 0.65
    static let engineFlickerAmp: CGFloat = 0.35
    static let podRotationPerSecond = 14.0 // banking rate through corners
    static let junkTiltRange: CGFloat = 0.35 // wreckage sits crooked

    static let maxFrameDt = 0.05
}
