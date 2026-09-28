import SpriteKit

// Every color lives here, by role. This set is level 1, lunar dawn; later
// levels swap the values per the DESIGN.md palette arc.
enum Palette {
    // sky
    static let space = SKColor(red: 0.03, green: 0.03, blue: 0.07, alpha: 1)
    static let star = SKColor(red: 0.85, green: 0.87, blue: 0.95, alpha: 1)
    static let horizonGlow = SKColor(red: 0.45, green: 0.48, blue: 0.60, alpha: 1)

    // the bore: engineered transit-tube panels, lit from the open roof
    static let trenchAir = SKColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1)
    static let depthFog = SKColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1)
    static let floorPanel = SKColor(red: 0.30, green: 0.33, blue: 0.42, alpha: 1)
    static let lowerPanel = SKColor(red: 0.24, green: 0.26, blue: 0.34, alpha: 1)
    static let upperPanel = SKColor(red: 0.17, green: 0.19, blue: 0.26, alpha: 1)
    static let mouthLight = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 1)
    static let rockBody = SKColor(red: 0.16, green: 0.17, blue: 0.21, alpha: 1)
    static let dirtLight = SKColor(red: 0.22, green: 0.23, blue: 0.27, alpha: 1)
    static let dirtDark = SKColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1)
    static let bone = SKColor(red: 0.75, green: 0.73, blue: 0.62, alpha: 1)
    static let rockSlopeLit = SKColor(red: 0.30, green: 0.31, blue: 0.37, alpha: 1)
    static let rockSlopeShade = SKColor(red: 0.22, green: 0.23, blue: 0.28, alpha: 1)
    static let rockFloor = SKColor(red: 0.26, green: 0.27, blue: 0.32, alpha: 1)
    static let surface = SKColor(red: 0.38, green: 0.39, blue: 0.45, alpha: 1)
    static let edgeLight = SKColor(red: 0.55, green: 0.57, blue: 0.66, alpha: 1)
    static let stripe = SKColor(red: 0.40, green: 0.44, blue: 0.58, alpha: 1)
    static let railHot = SKColor(red: 0.55, green: 0.85, blue: 1.0, alpha: 1)

    // actors
    static let podHullLight = SKColor(red: 0.82, green: 0.85, blue: 0.90, alpha: 1)
    static let podHull = SKColor(red: 0.62, green: 0.66, blue: 0.74, alpha: 1)
    static let podHullDark = SKColor(red: 0.38, green: 0.42, blue: 0.50, alpha: 1)
    static let podEngine = SKColor(red: 0.55, green: 0.90, blue: 1.0, alpha: 1)
    static let enemyHull = SKColor(red: 0.58, green: 0.46, blue: 0.40, alpha: 1)
    static let enemyMarker = SKColor(red: 1.0, green: 0.35, blue: 0.25, alpha: 1)
    static let enemyEngine = SKColor(red: 1.0, green: 0.62, blue: 0.30, alpha: 1)
    static let ufoGlass = SKColor(red: 0.60, green: 0.85, blue: 0.90, alpha: 1)
    static let ufoGlint = SKColor(red: 0.95, green: 1.0, blue: 1.0, alpha: 1)
    static let ufoHull = SKColor(red: 0.72, green: 0.74, blue: 0.80, alpha: 1)
    static let ufoHullDark = SKColor(red: 0.42, green: 0.44, blue: 0.52, alpha: 1)
    static let ufoLight = SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 1)
    static let junkDark = SKColor(red: 0.28, green: 0.26, blue: 0.24, alpha: 1)
    static let junkLight = SKColor(red: 0.48, green: 0.45, blue: 0.40, alpha: 1)
    static let hazard = SKColor(red: 0.95, green: 0.78, blue: 0.15, alpha: 1)

    // earth
    static let earthAtmos = SKColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1)
    static let earthOcean = SKColor(red: 0.15, green: 0.35, blue: 0.80, alpha: 1)
    static let earthOceanDeep = SKColor(red: 0.10, green: 0.24, blue: 0.60, alpha: 1)
    static let earthLand = SKColor(red: 0.25, green: 0.60, blue: 0.30, alpha: 1)
    static let earthSand = SKColor(red: 0.78, green: 0.66, blue: 0.40, alpha: 1)
    static let earthCloud = SKColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1)
    static let earthNight = SKColor(red: 0.04, green: 0.05, blue: 0.12, alpha: 1)

    // interface and effects
    static let reticle = SKColor(red: 0.55, green: 1.0, blue: 0.65, alpha: 1)
    static let tracer = SKColor(red: 0.80, green: 1.0, blue: 0.90, alpha: 1)
    static let spark = SKColor(red: 1.0, green: 0.95, blue: 0.75, alpha: 1)
    static let flash = SKColor.white
}
