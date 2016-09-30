
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

kernel void compute_main(
                        uint2 gid                                    [[ thread_position_in_grid ]],
                        device float4* params                  [[ buffer(0) ]]
                        )
{
  params[gid.x].xyz += 5;
}

kernel void animate_main(
                         uint2 gid                                    [[ thread_position_in_grid ]],
                         device Animation* params                  [[ buffer(0) ]],
                         constant float *dt                  [[ buffer(1) ]]
                         )
{
  device Animation *a = &params[gid.x];
  float4 diff = a->frame - a->target;
  a->running = any(abs(a->velocity) > a->threshold || abs(diff) > a->threshold);

  float4 Fspring = (-a->stiffness) * diff;
  float4 Fdamper = (-a->damping) * a->velocity;

  float4 acceleration = Fspring + Fdamper;

  float4 newV = a->velocity + acceleration * dt[0];
  float4 newX = a->frame + newV * dt[0];
  
  a->velocity = a->running ? newV : float4();
  a->frame = a->running ? newX : a->target;
}
