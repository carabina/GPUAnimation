//
//  ExamplesViewController.swift
//  GPUAnimationExamples
//
//  Created by YiLun Zhao on 2016-09-27.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit

let π = CGFloat(M_PI)
class ExamplesViewController: UIViewController {
  @IBOutlet weak var square: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    square.layer.cornerRadius = 8
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    
    square.addGestureRecognizer(LZPanGestureRecognizer(target: self, action: #selector(pan)))
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    let dTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
    dTap.numberOfTapsRequired = 2
    view.addGestureRecognizer(dTap)
    
    square.layer.shadowColor = square.backgroundColor?.cgColor
    square.layer.shadowRadius = 30
    square.layer.shadowOpacity = 0
  }
  
  var isBig = false
  func doubleTap(_ gr:UITapGestureRecognizer){
    let newSize = isBig ? CGSize(width: 100, height: 100) : CGSize(width: 200, height: 200)
    isBig = !isBig
    square.animate {
      $0.bounds.target = CGRect(origin: CGPoint.zero, size: newSize)
    }
  }
  
  func onSquareVelocityChanged(velocity:CGPoint){
    let maxRotate = π/3
    let rotateX = -(velocity.y/1000).clamp(-maxRotate,maxRotate)
    let rotateY = (velocity.x/1000).clamp(-maxRotate,maxRotate)
    
    self.square.animate{
      $0.transform.resetToIdentity()
      $0.transform.rotate(x: rotateX, y: rotateY, z: 0)
      $0.alpha.target = 1 - max(abs(rotateY),abs(rotateX)) / π * 2
      $0.shadowOffset.target = CGSize(width: rotateY*20, height:-rotateX*20)
    }
  }
  
  func tap(_ gr:UITapGestureRecognizer){
    let loc = gr.location(in: view)
    square.animate{
      $0.center.target = loc
      $0.center.onVelocityChange = self.onSquareVelocityChanged
    }
  }
  
  func pan(_ gr:LZPanGestureRecognizer){
    square.animate{
      // high stiffness -> high acceleration (will help it stay under touch)
      $0.stiffness = 700
      $0.damping = 25
      $0.center.target = gr.translatedViewCenterPoint
      $0.center.onVelocityChange = self.onSquareVelocityChanged
    }
  }
}

