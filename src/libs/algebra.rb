module Alex
  class Ray
    attr_accessor :front, :position
    def initialize(f, pos)
      @front = f
      @position = pos
    end

    def distance(pos)
      (@position - pos).r
    end
  end

end
