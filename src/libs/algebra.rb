module Alex
  class Ray
    attr_accessor :front, :position
    def initialize(f, pos)
      @front = f
      @position = pos
    end
  end

end
