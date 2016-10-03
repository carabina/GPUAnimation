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

public protocol VectorConvertable{
  var toVec4:vector_float4 { get }
  static func fromVec4(_ values: vector_float4) -> Self
}

extension CGFloat:VectorConvertable{
  public var toVec4:vector_float4 {
    return [Float(self), 0,0,0]
  }
  public static func fromVec4(_ values: vector_float4) -> CGFloat {
    return CGFloat(values[0])
  }
}

extension CGRect:VectorConvertable{
  public var toVec4:vector_float4 {
    return [Float(origin.x), Float(origin.y), Float(width), Float(height)]
  }
  public static func fromVec4(_ values: vector_float4) -> CGRect {
    return self.init(x: CGFloat(values.x), y: CGFloat(values.y), width: CGFloat(values.z), height: CGFloat(values.w))
  }
}

extension CGPoint:VectorConvertable{
  public var toVec4:vector_float4 {
    return [Float(x), Float(y), 0, 0]
  }
  public static func fromVec4(_ values: vector_float4) -> CGPoint {
    return self.init(x: CGFloat(values.x), y: CGFloat(values.y))
  }
}

extension CGSize:VectorConvertable{
  public var toVec4:vector_float4 {
    return [Float(width), Float(height), 0, 0]
  }
  public static func fromVec4(_ values: vector_float4) -> CGSize {
    return self.init(width: CGFloat(values.x), height: CGFloat(values.y))
  }
}

extension UIColor:VectorConvertable{
  public var toVec4:vector_float4 {
    var r : CGFloat = 0
    var g : CGFloat = 0
    var b : CGFloat = 0
    var a : CGFloat = 0
    self.getRed(&r, green: &g, blue: &b, alpha: &a)
    return [Float(r),Float(g),Float(b),Float(a)]
  }
  public static func fromVec4(_ values: vector_float4) -> Self {
    return self.init(red: CGFloat(values[0]), green: CGFloat(values[1]), blue: CGFloat(values[2]), alpha: CGFloat(values[3]))
  }
}
