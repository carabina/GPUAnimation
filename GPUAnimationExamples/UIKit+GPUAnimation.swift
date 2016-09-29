//
//  UIKit+GPUAnimation.swift
//  MetalLayoutTest
//
//  Created by Luke Zhao on 2016-09-28.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit
import MetalKit

public protocol GPUAnimatable{
  var toVec4:vector_float4 { get }
  mutating func fromVec4(_:vector_float4)
}

extension CGRect:GPUAnimatable{
  public var toVec4:vector_float4 {
    return [Float(origin.x), Float(origin.y), Float(width), Float(height)]
  }
  public mutating func fromVec4(_ vec4: vector_float4) {
    origin.fromVec4(vec4)
    size.fromVec4(vec4)
  }
}

extension CGPoint:GPUAnimatable{
  public var toVec4:vector_float4 {
    return [Float(x), Float(y), 0, 0]
  }
  public mutating func fromVec4(_ vec4: vector_float4) {
    x = CGFloat(vec4.x)
    y = CGFloat(vec4.y)
  }
}

extension CGSize:GPUAnimatable{
  public var toVec4:vector_float4 {
    return [0, 0, Float(width), Float(height)]
  }
  public mutating func fromVec4(_ vec4: vector_float4) {
    width = CGFloat(vec4.z)
    height = CGFloat(vec4.w)
  }
}

