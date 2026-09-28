import SpriteKit

// Grey-box prototype. Disposable by design: it exists to answer whether
// aim-as-movement feels good. Scope and rules are in AGENTS.md.
final class GameScene: SKScene {

    private enum Key {
        static let left: UInt16 = 123
        static let right: UInt16 = 124
        static let down: UInt16 = 125
        static let up: UInt16 = 126
        static let space: UInt16 = 49
    }

    private struct Junk {
        let node: SKSpriteNode
        let laneX: CGFloat
        let size: CGSize
        var progress: Double
    }

    private var held = Set<UInt16>()
    private var lastTime: TimeInterval = 0

    private let skyFlash = SKSpriteNode()
    private var railGlows: [SKShapeNode] = []
    private let pod = SKSpriteNode()
    private let engineGlow = SKSpriteNode()
    private let crosshair = SKShapeNode()
    private let skimmer = SKSpriteNode()
    private let passRing = SKShapeNode(circleOfRadius: Tuning.passRingRadius)
    private var stripes: [SKShapeNode] = []

    private var podX: CGFloat = 0
    private var railedIndex: Int?
    private var dismountAccum: TimeInterval = 0
    private var lastDownTap: TimeInterval = 0
    private var lastUpTap: TimeInterval = 0
    private var podAirRemaining: TimeInterval = 0
    private var brakeRemaining: TimeInterval = 0
    private var stunRemaining: TimeInterval = 0
    private var idleSeconds: TimeInterval = 0
    private var stripePhase = 0.0
    private var junkPieces: [Junk] = []
    private var junkSpawnCountdown: TimeInterval = 0
    private var skimmerAlive = false
    private var skimmerHasBraked = false
    private var skimmerLane = 0
    private var skimmerX: CGFloat = 0
    private var hopTarget: Int?
    private var hopFromX: CGFloat = 0
    private var hopT: TimeInterval = 0
    private var hopCountdown: TimeInterval = 0
    private var skimmerElapsed: TimeInterval = 0
    private var respawnCountdown: TimeInterval = 0
    private var kills = 0
    private var passes = 0

    private var centerX: CGFloat { size.width / 2 }
    private var leftWallX: CGFloat { Tuning.trenchWallInset }
    private var rightWallX: CGFloat { size.width - Tuning.trenchWallInset }
    private var railXs: [CGFloat] { Tuning.railOffsetsX.map { centerX + $0 } }
    private var isRailed: Bool { railedIndex != nil }
    private var flatMinX: CGFloat { centerX - Tuning.flatHalfWidth }
    private var flatMaxX: CGFloat { centerX + Tuning.flatHalfWidth }
    private var aimRest: CGPoint {
        CGPoint(x: centerX, y: Tuning.trenchBottomY + Tuning.aimRestHeight)
    }

    // your forward speed through the slot, and how fast the quarry gains on
    // escape: braking beats railing beats nothing
    private var forwardScale: Double {
        brakeRemaining > 0 ? Tuning.brakeScrollScale : isRailed ? Tuning.railScrollScale : 1
    }
    private var escapeScale: Double {
        brakeRemaining > 0 ? Tuning.brakeEscapeScale : isRailed ? Tuning.railClockScale : 1
    }

    // the trench profile, rear-forward view: flat floor, straight slopes to
    // the rim at the walls
    private func baseProfileY(_ x: CGFloat) -> CGFloat {
        let a = abs(x - centerX)
        guard a > Tuning.flatHalfWidth else { return Tuning.trenchBottomY }
        let run = centerX - Tuning.trenchWallInset - Tuning.flatHalfWidth
        let t = min(1, (a - Tuning.flatHalfWidth) / run)
        return Tuning.trenchBottomY + (Tuning.trenchRimY - Tuning.trenchBottomY) * t
    }

    // each rail is a bump riding the profile, wall or floor
    private func trackY(_ x: CGFloat) -> CGFloat {
        var y = baseProfileY(x)
        if let nearest = railXs.min(by: { abs(x - $0) < abs(x - $1) }),
           abs(x - nearest) <= Tuning.railBumpHalfWidth {
            let t = abs(x - nearest) / Tuning.railBumpHalfWidth
            y += Tuning.railBumpHeight * (1 - t * t)
        }
        return y
    }

    // one perspective for everything in the slot: depth 0 is the horizon
    // (trench center at rim height), depth 1 is the player's cross-section.
    // A grounded thing at near-anchor x projects toward the vanishing point
    // and scales with depth: far is small, near is big, nothing flies.
    private func project(_ nearX: CGFloat, _ depth: Double) -> (point: CGPoint, scale: CGFloat) {
        let f = Tuning.farPointScale
            + (1 - Tuning.farPointScale) * CGFloat(pow(depth, Tuning.depthExponent))
        let vp = CGPoint(x: centerX, y: Tuning.trenchRimY)
        let near = CGPoint(x: nearX, y: trackY(nearX))
        let point = CGPoint(x: vp.x + (near.x - vp.x) * f,
                            y: vp.y + (near.y - vp.y) * f)
        return (point, f)
    }

    // screen position for a grounded sprite of the given full height
    private func place(_ node: SKNode, nearX: CGFloat, depth: Double, height: CGFloat) -> CGFloat {
        let (p, f) = project(nearX, depth)
        node.position = CGPoint(x: p.x, y: p.y + height / 2 * f)
        node.setScale(f)
        return f
    }

    // MARK: build

    override func didMove(to view: SKView) {
        backgroundColor = Palette.space
        buildTrench()
        buildActors()
        podX = centerX
        crosshair.position = aimRest
        junkSpawnCountdown = Tuning.junkSpawnSeconds
        spawnSkimmer()
    }

    private func buildTrench() {
        // stars: a golden-ratio scatter above the rim, deterministic
        let starBottom = Tuning.trenchRimY + Tuning.starMargin
        let starSpan = size.height - starBottom - Tuning.starMargin
        for i in 0..<Tuning.starCount {
            let fx = (Double(i) * 0.61803).truncatingRemainder(dividingBy: 1)
            let fy = (Double(i) * 0.38197).truncatingRemainder(dividingBy: 1)
            let star = SKSpriteNode(color: Palette.star, size: Tuning.starSize)
            star.position = CGPoint(x: CGFloat(fx) * size.width,
                                    y: starBottom + CGFloat(fy) * starSpan)
            star.alpha = Tuning.starAlphas[i % Tuning.starAlphas.count]
            addChild(star)
        }

        // Earthrise: the limb sits below the rim, so the horizon and the
        // slot's interior occlude it. Risen, still rising.
        let earth = SKSpriteNode(texture: Sprites.earth)
        earth.size = Tuning.earthSize
        earth.position = CGPoint(x: Tuning.earthX, y: Tuning.earthY)
        addChild(earth)

        // the slot's interior: nearer than the horizon, so it hides the limb
        let interior = CGMutablePath()
        interior.move(to: CGPoint(x: leftWallX, y: Tuning.trenchRimY))
        for x in stride(from: leftWallX, through: rightWallX, by: Tuning.trackSampleStep) {
            interior.addLine(to: CGPoint(x: x, y: trackY(x)))
        }
        interior.addLine(to: CGPoint(x: rightWallX, y: Tuning.trenchRimY))
        interior.closeSubpath()
        let interiorNode = SKShapeNode(path: interior)
        interiorNode.fillColor = Palette.trenchAir
        interiorNode.strokeColor = .clear
        addChild(interiorNode)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: Tuning.trenchRimY))
        for x in stride(from: CGFloat(0), through: size.width, by: Tuning.trackSampleStep) {
            path.addLine(to: CGPoint(x: x, y: trackY(x)))
        }
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.closeSubpath()
        let rock = SKShapeNode(path: path)
        rock.fillColor = Palette.rockBody
        rock.strokeColor = Palette.edgeLight
        rock.lineWidth = Tuning.strokeWidth
        addChild(rock)

        // lit bevels: the cut faces of the slot catch the light
        func facet(_ points: [CGPoint], _ color: SKColor) {
            let p = CGMutablePath()
            p.addLines(between: points)
            p.closeSubpath()
            let node = SKShapeNode(path: p)
            node.fillColor = color
            node.strokeColor = .clear
            addChild(node)
        }
        let bevel = Tuning.bevelDepth
        let bottomY = Tuning.trenchBottomY
        let rimY = Tuning.trenchRimY
        facet([CGPoint(x: flatMinX, y: bottomY),
               CGPoint(x: flatMaxX, y: bottomY),
               CGPoint(x: flatMaxX, y: bottomY - bevel),
               CGPoint(x: flatMinX, y: bottomY - bevel)], Palette.rockFloor)
        facet([CGPoint(x: flatMinX, y: bottomY),
               CGPoint(x: leftWallX, y: rimY),
               CGPoint(x: leftWallX, y: rimY - bevel),
               CGPoint(x: flatMinX, y: bottomY - bevel)], Palette.rockSlopeLit)
        facet([CGPoint(x: flatMaxX, y: bottomY),
               CGPoint(x: rightWallX, y: rimY),
               CGPoint(x: rightWallX, y: rimY - bevel),
               CGPoint(x: flatMaxX, y: bottomY - bevel)], Palette.rockSlopeShade)
        facet([CGPoint(x: 0, y: rimY),
               CGPoint(x: leftWallX, y: rimY),
               CGPoint(x: leftWallX, y: rimY - bevel),
               CGPoint(x: 0, y: rimY - bevel)], Palette.surface)
        facet([CGPoint(x: rightWallX, y: rimY),
               CGPoint(x: size.width, y: rimY),
               CGPoint(x: size.width, y: rimY - bevel),
               CGPoint(x: rightWallX, y: rimY - bevel)], Palette.surface)

        // busy lunar terrain: mounds breaking the horizon on the surface strips
        for spot in Tuning.moundSpots {
            let mound = SKShapeNode(ellipseOf: CGSize(width: spot.rx * 2, height: spot.ry * 2))
            mound.position = CGPoint(x: spot.x, y: rimY)
            mound.fillColor = Palette.surface
            mound.strokeColor = .clear
            addChild(mound)
        }
        for spot in Tuning.craterSpots {
            let lip = SKShapeNode(ellipseOf: CGSize(width: spot.rx * 2, height: spot.ry * 2))
            lip.position = CGPoint(x: spot.x, y: rimY - Tuning.craterDropY + 1)
            lip.fillColor = Palette.edgeLight
            lip.strokeColor = .clear
            addChild(lip)
            let bowl = SKShapeNode(ellipseOf: CGSize(width: spot.rx * 2, height: spot.ry * 2))
            bowl.position = CGPoint(x: spot.x, y: rimY - Tuning.craterDropY)
            bowl.fillColor = Palette.rockSlopeShade
            bowl.strokeColor = .clear
            addChild(bowl)
        }
        // dirt speckle: rubble in the cross-section, golden-ratio scattered
        var speckled = 0
        var probe = 0
        while speckled < Tuning.speckleCount && probe < Tuning.speckleCount * 10 {
            probe += 1
            let x = CGFloat((Double(probe) * 0.61803).truncatingRemainder(dividingBy: 1))
                * size.width
            let y = CGFloat((Double(probe) * 0.38197).truncatingRemainder(dividingBy: 1))
                * Tuning.trenchRimY
            guard y < baseProfileY(x) - Tuning.speckleMargin else { continue }
            let side = Tuning.speckleSizes[speckled % Tuning.speckleSizes.count]
            let fleck = SKSpriteNode(color: speckled % 2 == 0 ? Palette.dirtLight
                                                              : Palette.dirtDark,
                                     size: CGSize(width: side, height: side))
            fleck.position = CGPoint(x: x, y: y)
            addChild(fleck)
            speckled += 1
        }
        // and the ones who dug here before us
        for spot in Tuning.skeletonSpots {
            let bones = SKSpriteNode(texture: Sprites.skeleton)
            bones.size = Tuning.skeletonSize
            bones.position = spot
            bones.alpha = Tuning.skeletonAlpha
            addChild(bones)
        }

        let horizon = SKSpriteNode(color: Palette.horizonGlow,
                                   size: CGSize(width: size.width,
                                                height: Tuning.horizonGlowHeight))
        horizon.position = CGPoint(x: centerX, y: rimY)
        addChild(horizon)

        // the kablammo flash washes the whole sky, Earth included
        skyFlash.color = Palette.flash
        skyFlash.size = CGSize(width: size.width, height: size.height - rimY)
        skyFlash.position = CGPoint(x: centerX, y: (size.height + rimY) / 2)
        skyFlash.alpha = 0
        addChild(skyFlash)

        // lane lines: the rails run from the horizon out into their bumps,
        // so riding one is visible
        for railX in railXs {
            let lane = CGMutablePath()
            lane.move(to: project(railX, 0).point)
            lane.addLine(to: CGPoint(x: railX, y: trackY(railX)))
            let laneNode = SKShapeNode(path: lane)
            laneNode.strokeColor = Palette.laneLine
            laneNode.lineWidth = Tuning.strokeWidth
            laneNode.alpha = Tuning.laneLineAlpha
            addChild(laneNode)
        }

        for railX in railXs {
            let glow = CGMutablePath()
            var first = true
            for x in stride(from: railX - Tuning.railBumpHalfWidth,
                            through: railX + Tuning.railBumpHalfWidth,
                            by: Tuning.trackSampleStep) {
                let p = CGPoint(x: x, y: trackY(x) + Tuning.strokeWidth)
                if first {
                    glow.move(to: p)
                    first = false
                } else {
                    glow.addLine(to: p)
                }
            }
            let node = SKShapeNode(path: glow)
            node.strokeColor = Palette.railHot
            node.glowWidth = Tuning.railGlowWidth
            node.lineWidth = Tuning.railLineWidth
            node.alpha = Tuning.railIdleAlpha
            addChild(node)
            railGlows.append(node)
        }

        for _ in 0..<Tuning.stripeCount {
            let stripe = SKShapeNode()
            stripe.strokeColor = Palette.stripe
            stripe.lineWidth = Tuning.strokeWidth
            addChild(stripe)
            stripes.append(stripe)
        }
    }

    private func buildActors() {
        skimmer.texture = Sprites.skimmer
        skimmer.size = Tuning.skimmerSize
        addChild(skimmer)

        passRing.strokeColor = Palette.enemyMarker
        passRing.fillColor = .clear
        passRing.lineWidth = Tuning.strokeWidth
        addChild(passRing)

        pod.texture = Sprites.pod
        pod.size = Tuning.podSize
        addChild(pod)

        engineGlow.color = Palette.podEngine
        engineGlow.size = Tuning.engineGlowSize
        engineGlow.position = CGPoint(x: 0, y: -Tuning.podSize.height / 2)
        engineGlow.blendMode = .add
        engineGlow.isHidden = true
        pod.addChild(engineGlow)

        // the reticle: ring, four ticks, an open center (ratios are art)
        let r = Tuning.crosshairRadius
        let cross = CGMutablePath()
        cross.addEllipse(in: CGRect(x: -r * 0.6, y: -r * 0.6,
                                    width: r * 1.2, height: r * 1.2))
        cross.move(to: CGPoint(x: -r * 1.2, y: 0))
        cross.addLine(to: CGPoint(x: -r * 0.5, y: 0))
        cross.move(to: CGPoint(x: r * 0.5, y: 0))
        cross.addLine(to: CGPoint(x: r * 1.2, y: 0))
        cross.move(to: CGPoint(x: 0, y: -r * 1.2))
        cross.addLine(to: CGPoint(x: 0, y: -r * 0.5))
        cross.move(to: CGPoint(x: 0, y: r * 0.5))
        cross.addLine(to: CGPoint(x: 0, y: r * 1.2))
        crosshair.path = cross
        crosshair.strokeColor = Palette.reticle
        crosshair.lineWidth = Tuning.strokeWidth
        addChild(crosshair)
    }

    // MARK: loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, Tuning.maxFrameDt)
        lastTime = currentTime
        guard dt > 0 else { return }
        stepCrosshair(dt)
        stepPod(dt)
        stepStripes(dt)
        stepJunk(dt)
        stepSkimmer(dt)
    }

    private func stepCrosshair(_ dt: TimeInterval) {
        if stunRemaining > 0 {
            stunRemaining -= dt
            let rate = Tuning.gravityRecenterPerSecond * Tuning.stunGravityMultiplier
            pullAimHome(CGFloat(min(1, rate * dt)))
            return
        }
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        if held.contains(Key.left) { dx -= 1 }
        if held.contains(Key.right) { dx += 1 }
        if held.contains(Key.down) { dy -= 1 }
        if held.contains(Key.up) { dy += 1 }
        if dx != 0 || dy != 0 {
            idleSeconds = 0
            let step = Tuning.crosshairSpeed * CGFloat(dt)
            crosshair.position.x += dx * step
            crosshair.position.y += dy * step
            clampAim()
            return
        }
        // on a rail the controls are normal: the aim stays where you put it
        guard !isRailed else { return }
        idleSeconds += dt
        guard idleSeconds >= Tuning.gravityGraceSeconds else { return }
        pullAimHome(CGFloat(min(1, Tuning.gravityRecenterPerSecond * dt)))
    }

    // gravity pulls the aim down to trench level and, on the slopes, in toward
    // the flat area; on the flat it leaves the lateral position alone
    private func pullAimHome(_ pull: CGFloat) {
        let gx = crosshair.position.x.clamped(flatMinX, flatMaxX)
        crosshair.position.x += (gx - crosshair.position.x) * pull
        crosshair.position.y += (aimRest.y - crosshair.position.y) * pull
    }

    // the aim lives inside the slot: between the walls, above the track,
    // below the rim. No focus outside the trench.
    private func clampAim() {
        let r = Tuning.crosshairRadius
        let x = crosshair.position.x.clamped(leftWallX + r, rightWallX - r)
        let y = crosshair.position.y.clamped(trackY(x) + r, Tuning.trenchRimY)
        crosshair.position = CGPoint(x: x, y: y)
    }

    private func stepPod(_ dt: TimeInterval) {
        brakeRemaining = max(0, brakeRemaining - dt)
        podAirRemaining = max(0, podAirRemaining - dt)
        let halfW = Tuning.podSize.width / 2
        if let i = railedIndex {
            podX = railXs[i]
            let hardPort = held.contains(Key.left)
                && crosshair.position.x <= leftWallX + Tuning.railEdgeMargin
            let hardStarboard = held.contains(Key.right)
                && crosshair.position.x >= rightWallX - Tuning.railEdgeMargin
            if stunRemaining <= 0, hardPort || hardStarboard {
                dismountAccum += dt
                if dismountAccum >= Tuning.railDismountHoldSeconds { clunkOff() }
            } else {
                dismountAccum = 0
            }
        } else {
            let prevX = podX
            let targetX = crosshair.position.x.clamped(leftWallX + halfW, rightWallX - halfW)
            let follow = CGFloat(1 - exp(-dt / Tuning.aimFollowLag))
            podX += (targetX - podX) * follow
            // the wonk: off-rail you steer yaw, pitch, and aim at once, so the
            // pod's motion smears the aim with it
            crosshair.position.x += (podX - prevX) * Tuning.wonkAimDrag
            clampAim()
            for (i, railX) in railXs.enumerated()
            where abs(podX - railX) < Tuning.railSnapDistance
                && abs(crosshair.position.x - railX) < Tuning.railAimSnapDistance {
                notchIn(i)
                break
            }
        }
        pod.position = CGPoint(x: podX, y: trackY(podX) + Tuning.podSize.height / 2)
        if podAirRemaining > 0 {
            let t = 1 - podAirRemaining / Tuning.podHopSeconds
            pod.position.y += Tuning.podHopHeight * CGFloat(sin(Double.pi * t))
        }
        engineGlow.isHidden = !isRailed
        for (i, glow) in railGlows.enumerated() {
            glow.alpha = i == railedIndex ? 1 : Tuning.railIdleAlpha
        }
    }

    private func notchIn(_ i: Int) {
        railedIndex = i
        dismountAccum = 0
        podX = railXs[i]
        jolt()
        spark(at: CGPoint(x: podX, y: trackY(podX) + Tuning.podSize.height),
              radius: Tuning.sparkRadius)
    }

    private func clunkOff() {
        railedIndex = nil
        dismountAccum = 0
        jolt()
        spark(at: pod.position, radius: Tuning.sparkRadius)
    }

    private func slamLock() {
        guard let i = railXs.indices.min(by: { abs(podX - railXs[$0]) < abs(podX - railXs[$1]) })
        else { return }
        railedIndex = i
        dismountAccum = 0
        podX = railXs[i]
        brakeRemaining = Tuning.brakeSeconds
        jolt()
        spark(at: CGPoint(x: podX, y: trackY(podX) + Tuning.podSize.height),
              radius: Tuning.sparkRadius)
    }

    private func podHop() {
        guard podAirRemaining <= 0 else { return }
        podAirRemaining = Tuning.podHopSeconds
    }

    private func jolt() {
        pod.run(.sequence([
            .scaleY(to: Tuning.joltScaleY, duration: Tuning.joltInSeconds),
            .scaleY(to: 1, duration: Tuning.joltOutSeconds),
        ]))
    }

    private func spark(at point: CGPoint, radius: CGFloat) {
        let s = SKShapeNode(circleOfRadius: radius)
        s.position = point
        s.strokeColor = Palette.spark
        s.lineWidth = Tuning.strokeWidth
        addChild(s)
        s.run(.sequence([
            .group([.scale(to: Tuning.killPopScale, duration: Tuning.tracerFadeSeconds),
                    .fadeOut(withDuration: Tuning.tracerFadeSeconds)]),
            .removeFromParent(),
        ]))
    }

    private func stepStripes(_ dt: TimeInterval) {
        stripePhase = (stripePhase + dt * Tuning.trackScrollPerSecond * forwardScale)
            .truncatingRemainder(dividingBy: 1)
        for (i, stripe) in stripes.enumerated() {
            let d = (stripePhase + Double(i) / Double(Tuning.stripeCount))
                .truncatingRemainder(dividingBy: 1)
            let path = CGMutablePath()
            var first = true
            for x in stride(from: leftWallX, through: rightWallX, by: Tuning.stripeSampleStep) {
                let p = project(x, d).point
                if first {
                    path.move(to: p)
                    first = false
                } else {
                    path.addLine(to: p)
                }
            }
            stripe.path = path
            stripe.alpha = Tuning.stripeAlphaBase + Tuning.stripeAlphaGain * CGFloat(d)
        }
    }

    private func stepJunk(_ dt: TimeInterval) {
        junkSpawnCountdown -= dt
        if junkSpawnCountdown <= 0 {
            spawnJunk()
            junkSpawnCountdown = Tuning.junkSpawnSeconds
        }
        // junk is stationary in the slot; it closes at the pod's forward
        // speed, so going fast on a rail makes it loom twice as fast
        let closeRate = Tuning.trackScrollPerSecond * forwardScale
        for i in junkPieces.indices {
            junkPieces[i].progress += dt * closeRate
            let piece = junkPieces[i]
            if piece.progress >= 1 {
                resolveJunkArrival(piece)
            } else {
                _ = place(piece.node, nearX: piece.laneX, depth: piece.progress,
                          height: piece.size.height)
            }
        }
        junkPieces.removeAll { $0.progress >= 1 }
    }

    // junk follows the rules too: it sits on a lane. Battle debris, so the
    // pieces and sizes vary.
    private func spawnJunk() {
        let lane = railXs.randomElement() ?? centerX
        let art = Sprites.junkArts.randomElement() ?? Sprites.junkArts[0]
        let spread = CGFloat.random(in: Tuning.junkScaleMin...Tuning.junkScaleMax)
        let junkSize = CGSize(width: art.size.width * spread,
                              height: art.size.height * spread)
        let node = SKSpriteNode(texture: art.texture)
        node.size = junkSize
        _ = place(node, nearX: lane, depth: 0, height: junkSize.height)
        addChild(node)
        junkPieces.append(Junk(node: node, laneX: lane, size: junkSize, progress: 0))
    }

    private func resolveJunkArrival(_ piece: Junk) {
        let reach = (piece.size.width + Tuning.podSize.width) / 2
        // an airborne pod sails over arriving junk
        if abs(piece.laneX - podX) < reach, podAirRemaining <= 0 { stunPod() }
        piece.node.run(.sequence([.fadeOut(withDuration: Tuning.junkFadeSeconds),
                                  .removeFromParent()]))
    }

    private func stunPod() {
        stunRemaining = Tuning.stunSeconds
        railedIndex = nil
        let flickers = Int(Tuning.stunSeconds / (2 * Tuning.stunFlickerSeconds))
        pod.run(.repeat(.sequence([
            .fadeAlpha(to: Tuning.stunFlickerAlpha, duration: Tuning.stunFlickerSeconds),
            .fadeAlpha(to: 1, duration: Tuning.stunFlickerSeconds),
        ]), count: flickers))
    }

    private func stepSkimmer(_ dt: TimeInterval) {
        guard skimmerAlive else {
            respawnCountdown -= dt
            if respawnCountdown <= 0 { spawnSkimmer() }
            return
        }
        // the quarry runs AWAY: the clock is the chase, the horizon is escape
        skimmerElapsed += dt * escapeScale
        if skimmerElapsed / Tuning.passClockSeconds >= 1 {
            skimmerEscaped()
            return
        }
        // mercy: a fleeing racer eases off once to keep a losing player in it
        if !skimmerHasBraked, passes > kills,
           skimmerElapsed / Tuning.passClockSeconds >= Tuning.mercyEscapeFraction {
            skimmerHasBraked = true
            skimmerElapsed = max(0, skimmerElapsed - Tuning.skimmerBrakeSeconds)
            spark(at: skimmer.position, radius: Tuning.sparkRadius)
        }
        if let target = hopTarget {
            hopT += dt
            let t = min(1, hopT / Tuning.skimmerHopSeconds)
            skimmerX = hopFromX + (railXs[target] - hopFromX) * CGFloat(t)
            if t >= 1 {
                skimmerLane = target
                hopTarget = nil
                hopCountdown = nextHopDelay()
            }
        } else {
            skimmerX = railXs[skimmerLane]
            hopCountdown -= dt
            if hopCountdown <= 0 { startHop() }
        }
        let progress = skimmerElapsed / Tuning.passClockSeconds
        let depth = Tuning.skimmerSpawnDepth * (1 - progress)
        let f = place(skimmer, nearX: skimmerX, depth: depth,
                      height: Tuning.skimmerSize.height)
        passRing.position = skimmer.position
        let ringScale = Tuning.passRingMinScale
            + (1 - Tuning.passRingMinScale) * CGFloat(1 - progress)
        passRing.setScale(ringScale * f)
    }

    private func nextHopDelay() -> TimeInterval {
        Tuning.skimmerHopIntervalSeconds + .random(in: 0...Tuning.skimmerHopJitterSeconds)
    }

    private func startHop() {
        let options = [skimmerLane - 1, skimmerLane + 1].filter { railXs.indices.contains($0) }
        guard let target = options.randomElement() else { return }
        hopTarget = target
        hopFromX = skimmerX
        hopT = 0
    }

    // MARK: skimmer lifecycle

    private func spawnSkimmer() {
        skimmerLane = railXs.indices.randomElement() ?? 0
        skimmerX = railXs[skimmerLane]
        hopTarget = nil
        hopCountdown = nextHopDelay()
        skimmerElapsed = 0
        skimmerHasBraked = false
        skimmerAlive = true
        let f = place(skimmer, nearX: skimmerX, depth: Tuning.skimmerSpawnDepth,
                      height: Tuning.skimmerSize.height)
        passRing.position = skimmer.position
        passRing.setScale(f)
        skimmer.isHidden = false
        passRing.isHidden = false
    }

    private func despawnSkimmer() {
        skimmerAlive = false
        skimmer.isHidden = true
        passRing.isHidden = true
        respawnCountdown = Tuning.respawnDelaySeconds
    }

    private func killSkimmer() {
        kills += 1
        spark(at: skimmer.position, radius: Tuning.hitRadius)
        for i in 0..<Tuning.fragmentCount {
            let frag = SKSpriteNode(color: Palette.enemyEngine, size: Tuning.fragmentSize)
            frag.position = skimmer.position
            let angle = Double(i) / Double(Tuning.fragmentCount) * 2 * Double.pi
            frag.run(.sequence([
                .group([.moveBy(x: CGFloat(cos(angle)) * Tuning.fragmentDistance,
                                y: CGFloat(sin(angle)) * Tuning.fragmentDistance,
                                duration: Tuning.fragmentSeconds),
                        .fadeOut(withDuration: Tuning.fragmentSeconds)]),
                .removeFromParent(),
            ]))
            addChild(frag)
        }
        despawnSkimmer()
    }

    // kablammo: the quarry made the distance
    private func skimmerEscaped() {
        passes += 1
        skyFlash.removeAllActions()
        skyFlash.run(.sequence([
            .fadeAlpha(to: Tuning.passFlashAlpha, duration: Tuning.passFlashInSeconds),
            .fadeAlpha(to: 0, duration: Tuning.passFlashOutSeconds),
        ]))
        despawnSkimmer()
    }

    // MARK: fire

    private func fire() {
        guard stunRemaining <= 0 else { return }
        // railed with the aim up your own notch: the bolt runs the lane and
        // blasts everything in that line
        if let i = railedIndex, aimIsUpLane(railXs[i]) {
            fireUpLane(railXs[i])
            return
        }
        drawTracer(to: crosshair.position)
        // one target per shot: the skimmer first, then junk in the way
        if skimmerAlive, aimDistance(to: skimmer.position) <= Tuning.hitRadius {
            killSkimmer()
            return
        }
        if let i = junkPieces.firstIndex(where: {
            aimDistance(to: $0.node.position) <= Tuning.hitRadius
        }) {
            spark(at: junkPieces[i].node.position, radius: Tuning.sparkRadius)
            junkPieces[i].node.removeFromParent()
            junkPieces.remove(at: i)
        }
    }

    // distance from the crosshair to the lane's line, near bump to horizon
    private func aimIsUpLane(_ railX: CGFloat) -> Bool {
        let a = CGPoint(x: railX, y: trackY(railX))
        let b = project(railX, 0).point
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let ap = CGPoint(x: crosshair.position.x - a.x, y: crosshair.position.y - a.y)
        let len2 = ab.x * ab.x + ab.y * ab.y
        let t = ((ap.x * ab.x + ap.y * ab.y) / len2).clamped(0, 1)
        let closest = CGPoint(x: a.x + ab.x * t, y: a.y + ab.y * t)
        return hypot(crosshair.position.x - closest.x,
                     crosshair.position.y - closest.y) <= Tuning.laneShotTolerance
    }

    private func fireUpLane(_ railX: CGFloat) {
        drawTracer(to: project(railX, 0).point)
        for piece in junkPieces where piece.laneX == railX {
            spark(at: piece.node.position, radius: Tuning.sparkRadius)
            piece.node.removeFromParent()
        }
        junkPieces.removeAll { $0.laneX == railX }
        if skimmerAlive, hopTarget == nil, railXs[skimmerLane] == railX {
            killSkimmer()
        }
    }

    private func drawTracer(to point: CGPoint) {
        let tracer = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: pod.position)
        p.addLine(to: point)
        tracer.path = p
        tracer.strokeColor = Palette.tracer
        tracer.glowWidth = Tuning.tracerGlowWidth
        tracer.lineWidth = Tuning.strokeWidth
        addChild(tracer)
        tracer.run(.sequence([.fadeOut(withDuration: Tuning.tracerFadeSeconds),
                              .removeFromParent()]))
    }

    private func aimDistance(to point: CGPoint) -> CGFloat {
        hypot(crosshair.position.x - point.x, crosshair.position.y - point.y)
    }

    // MARK: input

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == "q" {
            NSApp.terminate(nil)
            return
        }
        if event.keyCode == Key.space {
            if !event.isARepeat { fire() }
            return
        }
        if event.keyCode == Key.down, !event.isARepeat, stunRemaining <= 0 {
            if event.timestamp - lastDownTap <= Tuning.railDoubleTapSeconds {
                // double-down: off a rail = clunk off; on the floor = slam
                // lock into the nearest rail, at the cost of a hard brake
                if isRailed { clunkOff() } else { slamLock() }
            }
            lastDownTap = event.timestamp
        }
        if event.keyCode == Key.up, !event.isARepeat, stunRemaining <= 0 {
            if event.timestamp - lastUpTap <= Tuning.railDoubleTapSeconds {
                podHop()
            }
            lastUpTap = event.timestamp
        }
        held.insert(event.keyCode)
    }

    override func keyUp(with event: NSEvent) {
        held.remove(event.keyCode)
    }
}

private extension Comparable {
    func clamped(_ lo: Self, _ hi: Self) -> Self { min(max(self, lo), hi) }
}
