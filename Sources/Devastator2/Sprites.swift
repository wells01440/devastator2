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

    // battle debris on the tracks: pieces of craft, bits and bobs
    struct JunkArt {
        let texture: SKTexture
        let size: CGSize
    }

    static let junkArts: [JunkArt] = [
        // a sheared wing
        JunkArt(texture: texture([
            "..........KK.",
            ".......KKWWK.",
            "....KKWWWWK..",
            ".KKWWWWWWK...",
            "KWWWWWKKK....",
        ], [
            "W": Palette.enemyHull,
            "K": Palette.junkLight,
        ]), size: CGSize(width: 26, height: 10)),
        // a hull chunk with a dead viewport
        JunkArt(texture: texture([
            ".KKKKKK..",
            "KWWWWWWK.",
            "KWRRWWWKK",
            "KWRRWWWWK",
            "KWWWWKKK.",
            ".KWWWK...",
            "..KKK....",
        ], [
            "W": Palette.podHullDark,
            "R": Palette.junkDark,
            "K": Palette.junkLight,
        ]), size: CGSize(width: 18, height: 14)),
        // a girder strut
        JunkArt(texture: texture([
            "KKWWKKWWKKWWKK",
            "KWWKKWWKKWWKKW",
            "..KKWWKKWWKK..",
        ], [
            "W": Palette.junkDark,
            "K": Palette.junkLight,
        ]), size: CGSize(width: 28, height: 6)),
        // a bit. also a bob
        JunkArt(texture: texture([
            ".KW..",
            "KWWK.",
            ".KWWK",
            "..KK.",
        ], [
            "W": Palette.junkDark,
            "K": Palette.junkLight,
        ]), size: CGSize(width: 10, height: 8)),
    ]

    // what you are defending. It hangs over everything; that is the point.
    static let earth = texture([
        "...........AA...........",
        ".......AAAAAAAAAA.......",
        ".....AIIIIIIIIIIIIA.....",
        "....AIIOOOOONNOOOIIA....",
        "...AIOOOONNNNOOOOOOIA...",
        "..AOOOONNNNNNOOOOOOOOA..",
        "..AOOONNNNNNNNOOODDOOA..",
        ".AOOONNNNNNNNNOODDDOOOA.",
        ".AOODNNNNNNNOOOODDDOOOA.",
        "AOODDNNNNNOOOOOODDOOOOOA",
        "AOOODDNNNOOOOOOOOOOONOOA",
        "AOOOODNNOOOOOOOOOONNNOOA",
        "AOOOOOOOOOOOOOOOONNNNOOA",
        "AODOOOOOOOOOOOOONNNNNOOA",
        "AODDOOOOOOOOOOOONNNNOOOA",
        ".AODDOOOOOOOOOONNNOOOOA.",
        ".AOODOOOOOOOOOONNOOOOOA.",
        "..AOOOOOOONOOOOOOOOOOA..",
        "..AOOOOOONNNOOOOOOOOOA..",
        "...AOOOOONNOOOOOOOOIA...",
        "....AIOOOOOOOOOOIIIA....",
        ".....AIIIIIIIIIIIIA.....",
        ".......AAAAAAAAAA.......",
        "...........AA...........",
    ], [
        "A": Palette.earthAtmos,
        "I": Palette.earthIce,
        "O": Palette.earthOcean,
        "D": Palette.earthOceanDeep,
        "N": Palette.earthLand,
    ])
}
