Pod::Spec.new do |s|
  s.name             = 'matter_sharing'
  s.version          = '0.1.0'
  s.summary          = 'Share Matter devices to Apple Home and Google Home.'
  s.description      = <<-DESC
    Flutter plugin to share Matter smart home devices to Apple Home and Google Home
    on iOS and Android.
  DESC
  s.homepage         = 'https://github.com/dustinchu/matter_sharing'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dustin Chu' => 'love2121103@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.1'
  s.swift_version    = '5.9'

  # Google Home SDK xcframeworks must be placed in your app's ios/Frameworks/ directory:
  #   YOUR_APP/ios/Frameworks/GoogleHomeSDK.xcframework
  #   YOUR_APP/ios/Frameworks/GoogleHomeTypes.xcframework
  # See: https://github.com/dustinchu/matter_sharing/blob/main/SETUP_IOS.md
  #
  # During pod install, __FILE__ resolves to:
  #   ios/.symlinks/plugins/matter_sharing/ios/matter_sharing.podspec
  # so '../../../..' goes up to the app's ios/ directory.
  app_ios = File.expand_path('../../../..', __FILE__)
  app_frameworks = File.join(app_ios, 'Frameworks')

  if File.exist?("#{app_frameworks}/GoogleHomeSDK.xcframework") &&
     File.exist?("#{app_frameworks}/GoogleHomeTypes.xcframework")
    s.vendored_frameworks = [
      "#{app_frameworks}/GoogleHomeSDK.xcframework",
      "#{app_frameworks}/GoogleHomeTypes.xcframework"
    ]

    # Expose framework search path to ALL targets (Runner + MatterExtension)
    # so that `import GoogleHomeSDK` compiles without manual Xcode settings.
    s.user_target_xcconfig = {
      'FRAMEWORK_SEARCH_PATHS' => "$(inherited) #{app_frameworks}/GoogleHomeSDK.xcframework/ios-arm64 #{app_frameworks}/GoogleHomeSDK.xcframework/ios-arm64-simulator",
      'OTHER_LDFLAGS' => '$(inherited) -framework GoogleHomeSDK'
    }
  end

  # System frameworks required
  s.frameworks = 'MatterSupport', 'Matter', 'HomeKit'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_OBJC_INTERFACE_HEADER_NAME' => 'matter_sharing-Swift.h',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
