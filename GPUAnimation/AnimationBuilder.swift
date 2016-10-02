//
//  AnimationBuilder.swift
//  GPUAnimationExamples
//
//  Created by YiLun Zhao on 2016-10-01.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MetalKit

var associationKey = "UIView+GPUAnimation"

public class AnimationTarget{
  unowned var view:UIView
  internal var animations:[String:(((Bool)->Void)?) -> Void] = [:]
  init(view:UIView) {
    self.view = view
    #if DEBUGMEMORY
      type(of: self).inited += 1
    #endif
  }
  
  #if DEBUGMEMORY
  static var inited = 0
  deinit{
    type(of: self).inited -= 1
  }
  #endif
  
  var stiffness:Float = 150
  var damping:Float = 10
  var threshold:Float = 0.01
  
  func custom(key:String,
              getter:@escaping () -> vector_float4,
              setter:@escaping (inout vector_float4) -> Void,
              target:vector_float4){
    animations[key] = { [key, view, threshold, stiffness, damping] (completion) in
      GPUSpringAnimator.sharedInstance.animate(view,
                                               key: key,
                                               getter: getter,
                                               setter: setter,
                                               target: target,
                                               stiffness: stiffness,
                                               damping: damping,
                                               threshold: threshold,
                                               completion: completion)
    }
  }
  
  private lazy var _frame:CGRect = self.view.frame
  var frame:CGRect {
    get { return _frame }
    set {
      _frame = newValue
      let v = self.view
      custom(key: "frame",
             getter: { return v.frame.toVec4 },
             setter: { nv in v.frame.fromVec4(nv) },
             target: newValue.toVec4)
    }
  }
  
  private lazy var _bounds:CGRect = self.view.bounds
  var bounds:CGRect {
    get { return _bounds }
    set {
      _bounds = newValue
      let v = self.view
      custom(key: "bounds",
             getter: { return v.bounds.toVec4 },
             setter: { nv in v.bounds.fromVec4(nv) },
             target: newValue.toVec4)
    }
  }
  
  private lazy var _backgroundColor:UIColor = self.view.backgroundColor ?? UIColor.white
  var backgroundColor:UIColor {
    get { return _backgroundColor }
    set {
      _backgroundColor = newValue
      let v = self.view
      custom(key: "backgroundColor",
             getter: { return v.backgroundColor!.toVec4 },
             setter: { nv in v.backgroundColor = UIColor.fromVec4(nv) },
             target: newValue.toVec4)
    }
  }
  
  private lazy var _center:CGPoint = self.view.center
  var center:CGPoint {
    get { return _center }
    set {
      _center = newValue
      let v = self.view
      custom(key: "center",
             getter: { return v.center.toVec4 },
             setter: { nv in v.center.fromVec4(nv) },
             target: newValue.toVec4)
    }
  }
}




internal enum AnimationGroup{
  case animation([(AnimationTarget)->Void]);
  case callback(()->());
  case delay(TimeInterval);
}

public class GPUAnimationBuilder{
  
  private var executed = false
  unowned var view:UIView
  private var groups:[AnimationGroup] = []
  var currentRunningAnimation:[String:(((Bool)->Void)?) -> Void] = [:]
  var timer:Timer?
  
  var running = false
  var currentRunningGroupIndex = 0{
    didSet{
      if currentRunningGroupIndex >= groups.count {
        running = false
      }
    }
  }
  
  init(view:UIView){
    self.view = view
    #if DEBUGMEMORY
      type(of: self).inited += 1
    #endif
  }
  
  func clone() -> GPUAnimationBuilder{
    let c = GPUAnimationBuilder(view:view)
    c.groups = groups
    return c
  }
  
  #if DEBUGMEMORY
  static var inited = 0
  #endif
  deinit{
    #if DEBUGMEMORY
      type(of: self).inited -= 1
    #endif
    if !executed{
      // if we have never executed, create a clone and then execute the clone
      // we cannot execute from the current Container because it is deallocating
      clone().execute()
    }
  }
  
  private func step() {
    currentRunningGroupIndex += 1
    currentRunningAnimation = [:]
    guard running else { return }
    
    switch groups[currentRunningGroupIndex] {
    case .callback(let cb):
      cb()
      if (currentRunningGroupIndex != 0) {
        self.step()
      }
    case .animation(let setupBlocks):
      for block in setupBlocks{
        let target = AnimationTarget(view: self.view)
        block(target)
        for (k, v) in target.animations{
          currentRunningAnimation[k] = v
        }
      }
      if currentRunningAnimation.count > 1{
        let dispatchGroup = DispatchGroup()
        var allFinished = true
        for fn in currentRunningAnimation.values{
          dispatchGroup.enter()
          fn { finished in
            if (!finished) {
              allFinished = false
            }
            dispatchGroup.leave()
          }
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
          self.running = allFinished
          self.step()
        }
      } else if currentRunningAnimation.count == 1{
        currentRunningAnimation.values.first!{ (allFinished) in
          self.running = allFinished
          self.step()
        }
      }
    case .delay(let time):
      self.timer = Timer.scheduledTimer(withTimeInterval: time, repeats: false) { timer in
        self.step()
      }
    }
  }
  
  @discardableResult func execute() -> GPUAnimationBuilder {
    stop()
    currentRunningGroupIndex = -1
    executed = true
    running = true
    step()
    return self
  }
  
  @discardableResult func delay(_ time:CFTimeInterval) -> GPUAnimationBuilder{
    groups.append(.delay(time))
    return self
  }
  
  @discardableResult func stop() -> GPUAnimationBuilder{
    guard running else { return self }
    running = false
    timer?.invalidate()
    for key in currentRunningAnimation.keys{
      GPUSpringAnimator.sharedInstance.remove(view, key: key)
    }
    return self
  }
  
  @discardableResult func then(_ block:(() -> Void)? = nil) -> GPUAnimationBuilder{
    if let block = block{
      groups.append(AnimationGroup.callback(block))
    } else {
      groups.append(AnimationGroup.animation([]))
    }
    return self
  }
  
  @discardableResult func animate(_ block:@escaping (AnimationTarget) -> Void) -> GPUAnimationBuilder{
    if let last = groups.last, case .animation(let animations) = last{
      groups.removeLast()
      groups.append(.animation(animations+[block]))
    } else {
      groups.append(.animation([block]))
    }
    return self
  }
}
