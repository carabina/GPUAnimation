// The MIT License (MIT)
//
// Copyright (c) 2015 Luke Zhao <me@lkzhao.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import MetalKit


private class Shared {
  static var device: MTLDevice! = MTLCreateSystemDefaultDevice()
  static var queue: MTLCommandQueue! = device?.makeCommandQueue()
  static var metalAvaliable:Bool{
    return library != nil
  }
  static var library: MTLLibrary! = {
    if let device = device, let path = Bundle(for:Shared.self).path(forResource: "default", ofType: "metallib"){
      return try? device.makeLibrary(filepath: path)
    }
    return nil
  }()
}

public protocol GPUBufferType {
  var buffer: MTLBuffer? { get }
}

open class GPUBuffer<Key:Hashable, Value, MetaData>:Sequence, GPUBufferType {

  public func makeIterator() -> DictionaryIterator<Key, Int> {
    return managed.makeIterator()
  }

  public var content: UnsafeMutableBufferPointer<Value>? = nil
  public var buffer: MTLBuffer? = nil

  private var freeIndexes:[Int] = []
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
  
  public func clear(){
    content = nil
    buffer = nil
    freeIndexes = []
    managed = [:]
    metaData = [:]
  }

  public func resize(size:Int){
    let oldSize = capacity
    if Shared.metalAvaliable {
      let newBuffer: MTLBuffer = Shared.device.makeBuffer(length: MemoryLayout<Value>.size * size, options: [.storageModeShared])
      if buffer != nil {
        memcpy(newBuffer.contents(), buffer!.contents(), Swift.min(size * MemoryLayout<Value>.size, buffer!.length))
      }
      buffer = newBuffer
      content = UnsafeMutableBufferPointer(start: buffer!.contents().assumingMemoryBound(to: Value.self), count: buffer!.length / MemoryLayout<Value>.size)
    } else {
      let newLoc = UnsafeMutablePointer<Value>.allocate(capacity: size)
      if content != nil {
        memcpy(newLoc, content!.baseAddress, content!.count * MemoryLayout<Value>.size)
        content!.baseAddress!.deinitialize(count: content!.count)
        content!.baseAddress!.deallocate(capacity: content!.count)
      }
      content = UnsafeMutableBufferPointer(start: newLoc, count: size)
    }
    
    for i in oldSize..<content!.count{
      freeIndexes.append(i)
    }
  }
}

open class GPUWorker {
  var computeFn: MTLFunction?
  var computePS: MTLComputePipelineState?
  var buffers:[GPUBufferType] = []
  var threadExecutionWidth:Int = 32
  public var completionCallback:(()->Void)?
  public var fallbackFunction:(()->Void)?
  
  public init(functionName:String, fallback:(()->Void)? = nil) {
    self.fallbackFunction = fallback
    if Shared.metalAvaliable {
      computeFn = Shared.library.makeFunction(name: functionName)
      computePS = try? Shared.device.makeComputePipelineState(function: computeFn!)
      threadExecutionWidth = computePS!.threadExecutionWidth
    } else {
      print("GPUAnimation: Metal Not Avaliable, using fallback function for \(functionName)")
    }
  }
  
  public func addBuffer<K: Hashable,V,M>(buffer:GPUBuffer<K,V,M>){
    buffers.append(buffer)
  }
  
  public func process(size:Int){
    if let computePS = computePS{
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
    } else {
      fallbackFunction?()
      completionCallback?()
    }
  }
  
  private func doneProcessing(buffer:MTLCommandBuffer){
    DispatchQueue.main.async {
      self.completionCallback?()
    }
  }
}
