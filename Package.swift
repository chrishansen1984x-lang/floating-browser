// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FloatingBrowser",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FloatingBrowser", targets: ["FloatingBrowser"])
    ],
    targets: [
        .executableTarget(
            name: "FloatingBrowser",
            path: "Sources"
        ),
        .testTarget(
            name: "FloatingBrowserTests",
            dependencies: ["FloatingBrowser"],
            path: "Tests"
        )
    ]
)
