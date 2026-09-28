import SpriteKit

final class GameScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .black
        let label = SKLabelNode(text: "DEVASTATOR 2")
        label.fontName = "Menlo-Bold"
        label.fontSize = 24
        label.fontColor = .yellow
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)

        let sub = SKLabelNode(text: "grey-box pending — see AGENTS.md")
        sub.fontName = "Menlo"
        sub.fontSize = 12
        sub.fontColor = .gray
        sub.position = CGPoint(x: size.width / 2, y: size.height / 2 - 28)
        addChild(sub)
    }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == "q" { NSApp.terminate(nil) }
    }
}
