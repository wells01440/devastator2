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

    private var held = Set<UInt16>()
    private var lastTime: TimeInterval = 0

    private let skyFlash = SKSpriteNode()
    private let pod = SKSpriteNode()
    private let crosshair = SKShapeNode()
    private let obstacle = SKSpriteNode()
    private let skimmer = SKSpriteNode()
    private let passRing = SKShapeNode(circleOfRadius: Tuning.passRingRadius)
    private let debugLine = SKLabelNode()

    private var podX: CGFloat = 0
    private var skimmerAlive = false
    private var skimmerLaneX: CGFloat = 0
    private var skimmerElapsed: TimeInterval = 0
    private var respawnCountdown: TimeInterval = 0
    private var kills = 0
    private var passes = 0

    private var centerX: CGFloat { size.width / 2 }
    private var leftWallX: CGFloat { Tuning.trenchWallInset }
    private var rightWallX: CGFloat { size.width - Tuning.trenchWallInset }
    private var aimRest: CGPoint {
        CGPoint(x: centerX, y: Tuning.trenchBottomY + Tuning.aimRestHeight)
    }

    // the U: track height at x, trench bottom at center rising to the rim at the walls
    private func trackY(_ x: CGFloat) -> CGFloat {
        let t = min(1, abs(x - centerX) / (centerX - Tuning.trenchWallInset))
        return Tuning.trenchBottomY + (Tuning.trenchRimY - Tuning.trenchBottomY) * t * t
    }

    private func grey(_ white: CGFloat) -> SKColor { SKColor(white: white, alpha: 1) }

    // MARK: build

    override func didMove(to view: SKView) {
        backgroundColor = .black
        buildTrench()
        buildActors()
        podX = centerX
        crosshair.position = aimRest
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
    }

    private func buildActors() {
        obstacle.color = grey(Tuning.obstacleGrey)
        obstacle.size = Tuning.obstacleSize
        let ox = centerX + Tuning.obstacleOffsetX
        obstacle.position = CGPoint(x: ox, y: trackY(ox) + Tuning.obstacleSize.height / 2)
        addChild(obstacle)

        pod.color = grey(Tuning.podGrey)
        pod.size = Tuning.podSize
        addChild(pod)

        skimmer.color = grey(Tuning.skimmerGrey)
        skimmer.size = Tuning.skimmerSize
        addChild(skimmer)

        passRing.strokeColor = .white
        passRing.lineWidth = Tuning.strokeWidth
        addChild(passRing)

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
        stepSkimmer(dt)
        let clock = skimmerAlive ? max(0, Tuning.passClockSeconds - skimmerElapsed) : 0
        debugLine.text = String(format: "kills %d   passes %d   clock %.1f", kills, passes, clock)
    }

    private func stepCrosshair(_ dt: TimeInterval) {
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        if held.contains(Key.left) { dx -= 1 }
        if held.contains(Key.right) { dx += 1 }
        if held.contains(Key.down) { dy -= 1 }
        if held.contains(Key.up) { dy += 1 }
        if dx == 0 && dy == 0 {
            let pull = CGFloat(min(1, Tuning.gravityRecenterPerSecond * dt))
            crosshair.position.x += (aimRest.x - crosshair.position.x) * pull
            crosshair.position.y += (aimRest.y - crosshair.position.y) * pull
        } else {
            let r = Tuning.crosshairRadius
            let step = Tuning.crosshairSpeed * CGFloat(dt)
            crosshair.position.x = (crosshair.position.x + dx * step).clamped(r, size.width - r)
            crosshair.position.y = (crosshair.position.y + dy * step).clamped(r, size.height - r)
        }
    }

    private func stepPod(_ dt: TimeInterval) {
        let halfW = Tuning.podSize.width / 2
        let targetX = crosshair.position.x.clamped(leftWallX + halfW, rightWallX - halfW)
        let follow = CGFloat(1 - exp(-dt / Tuning.aimFollowLag))
        var newX = podX + (targetX - podX) * follow

        // the obstacle blocks the U unless the aim routes up and over it
        let spanMin = obstacle.position.x - obstacle.size.width / 2 - halfW
        let spanMax = obstacle.position.x + obstacle.size.width / 2 + halfW
        let obstacleTop = obstacle.position.y + obstacle.size.height / 2
        let mayCross = crosshair.position.y > obstacleTop + Tuning.obstacleClearance
        if !mayCross {
            if podX <= spanMin && newX > spanMin { newX = spanMin }
            if podX >= spanMax && newX < spanMax { newX = spanMax }
        }
        podX = newX

        let overObstacle = newX > spanMin && newX < spanMax
        let baseY = overObstacle ? obstacleTop : trackY(newX)
        pod.position = CGPoint(x: newX, y: baseY + Tuning.podSize.height / 2)
    }

    private func stepSkimmer(_ dt: TimeInterval) {
        guard skimmerAlive else {
            respawnCountdown -= dt
            if respawnCountdown <= 0 { spawnSkimmer() }
            return
        }
        skimmerElapsed += dt
        let progress = skimmerElapsed / Tuning.passClockSeconds
        if progress >= 1 {
            skimmerPassed()
            return
        }
        let weave = CGFloat(sin(2 * Double.pi * Tuning.skimmerWeaveHz * skimmerElapsed))
        let halfW = Tuning.skimmerSize.width / 2
        let x = (skimmerLaneX + Tuning.skimmerWeaveAmplitude * weave)
            .clamped(leftWallX + halfW, rightWallX - halfW)
        let farY = Tuning.trenchRimY - Tuning.skimmerSize.height
        let nearY = trackY(x) + Tuning.skimmerSize.height / 2
        skimmer.position = CGPoint(x: x, y: farY + (nearY - farY) * CGFloat(progress))
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
                                   y: Tuning.trenchRimY - Tuning.skimmerSize.height)
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
        let pop = SKShapeNode(circleOfRadius: Tuning.hitRadius)
        pop.position = skimmer.position
        pop.strokeColor = .white
        pop.lineWidth = Tuning.strokeWidth
        addChild(pop)
        pop.run(.sequence([
            .group([.scale(to: Tuning.killPopScale, duration: Tuning.tracerFadeSeconds),
                    .fadeOut(withDuration: Tuning.tracerFadeSeconds)]),
            .removeFromParent(),
        ]))
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

        guard skimmerAlive else { return }
        let d = hypot(crosshair.position.x - skimmer.position.x,
                      crosshair.position.y - skimmer.position.y)
        if d <= Tuning.hitRadius { killSkimmer() }
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
        held.insert(event.keyCode)
    }

    override func keyUp(with event: NSEvent) {
        held.remove(event.keyCode)
    }
}

private extension Comparable {
    func clamped(_ lo: Self, _ hi: Self) -> Self { min(max(self, lo), hi) }
}
