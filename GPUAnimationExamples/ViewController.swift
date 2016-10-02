//
//  ViewController.swift
//  MetalLayoutTest
//
//  Created by YiLun Zhao on 2016-09-27.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit
import pop
import MotionAnimation

enum AnimationLibrary{
  case GPU;
  case POP;
  case Motion;
}

class ViewController: UIViewController {
  
  var countLabel: UILabel!
  var testViews:[UIView] = []
  var step = 0
  var timer:Timer?
  var stopGenerating = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.black
    countLabel = UILabel(frame: CGRect(x: 10, y: 30, width: 200, height: 40))
    countLabel.textColor = UIColor.white
    view.addSubview(countLabel)
    countLabel.layer.zPosition = 100
    
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    
//    countLabel.text = "Hello World"
//    animator.animate(view: countLabel, to: CGRect(x: 300, y: 30, width: 200, height: 40))
    
    let library = AnimationLibrary.GPU
    
    timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (_) in
      self.step += 1
      let height = self.view.frame.height
      let width = self.view.frame.width
      if (self.step % 10 != 0) {
        if (self.stopGenerating) { return }
        let k = UIView(frame: CGRect(x: CGFloat.random(lower: 50, width-50),
                                     y: CGFloat.random(lower: 50, height-50),
                                     width: 0,
                                     height: 0))
        k.translatesAutoresizingMaskIntoConstraints = false
        k.layer.cornerRadius = 10
        k.backgroundColor = UIColor(red: CGFloat.random(), green: CGFloat.random(), blue: CGFloat.random(), alpha: 1.0)
        self.view.addSubview(k)
        self.testViews.append(k)
        if library == .POP{
          let anim = POPSpringAnimation(propertyNamed: kPOPViewBounds)
          anim?.toValue = NSValue(cgRect:CGRect(x: 0,
                                              y: 0,
                                              width: CGFloat.random(lower: 100, 200),
                                              height: CGFloat.random(lower: 100, 200)))
          k.pop_add(anim, forKey: "size")
        } else if library == .Motion {
          k.m_animate("bounds", to: CGRect(x: 0,
                                           y: 0,
                                           width: CGFloat.random(lower: 100, 200),
                                           height: CGFloat.random(lower: 100, 200)),
                      stiffness: CGFloat.random(lower: 100, 300),
                      damping: CGFloat.random(lower: 100, 300))
        } else {
          k.animate{
            $0.stiffness = Float.random(lower: 100, 300)
            $0.damping = Float.random(lower: 5, 50)
            $0.bounds = CGRect(x: 0,
                               y: 0,
                               width: CGFloat.random(lower: 100, 200),
                               height: CGFloat.random(lower: 100, 200))
          }
        }
        self.countLabel.text = "\(self.view.subviews.count) Subviews"
      } else {
        for k in self.testViews {
          if library == .POP{
            if let anim = k.pop_animation(forKey: "size") as? POPSpringAnimation{
              anim.toValue = NSValue(cgRect:CGRect(x: 0,
                                                    y: 0,
                                                    width: CGFloat.random(lower: 100, 200),
                                                    height: CGFloat.random(lower: 100, 200)))
            } else {
              let anim = POPSpringAnimation(propertyNamed: kPOPViewBounds)!
              anim.springBounciness = CGFloat.random(lower: 0, 20)
              anim.springSpeed = CGFloat.random(lower: 0, 20)
              anim.toValue = NSValue(cgRect:CGRect(x: 0,
                                                    y: 0,
                                                    width: CGFloat.random(lower: 100, 200),
                                                    height: CGFloat.random(lower: 100, 200)))
              k.pop_add(anim, forKey: "size")
            }
            
            if let anim = k.pop_animation(forKey: "center") as? POPSpringAnimation{
              anim.toValue = NSValue(cgPoint:CGPoint(x: CGFloat.random(lower: 50, width-50),
                                                      y: CGFloat.random(lower: 50, height-50)))
            } else {
              let anim = POPSpringAnimation(propertyNamed: kPOPViewCenter)!
              anim.springBounciness = CGFloat.random(lower: 0, 20)
              anim.springSpeed = CGFloat.random(lower: 0, 20)
              anim.toValue = NSValue(cgPoint:CGPoint(x: CGFloat.random(lower: 50, width-50),
                                                      y: CGFloat.random(lower: 50, height-50)))
              k.pop_add(anim, forKey: "center")
            }
          } else if library == .Motion {
            k.m_animate("center", to: CGPoint(x: CGFloat.random(lower: 50, width-50),
                                        y: CGFloat.random(lower: 50, height-50)),
                        stiffness:CGFloat.random(lower: 100, 300),
                        damping:CGFloat.random(lower: 5, 50))
            k.m_animate("bounds", to: CGRect(x: 0,
                                       y: 0,
                                       width: CGFloat.random(lower: 100, 200),
                                       height: CGFloat.random(lower: 100, 200)),
                        stiffness:CGFloat.random(lower: 100, 300),
                        damping:CGFloat.random(lower: 5, 50))
          } else {
            k.animate {
              $0.stiffness = Float.random(lower: 100, 300)
              $0.damping = Float.random(lower: 5, 50)
              $0.center = CGPoint(x: CGFloat.random(lower: 50, width-50),
                                  y: CGFloat.random(lower: 50, height-50))
              $0.bounds = CGRect(x: 0,
                                 y: 0,
                                 width: CGFloat.random(lower: 100, 200),
                                 height: CGFloat.random(lower: 100, 200))
            }
//            self.animator.animate(k, key: "center", getter: { return k.center.toVec4 }, setter: { nv in k.center.fromVec4(nv) }, target: CGPoint(x: CGFloat.random(lower: 50, width-50), y: CGFloat.random(lower: 50, height-50)).toVec4)
          }
        }
      }
    }
  }

  func tap(_ gr:UITapGestureRecognizer){
//    let loc = gr.location(in: view)
    stopGenerating = !stopGenerating
  }
}

