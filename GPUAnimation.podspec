Pod::Spec.new do |s|
  s.name             = "GPUAnimation"
  s.version          = "0.0.2"
  s.summary          = "iOS Animation Made Fast and Simple."

  s.description      = <<-DESC
                        A iOS UIKit Animation Library that use the Metal for all the heavy lifting.
                        Provides an elegant API for animating any attributes you like.
                        Save CPU time for handing events instead of calculation animation steps.
                       DESC

  s.homepage         = "https://github.com/lkzhao/GPUAnimation"
  s.license          = 'MIT'
  s.author           = { "Luke" => "me@lkzhao.com" }
  s.source           = { :git => "https://github.com/lkzhao/GPUAnimation.git", tag: s.version }
  
  s.ios.deployment_target  = '9.0'
  s.ios.frameworks         = 'UIKit','MetalKit'

  s.requires_arc = true

  s.source_files = 'GPUAnimation/*.swift'

  s.resource_bundles = {
      'GPUAnimation' => [
          'GPUAnimation/*.metal'
      ]
    }
end
