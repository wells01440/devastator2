import AppKit
import SpriteKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)

let scene = GameScene(size: Tuning.sceneSize)
scene.scaleMode = .aspectFit

let view = SKView(frame: NSRect(origin: .zero, size: Tuning.windowSize))
view.presentScene(scene)

let window = NSWindow(
    contentRect: NSRect(origin: .zero, size: Tuning.windowSize),
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered,
    defer: false
)
window.title = "Devastator 2"
window.contentView = view
window.center()
window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)
app.run()
