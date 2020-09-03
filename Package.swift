// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Radon",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(name: "radon", targets: ["Radon"])
    ],
    dependencies: [
        .package(url: "https://github.com/basvankuijck/CommandLine.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", from: "1.0.0"),
        .package(url: "https://github.com/e-sites/Francium.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Radon",
            dependencies: [ "CommandLineKit", "Cryptor", "Francium" ],
            path: ".",
            sources: ["Sources"]
        )
    ]
)
