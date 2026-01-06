// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "scenic-kernel",
    products: [
        .library(
            name: "scenic_kernel",
            targets: ["scenic_kernel"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "scenic_kernel",
            path: "build/libscenic_kernel.a"
        )
    ]
)
