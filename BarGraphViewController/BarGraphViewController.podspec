Pod::Spec.new do |s|
  s.name = "BarGraphViewController"
  s.version = "1.0.4"
  s.summary = "A view controller, which generates a UICollectionView-based bar graph."
  s.description = "A view controller, which can generate an animatable bar graph."
  s.homepage = "https://github.com/acruis/BarGraphViewController"
  s.license = "MIT"
  s.authors = { "acruis" => "datsquall@gmail.com" }
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.source = { :git => 'https://github.com/acruis/BarGraphViewController.git', :tag => s.version }
  s.source_files = "BarGraphViewController/BarGraphViewController"
end