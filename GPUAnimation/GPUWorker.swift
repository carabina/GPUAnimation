//
//  GPUWorker.swift
//  MetalLayoutTest
//
//  Created by YiLun Zhao on 2016-09-28.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import MetalKit


private class Shared {
  static var device: MTLDevice! = MTLCreateSystemDefaultDevice()
  static var queue: MTLCommandQueue! = device.makeCommandQueue()
  static var library: MTLLibrary! = device.newDefaultLibrary()
}

internal protocol GPUBufferType {
  var buffer: MTLBuffer? { get }
}

open class GPUBuffer<Key:Hashable, Value, MetaData>:Sequence, GPUBufferType {

  public func makeIterator() -> DictionaryIterator<Key, Int> {
    return managed.makeIterator()
  }
  public var content: UnsafeMutableBufferPointer<Value>? = nil
  
  internal var buffer: MTLBuffer? = nil
  internal var freeIndexes:[Int] = []
  private var managed:[Key:Int] = [:]
  private var metaData:[Key:MetaData] = [:]
  
  public var capacity:Int{
    return content?.count ?? 0
  }
  
  public var count:Int{
    return managed.count
  }
  
  public init(_ size:Int = 2){
    resize(size:size)
  }
  
  public func indexOf(key:Key) -> Int? {
    return managed[key]
  }

  public func remove(key:Key){
    if let i = managed[key] {
      managed[key] = nil
      metaData[key] = nil
      freeIndexes.append(i)
    }
  }
  
  public func add(key:Key, value:Value, meta:MetaData? = nil){
    if let i = managed[key] {
      metaData[key] = meta
      content![i] = value
    } else {
      if freeIndexes.count == 0 {
        resize(size: (content?.count ?? 1) * 2)
      }
      let i = freeIndexes.popLast()!
      managed[key] = i
      metaData[key] = meta
      content![i] = value
    }
  }
  
  public func metaDataFor(key:Key) -> MetaData?{
    return metaData[key]
  }

  public func resize(size:Int){
    let oldSize = capacity
    if (size <= oldSize) {
      return
    }
    if buffer != nil {
      let newBuffer: MTLBuffer = Shared.device.makeBuffer(length: MemoryLayout<Value>.size * size, options: [.storageModeShared])
      memcpy(newBuffer.contents(), buffer!.contents(), buffer!.length)
      buffer = newBuffer
    } else {
      buffer = Shared.device.makeBuffer(length: MemoryLayout<Value>.size * size, options: [.storageModeShared])
    }
    content = UnsafeMutableBufferPointer(start: buffer!.contents().assumingMemoryBound(to: Value.self), count: buffer!.length / MemoryLayout<Value>.size)
    for i in oldSize..<content!.count{
      freeIndexes.append(i)
    }
    print("GPU Animation buffer new size: \(content!.count)")
  }
}

open class GPUWorker {
  public enum GPUWorkerError: Error {
    case MetalNotAvaliable
    case FunctionDoesNotExist
  }
  let computeFn: MTLFunction
  let computePS: MTLComputePipelineState
  var buffers:[GPUBufferType] = []
  var completionCallback:(()->Void)?
  var threadExecutionWidth:Int = 32
  
  public init(functionName:String) throws {
    if Shared.device == nil {
      throw GPUWorkerError.MetalNotAvaliable
    }
    if let computeFn = Shared.library.makeFunction(name: functionName){
      self.computeFn = computeFn
    } else {
      throw GPUWorkerError.FunctionDoesNotExist
    }
    computePS = try Shared.device.makeComputePipelineState(function: computeFn)
    threadExecutionWidth = computePS.threadExecutionWidth
  }
  
  func addBuffer<K: Hashable,V,M>(buffer:GPUBuffer<K,V,M>){
    buffers.append(buffer)
  }
  
  func process(size:Int){
    let commandBuffer = Shared.queue.makeCommandBuffer()
    let computeCE = commandBuffer.makeComputeCommandEncoder()
    computeCE.setComputePipelineState(computePS)
    for (i, buffer) in buffers.enumerated() {
      computeCE.setBuffer(buffer.buffer, offset: 0, at: i)
    }
    
    computeCE.dispatchThreadgroups(MTLSize(width: (size+threadExecutionWidth-1)/threadExecutionWidth, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: threadExecutionWidth, height: 1, depth: 1))
    computeCE.endEncoding()
    commandBuffer.addCompletedHandler(self.doneProcessing)
    commandBuffer.commit()
  }
  
  func doneProcessing(buffer:MTLCommandBuffer){
    DispatchQueue.main.async {
      self.completionCallback?()
    }
  }
}
