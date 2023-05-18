
Pod::Spec.new do |s|
  s.name         = "RNSpeechIflytek"
  s.version      = "1.0.4"
  s.summary      = "RNSpeechIflytek"
  s.homepage     = "https://github.com/author/RNSpeechIflytek.git"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/author/RNSpeechIflytek.git", :tag => "master" }
  s.source_files  = "*.{h,m,mm}"
  s.vendored_frameworks = "libs/iflyMSC.framework"

  s.libraries = ['z','c++']
  s.frameworks = ['AVFoundation','SystemConfiguration','Foundation','CoreTelephony','AudioToolbox','UIKit','CoreLocation','Contacts','AddressBook','QuartzCore','CoreGraphics','MediaPlayer']
  s.requires_arc = true

  s.dependency "React"
  #s.dependency "others"

end

  
