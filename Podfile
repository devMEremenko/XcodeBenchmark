source = 'https://github.com/CocoaPods/Specs.git'
minimum_target = '14.5'

platform :ios, minimum_target

target 'XcodeBenchmark' do
  use_frameworks!
  inhibit_all_warnings!
  
  # Firebase
  pod 'FirebaseCore', '~> 11.0'
  pod 'FirebaseFirestore', '~> 11.0'
  pod 'FirebaseAuth', '~> 11.0'
  pod 'FirebaseAnalytics', '~> 11.0'
  pod 'FirebaseRemoteConfig', '~> 11.0'
  pod 'FirebaseStorage', '~> 11.0'
  pod 'FirebaseMessaging', '~> 11.0'

  pod 'lottie-ios'

  # Networking
  pod 'AFNetworking'
  pod 'SDWebImage'
  pod 'Moya'
  pod 'Starscream'
  
  # Core
  pod 'SwiftyJSON'
  pod 'Realm'
  pod 'MagicalRecord', :git => 'https://github.com/magicalpanda/MagicalRecord'
  pod 'RxBluetoothKit', :git => 'https://github.com/i-mobility/RxBluetoothKit.git', :tag => '7.0.4'
  pod 'ReactiveCocoa'
  pod 'CryptoSwift'
  pod 'R.swift.Library'
  pod 'ObjectMapper'
  
  pod 'TRON'
  pod 'DTCollectionViewManager'
  pod 'DTTableViewManager'
  pod 'Ariadne'
  pod 'LoadableViews'
  
  pod 'SwiftDate'
  pod 'SwiftyBeaver'
  
  # UI
  pod 'Hero'
  pod 'SVProgressHUD'
  pod 'Eureka'
  pod 'IQKeyboardManagerSwift'
  pod 'Macaw'
  
  # Layout
  pod 'SnapKit'
  pod 'Masonry'

  # Google
  pod 'GoogleMaps'
  pod 'GooglePlaces'
  pod 'Google-Mobile-Ads-SDK', '~> 11.0'
  pod 'GoogleSignIn', '~> 8.0'

  # Social
  pod 'VK-ios-sdk'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'FacebookShare'
end

post_install do |pi|
    pi.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = minimum_target
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'

            xcconfig_path = config.base_configuration_reference.real_path
            xcconfig = File.read(xcconfig_path)
            xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
            File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
        end
        
        if target.name == 'BoringSSL-GRPC'
          target.source_build_phase.files.each do |file|
            if file.settings && file.settings['COMPILER_FLAGS']
              flags = file.settings['COMPILER_FLAGS'].split
              flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
              file.settings['COMPILER_FLAGS'] = flags.join(' ')
            end
          end
        end
    end

    afnetworking_reachability = pi.sandbox.root + 'AFNetworking/AFNetworking/AFNetworkReachabilityManager.m'
    if File.exist?(afnetworking_reachability)
      file_content = File.read(afnetworking_reachability)
      patched_content = file_content
        .gsub('#import <netinet/in.h>' + "\n", "#import <sys/socket.h>\n#import <netinet/in.h>\n")
        .gsub("#import <netinet6/in6.h>\n", '')
        .gsub('struct sockaddr_in6 address;', 'struct sockaddr_storage address;')
        .gsub('address.sin6_len = sizeof(address);', 'address.ss_len = sizeof(address);')
        .gsub('address.sin6_family = AF_INET6;', 'address.ss_family = AF_INET6;')
      if patched_content != file_content
        File.write(afnetworking_reachability, patched_content)
      end
    end

    afnetworking_http = pi.sandbox.root + 'AFNetworking/AFNetworking/AFHTTPSessionManager.m'
    if File.exist?(afnetworking_http)
      file_content = File.read(afnetworking_http)
      patched_content = file_content.gsub("#import <netinet6/in6.h>\n", '')
      if patched_content != file_content
        File.write(afnetworking_http, patched_content)
      end
    end
end
