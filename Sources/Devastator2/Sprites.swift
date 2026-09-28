import SpriteKit

// Pixel-art sprites as string maps, the C64 way: one character per pixel,
// '.' transparent, letters index the sprite's ink table. Textures render at
// one pixel per cell and upscale nearest-neighbor, so nodes sized at 2x in
// Tuning keep the chunky DS read. Edit the maps in place.
enum Sprites {

    static func texture(_ map: [String], _ inks: [Character: SKColor]) -> SKTexture {
        let h = map.count
        let w = map[0].count
        let ctx = CGContext(data: nil, width: w, height: h,
                            bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        for (row, line) in map.enumerated() {
            for (col, ch) in line.enumerated() {
                guard let ink = inks[ch] else { continue }
                ctx.setFillColor(ink.cgColor)
                ctx.fill(CGRect(x: col, y: h - 1 - row, width: 1, height: 1))
            }
        }
        let tex = SKTexture(cgImage: ctx.makeImage()!)
        tex.filteringMode = .nearest
        return tex
    }

    // the gun pod from behind: turret, hull, rail skids, engines
    static let pod = texture([
        "......TT......",
        ".....HTTH.....",
        "...HHHHHHHH...",
        "..HLLHHHHLLH..",
        ".HHHHHHHHHHHH.",
        ".HDEEHHHHEEDH.",
        "..DEED..DEED..",
        "..D..D..D..D..",
    ], [
        "T": Palette.podHullLight,
        "L": Palette.podHullLight,
        "H": Palette.podHull,
        "D": Palette.podHullDark,
        "E": Palette.podEngine,
    ])

    // the Skimmer from behind, fleeing: marker fin up top, engines at you
    static let skimmer = texture([
        ".....RR.....",
        "...WWWWWW...",
        "..WWWWWWWW..",
        ".WEEWWWWEEW.",
        ".WEEWWWWEEW.",
        "..W..WW..W..",
        "....E..E....",
    ], [
        "W": Palette.enemyHull,
        "R": Palette.enemyMarker,
        "E": Palette.enemyEngine,
    ])

    // wreckage on the tracks
    static let junk = texture([
        "...KKJ.....",
        ".KJJJJK....",
        "KJJJJJJKK..",
        ".KJJJJJJJK.",
        "..KJJJJJK..",
        "....KKK....",
    ], [
        "J": Palette.junkDark,
        "K": Palette.junkLight,
    ])

    // what you are defending
    static let earth = texture([
        "...AAAAAA...",
        ".AAOOOONOAA.",
        ".AOONNNNOOA.",
        "AOONNOOOONOA",
        "AOONOOOOONNA",
        "AOOOOOOONNNA",
        "AOOOOOONNNOA",
        "AONOOOOOOOOA",
        "AONNOOOOOOOA",
        ".AONNOOOONA.",
        ".AAOOOOOOAA.",
        "...AAAAAA...",
    ], [
        "A": Palette.earthAtmos,
        "O": Palette.earthOcean,
        "N": Palette.earthLand,
    ])
}
