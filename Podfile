platform :ios, '8.0'
use_frameworks!

def import_pods

pod 'iAsync.async'
pod 'iAsync.utils'
pod 'iAsync.network'

pod 'FBSDKCoreKit'
pod 'FBSDKShareKit'
pod 'FBSDKLoginKit'

end

target 'iAsync.social', :exclusive => true do
  import_pods
end

target 'iAsync.socialTests', :exclusive => true do
  import_pods
end
