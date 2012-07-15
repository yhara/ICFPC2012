require_relative 'hash_eqlable'

class LambdaLifter
  class Pos
    include HashEqlable

    def self.[](x,y)
      new(x, y)
    end

    attr_reader :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end

    def +(other)
      return self.class.new(x + other.x, y + other.y)
    end

    def -(other)
      return self.class.new(x - other.x, y - other.y)
    end

    # Note: ソートしたときに、bottom to top・left to rightになってほしいため、
    # [y, x]としている
    def <=>(other)
      [y, x] <=> [other.y, other.x]
    end
    include Comparable

    def inspect
      "(#{@x}, #{@y})"
    end
    alias :to_s :inspect

    def hash
      [x, y].hash
    end
  end
end
