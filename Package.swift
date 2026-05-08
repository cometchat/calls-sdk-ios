// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CometChatCallsSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "CometChatCallsSDK", targets: ["CometChatCallsSDK", "WebRTC"])
    ],
    targets: [
        .binaryTarget(
            name: "CometChatCallsSDK",
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/5.0.0/CometChatCallsSDK-5.0.0.zip",
            checksum: "7369555e599ebccbd9028b3c39e75a58fef1452e5ed9cabb00509ff27fcc2879"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/124.0.4/CometChatWebRTC-124.0.4.xcframework.zip",
            checksum: "fae7fc22b83c68ce69fcb5dbb447fe08ef2cc4b7a1ab83b624ae1bcc996d93fe"
        )
    ]
)
