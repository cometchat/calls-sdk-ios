// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CometChatCallsSDK",
    platforms: [
        .iOS("15.1")
    ],
    products: [
        .library(name: "CometChatCallsSDK", targets: ["CometChatCallsSDK", "WebRTC"])
    ],
    targets: [
        .binaryTarget(
            name: "CometChatCallsSDK",
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/5.1.0/CometChatCallsSDK-5.1.0.zip",
            checksum: "3d60c645ff3c8aa7a78d90467a5de1f2ab8ab8dfc429caf39d556f806c10394e"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/155.0.0/CometChatWebRTC-155.0.0.xcframework.zip",
            checksum: "bfc104ed2d3afb4285f4502aa949f1b44a0435d6e29c377094b24ed421578f59"
        )
    ]
)
