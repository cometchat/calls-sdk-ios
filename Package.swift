// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CometChatCallsSDK",
    platforms: [
        // Only add support for iOS 11 and up.
        .iOS(.v11)
    ],
    products: [
        .library(name: "CometChatCallsSDK", targets: ["CometChatCallsSDK","WebRTC"])
    ],
    targets: [
        .binaryTarget(
            name: "CometChatCallsSDK",
            url: "https://library.cometchat.io/ios/v4.0/xcode16/CometChatCallsSDK_4_2_0.xcframework.zip",
            checksum: "1027d2bc7fc3a1d78dba0b689d29225b22d1c2ef9524618669a25cc86233c67e"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.0/xcode12/CometChatWebRTC_124_0_4.xcframework.zip",
            checksum: "1f14e51b820f4046229702d3a59c7b81fead1550b078734d79ca6b09560bcd9c"
        )
    ]
    
)
