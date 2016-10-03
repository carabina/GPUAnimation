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
//    square.delay(2).animate{
//      $0.alpha.target = 0
//      $0.alpha.onChange = { newAlpha in
//        print(newAlpha)
//      }
//    }.then.animate{
//      $0.damping = 50
//      $0.alpha.target = 1
//    }.animate{
//      $0.transform.rotate(by: Float(M_PI_2) )
//      $0.transform.scale(by: 2.0)
//    }.delay(2).animate{
//      $0.transform.resetToIdentity()
//    }
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
//    square.animate{
//      $0.threshold = 10
//      $0.stiffness = 300
//      $0.transform.translate(x: -20, y: 0, z: 0)
//    }.then.animate{
//      $0.threshold = 10
//      $0.stiffness = 300
//      $0.transform.resetToIdentity()
//      $0.transform.translate(x: 20, y: 0, z: 0)
//    }.then.animate{
//      $0.threshold = 10
//      $0.stiffness = 300
//      $0.transform.resetToIdentity()
//      $0.transform.translate(x: -15, y: 0, z: 0)
//    }.then.animate{
//      $0.threshold = 1
//      $0.stiffness = 300
//      $0.transform.resetToIdentity()
//    }
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
  
  func testAlloc(){
    for _ in 0...10000{
      square.animate { to in
        to.stiffness = 200
        to.bounds.target = CGRect(x: 0, y: 0, width: 300, height: 300)
      }.animate{ to in
        to.stiffness = 300
        to.center.target = CGPoint(x:200, y:400)
      }
    }
  }
  
  func test1(){
    square.animate { to in
      to.stiffness = 200
      to.bounds.target = CGRect(x: 0, y: 0, width: 300, height: 300)
    }.animate{ to in
      to.stiffness = 300
      to.center.target = CGPoint(x:200, y:400)
    }.then {
      print("First stage done")
    }.delay(2).animate{ to in
      to.bounds.target = CGRect(x: 0, y: 0, width: 100, height: 200)
      to.center.target = CGPoint(x:200, y:100)
      to.backgroundColor.target = UIColor.black
    }.then {
      print("Second stage done")
    }.animate{ to in
      to.stiffness = 200
      to.bounds.target = CGRect(x: 0, y: 0, width: 300, height: 300)
      to.center.target = CGPoint(x:200, y:400)
    }.animate{ to in
      to.damping = 40
      to.backgroundColor.target = UIColor.green
    }.then {
      print("test 1 finished!")
      self.test2()
    }
  }
  
  func test2(){
    let animation = square.animate{
      $0.stiffness = 20
      $0.bounds.target = CGRect(x: 0, y: 0, width: 50, height: 50)
    }.then{
      print("This line shouldn't be printed")
    }.execute()
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false){ timer in
      animation.stop()
      print("test 2 finished!")
      self.test3()
    }
  }
  
  func test3(){
    let animation = square.delay(2).animate{
      $0.stiffness = 20
      $0.bounds.target = CGRect(x: 0, y: 0, width: 50, height: 500)
    }.then{ print("This line shouldn't be printed") }.execute()
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false){ timer in
      print("test 3 finished!")
      animation.stop()
      self.test4()
    }
  }
  
  lazy var storedAnimation:UIViewAnimationBuilder = self.square.animate{
    $0.stiffness = 20
    $0.bounds.target = CGRect(x: 0, y: 0, width: 50, height: 500)
  }.then().animate{
    $0.stiffness = 20
    $0.bounds.target = CGRect(x: 0, y: 0, width: 50, height: 50)
  }.then{
    print("Stored animation finished")
    self.storedAnimation.execute()
  }
  func test4(){
    storedAnimation.execute()
  }
}

