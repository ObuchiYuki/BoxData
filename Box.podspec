Pod::Spec.new do |spec|

  spec.name         = "Box"
  spec.version      = "1.0.0"
  spec.summary      = "Light weight seriarization library."
  spec.homepage     = "https://github.com/ObuchiYuki/BoxData"
  spec.license      = "MIT"
  spec.author             = { "yuki" => "yukibochi1@gmail.com" }
  spec.source       = { :git => "https://github.com/ObuchiYuki/BoxData.git", :tag => "#{spec.version}" }
  spec.source_files  = "Classes", "Classes/**/*.{h,m}"
  spec.exclude_files = "Classes/Exclude"

end
