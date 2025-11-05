// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PryntTrimmerNext",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "TrimmerEngine", targets: ["TrimmerEngine"]),
        .library(name: "TrimmerUI", targets: ["TrimmerUI"]),
    ],
    targets: [
        .target(
            name: "TrimmerEngine",
            path: "Sources/TrimmerEngine"
        ),
        .target(
            name: "TrimmerUI",
            dependencies: ["TrimmerEngine"],
            path: "Sources/TrimmerUI"
        ),
        .executableTarget(
            name: "DemoLauncher",
            path: "Examples/DemoLauncher"
        )
    ]
)
