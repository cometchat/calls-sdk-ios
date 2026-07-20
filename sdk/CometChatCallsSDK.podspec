Pod::Spec.new do |spec|
  spec.name             = 'CometChatCallsSDK'
  spec.version          = '5.0.2'
  spec.license          = { :type => 'MIT', :text => 'Copyright (c) CometChat. MIT License.' }
  spec.homepage         = 'https://www.cometchat.com/'
  spec.authors          = { 'CometChat' => 'jitvar.patil@cometchat.com' }
  spec.summary          = 'CometChat Calls SDK for iOS - Provides video and audio calling capabilities.'
  spec.source           = { :http => 'https://dl.cloudsmith.io/public/cometchat/cometchat/raw/versions/5.0.2/CometChatCallsSDK-5.0.2.zip' }
  spec.vendored_frameworks = 'CometChatCallsSDK.xcframework'
  spec.dependency 'CometChatWebRTC', '~> 124.0.4'
  spec.documentation_url = 'https://www.cometchat.com/docs/'
  spec.framework        = 'CometChatCallsSDK'
  spec.resource_bundles = { 'CometChatCallsSDK' => ['CometChatCallsSDK.xcframework/PrivacyInfo.xcprivacy'] }
  spec.platform         = :ios, '15.1'
end
