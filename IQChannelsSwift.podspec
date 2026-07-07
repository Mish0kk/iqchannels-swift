#
# Be sure to run `pod lib lint IQChannelsSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'IQChannelsSwift'
    s.version          = '2.3.4'
    s.summary          = 'A short description of IQChannelsSwift.'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    TODO: Add long description of the pod here.
    DESC
    
    s.homepage         = 'https://github.com/iqstore/iqchannels-swift'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Daulet Tokmukhanbet' => '61043918+dato3@users.noreply.github.com' }
    s.source           = { :git => 'https://github.com/iqstore/iqchannels-swift.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '14.0'
    
    s.source_files = 'IQChannelsSwift/IQLibraryConfiguration.swift', 'IQChannelsSwift/**/*.h', 'IQChannelsSwift/**/*.m'
    
    s.subspec 'Controllers' do |spec|
        spec.source_files = 'IQChannelsSwift/Controllers/**/*'
    end
    
    s.subspec 'Views' do |spec|
        spec.source_files = 'IQChannelsSwift/Views/**/*'
    end
    
    s.subspec 'Models' do |spec|
        spec.source_files = 'IQChannelsSwift/Models/**/*'
    end
    
    s.subspec 'ViewModels' do |spec|
        spec.source_files = 'IQChannelsSwift/ViewModels/**/*'
    end    
    
    s.subspec 'Managers' do |spec|
        spec.source_files = 'IQChannelsSwift/Managers/**/*'
    end
    
    s.subspec 'ManagersObjC' do |spec|
        spec.source_files = 'IQChannelsSwift/ManagersObjC/**/*'
    end
    
    s.subspec 'Protocols' do |spec|
        spec.source_files = 'IQChannelsSwift/Protocols/**/*'
    end
    
    s.subspec 'Extensions' do |spec|
        spec.source_files = 'IQChannelsSwift/Extensions/**/*'
    end
    
    s.subspec 'Database' do |spec|
        spec.source_files = 'IQChannelsSwift/Database/**/*'
    end
    
    s.resource_bundles = {
        'IQChannelsSwift' => ['IQChannelsSwift/Assets/Assets.xcassets', 'IQChannelsSwift/PrivacyInfo.xcprivacy']
    }
    
    s.frameworks = 'UIKit'
#    s.dependency 'TRVSEventSource', '0.0.8'
    s.dependency 'SDWebImageSwiftUI', '3.0.4'
    s.dependency 'SQLite.swift', '> 0.13'
    # s.dependency 'AFNetworking', '~> 2.3'
end
