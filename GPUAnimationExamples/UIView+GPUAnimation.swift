//
//  UIView+GPUAnimation.swift
//  MetalLayoutTest
//
//  Created by Luke Zhao on 2016-09-28.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit


var associationKey = "UIView+GPUAnimation"

public class GPUAnimationBuilder{
  weak var view:UIView?
  internal var animations:[String:(UIView, (()->Void)?) -> Void] = [:]
  init(view:UIView?) {
    self.view = view
  }
  
  var stiffness:Float = 150
  var damping:Float = 10
  var threshold:Float = 0.01
  
  lazy var _frame:CGRect = self.view?.frame ?? CGRect.zero
  var frame:CGRect {
    get {
      return _frame;
    }
    set {
      _frame = newValue
      animations["frame"] = { [unowned self] (v, completion) in
        GPUSpringAnimator.sharedInstance.animate(v,
                                                 key: "frame",
                                                 getter: v.frame.toVec4,
                                                 setter: { nv in
                                                  v.frame.fromVec4(nv)
                                                 },
                                                 target: newValue.toVec4,
                                                 stiffness: self.stiffness,
                                                 damping: self.damping,
                                                 threshold: self.threshold,
                                                 completion:completion)
      }
    }
  }
  
  lazy var _bounds:CGRect = self.view?.bounds ?? CGRect.zero
  var bounds:CGRect {
    get {
      return _bounds;
    }
    set {
      _bounds = newValue
      animations["bounds"] = { [unowned self] (v, completion) in
        GPUSpringAnimator.sharedInstance.animate(v,
                                                 key: "bounds",
                                                 getter: v.bounds.toVec4,
                                                 setter: { nv in
                                                  v.bounds.fromVec4(nv)
          },
                                                 target: newValue.toVec4,
                                                 stiffness: self.stiffness,
                                                 damping: self.damping,
                                                 threshold: self.threshold,
                                                 completion:completion)
      }
    }
  }
  
  lazy var _backgroundColor:UIColor = self.view?.backgroundColor ?? UIColor.white
  var backgroundColor:UIColor {
    get {
      return _backgroundColor;
    }
    set {
      _backgroundColor = newValue
      animations["backgroundColor"] = { [unowned self] (v, completion) in
        GPUSpringAnimator.sharedInstance.animate(v,
                                                 key: "backgroundColor",
                                                 getter: v.backgroundColor!.toVec4,
                                                 setter: { nv in
                                                  v.backgroundColor = UIColor.fromVec4(nv)
          },
                                                 target: newValue.toVec4,
                                                 stiffness: self.stiffness,
                                                 damping: self.damping,
                                                 threshold: self.threshold,
                                                 completion:completion)
      }
    }
  }
  
  lazy var _center:CGPoint = self.view?.center ?? CGPoint.zero
  var center:CGPoint {
    get {
      return _center;
    }
    set {
      _center = newValue
      animations["center"] = { [unowned self] (v, completion) in
        GPUSpringAnimator.sharedInstance.animate(v,
                                                 key: "center",
                                                 getter: v.center.toVec4,
                                                 setter: { nv in
                                                  v.center.fromVec4(nv)
          },
                                                 target: newValue.toVec4,
                                                 stiffness: self.stiffness,
                                                 damping: self.damping,
                                                 threshold: self.threshold,
                                                 completion:completion)
      }
    }
  }
}


class GPUAnimationGroup{
  var builders:[GPUAnimationBuilder] = []
  var completion:(()->())? = nil
  var delay:TimeInterval?
  var isEmpty:Bool {
    return builders.count == 0 && completion == nil && delay == nil
  }
}

public class GPUAnimationBuilderContainer{
  var running:Bool{
    get {
      let count = groups.count - (groups.last!.isEmpty ? 1 : 0)
      return currentRuningGroupIndex >= 0 && currentRuningGroupIndex < count
    }
  }
  
  private var executed = false
  unowned var view:UIView
  var groups:[GPUAnimationGroup] = [GPUAnimationGroup()]
  var dispatchGroup:DispatchGroup = DispatchGroup()
  var timer:Timer?
  var currentRuningGroupIndex = -1
  
  init(view:UIView){
    self.view = view
  }
  
  func clone() -> GPUAnimationBuilderContainer{
    let c = GPUAnimationBuilderContainer(view:view)
    c.groups = groups
    c.dispatchGroup = dispatchGroup
    c.timer = timer
    c.currentRuningGroupIndex = currentRuningGroupIndex
    return c
  }
  
  deinit{
    if !executed{
      // if we have never executed, create a clone and then execute the clone
      // we cannot execute from the current Container because it is deallocating
      clone().execute()
    }
  }
  
  private func advance() -> Bool{
    currentRuningGroupIndex += 1
    if (!running) {
      currentRuningGroupIndex = -1
      return false // should stop
    }
    return true // should continue
  }
  private func step() {
    guard running else { return }
    let g = groups[currentRuningGroupIndex]
    for b in g.builders{
      for (_, fn) in b.animations{
        self.dispatchGroup.enter()
        fn(view) {
          self.dispatchGroup.leave()
        }
      }
    }
    let completion:()->Void
    if let delay = g.delay, delay > 0{
      completion = {
        // g.completion?() might call execute again..
        // therefore need to record shouldStep to determine if the current cycle need to be continued
        // otherwise we might endup calling step twice
        // we also need to advance the counter before calling g.completion in order make execute callable
        let shouldStep = self.advance()
        g.completion?()
        if shouldStep {
          self.timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            self.step()
          }
        }
      }
    } else {
      completion = {
        // see explaination above
        let shouldStep = self.advance()
        g.completion?()
        if shouldStep { self.step() }
      }
    }
    dispatchGroup.notify(queue: DispatchQueue.main, execute:completion)
  }
  
  @discardableResult func execute() -> GPUAnimationBuilderContainer {
    stop()
    currentRuningGroupIndex = 0
    executed = true
    step()
    return self
  }
  
  @discardableResult func delay(_ time:CFTimeInterval) -> GPUAnimationBuilderContainer{
    groups.last!.delay = time
    groups.append(GPUAnimationGroup())
    return self
  }
  
  @discardableResult func stop() -> GPUAnimationBuilderContainer{
    guard running else { return self }
    timer?.invalidate()
    let g = groups[currentRuningGroupIndex]
    for b in g.builders{
      for (key, _) in b.animations{
        // remove current running animations
        GPUSpringAnimator.sharedInstance.remove(view, key: key)
      }
    }
    currentRuningGroupIndex = -1
    return self
  }
  
  @discardableResult func then(_ block:(() -> Void)? = nil) -> GPUAnimationBuilderContainer{
    groups.last!.completion = block
    groups.append(GPUAnimationGroup())
    return self
  }
  
  @discardableResult func animate(_ block:(GPUAnimationBuilder) -> Void) -> GPUAnimationBuilderContainer{
    let animationBuilder = GPUAnimationBuilder(view: self.view)
    groups.last!.builders.append(animationBuilder)
    block(animationBuilder)
    return self
  }
}

extension UIView{
  @discardableResult func delay(_ time:CFTimeInterval) -> GPUAnimationBuilderContainer{
    return GPUAnimationBuilderContainer(view: self).delay(time)
  }
  @discardableResult func animate(_ block:(GPUAnimationBuilder) -> Void) -> GPUAnimationBuilderContainer{
    return GPUAnimationBuilderContainer(view: self).animate(block)
  }
  func animateTo(frame:CGRect,
                  stiffness:Float = 150,
                  damping:Float = 10,
                  threshold:Float = 0.01){
    GPUSpringAnimator.sharedInstance.animate(self,
                                             key: "frame",
                                             getter: self.frame.toVec4,
                                             setter: { [unowned self] nv in
                                               self.frame.fromVec4(nv)
                                             },
                                             target: frame.toVec4,
                                             stiffness: stiffness,
                                             damping: damping,
                                             threshold: threshold)
  }
  
  func animateTo(bounds:CGRect,
                 stiffness:Float = 150,
                 damping:Float = 10,
                 threshold:Float = 0.01){
    GPUSpringAnimator.sharedInstance.animate(self,
                                             key: "bounds",
                                             getter: self.bounds.toVec4,
                                             setter: { [unowned self] nv in
                                               self.bounds.fromVec4(nv)
                                             },
                                             target: bounds.toVec4,
                                             stiffness: stiffness,
                                             damping: damping,
                                             threshold: threshold)
  }

  func animateTo(center:CGPoint,
               stiffness:Float = 150,
               damping:Float = 10,
               threshold:Float = 0.01){
    GPUSpringAnimator.sharedInstance.animate(self,
                                             key: "center",
                                             getter: self.center.toVec4,
                                             setter: { [unowned self] nv in
                                               self.center.fromVec4(nv)
                                             },
                                             target: center.toVec4,
                                             stiffness: stiffness,
                                             damping: damping,
                                             threshold: threshold)
  }
}
