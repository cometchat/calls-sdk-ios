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
            url: "https://library.cometchat.io/ios/v4.0/xcode15/CometChatCallsSDK_4_1_0.xcframework.zip",
            checksum: "02251d30f384d6c8bf0b35f659a30c550dc9190249749963b832d45f51a7af9f"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.1/xcode12/WebRTC_1.xcframework.zip",
            checksum: "3060aaaf679df346075f5c90f4dd816312e30dc73b925ec5e9d868923c7b5159"
        )
    ]
    
)
