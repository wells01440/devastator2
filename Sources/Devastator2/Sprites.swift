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

    // the opponent: a saucer, frisbee-proud. Glass dome with a glint,
    // running lights around the rim, tractor glow underneath.
    static let skimmer = texture([
        ".........GGGG.........",
        "........GggGGGG.......",
        ".......GGGGGGGGG......",
        "....MMMMMMMMMMMMMM....",
        ".MMMMMMMMMMMMMMMMMMMM.",
        "MLMMLLMMLMMLLMMLLMMLLM",
        ".mmmmmmmmmmmmmmmmmmmm.",
        "...mmmEEEEEEEEEEmmm...",
        ".....mEEEEEEEEEEm.....",
        ".......EE....EE.......",
    ], [
        "G": Palette.ufoGlass,
        "g": Palette.ufoGlint,
        "M": Palette.ufoHull,
        "m": Palette.ufoHullDark,
        "L": Palette.ufoLight,
        "E": Palette.enemyEngine,
    ])

    // buried in the dirt, Dig Dug style
    static let skeleton = texture([
        "...BBBB.....",
        "..BBBBBB....",
        "..B.BB.B....",
        "..BBBBBB....",
        "...B..B.....",
        "....BB......",
        "..BBBBBB....",
        "....BB......",
        ".BBBBBBBB...",
        "....BB......",
    ], [
        "B": Palette.bone,
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

    // Earthrise. Day on the west limb, the terminator sweeping the east
    // into night, clouds streaking the oceans. The fabulous shot.
    static let earth = texture([
        "...............AA...............",
        "..........AACCOOOOTTAA..........",
        "........ACCCCOOOOOOTTTTA........",
        "......ACCOOOOOCCOOOOTTTTTA......",
        ".....AOCOOOONNOOCCOOOTTTTTA.....",
        "....AOOOOONNNNOOOCCOOOTTTTTA....",
        "...AOOOONNNNNNOOOOCCOOTTTTTTA...",
        "...AOONNNNSNNNOOOOOCCOTTTTTTA...",
        "..AOONNNSSNNNOOOOOOCCCOTTTTTTA..",
        ".AOONNSSSNNOOOOOOOOCCCOOTTTTTTA.",
        ".AOODNNSSNNOOOOOOOCCCOOOTTTTTTA.",
        ".AOODDNNNNOOOOOOOOCCOOOOTTTTTTA.",
        "AOODDDNNOOOOOOOOOOCCCOOOTTTTTTTA",
        "AOOODDOOOOOOOCCOOOOCCOOOTTTTTTTA",
        "AOOOODOOOOOOCCCCOOOOOOOOTTTTTTTA",
        "ACOOOOOOOOOCCCCCCOOOOOOOTTTTTTTA",
        "ACCOOOOOOOOOCCCCCOOOOOOOTTTTTTTA",
        "AOCCOOOOOOOOOCCCOOOOONOOTTTTTTTA",
        "AOOCCOOOOOOOOOOOOOOONNNOTTTTTTTA",
        "AOOOCCOOOOOOOOOOOOOONNNNOTTTTTTA",
        ".AOOOOCCCOOOOOOOOONNNNNOTTTTTTA.",
        ".AOOOOOCCCOOOOOOOONNNNOOTTTTTTA.",
        ".AOOOOOOCCCOOOOOOONNNOOOTTTTTTA.",
        "..AOOOOOOOCCCOOOOOONNOOTTTTTTA..",
        "...ADOOOOOOOCCCOOOOOOTTTTTTTA...",
        "...ADDOOOOOOOCCCOOOOOTTTTTTTA...",
        "....ADDDOOOOOOOCCOOOOTTTTTTA....",
        ".....AADDOOOOOOOCOOOTTTTTAA.....",
        "......AADDOOOOOOOOOTTTTTAA......",
        "........AAADOOOOOOTTTAAA........",
        "..........AAAOOOOTTAAA..........",
        "...............AA...............",
    ], [
        "A": Palette.earthAtmos,
        "O": Palette.earthOcean,
        "D": Palette.earthOceanDeep,
        "N": Palette.earthLand,
        "S": Palette.earthSand,
        "C": Palette.earthCloud,
        "T": Palette.earthNight,
    ])
}
