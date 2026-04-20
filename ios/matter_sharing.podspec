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

  # System frameworks required
  s.frameworks = 'MatterSupport', 'Matter', 'HomeKit'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_OBJC_INTERFACE_HEADER_NAME' => 'matter_sharing-Swift.h',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
