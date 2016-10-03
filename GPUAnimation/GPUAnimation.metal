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

#include <metal_stdlib>
using namespace metal;

struct Animation {
  float4 frame;
  float4 target;
  float4 velocity;
  float threshold;
  float stiffness;
  float damping;
  int running;
};

kernel void springAnimate(
                          uint2 gid                                    [[ thread_position_in_grid ]],
                          device Animation* params                  [[ buffer(0) ]],
                          constant float *dt                  [[ buffer(1) ]]
                          )
{
  device Animation *a = &params[gid.x];
  float4 diff = a->frame - a->target;
  a->running = a->running && any(abs(a->velocity) > a->threshold || abs(diff) > a->threshold);

  float4 Fspring = (-a->stiffness) * diff;
  float4 Fdamper = (-a->damping) * a->velocity;

  float4 acceleration = Fspring + Fdamper;

  float4 newV = a->velocity + acceleration * dt[0];
  float4 newX = a->frame + newV * dt[0];
  
  a->velocity = a->running ? newV : float4();
  a->frame = a->running ? newX : a->target;
}
