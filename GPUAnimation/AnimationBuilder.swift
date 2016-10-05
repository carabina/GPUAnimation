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

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#endif
import MetalKit

public struct TransformAnimatable{
  var target:CATransform3D{
    didSet{
      build()
    }
  }
  
  public mutating func rotate(by:CGFloat){
    rotate(x: 0, y: 0, z: by)
  }
  public mutating func rotate(x:CGFloat, y:CGFloat, z:CGFloat){
    var t = target
    t = CATransform3DRotate(t, x, 1.0, 0, 0)
    t = CATransform3DRotate(t, y, 0, 1.0, 0)
    t = CATransform3DRotate(t, z, 0, 0, 1.0)
    target = t
  }
  public mutating func scale(by:CGFloat){
    scale(x:by,y:by,z:0)
  }
  public mutating func scale(x:CGFloat, y:CGFloat, z:CGFloat){
    target = CATransform3DScale(target, x, y, z)
  }
  public mutating func translate(x:CGFloat, y:CGFloat, z:CGFloat){
    target = CATransform3DTranslate(target,  x, y, z)
  }
  
  
  public mutating func resetToIdentity(){
    target = CATransform3DIdentity
    target.m34 = 1.0 / -500;
  }

  private unowned var viewState:ViewAnimationState

  private func build(){
    #if os(macOS)
      guard let layer = self.viewState.view.layer else { return }
    #elseif os(iOS)
      let layer = self.viewState.view.layer
    #endif
    for i in 0..<4{
      viewState.custom(key: "transform\(i)",
        getter: { [layer] in return layer.transform[i] },
        setter: { [layer] nv in layer.transform[i] = nv },
        target: target[i])
    }
  }

  init(viewState:ViewAnimationState){
    self.viewState = viewState
    #if os(macOS)
      self.target = self.viewState.view.layer?.transform ?? CATransform3DIdentity
    #elseif os(iOS)
      self.target = self.viewState.view.layer.transform
    #endif
    self.target.m34 = 1.0 / -500;
  }
}
public struct Animatable<T:VectorConvertable>{
  public var target:T{
    didSet{
      build()
    }
  }
  public var onChange:((T)->Void)?{
    didSet{
      build()
    }
  }
  public var onVelocityChange:((T)->Void)?{
    didSet{
      build()
    }
  }
  private unowned var viewState:ViewAnimationState
  private var key:String
  
  private var getter:() -> T
  private var setter:(T) -> Void

  private func build(){
    let originalGetter = self.getter
    let originalSetter = self.setter
    let setter:((inout float4) -> Void)
    if onChange != nil && onVelocityChange != nil {
      setter = { [view = viewState.view, key, originalSetter, onChange, onVelocityChange] value in
        let v = T.fromVec4(value)
        let velocity = T.fromVec4(GPUSpringAnimator.sharedInstance.velocityFor(view, key:key))
        originalSetter(v)
        onChange!(v)
        onVelocityChange!(velocity)
      }
    } else if let onChange = onChange {
      setter = { [originalSetter, onChange] value in
        let v = T.fromVec4(value)
        originalSetter(v)
        onChange(v)
      }
    } else if let onVelocityChange = onVelocityChange {
      setter = { [view = viewState.view, key, originalSetter, onVelocityChange] value in
        let v = T.fromVec4(value)
        let velocity = T.fromVec4(GPUSpringAnimator.sharedInstance.velocityFor(view, key:key))
        originalSetter(v)
        onVelocityChange(velocity)
      }
    } else {
      setter = { [originalSetter] value in
        originalSetter(T.fromVec4(value))
      }
    }
    viewState.custom(key: key, getter: { return originalGetter().toVec4 }, setter: setter, target: target.toVec4)
  }

  init(viewState:ViewAnimationState,
       key:String,
       getter:@escaping () -> T,
       setter:@escaping (T) -> Void){
    self.target = getter()
    self.getter = getter
    self.setter = setter
    self.viewState = viewState
    self.key = key
  }
}

public class ViewAnimationState{
  internal var animations:[String:(((Bool)->Void)?) -> Void] = [:]
  #if os(macOS)
  unowned var view:NSView
  init(view:NSView) {
    self.view = view
  }
  #elseif os(iOS)
  unowned var view:UIView
  init(view:UIView) {
  self.view = view
  }
  #endif
  
  var layer:CALayer{
    #if os(macOS)
      return view.layer!
    #elseif os(iOS)
      return view.layer
    #endif
  }
  
  public var stiffness:Float = 200
  public var damping:Float = 10
  public var threshold:Float = 0.01
  
  public func custom(key:String,
              getter:@escaping () -> float4,
              setter:@escaping (inout float4) -> Void,
              target:float4){
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
  
  public lazy var frame:Animatable<CGRect> = Animatable<CGRect>(viewState:self,
                                                                key:"frame",
                                                                getter:{ [view = self.view] in return view.frame },
                                                                setter: { [view = self.view] in view.frame = $0})
  
  public lazy var bounds:Animatable<CGRect> = Animatable<CGRect>(viewState:self,
                                                                 key:"bounds",
                                                                 getter:{ [view = self.view] in return view.bounds },
                                                                 setter: { [view = self.view] in view.bounds = $0})
  
  public lazy var position:Animatable<CGPoint> = Animatable<CGPoint>(viewState: self,
                                                                     key: "position",
                                                                     getter:{ [view = self.view] in return view.frame.origin },
                                                                     setter: { [view = self.view] in view.frame.origin = $0})

  public lazy var center:Animatable<CGPoint> =
    Animatable<CGPoint>(viewState: self,
                        key: "center",
                        getter:{ [view = self.view] in return view.center },
                        setter: { [view = self.view] in view.center = $0})
  
  
  
  public lazy var shadowOffset:Animatable<CGSize> = Animatable<CGSize>(viewState: self,
                                                                       key: "shadowOffset",
                                                                       getter:{ [layer = self.layer] in return layer.shadowOffset },
                                                                       setter: { [layer = self.layer] in layer.shadowOffset = $0})
  
  public lazy var shadowOpacity:Animatable<CGFloat> = Animatable<CGFloat>(viewState: self,
                                                                          key: "shadowOpacity",
                                                                          getter:{ [layer = self.layer] in return CGFloat(layer.shadowOpacity) },
                                                                          setter: { [layer = self.layer] in layer.shadowOpacity = Float($0)})
  
  public lazy var shadowRadius:Animatable<CGFloat> = Animatable<CGFloat>(viewState: self,
                                                                         key: "shadowRadius",
                                                                         getter:{ [layer = self.layer] in return layer.shadowRadius },
                                                                         setter: { [layer = self.layer] in layer.shadowRadius = $0})
  
  public lazy var alpha:Animatable<Float> = Animatable<Float>(viewState: self,
                                                                  key: "alpha",
                                                                  getter:{ [layer = self.layer] in return layer.opacity },
                                                                  setter: { [layer = self.layer] in layer.opacity = $0})
  
  public lazy var transform:TransformAnimatable = TransformAnimatable(viewState: self)

#if os(macOS)
  
  public lazy var backgroundColor:Animatable<NSColor> =
    Animatable<NSColor>(viewState:self,
                        key:"backgroundColor",
                        getter:{ [layer = self.layer] in
                          if let bc = layer.backgroundColor{
                            return NSColor(cgColor:bc)!
                          }
                          return NSColor.clear
                        },
                        setter: { [layer = self.layer] in layer.backgroundColor = $0.cgColor })

  public lazy var shadowColor:Animatable<NSColor> =
    Animatable<NSColor>(viewState:self,
                        key:"shadowColor",
                        getter:{ [layer = self.layer] in
                          if let bc = layer.shadowColor{
                            return NSColor(cgColor:bc)!
                          }
                          return NSColor.clear
                        },
                        setter: { [layer = self.layer] in layer.shadowColor = $0.cgColor })
  
#elseif os(iOS)

  public lazy var backgroundColor:Animatable<UIColor> = Animatable<UIColor>(viewState:self,
  key:"backgroundColor",
  getter:{ [view = self.view] in return view.backgroundColor! },
  setter: { [view = self.view] in view.backgroundColor = $0})
  
  public lazy var shadowColor:Animatable<UIColor> = Animatable<UIColor>(viewState:self,
  key:"shadowColor",
  getter:{ [view = self.view] in return UIColor(cgColor:view.layer.shadowColor!) },
  setter: { [view = self.view] in view.layer.shadowColor = $0.cgColor })

#endif
}




internal enum ViewAnimationGroup{
  case animation([(ViewAnimationState)->Void]);
  case callback(()->());
  case delay(TimeInterval);
}

public class ViewAnimationBuilder{
  #if os(macOS)
  unowned var view:NSView
  init(view:NSView) {
    self.view = view
  }
  #elseif os(iOS)
  unowned var view:UIView
  init(view:UIView) {
  self.view = view
  }
  #endif
  
  private var executed = false
  private var groups:[ViewAnimationGroup] = []
  private var currentRunningAnimation:[String:(((Bool)->Void)?) -> Void] = [:]
  private var timer:Timer?
  
  private(set) public var running = false
  private var currentRunningGroupIndex = 0{
    didSet{
      if currentRunningGroupIndex >= groups.count {
        running = false
      }
    }
  }
  
  private func clone() -> ViewAnimationBuilder{
    let c = ViewAnimationBuilder(view:view)
    c.groups = groups
    return c
  }
  
  deinit{
    if !executed{
      // if we have never executed, create a clone and then execute the clone
      // we cannot execute from the current Container because it is deallocating
      clone().execute()
    }
  }
  
  @objc private func step() {
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
        let target = ViewAnimationState(view: self.view)
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
      self.timer = Timer.scheduledTimer(timeInterval: time,
                                        target: self,
                                        selector: #selector(self.step),
                                        userInfo: nil,
                                        repeats: false)
    }
  }
  
  @discardableResult public func execute() -> ViewAnimationBuilder {
    //    stop()
    executed = true
    #if os(macOS)
      if view.layer == nil{
        print("GPU Animated view must be layer backed")
        return self
      }
    #endif
    currentRunningGroupIndex = -1
    running = true
    step()
    return self
  }
  
  @discardableResult public func delay(_ time:CFTimeInterval) -> ViewAnimationBuilder{
    groups.append(.delay(time))
    return self
  }
  
  @discardableResult public func stop() -> ViewAnimationBuilder{
    guard running else { return self }
    running = false
    timer?.invalidate()
    for key in currentRunningAnimation.keys{
      GPUSpringAnimator.sharedInstance.remove(view, key: key)
    }
    return self
  }
  
  public var then:ViewAnimationBuilder{
    groups.append(ViewAnimationGroup.animation([]))
    return self
  }

  @discardableResult public func then(_ block:(() -> Void)? = nil) -> ViewAnimationBuilder{
    if let block = block{
      groups.append(ViewAnimationGroup.callback(block))
      return self
    }
    return then
  }
  
  @discardableResult public func animate(_ block:@escaping (ViewAnimationState) -> Void) -> ViewAnimationBuilder{
    if let last = groups.last, case .animation(let animations) = last{
      groups.removeLast()
      groups.append(.animation(animations+[block]))
    } else {
      groups.append(.animation([block]))
    }
    return self
  }
}
