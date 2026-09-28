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
        var progress: Double
    }

    private var held = Set<UInt16>()
    private var lastTime: TimeInterval = 0

    private let skyFlash = SKSpriteNode()
    private var railGlows: [SKShapeNode] = []
    private let pod = SKSpriteNode()
    private let crosshair = SKShapeNode()
    private let skimmer = SKSpriteNode()
    private let passRing = SKShapeNode(circleOfRadius: Tuning.passRingRadius)
    private let debugLine = SKLabelNode()
    private var stripes: [SKShapeNode] = []

    private var podX: CGFloat = 0
    private var railedIndex: Int?
    private var dismountAccum: TimeInterval = 0
    private var lastDownTap: TimeInterval = 0
    private var stunRemaining: TimeInterval = 0
    private var idleSeconds: TimeInterval = 0
    private var stripePhase = 0.0
    private var junkPieces: [Junk] = []
    private var junkSpawnCountdown: TimeInterval = 0
    private var skimmerAlive = false
    private var skimmerLaneX: CGFloat = 0
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

    private func railLabel(_ i: Int) -> String {
        i == 0 ? "L" : i == railXs.count - 1 ? "R" : "C"
    }

    // the trench profile, rear-forward view: flat floor with a rail bump per
    // lane, straight slopes to the rim at the walls
    private func trackY(_ x: CGFloat) -> CGFloat {
        if let nearest = railXs.min(by: { abs(x - $0) < abs(x - $1) }),
           abs(x - nearest) <= Tuning.railBumpHalfWidth {
            let t = abs(x - nearest) / Tuning.railBumpHalfWidth
            return Tuning.trenchBottomY + Tuning.railBumpHeight * (1 - t * t)
        }
        let a = abs(x - centerX)
        guard a > Tuning.flatHalfWidth else { return Tuning.trenchBottomY }
        let run = centerX - Tuning.trenchWallInset - Tuning.flatHalfWidth
        let t = min(1, (a - Tuning.flatHalfWidth) / run)
        return Tuning.trenchBottomY + (Tuning.trenchRimY - Tuning.trenchBottomY) * t
    }

    // depth 0 is the far rim, depth 1 is the near track surface at x
    private func depthY(_ x: CGFloat, _ progress: Double, height: CGFloat) -> CGFloat {
        let farY = Tuning.trenchRimY - height
        let nearY = trackY(x) + height / 2
        return farY + (nearY - farY) * CGFloat(progress)
    }

    private func grey(_ white: CGFloat) -> SKColor { SKColor(white: white, alpha: 1) }

    // MARK: build

    override func didMove(to view: SKView) {
        backgroundColor = .black
        buildTrench()
        buildActors()
        podX = centerX
        crosshair.position = aimRest
        junkSpawnCountdown = Tuning.junkSpawnSeconds
        spawnSkimmer()
    }

    private func buildTrench() {
        let sky = SKSpriteNode(color: grey(Tuning.skyGrey),
                               size: CGSize(width: size.width, height: Tuning.skyBandHeight))
        sky.position = CGPoint(x: centerX, y: size.height - Tuning.skyBandHeight / 2)
        addChild(sky)

        skyFlash.color = .white
        skyFlash.size = sky.size
        skyFlash.position = sky.position
        skyFlash.alpha = 0
        addChild(skyFlash)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: Tuning.trenchRimY))
        for x in stride(from: CGFloat(0), through: size.width, by: Tuning.trackSampleStep) {
            path.addLine(to: CGPoint(x: x, y: trackY(x)))
        }
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.closeSubpath()
        let rock = SKShapeNode(path: path)
        rock.fillColor = grey(Tuning.rockGrey)
        rock.strokeColor = grey(Tuning.edgeGrey)
        rock.lineWidth = Tuning.strokeWidth
        addChild(rock)

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
            node.strokeColor = .white
            node.lineWidth = Tuning.railLineWidth
            node.alpha = Tuning.railIdleAlpha
            addChild(node)
            railGlows.append(node)
        }

        for _ in 0..<Tuning.stripeCount {
            let stripe = SKShapeNode()
            stripe.strokeColor = grey(Tuning.edgeGrey)
            stripe.lineWidth = Tuning.strokeWidth
            addChild(stripe)
            stripes.append(stripe)
        }
    }

    private func buildActors() {
        skimmer.color = grey(Tuning.skimmerGrey)
        skimmer.size = Tuning.skimmerSize
        addChild(skimmer)

        passRing.strokeColor = .white
        passRing.lineWidth = Tuning.strokeWidth
        addChild(passRing)

        pod.color = grey(Tuning.podGrey)
        pod.size = Tuning.podSize
        addChild(pod)

        let r = Tuning.crosshairRadius
        let cross = CGMutablePath()
        cross.move(to: CGPoint(x: -r, y: 0))
        cross.addLine(to: CGPoint(x: r, y: 0))
        cross.move(to: CGPoint(x: 0, y: -r))
        cross.addLine(to: CGPoint(x: 0, y: r))
        crosshair.path = cross
        crosshair.strokeColor = .white
        crosshair.lineWidth = Tuning.strokeWidth
        addChild(crosshair)

        debugLine.fontName = "Menlo"
        debugLine.fontSize = Tuning.debugFontSize
        debugLine.fontColor = grey(Tuning.edgeGrey)
        debugLine.horizontalAlignmentMode = .left
        debugLine.position = CGPoint(x: Tuning.debugInset, y: Tuning.debugInset)
        addChild(debugLine)
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
        let clock = skimmerAlive ? max(0, Tuning.passClockSeconds - skimmerElapsed) : 0
        var state = ""
        if stunRemaining > 0 {
            state = "   STUN"
        } else if let i = railedIndex {
            state = "   RAIL \(railLabel(i))"
        }
        debugLine.text = String(format: "kills %d   passes %d   clock %.1f%@",
                                kills, passes, clock, state)
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
            let r = Tuning.crosshairRadius
            let step = Tuning.crosshairSpeed * CGFloat(dt)
            crosshair.position.x = (crosshair.position.x + dx * step).clamped(r, size.width - r)
            crosshair.position.y = (crosshair.position.y + dy * step).clamped(r, size.height - r)
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

    private func stepPod(_ dt: TimeInterval) {
        let halfW = Tuning.podSize.width / 2
        if let i = railedIndex {
            podX = railXs[i]
            let hardPort = held.contains(Key.left)
                && crosshair.position.x <= Tuning.railEdgeMargin
            let hardStarboard = held.contains(Key.right)
                && crosshair.position.x >= size.width - Tuning.railEdgeMargin
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
            for (i, railX) in railXs.enumerated()
            where abs(podX - railX) < Tuning.railSnapDistance
                && abs(crosshair.position.x - railX) < Tuning.railAimSnapDistance {
                notchIn(i)
                break
            }
        }
        pod.position = CGPoint(x: podX, y: trackY(podX) + Tuning.podSize.height / 2)
        pod.color = grey(isRailed ? Tuning.podRailGrey : Tuning.podGrey)
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

    private func jolt() {
        pod.run(.sequence([
            .scaleY(to: Tuning.joltScaleY, duration: Tuning.joltInSeconds),
            .scaleY(to: 1, duration: Tuning.joltOutSeconds),
        ]))
    }

    private func spark(at point: CGPoint, radius: CGFloat) {
        let s = SKShapeNode(circleOfRadius: radius)
        s.position = point
        s.strokeColor = .white
        s.lineWidth = Tuning.strokeWidth
        addChild(s)
        s.run(.sequence([
            .group([.scale(to: Tuning.killPopScale, duration: Tuning.tracerFadeSeconds),
                    .fadeOut(withDuration: Tuning.tracerFadeSeconds)]),
            .removeFromParent(),
        ]))
    }

    private func stepStripes(_ dt: TimeInterval) {
        let scale = isRailed ? Tuning.railScrollScale : 1
        stripePhase = (stripePhase + dt * Tuning.trackScrollPerSecond * scale)
            .truncatingRemainder(dividingBy: 1)
        for (i, stripe) in stripes.enumerated() {
            let d = (stripePhase + Double(i) / Double(Tuning.stripeCount))
                .truncatingRemainder(dividingBy: 1)
            let path = CGMutablePath()
            var first = true
            for x in stride(from: leftWallX, through: rightWallX, by: Tuning.stripeSampleStep) {
                let y = Tuning.trenchRimY + (trackY(x) - Tuning.trenchRimY) * CGFloat(d)
                if first {
                    path.move(to: CGPoint(x: x, y: y))
                    first = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
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
        for i in junkPieces.indices {
            junkPieces[i].progress += dt / Tuning.junkTravelSeconds
            let piece = junkPieces[i]
            if piece.progress >= 1 {
                resolveJunkArrival(piece)
            } else {
                piece.node.position = CGPoint(
                    x: piece.laneX,
                    y: depthY(piece.laneX, piece.progress, height: Tuning.junkSize.height))
            }
        }
        junkPieces.removeAll { $0.progress >= 1 }
    }

    private func spawnJunk() {
        let half = Tuning.junkSize.width / 2
        let onRail = Double.random(in: 0..<1) < Tuning.railJunkChance
        let lane = onRail
            ? railXs.randomElement() ?? centerX
            : CGFloat.random(in: (leftWallX + half)...(rightWallX - half))
        let node = SKSpriteNode(color: grey(Tuning.junkGrey), size: Tuning.junkSize)
        node.position = CGPoint(x: lane, y: depthY(lane, 0, height: Tuning.junkSize.height))
        addChild(node)
        junkPieces.append(Junk(node: node, laneX: lane, progress: 0))
    }

    private func resolveJunkArrival(_ piece: Junk) {
        let reach = (Tuning.junkSize.width + Tuning.podSize.width) / 2
        if abs(piece.laneX - podX) < reach { stunPod() }
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
        skimmerElapsed += dt * (isRailed ? Tuning.railClockScale : 1)
        let progress = skimmerElapsed / Tuning.passClockSeconds
        if progress >= 1 {
            skimmerPassed()
            return
        }
        let weave = CGFloat(sin(2 * Double.pi * Tuning.skimmerWeaveHz * skimmerElapsed))
        let halfW = Tuning.skimmerSize.width / 2
        let x = (skimmerLaneX + Tuning.skimmerWeaveAmplitude * weave)
            .clamped(leftWallX + halfW, rightWallX - halfW)
        skimmer.position = CGPoint(x: x, y: depthY(x, progress, height: Tuning.skimmerSize.height))
        passRing.position = skimmer.position
        passRing.setScale(CGFloat(1 - progress))
    }

    // MARK: skimmer lifecycle

    private func spawnSkimmer() {
        let margin = Tuning.skimmerWeaveAmplitude + Tuning.skimmerSize.width
        skimmerLaneX = .random(in: (leftWallX + margin)...(rightWallX - margin))
        skimmerElapsed = 0
        skimmerAlive = true
        skimmer.position = CGPoint(x: skimmerLaneX,
                                   y: depthY(skimmerLaneX, 0, height: Tuning.skimmerSize.height))
        passRing.position = skimmer.position
        passRing.setScale(1)
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
        despawnSkimmer()
    }

    private func skimmerPassed() {
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
        let tracer = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: pod.position)
        p.addLine(to: crosshair.position)
        tracer.path = p
        tracer.strokeColor = .white
        tracer.lineWidth = Tuning.strokeWidth
        addChild(tracer)
        tracer.run(.sequence([.fadeOut(withDuration: Tuning.tracerFadeSeconds),
                              .removeFromParent()]))

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
        if event.keyCode == Key.down, isRailed, !event.isARepeat, stunRemaining <= 0 {
            if event.timestamp - lastDownTap <= Tuning.railDoubleTapSeconds {
                clunkOff()
            }
            lastDownTap = event.timestamp
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
