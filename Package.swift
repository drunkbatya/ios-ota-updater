// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OTAUpdater",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "OTAUpdater", targets: ["OTAUpdater"]),
    ],
    targets: [
        .target(name: "OTAUpdater"),
    ]
)
