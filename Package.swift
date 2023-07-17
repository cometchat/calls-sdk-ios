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
            url: "https://library.cometchat.io/ios/spm/Calls/CometChatProCalls_3_0_1-beta3.xcframework.zip",
            checksum: "744f0384c9743a288ad344e942901f65bff038d0759265c30329cbc6274c9dec"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.1/xcode12/WebRTC_1.xcframework.zip",
            checksum: "3060aaaf679df346075f5c90f4dd816312e30dc73b925ec5e9d868923c7b5159"
        )
    ]
    
)
