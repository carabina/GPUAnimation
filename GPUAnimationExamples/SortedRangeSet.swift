//
//  SortedRangeSet.swift
//  GPUAnimationExamples
//
//  Created by Luke Zhao on 2016-09-28.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//


class SortedRangeSet{
  var ranges:[CountableRange<Int>] = []
  var free = 0
  var capacity = 0
  func reserve(size:Int) -> CountableRange<Int>?{
    for (i, r) in ranges.enumerated(){
      if r.count >= size{
        let rtn = r.startIndex..<r.startIndex+size
        if r.count == size{
          ranges.remove(at: i)
        } else {
          ranges[i] = (r.startIndex + size)..<r.endIndex
        }
        free -= size
        return rtn
      }
    }
    return nil
  }
  func release(range:CountableRange<Int>){
    var insertFn = { self.ranges.append(range) }
    for (i, r) in ranges.enumerated(){
      if (range.overlaps(r)) {
        insertFn = { self.ranges[i] = range.startIndex..<r.endIndex }
        break
      } else if range.endIndex <= r.startIndex {
        insertFn = { self.ranges.insert(range, at: i) }
        break
      }
    }
    capacity = max(range.endIndex, capacity)
    insertFn()
  }
}
