// The MIT License (MIT)
//
// Copyright (c) 2015 Luke Zhao <me@lkzhao.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import MetalKit

fileprivate struct GPUAnimationState{
  // do not change the order of these variables
  // this struct is shared in Metal shader
  var frame: float4 = float4()
  var target: float4
  var velocity: float4 = float4()
  var threshold: Float
  var stiffness: Float
  var damping: Float
  var running: Int32 = 1

  init(current c:float4, target t: float4, stiffness s:Float = 150, damping d:Float = 10, threshold th:Float = 0.01) {
    frame = c
    target = t
    threshold = th
    stiffness = s
    damping = d
  }
}

public typealias GPUAnimationGetter = () -> float4
public typealias GPUAnimationSetter = (inout float4) -> Void

fileprivate struct GPUAnimationMetaData{
  var getter:GPUAnimationGetter!
  var setter:GPUAnimationSetter!
  var completion:((Bool)->Void)?
  init(getter:@escaping GPUAnimationGetter, setter:@escaping GPUAnimationSetter, completion:((Bool)->Void)? = nil){
    self.getter = getter
    self.setter = setter
    self.completion = completion
  }
}

open class GPUSpringAnimator: NSObject {
  open static let sharedInstance = GPUSpringAnimator()
  
  private var displayLinkPaused:Bool{
    get{
      return displayLink == nil
    }
    set{
      newValue ? stop() : start()
    }
  }
  
  #if os(macOS)
    private var displayLink : CVDisplayLink?
  #elseif os(iOS)
    private var displayLink : CADisplayLink?
  #endif
  private var worker:GPUWorker!
  private var animating = KeySet<Int, String>()
  private var animationBuffer = GPUBuffer<String, GPUAnimationState, GPUAnimationMetaData>()
  private var paramBuffer = GPUBuffer<String, Float, Any>(1)
  private var queuedCommands = [()->()]()
  private var dt:Float = 0
  private var processing = false
  
  private override init(){
    super.init()
    paramBuffer.content![0] = 0
    worker = GPUWorker(functionName: "springAnimate", fallback:springFallback)
    worker.addBuffer(buffer: animationBuffer)
    worker.addBuffer(buffer: paramBuffer)
    worker.completionCallback = doneProcessing
  }
  
  private func springFallback(){
    let dt = paramBuffer.content![0]
    for (_, i) in animationBuffer {
      let a = animationBuffer.content!.baseAddress!.advanced(by: i)
      if (a.pointee.running == 0) { continue }
      
      let diff = a.pointee.frame - a.pointee.target
      
      a.pointee.running = 0
      let absV = abs(a.pointee.velocity)
      let absD = abs(diff)
      for c in [absD.x,absD.y,absD.z,absD.w,absV.x,absV.y,absV.z,absV.w]{
        if c > a.pointee.threshold{
          a.pointee.running = 1
          break
        }
      }
      
      if a.pointee.running != 0 {
        let Fspring = (-a.pointee.stiffness) * diff;
        let Fdamper = (-a.pointee.damping) * a.pointee.velocity;
        
        let acceleration = Fspring + Fdamper;
        
        a.pointee.velocity = a.pointee.velocity + acceleration * dt;
        a.pointee.frame = a.pointee.frame + a.pointee.velocity * dt;
      } else {
        a.pointee.velocity = float4();
        a.pointee.frame = a.pointee.target;
      }
    }
  }
  
  private func doneProcessing(){
    for (k, i) in animationBuffer {
      let meta = animationBuffer.metaDataFor(key: k)!
      meta.setter(&animationBuffer.content![i].frame)
      if (animationBuffer.content![i].running == 0) {
        animationBuffer.remove(key: k)
        meta.completion?(true)
      }
    }
    for fn in queuedCommands{
      fn()
    }
    queuedCommands = []
    processing = false
  }
  
  private func update(duration:Float) {
    dt += duration
    if processing { return }
    
    if animationBuffer.count == 0{
      displayLinkPaused = true
    } else {
      processing = true
      for (k, i) in animationBuffer {
        animationBuffer.content![i].frame = animationBuffer.metaDataFor(key: k)!.getter()
      }

      paramBuffer.content![0] = dt
      dt = 0
      worker.process(size: animationBuffer.capacity)
    }
  }
  
  public func remove<T:Hashable>(_ item:T, key:String? = nil){
    let removeFn:()->Void
    if let key = key {
      let animationKey = "\(item.hashValue)" + key
      removeFn = {
        self.animating[item.hashValue].remove(key)
        self.animationBuffer.metaDataFor(key: animationKey)?.completion?(false)
        self.animationBuffer.remove(key: animationKey)
      }
    } else {
      removeFn = {
        for key in self.animating[item.hashValue]{
          let animationKey = "\(item.hashValue)" + key
          self.animationBuffer.metaDataFor(key: animationKey)?.completion?(false)
          self.animationBuffer.remove(key: animationKey)
        }
      }
    }
    if processing {
      queuedCommands.append(removeFn)
    } else {
      removeFn()
    }
  }
  
  public func animate<T:Hashable>(_ item:T,
                    key:String,
                    getter:@escaping () -> float4,
                    setter:@escaping (inout float4) -> Void,
                    target:float4,
                    stiffness:Float = 200,
                    damping:Float = 10,
                    threshold:Float = 0.01,
                    completion:((Bool) -> Void)? = nil) {
    let animationKey = "\(item.hashValue)" + key
    let metaData = GPUAnimationMetaData(getter:getter, setter:setter, completion:completion)
    var state = GPUAnimationState(current: getter(), target: target, stiffness: stiffness, damping: damping, threshold: threshold)
    let insertFn = {
      self.animationBuffer.metaDataFor(key: animationKey)?.completion?(false)
      if let index = self.animationBuffer.indexOf(key: animationKey){
        state.velocity = self.animationBuffer.content![index].velocity
      }
      self.animationBuffer.add(key: animationKey, value: state, meta:metaData)
      self.animating[item.hashValue].insert(key)
      if self.displayLinkPaused {
        self.displayLinkPaused = false
      }
    }
    if processing {
      queuedCommands.append(insertFn)
    } else {
      insertFn()
    }
  }
  
  public func velocityFor<T:Hashable>(_ item:T, key:String) -> float4{
    if let index = self.animationBuffer.indexOf(key: "\(item.hashValue)" + key){
      return self.animationBuffer.content![index].velocity
    }
    return float4()
  }
  
  private func start() {
    if !displayLinkPaused {
      return
    }
    
    #if os(macOS)
      CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
      CVDisplayLinkSetOutputCallback(displayLink!, { (_, _, outTime, _, _, userInfo) -> CVReturn in
        let this = Unmanaged<GPUSpringAnimator>.fromOpaque(userInfo!).takeUnretainedValue()
        let out = outTime.pointee
        let duration = Float(1.0 / (out.rateScalar * Double(out.videoTimeScale) / Double(out.videoRefreshPeriod)))
        this.update(duration:duration)
        return kCVReturnSuccess
      }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
      CVDisplayLinkStart(displayLink!)
    #elseif os(iOS)
      displayLink = CADisplayLink(target: self, selector: #selector(updateIOS))
      displayLink!.add(to: RunLoop.main, forMode: RunLoopMode(rawValue: RunLoopMode.commonModes.rawValue))
    #endif
  }
  
  #if os(iOS)
  @objc private func updateIOS(){
    self.update(duration:Float(displayLink!.duration))
  }
  #endif
  
  private func stop() {
    if displayLinkPaused { return }
    animationBuffer.clear()
    #if os(macOS)
      CVDisplayLinkStop(displayLink!)
    #elseif os(iOS)
      displayLink!.isPaused = true
      displayLink!.remove(from: RunLoop.main, forMode: RunLoopMode(rawValue: RunLoopMode.commonModes.rawValue))
    #endif
    displayLink = nil
  }
}




