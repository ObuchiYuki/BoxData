Pod::Spec.new do |s|
  s.name             = 'BoxData'
  s.version          = '0.0.2.3'
  s.summary          = 'A light weight Codable Data format library.'
  s.homepage         = 'https://github.com/ObuchiYuki/BoxData'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ObuchiYuki' => 'yukibochi1@gmail.com' }
  s.source           = { :git => 'https://github.com/ObuchiYuki/BoxData.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target  = '10.12'

  s.source_files = 'BoxData/Classes/**/*'
  s.swift_versions = "5.0"
  
end
