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
        .library(name: "CometChatCalls", targets: ["CometChatCalls","WebRTC"])
    ],
    targets: [
        .binaryTarget(
            name: "CometChatCalls",
            url: "https://library.cometchat.io/ios/spm/Calls/CometChatCalls_2_3_0-alpha4.xcframework.zip",
            checksum: "6b14d7a2ed6dfa749308383a1e53528927a991a9fec73fc063b3977e0c71f116"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.1/xcode12/WebRTC_1.xcframework.zip",
            checksum: "3060aaaf679df346075f5c90f4dd816312e30dc73b925ec5e9d868923c7b5159"
        )
    ]
    
)
