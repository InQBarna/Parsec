// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parsec",
    defaultLocalization: "en",    
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "Parsec",
            targets: ["Parsec"]),
    ],
    targets: [
        .target(
            name: "Parsec",
            path: "Source"
        )
    ]
)
