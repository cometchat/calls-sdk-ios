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
            url: "https://library.cometchat.io/ios/spm/Calls/CometChatProCalls_3_0_0-alpha3.xcframework.zip",
            checksum: "ba397155ce5f83e7980403667390140571dc228990a7f0c5a2f18d61f44b777a"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.1/xcode12/WebRTC_1.xcframework.zip",
            checksum: "3060aaaf679df346075f5c90f4dd816312e30dc73b925ec5e9d868923c7b5159"
        )
    ]
    
)
