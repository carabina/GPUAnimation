//
//  UIView+GPUAnimation.swift
//  MetalLayoutTest
//
//  Created by Luke Zhao on 2016-09-28.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit

extension UIView{
  @discardableResult func delay(_ time:CFTimeInterval) -> GPUAnimationBuilder{
    return GPUAnimationBuilder(view: self).delay(time)
  }
  @discardableResult func animate(_ block:@escaping (AnimationTarget) -> Void) -> GPUAnimationBuilder{
    return GPUAnimationBuilder(view: self).animate(block)
  }
}
