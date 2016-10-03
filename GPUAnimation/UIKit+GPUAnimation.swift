//
//  UIKit+GPUAnimation.swift
//  MetalLayoutTest
//
//  Created by Luke Zhao on 2016-09-28.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit
import MetalKit

extension Dictionary {
  subscript(key: Key, withDefault value: @autoclosure () -> Value) -> Value {
    mutating get {
      if self[key] == nil {
        self[key] = value()
      }
      return self[key]!
    }
    set {
      self[key] = newValue
    }
  }
}

extension CGFloat{
  func clamp(_ a:CGFloat, _ b:CGFloat) -> CGFloat{
    return self < a ? a : (self > b ? b : self)
  }
}
extension CGPoint{
  func translate(_ dx:CGFloat, dy:CGFloat) -> CGPoint{
    return CGPoint(x: self.x+dx, y: self.y+dy)
  }
  
  func transform(_ t:CGAffineTransform) -> CGPoint{
    return self.applying(t)
  }
  
  func distance(_ b:CGPoint)->CGFloat{
    return sqrt(pow(self.x-b.x,2)+pow(self.y-b.y,2));
  }
}
func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
func /(left: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: left.x/right, y: left.y/right)
}
func *(left: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: left.x*right, y: left.y*right)
}
func *(left: CGFloat, right: CGPoint) -> CGPoint {
  return right * left
}
func *(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x*right.x, y: left.y*right.y)
}
prefix func -(point:CGPoint) -> CGPoint {
  return CGPoint.zero - point
}
