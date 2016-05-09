require_relative 'libs/algebra'
require 'matrix'

module Alex
  class RayTracer
    def initialize(world, trace_depth)
      @world = world
      @trace_depth = trace_depth
    end
    def trace(x, y, ray)
      # map
      queue = Queue.new
      light_queue = Queue.new
      queue.enq({ type: :ray, ray: ray, trace_depth: @trace_depth, attenuation: Matrix[[1,0,0],[0,1,0],[0,0,1]] })
      begin
        item = queue.deq
        rays, lights = rt_map(item)

        rays.each { |r| queue.enq r }
        lights.each { |l| light_queue.enq l[:color] }
      end until queue.empty?

      # reduce
      sum = light_queue.deq
      until light_queue.empty?
        item = light_queue.deq
        sum = rt_reduce(sum, item)
      end
      sum
    end

    def rt_map(rt_ray)
      ret = [[], []]
      return ret if rt_ray[:trace_depth] <= 0

      # intersection
      object, intersection = @world.intersect(rt_ray[:ray])
      if object
        p = object.intersect_parameters(rt_ray[:ray], intersection)
        n = p[:n]
        reflection = p[:reflection]

        # reflection
        reflection = {
            type:         :ray,
            ray:          reflection,
            trace_depth:  rt_ray[:trace_depth] - 1,
            attenuation:  rt_ray[:attenuation] *
                object.reflect_attenuation(rt_ray[:ray], intersection, n, reflection)
        }

        ret.first << reflection
      end


      # ambient light
      ambient = { type: :light, color: @world.ambient_light }
      ret.last << ambient

      ret
    end

    def rt_reduce(rt_light1, rt_light2)
      mix_color(rt_light1, rt_light2)
    end

    private
    def mix_color(c1, c2)
      c1 + c2
    end

  end
end
