
Pod::Spec.new do |s|


  s.name         = "VinliNet"
  s.version      = "1.0.9"
  s.summary      = "Framework for accessing Vinli services."

  s.description  = <<-DESC
                   Framework for accessing Vinli services for developers
                   DESC

  s.homepage     = "https://github.com/vinli/ios-net"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "Andrew Wells" => "andrew@vin.li" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/vinli/ios-net.git", :tag => "1.0.9" }

  s.source_files = 'VinliSDK/*.{h,m}'
  #s.resources    = 'VinliSDK/*.{storyboard}'

  s.requires_arc = true

end
