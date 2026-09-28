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
        let ping: SKShapeNode
        let rail: Int
        let size: CGSize
        let tilt: CGFloat
        var progress: Double
    }

    private struct TurboPad {
        let node: SKShapeNode
        let rail: Int
        let isLast: Bool
        var depth: Double
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

    private struct BigJump {
        let fromAnchor: CGPoint
        let toAnchor: CGPoint
        let fromRot: CGFloat
        let toRot: CGFloat
        let landT: CGFloat
        let landRail: Int?
        let vertical: Bool
        var remaining: TimeInterval
    }

    private struct Station {
        let node: SKNode
        let t: CGFloat
        var depth: Double
    }

    private struct Bolt {
        let node: SKShapeNode
        let t: CGFloat
        var depth: Double
    }

    private enum PickupKind {
        case gun, shield, points, multiplier
    }

    private struct Pickup {
        let node: SKSpriteNode
        let kind: PickupKind
        let rail: Int
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
    private var railGlows: [SKShapeNode] = []
    private var railStrips: [SKShapeNode] = []
    private var stripes: [SKShapeNode] = []
    private var streamers: [Streamer] = []
    private var lightRings: [SKShapeNode] = []
    private var lightRingPhase = 0.0
    private var stations: [Station] = []
    private var stationCountdown: TimeInterval = 0
    private let launchLabel = SKLabelNode()
    private var hullPips: [SKSpriteNode] = []
    private var gunPips: [SKSpriteNode] = []
    private let p1ScoreLabel = SKLabelNode()
    private let p2ScoreLabel = SKLabelNode()
    private var bolts: [Bolt] = []
    private var pickups: [Pickup] = []
    private var pickupCountdown: TimeInterval = 0
    private var shootCountdown: TimeInterval = 0
    private var gunLevel = 1
    private var skimmerHp = Tuning.skimmerHitsToKill
    private var skimmerHpPips: [SKSpriteNode] = []
    private var score = 0
    private var scoreMultiplier = 1
    private var devastatorBanked = false
    private let devastatorLamp = SKShapeNode()
    private var turboPads: [TurboPad] = []
    private var turboChainBroken = false
    private var turboCountdown: TimeInterval = 0
    private var turboRemaining: TimeInterval = 0

    private var walls: [Wall] = []
    private var perimeterLength: CGFloat = 0
    private var railTs: [CGFloat] = []

    private var podT: CGFloat = 0.5
    private var podRotation: CGFloat = 0
    private var railedIndex: Int?
    private var stickAccum: TimeInterval = 0
    private var notchCooldown: TimeInterval = 0
    private var lastUpTap: TimeInterval = 0
    private var podAirRemaining: TimeInterval = 0
    private var bigJump: BigJump?
    private var hull = Tuning.hullMax
    private var invulnRemaining: TimeInterval = 0
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
    // turbo outruns everything, and even rewinds the chase
    private var forwardScale: Double {
        turboRemaining > 0 ? Tuning.turboScrollScale : isRailed ? Tuning.railScrollScale : 1
    }
    private var escapeScale: Double {
        turboRemaining > 0 ? Tuning.turboEscapeScale : isRailed ? Tuning.railClockScale : 1
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

    private func scaled(_ p: CGPoint, _ f: CGFloat) -> CGPoint {
        CGPoint(x: tubeCenter.x + (p.x - tubeCenter.x) * f,
                y: tubeCenter.y + (p.y - tubeCenter.y) * f)
    }

    // flat-shaded panel color: the base sinks into depth fog with distance,
    // biased by which side the earthlight falls on
    private func shaded(_ base: SKColor, f: CGFloat, bias: CGFloat) -> SKColor {
        let c = base.usingColorSpace(.deviceRGB) ?? base
        let fog = Palette.depthFog.usingColorSpace(.deviceRGB) ?? Palette.depthFog
        let t = (1 - f) * Tuning.fogStrength
        func channel(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
            let lit = a * bias
            return max(0, min(1, lit + (b - lit) * t))
        }
        return SKColor(red: channel(c.redComponent, fog.redComponent),
                       green: channel(c.greenComponent, fog.greenComponent),
                       blue: channel(c.blueComponent, fog.blueComponent),
                       alpha: 1)
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
        stationCountdown = Tuning.stationFirstSeconds
        pickupCountdown = Tuning.pickupFirstSeconds
        turboCountdown = Tuning.turboChainIntervalSeconds / 2
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

        // Earthrise over the open roofline, limb behind the surface, wrapped
        // in an atmosphere halo
        let halo = SKShapeNode(circleOfRadius: Tuning.earthHaloRadius)
        halo.position = CGPoint(x: Tuning.earthX, y: Tuning.earthY)
        halo.strokeColor = Palette.earthAtmos
        halo.glowWidth = Tuning.earthHaloWidth
        halo.lineWidth = Tuning.strokeWidth
        halo.blendMode = .add
        halo.alpha = Tuning.earthHaloAlpha
        addChild(halo)
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
        // boulders in the regolith
        for spot in Tuning.boulderSpots {
            let boulder = SKShapeNode(ellipseOf: CGSize(width: spot.rx * 2,
                                                        height: spot.ry * 2))
            boulder.position = CGPoint(x: spot.x, y: spot.y)
            boulder.fillColor = Palette.rockSlopeShade
            boulder.strokeColor = Palette.edgeLight
            boulder.lineWidth = Tuning.strokeWidth / 2
            addChild(boulder)
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
        interior.fillColor = Palette.depthFog
        interior.strokeColor = Palette.edgeLight
        interior.lineWidth = Tuning.strokeWidth
        addChild(interior)

        // the filled tube: flat-shaded panel bands from the near rim down
        // into the fog at the mouth
        let panelColors: [SKColor] = [Palette.upperPanel, Palette.lowerPanel,
                                      Palette.floorPanel,
                                      Palette.lowerPanel, Palette.upperPanel]
        let panelBias: [CGFloat] = [Tuning.lightBiasLeft, Tuning.lightBiasLeft, 1,
                                    Tuning.lightBiasRight, Tuning.lightBiasRight]
        let bands = Tuning.tubeBandCount
        let bandFs: [CGFloat] = (0...bands).map {
            Tuning.farPointScale + (1 - Tuning.farPointScale) * CGFloat($0) / CGFloat(bands)
        }
        for k in 0..<bands {
            let f0 = bandFs[k]
            let f1 = bandFs[k + 1]
            for (i, w) in walls.enumerated() {
                let quad = CGMutablePath()
                quad.addLines(between: [scaled(w.a, f1), scaled(w.b, f1),
                                        scaled(w.b, f0), scaled(w.a, f0)])
                quad.closeSubpath()
                let panel = SKShapeNode(path: quad)
                panel.fillColor = shaded(panelColors[i], f: (f0 + f1) / 2,
                                         bias: panelBias[i])
                panel.strokeColor = .clear
                addChild(panel)
            }
        }

        // grunge on the panels: scuffs and stains down the bore
        for i in 0..<Tuning.grungeCount {
            let t = CGFloat((Double(i) * 0.61803).truncatingRemainder(dividingBy: 1))
            let d = 0.15 + 0.75 * (Double(i) * 0.38197).truncatingRemainder(dividingBy: 1)
            let frame = wallFrame(at: t)
            let mark = SKSpriteNode(color: i % 2 == 0 ? Palette.dirtDark
                                                      : Palette.dirtLight,
                                    size: CGSize(width: Tuning.speckleSizes[i % 4] + 2,
                                                 height: Tuning.speckleSizes[i % 4]))
            let anchor = CGPoint(x: frame.point.x + frame.wall.normal.dx * 2,
                                 y: frame.point.y + frame.wall.normal.dy * 2)
            let (p, f) = projectPoint(anchor, d)
            mark.position = p
            mark.setScale(f)
            mark.zRotation = frame.wall.rotation
            mark.alpha = Tuning.grungeAlpha
            addChild(mark)
        }

        // light strips running each rail from the near arc into the mouth
        for t in railTs {
            let half = Tuning.railStripHalfWidth / perimeterLength
            let a = wallFrame(at: t - half).point
            let b = wallFrame(at: t + half).point
            let strip = CGMutablePath()
            strip.addLines(between: [a, b,
                                     scaled(b, Tuning.farPointScale),
                                     scaled(a, Tuning.farPointScale)])
            strip.closeSubpath()
            let node = SKShapeNode(path: strip)
            node.fillColor = Palette.railHot
            node.strokeColor = .clear
            node.blendMode = .add
            node.alpha = Tuning.railStripAlphaIdle
            addChild(node)
            railStrips.append(node)
        }

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

        // seam lines between tube segments, sweeping past
        for _ in 0..<Tuning.stripeCount {
            let stripe = SKShapeNode()
            stripe.strokeColor = Palette.stripe
            stripe.lineWidth = Tuning.strokeWidth
            addChild(stripe)
            stripes.append(stripe)
        }

        // bright tunnel light rings, sweeping past as fixtures
        for _ in 0..<Tuning.lightRingCount {
            let ring = SKShapeNode()
            ring.strokeColor = Palette.railHot
            ring.lineWidth = Tuning.lightRingWidth
            ring.glowWidth = Tuning.railGlowWidth
            ring.blendMode = .add
            addChild(ring)
            lightRings.append(ring)
        }

        // the glass canopy: a glazed sheet running the roof slot down the
        // tube, and the near band the HUD projects on
        let sheet = CGMutablePath()
        sheet.addLines(between: [v[5], v[0],
                                 scaled(v[0], Tuning.farPointScale),
                                 scaled(v[5], Tuning.farPointScale)])
        sheet.closeSubpath()
        let glassSheet = SKShapeNode(path: sheet)
        glassSheet.fillColor = Palette.ufoGlass.withAlphaComponent(Tuning.glassSheetAlpha)
        glassSheet.strokeColor = .clear
        addChild(glassSheet)

        let band = SKSpriteNode(color: Palette.ufoGlass,
                                size: CGSize(width: v[5].x - v[0].x,
                                             height: Tuning.glassBandHeight))
        band.alpha = Tuning.glassAlpha
        band.position = CGPoint(x: centerX, y: Tuning.hexTopY - Tuning.glassBandHeight / 2)
        addChild(band)
        for i in 0..<2 {
            let glint = SKShapeNode()
            let gp = CGMutablePath()
            let gx = v[0].x + (v[5].x - v[0].x) * (i == 0 ? 0.2 : 0.7)
            gp.move(to: CGPoint(x: gx, y: Tuning.hexTopY - Tuning.glassBandHeight))
            gp.addLine(to: CGPoint(x: gx + Tuning.glassBandHeight, y: Tuning.hexTopY))
            glint.path = gp
            glint.strokeColor = Palette.ufoGlint
            glint.lineWidth = Tuning.strokeWidth
            glint.alpha = Tuning.glintAlpha
            addChild(glint)
        }

        // the HUD, projected on the glass: launch clock and hull pips
        launchLabel.fontName = "Menlo-Bold"
        launchLabel.fontSize = Tuning.hudFontSize
        launchLabel.fontColor = Palette.railHot
        launchLabel.verticalAlignmentMode = .center
        launchLabel.position = CGPoint(x: centerX,
                                       y: Tuning.hexTopY - Tuning.glassBandHeight / 2)
        launchLabel.zPosition = 3
        addChild(launchLabel)
        for i in 0..<Tuning.hullMax {
            let pip = SKSpriteNode(color: Palette.podEngine, size: Tuning.hudPipSize)
            pip.position = CGPoint(
                x: v[0].x + Tuning.hudPipGap + Tuning.hudPipSize.width / 2
                    + CGFloat(i) * (Tuning.hudPipSize.width + Tuning.hudPipGap),
                y: Tuning.hexTopY - Tuning.glassBandHeight / 2)
            pip.zPosition = 3
            addChild(pip)
            hullPips.append(pip)
        }
        // the DEVASTATOR lamp: a diamond beside the launch clock
        let lampPath = CGMutablePath()
        let lr = Tuning.hudPipSize.width * 0.9
        lampPath.addLines(between: [CGPoint(x: 0, y: lr), CGPoint(x: lr, y: 0),
                                    CGPoint(x: 0, y: -lr), CGPoint(x: -lr, y: 0)])
        lampPath.closeSubpath()
        devastatorLamp.path = lampPath
        devastatorLamp.fillColor = Palette.hazard
        devastatorLamp.strokeColor = Palette.ufoGlint
        devastatorLamp.lineWidth = Tuning.strokeWidth / 2
        devastatorLamp.glowWidth = Tuning.tracerGlowWidth
        devastatorLamp.position = CGPoint(x: centerX - 70,
                                          y: Tuning.hexTopY - Tuning.glassBandHeight / 2)
        devastatorLamp.zPosition = 3
        devastatorLamp.alpha = 0.15
        addChild(devastatorLamp)

        for i in 0..<Tuning.gunLevelMax {
            let pip = SKSpriteNode(color: Palette.hazard, size: Tuning.hudPipSize)
            pip.position = CGPoint(
                x: v[5].x - Tuning.hudPipGap - Tuning.hudPipSize.width / 2
                    - CGFloat(i) * (Tuning.hudPipSize.width + Tuning.hudPipGap),
                y: Tuning.hexTopY - Tuning.glassBandHeight / 2)
            pip.zPosition = 3
            addChild(pip)
            gunPips.append(pip)
        }

        // glass slashes down the glazed roof, angled across the sheet
        for d in Tuning.glassSlashDepths {
            let slash = SKShapeNode()
            let sp = CGMutablePath()
            sp.move(to: projectPoint(v[0], d).point)
            sp.addLine(to: projectPoint(v[5], d + Tuning.glassSlashSpan).point)
            slash.path = sp
            slash.strokeColor = Palette.ufoGlint
            slash.lineWidth = Tuning.strokeWidth
            slash.alpha = Tuning.glassSlashAlpha
            addChild(slash)
        }

        // the far mouth: the exit the quarry is running for
        let mouthPath = CGMutablePath()
        mouthPath.addLines(between: v.map { projectPoint($0, 0).point })
        mouth.path = mouthPath
        mouth.strokeColor = Palette.railHot
        mouth.fillColor = Palette.mouthLight.withAlphaComponent(Tuning.mouthFillAlpha)
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

        // the P1 and P2 score readouts, bottom corners of the dashboard
        p1ScoreLabel.fontName = "Menlo-Bold"
        p1ScoreLabel.fontSize = Tuning.scoreFontSize
        p1ScoreLabel.fontColor = Palette.podEngine
        p1ScoreLabel.horizontalAlignmentMode = .left
        p1ScoreLabel.position = CGPoint(x: Tuning.scoreInset, y: Tuning.scoreInset)
        p1ScoreLabel.zPosition = 3
        addChild(p1ScoreLabel)
        p2ScoreLabel.fontName = "Menlo-Bold"
        p2ScoreLabel.fontSize = Tuning.scoreFontSize
        p2ScoreLabel.fontColor = Palette.podHullDark
        p2ScoreLabel.horizontalAlignmentMode = .right
        p2ScoreLabel.position = CGPoint(x: size.width - Tuning.scoreInset,
                                        y: Tuning.scoreInset)
        p2ScoreLabel.zPosition = 3
        p2ScoreLabel.text = "P2 ------"
        addChild(p2ScoreLabel)

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
        // the big jump plays at full speed while the world goes slo-mo
        let worldDt = bigJump == nil ? dt : dt * Tuning.bigJumpSloMo
        stepPod(dt)
        stepStripes(worldDt)
        stepStreamers(worldDt)
        stepRings(worldDt)
        stepStations(worldDt)
        stepJunk(worldDt)
        stepSkimmer(worldDt)
        stepBolts(worldDt)
        stepPickups(worldDt)
        stepTurbo(worldDt, realDt: dt)
        stepSight()
        stepHud()
    }

    // turbo gates arrive in a lane-switch chain; ride every one and sprint
    private func stepTurbo(_ dt: TimeInterval, realDt: TimeInterval) {
        turboRemaining = max(0, turboRemaining - realDt)
        turboCountdown -= dt
        if turboCountdown <= 0 {
            spawnTurboChain()
            turboCountdown = Tuning.turboChainIntervalSeconds
        }
        for i in turboPads.indices {
            turboPads[i].depth += dt * Tuning.trackScrollPerSecond * forwardScale
            let pad = turboPads[i]
            pad.node.isHidden = pad.depth < 0
            if pad.depth >= 1 {
                let onPad = laneDistance(railTs[pad.rail], podT)
                    <= Tuning.laneHitWidth && podAirRemaining <= 0 && bigJump == nil
                if onPad {
                    spark(at: wallFrame(at: railTs[pad.rail]).point,
                          radius: Tuning.sparkRadius)
                    if pad.isLast, !turboChainBroken {
                        turboRemaining = Tuning.turboSeconds
                        scorePopup("TURBO", at: pod.position, color: Palette.railHot)
                    }
                } else {
                    turboChainBroken = true
                }
                pad.node.removeFromParent()
            } else if pad.depth > 0 {
                placeOnWall(pad.node, t: railTs[pad.rail], depth: pad.depth,
                            height: Tuning.turboPadSize.height / 2)
            }
        }
        turboPads.removeAll { $0.depth >= 1 }
    }

    private func spawnTurboChain() {
        turboChainBroken = false
        var lane = Int.random(in: 0..<Tuning.railCount)
        for i in 0..<Tuning.turboChainLength {
            let node = SKShapeNode(rectOf: Tuning.turboPadSize,
                                   cornerRadius: Tuning.turboPadSize.height / 2)
            node.fillColor = Palette.railHot
            node.strokeColor = Palette.ufoGlint
            node.lineWidth = Tuning.strokeWidth / 2
            node.glowWidth = Tuning.railGlowWidth
            node.blendMode = .add
            node.zPosition = 0.7
            node.isHidden = true
            addChild(node)
            turboPads.append(TurboPad(node: node, rail: lane,
                                      isLast: i == Tuning.turboChainLength - 1,
                                      depth: -Double(i) * Tuning.turboPadDepthGap))
            // the chain switches lanes each gate
            let step = Bool.random() ? 1 : -1
            lane = min(Tuning.railCount - 1, max(0, lane + step))
        }
    }

    private func stepRings(_ dt: TimeInterval) {
        lightRingPhase = (lightRingPhase + dt * Tuning.trackScrollPerSecond * forwardScale)
            .truncatingRemainder(dividingBy: 1)
        let v = hexVertices
        for (i, ring) in lightRings.enumerated() {
            let d = (lightRingPhase + Double(i) / Double(Tuning.lightRingCount))
                .truncatingRemainder(dividingBy: 1)
            let path = CGMutablePath()
            path.addLines(between: v.map { projectPoint($0, d).point })
            ring.path = path
            ring.alpha = Tuning.lightRingAlphaBase
                + Tuning.lightRingAlphaGain * CGFloat(d)
        }
    }

    private func stepStations(_ dt: TimeInterval) {
        stationCountdown -= dt
        if stationCountdown <= 0 {
            spawnStation()
            stationCountdown = Tuning.stationIntervalSeconds
        }
        for i in stations.indices {
            stations[i].depth += dt * Tuning.trackScrollPerSecond * forwardScale
            let s = stations[i]
            if s.depth < 1 {
                placeOnWall(s.node, t: s.t, depth: s.depth, height: 0)
            } else {
                s.node.run(.sequence([.fadeOut(withDuration: Tuning.junkFadeSeconds),
                                      .removeFromParent()]))
            }
        }
        stations.removeAll { $0.depth >= 1 }
    }

    // a transit stop sliding past: platform slab, window band, lit sign
    private func spawnStation() {
        let node = SKNode()
        node.zPosition = 0.5
        let slab = SKSpriteNode(color: Palette.surface, size: Tuning.stationSlabSize)
        slab.position = CGPoint(x: 0, y: Tuning.stationSlabSize.height / 2)
        node.addChild(slab)
        let windows = SKSpriteNode(color: Palette.ufoGlass, size: Tuning.stationWindowSize)
        windows.position = CGPoint(x: 0, y: Tuning.stationSlabSize.height
                                   + Tuning.stationWindowSize.height / 2)
        node.addChild(windows)
        let sign = SKSpriteNode(color: Palette.railHot, size: Tuning.stationSignSize)
        sign.blendMode = .add
        sign.position = CGPoint(x: Tuning.stationSlabSize.width / 2,
                                y: Tuning.stationSlabSize.height * 2)
        node.addChild(sign)
        addChild(node)
        let wall = Int.random(in: 0..<Tuning.railCount)
        let shift = (Tuning.stationSlabSize.width / 2 + Tuning.railGlowHalfLength)
            / perimeterLength
        let t = railTs[wall] + (Bool.random() ? shift : -shift)
        placeOnWall(node, t: t, depth: 0, height: 0)
        stations.append(Station(node: node, t: t, depth: 0))
    }

    private func stepHud() {
        if skimmerAlive {
            let remaining = max(0, Tuning.passClockSeconds - skimmerElapsed)
            launchLabel.text = String(format: "LAUNCH T-%04.1f", remaining)
            launchLabel.fontColor = remaining < Tuning.hudUrgentSeconds
                ? Palette.enemyMarker : Palette.railHot
            launchLabel.alpha = 1
        } else {
            launchLabel.text = "TUBE CLEAR"
            launchLabel.fontColor = Palette.railHot
            launchLabel.alpha = 0.5
        }
        for (i, pip) in hullPips.enumerated() {
            pip.alpha = i < hull ? 1 : 0.15
        }
        for (i, pip) in gunPips.enumerated() {
            pip.alpha = i < gunLevel ? 1 : 0.15
        }
        devastatorLamp.alpha = devastatorBanked ? 1 : 0.15
        p1ScoreLabel.text = scoreMultiplier > 1
            ? String(format: "P1 %06d x%d", score, scoreMultiplier)
            : String(format: "P1 %06d", score)
    }

    private func stepPod(_ dt: TimeInterval) {
        podAirRemaining = max(0, podAirRemaining - dt)
        notchCooldown = max(0, notchCooldown - dt)
        invulnRemaining = max(0, invulnRemaining - dt)

        // the big jump: a committed leap across the bore, world in slo-mo
        if var jump = bigJump {
            jump.remaining -= dt
            if jump.remaining <= 0 {
                bigJump = nil
                podT = jump.landT
                railedIndex = jump.landRail
                podRotation = jump.toRot
                jolt()
                spark(at: wallFrame(at: podT).point, radius: Tuning.sparkRadius)
            } else {
                bigJump = jump
                let u = CGFloat(1 - jump.remaining / Tuning.bigJumpSeconds)
                if jump.vertical {
                    let frame = wallFrame(at: jump.landT)
                    let lift = Tuning.podSize.height / 2
                        + Tuning.bigJumpHeight * CGFloat(sin(Double.pi * Double(u)))
                    pod.position = CGPoint(x: frame.point.x + frame.wall.normal.dx * lift,
                                           y: frame.point.y + frame.wall.normal.dy * lift)
                } else {
                    pod.position = CGPoint(
                        x: jump.fromAnchor.x + (jump.toAnchor.x - jump.fromAnchor.x) * u,
                        y: jump.fromAnchor.y + (jump.toAnchor.y - jump.fromAnchor.y) * u)
                    podRotation = jump.fromRot + (jump.toRot - jump.fromRot) * u
                }
                pod.zRotation = podRotation
                engineGlow.isHidden = false
                engineGlow.alpha = 1
                return
            }
        }

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
            railStrips[i].alpha = i == railedIndex ? Tuning.railStripAlphaHot
                                                  : Tuning.railStripAlphaIdle
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

    private func podHop() {
        guard podAirRemaining <= 0, bigJump == nil else { return }
        podAirRemaining = Tuning.podHopSeconds
    }

    // to the opposite wall's rail; off the floor, straight up and back
    private func startBigJump() {
        guard bigJump == nil else { return }
        let from = railedIndex
            ?? railTs.indices.min { laneDistance(podT, railTs[$0]) < laneDistance(podT, railTs[$1]) }
            ?? Tuning.railCount / 2
        podAirRemaining = 0
        let fromFrame = wallFrame(at: podT)
        let fromAnchor = CGPoint(
            x: fromFrame.point.x + fromFrame.wall.normal.dx * Tuning.podSize.height / 2,
            y: fromFrame.point.y + fromFrame.wall.normal.dy * Tuning.podSize.height / 2)
        if from == Tuning.railCount / 2 {
            bigJump = BigJump(fromAnchor: fromAnchor, toAnchor: fromAnchor,
                              fromRot: podRotation, toRot: wallFrame(at: podT).wall.rotation,
                              landT: podT, landRail: railedIndex,
                              vertical: true, remaining: Tuning.bigJumpSeconds)
        } else {
            let target = (from + 3) % 6
            let landT = railTs[target]
            let toFrame = wallFrame(at: landT)
            let toAnchor = CGPoint(
                x: toFrame.point.x + toFrame.wall.normal.dx * Tuning.podSize.height / 2,
                y: toFrame.point.y + toFrame.wall.normal.dy * Tuning.podSize.height / 2)
            bigJump = BigJump(fromAnchor: fromAnchor, toAnchor: toAnchor,
                              fromRot: podRotation, toRot: toFrame.wall.rotation,
                              landT: landT, landRail: target,
                              vertical: false, remaining: Tuning.bigJumpSeconds)
        }
        railedIndex = nil
        stickAccum = 0
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
                if piece.progress > Tuning.junkPingDepth, piece.ping.parent != nil {
                    piece.ping.removeFromParent()
                }
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
        // radar ping: a green pulse at the near end of the junk's lane
        let frame = wallFrame(at: railTs[rail])
        let ping = SKShapeNode(circleOfRadius: Tuning.junkPingRadius)
        ping.position = CGPoint(x: frame.point.x + frame.wall.normal.dx * Tuning.junkPingRadius,
                                y: frame.point.y + frame.wall.normal.dy * Tuning.junkPingRadius)
        ping.strokeColor = Palette.shieldGreen
        ping.fillColor = .clear
        ping.lineWidth = Tuning.strokeWidth
        ping.glowWidth = Tuning.tracerGlowWidth
        ping.zPosition = 1.4
        ping.run(.repeatForever(.sequence([
            .group([.scale(to: 1.4, duration: 0.35), .fadeAlpha(to: 0.2, duration: 0.35)]),
            .group([.scale(to: 0.7, duration: 0.35), .fadeAlpha(to: 1, duration: 0.35)]),
        ])))
        addChild(ping)
        junkPieces.append(Junk(node: node, ping: ping, rail: rail, size: junkSize,
                               tilt: tilt, progress: 0))
        placeOnWall(node, t: railTs[rail], depth: 0, height: junkSize.height)
        node.zRotation += tilt
    }

    private func resolveJunkArrival(_ piece: Junk) {
        let reach = (piece.size.width + Tuning.podSize.width) / 2
        if bigJump == nil, invulnRemaining <= 0,
           laneDistance(railTs[piece.rail], podT) < reach {
            // clearance is the jump arc against the wreck: bigger junk needs
            // the top of the arc
            var cleared = false
            if podAirRemaining > 0 {
                let t = 1 - podAirRemaining / Tuning.podHopSeconds
                let lift = Tuning.podHopHeight * CGFloat(sin(Double.pi * t))
                cleared = lift > piece.size.height * Tuning.junkClearanceFactor
            }
            if !cleared { damagePod() }
        }
        piece.ping.removeFromParent()
        piece.node.run(.sequence([.fadeOut(withDuration: Tuning.junkFadeSeconds),
                                  .removeFromParent()]))
    }

    private func damagePod() {
        hull -= 1
        scoreMultiplier = 1
        stunPod()
        if hull <= 0 {
            hull = Tuning.hullMax
            gunLevel = 1
            invulnRemaining = Tuning.invulnSeconds
        }
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
        // return fire: a rail-gun bolt straight down its lane
        if hopTarget == nil {
            shootCountdown -= dt
            if shootCountdown <= 0 {
                fireBolt()
                shootCountdown = Tuning.skimmerShootIntervalSeconds
                    + .random(in: 0...Tuning.skimmerShootJitterSeconds)
            }
        }
        let progress = skimmerElapsed / Tuning.passClockSeconds
        let depth = Tuning.skimmerSpawnDepth * (1 - progress)
        placeOnWall(skimmer, t: skimmerT, depth: depth,
                    height: Tuning.skimmerSize.height)
    }

    private var skimmerDepth: Double {
        Tuning.skimmerSpawnDepth * (1 - skimmerElapsed / Tuning.passClockSeconds)
    }

    private func fireBolt() {
        let node = SKShapeNode()
        node.strokeColor = Palette.enemyEngine
        node.glowWidth = Tuning.tracerGlowWidth
        node.lineWidth = Tuning.strokeWidth
        node.blendMode = .add
        node.zPosition = 1.6
        addChild(node)
        bolts.append(Bolt(node: node, t: railTs[skimmerLane], depth: skimmerDepth))
    }

    private func stepBolts(_ dt: TimeInterval) {
        for i in bolts.indices {
            bolts[i].depth += dt * Tuning.boltDepthPerSecond
            let bolt = bolts[i]
            if bolt.depth >= 1 {
                // a bolt hugs its rail; any air clears it
                if laneDistance(bolt.t, podT) <= Tuning.laneHitWidth,
                   podAirRemaining <= 0, bigJump == nil, invulnRemaining <= 0 {
                    damagePod()
                }
                bolt.node.removeFromParent()
            } else {
                let frame = wallFrame(at: bolt.t)
                let anchor = CGPoint(x: frame.point.x + frame.wall.normal.dx * 3,
                                     y: frame.point.y + frame.wall.normal.dy * 3)
                let head = projectPoint(anchor, bolt.depth).point
                let tail = projectPoint(anchor, min(1, bolt.depth + 0.05)).point
                let path = CGMutablePath()
                path.move(to: head)
                path.addLine(to: tail)
                bolt.node.path = path
            }
        }
        bolts.removeAll { $0.depth >= 1 }
    }

    // level-ups ride the lanes; be there, on the ground, when they arrive
    private func stepPickups(_ dt: TimeInterval) {
        pickupCountdown -= dt
        if pickupCountdown <= 0 {
            spawnPickup()
            pickupCountdown = Tuning.pickupIntervalSeconds
        }
        for i in pickups.indices {
            pickups[i].depth += dt * Tuning.trackScrollPerSecond * forwardScale
            let pickup = pickups[i]
            if pickup.depth >= 1 {
                let reach = (Tuning.pickupSize.width + Tuning.podSize.width) / 2
                if laneDistance(railTs[pickup.rail], podT) < reach,
                   podAirRemaining <= 0, bigJump == nil {
                    collect(pickup.kind)
                    spark(at: pickup.node.position, radius: Tuning.sparkRadius)
                }
                pickup.node.removeFromParent()
            } else {
                placeOnWall(pickup.node, t: railTs[pickup.rail], depth: pickup.depth,
                            height: Tuning.pickupSize.height)
            }
        }
        pickups.removeAll { $0.depth >= 1 }
    }

    private func spawnPickup() {
        // splatter: points most common, tools and armor behind them
        let kind: PickupKind
        switch Int.random(in: 0..<5) {
        case 0, 1: kind = .points
        case 2: kind = .gun
        case 3: kind = .shield
        default: kind = .multiplier
        }
        addPickup(kind, rail: Int.random(in: 0..<Tuning.railCount), depth: 0)
    }

    private func addPickup(_ kind: PickupKind, rail: Int, depth: Double) {
        let tex: SKTexture
        switch kind {
        case .gun: tex = Sprites.gunChip
        case .shield: tex = Sprites.shieldChip
        case .points: tex = Sprites.pointsChip
        case .multiplier: tex = Sprites.multChip
        }
        let node = SKSpriteNode(texture: tex)
        node.size = Tuning.pickupSize
        node.zPosition = 1.4
        addChild(node)
        pickups.append(Pickup(node: node, kind: kind, rail: rail, depth: depth))
    }

    private func collect(_ kind: PickupKind) {
        switch kind {
        case .gun:
            gunLevel = min(Tuning.gunLevelMax, gunLevel + 1)
        case .shield:
            hull = min(Tuning.hullPickupCap, hull + 1)
        case .points:
            let points = Tuning.pointsChipValue * scoreMultiplier
            score += points
            scorePopup("+\(points)", at: pod.position, color: Palette.podEngine)
        case .multiplier:
            scoreMultiplier = min(Tuning.chainMax, scoreMultiplier + 1)
            scorePopup("x\(scoreMultiplier)", at: pod.position, color: Palette.enemyMarker)
        }
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
        skimmerHp = Tuning.skimmerHitsToKill
        skimmer.removeAllChildren()
        // remaining hits, readable over the dome
        skimmerHpPips = []
        for i in 0..<Tuning.skimmerHitsToKill {
            let pip = SKSpriteNode(color: Palette.enemyMarker, size: Tuning.hpPipSize)
            let span = CGFloat(Tuning.skimmerHitsToKill - 1)
                * (Tuning.hpPipSize.width + Tuning.hpPipGap)
            pip.position = CGPoint(
                x: -span / 2 + CGFloat(i) * (Tuning.hpPipSize.width + Tuning.hpPipGap),
                y: Tuning.skimmerSize.height / 2 + Tuning.hpPipRise)
            skimmer.addChild(pip)
            skimmerHpPips.append(pip)
        }
        shootCountdown = Tuning.skimmerShootIntervalSeconds
        skimmerAlive = true
        placeOnWall(skimmer, t: skimmerT, depth: Tuning.skimmerSpawnDepth,
                    height: Tuning.skimmerSize.height)
        skimmer.isHidden = false
    }

    private func despawnSkimmer() {
        skimmerAlive = false
        skimmer.isHidden = true
        respawnCountdown = Tuning.respawnDelaySeconds
    }

    // three hits by default; every hit flashes the hull, knocks something
    // off, and sheds a multiplier chip worth chasing
    private func hitSkimmer(_ damage: Int) {
        skimmerHp -= damage
        for (i, pip) in skimmerHpPips.enumerated() {
            pip.alpha = i < skimmerHp ? 1 : 0.15
        }
        if skimmerHp <= 0 {
            killSkimmer()
            return
        }
        skimmer.run(.sequence([
            .colorize(with: Palette.flash, colorBlendFactor: 0.9, duration: 0.02),
            .colorize(withColorBlendFactor: 0, duration: Tuning.hitFlashSeconds),
        ]))
        addPickup(.multiplier, rail: skimmerLane, depth: skimmerDepth)
        skimmerElapsed = max(0, skimmerElapsed - Tuning.skimmerHitKnockbackSeconds)
        spark(at: skimmer.position, radius: Tuning.sparkRadius)
        // a piece comes off, and the wound stays on the hull
        for sign: CGFloat in [-1, 1] {
            let frag = SKSpriteNode(color: Palette.ufoHullDark, size: Tuning.fragmentSize)
            frag.position = skimmer.position
            frag.zPosition = 2.5
            frag.run(.sequence([
                .group([.moveBy(x: sign * Tuning.fragmentDistance,
                                y: Tuning.fragmentDistance / 2,
                                duration: Tuning.fragmentSeconds),
                        .fadeOut(withDuration: Tuning.fragmentSeconds)]),
                .removeFromParent(),
            ]))
            addChild(frag)
        }
        let scorch = SKSpriteNode(color: Bool.random() ? Palette.junkDark
                                                       : Palette.enemyEngine,
                                  size: Tuning.fragmentSize)
        scorch.position = CGPoint(
            x: .random(in: -Tuning.skimmerSize.width / 3...Tuning.skimmerSize.width / 3),
            y: .random(in: -Tuning.skimmerSize.height / 4...Tuning.skimmerSize.height / 4))
        skimmer.addChild(scorch)
    }

    private func killSkimmer() {
        kills += 1
        let remaining = max(0, Tuning.passClockSeconds - skimmerElapsed)
        let brink = Tuning.brinkTiers.first { remaining <= $0.secondsLeft }?.multiplier ?? 1
        let points = Tuning.baseKillScore * brink * scoreMultiplier
        score += points
        scorePopup("+\(points)", at: skimmer.position,
                   color: brink > 1 ? Palette.enemyMarker : Palette.reticle)
        // a brink kill banks the DEVASTATOR; the wreck sheds a multiplier
        if brink > 1, !devastatorBanked {
            devastatorBanked = true
            scorePopup("DEVASTATOR READY", at: pod.position, color: Palette.hazard)
        }
        addPickup(.multiplier, rail: skimmerLane, depth: skimmerDepth)
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
            piece.ping.removeFromParent()
        }
        junkPieces.removeAll { laneDistance(railTs[$0.rail], podT) <= Tuning.laneHitWidth }
        if skimmerInLine { hitSkimmer(gunLevel) }
    }

    // the DEVASTATOR: everything in the tube dies in one white breath
    private func fireDevastator() {
        guard devastatorBanked, stunRemaining <= 0 else { return }
        devastatorBanked = false
        let flash = SKSpriteNode(color: Palette.flash, size: size)
        flash.position = CGPoint(x: centerX, y: size.height / 2)
        flash.alpha = Tuning.devastatorFlashAlpha
        flash.zPosition = 5
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: Tuning.devastatorFlashSeconds),
                             .removeFromParent()]))
        for piece in junkPieces {
            spark(at: piece.node.position, radius: Tuning.sparkRadius)
            piece.node.removeFromParent()
            piece.ping.removeFromParent()
        }
        junkPieces.removeAll()
        for bolt in bolts { bolt.node.removeFromParent() }
        bolts.removeAll()
        if skimmerAlive { killSkimmer() }
    }

    private func scorePopup(_ text: String, at point: CGPoint, color: SKColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = Tuning.scoreFontSize
        label.fontColor = color
        label.position = point
        label.zPosition = 3
        addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: Tuning.popupRise, duration: Tuning.popupSeconds),
                    .fadeOut(withDuration: Tuning.popupSeconds)]),
            .removeFromParent(),
        ]))
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
        if event.keyCode == Key.down, !event.isARepeat {
            fireDevastator()
        }
        if event.keyCode == Key.up, !event.isARepeat, stunRemaining <= 0 {
            // one tap hops; a second tap in the window is the big jump
            if event.timestamp - lastUpTap <= Tuning.railDoubleTapSeconds {
                startBigJump()
            } else {
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
