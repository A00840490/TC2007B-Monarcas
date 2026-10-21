// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CaritasAuth",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "CaritasAuth", targets: ["CaritasAuth"])
    ],
    targets: [
        .target(name: "CaritasAuth", resources: [.process("Resources")])
    ]
)
