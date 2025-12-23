source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def tor
  pod 'Tor/GeoIP-NoLZMA',
   '~> 408.21'
#   :git => 'https://github.com/iCepa/Tor.framework'
#  :path => '../Tor.framework'

#  pod 'Tor/Onionmasq',
#    :podspec => 'https://raw.githubusercontent.com/iCepa/Tor.framework/pure_pod/Arti.podspec'
end

def iptproxy
  pod 'IPtProxyUI/AppEx',
  '~> 4.10'
#   :git => 'https://github.com/tladesignz/IPtProxyUI-ios'
#   :path => '../IPtProxyUI'

#  pod 'IPtProxy',
#   :path => '../IPtProxy'
end

target 'Orbot' do
  platform :ios, '15.0'

  tor
  iptproxy

  pod 'Eureka', '~> 5.5'
  pod 'ProgressHUD', '~> 14.1'
end

target 'Orbot Mac' do
  platform :macos, '11.0'

  tor
  iptproxy
end

target 'TorVPN' do
  platform :ios, '15.0'

  tor
#  iptproxy

  pod 'GCDWebServerExtension', :git => 'https://github.com/tladesignz/GCDWebServer.git'
end

target 'StatusWidget' do
  platform :ios, '15.0'

  tor
  iptproxy
end

target 'TorVPN Mac' do
  platform :macos, '11.0'

  tor
  iptproxy
end

# Fix Xcode 15 compile issues.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.respond_to?(:name) and !target.name.start_with?("Pods-")
      target.build_configurations.each do |config|
        if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
        end
      end
    end
  end
end
