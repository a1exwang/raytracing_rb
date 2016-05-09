require_relative 'libs/algebra'
require 'matrix'

module Alex
  class RayTracer
    def initialize(world, trace_depth)
      @world = world
      @trace_depth = trace_depth
    end

    # 反向跟踪屏幕x, y点上射入相机的光线
    def trace(x, y, ray)
      # map
      queue = Queue.new
      light_queue = Queue.new
      queue.enq(
          type: :root,
          ray: ray,
          trace_depth: @trace_depth,
          attenuation: Matrix[[1,0,0],[0,1,0],[0,0,1]]
      )
      begin
        item = queue.deq
        rays, lights = rt_map(item)

        rays.each { |r| queue.enq r }
        lights.each { |l| light_queue.enq l[:color] }
      end until queue.empty?

      # reduce
      sum = Vector[0, 0, 0]
      until light_queue.empty?
        item = light_queue.deq
        sum = rt_reduce(sum, item)
      end
      sum
    end

    # 对一条光线, 求反射, 折射光线, 散射, 高光, 环境光颜色
    # 最终所有光线都变成了颜色值
    def rt_map(rt_ray)
      ret = [[], []]
      return ret if rt_ray[:trace_depth] <= 0

      # 首先判断是不是直接射到光源
      # high light
      @world.high_lights(rt_ray[:ray], rt_ray[:object]).each do |_light, color|
        puts "high light from #{rt_ray[:object]&.name} to #{_light.name}"
        ret.last << { type: :high_light, color: color }
      end

      # 如果是高光项, 那么不可能再传播
      return ret if ret.last.size > 0

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
            object:       object,
            attenuation:  rt_ray[:attenuation] *
                object.reflect_attenuation(rt_ray[:ray], intersection, n, reflection)
        }
        ret.first << reflection

        # diffusion
        @world.diffused_lights(rt_ray[:ray].position, object).each do |_light, color|
          ret.last << { type: :diffusion, color: color }
        end

        # ambient light
        ambient = { type: :ambient, color: @world.ambient_light }
        ret.last << ambient
      end

      ret
    end

    # 混合颜色值
    def rt_reduce(rt_light1, rt_light2)
      mix_color(rt_light1, rt_light2)
    end

    private
    # 混合两个颜色值
    def mix_color(c1, c2)
      x = 1 - 1 / (Math::E ** (Math.log(1/(1-c1[0])) + Math.log(1/(1-c2[0]))) / Math.log(Math::E))
      y = 1 - 1 / (Math::E ** (Math.log(1/(1-c1[1])) + Math.log(1/(1-c2[1]))) / Math.log(Math::E))
      z = 1 - 1 / (Math::E ** (Math.log(1/(1-c1[2])) + Math.log(1/(1-c2[2]))) / Math.log(Math::E))
      Vector[x, y, z]
    end

  end
end
