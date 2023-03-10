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
        .library(name: "CometChatCalls", targets: ["CometChatCall","CometChatProCalls","WebRTC"])
    ],
    targets: [
        .binaryTarget(
            name: "CometChatCall",
            url: "https://library.cometchat.io/ios/spm/Calls/CometChatCall_3_0_0-alpha1.xcframework.zip",
            checksum: "15d2f655314b893c17311f5e7e79e7906a2ca84b22cf7e92c6e1177422cd5976"
        ),
        .binaryTarget(
            name: "CometChatProCalls",
            url: "https://library.cometchat.io/ios/spm/Calls/CometChatProCalls_2_3_0-alpha1.xcframework.zip",
            checksum: "60ab190c5894ce1279bf302770af433c606aac64be250f7360c6a276e3dd4c4f"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.1/xcode12/WebRTC_1.xcframework.zip",
            checksum: "3060aaaf679df346075f5c90f4dd816312e30dc73b925ec5e9d868923c7b5159"
        )
    ]
    
)
