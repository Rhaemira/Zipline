// swift-tools-version: 5.9
// Created by Amirali Yazdani.
import PackageDescription

let package = Package(
    name: "ZiplineCore",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "ZiplineCore", targets: ["ZiplineCore"])],
    targets: [
        .target(name: "ZiplineCore"),
        .testTarget(name: "ZiplineCoreTests", dependencies: ["ZiplineCore"])
    ]
)