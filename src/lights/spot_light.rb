require_relative 'light'

module Alex::Lights
  class SpotLight < Light
    attr_accessor :radius

    def intersect?(ray)
      # 算出直线上到球心最近的点
      t = - (ray.position - self.center).dot(ray.front) / ray.front.r ** 2
      v = t * ray.front
      nearest_point = ray.position + v

      # 检查最近点是否在光线正方向
      # 这样就禁止了球内向球外发出光线
      if v.dot(ray.front) < 0
        return nil
      end

      # 如果最近点在球内, 则有交点
      nearest_dis = (nearest_point - self.center).r
      nearest_dis > self.radius
    end
  end
end