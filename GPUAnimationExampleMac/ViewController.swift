//
//  ViewController.swift
//  GPUAnimationExampleMac
//
//  Created by YiLun Zhao on 2016-10-04.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

  @IBOutlet weak var square: NSView!
  override func viewDidLoad() {
    super.viewDidLoad()
    square.wantsLayer = true
    view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(tap)))
  }
  
  override func viewWillAppear() {
    square.layer!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    square.layer!.backgroundColor = NSColor.blue.cgColor
    square.animate{
      $0.frame.target =  CGRect(x: 300, y: 50, width:100, height:100)
      $0.backgroundColor.target = NSColor.black
    }
  }

  func tap(_ gr:NSClickGestureRecognizer){
    let loc = gr.location(in: view)
    square.animate{
      $0.center.target = loc
    }
  }
}

