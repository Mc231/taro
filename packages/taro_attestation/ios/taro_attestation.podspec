#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint taro_attestation.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'taro_attestation'
  s.version          = '0.0.0'
  s.summary          = 'Taro device attestation (App Attest / DeviceCheck).'
  s.description      = <<-DESC
Taro device attestation (App Attest / DeviceCheck).
                       DESC
  s.homepage         = 'https://github.com/Mc231/taro'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Volodymyr Shyrochuk' => 'volodymyr.shyrochuk@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'taro_attestation/Sources/taro_attestation/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'taro_attestation_privacy' => ['taro_attestation/Sources/taro_attestation/PrivacyInfo.xcprivacy']}
end
