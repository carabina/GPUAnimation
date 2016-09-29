//
//  GPUAnimator.swift
//  MetalLayoutTest
//
//  Created by YiLun Zhao on 2016-09-27.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit
import MetalKit

internal struct GPUAnimationState{
  // do not change the order of these variables
  var frame: vector_float4 = vector_float4()
  var target: vector_float4
  var velocity: vector_float4 = vector_float4()
  var threshold: Float
  var stiffness: Float
  var damping: Float
  var running: Bool = true

  init(current c:vector_float4, target t: vector_float4, stiffness s:Float = 150, damping d:Float = 10, threshold th:Float = 0.001) {
    frame = c
    target = t
    threshold = th
    stiffness = s
    damping = d
  }
}

public typealias GPUAnimationGetter = () -> vector_float4
public typealias GPUAnimationSetter = (inout vector_float4) -> Void
internal class GPUAnimationEntry:Hashable{
  var getter:GPUAnimationGetter
  var setter:GPUAnimationSetter
  var completion:(()->Void)?
  var hashValue:Int
  init(hashValue: Int, getter:@escaping GPUAnimationGetter, setter:@escaping GPUAnimationSetter, completion:(()->Void)? = nil){
    self.hashValue = hashValue
    self.getter = getter
    self.setter = setter
    self.completion = completion
  }
}
internal func ==(lhs: GPUAnimationEntry, rhs: GPUAnimationEntry) -> Bool {
  return lhs.hashValue == rhs.hashValue
}

open class GPUSpringAnimator: NSObject {
  open static let sharedInstance = GPUSpringAnimator()
  
  open var displayLinkPaused:Bool{
    get{
      return displayLink == nil
    }
    set{
      newValue ? stop() : start()
    }
  }
  
  var displayLink : CADisplayLink!
  var worker:GPUWorker!
  var animationBuffer = GPUBuffer<GPUAnimationEntry, GPUAnimationState>()
  var paramBuffer = GPUBuffer<String, Float>(1)
  
  override init(){
    super.init()
    do {
      paramBuffer.content![0] = 0
      worker = try GPUWorker(functionName: "animate_main")
      worker.addBuffer(buffer: animationBuffer)
      worker.addBuffer(buffer: paramBuffer)
      worker.completionCallback = doneProcessing
    } catch let e {
      print("\(e)")
    }
  }
  
  var dt:Float = 0
  
  func doneProcessing(){
    for (k, i) in animationBuffer {
      k.setter(&animationBuffer.content![i].frame)
      if (!animationBuffer.content![i].running) {
        animationBuffer.remove(key: k)
        k.completion?()
      }
    }
  }
  
  func update() {
    dt += Float(displayLink.duration)
    if ( worker.processing ) { return }
    
    if animationBuffer.count == 0{
      displayLinkPaused = true
    } else {
      for (k, i) in animationBuffer {
        animationBuffer.content![i].frame = k.getter()
      }

      paramBuffer.content![0] = dt
      dt = 0
      worker.process(size: animationBuffer.capacity)
    }
  }
  
  open func animate<T:Hashable>(_ item:T,
                    key:String,
                    getter:@autoclosure @escaping () -> vector_float4,
                    setter:@escaping (inout vector_float4) -> Void,
                    target:vector_float4,
                    stiffness:Float = 150,
                    damping:Float = 10,
                    threshold:Float = 0.001,
                    completion:(() -> Void)? = nil) {
    let entry = GPUAnimationEntry(hashValue: item.hashValue + key.hashValue, getter:getter, setter:setter, completion:completion)
    animationBuffer.add(key: entry, value: GPUAnimationState(current: getter(), target: target, stiffness: stiffness, damping: damping, threshold: threshold))
    if displayLinkPaused{
      displayLinkPaused = false
    }
  }
  
  func start() {
    if !displayLinkPaused {
      return
    }
    displayLink = CADisplayLink(target: self, selector: #selector(update))
    displayLink.add(to: RunLoop.main, forMode: RunLoopMode(rawValue: RunLoopMode.commonModes.rawValue))
  }
  
  func stop() {
    if displayLinkPaused{
      return
    }
    displayLink.isPaused = true
    displayLink.remove(from: RunLoop.main, forMode: RunLoopMode(rawValue: RunLoopMode.commonModes.rawValue))
    displayLink = nil
  }
}




