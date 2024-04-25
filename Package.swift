// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CometChatProCalls",
    platforms: [
        // Only add support for iOS 11 and up.
        .iOS(.v11)
    ],
    products: [
        .library(name: "CometChatProCalls", targets: ["CometChatProCalls","WebRTC"])
    ],
    targets: [
        .binaryTarget(
            name: "CometChatProCalls",
            url: "https://library.cometchat.io/ios/v3.0/xcode14/CometChatProCalls_3_0_4.xcframework.zip",
            checksum: "c72036f896ece84325ff3506df1a6b82ea2ed3d659fcd2c34981be1937a9b2fe"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.1/xcode12/WebRTC_1.xcframework.zip",
            checksum: "3060aaaf679df346075f5c90f4dd816312e30dc73b925ec5e9d868923c7b5159"
        )
    ]
    
)
