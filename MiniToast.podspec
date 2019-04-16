Pod::Spec.new do |s|
  s.name             = 'MiniToast'
  s.module_name      = 'Toast'
  s.author           = 'Elias Abel'
  s.version          = "1.1.0"
  s.summary          = "An Android toast view implementation for iOS."
  s.description      = "MiniToast is an Android toast view implementation for iOS."
  s.license          = { :type => "MIT", :file => "LICENSE.md" }
  s.source           = { :git => "https://github.com/Meniny/MiniToast.git", :tag => s.version.to_s }
  s.homepage         = "https://github.com/Meniny/MiniToast"
  s.social_media_url = 'https://meniny.cn/'

  s.ios.deployment_target  = '9.0'

  s.dependency         'JustLayout'
  s.swift_version    = '5.0'
  s.requires_arc     = true
  s.source_files     = "MiniToast/*.swift"
end
