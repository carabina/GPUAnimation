//
//  BouncyView.swift
//  GPUAnimationExamples
//
//  Created by YiLun Zhao on 2016-10-03.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

class BouncyView:UIView{
  
  var scale:CGFloat = 1.0{
    didSet{
      
    }
  }
  var xyRotationByTouch:CGPoint = CGPoint(){
    didSet{
      
    }
  }

//  open fileprivate(set) var holding = false
//  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//    super.touchesBegan(touches, with: event)
//    if let touch = touches.first{
//      var loc = touch.location(in: self)
//      loc = CGPoint(x: loc.x.clamp(0, bounds.width), y: loc.y.clamp(0, bounds.height))
//      loc = loc - bounds.center
//      let rotation = CGPoint(x: -loc.y / bounds.height, y: loc.x / bounds.width)
//      
//      let force = touch.maximumPossibleForce == 0 ? 1 : touch.force
//      self.m_animate("scale", to: 0.95 - force*0.01, stiffness: 150, damping: 7)
//      self.m_animate("xyRotation", to: rotation * (0.21 + force * 0.04), stiffness: 150, damping: 7)
//    }
//    holding = true
//  }
//  open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//    super.touchesMoved(touches, with: event)
//    if let touch = touches.first {
//      var loc = touch.location(in: self)
//      loc = CGPoint(x: loc.x.clamp(0, bounds.width), y: loc.y.clamp(0, bounds.height))
//      loc = loc - bounds.center
//      let rotation = CGPoint(x: -loc.y / bounds.height, y: loc.x / bounds.width)
//      let force = touch.maximumPossibleForce == 0 ? 1 : touch.force
//      self.m_animate("scale", to: 0.95 - force * 0.01, stiffness: 150, damping: 7)
//      self.m_animate("xyRotation", to: rotation * (0.21 + force * 0.04), stiffness: 150, damping: 7)
//    }
//  }
//  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//    super.touchesEnded(touches, with: event)
//    self.m_animate("scale", to: 1.0, stiffness: 150, damping: 7)
//    self.m_animate("xyRotation", to: CGPoint.zero, stiffness: 150, damping: 7)
//    holding = false
//  }
//  open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
//    super.touchesCancelled(touches!, with: event)
//    self.m_animate("scale", to: 1.0, stiffness: 150, damping: 7)
//    self.m_animate("xyRotation", to: CGPoint.zero, stiffness: 150, damping: 7)
//    holding = false
//  }
}
