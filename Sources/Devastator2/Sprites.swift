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

    // the gun pod from behind at full working resolution: turret glass,
    // shoulder lights, belly plate, twin rail skids with engine wash
    static let pod = texture([
        "............TTTT............",
        "...........TTTTTT...........",
        "..........HHTTTTHH..........",
        ".......HHHHHHHHHHHHHH.......",
        "......HLLHHHHHHHHHHLLH......",
        ".....HLLHHHHHHHHHHHHLLH.....",
        "....HHHHHHHHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHHHHHHHH...",
        "..HDDHHHHHHHHHHHHHHHHHHDDH..",
        "..HDEEDHHHHHHHHHHHHHHDEEDH..",
        "..HDEEDHHHDDDDDDDDHHHDEEDH..",
        "..HDEEDHHDDDDDDDDDDHHDEEDH..",
        "...DDEEDDHHHHHHHHHHDDEEDD...",
        "....DEEED..........DEEED....",
        "....DD.DD..........DD.DD....",
        ".....D..D............D..D...",
    ], [
        "T": Palette.ufoGlass,
        "L": Palette.podHullLight,
        "H": Palette.podHull,
        "D": Palette.podHullDark,
        "E": Palette.podEngine,
    ])

    // the opponent at full working resolution: a saucer, frisbee-proud.
    // Glass dome with a glint, running lights, tractor wash and prongs.
    static let skimmer = texture([
        "..................GGGGGGGG..................",
        "................GGggggGGGGGG................",
        "..............GGggggggGGGGGGGG..............",
        ".............GGgggggGGGGGGGGGGG.............",
        "............GGggggGGGGGGGGGGGGGG............",
        "............GGGGGGGGGGGGGGGGGGGG............",
        "...........MGGGGGGGGGGGGGGGGGGGGM...........",
        "......MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM......",
        "...MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM...",
        ".MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.",
        "MLLMMLLMMLLMMLLMMLLMMLLMMLLMMLLMMLLMMLLMMLLM",
        ".mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm.",
        "...mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm...",
        "......mmmEEEEEEEEEEEEEEEEEEEEEEEEEEmmm......",
        ".........mEEEEEEEEEEEEEEEEEEEEEEEEm.........",
        "............EEEEEEEEEEEEEEEEEEEE............",
        "..............EE....EEEE....EE..............",
        "...............EE....EE....EE...............",
        "................E....EE....E................",
        "..................EE....EE..................",
    ], [
        "G": Palette.ufoGlass,
        "g": Palette.ufoGlint,
        "M": Palette.ufoHull,
        "m": Palette.ufoHullDark,
        "L": Palette.ufoLight,
        "E": Palette.enemyEngine,
    ])

    // level-up chips riding the lanes: catch them, unlike the junk
    static let gunChip = texture([
        ".KKKKKKKKKK.",
        "KJJJJJJJJJJK",
        "KJJJJJYYJJJK",
        "KJJJJYYJJJJK",
        "KJJJYYYYYJJK",
        "KJJJJJYYJJJK",
        "KJJJJYYJJJJK",
        "KJJJJYJJJJJK",
        "KJJJJJJJJJJK",
        ".KKKKKKKKKK.",
    ], [
        "K": Palette.junkLight,
        "J": Palette.junkDark,
        "Y": Palette.hazard,
    ])

    static let shieldChip = texture([
        ".KKKKKKKKKK.",
        "KJJJJJJJJJJK",
        "KJJJSSSSJJJK",
        "KJJSSSSSSJJK",
        "KJJSSSSSSJJK",
        "KJJSSSSSSJJK",
        "KJJJSSSSJJJK",
        "KJJJJSSJJJJK",
        "KJJJJJJJJJJK",
        ".KKKKKKKKKK.",
    ], [
        "K": Palette.junkLight,
        "J": Palette.junkDark,
        "S": Palette.shieldGreen,
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

    // battle debris on the tracks: big, detailed, dangerous. Hazard stripes
    // and dead beacons; pieces of the transit system and the war.
    struct JunkArt {
        let texture: SKTexture
        let size: CGSize
    }

    static let junkArts: [JunkArt] = [
        // a wrecked transit car: windows dark, hazard chevrons, torn frame
        JunkArt(texture: texture([
            "....KKKKKKKKKKKKKKKKKKKKKKKKKKKK....",
            "...KWWWWWWWWWWWWWWWWWWWWWWWWWWWWK...",
            "..KWGGWWGGWWGGWWGGWWGGWWGGWWGGWWGK..",
            "..KWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK..",
            "..KYJYJYJYJYJYJYJYJYJYJYJYJYJYJYJK..",
            "..KWWWWWWWWWWWWWWRRWWWWWWWWWWWWWWK..",
            "..KWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK..",
            "..KWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK..",
            "...JJWWWWJJWWWWWWJJWWWWWWJJWWWJJJ...",
            "....JJJWWJJJWWWWJJJWWWWJJJWWJJJJ....",
            "......JJ..JJJJ....JJJJ....JJJJ......",
            "........KK....KKKK....KKKK..........",
            "..........J..J........J..J..........",
            "............K....KK....K............",
        ], [
            "W": Palette.podHullDark,
            "G": Palette.trenchAir,
            "K": Palette.junkLight,
            "J": Palette.junkDark,
            "Y": Palette.hazard,
            "R": Palette.enemyMarker,
        ]), size: CGSize(width: 36, height: 14)),
        // half a downed saucer, engines dead, keel torn open
        JunkArt(texture: texture([
            ".........MMMMMM...............",
            "......MMGGgGMMMMMMMM..........",
            "...MMMMMMMMMMMMMYYMMMMMM......",
            ".MLLMMLLMMLLMMMMJJJJMMMLLMMM..",
            "mmmmmmmmmmmmmmJJJJJJmmmmmmmmmm",
            ".mmmmmmmmmmmmJJJJJJJJmmmmmmm..",
            "...mmEEEEmmmmmJJJJmmmEEmm.....",
            "......mJJm....mEEmRR..........",
            "..........JJ..JJRR............",
            ".............J..J.............",
        ], [
            "M": Palette.ufoHull,
            "m": Palette.ufoHullDark,
            "G": Palette.ufoGlass,
            "g": Palette.ufoGlint,
            "L": Palette.ufoLight,
            "E": Palette.enemyEngine,
            "J": Palette.junkDark,
            "Y": Palette.hazard,
            "R": Palette.enemyMarker,
        ]), size: CGSize(width: 30, height: 10)),
        // a tangle of crossed girders, hazard-tipped
        JunkArt(texture: texture([
            "YY..............................YY",
            ".KK............................KK.",
            "..KKJ........................JKK..",
            "...JKKJ....................JKKJ...",
            "....JJKKJ................JKKJJ....",
            ".....JJJKKJJ..........JJKKJJJ.....",
            "......JJJJKKJJJJJJJJJJKKJJJJ......",
            ".....JJJKKJJJJJJJJJJJJJJKKJJJ.....",
            "....JJKKJJ....JJJJ....JJJKKJJ.....",
            "...JKKJ........RR........JKKJ.....",
            "..KKJ......................JKK....",
            ".YY..........................YY...",
        ], [
            "K": Palette.junkLight,
            "J": Palette.junkDark,
            "Y": Palette.hazard,
            "R": Palette.enemyMarker,
        ]), size: CGSize(width: 34, height: 12)),
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
