Pod::Spec.new do |s|
  s.name             = "GPUAnimation"
  s.version          = "0.0.1"
  s.summary          = "iOS Animation on GPU Made Fast and Easy "

  s.description      = <<-DESC
                        A iOS UIKit Animation Library that use the Metal library for all the heavy lifting.
                        Provides an elegant API for view animtions. Also able to animate any attributes you like.
                        Save CPU time for handing events instead of calculation animation steps.
                       DESC

  s.homepage         = "https://github.com/lkzhao/GPUAnimation"
  s.screenshots      = "https://github.com/lkzhao/GPUAnimation/blob/master/imgs/demo.gif?raw=true"
  s.license          = 'MIT'
  s.author           = { "Luke" => "me@lkzhao.com" }
  s.source           = { :git => "https://github.com/lkzhao/GPUAnimation.git" }
  
  s.ios.deployment_target  = '9.0'
  s.ios.frameworks         = 'UIKit','MetalKit','Accelerate'

  s.requires_arc = true

  s.source_files = 'GPUAnimation/*'
end
