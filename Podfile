source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def shared
  pod 'Tor/GeoIP', '~> 407.12'
  pod 'IPtProxyUI', '~> 1.10.3' #:git => 'https://github.com/tladesignz/IPtProxyUI-ios' # :path => '../IPtProxyUI-ios'
end

def shared_vpn
  pod 'GCDWebServerExtension', :git => 'https://github.com/tladesignz/GCDWebServer.git'
end

target 'Orbot' do
  platform :ios, '15.0'

  shared

  pod 'Eureka', '~> 5.3'
end

target 'Orbot Mac' do
	platform :macos, '11.0'

	shared
end

target 'TorVPN' do
  platform :ios, '15.0'

  shared
  shared_vpn
end

target 'TorVPN Mac' do
  platform :macos, '11.0'

  shared
  shared_vpn
end

# Fix Xcode 14 code signing issues with bundles.
# See https://github.com/CocoaPods/CocoaPods/issues/8891#issuecomment-1249151085
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
