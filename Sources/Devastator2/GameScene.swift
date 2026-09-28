import SpriteKit

// The lunar transit tube. One axis: you shuttle around the five railed
// walls of a hexagonal bore whose roofline is open to the surface. Your
// shot goes straight down the tube. Mechanics settled with the owner;
// AGENTS.md is the brief.
final class GameScene: SKScene {

    private enum Key {
        static let left: UInt16 = 123
        static let right: UInt16 = 124
        static let down: UInt16 = 125
        static let up: UInt16 = 126
        static let space: UInt16 = 49
    }

    private struct Wall {
        let a: CGPoint
        let b: CGPoint
        let length: CGFloat
        let start: CGFloat // cumulative perimeter length at a
        let dir: CGVector // unit, a toward b
        let normal: CGVector // unit, into the tube
        let rotation: CGFloat // zRotation for a sprite standing on this wall
    }

    private struct Junk {
        let node: SKSpriteNode
        let rail: Int
        let size: CGSize
        let tilt: CGFloat
        var progress: Double
    }

    private enum StreamerFlavor {
        case surface, wall, pulse
    }

    private struct Streamer {
        let node: SKNode
        let flavor: StreamerFlavor
        var anchor: CGPoint
        var depth: Double
    }

    // MARK: state

    private var held = Set<UInt16>()
    private var lastTime: TimeInterval = 0
    private var worldTime: TimeInterval = 0

    private let skyFlash = SKSpriteNode()
    private let pod = SKSpriteNode()
    private let engineGlow = SKSpriteNode()
    private let sightBeam = SKShapeNode()
    private let farSight = SKShapeNode()
    private let mouth = SKShapeNode()
    private let skimmer = SKSpriteNode()
    private let passRing = SKShapeNode(circleOfRadius: Tuning.passRingRadius)
    private var railGlows: [SKShapeNode] = []
    private var stripes: [SKShapeNode] = []
    private var streamers: [Streamer] = []

    private var walls: [Wall] = []
    private var perimeterLength: CGFloat = 0
    private var railTs: [CGFloat] = []

    private var podT: CGFloat = 0.5
    private var podRotation: CGFloat = 0
    private var railedIndex: Int?
    private var stickAccum: TimeInterval = 0
    private var notchCooldown: TimeInterval = 0
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
    private var skimmerT: CGFloat = 0
    private var hopTarget: Int?
    private var hopFromT: CGFloat = 0
    private var hopT: TimeInterval = 0
    private var hopCountdown: TimeInterval = 0
    private var skimmerElapsed: TimeInterval = 0
    private var respawnCountdown: TimeInterval = 0
    private var kills = 0
    private var passes = 0

    private var centerX: CGFloat { size.width / 2 }
    private var tubeCenter: CGPoint { CGPoint(x: centerX, y: Tuning.hexWaistY) }
    private var isRailed: Bool { railedIndex != nil }
    private var bottomRailT: CGFloat { railTs[Tuning.railCount / 2] }

    // your forward speed through the tube, and how fast the quarry gains:
    // braking beats railing beats coasting
    private var forwardScale: Double {
        brakeRemaining > 0 ? Tuning.brakeScrollScale : isRailed ? Tuning.railScrollScale : 1
    }
    private var escapeScale: Double {
        brakeRemaining > 0 ? Tuning.brakeEscapeScale : isRailed ? Tuning.railClockScale : 1
    }

    // MARK: the bore

    // vertices, roofline first: TL, L, BL, BR, R, TR. The railed perimeter
    // runs TL -> L -> BL -> BR -> R -> TR; the roof edge TR -> TL is the
    // open surface side.
    private var hexVertices: [CGPoint] {
        [CGPoint(x: centerX - Tuning.hexEdgeHalf, y: Tuning.hexTopY),
         CGPoint(x: centerX - Tuning.hexWaistHalf, y: Tuning.hexWaistY),
         CGPoint(x: centerX - Tuning.hexEdgeHalf, y: Tuning.hexBottomY),
         CGPoint(x: centerX + Tuning.hexEdgeHalf, y: Tuning.hexBottomY),
         CGPoint(x: centerX + Tuning.hexWaistHalf, y: Tuning.hexWaistY),
         CGPoint(x: centerX + Tuning.hexEdgeHalf, y: Tuning.hexTopY)]
    }

    private func buildWalls() {
        let v = hexVertices
        walls = []
        var cursor: CGFloat = 0
        for i in 0..<Tuning.railCount {
            let a = v[i]
            let b = v[i + 1]
            let len = hypot(b.x - a.x, b.y - a.y)
            let dir = CGVector(dx: (b.x - a.x) / len, dy: (b.y - a.y) / len)
            var normal = CGVector(dx: -dir.dy, dy: dir.dx)
            let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            if (tubeCenter.x - mid.x) * normal.dx + (tubeCenter.y - mid.y) * normal.dy < 0 {
                normal = CGVector(dx: -normal.dx, dy: -normal.dy)
            }
            let rotation = atan2(normal.dy, normal.dx) - .pi / 2
            walls.append(Wall(a: a, b: b, length: len, start: cursor,
                              dir: dir, normal: normal, rotation: rotation))
            cursor += len
        }
        perimeterLength = cursor
        railTs = walls.map { ($0.start + $0.length / 2) / cursor }
    }

    private func wallIndex(at t: CGFloat) -> Int {
        let s = t.clamped(0, 1) * perimeterLength
        for (i, w) in walls.enumerated() where s <= w.start + w.length {
            return i
        }
        return walls.count - 1
    }

    private func wallFrame(at t: CGFloat) -> (point: CGPoint, wall: Wall) {
        let w = walls[wallIndex(at: t)]
        let s = t.clamped(0, 1) * perimeterLength - w.start
        return (CGPoint(x: w.a.x + w.dir.dx * s, y: w.a.y + w.dir.dy * s), w)
    }

    private func laneDistance(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        abs(a - b) * perimeterLength
    }

    // hexagon interior half width at height y; negative means no interior
    private func hexHalfWidth(at y: CGFloat) -> CGFloat {
        if y < Tuning.hexBottomY || y > Tuning.hexTopY { return -1 }
        if y <= Tuning.hexWaistY {
            let t = (y - Tuning.hexBottomY) / (Tuning.hexWaistY - Tuning.hexBottomY)
            return Tuning.hexEdgeHalf + (Tuning.hexWaistHalf - Tuning.hexEdgeHalf) * t
        }
        let t = (y - Tuning.hexWaistY) / (Tuning.hexTopY - Tuning.hexWaistY)
        return Tuning.hexWaistHalf + (Tuning.hexEdgeHalf - Tuning.hexWaistHalf) * t
    }

    // MARK: perspective

    // one perspective for everything in the tube: depth 0 is the far mouth
    // at the bore's center, depth 1 is the player's cross-section
    private func projectPoint(_ near: CGPoint, _ depth: Double) -> (point: CGPoint, scale: CGFloat) {
        let f = Tuning.farPointScale
            + (1 - Tuning.farPointScale) * CGFloat(pow(depth, Tuning.depthExponent))
        let point = CGPoint(x: tubeCenter.x + (near.x - tubeCenter.x) * f,
                            y: tubeCenter.y + (near.y - tubeCenter.y) * f)
        return (point, f)
    }

    // screen placement for a sprite riding a wall at perimeter t
    @discardableResult
    private func placeOnWall(_ node: SKNode, t: CGFloat, depth: Double,
                             height: CGFloat, lift: CGFloat = 0) -> CGFloat {
        let frame = wallFrame(at: t)
        let anchor = CGPoint(x: frame.point.x + frame.wall.normal.dx * (height / 2 + lift),
                             y: frame.point.y + frame.wall.normal.dy * (height / 2 + lift))
        let (p, f) = projectPoint(anchor, depth)
        node.position = p
        node.setScale(f)
        node.zRotation = frame.wall.rotation
        return f
    }

    // MARK: build

    override func didMove(to view: SKView) {
        backgroundColor = Palette.space
        buildWalls()
        buildWorld()
        buildStreamers()
        buildActors()
        podT = bottomRailT
        railedIndex = Tuning.railCount / 2
        podRotation = walls[Tuning.railCount / 2].rotation
        junkSpawnCountdown = Tuning.junkSpawnSeconds
        spawnSkimmer()
    }

    private func buildWorld() {
        // stars above the surface line
        let starBottom = Tuning.hexTopY + Tuning.starMargin
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

        // Earthrise over the open roofline, limb behind the surface
        let earth = SKSpriteNode(texture: Sprites.earth)
        earth.size = Tuning.earthSize
        earth.position = CGPoint(x: Tuning.earthX, y: Tuning.earthY)
        addChild(earth)

        // the regolith cross-section the tube is bored through
        let dirt = SKSpriteNode(color: Palette.rockBody,
                                size: CGSize(width: size.width, height: Tuning.hexTopY))
        dirt.position = CGPoint(x: centerX, y: Tuning.hexTopY / 2)
        addChild(dirt)

        // dirt speckle, golden-ratio scattered outside the bore
        var speckled = 0
        var probe = 0
        while speckled < Tuning.speckleCount && probe < Tuning.speckleCount * 10 {
            probe += 1
            let x = CGFloat((Double(probe) * 0.61803).truncatingRemainder(dividingBy: 1))
                * size.width
            let y = CGFloat((Double(probe) * 0.38197).truncatingRemainder(dividingBy: 1))
                * Tuning.hexTopY
            let half = hexHalfWidth(at: y)
            guard half < 0 || abs(x - centerX) > half + Tuning.speckleMargin else { continue }
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

        // the bore interior, nearer than the horizon so it hides the limb
        let v = hexVertices
        let hexPath = CGMutablePath()
        hexPath.addLines(between: v)
        hexPath.closeSubpath()
        let interior = SKShapeNode(path: hexPath)
        interior.fillColor = Palette.trenchAir
        interior.strokeColor = Palette.edgeLight
        interior.lineWidth = Tuning.strokeWidth
        addChild(interior)

        // lit bevels on the five railed walls
        let facetColors: [SKColor] = [Palette.rockSlopeLit, Palette.rockSlopeLit,
                                      Palette.rockFloor,
                                      Palette.rockSlopeShade, Palette.rockSlopeShade]
        for (i, w) in walls.enumerated() {
            let quad = CGMutablePath()
            let na = CGPoint(x: w.a.x + w.normal.dx * Tuning.bevelDepth,
                             y: w.a.y + w.normal.dy * Tuning.bevelDepth)
            let nb = CGPoint(x: w.b.x + w.normal.dx * Tuning.bevelDepth,
                             y: w.b.y + w.normal.dy * Tuning.bevelDepth)
            quad.addLines(between: [w.a, w.b, nb, na])
            quad.closeSubpath()
            let facet = SKShapeNode(path: quad)
            facet.fillColor = facetColors[i]
            facet.strokeColor = .clear
            addChild(facet)
        }

        // the surface: caps beside the open roofline, busy terrain on it
        let capL = SKSpriteNode(color: Palette.surface,
                                size: CGSize(width: v[0].x, height: Tuning.bevelDepth))
        capL.position = CGPoint(x: v[0].x / 2, y: Tuning.hexTopY - Tuning.bevelDepth / 2)
        addChild(capL)
        let capR = SKSpriteNode(color: Palette.surface,
                                size: CGSize(width: size.width - v[5].x,
                                             height: Tuning.bevelDepth))
        capR.position = CGPoint(x: (size.width + v[5].x) / 2,
                                y: Tuning.hexTopY - Tuning.bevelDepth / 2)
        addChild(capR)
        for spot in Tuning.moundSpots {
            let mound = SKShapeNode(ellipseOf: CGSize(width: spot.rx * 2, height: spot.ry * 2))
            mound.position = CGPoint(x: spot.x, y: Tuning.hexTopY)
            mound.fillColor = Palette.surface
            mound.strokeColor = .clear
            addChild(mound)
        }
        for spot in Tuning.craterSpots {
            let lip = SKShapeNode(ellipseOf: CGSize(width: spot.rx * 2, height: spot.ry * 2))
            lip.position = CGPoint(x: spot.x, y: Tuning.hexTopY - Tuning.craterDropY + 1)
            lip.fillColor = Palette.edgeLight
            lip.strokeColor = .clear
            addChild(lip)
            let bowl = SKShapeNode(ellipseOf: CGSize(width: spot.rx * 2, height: spot.ry * 2))
            bowl.position = CGPoint(x: spot.x, y: Tuning.hexTopY - Tuning.craterDropY)
            bowl.fillColor = Palette.rockSlopeShade
            bowl.strokeColor = .clear
            addChild(bowl)
        }

        let horizon = SKSpriteNode(color: Palette.horizonGlow,
                                   size: CGSize(width: size.width,
                                                height: Tuning.horizonGlowHeight))
        horizon.position = CGPoint(x: centerX, y: Tuning.hexTopY)
        addChild(horizon)

        // the kablammo flash washes the whole sky, Earth included
        skyFlash.color = Palette.flash
        skyFlash.size = CGSize(width: size.width, height: size.height - Tuning.hexTopY)
        skyFlash.position = CGPoint(x: centerX, y: (size.height + Tuning.hexTopY) / 2)
        skyFlash.alpha = 0
        addChild(skyFlash)

        // lane rays from the far mouth out to each rail
        for t in railTs {
            let near = wallFrame(at: t).point
            let ray = CGMutablePath()
            ray.move(to: projectPoint(near, 0).point)
            ray.addLine(to: near)
            let node = SKShapeNode(path: ray)
            node.strokeColor = Palette.laneLine
            node.lineWidth = Tuning.strokeWidth
            node.alpha = Tuning.laneLineAlpha
            addChild(node)
        }

        // the hot rails: glow arcs at the five wall centers
        for t in railTs {
            let frame = wallFrame(at: t)
            let half = Tuning.railGlowHalfLength / perimeterLength
            let a = wallFrame(at: t - half).point
            let b = wallFrame(at: t + half).point
            let arc = CGMutablePath()
            arc.move(to: CGPoint(x: a.x + frame.wall.normal.dx * Tuning.strokeWidth,
                                 y: a.y + frame.wall.normal.dy * Tuning.strokeWidth))
            arc.addLine(to: CGPoint(x: b.x + frame.wall.normal.dx * Tuning.strokeWidth,
                                    y: b.y + frame.wall.normal.dy * Tuning.strokeWidth))
            let node = SKShapeNode(path: arc)
            node.strokeColor = Palette.railHot
            node.glowWidth = Tuning.railGlowWidth
            node.lineWidth = Tuning.railGlowWidth
            node.alpha = Tuning.railIdleAlpha
            addChild(node)
            railGlows.append(node)
        }

        // receding open-hex outlines: the bore telescoping away
        for _ in 0..<Tuning.stripeCount {
            let stripe = SKShapeNode()
            stripe.strokeColor = Palette.stripe
            stripe.lineWidth = Tuning.strokeWidth
            addChild(stripe)
            stripes.append(stripe)
        }

        // the far mouth: the exit the quarry is running for
        let mouthPath = CGMutablePath()
        mouthPath.addLines(between: v.map { projectPoint($0, 0).point })
        mouth.path = mouthPath
        mouth.strokeColor = Palette.railHot
        mouth.glowWidth = Tuning.railGlowWidth
        mouth.lineWidth = Tuning.strokeWidth
        mouth.blendMode = .add
        mouth.run(.repeatForever(.sequence([
            .fadeAlpha(to: Tuning.mouthAlphaLo, duration: Tuning.mouthPulseSeconds / 2),
            .fadeAlpha(to: Tuning.mouthAlphaHi, duration: Tuning.mouthPulseSeconds / 2),
        ])))
        addChild(mouth)
    }

    // the parallax layers: craters pouring along the surface band, streaks
    // running down the walls, energy pulses racing the rails
    private func buildStreamers() {
        for i in 0..<Tuning.surfaceStreamerCount {
            let node: SKNode
            if i % 2 == 0 {
                let crater = SKShapeNode(ellipseOf: Tuning.surfaceFeatureSize)
                crater.fillColor = Palette.rockSlopeShade
                crater.strokeColor = Palette.edgeLight
                crater.lineWidth = Tuning.strokeWidth / 2
                node = crater
            } else {
                node = SKSpriteNode(color: Palette.dirtLight,
                                    size: CGSize(width: Tuning.surfaceFeatureSize.height,
                                                 height: Tuning.surfaceFeatureSize.height))
            }
            addStreamer(node, .surface, phase: Double(i) / Double(Tuning.surfaceStreamerCount))
        }
        for i in 0..<Tuning.wallStreakCount {
            let node = SKSpriteNode(color: Palette.edgeLight, size: Tuning.wallStreakSize)
            addStreamer(node, .wall, phase: Double(i) / Double(Tuning.wallStreakCount))
        }
        for i in 0..<Tuning.railPulseCount {
            let node = SKSpriteNode(color: Palette.railHot, size: Tuning.railPulseSize)
            node.blendMode = .add
            addStreamer(node, .pulse, phase: Double(i) / Double(Tuning.railPulseCount))
        }
    }

    private func addStreamer(_ node: SKNode, _ flavor: StreamerFlavor, phase: Double) {
        addChild(node)
        streamers.append(Streamer(node: node, flavor: flavor,
                                  anchor: streamerAnchor(flavor, node), depth: phase))
    }

    private func streamerAnchor(_ flavor: StreamerFlavor, _ node: SKNode) -> CGPoint {
        switch flavor {
        case .surface:
            let pad = Tuning.streamEdgePad
            let leftEdge = hexVertices[0].x
            let rightEdge = hexVertices[5].x
            let x: CGFloat = Bool.random()
                ? .random(in: pad...(leftEdge - pad))
                : .random(in: (rightEdge + pad)...(size.width - pad))
            return CGPoint(x: x, y: Tuning.hexTopY - Tuning.craterDropY)
        case .wall:
            let t = CGFloat.random(in: 0...1)
            let frame = wallFrame(at: t)
            node.zRotation = frame.wall.rotation
            return CGPoint(x: frame.point.x + frame.wall.normal.dx * 6,
                           y: frame.point.y + frame.wall.normal.dy * 6)
        case .pulse:
            let t = railTs.randomElement() ?? bottomRailT
            let frame = wallFrame(at: t)
            return CGPoint(x: frame.point.x + frame.wall.normal.dx * 3,
                           y: frame.point.y + frame.wall.normal.dy * 3)
        }
    }

    private func stepStreamers(_ dt: TimeInterval) {
        for i in streamers.indices {
            let rate: Double
            switch streamers[i].flavor {
            case .surface: rate = Tuning.streamRateSurface
            case .wall: rate = Tuning.streamRateWall
            case .pulse: rate = Tuning.streamRatePulse
            }
            streamers[i].depth += dt * Tuning.trackScrollPerSecond * forwardScale * rate
            if streamers[i].depth >= 1 {
                streamers[i].depth -= 1
                streamers[i].anchor = streamerAnchor(streamers[i].flavor, streamers[i].node)
            }
            let s = streamers[i]
            let (p, f) = projectPoint(s.anchor, s.depth)
            s.node.position = p
            s.node.setScale(f)
            s.node.alpha = Tuning.streamAlphaBase + Tuning.streamAlphaGain * CGFloat(s.depth)
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

        // the sight: your firing line, always on, brighter with a target
        sightBeam.strokeColor = Palette.reticle
        sightBeam.lineWidth = Tuning.strokeWidth
        sightBeam.alpha = Tuning.sightAlphaIdle
        addChild(sightBeam)
        farSight.path = CGPath(ellipseIn: CGRect(x: -Tuning.farSightRadius,
                                                 y: -Tuning.farSightRadius,
                                                 width: Tuning.farSightRadius * 2,
                                                 height: Tuning.farSightRadius * 2),
                               transform: nil)
        farSight.strokeColor = Palette.reticle
        farSight.fillColor = .clear
        farSight.lineWidth = Tuning.strokeWidth
        farSight.alpha = Tuning.sightAlphaIdle
        addChild(farSight)

        pod.texture = Sprites.pod
        pod.size = Tuning.podSize
        addChild(pod)

        engineGlow.color = Palette.podEngine
        engineGlow.size = Tuning.engineGlowSize
        engineGlow.position = CGPoint(x: 0, y: -Tuning.podSize.height / 2)
        engineGlow.blendMode = .add
        engineGlow.isHidden = true
        pod.addChild(engineGlow)
    }

    // MARK: loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, Tuning.maxFrameDt)
        lastTime = currentTime
        guard dt > 0 else { return }
        worldTime += dt
        stepPod(dt)
        stepStripes(dt)
        stepStreamers(dt)
        stepJunk(dt)
        stepSkimmer(dt)
        stepSight()
    }

    private func stepPod(_ dt: TimeInterval) {
        brakeRemaining = max(0, brakeRemaining - dt)
        podAirRemaining = max(0, podAirRemaining - dt)
        notchCooldown = max(0, notchCooldown - dt)

        var dir: CGFloat = 0
        if held.contains(Key.left) { dir -= 1 }
        if held.contains(Key.right) { dir += 1 }

        if stunRemaining > 0 {
            stunRemaining -= dt
            let rate = Tuning.gravityRecenterPerSecond * Tuning.stunGravityMultiplier
            podT += (bottomRailT - podT) * CGFloat(min(1, rate * dt))
        } else if let i = railedIndex {
            podT = railTs[i]
            // a sustained pull pops the notch; taps stay seated
            if dir != 0 {
                stickAccum += dt
                if stickAccum >= Tuning.railStickSeconds {
                    popOff()
                    podT += dir * Tuning.podPerimeterSpeed / perimeterLength * CGFloat(dt)
                }
            } else {
                stickAccum = 0
            }
        } else {
            if dir != 0 {
                idleSeconds = 0
                podT += dir * Tuning.podPerimeterSpeed / perimeterLength * CGFloat(dt)
            } else {
                idleSeconds += dt
                if idleSeconds >= Tuning.gravityGraceSeconds {
                    let pull = CGFloat(min(1, Tuning.gravityRecenterPerSecond * dt))
                    podT += (bottomRailT - podT) * pull
                }
                // settle into the nearest notch: click
                if notchCooldown <= 0,
                   let i = nearestRail(within: Tuning.railSnapDistance) {
                    notchIn(i)
                }
            }
            podT = podT.clamped(0, 1)
        }

        // render: bank into the walls, rumble on the rail, hop off it
        let frame = wallFrame(at: podT)
        let target = frame.wall.rotation
        podRotation += (target - podRotation)
            * CGFloat(min(1, Tuning.podRotationPerSecond * dt))
        var lift = Tuning.podSize.height / 2
        if podAirRemaining > 0 {
            let t = 1 - podAirRemaining / Tuning.podHopSeconds
            lift += Tuning.podHopHeight * CGFloat(sin(Double.pi * t))
        }
        var pos = CGPoint(x: frame.point.x + frame.wall.normal.dx * lift,
                          y: frame.point.y + frame.wall.normal.dy * lift)
        if isRailed {
            let shake = CGFloat(sin(worldTime * 2 * .pi * Tuning.railShakeHz))
                * Tuning.railShakeAmplitude
            pos.x += frame.wall.dir.dx * shake
            pos.y += frame.wall.dir.dy * shake
            engineGlow.alpha = Tuning.engineFlickerBase + Tuning.engineFlickerAmp
                * CGFloat(sin(worldTime * 2 * .pi * Tuning.engineFlickerHz))
        }
        pod.position = pos
        pod.zRotation = podRotation
        engineGlow.isHidden = !isRailed
        for (i, glow) in railGlows.enumerated() {
            glow.alpha = i == railedIndex ? 1 : Tuning.railIdleAlpha
        }
    }

    private func nearestRail(within distance: CGFloat) -> Int? {
        let i = railTs.indices.min { laneDistance(podT, railTs[$0]) < laneDistance(podT, railTs[$1]) }
        guard let i, laneDistance(podT, railTs[i]) <= distance else { return nil }
        return i
    }

    private func notchIn(_ i: Int) {
        railedIndex = i
        stickAccum = 0
        podT = railTs[i]
        jolt()
        spark(at: wallFrame(at: podT).point, radius: Tuning.sparkRadius)
    }

    private func popOff() {
        railedIndex = nil
        stickAccum = 0
        notchCooldown = Tuning.notchCooldownSeconds
        jolt()
    }

    private func clunkOff() {
        railedIndex = nil
        stickAccum = 0
        notchCooldown = Tuning.notchCooldownSeconds
        jolt()
        spark(at: pod.position, radius: Tuning.sparkRadius)
    }

    // the spike: slam into the nearest rail, pay for it in speed
    private func slamLock() {
        guard let i = railTs.indices.min(by: {
            laneDistance(podT, railTs[$0]) < laneDistance(podT, railTs[$1])
        }) else { return }
        railedIndex = i
        stickAccum = 0
        podT = railTs[i]
        brakeRemaining = Tuning.brakeSeconds
        jolt()
        spark(at: wallFrame(at: podT).point, radius: Tuning.sparkRadius)
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
        s.fillColor = .clear
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
        let v = hexVertices
        for (i, stripe) in stripes.enumerated() {
            let d = (stripePhase + Double(i) / Double(Tuning.stripeCount))
                .truncatingRemainder(dividingBy: 1)
            let path = CGMutablePath()
            path.addLines(between: v.map { projectPoint($0, d).point })
            stripe.path = path
            stripe.alpha = Tuning.stripeAlphaBase + Tuning.stripeAlphaGain * CGFloat(d)
        }
    }

    // MARK: junk

    private func stepJunk(_ dt: TimeInterval) {
        junkSpawnCountdown -= dt
        if junkSpawnCountdown <= 0 {
            spawnJunk()
            junkSpawnCountdown = Tuning.junkSpawnSeconds
        }
        // wreckage is stationary in the tube; it closes at your forward speed
        let closeRate = Tuning.trackScrollPerSecond * forwardScale
        for i in junkPieces.indices {
            junkPieces[i].progress += dt * closeRate
            let piece = junkPieces[i]
            if piece.progress >= 1 {
                resolveJunkArrival(piece)
            } else {
                placeOnWall(piece.node, t: railTs[piece.rail], depth: piece.progress,
                            height: piece.size.height)
                piece.node.zRotation += piece.tilt
            }
        }
        junkPieces.removeAll { $0.progress >= 1 }
    }

    private func spawnJunk() {
        let rail = Int.random(in: 0..<Tuning.railCount)
        let art = Sprites.junkArts.randomElement() ?? Sprites.junkArts[0]
        let spread = CGFloat.random(in: Tuning.junkScaleMin...Tuning.junkScaleMax)
        let junkSize = CGSize(width: art.size.width * spread,
                              height: art.size.height * spread)
        let node = SKSpriteNode(texture: art.texture)
        node.size = junkSize
        addChild(node)
        let tilt = CGFloat.random(in: -Tuning.junkTiltRange...Tuning.junkTiltRange)
        junkPieces.append(Junk(node: node, rail: rail, size: junkSize,
                               tilt: tilt, progress: 0))
        placeOnWall(node, t: railTs[rail], depth: 0, height: junkSize.height)
        node.zRotation += tilt
    }

    private func resolveJunkArrival(_ piece: Junk) {
        let reach = (piece.size.width + Tuning.podSize.width) / 2
        // an airborne pod sails over arriving wreckage
        if laneDistance(railTs[piece.rail], podT) < reach, podAirRemaining <= 0 {
            stunPod()
        }
        piece.node.run(.sequence([.fadeOut(withDuration: Tuning.junkFadeSeconds),
                                  .removeFromParent()]))
    }

    private func stunPod() {
        stunRemaining = Tuning.stunSeconds
        railedIndex = nil
        notchCooldown = Tuning.notchCooldownSeconds
        let flickers = Int(Tuning.stunSeconds / (2 * Tuning.stunFlickerSeconds))
        pod.run(.repeat(.sequence([
            .fadeAlpha(to: Tuning.stunFlickerAlpha, duration: Tuning.stunFlickerSeconds),
            .fadeAlpha(to: 1, duration: Tuning.stunFlickerSeconds),
        ]), count: flickers))
    }

    // MARK: the quarry

    private func stepSkimmer(_ dt: TimeInterval) {
        guard skimmerAlive else {
            respawnCountdown -= dt
            if respawnCountdown <= 0 { spawnSkimmer() }
            return
        }
        // it runs for the far mouth: the clock is the chase
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
            skimmerT = hopFromT + (railTs[target] - hopFromT) * CGFloat(t)
            if t >= 1 {
                skimmerLane = target
                hopTarget = nil
                hopCountdown = nextHopDelay()
            }
        } else {
            skimmerT = railTs[skimmerLane]
            hopCountdown -= dt
            if hopCountdown <= 0 { startHop() }
        }
        let progress = skimmerElapsed / Tuning.passClockSeconds
        let depth = Tuning.skimmerSpawnDepth * (1 - progress)
        let f = placeOnWall(skimmer, t: skimmerT, depth: depth,
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
        let options = [skimmerLane - 1, skimmerLane + 1].filter { railTs.indices.contains($0) }
        guard let target = options.randomElement() else { return }
        hopTarget = target
        hopFromT = skimmerT
        hopT = 0
    }

    private func spawnSkimmer() {
        skimmerLane = Int.random(in: 0..<Tuning.railCount)
        skimmerT = railTs[skimmerLane]
        hopTarget = nil
        hopCountdown = nextHopDelay()
        skimmerElapsed = 0
        skimmerHasBraked = false
        skimmerAlive = true
        let f = placeOnWall(skimmer, t: skimmerT, depth: Tuning.skimmerSpawnDepth,
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
        spark(at: skimmer.position, radius: Tuning.laneHitWidth / 2)
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

    // kablammo: the quarry made the mouth
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

    private var sightAnchor: CGPoint {
        let frame = wallFrame(at: podT)
        return CGPoint(x: frame.point.x + frame.wall.normal.dx * Tuning.podSize.height / 2,
                       y: frame.point.y + frame.wall.normal.dy * Tuning.podSize.height / 2)
    }

    private var skimmerInLine: Bool {
        skimmerAlive && laneDistance(skimmerT, podT) <= Tuning.laneHitWidth
    }

    private func stepSight() {
        let near = sightAnchor
        let far = projectPoint(near, 0).point
        let path = CGMutablePath()
        path.move(to: near)
        path.addLine(to: far)
        sightBeam.path = path
        farSight.position = far
        let junkInLine = junkPieces.contains {
            laneDistance(railTs[$0.rail], podT) <= Tuning.laneHitWidth
        }
        let hot = skimmerInLine || junkInLine
        sightBeam.alpha = hot ? Tuning.sightAlphaLock : Tuning.sightAlphaIdle
        farSight.alpha = sightBeam.alpha
        let lockColor = skimmerInLine ? Palette.enemyMarker : Palette.reticle
        sightBeam.strokeColor = lockColor
        farSight.strokeColor = lockColor
    }

    // the shot goes straight down the tube to the end, and owns its line
    private func fire() {
        guard stunRemaining <= 0 else { return }
        let tracer = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: sightAnchor)
        p.addLine(to: projectPoint(sightAnchor, 0).point)
        tracer.path = p
        tracer.strokeColor = Palette.tracer
        tracer.glowWidth = Tuning.tracerGlowWidth
        tracer.lineWidth = Tuning.strokeWidth
        addChild(tracer)
        tracer.run(.sequence([.fadeOut(withDuration: Tuning.tracerFadeSeconds),
                              .removeFromParent()]))

        for piece in junkPieces
        where laneDistance(railTs[piece.rail], podT) <= Tuning.laneHitWidth {
            spark(at: piece.node.position, radius: Tuning.sparkRadius)
            piece.node.removeFromParent()
        }
        junkPieces.removeAll { laneDistance(railTs[$0.rail], podT) <= Tuning.laneHitWidth }
        if skimmerInLine { killSkimmer() }
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
                // double-down: seated = clunk off; coasting = spike into the
                // nearest rail, at the cost of a hard brake
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
