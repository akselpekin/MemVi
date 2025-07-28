// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MemVi",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "MemVi"),
    ]
)
