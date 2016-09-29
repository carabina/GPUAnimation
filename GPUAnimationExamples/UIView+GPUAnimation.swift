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
  var view:UIView
  init(view:UIView) {
    self.view = view
  }
  func wait(_ time:Float){
    view.animate.moveTo(x: 100, y: 200).rotate(5)
  }
  func rotate(_ z:Float, x:Float = 0, y:Float = 0){
    
  }
  func moveTo(x:Float, y:Float) -> Self{
    return self
  }
  func sizeTo(width:Float, height:Float){
    
  }
}

extension UIView{
  
  public var animate: GPUAnimationBuilder {
    get {
      if let instance = objc_getAssociatedObject(self, &associationKey) as? GPUAnimationBuilder {
        return instance
      }
      let instance = GPUAnimationBuilder(view: self)
      objc_setAssociatedObject(self, &associationKey, instance, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return instance
    }
  }
  
  func animateTo(frame:CGRect,
                  stiffness:Float = 150,
                  damping:Float = 10,
                  threshold:Float = 0.001){
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
                 threshold:Float = 0.001){
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
               threshold:Float = 0.001){
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
