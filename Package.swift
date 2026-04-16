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
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/4.2.3/CometChatCallsSDK_4_2_3.xcframework.zip",
            checksum: "9828f522b64182fe68fb0f78b43e7f8214502fb7f6295f02f6700294a7e83682"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://library.cometchat.io/ios/v2.0/xcode12/CometChatWebRTC_124_0_4.xcframework.zip",
            checksum: "1f14e51b820f4046229702d3a59c7b81fead1550b078734d79ca6b09560bcd9c"
        )
    ]
    
)
