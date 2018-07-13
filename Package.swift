// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "Radon",
    products: [
        .executable(name: "radon", targets: ["Radon"])
    ],
    dependencies: [
        .package(url: "https://github.com/jatoben/CommandLine.git", from: "3.0.0-pre1"),
        .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", from: "1.0.0"),
        .package(url: "https://github.com/e-sites/Francium.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Radon",
            dependencies: [ "CommandLine", "Cryptor", "Francium" ],
            path: ".",
            sources: ["Sources"]
        )
    ]
)
