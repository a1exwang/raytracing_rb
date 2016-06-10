require 'rmagick'

module Alex
  class Texture
    attr_reader :width
    attr_reader :height
    def initialize(file_name)
      @data = []
      @image = Magick::Image.read(file_name).first
      @width = @image.columns
      @height = @image.rows
      @image.each_pixel do |pixel, col, row|
        @data[row] = [] unless @data[row]
        @data[row][col] = [(pixel.red >> 8) / 256.0, (pixel.green >> 8) / 256.0, (pixel.blue >> 8) / 256.0]
      end
    end

    def [](x, y)
      @data[x][y]
    end

    def to_a
      @data.dup
    end
  end
end
