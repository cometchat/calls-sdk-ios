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
            url: "https://dl.cloudsmith.io/public/cometchat/call-team/raw/versions/5.0.0-beta.2/CometChatCallsSDK-5.0.0-beta.2.zip",
            checksum: "07d68f133125373d92ecdf483e3fe22dbae85c433b4a5e070f6514835104a31d"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://dl.cloudsmith.io/public/cometchat/call-team/raw/versions/124.0.4/CometChatWebRTC-124.0.4.xcframework.zip",
            checksum: "fae7fc22b83c68ce69fcb5dbb447fe08ef2cc4b7a1ab83b624ae1bcc996d93fe"
        )
    ]
)
