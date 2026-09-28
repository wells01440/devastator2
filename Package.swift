// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Devastator2",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Devastator2",
            path: "Sources/Devastator2"
        )
    ]
)
