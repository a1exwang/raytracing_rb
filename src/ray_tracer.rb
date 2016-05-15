require_relative 'libs/algebra'
require 'matrix'

module Alex
  class RayTracer
    def initialize(world, trace_depth, width, height)
      @world = world
      @trace_depth = trace_depth
      @queue = Queue.new
      @light_queues = Array.new(width) { Array.new(height) { Queue.new } }
      @queue_size = 0
      @qs_lock = Mutex.new
      # @threads = Array.new(4) do |i|
      #   Thread.new do
      #     loop do
      #       item = @queue.deq
      #       #@qs_lock.synchronize { @queue_size -= 1 }
      #
      #       x, y = item[:x], item[:y]
      #       results = [item]
      #       1.times do
      #         new_results = []
      #         results.each do |r|
      #           rays, lights = rt_map(r)
      #           new_results += rays
      #           lights.each { |l| @light_queues[x][y].enq [x, y, l[:color]] }
      #         end
      #         results = new_results
      #       end
      #       results.each { |r| @queue.enq r }
      #     end
      #   end
      # end

    #   @reducers = Array.new(1) do |i|
    #     Thread.new do
    #       loop do
    #         busy = false
    #         @light_queues.each do |q|
    #           unless q.empty?
    #             x, y, item = q.deq
    #             @sums[x][y] = rt_reduce(@sums[x][y], item)
    #             busy = true
    #           end
    #         end
    #         puts "reducer #{i} is not busy not!" unless busy
    #       end
    #     end
    #   end
    #   @sums = Array.new(width) { Array.new(height) { Vector[0, 0, 0] }}
    end

    # 反向跟踪屏幕x, y点上射入相机的光线
    def trace(x, y, ray)
      # map
      @queue.enq(
          type: :root,
          ray: ray,
          trace_depth: @trace_depth,
          attenuation: Matrix.identity(3),
          x:  x,
          y:  y
      )
      #@qs_lock.synchronize { @queue_size += 1 }
    end

    def trace_sync(x, y, ray)
      @queue.enq(
          type: :root,
          ray: ray,
          trace_depth: @trace_depth,
          attenuation: Matrix.identity(3),
          object: { name: 'root' },
          x:  x,
          y:  y
      )
      until @queue.empty?
        item = @queue.deq
        x, y = item[:x], item[:y]
        rays, lights = rt_map(item)
        lights.each { |l| @light_queues[x][y] << [x, y, l[:color]] }
        rays.each { |r| @queue << r }
      end

      @sum = Vector[0, 0, 0]
      until @light_queues[x][y].empty?
        x, y, item = @light_queues[x][y].deq
        @sum = rt_reduce(@sum, item)
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
      @world.high_lights(rt_ray[:ray], rt_ray[:object]).each do |_light, color|
        ret.last << { type: :high_light, color: color, x: rt_ray[:x], y: rt_ray[:y] }
      end
      #puts "high light from #{rt_ray[:object]&.name} to lights" if ret.last.size > 0

      # 如果是高光项, 那么不可能再传播
      return ret if ret.last.size > 0

      # intersection
      object, intersection, direction = @world.intersect(rt_ray[:ray])
      if object
        p = object.intersect_parameters(rt_ray[:ray], intersection, direction)
        n = p[:n]
        reflection_ray = p[:reflection]
        refraction_ray = p[:refraction]

        att_reflect, att_refract = object.reflect_refract_matrix(rt_ray[:ray], intersection, n, reflection_ray, refraction_ray)

        # reflection
        if reflection_ray
          reflection = {
              type:         :ray,
              ray:          reflection_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_reflect
                  #object.reflect_attenuation(rt_ray[:ray], intersection, n, reflection_ray)
          }
          ret.first << reflection
        end

        if refraction_ray
          puts "refraction on #{object.name}, direction: #{direction}, att: #{att_refract[0,0]}"
          refraction = {
              type:         :ray,
              ray:          refraction_ray,
              trace_depth:  rt_ray[:trace_depth] - 1,
              x:            rt_ray[:x],
              y:            rt_ray[:y],
              object:       object,
              attenuation:  rt_ray[:attenuation] * att_refract
                  #object.refraction_attenuation(rt_ray[:ray], intersection, n, refraction_ray)
          }
          ret.first << refraction
        end

        # diffusion
        @world.diffused_lights(rt_ray[:ray].position, object).each do |_light, color|
          ret.last << { type: :diffusion, color: object.diffuse(color), x: rt_ray[:x], y: rt_ray[:y] }
        end

        # ambient light
        ambient = { type: :ambient, color: @world.ambient_light, x: rt_ray[:x], y: rt_ray[:y] }
        ret.last << ambient
      end

      if rt_ray[:x] == 40
        if rt_ray[:type] == :root && object
            puts "(#{rt_ray[:x]}, #{rt_ray[:y]}) #{object.name} #{intersection} #{direction}"
        end

        #puts ret.first
        puts ret.last
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
      #v = c1 + c2
      #Vector[v[0] > 1 ? 1 : v[0], v[1] > 1 ? 1 : v[1], v[2] > 1 ? 1 : v[2]]
    end

  end
end
