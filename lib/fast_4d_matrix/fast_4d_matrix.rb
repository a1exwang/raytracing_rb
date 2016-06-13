require 'json'
module Fast4DMatrix
  class Vec3
    # method stub
    def self.from_a(a, b, c); raise NotImplementedError; end
    def to_a; raise NotImplementedError; end
    def to_s; to_a.to_s; end
    def r;  raise NotImplementedError; end
    def r2; raise NotImplementedError; end
    def dot(other); raise NotImplementedError; end
    def cos(other); raise NotImplementedError; end
    def cross(other); raise NotImplementedError; end
    def add(other); raise NotImplementedError; end
    def sub(other); raise NotImplementedError; end
    def mul(other); raise NotImplementedError; end
    def add!(other); raise NotImplementedError; end
    def sub!(other); raise NotImplementedError; end
    def mul!(other); raise NotImplementedError; end
    def normalize;  raise NotImplementedError; end
    def normalize!; raise NotImplementedError; end
    def to_json(param); to_a.to_json; end
  end
  class Matrix33
    # method stub
    def self.zero; raise NotImplementedError; end
    def self.identity; raise NotImplementedError; end
    def add!(other); raise NotImplementedError; end
    def to_a; raise NotImplementedError; end
  end
end

require_relative '../fast_4d_matrix'
