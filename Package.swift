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
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/5.0.2/CometChatCallsSDK-5.0.2.zip",
            checksum: "271c19e1bfbda01ac3f067a57af1880038910c876a5d5078ca6d8b16af68f362"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/124.0.4/CometChatWebRTC-124.0.4.xcframework.zip",
            checksum: "fae7fc22b83c68ce69fcb5dbb447fe08ef2cc4b7a1ab83b624ae1bcc996d93fe"
        )
    ]
)
