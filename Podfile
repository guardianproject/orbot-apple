source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

target 'Orbot' do
  platform :ios, '15.0'
end

target 'Orbot Mac' do
  platform :macos, '12.0'
end

target 'Orbot Mac-sys' do
  platform :macos, '12.0'
end

target 'TorVPN' do
  platform :ios, '15.0'

  pod 'GCDWebServerExtension', :git => 'https://github.com/tladesignz/GCDWebServer.git'
end

target 'StatusWidget' do
  platform :ios, '15.0'
end

target 'TorVPN Mac' do
  platform :macos, '12.0'
end

target 'TorVPN Mac-sys' do
  platform :macos, '12.0'
end

# Fix Xcode 15 compile issues.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.respond_to?(:name) and !target.name.start_with?("Pods-")
      target.build_configurations.each do |config|
        if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        end
        if config.build_settings['MACOSX_DEPLOYMENT_TARGET'].to_f < 12
          config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
        end
      end
    end
  end
end
