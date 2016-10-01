//
//  GPUWorkerTest.swift
//  MetalLayoutTest
//
//  Created by Luke Zhao on 2016-09-28.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//
import MetalKit

class GPUWorkerTest {
  var worker:GPUWorker!
//  var computeBuffer = GPUBuffer<String, vector_float4>()
//  
//  init(){
//    do {
//      for i in 0..<10{
//        computeBuffer.add(key: "\(i)", value: vector_float4(Float(i),Float(i),Float(i),Float(i)))
//      }
//      worker = try GPUWorker(functionName: "compute_main")
//      worker.addBuffer(buffer: computeBuffer)
//      worker.completionCallback = doneProcessing
//    } catch let e {
//      print("\(e)")
//    }
//    
//    
//    for i in 0..<100000{
//      computeBuffer.add(key: "\(i)", value: vector_float4(Float(i),Float(i),Float(i),Float(i)))
//    }
//    var start = CACurrentMediaTime()
//    
//    for (_, i) in computeBuffer {
//      computeBuffer.content![i].x = 10
//    }
//    
//    print(CACurrentMediaTime() - start)
//    
////    worker.process(size: computeBuffer.capacity)
//  }
//  
//  func doneProcessing(){
//    print(computeBuffer.count)
//    for (k, result) in computeBuffer {
//      print(k, result)
//    }
//  }
}
