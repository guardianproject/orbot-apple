source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def shared
	pod 'Tor/GeoIP', '~> 407.8'
	pod 'IPtProxyUI', :git => 'https://github.com/tladesignz/IPtProxyUI-ios'
end

target 'Orbot' do
  platform :ios, '15.0'

  shared

  pod 'Eureka', '~> 5.3'
end

target 'Orbot Mac' do
	platform :macos, '12.3'

	shared
end

target 'TorVPN' do
  platform :ios, '15.0'

  shared

  pod 'GCDWebServerExtension', :git => 'https://github.com/tladesignz/GCDWebServer.git'
end

