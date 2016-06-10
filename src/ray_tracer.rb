require_relative 'libs/algebra'
require_relative '../logger'
require 'matrix'

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
          attenuation: Matrix.identity(3),
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

      @sum = Vector[0, 0, 0]
      until @light_queues[x][y].empty?
        x, y, item = @light_queues[x][y].pop
        if x == 100 && y == 40 && item[:type] != :ambient
          tmp = item
          chain = []
          puts "#{x}, #{y}"
          while tmp
            chain << tmp
            tmp = tmp[:parent]
          end
          chain.reverse.each do |c|
            puts "\tdepth:#{c[:trace_depth]}, #{c[:str]}"
          end
          puts
        end
        @sum = rt_reduce(@sum, item[:color])
      end

      @sum
    end

    # 对一条光线, 求反射, 折射光线, 散射, 高光, 环境光颜色
    # 最终所有光线都变成了颜色值
    def rt_map(rt_ray)
      ret = [[], []]
      return ret if rt_ray[:trace_depth] <= 0 #|| (rt_ray[:attenuation].reduce(0) { |sum, x| sum + x * x })

      # 首先判断是不是直接射到光源
      # high light
      lights = @world.high_lights(rt_ray[:ray], rt_ray[:object])
      lights.each do |light, color|
        LOG.logt('rt_map', "high_light: from(#{light.name}), to(#{rt_ray[:object]&.name})", 4)
        ret.last << {
            type: :high_light,
            color: rt_ray[:attenuation] * color / lights.size,
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
      object, intersection, direction = @world.intersect(rt_ray[:ray])
      if object
        reflection_energy_rate = 0.3 #0.4
        refraction_energy_rate = 0.0
        diffusion_energy_rate =  0.3 #0.2
        ambient_energy_rate =    0.01

        p = object.intersect_parameters(rt_ray[:ray], intersection, direction)
        n = p[:n]
        reflection_ray = p[:reflection]
        refraction_ray = p[:refraction]

        att_reflect, att_refract = object.reflect_refract_matrix(rt_ray[:ray], intersection, n, reflection_ray, refraction_ray)

        # reflection
        if reflection_ray
          LOG.logt('rt_map', "reflection: from(#{rt_ray[:parent] ? rt_ray[:parent][:object].name : 'root'})\n" +
              "to(#{object.name})\n" +
              "direction(#{reflection_ray.front})", 4)
          reflection = {
              type:         :ray,
              ray:          reflection_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_reflect * reflection_energy_rate,
              parent:       rt_ray,
              str:          "reflect on #{object.name}"
                  #object.reflect_attenuation(rt_ray[:ray], intersection, n, reflection_ray)
          }
          ret.first << reflection
        end

        if refraction_ray
          LOG.logt('rt_map', "refraction: from(#{rt_ray[:parent] ? rt_ray[:parent][:object]&.name : 'root'})\n" +
                             "to(#{object.name})\n" +
                             "direction(#{refraction_ray.front})", 4)
          refraction = {
              type:         :ray,
              ray:          refraction_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_refract * refraction_energy_rate,
              parent:       rt_ray,
              str:          "refract on #{object.name}"
          }
          ret.first << refraction
        end

        # diffusion
        lights = @world.diffused_lights(rt_ray[:ray].position, object)
        lights.each do |light, color|
          LOG.logt('rt_map', "diffusion: light(#{light.name}), object(#{object.name})", 4)
          ret.last << {
              type: :diffusion,
              color: rt_ray[:attenuation] * object.diffuse(color, intersection) * diffusion_energy_rate / lights.size,
              x: rt_ray[:x],
              y: rt_ray[:y],
              parent: rt_ray,
              str: "diffuse on object(#{object.name}) with light(#{light.name})",
              trace_depth: rt_ray[:trace_depth] - 1
          }
        end

        # ambient light
        ambient = {
            type: :ambient,
            color: rt_ray[:attenuation] * @world.ambient_light * ambient_energy_rate,
            x: rt_ray[:x],
            y: rt_ray[:y],
            parent: rt_ray,
            str: "ambient on #{object.name}",
            trace_depth: rt_ray[:trace_depth] - 1
        }
        LOG.logt('rt_map', "ambient: object(#{object.name})", 4)
        ret.last << ambient
      else
        LOG.logt('rt_map', "light_dead: (x, y) = #{[rt_ray[:x], rt_ray[:y]]}, direction = #{rt_ray[:ray].front.to_a.map { |x| x.round(3) }}")
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
