require_relative 'libs/algebra'
require_relative '../logger'
require_relative '../lib/fast_4d_matrix/fast_4d_matrix'
include Fast4DMatrix
module Alex
  class RayTracer
    def initialize(world, trace_depth, width, height)
      @world = world
      @trace_depth = trace_depth
      @queue = []
      @light_queues = Array.new(width) { Array.new(height) { Queue.new } }
      @queue_size = 0
    end

    def trace_sync(x, y, ray)
      root_obj = Object.new
      def root_obj.name
        'root'
      end
      @queue << {
          type: :root,
          ray: ray,
          trace_depth: @trace_depth,
          attenuation: Vec3.from_a(1.0, 1.0, 1.0),
          object: root_obj,
          x:  x,
          y:  y,
          str: "root for #{x}, #{y}"
      }
      until @queue.empty?
        item = @queue.pop
        x, y = item[:x], item[:y]
        rays, lights = rt_map(item)
        lights.each { |l| @light_queues[x][y] << [x, y, l] }
        rays.each { |r| @queue << r }
      end

      @sum = Vec3.from_a(0.0, 0.0, 0.0)
      until @light_queues[x][y].empty?
        x, y, item = @light_queues[x][y].pop
        @sum = rt_reduce(@sum, item[:color])
      end

      @sum
    end

    # 对一条光线, 求反射, 折射光线, 散射, 高光, 环境光颜色
    # 最终所有光线都变成了颜色值
    def rt_map(rt_ray)
      ret = [[], []]
      if rt_ray[:trace_depth] <= 0 #|| rt_ray[:attenuation].r < 0.0001
        LOG.logt('rt_map', "dead because of rt_depth: position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
            "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name})\n")
        return ret
      end

      # # 首先判断是不是直接射到光源
      # # high light
      # lights = @world.high_lights(rt_ray[:ray], rt_ray[:object])
      # lights.each do |light, color|
      #   LOG.logt('rt_map', "high_light: from(#{light.name}), to(#{rt_ray[:object]&.name})", 4)
      #   ret.last << {
      #       type: :high_light,
      #       color: rt_ray[:attenuation] * color / lights.size.to_f,
      #       x: rt_ray[:x],
      #       y: rt_ray[:y],
      #       parent: rt_ray,
      #       str: "highlight on #{light.name}",
      #       trace_depth: rt_ray[:trace_depth] - 1
      #   }
      # end
      #
      # # 如果是高光项, 那么不可能再传播
      # return ret if ret.last.size > 0

      # intersection
      object, intersection, direction, delta = @world.intersect(rt_ray[:ray])
      if object
        p = object.intersect_parameters(rt_ray[:ray], intersection, direction, delta)
        n = p[:n]
        reflection_ray = p[:reflection]
        refraction_ray = p[:refraction]

        att_reflect, att_refract = object.reflect_refract_vector(rt_ray[:ray], intersection, n, reflection_ray, refraction_ray)

        # # reflection
         if reflection_ray
          LOG.logt('rt_map', "reflection: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
              "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name})\n" +
              "on(#{object.name})\n" +
              "to direction(#{reflection_ray.front.to_s})")
          reflection = {
              type:         :reflection,
              ray:          reflection_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_reflect,
              parent:       rt_ray,
              str:          "reflect on #{object.name}"
                  #object.reflect_attenuation(rt_ray[:ray], intersection, n, reflection_ray)
          }
          ret.first << reflection
        end

        if refraction_ray
          LOG.logt('rt_map', "refraction: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]}, #{direction})\n" +
              "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name})\n" +
              "on(#{object.name}, #{intersection})\n" +
              "to direction(#{refraction_ray.front})")
          refraction = {
              type:         :refraction,
              ray:          refraction_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_refract,
              parent:       rt_ray,
              str:          "refract on #{object.name}"
          }
          ret.first << refraction
        end

        # diffusion
        lights = @world.diffused_lights(intersection + delta, object)
        lights.each do |light, color|
          LOG.logt('rt_map', "diffusion: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
              "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name})\n" +
              "light(#{light.name}), object(#{object.name})")
          ret.last << {
              type: :diffusion,
              color: rt_ray[:attenuation] * object.diffuse(color, intersection) / lights.size.to_f,
              x: rt_ray[:x],
              y: rt_ray[:y],
              parent: rt_ray,
              str: "diffuse on object(#{object.name}) with light(#{light.name})",
              trace_depth: rt_ray[:trace_depth] - 1
          }
        end

        # # ambient light
        # ambient = {
        #     type: :ambient,
        #     color: rt_ray[:attenuation] * object.ambient,
        #     x: rt_ray[:x],
        #     y: rt_ray[:y],
        #     parent: rt_ray,
        #     str: "ambient on #{object.name}",
        #     trace_depth: rt_ray[:trace_depth] - 1
        # }
        # LOG.logt('rt_map', "ambient: object(#{object.name})", 4)
        # ret.last << ambient
      else
        LOG.logt('rt_map', "light_dead: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
            "direction = #{rt_ray[:ray].front.to_a.map { |x| x.round(3) }}")
      end
      ret
    end

    # 混合颜色值
    def rt_reduce(rt_light1, rt_light2)
      ret = mix_color(rt_light1, rt_light2)
      unless ret.to_a.map { |x| x <= 1 }.reduce(true, &:'&')
        raise "color greater than 1, #{ret}"
      end
      ret
    end

    private
    # 混合两个颜色值
    def mix_color(c1, c2)
      # x = 1 - 1 / (Math::E ** (Math.log(1/(1-c1[0])) + Math.log(1/(1-c2[0]))) / Math.log(Math::E))
      # y = 1 - 1 / (Math::E ** (Math.log(1/(1-c1[1])) + Math.log(1/(1-c2[1]))) / Math.log(Math::E))
      # z = 1 - 1 / (Math::E ** (Math.log(1/(1-c1[2])) + Math.log(1/(1-c2[2]))) / Math.log(Math::E))
      # Vector[x, y, z]
      # v = c1 + c2
      # Vector[v[0] > 1 ? 1 : v[0], v[1] > 1 ? 1 : v[1], v[2] > 1 ? 1 : v[2]]
      c1 + c2
    end

  end
end
