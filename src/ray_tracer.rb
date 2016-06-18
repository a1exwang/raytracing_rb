require_relative 'libs/algebra'
require_relative '../logger'
require_relative '../lib/fast_4d_matrix/fast_4d_matrix'
include Fast4DMatrix
module Alex
  class RayTracer
    def initialize(world, trace_depth, width, height, monte_carlo_diffusion_times)
      @world = world
      @trace_depth = trace_depth
      @queue = []
      @light_queues = Array.new(width) { Array.new(height) { Queue.new } }
      @queue_size = 0
      @monte_carlo_diffusion_times = monte_carlo_diffusion_times
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

    # 对一条光线, 求反射, 折射光线和局部光照的颜色
    # 最终所有光线都变成了颜色值
    def rt_map(rt_ray)
      ret = [[], []]
      if rt_ray[:trace_depth] <= 0 || rt_ray[:attenuation].r < 0.0001
        LOG.logt('rt_map', "dead because of rt_depth: position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
            "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name}, #{rt_ray[:ray].front})\n")
        return ret
      end

      # 首先判断是不是直接射到光源
      # high light
      lights = @world.high_lights(rt_ray[:ray], rt_ray[:object])
      lights.each do |light, color|
        LOG.logt('rt_map', "high_light: from(#{light.name}), to(#{rt_ray[:object]&.name})", 4)
        ret.last << {
            type: :high_light,
            color: rt_ray[:attenuation] * color / lights.size.to_f,
            x: rt_ray[:x],
            y: rt_ray[:y],
            parent: rt_ray,
            str: "highlight on #{light.name}",
            trace_depth: rt_ray[:trace_depth] - 1
        }
      end

      # 如果是高光项, 那么不可能再传播
      return ret if ret.last.size > 0

      # intersection
      object, intersection, direction, delta, data = @world.intersect(rt_ray[:ray])
      if object
        p = object.intersect_parameters(rt_ray[:ray], intersection, direction, delta, data)
        n = p[:n]
        reflection_ray = p[:reflection]
        refraction_ray = p[:refraction]

        att_reflect, att_refract = object.reflect_refract_vector(rt_ray[:ray], intersection, n, reflection_ray, refraction_ray)

        if reflection_ray
          LOG.logt('rt_map', "reflection: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
              "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name}, #{rt_ray[:ray].front})\n" +
              "on(#{object.name})\n" +
              "out(#{reflection_ray})")
          reflection = {
              type:         :reflection,
              ray:          reflection_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_reflect,
              parent:       rt_ray
          }
          ret.first << reflection
        end

        if refraction_ray
          LOG.logt('rt_map', "refraction: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]}, #{direction})\n" +
              "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name})\n" +
              "on(#{object.name}, #{intersection})\n" +
              "out(#{refraction_ray})")
          refraction = {
              type:         :refraction,
              ray:          refraction_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_refract,
              parent:       rt_ray
          }
          ret.first << refraction
        end

        lights = @world.local_lights(intersection + delta, object)
        if lights.size == 0
          # # use path tracing to calculate diffusion
          # puts "path tracing at #{rt_ray[:x]}, #{rt_ray[:y]}"
          LOG.logt('rt_map', "path_tracing: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
              "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name}, #{rt_ray[:ray].front})\n" +
              "object(#{object.name})\n" +
              "lights(#{lights.map { |x| x.first.name }.join(', ')})")
          path_tracing_rays = object.path_tracing(intersection + delta, n, @monte_carlo_diffusion_times)
          path_tracing_rays.each do |pt_ray, pt_att|
            ret.first << {
                type: :path_tracing,
                ray: pt_ray,
                trace_depth: rt_ray[:trace_depth] - 1,
                x: rt_ray[:x],
                y: rt_ray[:y],
                object: object,
                attenuation: rt_ray[:attenuation] * pt_att,
                parent: rt_ray
            }
          end
        else
          # normal diffusion
          LOG.logt('rt_map', "local: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
              "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name}, #{rt_ray[:ray].front})\n" +
              "object(#{object.name})\n" +
              "lights(#{lights.map { |x| x.first.name }.join(', ')})")
          ret.last << {
              type: :local,
              color: rt_ray[:attenuation] * object.local_lighting(intersection, lights, n, rt_ray[:ray]),
              x: rt_ray[:x],
              y: rt_ray[:y],
              parent: rt_ray,
              trace_depth: rt_ray[:trace_depth] - 1
          }
        end
      else
        LOG.logt('rt_map', "light_dead: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
            "direction = #{rt_ray[:ray].front.to_a.map { |x| x.round(3) }}")
      end
      ret
    end

    def roulette_random(array)
      total = array.map { |_, p| p }.reduce(0, &:+)
      raise 'parameter error' if total == 0
      r = Random.rand * total
      sum = 0
      array.each do |data, probability|
        if sum <= r && r < sum + probability
          return data, probability
        else
          sum += r
        end
      end
      raise 'random blows up'
    end

    def path_trace_sync(x, y, ray)
      root_obj = Object.new
      def root_obj.name
        'root'
      end
      path_trace(
          type: :root,
          ray: ray,
          trace_depth: @trace_depth,
          attenuation: Vec3.from_a(1.0, 1.0, 1.0),
          object: root_obj,
          x:  x,
          y:  y,
          str: "root for #{x}, #{y}")
    end
    def path_trace(rt_ray)
      if rt_ray[:trace_depth] <= 0 || rt_ray[:attenuation].r < 0.0001
        LOG.logt('path_trace', "dead because of rt_depth: position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
            "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name}, #{rt_ray[:ray].front})\n")
        return Vec3.from_a(0.0, 0.0, 0.0)
      end

      # 首先判断是不是直接射到光源
      # high light
      ret = Vec3.from_a(0.0, 0.0, 0.0)
      lights = @world.high_lights(rt_ray[:ray], rt_ray[:object])
      high_light = false
      lights.each do |light, color|
        LOG.logt('path_trace', "high_light: from(#{light.name}), to(#{rt_ray[:object]&.name})", 4)
        ret += rt_ray[:attenuation] * color / lights.size.to_f
        high_light = true
      end
      # 如果是高光项, 那么不可能再传播
      return ret if high_light

      # intersection
      object, intersection, direction, delta, data = @world.intersect(rt_ray[:ray])
      if object
        p = object.intersect_parameters(rt_ray[:ray], intersection, direction, delta, data)
        n = p[:n]
        reflection_ray = p[:reflection]
        refraction_ray = p[:refraction]

        att_reflect, att_refract = object.reflect_refract_vector(rt_ray[:ray], intersection, n, reflection_ray, refraction_ray)

        actions = [[:diffuse, object.diffuse_probability]]
        actions << [:reflect, object.reflect_probability] if reflection_ray
        actions << [:refract, object.refract_probability] if refraction_ray
        action, _ = roulette_random(actions)

        case action
          when :reflect
            LOG.logt('path_trace', "reflection: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
                "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name}, #{rt_ray[:ray].front})\n" +
                "on(#{object.name})\n" +
                "out(#{reflection_ray})")
            reflection = {
                type:         :reflection,
                ray:          reflection_ray,
                trace_depth:  rt_ray[:trace_depth] - 1,
                x:            rt_ray[:x],
                y:            rt_ray[:y],
                object:       object,
                attenuation:  rt_ray[:attenuation] * att_reflect,
                parent:       rt_ray
            }
            path_trace(reflection)
          when :refract
            LOG.logt('path_trace', "refraction: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]}, #{direction})\n" +
                "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name})\n" +
                "on(#{object.name}, #{intersection})\n" +
                "out(#{refraction_ray})")
            refraction = {
                type:         :refraction,
                ray:          refraction_ray,
                trace_depth:  rt_ray[:trace_depth] - 1,
                x:            rt_ray[:x],
                y:            rt_ray[:y],
                object:       object,
                attenuation:  rt_ray[:attenuation] * att_refract,
                parent:       rt_ray
            }
            path_trace(refraction)
          when :diffuse
            LOG.logt('path_trace', "path_tracing: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
                "from(#{rt_ray[:type]}, #{rt_ray[:object]&.name}, #{rt_ray[:ray].front})\n" +
                "object(#{object.name})\n" +
                "lights(#{lights.map { |x| x.first.name }.join(', ')})")
            ray, att = object.diffuse_ray(intersection + delta, n)
            next_ray = {
                type: :diffuse,
                ray: ray,
                trace_depth: rt_ray[:trace_depth] - 1,
                x: rt_ray[:x],
                y: rt_ray[:y],
                object: object,
                attenuation: rt_ray[:attenuation] * att,
                parent: rt_ray
            }
            path_trace(next_ray)
          else
            raise 'unknown action'
        end
      else
        LOG.logt('path_trace', "light_dead: depth: #{rt_ray[:trace_depth]}, position(#{[rt_ray[:x], rt_ray[:y]]})\n" +
            "direction = #{rt_ray[:ray].front.to_a.map { |x| x.round(3) }}")
        Vec3.from_a(0.0, 0.0, 0.0)
      end
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
      c1 + c2
    end

  end
end
