require 'rmagick'
require_relative '../../lib/fast_4d_matrix/fast_4d_matrix'
include Fast4DMatrix
module Alex
  class Texture
    attr_reader :width
    attr_reader :height
    def initialize(file_name, horizontal_scale, vertical_scale, u_off = nil, v_off = nil)
      @horizontal_scale = horizontal_scale
      @vertical_scale = vertical_scale
      @data = []
      @image = Magick::Image.read(file_name).first
      @width = @image.columns
      @height = @image.rows
      @u_off = u_off || 0.0
      @v_off = v_off || 0.0
      @image.each_pixel do |pixel, col, row|
        @data[row] = [] unless @data[row]
        @data[row][col] = Vec3.from_a((pixel.red >> 8) / 256.0, (pixel.green >> 8) / 256.0, (pixel.blue >> 8) / 256.0)
      end
    end

    def color(uu, vv)
      u = ((uu + @u_off) / @horizontal_scale).to_i % @width
      v = ((vv + @v_off) / @vertical_scale).to_i % @height

      @data[v][u]
    end

    def [](x, y)
      @data[x][y]
    end

    def to_a
      @data.dup
    end
  end
end
