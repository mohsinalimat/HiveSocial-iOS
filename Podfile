# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

# ignore all warnings from all pods
inhibit_all_warnings!

target 'HIVE' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for HIVE
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'FirebaseFirestoreSwift'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Giphy'#, '~> 2.0.9'
  pod 'FBSDKLoginKit'
  pod 'GoogleSignIn'
  
  pod 'SDWebImage'
#  pod 'PINRemoteImage'
  pod 'IQKeyboardManagerSwift'
  
  pod 'MBProgressHUD'
  pod 'XLPagerTabStrip'
  pod 'ESPullToRefresh'
#  pod 'SPAlert'
  pod 'Zoomy'
  
  pod 'CollectionKit'
  pod 'BEMCheckBox'
  pod 'SwiftMessages'
  pod 'GradientLoadingBar'
  pod 'MessageKit'
  pod 'YPImagePicker'
  pod 'CollieGallery'
  pod 'SwipeCellKit'
#  pod 'Nuke'
#  pod 'IGListKit'
  pod 'GrowingTextView'

  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
  
end
