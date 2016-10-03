//
//  VectorConvertable.swift
//  
//
//  Created by YiLun Zhao on 2016-10-03.
//
//

import UIKit
import MetalKit


extension CATransform3D{
  public subscript(index: Int) -> float4{
    get {
      switch index{
      case 0:
        return float4(Float(m11),Float(m12),Float(m13),Float(m14))
      case 1:
        return float4(Float(m21),Float(m22),Float(m23),Float(m24))
      case 2:
        return float4(Float(m31),Float(m32),Float(m33),Float(m34))
      case 3:
        return float4(Float(m41),Float(m42),Float(m43),Float(m44))
      default:
        return float4()
      }
    }
    set {
      switch index{
      case 0:
        self.m11 = CGFloat(newValue.x)
        self.m12 = CGFloat(newValue.y)
        self.m13 = CGFloat(newValue.z)
        self.m14 = CGFloat(newValue.w)
      case 1:
        self.m21 = CGFloat(newValue.x)
        self.m22 = CGFloat(newValue.y)
        self.m23 = CGFloat(newValue.z)
        self.m24 = CGFloat(newValue.w)
      case 2:
        self.m31 = CGFloat(newValue.x)
        self.m32 = CGFloat(newValue.y)
        self.m33 = CGFloat(newValue.z)
        self.m34 = CGFloat(newValue.w)
      case 3:
        self.m41 = CGFloat(newValue.x)
        self.m42 = CGFloat(newValue.y)
        self.m43 = CGFloat(newValue.z)
        self.m44 = CGFloat(newValue.w)
      default:
        break
      }
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
