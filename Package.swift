// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "displaytoggle",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "DisplayToggleCore", targets: ["DisplayToggleCore"]),
        .executable(name: "DisplayToggleApp", targets: ["DisplayToggleApp"])
    ],
    targets: [
        .target(
            name: "DisplayToggleCore",
            dependencies: []
        ),
        .executableTarget(
            name: "DisplayToggleApp",
            dependencies: ["DisplayToggleCore"]
        ),
        .testTarget(
            name: "DisplayToggleCoreTests",
            dependencies: ["DisplayToggleCore"],
            swiftSettings: [
                .unsafeFlags(["-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-framework", "Testing",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
                ])
            ]
        )
    ]
)
