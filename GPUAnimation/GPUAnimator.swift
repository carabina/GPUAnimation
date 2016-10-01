//
//  GPUAnimator.swift
//  MetalLayoutTest
//
//  Created by YiLun Zhao on 2016-09-27.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit
import MetalKit



fileprivate struct GPUAnimationState{
  // do not change the order of these variables
  // this struct is shared in Metal shader
  var frame: vector_float4 = vector_float4()
  var target: vector_float4
  var velocity: vector_float4 = vector_float4()
  var threshold: Float
  var stiffness: Float
  var damping: Float
  var running: Int32 = 1

  init(current c:vector_float4, target t: vector_float4, stiffness s:Float = 150, damping d:Float = 10, threshold th:Float = 0.01) {
    frame = c
    target = t
    threshold = th
    stiffness = s
    damping = d
  }
}

public typealias GPUAnimationGetter = () -> vector_float4
public typealias GPUAnimationSetter = (inout vector_float4) -> Void

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
  
  private var displayLink : CADisplayLink!
  private var worker:GPUWorker!
  private var animationBuffer = GPUBuffer<Int, GPUAnimationState, GPUAnimationMetaData>()
  private var paramBuffer = GPUBuffer<String, Float, Any>(1)
  private var queuedCommands = [()->()]()
  private var dt:Float = 0
  private var processing = false
  
  private override init(){
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
  
  @objc private func update() {
    dt += Float(displayLink.duration)
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
  
  open func remove<T:Hashable>(_ item:T, key:String){
    let animationKey = item.hashValue + key.hashValue
    let removeFn = {
      self.animationBuffer.metaDataFor(key: animationKey)?.completion?(false)
      self.animationBuffer.remove(key: animationKey)
    }
    if processing {
      queuedCommands.append(removeFn)
    } else {
      removeFn()
    }
  }
  
  open func animate<T:Hashable>(_ item:T,
                    key:String,
                    getter:@escaping () -> vector_float4,
                    setter:@escaping (inout vector_float4) -> Void,
                    target:vector_float4,
                    stiffness:Float = 150,
                    damping:Float = 10,
                    threshold:Float = 0.01,
                    completion:((Bool) -> Void)? = nil) {
    let animationKey = item.hashValue + key.hashValue
    let metaData = GPUAnimationMetaData(getter:getter, setter:setter, completion:completion)
    let state = GPUAnimationState(current: getter(), target: target, stiffness: stiffness, damping: damping, threshold: threshold)
    let insertFn = {
      self.animationBuffer.metaDataFor(key: animationKey)?.completion?(false)
      self.animationBuffer.add(key: animationKey, value: state, meta:metaData)
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
  
  private func start() {
    if !displayLinkPaused {
      return
    }
    displayLink = CADisplayLink(target: self, selector: #selector(update))
    displayLink.add(to: RunLoop.main, forMode: RunLoopMode(rawValue: RunLoopMode.commonModes.rawValue))
  }
  
  private func stop() {
    if displayLinkPaused{
      return
    }
    displayLink.isPaused = true
    displayLink.remove(from: RunLoop.main, forMode: RunLoopMode(rawValue: RunLoopMode.commonModes.rawValue))
    displayLink = nil
  }
}




