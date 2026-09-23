// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CometChatCallsSDK",
    platforms: [
        // Minimum iOS matches the shipped binary (MinimumOSVersion 16.0).
        .iOS("16.0")
    ],
    products: [
        .library(name: "CometChatCallsSDK", targets: ["CometChatCallsSDK","WebRTC"])
    ],
    targets: [
        .binaryTarget(
            name: "CometChatCallsSDK",
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/4.3.4/CometChatCallsSDK_4_3_4.xcframework.zip",
            checksum: "77f2a8dab6759c3c16fcb2a7958c843e24040cde12e41fb0a74d0e249d51d554"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.0/xcode12/CometChatWebRTC_124_0_4.xcframework.zip",
            checksum: "1f14e51b820f4046229702d3a59c7b81fead1550b078734d79ca6b09560bcd9c"
        )
    ]
    
)
