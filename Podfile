source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def shared
  pod 'Tor/GeoIP', '~> 407.8'
  pod 'IPtProxyUI', :git => 'https://github.com/tladesignz/IPtProxyUI-ios' # :path => '../IPtProxyUI-ios'
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
	platform :macos, '12.3'

	shared
end

target 'TorVPN' do
  platform :ios, '15.0'

  shared
  shared_vpn
end

target 'TorVPN Mac' do
  platform :macos, '12.3'

  shared
  shared_vpn
end
