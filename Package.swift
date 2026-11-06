// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DisplaySleep",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "DisplaySleep",
            path: "Sources/DisplaySleep"
        )
    ]
)
