# GPUAnimation
#### Requires Swift 3, iOS 9
A iOS UIKit Animation Library that uses the **Metal** for the heavy lifting.
It provides an elegant swift API for animating any attributes you like.
Save CPU time for handing events instead of calculation animation steps.

**NOTE**: This is currently in **BETA**, use at caution.

## Table of Contents
* [Installation](#installation)
* [Usage](#usage)
* [Animation Attributes](#animation-attributes)
* [Parallel Execution](#parallel-execution)
* [Serial Execution](#serial-execution)
* [Advance Controls](#advance-controls)
  * [Delay Animation](#delay-animation)
  * [Register Callback](#register-callback)
  * [Observing value or velocity changes](#observing-value-or-velocity-changes)
* [UIView Animatable Properties](#uiview-animatable-properties)
* [Animating Custom Properties](#animating-custom-properties)

# Installation
Cocoapods
```
use_frameworks!
pod "GPUAnimation"
```

# Usage

```swift
view.animate {
  $0.alpha.target = 0.5
  $0.center.target = CGPoint(x:100,y:200)
}.delay(2.0).animate {
  $0.center.target = CGPoint(x:50,y:50)
  $0.center.onChange = { newAlpha in
    print(newAlpha)
  }
  $0.backgroundColor.target = UIColor.black
}.then {
  print("Animation completed")
}
```

# Animation Attributes

GPUAnimation runs all animations like a spring. There is no way to specify the duration of the animation.  
This is to ensure that your object follows a physics like smooth velocity curve.  
Even if you change the animation target, the object maintains its velocity and follow a natural curve to its new target.  

You can adjust the spring property by tweaking the following values:
* **stiffness** (tension on the spring, higher value -> faster animation, **default: 200**)
* **damping** (friction on the spring, higher value -> less bounciness, **default: 10**)
* **threshold** (ending threshold, if both velocity and distance drop below this threshold, the animation is ended, **default: 0.01**)

The way you adjust these values is like this:
```swift
view.animate {
  $0.stiffness = 500
  $0.damping = 30
  $0.threshold = 1
  $0.center.target = CGPoint(x:100,y:200) // this animation is affected by the new attributes
  $0.bounds.target = CGRect(x:0,y:0,width:100,height:100) // this too
}.animate{
  $0.backgroundColor.target = UIColor.black // this is not affected(still uses default stiffness, etc..)
}
```
Though I believe it is spring is enough for most situations.  
I understand that sometimes a timing curve is useful.  
(Please let me know if this feature is helpful to you)

# Parallel Execution
By default, all properties(eg. `alpha`, `center`, `backgroundColor` in the example below) are animated concurrently.
```swift
view.animate {
  $0.alpha.target = 0.5
  $0.center.target = CGPoint(x:100,y:200)
}.animate {
  $0.backgroundColor.target = UIColor.black
}
```

# Serial Execution
Use `.then` or `.delay(time)` to seperate animations into serial groups.

For example below, `alpha` and `center` are animated first. Then `backgroundColor`. Then `bounds`
```swift
view.animate {
  $0.alpha.target = 0.5
  $0.center.target = CGPoint(x:100,y:200)
}.then.animate {
  $0.backgroundColor.target = UIColor.black
}.then.animate {
  $0.bounds.target = CGRect(x:0,y:0,width:100,height:100)
}
```

# Advance Controls
### Delay Animation
```swift
view.delay(2) {
  // this animation is trigger after 2 seconds
  $0.alpha.target = 0.5
}.delay(2).animate {
  // this animation is trigger after 4 seconds
  $0.backgroundColor.target = UIColor.black
}
```
### Register callback
Use `.then{ }` to register callback for animation completion
```
view.animate {
  $0.alpha.target = 0.5
  $0.center.target = CGPoint(x:100,y:200)
}.then{
  print("First batch done!")
}.animate {
  $0.backgroundColor.target = UIColor.black
}.then{
  print("Second batch done!")
}
```
### Observing value or velocity changes
```swift
view.animate{
  $0.center.target = CGPoint(x:200, y:200)
  $0.center.onChange = { newCenter in
    print(newCenter)
  }
  $0.center.onVelocityChange = { velocity in
    print("velocity:\(velocity)")
  }
}
```

# UIView Animatable Properties

* frame
* bounds
* center
* backgroundColor
* alpha
* shadowColor
* shadowRadius
* shadowOffset
* shadowOpacity
* transform
  * scale
  * rotate
  * translate
 
# Animating Custom Properties
### For UIView
```swift
view.animate{
  $0.custom(key: "myCustomProperty",
            getter: { return view.myCustomProperty.toVec4 },
            setter: { nv in view.myCustomProperty = CGFloat.fromVec4(nv) },
            target: 100.toVec4 )
}
```

### For any other objects. You can use the underlying API provided by GPUAnimator
```swift
class GPUAnimator{
  func animate(_ item:T,
               key:String,
               getter:@escaping () -> float4,
               setter:@escaping (inout float4) -> Void,
               target:float4,
               stiffness:Float = 200,
               damping:Float = 10,
               threshold:Float = 0.01,
               completion:((Bool) -> Void)? = nil)
}

// For example
class Foo{
  var a:CGFloat = 0
}
var f = Foo()
// Animate f.a to 5
GPUAnimator.sharedInstance.animate(f, key:"a", 
                                   getter:{ return f.a.toVec4 }, 
                                   setter:{ nv in f.a = CGFloat.fromVec4(nv) },
                                   target:5.toVec4)
```
