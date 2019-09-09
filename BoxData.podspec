Pod::Spec.new do |spec|

  spec.name         = "BoxData"
  spec.version      = "1.0"
  spec.summary      = "Light weight seriarization library."
  spec.homepage     = "https://github.com/ObuchiYuki/BoxData"
  spec.license      = "MIT"
  spec.author             = { "yuki" => "yukibochi1@gmail.com" }
  spec.source       = { :git => "https://github.com/ObuchiYuki/BoxData.git", :tag => "#{spec.version}" }
  spec.source_files  = "Box/SharedCode/*.{swift}"
  spec.swift_version = "4.0"
  spec.ios.deployment_target  = '9.0'
  spec.osx.deployment_target  = '10.10'

  #spec.platform     = :ios, "10.0"


end
