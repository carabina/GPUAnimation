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
  var locked: Bool { get set }
}

open class GPUBuffer<Key:Hashable, Value>:Sequence, GPUBufferType {

  public func makeIterator() -> DictionaryIterator<Key, Int> {
    return managed.makeIterator()
  }
  
  public var managed:[Key:Int] = [:]
  
  public var content: UnsafeMutableBufferPointer<Value>? = nil
  
  internal var buffer: MTLBuffer? = nil
  internal var freeIndexes:[Int] = []
  internal var toBeSet:[Key:Value] = [:]
  internal var toBeRemoved = Set<Key>()
  
  public var capacity:Int{
    return content?.count ?? 0
  }
  
  public var count:Int{
    return managed.count
  }
  
  internal var locked:Bool = false{
    didSet{
      if locked{
        // GPU will start processing this buffer. process all queued objects
        for k in toBeRemoved{
          unset(k)
        }
        
        for (k, v) in toBeSet{
          set(k, to: v)
        }
      }
    }
  }
  
  public init(_ size:Int = 2){
    resize(size:size)
  }
  
  public func remove(key:Key){
    if locked {
      toBeSet[key] = nil
      toBeRemoved.insert(key)
    } else {
      unset(key)
    }
  }
  
  public func add(key:Key, value:Value){
    if locked {
      toBeSet[key] = value
      toBeRemoved.remove(key)
    } else {
      set(key, to: value)
    }
  }
  
  private func unset(_ key:Key){
    toBeRemoved.remove(key)
    if let i = managed[key] {
      toBeSet.removeValue(forKey: key)
      managed.removeValue(forKey: key)
      freeIndexes.append(i)
    }
  }
  
  private func set(_ key:Key, to value:Value){
    toBeSet.removeValue(forKey: key)
    if let i = managed[key] {
      content![i] = value
    } else {
      if freeIndexes.count == 0 {
        resize(size: (content?.count ?? 1) * 2)
      }
      let i = freeIndexes.popLast()!
      managed[key] = i
      content![i] = value
    }
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
    print(Shared.device.maxThreadsPerThreadgroup)
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
  
  func addBuffer<K: Hashable,V>(buffer:GPUBuffer<K,V>){
    buffers.append(buffer)
  }
  
  var processing = false
  func process(size:Int){
    guard processing == false else { return }
    processing = true
    let commandBuffer = Shared.queue.makeCommandBuffer()
    let computeCE = commandBuffer.makeComputeCommandEncoder()
    computeCE.setComputePipelineState(computePS)
    for (i, buffer) in buffers.enumerated() {
      buffers[i].locked = true
      computeCE.setBuffer(buffer.buffer, offset: 0, at: i)
    }
    
    computeCE.dispatchThreadgroups(MTLSize(width: (size+threadExecutionWidth-1)/threadExecutionWidth, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: threadExecutionWidth, height: 1, depth: 1))
    computeCE.endEncoding()
    commandBuffer.addCompletedHandler { (_) in
      DispatchQueue.main.async(execute:self.doneProcessing)
    }
    commandBuffer.commit()
  }
  
  func doneProcessing(){
    processing = false
    for (i, _) in buffers.enumerated() {
      buffers[i].locked = false
    }
    completionCallback?()
  }
}