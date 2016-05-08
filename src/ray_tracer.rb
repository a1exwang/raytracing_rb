require_relative 'libs/algebra'

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
      queue.enq({ type: :ray, ray: ray })
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
      [
          # rays
          [],
          # lights
          [{ type: :light, color: @world.ambient_light }]
      ]
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
